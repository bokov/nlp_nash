#' ---
#' title: "Merging Clinithink Data"
#' author:
#' - "Pankil Shah"
#' - "Alex Bokov"
#' css: "production.css"
#' output:
#'   html_document:
#'     toc: false
#'     toc_float: false
#'     keep_md: yes
#' ---
#'
#+ set_config, echo=FALSE, message=FALSE, warning=FALSE,results='hide'
.projpackages <- c('dplyr','stringr');
.deps <- c( 'dictionary.R' );
#+ load_deps, echo=FALSE, message=FALSE, warning=FALSE,results='hide'
# do not edit the next two lines
.junk<-capture.output(source('./scripts/global.R',chdir=TRUE,echo=FALSE));
.currentscript <- current_scriptname('merge.R');
#'
#' # Clean up the data
#'
#+ cleanup
# cleanup ----
xwalk <- mutate(xwalk,utmedmrn=as.character(utmedmrn));
dat01 <- mutate(dat01,mrn=as.character(mrn),orig_order=seq_len(nrow(dat01)));
dat02 <- grep('(_tf|_fncl_.*)$',names(dat02),val=T) %>% gsub('_tf','',.) %>%
  c('age_at_death_days','start_date') %>% setdiff(names(dat02),.) %>%
  select(dat02,.) %>% `[`(-1,) %>% group_by(patient_num) %>%
  group_modify(function(xx,...){
    as.data.frame(sapply(xx,function(zz){
      if(is.logical(zz)) return(any(zz,na.rm = TRUE)) else {
        return(last(na.omit(zz)))}},simplify=FALSE));
    });
#' # Start joining
#'
#' ## dat02 + xwalk = dat03
#+ dat03
# dat03 ----
dat03 <- left_join(dat02,xwalk,by=c(patient_num='patient_num')
                   ,suffix=c('','.xwalk'));
if(with(dat03,!all.equal(sex_cd,sex_cd.xwalk))){
  warning('Mismatch in "sex_cd" between dat02 and xwalk')};
#'
#' ## Now join dat01 on
#'
#+ dat04
# dat04 ----
dat04 <- right_join(dat01,dat03,by=c(mrn='utmedmrn'));
if(with(dat04,sum((age-age_in_years_num)<=1,na.rm = T)!=nrow(dat01))){
  warning('Mismatch between "age" from Clinithink and "age_in_years_num" from i2b2');
}

#' Sort it in the same order as the original. First rows.
dat04 <- rbind(dat04[match(dat01$mrn,dat04$mrn),],subset(dat04,is.na(surname)));
#' Then, columns.
dat04 <- dat04[,c(intersect(names(dat01),names(dat04))
                  ,setdiff(names(dat04),names(dat01)))];

if(!(identical(dat04$mrn[seq_len(nrow(dat01))],dat01$mrn) &&
     all(diff(na.omit(dat04$orig_order))==1))){
  warning('Unable to restore original sort order')};

if(!(all(dat04$mrn %in% xwalk$utmedmrn) &&
     all(dat04$patient_num %in% dat02$patient_num))){
  warning('Some records lost during merge')};

if(!identical(names(dat04)[seq_len(ncol(dat01))],names(dat01))){
  warning('Columns incorrectly reordered')};

#' We could do a cross-check on Forename and Surname but there are a bunch of
#' edge-cases due to spacing, initials, etc. So maybe later.
#'
#' # Export the data for use outside these scripts
#'
#' ## Create temporary variable for restoring original column names
.names.dat04.out <- names(dat04);
.names.dat04.out[seq_len(ncol(dat01))] <-
  submulti(.names.dat04.out[seq_len(ncol(dat01))],map0[,c('varname','origname')]
           ,method = 'startsends');
#' ## The full, identified version
#'
export(setNames(dat04,.names.dat04.out)
       ,'PHI_NASH_1_3.1578502159.0543473_Clinithink_v00.xlsx');
#' ## The de-identified version
#'
#' Replace MRN column with i2b2 PATIENT_NUM
dat04$mrn <- dat04$patient_num;
#' Blow away the patient names without changing the column structure
dat04[,c('surname','forename')] <- NA;
#' Remove the identifying/extraneous variables
v_toremove <- c('patient_num','sex_cd.xwalk','patient_ide','pat_name');
dat04 <- select(dat04,-v_toremove);
attr(dat04,'tblinfo') <- tblinfo(dat04);
.names.dat04.out <- setdiff(.names.dat04.out,v_toremove);
#' Save out
export(setNames(dat04,.names.dat04.out)
       ,'DEID_NASH_1_3.1578502159.0543473_Clinithink_v00.xlsx');
#+ save,echo=FALSE,results='hide'
save(file=paste0(.currentscript,'.rdata'),list=c('map0','dat04'));
c()
