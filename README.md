# Name of App *(Give your app a short and informative title. Please adhere to our convention of Title Case without hyphens (e.g. My New App))*

MoveApps

Github repository: *github.com/yourAccount/Name-of-App* *(provide the link to the repository where the code of the App can be found)*

*(Note: all text in italics are instructions for filling out this template. Please replace or delete them before publishing your App.)*

*(Optional, but very helpful for Users: add here a screenshot or example figure of a typical result of the App, e.g. a plot, a map or a table. Save the image in the repository (e.g. in a folder `documentation/`) and include it with:*
<p align="center">
  <img alt="Screenshot of the Apps UI" src="documentation/screenshot_UI.png" width="600">
</p>
*)*

## Description
*Enter here the short description of the App that might also be used when filling out the description during App submission to MoveApps. This text is directly presented to Users that look through the list of Apps when compiling Workflows.*

## Documentation
*Enter here a detailed description of your App. What is it intended to be used for. Which steps of analyses are performed and how. Please be explicit about any detail that is important for use and understanding of the App and its outcomes. You might also refer to the sections below.*

### Application scope
#### Generality of App usability
*State here if the App was developed for a specific species, taxon or taxonomic group, or to answer a specific question. How might it influence the scope and utility of the App. This information will help the user to understand why the App might be producing no or odd results.*

*Examples:*

This App was developed for any taxonomic group. 

This App was developed using data of birds. 

This App was developed using data of red deer. 

This App was developed to identify kill sites, but can probably be used to identify any kind of location clusters like nests, dens or drinking holes.

#### Required data properties
*State here the required and/or optimal data properties for this App to perform properly.*

The App is designed to work with any type of GPS location data, provided that the tracking device is also equipped with an accelerometer capable of recording tri-axial acceleration data (X: sway, Y: surge, and Z: heave).

### Input type
The App automatically retrieves GPS location and tri-axial accelerometer data from Movebank using the `move::getMovebank` and `move::getMovebankData` functions. No manual data upload is required.

Input type: Movebank study data (GPS and accelerometer data).

### Output type
The App generates several intermediate CSV and Excel files during processing, but its primary output is a CSV file named `original_df_annotated_.csv`, containing the original GPS data annotated with the predicted breeding-related information.

Output type: CSV (`.csv`).

Final output file: `original_df_annotated_.csv`.

### Artefacts
`all_data_movebank.csv`: CSV file containing raw GPS and accelerometer data downloaded from Movebank in long format, along with all additional metadata and associated data columns.

`gps_raw_data.csv`: CSV file containing GPS data downloaded from Movebank in long format, along with only the essential additional metadata and associated data columns ("individual_local_identifier", "timestamp", "location_long", "location_lat", "sex", "device_type").

`gps_raw_data.csv`: CSV file containing accelerometer data downloaded from Movebank in wide format, one row per accelerometer burst, along with only the essential additional metadata and associated data columns ("individual_local_identifier", "timestamp", "location_long", "location_lat", "acceleration_raw_x", "acceleration_raw_y", "acceleration_raw_z", "sex","device_type").

`nest_df.csv`: CSV file containing the estimated nest coordinates (latitude and longitude) for each bird-year combination, identified using the `nestR` package.

`gps_.csv`: CSV file containing GPS data after applying quality and spatial filters. Includes only individual-year combinations meeting the minimum daily GPS fix and accelerometer bout requirements, with GPS fixes restricted to locations within the defined nest buffer.

`acc_.csv`: CSV file containing accelerometer data after applying quality and spatial filters. Includes only individual-year combinations meeting the minimum daily GPS fix and accelerometer bout requirements, with bouts restricted to locations within the defined nest buffer.

`gps_nest_status_.csv`: CSV file containing GPS data after applying (only) quality filters, retaining only individual-year combinations that meet the minimum daily GPS fix and accelerometer bout requirements. Includes an additional column classifying each GPS fix as `at_nest` (within the defined nest buffer) or `not_nest` (outside the nest buffer). 

