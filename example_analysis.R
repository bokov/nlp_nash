#' ---
#' title: "Evaluating Clinithink Results"
#' author:
#' - "Pankil Shah"
#' - "Alex Bokov"
#' - "Dimpy Shah"
#' - "Ronald Rodriguez"
#' - "Meredith Zozus"
#' css: "production.css"
#' output:
#'   html_document:
#'     toc: true
#'     toc_float: true
#' ---
#'
#+ set_config, echo=FALSE, message=FALSE, warning=FALSE,results='hide'
.projpackages <- c('GGally','pander','dplyr','ggplot2','psych','git2r');
.deps <- c( 'dictionary.R' );
#+ load_deps, echo=FALSE, message=FALSE, warning=FALSE,results='hide'
# do not edit the next two lines
.junk<-capture.output(source('./scripts/global.R',chdir=TRUE,echo=FALSE));
.currentscript <- current_scriptname('example_analysis.R');
#'
#' # Data
#'
#' This dataset is a spreadsheet with `r ncol(dat01)` columns and
#' `r nrow(dat01)` observations. Most of the columns represent various concepts
#' extracted from the notes by the Clinithink system. They are numeric and range
#' from 0 to 1, representing the weight each variable contributes to the overall
#' score (`patientscore`).
#'
#' # Variables
#'
#' The following variables are not used in analysis and are filtered out:
#+ c_omit, echo=FALSE
attr(dat01,'tblinfo')$c_omit <- attr(dat01,'tblinfo')$column %in%
  c('mrn','surname','forename','patientreporturl'
    # the above are non-analyzable text fields
    ,'gender' # in this dataset it's always 'U'
    ,'other_chron_liver_disease_prm_exc' # has all 0 values except for one
    );
gsub('\\b_|_\\b','`',pander(v(c_omit,dat01)));
#'
#' The reason `other_chron_liver_disease_prm_exc` is among them is that in this
#' dataset it always has a value of 0 except for one case.
#'
#' To match the instructions given to the screeners we need to consider just
#' the NLP variables that indicate NASH, rather than the ones which reflect
#' other eligibility criteria. Therefore we created another score, named
#' `a_ct_nash` that is the sum of the following variables:
#+ c_nashonly, echo=FALSE
attr(dat01,'tblinfo')$c_nashonly <- attr(dat01,'tblinfo')$column %in%
  c('nash_prm_inc','signs_of_nash_prm_inc','hepatic_fibrosis_nash_risk_prm_inc');
gsub('\\b_|_\\b','`',pander(v(c_nashonly,dat01)));
dat01$a_ct_nash <- dat01[,v(c_nashonly,dat01)] %>% rowSums;
#'
#' ***
#'
#' The following variables were used by CliniThink as exclusion criteria:
#+ c_exclude, echo=FALSE
attr(dat01,'tblinfo')$c_exclude <- attr(dat01,'tblinfo')$column %in%
  grep('_exc$',map0$varname,val=TRUE);
gsub('\\b_|_\\b','`',pander(v(c_exclude,dat01)));
#'
#' ***
#'
#' The following variables were used by CliniThink as inclusion criteria:
#+ c_include, echo=FALSE
attr(dat01,'tblinfo')$c_include <- attr(dat01,'tblinfo')$column %in%
  grep('_inc$',map0$varname,val=TRUE);
gsub('\\b_|_\\b','`',pander(v(c_include,dat01)));
#'
#' ***
#'
#' # Correlation of each pair of variables
#'
#' Below is a correlation matrix for each of the variables-- all the
#' inclusion/exclusion ones (except for `other_chron_liver_disease_prm_exc` as
#' explained above) plus `age`, `a_ct_nash` (the raw present/absent status for
#' NASH), and `patientscore` (the score calculated via Clinithink).
#'
#' Red indicates strong positive correlations and dark teak indicates strong
#' inverse correlations. The rows and columns have been sorted so as to make it
#' easier to see clusters of correlated variables.
#'
#' As expected `r gsub('\\b_|_\\b','\x60',pander(v(c_nashonly,dat01)))`
#' correlate with `a_ct_nash` (presence/absence of NASH) since the latter is
#' their sum. Interestingly, all
#' the large correlations for `patientscore` are negative ones, mostly for
#' exclusion criteria.
#'
#+ cor01, echo=FALSE
# Calculate a correlation matrix
cor01 <- dat01 %>% select(-c(v(c_omit,.))) %>% cor %>%
  {.ord<-hclust(as.dist((1-abs(.))/2))$order;(.)[.ord,.ord]};
# Move the two score variables to the last two rows and columns for easier
# interpretation
cor01 <- c('a_ct_nash','patientscore') %>% c(Filter(function(xx) !xx %in% .
                                                    ,colnames(cor01)),.) %>%
  `[`(cor01,.,.);
