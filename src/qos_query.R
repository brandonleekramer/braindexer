

'{
  allocationDailyDataPoints(
    first: 1000
    where: {indexer: "0x920fdeb00ee04dd72f62d8a8f80f13c82ef76c1e", 
    subgraphDeployment: "QmYXL6XeXyGC2DCnoQ45ApG68pi8irCZdRdtFx69FetRDd"}
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
}'