library(tidyverse)

# Downloading data and getting it into R -----------------------------------


file_url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"

# Download and unzip dataset directory if it doesn't already exist:

if (!dir.exists("dataset")) {
  temp <- tempfile()
  download.file(file_url, temp)
  unzip(temp, exdir = "dataset")
  unlink(temp)
}

# Create named character vector "paths" that contains the paths
# to all the files of interest in the directory. We use str_subset to omit
# the "Inertial Signals" sub-directories and "readme" or "info" files,
# as they will not be needed.  

paths <- list.files("dataset",
                    recursive = TRUE,
                    full.names = TRUE
                    ) %>% str_subset("Inertial|README|info", negate = TRUE)

names(paths) <- basename(paths) %>% str_sub(1,-5)

# Processing --------------------------------------------------------------

# Use read_delim to read each .txt file into a data frame and return a list  
# of the 8 data frames. They are then accessed by e.g. data$features

data <- paths %>%
  map(read_delim, delim = " ", trim_ws = TRUE, col_names = FALSE)

# From the features data frame, we can get the numbers and names of the columns 
# for the variables we need to keep, using str_which and a regular expression:

var_cols <- deframe(data$features) %>%  str_which("(-mean\\(\\))|(-std\\(\\))")

var_names <- deframe(data$features)[var_cols]

# We now join separately the subject, y, and the relevant columns of X for both
# "test" and "train", using bind_cols

test <- bind_cols(data$subject_test, 
                  data$y_test, 
                  select(data$X_test, all_of(var_cols))
)


train <- bind_cols(data$subject_train, 
                  data$y_train, 
                  select(data$X_train, all_of(var_cols))
)

# Then, we combine these two tables into a single "human_activity":

human_activity <- bind_rows(test, train)

# Next, we add column names:

names(human_activity) <- c("Subject", "Activity", var_names)

# Right now every column is a double, but it makes more sense for Subject and
# Activity to be treated as factors:

human_activity <- human_activity %>% mutate(across(1:2, as.factor))

# Lastly, we can use data$activity_labels to replace the numbers in the 
# Activity column with the correct activity name. 

new_factors <- data$activity_labels %>% 
  transmute(Activity = X2 , Code = as.character(X1)) %>%
  deframe() 

human_activity <- human_activity %>% 
  mutate(Activity = fct_recode(Activity, !!!new_factors))

# We are done with the first table, next just group by subject and activity and
# take the means of all the columns:

human_activity_means <- human_activity %>% 
  group_by(Subject, Activity) %>%
  summarize(across(everything(), ~ mean(.x, na.rm = TRUE)))

# We can then export these tidy data sets as .csv:

write_csv(human_activity, "human_activity.csv")

write_csv(human_activity_means, "human_activity_means.csv")