select(dat01,-c(v(c_omit,dat01))) %>% ggcorr(cor_matrix=cor01,label=TRUE
                                             ,label_size=2,nudge_x=-8
                                             ,layout.exp=8,nbreaks = 5, size=3);
#'
#' ***
#'
#' # NASH vs Clinithink Score
#'
#' In the above figure we also see that there is no correlation between
#' `a_ct_nash` and `patientscore`. In the table below we can see in more
#' detail considerable discrepancy between them (the italicized values).
#+ nash_v_score, echo=FALSE
with(dat01,table(`NASH Present:`=factor(a_ct_nash,levels=c(0,.5,1.5)
                                        ,labels=c('No','Maybe','Yes'))
                 ,`Clinithink Score:`=cut(patientscore,c(-Inf,0,Inf)
                                          ,labels = c('<=0','>0')))) %>%
  ftable %>% pander(justify='right',emphasize.strong.rows = 1:2
                    ,emphasize.cells=cbind(c(3,5),c(4,3)));
#' ***
#'
#' Below are estimates for $\kappa$ and weighted $\kappa$ again showing very
#' little agreement between detection of NASH via Clinithink's NLP (`a_ct_nash`)
#' versus recruitment eligibility via Clinithink's NLP (`patientscore`). The
#' `patientscore`, a continuous variable, was binned into three quantiles for
#' comparison with `a_ct_nash` which only has three distinct values to begin
#' with.
#'
#+ kappa, echo=FALSE,warning=FALSE,message=FALSE
mutate(dat01,a_ct_nash=(factor(a_ct_nash,levels=c(0,.5,1.5)
                               ,labels=c('No','Maybe','Yes')))
       ,patientscore=(cut(patientscore,quantile(patientscore,(0:3)/3)
                          ,include.lowest = TRUE
                          ,labels=c('No','Maybe','Yes')))) %>%
  select(c('a_ct_nash','patientscore')) %>%
  psych::cohen.kappa(levels = c('No','Maybe','Yes')) %>%
  `[`(c('n.obs','agree','weight','confid')) %>%
  setNames(c('Number of Observations','Agreement','Weights'
             ,'$\\kappa$  Estimates'))%>% pander;
#'
#'
#' # Next steps
#'
#' This is just a characterization of the Clinithink results, comparing two
#' scores that are both based on different summations of Clinithink-abstracted
#' concepts.
#'
#' The actual tests of greatest interest will be for the degree of agreement
#' between a) Clinithink, b) manual review of patient charts by trained
#' personnel, and c) a query against the structured data in the CIRD research
#' data warehouse.
#'
#' We now need items b) and c). Once we have them, we can proceed with the main
#' tests of interest.
#'
#' It will also be important to discover any patterns in the data that could
#' help us understand or at least predict the greatest discrepancies between the
#' three screening methods.
#'
#' # Reproducibility of these Results
#'
#+ git, echo=FALSE, message=FALSE, warning=FALSE, results='hide'
.repourl <- 'https://github.com/bokov/nlp_nash/';
.repo <- try(repository_head(repository(proj_get())));
.travisci <- 'https://travis-ci.org/bokov/nlp_nash';
if(!is(.repo,'try-error') && !is_detached(.repo$repo) && is_branch(.repo) &&
   length(diff(.repo$repo)$files) == 0 &&
   sum(ahead_behind(.repo,branch_get_upstream(.repo))) == 0){
  .repourl <- paste0(.repourl,'tree/',.repo$name);
  .repomessage <- paste0('**',.repo$name,'** branch of the ');
  .sha <- substr(branch_target(.repo),1,7);
  .shamessage <- paste0(' The unique SHA hash for the revision you are currently reading is '
                        ,.sha,'.');
  .badge <- sprintf('\n\nCI testing status: [![Travis-CI Build Status](%1$s.svg?branch=%2$s)](%1$s)'
                    ,.travisci,.repo$name)
} else {
  .repomessage <- .shamessage <- .badge <- c();
}
#' This report is directly generated from R scripts stored in the
#' `r .repomessage` [bokov/nlp_nash](`r .repourl`) repository on GitHub.
#' `r .shamessage` If you check out or download it from GitHub and compile the
#' `r paste0('\x60',.currentscript,'\x60')` file, you will get the above plots
#' and tables _but_ based on _simulated data_ in the same format since the raw
#' data contains PHI and we are not permitted to distribute it. If you obtain
#' from the authors a copy of...
#'
#' **`r paste0('\x60',basename(inputdata),'\x60')`**
#'
#'
#' (MD5 sum: `r tools::md5sum(inputdata[1])`)
#'
#' ..._then_ you will be able to reproduce the exact results you see here.
#'
#' You can leave feedback or questions
#' [at this link](https://github.com/bokov/nlp_nash/issues).
#' `r .badge`
#'
#+ save,echo=FALSE,results='hide'
save(file=paste0(.currentscript,'.rdata'),list=setdiff(ls(),.origfiles));
c()
