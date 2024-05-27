

library("tidyverse")
library("lubridate")
library("plotly")
library("DT")
library("scales")
library("janitor")
#library("notionR")
library("onchainR")
library("here")
source(here("src", "helpers", "notion.R"))




rewardsByAllocation = function(block_start, skip_n){
  metadataQuery = str_c('{
  allocations(
    first: 1000 skip: ',skip_n,' orderBy: allocatedTokens orderDirection: desc
    where: {_change_block: {number_gte: ',block_start,'}, indexingDelegatorRewards_not: "0"}
  ) { indexer { id }
    id allocatedTokens indexingIndexerRewards indexingDelegatorRewards queryFeesCollected
  }
}')
  
  # clean subgraph data 
  networkSubgraph = "https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-arbitrum"
  metadataQuery = query_hosted_subgraph(metadataQuery, networkSubgraph)
  metadataQuery = metadataQuery$allocations  
  #metadataQuery = unnest_longer(
  #  metadataQuery, "indexer", indices_include = FALSE) 
  metadataQuery = metadataQuery %>% 
    mutate(allocation_id = id, 
           allocated_tokens = as.numeric(allocatedTokens)/(10^18),
           indexer_rewards = as.numeric(indexingIndexerRewards)/(10^18),
           delegator_rewards = as.numeric(indexingDelegatorRewards)/(10^18),
           query_fees = as.numeric(queryFeesCollected)/(10^18)) %>% 
    select(indexer, allocation_id, allocated_tokens, 
           indexer_rewards, delegator_rewards, query_fees) %>% 
    unnest(indexer) %>% rename(wallet_address = id)
  metadataQuery
}
  
get_block_number = function(timestamp, my_api_key){
  ts_query = str_c('{ blocks( first: 1, where: {timestamp: "',timestamp,'"}) {number timestamp}}')
  ts_query = query_subgraph(graphql_query = ts_query,
                            subgraph_id = "JBnWrv9pvBvSi2pUZzba3VweGBTde6s44QvsDABP47Gt",
                            api_key = my_api_key)
  ts_query = as.numeric(ts_query$blocks$number)
  ts_query
}

unix_before_7 = get_unix(today()-7)
block_number = get_block_number(unix_before_7, braindexer_api_key)
block_number


allocations_df = bind_rows(
  rewardsByAllocation(block_number,0),
  rewardsByAllocation(block_number,1000),
  rewardsByAllocation(block_number,2000)
) %>% group_by(wallet_address) %>% 
  summarise(allocation_count = length(allocation_id),
            allocated_tokens = max(allocated_tokens),
            indexer_rewards = sum(indexer_rewards),
            delegator_rewards = sum(delegator_rewards),
            query_fees = sum(query_fees)) %>% 
  arrange(desc(query_fees)) %>% 
  left_join(indexers, by = "wallet_address") %>% 
  select(indexer_name, everything())



