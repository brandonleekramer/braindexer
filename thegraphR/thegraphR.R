
`%notin%` <- Negate(`%in%`)

# query_volumeByDeployment gets query volume over past N days for top 1000 subgraphs
# TODO: Build out support for multiple chains and multiple gateways in query 
# TODO: Add autopagination and subgraph names to this query
queryVolumeByDeployment = function(unix_timestamp, chain_id, gateway_id){
  dataOutput = str_c('{queryDailyDataPoints(
      first: 1000
      where: {
        chain_id: "',chain_id,'", 
        gateway_id: "',gateway_id,'", 
        dayStart_gt: "',unix_timestamp,'"} 
      orderBy: query_count
      orderDirection: desc
    ) {
      subgraphDeployment {
        id
      }
      query_count
      gateway_query_success_rate 
      avg_gateway_latency_ms
      total_query_fees
      gateway_id
      chain_id
      dayStart
      }
  }')
  
  qosSubgraph = "https://api.thegraph.com/subgraphs/name/juanmardefago/gateway-qos-oracle"
  dataOutput = query_hosted_subgraph(dataOutput, qosSubgraph)
  dataOutput = as.data.frame(dataOutput$queryDailyDataPoints) %>% 
    unnest(subgraphDeployment) %>% 
    mutate(query_count = as.numeric(query_count)) %>% 
    rename(deployment_id = id) %>% 
    filter(!is.na(deployment_id))
  dataOutput
}

# query_allocationsByIndexer gets first 1000 current allocations for Indexer wallet address
# TODO: Add autopagination and subgraph names to this query
allocationsByIndexer = function(wallet_address){
  #wallet_address = "0x920fdeb00ee04dd72f62d8a8f80f13c82ef76c1e"
  dataOutputQuery = str_c('{
    indexers(
      first: 1000
      orderBy: allocationCount
      orderDirection: desc
      where: {id: "',wallet_address,'"}
    ) {
    allocations(first: 1000, orderBy: allocatedTokens) {
        id
        allocatedTokens
        subgraphDeployment {
          ipfsHash
          signalledTokens
          stakedTokens
          versions {
            subgraph {
              id
            }
          }
        }
      }
    }
  }') # removed id 
  
  networkSubgraph = "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-arbitrum"
  dataOutput = query_hosted_subgraph(dataOutputQuery, networkSubgraph)
  dataOutput = as.data.frame(dataOutput$indexers) %>% 
    unnest(allocations) %>% 
    rename(allocation_id = id) %>%
    unnest(subgraphDeployment) %>% 
    unnest(versions) %>%
    unnest(subgraph) %>%
    rename(subgraph_id = id) %>%
    mutate(allocatedTokens = as.numeric(allocatedTokens)/(10^18),
           signalledTokens = as.numeric(signalledTokens)/(10^18),
           stakedTokens = as.numeric(stakedTokens)/(10^18),
           allocatedTokens = round(allocatedTokens, 2),
           signalledTokens = round(signalledTokens, 2),
           stakedTokens = round(stakedTokens, 2)) %>% 
    rename(deployment_id = ipfsHash,
           allocated_tokens = allocatedTokens,
           signalled_tokens = signalledTokens,
           staked_tokens = stakedTokens) %>% 
    select(deployment_id, allocated_tokens, signalled_tokens, 
           staked_tokens, subgraph_id, allocation_id) %>% 
    arrange(desc(allocated_tokens))
  
  dataOutput
}

indexersByQueryVolume = function(unix_timestamp){
  dataOutput = str_c('{
  indexers(
      first: 1000, 
      orderBy: id, 
      orderDirection: asc) {
    id
    indexerDailyDataPoints(
      orderBy: query_count,
      orderDirection: desc,
      where: {dayStart_gt: "',unix_timestamp,'"}
    ) {
      dayStart
      subgraph_deployment_ipfs_hash
      query_count
      total_query_fees
      avg_query_fee
      }
    }
  }')
  
  qosSubgraph = "https://api.thegraph.com/subgraphs/name/juanmardefago/gateway-qos-oracle"
  dataOutput = query_hosted_subgraph(dataOutput, qosSubgraph)
  dataOutput = dataOutput$indexers
  dataOutput = unnest_longer(
    dataOutput,indexerDailyDataPoints,indices_include = FALSE) %>% 
    unnest(indexerDailyDataPoints) %>% 
    rename(queries_served = query_count) %>% 
    mutate(queries_served = as.numeric(queries_served)) %>% 
    rename(wallet_address = id,
           query_fees_grt = total_query_fees) %>% 
    select(dayStart, everything())
  dataOutput
}