`behav_classif_sitting_non_sitting.csv`: CSV file containing accelerometer data after applying quality and spatial filters, retaining only individual-year combinations that meet the minimum daily GPS fix and accelerometer bout requirements, with bouts restricted to locations within the defined nest buffer. Includes additional columns with summary statistics calculated from the tri-axial accelerometer data, used as predictors in the posture Random Forest classification. Also contains the Random Forest posture prediction for each bout (`sitting` or `non_sitting`) and its associated confidence score.

`daily_sitting_prop_.csv`: CSV file containing daily data, with one row per day, summarising the proportion of accelerometer bouts within the nest buffer classified as `sitting` by the posture Random Forest model for each bird-day combination. 

`daily_nest_use_.csv`: CSV file containing daily data, with one row per individual-day combination, summarising the proportion of GPS fixes recorded within the defined nest buffer.

`incubation_prediction_.csv`: CSV file containing daily data, with one row per individual-day combination. Includes all predictor variables used by the breeding behaviour Random Forest model, as well as the model's predictions classifying each bird-day as `incubation` or `non_incubation`, with an associated confidence score for each prediction.

`laying_hatching_predictions_daily_.xlsx`: Excel file containing daily data, with one row per individual-day combination. Includes all predictor variables used by the breeding behaviour Random Forest model, as well as the model's predictions classifying each bird-day as `incubation` or `non_incubation`, with an associated confidence score for each prediction. Also includes additional columns with the predicted laying and hatching dates, incubation period duration (days), and breeding outcome (`single_clutch`, `second_clutch`, `no_breeding`, `failed_breeding`, or `unknown`).

`laying_hatching_predictions_summary_.xlsx`: Excel file containing summary data, with one row per individual-year combination. Includes the predicted laying and hatching dates, incubation period duration (days), and breeding outcome (`single_clutch`, `second_clutch`, `no_breeding`, `failed_breeding`, or `unknown`).

`original_df_annotated_.csv`: CSV file derived from the original input dataset (`all_data_movebank.csv`), filtered to retain only individual-year combinations for which at least one breeding date (laying or hatching) was successfully predicted. Includes additional columns with the predicted laying and hatching dates, incubation period duration (days), and breeding outcome (`single_clutch`, `second_clutch`, `no_breeding`, `failed_breeding`, or `unknown`). This is the main output of the App.

### Settings 
#### Movebank Settings
`my_username` (my_username): Your Movebank username as a characater string. Unit: NA (dimensionless). Default: NA.

`my_password` (my_password): Your Movebank password as a characater string. Unit: NA (dimensionless). Default: NA.

`study_id` (study_id): Numeric Movebank study ID identifying the study from which the data will be imported. Unit: NA (dimensionless). Default: NA.

`time_start` (time_start): Earliest date and time from which GPS data will be downloaded. Format: yyyy-mm-dd hh:mm:ss (POSIXct), time zone: UTC. Default: NA.

`time_end` (time_end): Latest date and time from which GPS data will be downloaded. Format: yyyy-mm-dd hh:mm:ss (POSIXct), time zone: UTC. Default: NA.

#### NestR Settings
`sea_start` (sea_start1): Earliest date from which to search for candidate nest locations, corresponding to the start of the period of intensive nest use for the target species. Format: character string ("mm-dd"). Default: NA.

`sea_end` (sea_end1): Latest date from which to search for candidate nest locations, corresponding to the start of the period of intensive nest use for the target species. Format: character string ("mm-dd"). Default: NA.

`nest_cycle` (nest_cycle1): Expected duration of the period of intensive nest use for the target species. Unit: Days (d). Default: NA.

`buffer` (buffer1): Radius of the circular buffer around a candidate nest location within which GPS fixes are classified as being at the nest. Unit: Meters (m). Default: NA.

`min_pts` (min_pts1): "Minimum number of GPS fixes within a buffer required for its centroid to be considered a candidate nest location. Unit: Count (N). Default: NA.

`min_d_fix` (min_d_fix1): Minimum number of GPS fixes per day required at a candidate nest location. Unit: Count (N). Default: NA.

`min_consec` (min_consec1): Minimum number of consecutive days a bird must meet the nest-site criteria for a location to be identified as a nest. Unit: Days (d). Default: NA.

