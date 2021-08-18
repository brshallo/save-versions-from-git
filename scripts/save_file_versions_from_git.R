library(dplyr)
library(fs)
library(purrr)
library(readr)

# Add git to PATH (if not already on)
if(length(grep("(?i)Git//bin", Sys.getenv("PATH"))) == 0) {
  Sys.setenv(PATH = paste0(Sys.getenv("PATH"), ";C://Program Files//Git//bin"))
}

#' Save File Versions from Git
#' 
#' Function to save all previous versions of a file in a github (or other git)
#' repo to a folder. Currently `system()` calls are tailored to a Windows
#' Operating System and may not work on a different OS.
#'
#' @param repo_https HTTPS link from github to clone repo. (Also should work
#'   with Azure Repos or other service with similar structure).
#' @param file_path_in_repo File relative to the  cloned repo where the file of
#'   interest exists.
#' @param overwrite_all Default is FALSE (so if have run within a folder
#'   previously will not overwrite previously saved files.
#' @param skip_pull Default is FALSE. Setting to TRUE means will not do a git
#'   clone or git pull on `repo_https` e.g. if have already done these
#'   separately.
#' @param delete_clone Default is FALSE. If TRUE, will delete the folder and
#' files at `repo_local_path`.
#' @param delete_commits.txt Default is TRUE. If FALSE, will also output a
#'   commit.txt file that contains the hash and date tags for files.
#' @param repo_local_path Default parses expected repo name.
#' @param folder_output_override Set to a character string to set the output
#'   folder name. When NULL (default), files will be outputted to folder with
#'   name defined by `paste("versions", local_path,
#'   fs::path_ext_remove(fs::path_file(file_path_in_repo)), sep = "_")`
#'
#' @return Will create new files for all versions of file in git as well as "commits.txt" file)
#'
#' @examples
#' # Simple example
#' save_file_versions_from_git(repo_https = "https://github.com/brshallo/example-csv.git",
#'                             file_path_in_repo = "data/animal-encodings.csv")
#'                             
save_file_versions_from_git <- function(repo_https,
                                        file_path_in_repo,
                                        overwrite_all = FALSE,
                                        skip_pull = FALSE,
                                        delete_clone = FALSE,
                                        delete_commits.txt = TRUE,
                                        repo_local_path = stringr::str_extract(fs::path_ext_remove(repo_https), "([^/]*)$"),
                                        folder_output_override = NULL) {
  
  
  # minor changes to inputs from arguments
  file_in_repo <- fs::path_file(file_path_in_repo)
  folder_output <- paste("versions", repo_local_path, fs::path_ext_remove(file_in_repo), 
                         sep = "_")
  
  if(!is.null(folder_output_override)) folder_output <- folder_output_override
  
  # skip_pull if don't want to redownload or 
  if(!skip_pull) {
    # "clone" or "pull" if have cloned previously
    if (fs::dir_exists(repo_local_path)) {
      system(
        glue::glue(
          'bash -c "cd {repo_local_path} ; git pull {https}"',
          repo_local_path = repo_local_path,
          https = repo_https
        )
      )
    } else {
      system(glue::glue('bash -c "git clone {https}"',
                        https = repo_https))
    }
    
  }
  
  first_time <- !fs::dir_exists(folder_output)
  
  # Option to delete prior outputs of running
  if(overwrite_all && !first_time) fs::dir_delete(folder_output)
  
  # Create new dir for location to output
  fs::dir_create(folder_output)
  
  # Create commits.csv that contain cols for commit and date for versions of file 
  system(
    glue::glue(
      'bash -c "cd {repo_local_path} ; git log --oneline --pretty=format:{date_code} --date=short -- {file_path_in_repo} > ../{folder_output}/commits.txt"',
      repo_local_path = repo_local_path,
      file_path_in_repo = file_path_in_repo,
      folder_output = folder_output,
      date_code = "'%h %ad'" # otherwise messes-up quotes
    )
  )
  
  # Output everything in commits.csv to file_versions_output
  data_versions <- readr::read_delim(here::here(folder_output, "commits.txt"),
                                     delim = " ",
                                     col_names = c("commit", "date"))
  
  data_commands <- data_versions %>%
    mutate(
      output_file_name = glue::glue("{folder_output}/{commit}_{date}.{file_ext}",
                                    folder_output = folder_output,
                                    commit = commit,
                                    date = date,
                                    file_ext = fs::path_ext(file_in_repo)),
      command =
        glue::glue(
          'bash -c "cd {repo_local_path} ; git cat-file -p {commit}:{file_path_in_repo} > ../{output_file_name}"',
          repo_local_path = repo_local_path,
          commit = commit,
          file_path_in_repo = file_path_in_repo,
          output_file_name = output_file_name
        )
    )
  
  # If run previously and want to NOT overwrite  (e.g. to save time and just download most recent)
  if(!first_time && !overwrite_all){
    
    previously_run <- tibble(
      output_file_name = fs::dir_ls(folder_output) %>% glue::as_glue()
      )
    
    data_commands <- anti_join(data_commands, previously_run, "output_file_name")
  }
  
  purrr::walk(data_commands$command, system)
  
  if(delete_commits.txt){
    fs::path(folder_output, "commits.txt") %>% 
      fs::file_delete()
  }
  
  if(delete_clone) fs::dir_delete(repo_local_path)
  
  fs::dir_ls(folder_output)
  
}