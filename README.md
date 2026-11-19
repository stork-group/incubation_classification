# White Stork Incubation Phenology Predictor

MoveApps

Github repository: *github.com/yourAccount/Name-of-App* *(provide the link to the repository where the code of the App can be found)*

*(Note: all text in italics are instructions for filling out this template. Please replace or delete them before publishing your App.)*

*(Optional, but very helpful for Users: add here a screenshot or example figure of a typical result of the App, e.g. a plot, a map or a table. Save the image in the repository (e.g. in a folder `documentation/`) and include it with:*
<p align="center">
  <img alt="Screenshot of the Apps UI" src="documentation/screenshot_UI.png" width="600">
</p>
*)*

## Description
This Move App allows users to estimate key breeding parameters in birds using GPS and accelerometer tracking data. Specifically, it estimates egg-laying and hatching dates, incubation period duration, and breeding outcomes, including single clutch, second clutch, failed breeding and no breeding.

The App was developed and validated using data from White Stork (*Ciconia ciconia*), but its methodology may be applicable to other bird species with suitable tracking data. It uses both GPS and accelerometer data as input, which can be downloaded directly from Movebank. The estimation process combines machine-learning and statistical approaches to identify breeding-related behaviours and infer reproductive events from animal movement and activity patterns.

The App is primarily intended for researchers and conservation practitioners interested in studying breeding phenology, reproductive performance, and animal movement ecology. By providing estimates of key reproductive parameters from remotely collected tracking data, it offers a tool for investigating breeding behaviour and reproductive outcomes at the individual level, potentially reducing the need for intensive field monitoring.

## Documentation
*Enter here a detailed description of your App. What is it intended to be used for. Which steps of analyses are performed and how. Please be explicit about any detail that is important for use and understanding of the App and its outcomes. You might also refer to the sections below.*

### Application scope
#### Generality of App usability
This App estimates laying and hatching dates of birds using GPS and accelerometer data. The App was developed and trained using data from White Stork. However, its methodology may be applicable to closely related taxa, such as other stork species (Ciconiidae and potentially other Ciconiiformes), or to more distantly related species with similar behaviour, body size and morphology, such as herons and flamingos. Nevertheless, its application to non-stork species should be approached with caution, as differences in behaviour, morphology and breeding ecology may affect model performance. Predictions should therefore be critically evaluated and independently validated whenever possible.

To facilitate adaptation to other species, the App is accompanied by scripts to develop and train species-specific posture and breeding behaviour Random Forest models, provided that an appropriate training dataset is available for the target species. This allows users to retrain the classification models using species-specific data, potentially extending the App's applicability beyond White Storks.

#### Required data properties
The App is designed to work with any type of GPS location data, provided that the tracking device is also equipped with an accelerometer capable of recording tri-axial acceleration data (X: sway, Y: surge, and Z: heave).

### Input type
The App automatically retrieves GPS location and tri-axial accelerometer data from Movebank using the `move::getMovebank` and `move::getMovebankData` functions. No manual data upload is required.

Input type: Movebank study data (GPS and accelerometer data).

### Output type
The App generates several intermediate CSV and Excel files during processing, but its primary output is a CSV file named `original_df_annotated_.csv`, containing the original GPS data annotated with the predicted breeding-related information.

Output type: CSV (`.csv`).

Final output file: `original_df_annotated_.csv`.

### Artefacts
`nest_df.csv`: CSV file containing the estimated nest coordinates (latitude and longitude) for each bird-year combination, identified using the `nestR` package.

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
The App filters the input data to retain only individual-year combinations for which at least one breeding date (laying or hatching) was successfully predicted. It also adds columns with the predicted laying and hatching dates, incubation period duration (days), and breeding outcome (`single_clutch`, `second_clutch`, `no_breeding`, `failed_breeding`, or `unknown`).

### Errors and null handling
*Please describe here the most common errors of the App: how they occur and the best ways of solving them. You can also indicate for settings, as well as for the input data, which behaviour the App is supposed to show in case of errors or NULL values/input, including possible errors that can happen if settings/parameters are improperly set. Add here also any other important information that you find the User should be aware of.*

**Settings:** All settings must be properly defined before running the App. If any required setting is missing or left undefined, the App will stop and generate an error message indicating where the issue occured. The location of the error message within the script depends on which setting has not been specified.

**Input data:** If the input data contain only tracks with fewer than 19 GPS locations per day and/or fewer than 5 accelerometer bouts per day, the App will stop running and display an error message.

### Technical details
*Optional, but recommended. Summarize here how the App works "under the hood", so that Users and developers can get a quick idea of the methods, dependencies and assumptions without having to read the code. Keep it short (a few sentences or bullet points) and mention only what is not already obvious from the sections above.*

*Suggested points to cover:*

- *The main library/package(s) the core calculation relies on, ideally naming the central function(s) (e.g. `move2`, `sf`, `amt`, `ctmm`, `lme4`).*
- *The method or algorithm applied, and the reference/publication it is based on, if any.*
- *Assumptions made in the code (e.g. the locations are assumed to be independent).*
- *The level at which the data are processed (e.g. per track/individual, per track and year, on the whole data set at once).*
- *Anything relevant for performance (e.g. runtime or memory increases strongly with the number of locations, parallelization).*
- *Known simplifications or limitations of the implementation.*

