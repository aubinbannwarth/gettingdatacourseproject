## Prerequisites

We will make use of the **tidyverse** packages, including **readr**,
**dplyr**, **stringr**, and **forcats**, throughout. I invite you to
check out Hadley Wickham’s book [*R For Data
Science*](https://r4ds.had.co.nz/), if you are not familiar with them.

    library(tidyverse)

## The original data set

The original data set is obtained from [this
website](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones),
which includes a description of the data and the experimental procedure.

The actual zipped directory containing all the data is downloaded
[here](https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip).
We can use R to download and unzip the data set, including a check that
we have not already done so!

    file_url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"

    if (!dir.exists("dataset")) {
      temp <- tempfile()
      download.file(file_url, temp)
      unzip(temp, exdir = "dataset")
      unlink(temp)
    }

Let’s begin by creating a character vector, **paths**, of the full paths
to all files in the newly created *dataset* directory by using
**list\_files()**:

    (paths <- list.files("dataset", recursive = TRUE, full.names = TRUE))

    ##  [1] "dataset/UCI HAR Dataset/activity_labels.txt"                         
    ##  [2] "dataset/UCI HAR Dataset/features.txt"                                
    ##  [3] "dataset/UCI HAR Dataset/features_info.txt"                           
    ##  [4] "dataset/UCI HAR Dataset/README.txt"                                  
    ##  [5] "dataset/UCI HAR Dataset/test/Inertial Signals/body_acc_x_test.txt"   
    ##  [6] "dataset/UCI HAR Dataset/test/Inertial Signals/body_acc_y_test.txt"   
    ##  [7] "dataset/UCI HAR Dataset/test/Inertial Signals/body_acc_z_test.txt"   
    ##  [8] "dataset/UCI HAR Dataset/test/Inertial Signals/body_gyro_x_test.txt"  
    ##  [9] "dataset/UCI HAR Dataset/test/Inertial Signals/body_gyro_y_test.txt"  
    ## [10] "dataset/UCI HAR Dataset/test/Inertial Signals/body_gyro_z_test.txt"  
    ## [11] "dataset/UCI HAR Dataset/test/Inertial Signals/total_acc_x_test.txt"  
    ## [12] "dataset/UCI HAR Dataset/test/Inertial Signals/total_acc_y_test.txt"  
    ## [13] "dataset/UCI HAR Dataset/test/Inertial Signals/total_acc_z_test.txt"  
    ## [14] "dataset/UCI HAR Dataset/test/subject_test.txt"                       
    ## [15] "dataset/UCI HAR Dataset/test/X_test.txt"                             
    ## [16] "dataset/UCI HAR Dataset/test/y_test.txt"                             
    ## [17] "dataset/UCI HAR Dataset/train/Inertial Signals/body_acc_x_train.txt" 
    ## [18] "dataset/UCI HAR Dataset/train/Inertial Signals/body_acc_y_train.txt" 
    ## [19] "dataset/UCI HAR Dataset/train/Inertial Signals/body_acc_z_train.txt" 
    ## [20] "dataset/UCI HAR Dataset/train/Inertial Signals/body_gyro_x_train.txt"
    ## [21] "dataset/UCI HAR Dataset/train/Inertial Signals/body_gyro_y_train.txt"
    ## [22] "dataset/UCI HAR Dataset/train/Inertial Signals/body_gyro_z_train.txt"
    ## [23] "dataset/UCI HAR Dataset/train/Inertial Signals/total_acc_x_train.txt"
    ## [24] "dataset/UCI HAR Dataset/train/Inertial Signals/total_acc_y_train.txt"
    ## [25] "dataset/UCI HAR Dataset/train/Inertial Signals/total_acc_z_train.txt"
    ## [26] "dataset/UCI HAR Dataset/train/subject_train.txt"                     
    ## [27] "dataset/UCI HAR Dataset/train/X_train.txt"                           
    ## [28] "dataset/UCI HAR Dataset/train/y_train.txt"

Examination of *README.txt* allows us to understand the roles that these
files play.

For our purposes, we need to know that each of 30 individuals or
**Subjects** performed 6 **Activities**, while wearing a smartphone on
their waist that recorded some kinematic data (such as linear and
angular acceleration components) over some amount of time at a given
sampling rate. The activities range from SITTING to WALKING UPSTAIRS and
are given numbers from 1 to 6 in *activity\_labels.txt*.

The data was split into “train” and “test” groups, presumably for
machine learning applications. This means that there are two sets of
data, corresponding to the */train/* and */test/* sub directories we see
above.

The raw data, which is available in the */Inertial Signals/*
sub-directories of the zipped dataset, is not needed for our purposes.
Rather, we will be interested in the processed data that is in the
*X\_test.txt* and *X\_train.txt* files. Each of these files contains 561
columns corresponding to the **features** (i.e. variables) that were
computed from the raw data. The file *features.txt* lists the variable
names for each column, and can be used to match each column of
*X\_test.txt* or *X\_train.txt* to a descriptive variable name. Using
*features\_info.txt*, one may find additional information about how each
variable is computed, and what the names mean.

An observation (i.e. row in the table) gives the value of each feature
in some “window” of time (see *README.txt* for an exact definition), for
a specific **Subject** and **Activity**, but the values of the
**Subject** and **Activity** variables need to be looked up separately
in the single-column files *subject\_train.txt* and *y\_train.txt*,
respectively. For example, the 5th entry in *subject\_train.txt* gives
the value of the **Subject** variable for the 5th row (observation) of
*X\_train.txt*. After parsing, we will be able to bind the columns in
*subject\_train.txt*, *y\_train.txt* and *X\_train.txt* to get a single
tidy data frame.

Similarly, *X\_test.txt* will need to be combined with
*subject\_test.txt* and *y\_test.txt*.

The training and testing data frames can then be combined row-wise.

Lastly, we note that *activity\_labels.txt* provides a key that matches
the activity numbers used in *y\_train.txt* and *y\_test.txt* with plain
english descriptors of the activities. This will be used to replace the
numbers with relevant labels in the **Activity** column of the final
tidy data set.

For now, let’s use **str\_subset()** to only keep those elements of
**paths** that we are really interested in, by excluding the raw data
and the read me and information files:

    paths <- paths %>% str_subset("Inertial|README|info", negate = TRUE)

We set the names of this new vector equal the base file name, then use
**str\_sub()** to remove the *.txt* extensions:

    names(paths) <- basename(paths) %>% str_sub(1,-5)

This allows us to get the full path to, for example, the *X\_train.txt*
file using:

    paths["X_train"]

    ##                                     X_train 
    ## "dataset/UCI HAR Dataset/train/X_train.txt"

## Reading the relevant data

We may read all 8 files in **paths** at once using the **read\_delim()**
function and mapping it using **map()** onto each entry. Note that we
arrived at the correct parameters for **read\_delim()** by inspecting
some of the *.txt* files using the system viewer:

    data <- paths %>%
      map(read_delim, delim = " ", trim_ws = TRUE, col_names = FALSE)

Each individual data frame (or tibble to be precise, as we are using
**read\_delim()** from the **readr** package) can be accessed within the
list using its name, e.g. 

    data$features

    ## # A tibble: 561 x 2
    ##       X1 X2               
    ##    <dbl> <chr>            
    ##  1     1 tBodyAcc-mean()-X
    ##  2     2 tBodyAcc-mean()-Y
    ##  3     3 tBodyAcc-mean()-Z
    ##  4     4 tBodyAcc-std()-X 
    ##  5     5 tBodyAcc-std()-Y 
    ##  6     6 tBodyAcc-std()-Z 
    ##  7     7 tBodyAcc-mad()-X 
    ##  8     8 tBodyAcc-mad()-Y 
    ##  9     9 tBodyAcc-mad()-Z 
    ## 10    10 tBodyAcc-max()-X 
    ## # ... with 551 more rows

## The new “tidy” data sets

From the 8 data frames in the **data** list, we will now generate two
tidy data sets *human\_activity.txt* and *human\_activity\_means.txt*.

Firstly, we know that we should keep only those variables corresponding
to the means or standard deviations of some quantitites. We also know
from reading *features\_info.txt* that a set of 33 base signals were
computed. For each of these signals, a number of variables were derived,
including the mean and standard deviations. This means we should expect
to select 2x33 = 66 variables to keep in our tidy data set. We achieve
this by noting that the relevant variable names in the **features**
frame will contain the text **-mean()** or **-std()**. Using
**str\_which()** and a regular expression, we can find which of the 561
features is a mean or standard deviation and save the corresponding
column number in a variable, **var\_cols**:

    var_cols <- deframe(data$features) %>%  str_which("(-mean\\(\\))|(-std\\(\\))")

    var_names <- deframe(data$features)[var_cols]

Next, we can bind the **subject\_**, **y\_** and **X\_** data frames
using **bind\_cols()**, for both the training and testing data, while
also keeping only the relevant variables of the **X\_** data frames:

    test <- bind_cols(data$subject_test, 
                      data$y_test, 
                      select(data$X_test, all_of(var_cols))
    )


    train <- bind_cols(data$subject_train, 
                      data$y_train, 
                      select(data$X_train, all_of(var_cols))
    )

We can now finally bind **test** and **train** row-wise into a
**human\_activity** set:

    human_activity <- bind_rows(test, train)

We add column names:

    names(human_activity) <- c("Subject", "Activity", var_names)

Right now, all the columns in **human\_activity** are doubles, but the
first two should be factors:

    human_activity <- human_activity %>% mutate(across(1:2, as.factor))

Lastly, we can use **data$activity\_labels** to replace the numbers in
the **Activity** column with the correct activity name.

    new_factors <- data$activity_labels %>% 
      transmute(Activity = X2, Code = as.character(X1)) %>%
      deframe() 

    human_activity <- human_activity %>% 
      mutate(Activity = fct_recode(Activity, !!!new_factors))

That’s it for the first table which is now tidy with correct variable
names and descriptive activity names. For the second table, we simply
group by **Activity** and **Subject** and take the mean of all the other
columns. As there are 68 columns in **human\_activity**, and 30x6 = 180
combinations of **Activity** and **Subject**, **human\_activity\_means**
will have dimensions 180x68:

    human_activity_means <- human_activity %>% 
      group_by(Subject, Activity) %>%
      summarize(across(everything(), ~ mean(.x, na.rm = TRUE)))

Finally, we can export this now tidy data as *.txt* files:

    write.table(human_activity, "human_activity.txt", row.names = FALSE)

    write.table(human_activity_means, "human_activity_means.txt", row.names = FALSE)

## Summary of data set dimensions and variable names

So we have two tidy data frames, **human\_activity** and
**human\_activity\_means**. Their dimensions are given by:

    dim(human_activity)

    ## [1] 10299    68

    dim(human_activity_means)

    ## [1] 180  68

We see that the **human\_activity** frame has successfully captured all
10299 observations in the original dataset, which is the count that was
listed on the webpage. **human\_activity\_means** has 180=30x6 as
expected.

The 68 variable names are the same in both tables, and are listed below
for reference:

    names(human_activity)

    ##  [1] "Subject"                     "Activity"                   
    ##  [3] "tBodyAcc-mean()-X"           "tBodyAcc-mean()-Y"          
    ##  [5] "tBodyAcc-mean()-Z"           "tBodyAcc-std()-X"           
    ##  [7] "tBodyAcc-std()-Y"            "tBodyAcc-std()-Z"           
    ##  [9] "tGravityAcc-mean()-X"        "tGravityAcc-mean()-Y"       
    ## [11] "tGravityAcc-mean()-Z"        "tGravityAcc-std()-X"        
    ## [13] "tGravityAcc-std()-Y"         "tGravityAcc-std()-Z"        
    ## [15] "tBodyAccJerk-mean()-X"       "tBodyAccJerk-mean()-Y"      
    ## [17] "tBodyAccJerk-mean()-Z"       "tBodyAccJerk-std()-X"       
    ## [19] "tBodyAccJerk-std()-Y"        "tBodyAccJerk-std()-Z"       
    ## [21] "tBodyGyro-mean()-X"          "tBodyGyro-mean()-Y"         
    ## [23] "tBodyGyro-mean()-Z"          "tBodyGyro-std()-X"          
    ## [25] "tBodyGyro-std()-Y"           "tBodyGyro-std()-Z"          
    ## [27] "tBodyGyroJerk-mean()-X"      "tBodyGyroJerk-mean()-Y"     
    ## [29] "tBodyGyroJerk-mean()-Z"      "tBodyGyroJerk-std()-X"      
    ## [31] "tBodyGyroJerk-std()-Y"       "tBodyGyroJerk-std()-Z"      
    ## [33] "tBodyAccMag-mean()"          "tBodyAccMag-std()"          
    ## [35] "tGravityAccMag-mean()"       "tGravityAccMag-std()"       
    ## [37] "tBodyAccJerkMag-mean()"      "tBodyAccJerkMag-std()"      
    ## [39] "tBodyGyroMag-mean()"         "tBodyGyroMag-std()"         
    ## [41] "tBodyGyroJerkMag-mean()"     "tBodyGyroJerkMag-std()"     
    ## [43] "fBodyAcc-mean()-X"           "fBodyAcc-mean()-Y"          
    ## [45] "fBodyAcc-mean()-Z"           "fBodyAcc-std()-X"           
    ## [47] "fBodyAcc-std()-Y"            "fBodyAcc-std()-Z"           
    ## [49] "fBodyAccJerk-mean()-X"       "fBodyAccJerk-mean()-Y"      
    ## [51] "fBodyAccJerk-mean()-Z"       "fBodyAccJerk-std()-X"       
    ## [53] "fBodyAccJerk-std()-Y"        "fBodyAccJerk-std()-Z"       
    ## [55] "fBodyGyro-mean()-X"          "fBodyGyro-mean()-Y"         
    ## [57] "fBodyGyro-mean()-Z"          "fBodyGyro-std()-X"          
    ## [59] "fBodyGyro-std()-Y"           "fBodyGyro-std()-Z"          
    ## [61] "fBodyAccMag-mean()"          "fBodyAccMag-std()"          
    ## [63] "fBodyBodyAccJerkMag-mean()"  "fBodyBodyAccJerkMag-std()"  
    ## [65] "fBodyBodyGyroMag-mean()"     "fBodyBodyGyroMag-std()"     
    ## [67] "fBodyBodyGyroJerkMag-mean()" "fBodyBodyGyroJerkMag-std()"

The **Subject** and **Activity** columns represent the human subject
(numbered 1 to 30) and the activity that the observation corresponds to.
The next 66 variables are unchanged from their meaning in the original
*features\_info.txt*, where more information can be found about their
meaning. The only difference in **human\_activity\_means** is that the
values listed in these columns are the means of the values in
**human\_activity**, grouped by **Subject** and **Activity**.
