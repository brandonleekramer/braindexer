
library("tidyverse")
library("lubridate")
library("janitor")

unix_today = as.numeric(as.POSIXct((
  as.Date(today(), format="%d/%m/%Y")), format="%Y-%m-%d"))
unix_before_1 = as.numeric(as.POSIXct((
  as.Date(today(), format="%d/%m/%Y") - 1), format="%Y-%m-%d"))

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

queryVolumeByDeploymentOverTime = function(unix_timestamp, indexer_sync_list){
  
  subgraphs_metadata = subgraphDisplayNames()
  data_output = queryVolumeByDeployment(unix_timestamp, "mainnet", "mainnet-arbitrum") %>% 
    rename(success_rate = gateway_query_success_rate,
           avg_latency = avg_gateway_latency_ms) %>% 
    mutate(success_rate = round(as.numeric(success_rate),4),
           avg_latency = round(as.numeric(avg_latency),0)) %>% 
    group_by(deployment_id) %>% 
    summarise(query_count = sum(query_count),
              success_rate = str_c(round(mean(success_rate),4)*100,"%"),
              avg_latency = round(mean(avg_latency), 0)) %>% 
    left_join(subgraphs_metadata, by = "deployment_id") %>% 
    select(display_name, everything(), -network) %>% 
    mutate(rank = rank(-query_count, ties.method= "first")) %>%
    select(rank, display_name, query_count, success_rate, avg_latency, deployment_id) %>% 
    arrange(desc(query_count))
  data_output
}

subgraphDisplayNames = function(){
  metadataQuery = str_c('{
  subgraphs(first: 1000) {
    metadata {
      displayName
    }
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
  metadataQuery = metadataQuery$subgraphs 
  for (var in list("metadata", "currentVersion", "subgraphDeployment", "manifest")){
    metadataQuery = unnest_longer(metadataQuery, var, 
                                  indices_include = FALSE) %>% unnest(var)
  }
  
  metadataQuery = metadataQuery %>% 
    rename(display_name = displayName,
           deployment_id = id) %>% 
    filter(!is.na(display_name)) 
  metadataQuery
}

subgraph_queries_past1D = queryVolumeByDeploymentOverTime(unix_before_1)
