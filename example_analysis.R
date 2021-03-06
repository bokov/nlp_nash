#' ---
#' title: "Evaluating Clinithink Results"
#' author: "Pankil Shah, Alex Bokov, Dimpy Shah, Ronald Rodriguez, Meredith Zozus"
#' css: "production.css"
#' output:
#'   html_document:
#'     toc: false
#'     toc_float: false
#'     keep_md: yes
#' ---
#'
#+ set_config, echo=FALSE, message=FALSE, warning=FALSE,results='hide'
.projpackages <- c('GGally','pander','dplyr','ggplot2','psych','git2r');
.deps <- c( 'merge.R' );
#+ load_deps, echo=FALSE, message=FALSE, warning=FALSE,results='hide'
# do not edit the next two lines
.junk<-capture.output(source('./scripts/global.R',chdir=TRUE,echo=FALSE));
.currentscript <- current_scriptname('example_analysis.R');

panderOptions('table.alignment.default','right');
panderOptions('table.alignment.rownames','right');
panderOptions('table.split.table',Inf);
panderOptions('p.wrap','`');
panderOptions('p.copula',', and ');
#'
#' # Data
#'
#' This dataset is a spreadsheet with `r ncol(dat04)` columns and
#' `r nrow(dat04)` observations. Most of the columns represent various concepts
#' extracted from the notes by the Clinithink system. They are numeric and range
#' from 0 to 1, representing the weight each variable contributes to the overall
#' score (`patientscore`).
#'
#' # Variables
#'
#' The following variables are not used in analysis and are filtered out:
#+ c_omit, echo=FALSE
attr(dat04,'tblinfo')$c_omit <- attr(dat04,'tblinfo')$column %in%
  c('mrn','surname','forename','patientreporturl'
    # the above are non-analyzable text fields
    ,'gender' # in this dataset it's always 'U'
    ,'birth_date', 'orig_order'
    ,'other_chron_liver_disease_prm_exc' # has all 0 values except for one
    );
pander(v(c_omit,dat04));

#'
#' The reason `other_chron_liver_disease_prm_exc` is among them is that in this
#' dataset it always has a value of 0 except for one case.
#'
#' To match the instructions given to the screeners we need to consider just
#' the NLP variables that indicate NASH, rather than the ones which reflect
#' other eligibility criteria. Therefore we created another score, named
#' `a_ct_nash` that is the sum of the following variables:
#+ c_nashonly, echo=FALSE
attr(dat04,'tblinfo')$c_nashonly <- attr(dat04,'tblinfo')$column %in%
  c('nash_prm_inc','signs_of_nash_prm_inc','hepatic_fibrosis_nash_risk_prm_inc');
pander(paste(v(c_nashonly,dat04)));
dat04$a_ct_nash <- dat04[,v(c_nashonly,dat04)] %>% rowSums;
attr(dat04,'tblinfo')$c_i2b2nash <- attr(dat04,'tblinfo')$column %in%
  c('v001_nlchlc_ptnts_tf','v003_fbrs__ptnts_tf','v004_sthpts_tf');
#' The equivalent i2b2 determinations are based on the following ICD codes:
pander(paste(v(c_i2b2nash,dat04)));
dat04$a_i2b2nash <- dat04[,v(c_i2b2nash,dat04)] %>% rowSums;
#'
#' ***
#'
#' The following variables were used by CliniThink as exclusion criteria:
#+ c_exclude, echo=FALSE
attr(dat04,'tblinfo')$c_exclude <- attr(dat04,'tblinfo')$column %in%
  grep('_exc$',map0$varname,val=TRUE);
pander(v(c_exclude,dat04));
#'
#' ***
#'
#' The following variables were used by CliniThink as inclusion criteria:
#+ c_include, echo=FALSE
attr(dat04,'tblinfo')$c_include <- attr(dat04,'tblinfo')$column %in%
  grep('_inc$',map0$varname,val=TRUE);
pander(v(c_include,dat04));
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
#' As expected `r pander(v(c_nashonly,dat04))`
#' correlate with `a_ct_nash` (presence/absence of NASH) since the latter is
#' their sum. Interestingly, all
#' the large correlations for `patientscore` are negative ones, mostly for
#' exclusion criteria.
#'
#+ cor01, echo=FALSE
# Calculate a correlation matrix
cor01 <- dat04 %>% select(-c(v(c_omit,.),'sex_cd','language_cd','race_cd')) %>%
  cor(use='pairwise') %>%
  {.ord<-hclust(as.dist((1-abs(.))/2))$order;(.)[.ord,.ord]};
# Move the two score variables to the last two rows and columns for easier
# interpretation
cor01 <- c('a_ct_nash','patientscore') %>% c(Filter(function(xx) !xx %in% .
                                                    ,colnames(cor01)),.) %>%
  `[`(cor01,.,.);
select(dat04,colnames(cor01)) %>% mutate_all(as.numeric) %>%
  ggcorr(cor_matrix=cor01,label=TRUE,label_size=2,nudge_x=-8,layout.exp=8
         ,nbreaks = 5, size=3);
#'
#' ***
#'
#' # NASH vs Clinithink Score
#'
#' In the above figure we also see that there is no correlation between
#' `a_ct_nash` and `patientscore`. In the table below we can see in more
#' detail considerable discrepancy between them (the italicized values).
#+ nash_v_score, echo=FALSE
with(dat04,table(`NASH Present:`=factor(a_ct_nash,levels=c(0,.5,1.5)
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
mutate(dat04,a_ct_nash=(factor(a_ct_nash,levels=c(0,.5,1.5)
                               ,labels=c('No','Maybe','Yes')))
       ,patientscore=(cut(patientscore,quantile(patientscore,(0:3)/3,na.rm=T)
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


.thisisrealdata <- length(setdiff(normalizePath(dirname(inputdata))
                                  ,normalizePath('data'))) > 0;
if(.thisisrealdata){
  .datamessage01 <- ' If you obtain from the authors copies of ...';
  .datamessage02 <- '..._then_ you will be able to reproduce the exact results you see here.';
} else .datamessage01 <- .datamessage02 <- c();
#' This report is directly generated from R scripts stored in the
#' `r .repomessage` [bokov/nlp_nash](`r .repourl`) repository on GitHub.
#' `r .shamessage` If you check out or download it from GitHub and compile the
#' `r paste0('\x60',.currentscript,'\x60')` file, you will get the above plots
#' and tables _but_ based on _simulated data_ in the same format since the raw
#' data contains PHI and we are not permitted to distribute it.
#' `r .datamessage01`
#+ datafiles, echo=FALSE
if(.thisisrealdata){
  setNames(tools::md5sum(inputdata),basename(inputdata)) %>% cbind %>%
    data.frame %>% setNames('MD5 sum') %>% pander
}
#'
#' `r .datamessage02`
#'
#' You can leave feedback or questions
#' [at this link](https://github.com/bokov/nlp_nash/issues).
#' `r .badge`
#'
#+ save,echo=FALSE,results='hide'
save(file=paste0(.currentscript,'.rdata'),list=setdiff(ls(),.origfiles));
c()
