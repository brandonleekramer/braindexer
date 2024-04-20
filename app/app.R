#rm(list = ls())
library("shiny")
library("bslib")
library("tidyverse")
library("janitor")
library("lubridate")
library("DT")
library("plotly")
library("crosstalk")
options(scipen = 999)

braindexer_address = "0x920fdeb00ee04dd72f62d8a8f80f13c82ef76c1e"
braindexer_api_key = "70aaeb3f153cc384625e9d49b4958aef"

# pages -----------------------------------------------------
#setwd("/Users/bkram/Documents/git/braindexer/app")
#source("./thegraphR.R")
source("./home.R")
source("./status.R")
source("./queries.R")
#source("./rewards.R")
#source("./delegators.R")
#source("./top-indexers.R")
#source("./top-subgraphs.R")
#source("./docs.R")

# navbar ----------------------------------------------------

link_website <- tags$a(
  shiny::icon("brain"), "Website",
  href = "https://braindexer.com/",
  target = "_blank"
)
link_twitter <- tags$a(
  shiny::icon("twitter"), "Twitter",
  href = "https://twitter.com/Braindexer_eth",
  target = "_blank"
)
link_github <- tags$a(
  shiny::icon("github"), "GitHub",
  href = "https://github.com/braindexer/",
  target = "_blank"
)
link_explorer <- tags$a(
  shiny::icon("magnifying-glass"), "Explorer",
  href = "https://thegraph.com/explorer/profile/0x920fdeb00ee04dd72f62d8a8f80f13c82ef76c1e?view=Indexing&chain=arbitrum-one",
  target = "_blank"
)
link_graphscan <- tags$a(
  shiny::icon("eye"), "Graphscan",
  href = "https://arbitrum.graphscan.io/profile?id=0x920fdeb00ee04dd72f62d8a8f80f13c82ef76c1e#indexer-details",
  target = "_blank"
)
link_okgraph <- tags$a(
  shiny::icon("thumbs-up"), "OK Graph",
  href = "https://okgraph.xyz/",
  target = "_blank"
)

ui <- page_navbar(
  tags$head(tags$link(rel = "shortcut icon", href = "braindexer-transparent.png")),
  title = div(img(
    src = "braindexer-transparent.png",
    height = 55,
    #width = 55,
    style = "margin:30px 20px 0px 20px" # top right bottom left
  ),""),
  #nav_panel("Home", p(home_page())),
  #nav_panel("Status", p(status_page())),
  nav_panel("Queries", p(queries_page())),
  #nav_panel("Rewards", p(rewards_page())),
  #nav_panel("Delegators", p(delegators_page())),
  #nav_panel("Top Subgraphs", p(top_subgraphs_page())),
  #nav_panel("Top Indexers", p(top_indexers_page())),
  #nav_panel("Docs", p(docs_page())),
  nav_spacer(),
  nav_menu(
    title = "Links", align = "right",
    nav_item(link_website), 
    nav_item(link_twitter), 
    #nav_item(link_github), 
    nav_item(link_explorer),
    nav_item(link_graphscan), 
    nav_item(link_okgraph),
  ), 
  padding = "padding-top: 0px; padding-bottom: 0px;",
  window_title = "Braindexer"
)

# server ----------------------------------------------------

server <- function(input, output) { } 

shinyApp(ui, server)

# TODO: 
#  fix hover state on top-indexers page











