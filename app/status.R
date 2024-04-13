

status_page = function(){
  
  braindexer_address = "0x920fdeb00ee04dd72f62d8a8f80f13c82ef76c1e"
  braindexer_api_key = "70aaeb3f153cc384625e9d49b4958aef"

  card_img_styling = "display: block; margin-left: auto; margin-right: auto; border-radius: 15px;"
  card_title_font_styling = 'font-size: 16px; font-style: bold; display: block; margin-left: auto; margin-right: auto;'
  card_subtitle_font_styling = 'font-size: 10px; display: block; margin-left: auto; margin-right: auto;'
  card_id_font_styling = 'font-size: 6px; display: block; text-align: center;'
  
  subgraph_images = read_csv("./subgraph_images.csv")
  
  todays_unix = as.numeric(as.POSIXct((
    as.Date(lubridate::today(), format="%d/%m/%Y")), format="%Y-%m-%d"))
  
  braindexer_allocations = allocationsByIndexer(braindexer_address) %>% 
    select(deployment_id, allocated_tokens, subgraph_id, allocation_id) %>% 
    mutate(allocated_tokens = round(allocated_tokens, 2))
  
  braindexer_statuses = maxBlocksBehind(braindexer_address, todays_unix) %>% 
    select(subgraph_deployment_ipfs_hash, avg_indexer_blocks_behind) %>% 
    rename(deployment_id = subgraph_deployment_ipfs_hash,
           blocks_behind = avg_indexer_blocks_behind) 
  
  braindexer_allocations = braindexer_allocations %>% 
    left_join(braindexer_statuses, by = "deployment_id") %>% 
    left_join(subgraphDisplayNames(), by = "deployment_id") %>% 
    left_join(subgraph_images, by = "deployment_id")
  
  cards = list()
  for (i in 1:nrow(braindexer_allocations)) { 
    
    cards = append(cards, list(card(
      full_screen = TRUE, 
      min_height = 225, 
      max_height = 225,
      fill = FALSE,
      card_body(img(src = braindexer_allocations$subgraph_img[i], 
                    height = 100, style = card_img_styling),
        p(format(braindexer_allocations$display_name[i], nsmall=0, big.mark=","), 
          style = card_title_font_styling, class = 'padding: 0;'),
        #p("Network: ", format(braindexer_allocations$network[i], nsmall=0, big.mark=","), 
        #  style = 'font-size: 10px; display: block; margin-left: auto; margin-right: auto;'),
        #p(str_c("Current Allocation: ", format(braindexer_allocations$allocated_tokens[i], 
        #  nsmall=0, big.mark=",")), style = card_subtitle_font_styling, class = 'padding: 0;'),  
        p("Avg Blocks Behind (1D): ", format(braindexer_allocations$blocks_behind[i], 
            nsmall=0, big.mark=","), style = card_subtitle_font_styling, class = 'padding: 0;'),
      #  p(paste(format(braindexer_allocations$subgraph_id[i],   nsmall=0, big.mark=","),
      #          format(braindexer_allocations$deployment_id[i], nsmall=0, big.mark=","),
      #          format(braindexer_allocations$allocation_id[i], nsmall=0, big.mark=",")), 
      #    style = card_id_font_styling)
    ))))
  }
  
  ui = layout_column_wrap(
    width = "225px", #fixed_width = TRUE,
    height = 3000, gap = "20px", fill = FALSE,
    cards[[1]],cards[[2]],cards[[3]],cards[[4]],cards[[5]],
    cards[[6]],cards[[7]],cards[[8]],cards[[9]],cards[[10]],
    cards[[11]],cards[[12]],cards[[13]],cards[[14]],cards[[15]],
    cards[[16]],cards[[17]],cards[[18]],cards[[19]],cards[[20]],
    cards[[21]],cards[[22]],cards[[23]],cards[[24]],cards[[25]],
    cards[[26]],cards[[27]],cards[[28]],cards[[29]],cards[[30]],
    cards[[31]],cards[[32]],cards[[33]],cards[[34]],cards[[35]],
    cards[[36]]#,cards[[37]],cards[[38]],cards[[39]],cards[[40]]#,
    #cards[[41]],cards[[42]],cards[[43]],cards[[44]],cards[[45]]
  )
}

#subgraph_statues()




