subgraphDisplayNames = function(skip_n){
  metadataQuery = str_c('{
  subgraphs(skip:',skip_n,', first: 1000) {
    metadata {
      displayName
    }
    id
    currentVersion {
      subgraphDeployment {
        manifest {
          id
          network
        }
      }
    }
  }
 }')
  
  # clean subgraph data 
  networkSubgraph = "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-arbitrum"
  metadataQuery = query_hosted_subgraph(metadataQuery, networkSubgraph)
  metadataQuery = metadataQuery$subgraphs %>% rename(subgraph_id = id)
  for (var in list("metadata", "currentVersion", "subgraphDeployment", "manifest")){
    metadataQuery = unnest_longer(
      metadataQuery, var, indices_include = FALSE) %>% unnest(var)
  }
  
  metadataQuery = metadataQuery %>% 
    rename(display_name = displayName,
           deployment_id = id) %>% 
    filter(!is.na(display_name)) 
  metadataQuery
}

prepare_tiered_subgraphs = function(data, lowerbound, upperbound){
  combined_rank = data %>% 
    filter(time_period == "Past 14D") %>% 
    group_by(deployment_id) %>% 
    summarise(query_count = sum(query_count)) %>% 
    arrange(desc(query_count)) %>% 
    slice_max(query_count, n = upperbound) %>%
    mutate(chart_rank = 1:upperbound) %>% 
    select(chart_rank, deployment_id)
  
  tiered_subgraphs = data %>% 
    rename(period_rank = rank) %>% 
    left_join(combined_rank, by = "deployment_id") %>% 
    select(chart_rank, everything()) %>% 
    filter(!is.na(chart_rank) & (chart_rank > lowerbound))
  
  missing_from_tier = tiered_subgraphs %>% 
    arrange(time_period) %>% 
    group_by(chart_rank, display_name, deployment_id, braindexer) %>% 
    summarize(time_period = paste0(time_period, collapse = "|")) %>% 
    filter(time_period != "Past 14D|Past 1D|Past 7D") %>%
    rename(time_period_recode = time_period) %>% 
    mutate(time_period = if_else(time_period_recode == "Past 1D", "Past 14D|Past 7D", NA),
           time_period = if_else(time_period_recode == "Past 14D", "Past 1D|Past 7D", time_period),
           time_period = if_else(time_period_recode == "Past 7D", "Past 1D|Past 14D", time_period),
           time_period = if_else(time_period_recode == "Past 1D|Past 14D", "Past 7D", time_period),
           time_period = if_else(time_period_recode == "Past 1D|Past 7D", "Past 14D", time_period),
           time_period = if_else(time_period_recode == "Past 14D|Past 7D", "Past 1D", time_period)) %>% 
    select(-time_period_recode) %>% 
    separate_rows(time_period, sep = "\\|") %>% 
    mutate(query_count = 0, avg_latency = 0,
           time_period_rank = if_else(time_period == "Past 1D", "4", "NA"),
           time_period_rank = if_else(time_period == "Past 7D", "3", time_period_rank),
           time_period_rank = if_else(time_period == "Past 14D", "2", time_period_rank))
  
  tiered_subgraphs = bind_rows(tiered_subgraphs, missing_from_tier) %>% 
    mutate(display_name = if_else(is.na(display_name), 
                                  str_c(substr(deployment_id, 1, 4),"-", 
                                        str_sub(deployment_id,-4,-1)," ♻️️"), display_name),
           display_name = if_else(braindexer == "Syncing", str_c(display_name, " 🧠"), display_name),
           display_name = fct_reorder(display_name, chart_rank)) %>% 
    arrange(chart_rank, period_rank)
  tiered_subgraphs
}

queryVolumeByDeploymentOverTime = function(unix_timestamp, chain_id, subgraphs_metadata){
  
  data_output = queryVolumeByDeployment(
    unix_timestamp, chain_id, "mainnet-arbitrum") %>% 
    rename(success_rate = gateway_query_success_rate,
           avg_latency = avg_gateway_latency_ms) %>% 
    mutate(success_rate = round(as.numeric(success_rate),4),
           avg_latency = round(as.numeric(avg_latency),0)) %>% 
    group_by(deployment_id) %>% 
    summarise(query_count = sum(query_count),
              success_rate = str_c(round(mean(success_rate)*100,4),"%"),
              avg_latency = round(mean(avg_latency), 0)) %>% 
    left_join(subgraphs_metadata, by = "deployment_id") %>% 
    group_by(query_count, success_rate, avg_latency, deployment_id, network) %>% 
    slice(1L) %>% 
    select(display_name, everything(), network) %>% 
    mutate(rank = rank(-query_count, ties.method= "first")) %>%
    select(rank, display_name, query_count, success_rate, avg_latency, deployment_id, network) %>% 
    arrange(desc(query_count))
  data_output
}

