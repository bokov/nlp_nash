# UTHealth NLP Tools Evaluation

#### by Pankil Shah, Alex F. Bokov, Dimpy Shah, and Ronald Rodriguez
#### UT Health Population Health Sciences and Institute for the Integration of Medicine and Science

## Installation:

If you are an authorized user of the data, you should separately receive a copy
of the files `performance.rds` (md5: dafa6eb2f2e1a4df4c86e537310e24a6) and 
`merge.rds` (md5: 6c33457119ff440019fc1ac396c5cd48).

1. Clone this repository using 
   `git clone --recurse-submodules https://github.com/bokov/nlp_nash`
   Make sure you include the `--recurse-submodules` option.
   
2. Either copy `performance.rds` and `merge.rds` into the project directory or 
   (preferred) create a file called `local.config.R` in the project directory 
   and into that file put the following: 
   ` inputdata <- c(performance='PATH/TO/performance.rds',merge='PATH/TO/merge.rds')`
   ...where `PATH/TO` is replaced by the actual path where R should look for the 
   data. __DO NOT CHECK THE RDS FILES INTO GITHUB, YOU ARE RESPONSIBLE FOR
   MAINTAINING A STRICT SEPARATION BETWEEN DATA AND CODE__

3. Open the file `clinithink_manuscript_draft.Rmd` in  RStudio and 
   hit CTRL-SHIFT-K. The first time you do this, the scripts will install any
   needed R libraries that you are missing. This may take a long time but 
   afterward they will not need to do this.
   
   Alternatively, you can render the drafts from the console by typing:
   `rmarkdown::render('clinithink_manuscript_draft.Rmd',output_format='bookdown::html_document2',  encoding = 'UTF-8')`
   

## Summary of some of the files in this repo:

**`clinithink_manuscxript_draft.Rmd`**: The main document, which can be used to
generate the manuscript in HTML or Word format.

**`local.config.R`**: File specifying where R should look for the needed data 
files (see above).

**`.Rprofile`**: Provides the `fs()` command for highlighting text in markdown.

**`.boilerplate.R`**: Sets a lot of configuration options and attempts to install
the needed libraries if they are not available, keeping the utility code from
cluttering the main files.

**`template.docx`**: Template Word document whose styles control how the draft 
looks when rendered as Word.

**`production.css`**: CSS document whose styles control how the draft looks when 
rendered as HTML. Also available a less fancy `report.css`.

**`harvard-cite-them-right.csl`**: Controls the style of citations.

**`nlp_nash.bib`**: Bibliography file for this manuscript.

**`scripts`**: Re-usable utility scripts that are not yet part of an R package.

**`config.R`**: Global configuration options (including test data, but the test 
data is out of date at the moment).

We are grateful to you for [bug reports and any other feedback you may have to offer](https://github.com/bokov/nlp_nash/issues).


