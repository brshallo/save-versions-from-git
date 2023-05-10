
<!-- README.md is generated from README.Rmd. Please edit that file -->

# PRE-REQUISITES
Libraries required:
```
install.packages("tidyverse")
install.packages("dplyr")
install.packages("utf8")
install.packages("pkgconfig")
install.packages("gert")
install.packages("crayon")
install.packages("here")
install.packages("rprojroot")
install.packages("bit64")
```


# Save all versions of file from a git repo

`save_file_versions_from_git*()` is a helper to make it easy to save all
(prior) versions of a (small) file in a git repository to a new folder.
See
[scripts/save\_file\_versions\_from\_git.R](https://github.com/brshallo/save-versions-from-git/blob/main/scripts/save_file_versions_from_git.R)
for further documentation on arguments.

**Simple example:**

``` r
# Load in function
source("https://raw.githubusercontent.com/brshallo/save-versions-from-git/main/scripts/save_file_versions_from_git.R")
```

Let’s download all prior versions of the Chicago ridership data in the
[tidymodels/modeldata](https://github.com/tidymodels/modeldata) package
/ github repository.

``` r
save_file_versions_from_github(
  file_url = "https://github.com/tidymodels/modeldata/commits/master/data/Chicago.rda",
  delete_clone = TRUE)
#> modeldata_Chicago/2019-11-26T134459_747759a.rda
#> modeldata_Chicago/2020-06-22T083013_a5a177c.rda
#> modeldata_Chicago/2021-06-24T160626_3bba7a0.rda
#> modeldata_Chicago/2021-07-13T195732_b08d294.rda
#> modeldata_Chicago/2021-07-13T212802_a025b89.rda
```

From here we might read these in and investigate changes to the files
over time.

## Use case and another example

I wrote these functions primarily as a helper to load in small data
dictionary files that changed over time and were versioned in git.

The [example-csv](https://github.com/brshallo/example-csv) repository
contains a made-up .csv file of a data dictionary of codes for different
types of animals. These codes have changed over time. The history of
these changes can be seen by reviewing the git history of the file.

<img src="figures/git-history.PNG" width="909" />

Pretend we work at this zoo and are reviewing a variety of older
datasets that have old encodings on them. We may need older versions of
the “data/animal-encodings.csv” data dictionary file to understand them.
In some cases we may want to save all versions of the file to a new
folder location.

``` r
# Save versions of specified file from github
save_file_versions_from_github(file_url = "https://github.com/brshallo/example-csv/blob/main/data/animal-encodings.csv",
                               delete_clone = TRUE)
#> example-csv_animal-encodings/2021-08-17T133656_ee76260.csv
#> example-csv_animal-encodings/2021-08-17T133730_c61cda8.csv
#> example-csv_animal-encodings/2021-08-17T133800_840e0b0.csv
```

## Steps of function

The core function used by `save_versions_from_github()` uses
`save_versions_from_git()` which does the following:

1.  Clones repository locally (or pulls if have cloned previously)
2.  Creates new folder and “commits.txt” file specifying all previous
    versions of the file
3.  Save each version of the file into this new folder (default is for
    output folder name to be auto-generated based on repo and file name
    passed in as arugments).
4.  Output the files in the output folder (all versions from git history
    of specified file).

To use on other types of git hosting platforms, e.g. Azure Repos, you’ll
need to use `save_file_versions_from_git()` which takes in slightly
different arguments. Again, see documentation
“scripts/save\_file\_versions\_from\_git.R” for arguments.

# Notes and Cautions

-   Clones the target repo into the existing folder – so be careful
    about extant folder names, etc.
-   Is set-up using a mix of R and bash calls via `system()` – with a
    little more effort could have written the whole thing using bash and
    made a little bit cleaner.
-   In addition to R, requires that git and bash are installed – though
    doesn’t do any checks for this.
-   Written on Windows OS with Bash for Windows installed (have not
    tried on other configurations).
-   I imagine more elegant solutions for “get all versions of a data
    dictionary from a git repository” could be set-up using
    [pins](https://github.com/rstudio/pins) or other tools.
-   Naming convention is not 100% safe from duplicates and oddities. For
    example, if a repository has another file with the same name but in
    a different folder and `save_file_versions_from_git*()` is run from
    within the same project, default behavior may send to same folder
    with no clear way of differentiating.
-   use with caution
