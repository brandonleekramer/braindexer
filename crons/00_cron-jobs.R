
#install.packages("cronR")
#cronR::cron_rstudioaddin()
#cronR::cron_njobs()
#cronR::cron_ls()
#cronR::cron_rm()
Sys.setenv(RSTUDIO_PANDOC="/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools")
library("rmarkdown")
library("slackr")

#setwd("~/Documents/git/braindexer/crons/")
#rmarkdown::render("01_allocations-status-cron.Rmd",
#                  output_format="html_document",
#                  envir = topenv(),
#                  output_dir = "output_dir",
#                  intermediates_dir = "intermediates_dir",
#                  clean = FALSE
#)
setwd("~/Documents/git/braindexer/crons/")
rmarkdown::render("02_allocations-cron.Rmd",
                  output_format="html_document",
                  envir = topenv(),
                  output_dir = "output_dir",
                  intermediates_dir = "intermediates_dir",
                  clean = FALSE
)
setwd("~/Documents/git/braindexer/crons/")
rmarkdown::render("03_financials-cron.Rmd",
                  output_format="html_document",
                  envir = topenv(),
                  output_dir = "output_dir",
                  intermediates_dir = "intermediates_dir",
                  clean = FALSE
)

html_file <- "~/Documents/git/braindexer/crons/output_dir/02_allocations-cron.html"
slackr::slackr_setup(config_file = "~/Documents/git/braindexer/braindexer.slackr")
slackr::slackr_upload(html_file,
                      stringr::str_c("Braindexer Allocations Report: ", lubridate::today()),  
                      channels = "#allocation-alerts")


