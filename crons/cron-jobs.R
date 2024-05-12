
#install.packages("cronR")
#slackr_setup()
#cronR::cron_rstudioaddin()
#cronR::cron_njobs()
#cronR::cron_ls()
#cronR::cron_rm()
Sys.setenv(RSTUDIO_PANDOC="/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools")


library("rmarkdown")
library("slackr")

rmarkdown::render(
  "~/Documents/git/overlap-labs/src/finance/financials-cron.Rmd",
  output_format="html_document",
  envir = topenv(),
  output_dir = "output_dir",
  intermediates_dir = "intermediates_dir",
  clean = FALSE
)

rmarkdown::render(
  "~/Documents/git/braindexer/crons/current-allocations.Rmd",
                  output_format="html_document",
                  envir = topenv(),
                  output_dir = "output_dir",
                  intermediates_dir = "intermediates_dir",
                  clean = FALSE
)

rmarkdown::render(
  "~/Documents/git/braindexer/crons/future-allocations.Rmd",
                  output_format="html_document",
                  envir = topenv(),
                  output_dir = "output_dir",
                  intermediates_dir = "intermediates_dir",
                  clean = FALSE
)

slackr::slackr_setup(config_file = "~/Documents/git/braindexer/crons/braindexer.slackr")
future_allocations = "~/Documents/git/braindexer/output_dir/future-allocations.html"
slackr::slackr_upload(future_allocations,
                      stringr::str_c("Braindexer Proposed Allocations: ", lubridate::today()),  
                      channels = "#allocation-alerts")
current_allocations = "~/Documents/git/braindexer/output_dir/current-allocations.html"
slackr::slackr_upload(current_allocations,
                      stringr::str_c("Braindexer Current Allocations: ", lubridate::today()),  
                      channels = "#allocation-alerts")

# try a retry https://github.com/slackapi/python-slack-sdk/issues/1165#issuecomment-1051268386
# https://api.slack.com/apps/A0733PYRD6Y/oauth?success=1




