# This file loads a stanadrd set of configurations for making .Rmd reports and
# .R scriports look good. To use, source it from your first code chunk. To
# override settings on individual documents, simply run the settings commands
# you wish to override below where you source this file. To change the
# project-wide defaults, edit this file.
message('Setting project defaults');
.projpackages <- c('GGally','pander','dplyr','ggplot2','data.table'
                   ,'psych','git2r'
                   ,'epiR','UpSetR'
                   ,'survival','broom','forcats','table1','english');
.deps <- c( '' );
.debug <- 0;
if(!require(tidbits)){
  # get the instrequire function
  message('Getting instrequire function');
  source('https://github.com/bokov/tidbits/raw/integration/R/instrequire.R');
  instrequire(union(c('data.table', 'digest', 'dplyr', 'haven', 'knitr'
                      , 'magrittr', 'methods','readr', 'readxl', 'RCurl'
                      , 'tibble', 'devtools', 'rio'),.projpackages));
}

.junk<-capture.output(source('./scripts/global.R',chdir=TRUE,echo=FALSE
                             ,local=TRUE));
# Set some formatting options for this document
panderOptions('table.alignment.default','right');
panderOptions('table.alignment.rownames','right');
panderOptions('table.split.table',Inf);
panderOptions('p.wrap','');
panderOptions('p.copula',', and ');
panderOptions('graph.fontfamily','serif');
# theme_get() gives default theme
theme_set(theme_bw(base_family = 'serif',base_size=14) +
            theme(strip.background = element_rect(fill=NA,color=NA)
                  ,strip.text = element_text(size=15)));
knitr::opts_chunk$set(echo=.debug>0, warning=.debug>0, message=.debug>0);

# detect current output format
.outfmt <- knitr::opts_knit$get('rmarkdown.pandoc.to');
message('.outfmt = ',.outfmt);
if(is.null(.outfmt)){
  .outfmt <- if(knitr::is_html_output()) 'html' else {
    if(knitr::is_latex_output()) 'latex' else {
      if(interactive()) 'html' else {
        'unknown';
      }}}};

inputdata <- c(performance='performance.rds',merge='merge.rds');
if(file.exists('local.config.R')) source('local.config.R',local = TRUE);
message('Done setting project defaults');

searchrep <- rbind(
   c('aprev','Apparent prevalence')
  ,c('tprev','True prevalence')
  ,c('se','Sensitivity')
  ,c('sp','Specificity')
  ,c('ppv','Positive predictive value')
  ,c('npv','Negative predictive value')
  ,c('plr','Positive likelihood ratio')
  ,c('nlr','Negative likelihood ratio')
);

print.episumm <- . %>% `[`(searchrep[,1],) %>%
  mutate(.,stat=submulti(rownames(.),searchrep,method='startsends')) %>%
  mutate_if(is.numeric,formatC,format='f',digits=2) %>%
  mutate(ci=paste0('(',lower,', ',upper,')')) %>% select('stat','est','ci');