`min_top_att` (min_top_att1): Minimum percentage of GPS fixes at a candidate location on the day with the highest attendance required for that location to be considered a potential nest. Unit: Percentage (%). Default: NA.

`min_days_att` (min_days_att1): Minimum percentage of days on which a location must be visited, between the first and last recorded visit, for it to be considered a potential nest. Unit: Percentage (%). Default: NA.

#### Data Filter Settings
`month_start` (month_start): Earliest month to retain GPS data, corresponding to the start of the active breeding season. Specified as a numeric value (1–12). Unit: month. Default: NA.

`month_end` (month_end): Latest month to retain GPS data, corresponding to the end of the active breeding season. Specified as a numeric value (1–12). Unit: month. Default: NA.

`max_frequency` (max_frequency): Minimum time interval between consecutive GPS fixes. Unit: Minutes. Default: NA.

`min_n_fix_day` (min_n_fix_day): Minimum number of GPS fixes required per bird-day for inclusion in the analysis. Unit: Count (N). Default: NA.

`nest_radius` (nest_radius): Radius around the nest within which GPS fixes are classified as 'at the nest'. Unit: Meters (m). Default: NA.

`min_acc_bouts_day` (min_acc_bouts_day): Minimum number of accelerometer bouts required per bird-day for inclusion in the analysis. Unit: Count (N). Default: NA.

#### Breeding and Incubation Classification Settings
`laying_threshold` (laying_threshold): Probability threshold above which the GAM-smoothed incubation probability must rise for the first time to estimate the laying date. Unit: Probability (0-1). Default: NA.

`hatching_threshold` (laying_threshold): Probability threshold below which the GAM-smoothed incubation probability must fall for the last time to estimate the hatching date. Unit: Probability (0-1). Default: NA.

`min_inc_per_1clutch` (min_inc_per_1clutch): Minimum incubation period duration for a single clutch case in the target species. Unit: Days (d). Default: NA.

`min_inc_per_2clutch` (min_inc_per_2clutch): Minimum incubation period duration for a second clutch case in the target species. Unit: Days (d). Default: NA.

### Changes in output data
*Specify here how and if the App modifies the input data. Describe clearly what e.g. each additional column means.*

*Examples:*

The App adds to the input data the columns `Max_dist` and `Avg_dist`. They contain the maximum distance to the provided focal location and the average distance to it over all locations. 

The App filters the input data as selected by the user. 

The output data is the outcome of the model applied to the input data. 

The input data remains unchanged.

### Errors and null handling
*Please describe here the most common errors of the App: how they occur and the best ways of solving them. You can also indicate for settings, as well as for the input data, which behaviour the App is supposed to show in case of errors or NULL values/input, including possible errors that can happen if settings/parameters are improperly set. Add here also any other important information that you find the User should be aware of.*

*Examples:*

**Setting `radius`:** If no radius AND no duration are given, the input data set is returned with a warning. If no radius is given (NULL), but a duration is defined then a default radius of 1000m = 1km is set. 

**Input data:** If the input data contain fewer than 3 locations per track, the App stops with an error message stating which tracks are affected.

**Common error:** If the App is used on data with a very low fix rate, no resting sites are found and the App returns an empty data set. Adapt the settings `radius` and `duration` to the resolution of your data.

### Technical details
*Optional, but recommended. Summarize here how the App works "under the hood", so that Users and developers can get a quick idea of the methods, dependencies and assumptions without having to read the code. Keep it short (a few sentences or bullet points) and mention only what is not already obvious from the sections above.*

*Suggested points to cover:*

- *The main library/package(s) the core calculation relies on, ideally naming the central function(s) (e.g. `move2`, `sf`, `amt`, `ctmm`, `lme4`).*
- *The method or algorithm applied, and the reference/publication it is based on, if any.*
- *Assumptions made in the code (e.g. the locations are assumed to be independent).*
- *The level at which the data are processed (e.g. per track/individual, per track and year, on the whole data set at once).*
- *Anything relevant for performance (e.g. runtime or memory increases strongly with the number of locations, parallelization).*
- *Known simplifications or limitations of the implementation.*