queriesByPeriod = function(data){
  dataOutput = data %>% 
    group_by(wallet_address) %>% 
    summarise(queries_served = sum(queries_served),
              query_fees_grt = sum(as.numeric(query_fees_grt)),
              query_fees_grt = round(sum(query_fees_grt),2)) %>% 
    arrange(-queries_served) %>% 
    left_join(data %>% 
                group_by(wallet_address) %>% 
                summarise(subgraphs_served = n_distinct(subgraph_deployment_ipfs_hash)), 
              by = "wallet_address") %>% 
    mutate(rank = rank(-queries_served, ties.method= "first")) %>%
    select(rank, wallet_address, queries_served, subgraphs_served, query_fees_grt)
  dataOutput
}

getPriceGRT = function(my_api_key){
  chainlink_query = str_c('{ assetPairs(where: {id: "GRT/USD"}) { id currentPrice }}')
  grt_price = query_subgraph(graphql_query = chainlink_query,
                             subgraph_id = "4RTrnxLZ4H8EBdpAQTcVc7LQY9kk85WNLyVzg5iXFQCH",
                             api_key = my_api_key)
  grt_price = as.numeric(grt_price$assetPairs$currentPrice)
  grt_price
}

getGraphArbitrumStats = function(output = c("staked_tokens",
                                            "signalled_tokens",
                                            "delegated_tokens")){
  
  dataOutput = str_c('{graphNetworks(first: 5) {
    totalTokensStaked
    totalDelegatedTokens
    totalTokensSignalled
    }
  }')
  analytics_subgraph = "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-analytics-arbitrum"
  dataOutput = query_hosted_subgraph(dataOutput, analytics_subgraph) 
  
  if (output == "staked_tokens"){
    dataOutput = as.numeric(dataOutput$graphNetworks$totalTokensStaked)/(10^18)}
  if (output == "signalled_tokens"){
    dataOutput = round(as.numeric(dataOutput$graphNetworks$totalTokensSignalled)/(10^18),2)}
  if (output == "delegated_tokens"){
    dataOutput = round(as.numeric(dataOutput$graphNetworks$totalDelegatedTokens)/(10^18),2)}
  
  dataOutput
}

getDeploymentStats = function(my_api_key){
  dataOutput = str_c('{ subgraphDeployments(
    first: 1000
    orderBy: stakedTokens
    orderDirection: desc
    where: {activeSubgraphCount_not: 0}
  ) {
    ipfsHash
    signalledTokens
    stakedTokens
    }
  }')
  
  #total_staked = getGraphArbitrumStats("staked_tokens") + getGraphArbitrumStats("delegated_tokens")
  #total_signal = getGraphArbitrumStats("signalled_tokens")
  total_staked = 750309625.47 + 1585059501.99
  total_signal = 4149662.62
  
  dataOutput = query_subgraph(graphql_query = dataOutput,
                              subgraph_id = "DZz4kDTdmzWLWsV373w2bSmoar3umKKH9y82SUKr5qmp",
                              api_key = "70aaeb3f153cc384625e9d49b4958aef")
  dataOutput = as.data.frame(dataOutput$subgraphDeployments) %>% 
    mutate(signalled_tokens = round(as.numeric(signalledTokens)/(10^18),4),
           staked_tokens = round(as.numeric(stakedTokens)/(10^18),4),
           proportion = ((signalled_tokens)/(total_signal))/((staked_tokens)/(total_staked)),
           proportion = if_else(is.infinite(proportion), 0, proportion)) %>% 
    rename(deployment_id = ipfsHash) %>% 
    select(deployment_id, signalled_tokens, staked_tokens, proportion) %>% 
    arrange(desc(proportion))
  dataOutput
}


maxBlocksBehind = function(indexer_wallet, unix_day_start){
  dataOutput = str_c('{allocationDailyDataPoints(
    first: 1000
    where: {indexer: "',indexer_wallet,'", dayStart_gte: "',unix_day_start,'"}
    orderDirection: desc
    orderBy: query_count
  ) {
    subgraph_deployment_ipfs_hash
    avg_indexer_blocks_behind
    max_indexer_blocks_behind
    proportion_indexer_200_responses
    avg_indexer_latency_ms
    total_query_fees
    query_count
    }
  }')
  
  qosSubgraph = "https://api.thegraph.com/subgraphs/name/juanmardefago/gateway-qos-oracle"
  dataOutput = query_hosted_subgraph(dataOutput, qosSubgraph)
  dataOutput = as.data.frame(dataOutput$allocationDailyDataPoints) %>% 
    distinct(subgraph_deployment_ipfs_hash, .keep_all = TRUE) %>% 
    mutate(avg_indexer_blocks_behind = round(as.numeric(avg_indexer_blocks_behind),2),
           max_indexer_blocks_behind = round(as.numeric(max_indexer_blocks_behind),2),
           success_rate = round(as.numeric(proportion_indexer_200_responses)*100,4),
           avg_latency_ms = round(as.numeric(avg_indexer_latency_ms),2),
           total_query_fees = round(as.numeric(total_query_fees),4),
           query_count = as.numeric(query_count)) %>% 
    select(-proportion_indexer_200_responses, -avg_indexer_latency_ms)
  dataOutput
}
















