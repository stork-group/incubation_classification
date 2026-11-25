# White Stork Incubation Phenology Predictor

MoveApps

Github repository: https://github.com/stork-group/incubation_classification/

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
This App uses GPS and tri-axial accelerometer data retrieved directly from Movebank to estimate breeding parameters at the individual-year level, including egg-laying and hatching dates, incubation period duration and breeding outcome.

The App was developed and its classification models trained using White Stork data. Although its methodology may be applicable to other bird species, differences in behaviour, breeding ecology and tracking-device configurations may affect model performance. Its application to other species should therefore be approached with caution, and predictions should be independently validated whenever possible.

### Application scope
#### Generality of App usability
This App estimates laying and hatching dates of birds using GPS and accelerometer data. The App was developed and trained using data from White Stork. However, its methodology may be applicable to closely related taxa, such as other stork species (Ciconiidae and potentially other Ciconiiformes), or to more distantly related species with similar behaviour, body size and morphology, such as herons and flamingos. Nevertheless, its application to non-stork species should be approached with caution, as differences in behaviour, morphology and breeding ecology may affect model performance. Predictions should therefore be critically evaluated and independently validated whenever possible.

To facilitate adaptation to other species, the App is accompanied by scripts to develop and train species-specific posture and breeding behaviour Random Forest models, provided that an appropriate training dataset is available for the target species. This allows users to retrain the classification models using species-specific data, potentially extending the App's applicability beyond White Storks.

#### Required data properties
The App is designed to work with any type of GPS location data, provided that the tracking device is also equipped with an accelerometer capable of recording tri-axial acceleration data (X: sway, Y: surge, and Z: heave).

### Input type
move2_loc

### Output type
move2_loc

### Artefacts
`nest_df.csv`: CSV file containing the estimated nest coordinates (latitude and longitude) for each bird-year combination, identified using the `nestR` package.

`laying_hatching_predictions_daily_.xlsx`: Excel file containing daily data, with one row per individual-day combination. Includes all predictor variables used by the breeding behaviour Random Forest model, as well as the model's predictions classifying each bird-day as `incubation` or `non_incubation`, with an associated confidence score for each prediction. Also includes additional columns with the predicted laying and hatching dates, incubation period duration (days), and breeding outcome (`single_clutch`, `second_clutch`, `no_breeding`, `failed_breeding`, or `unclassified breeding`).

`laying_hatching_predictions_summary_.xlsx`: Excel file containing summary data, with one row per individual-year combination. Includes the predicted laying and hatching dates, incubation period duration (days), and breeding outcome (`single_clutch`, `second_clutch`, `no_breeding`, `failed_breeding`, or `unclassified breeding`).

`original_df_annotated_.csv`: CSV file derived from the original input dataset (`all_data_movebank.csv`), filtered to retain only individual-year combinations for which at least one breeding date (laying or hatching) was successfully predicted. Includes additional columns with the predicted laying and hatching dates, incubation period duration (days), and breeding outcome (`single_clutch`, `second_clutch`, `no_breeding`, `failed_breeding`, or `unclassified breeding`). This is the main output of the App.

### Settings 

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
The App filters the input data to retain only individual-year combinations for which at least one breeding date (laying or hatching) was successfully predicted. It also adds columns with the predicted laying and hatching dates, incubation period duration (days), and breeding outcome (`single_clutch`, `second_clutch`, `no_breeding`, `failed_breeding`, or `unclassified breeding`).

### Errors and null handling
**Settings:** All settings must be properly defined before running the App. If any required setting is missing or left undefined, the App will stop and generate an error message indicating where the issue occured. The location of the error message within the script depends on which setting has not been specified.

**Input data:** If the input data contain only tracks with fewer than 19 GPS locations per day and/or fewer than 5 accelerometer bouts per day, the App will stop running and display an error message.

### Technical details
The App follows a multi-step analytical workflow combining GPS-derived nest-use information, accelerometer-based behavioural classification using machine learning algorithms and statistical modelling to estimate breeding parameters.

**Nest identification:** Nest locations are identified from GPS tracking data using the nestR package (`find_nests`). Nest detection is performed separately for each individual and year, using user-defined parameters such as the breeding season, nest-use duration and spatial buffer. GPS data are temporally subsampled to a maximum frequency of one location every 20 minutes before nest identification to reduce computational requirements. When multiple candidate nests are identified, the most frequently and consistently visited location is selected.

**Data preparation and filtering:** GPS and accelerometer records are filtered according to user-defined temporal, spatial and sampling-frequency criteria. GPS locations are used to determine nest attendance, while accelerometer records are organised into 9-second bouts. Only complete bouts are retained, and a set of statistical features describing acceleration along the three axes (X, Y and Z) is extracted for subsequent behavioural classification. 

**Behavioural classification:** Two pre-trained Random Forest models are applied sequentially. The first model classifies accelerometer bouts as lying or non-lying, using raw acceleration measurements and derived statistical features. The resulting behavioural classifications are aggregated into daily proportions of lying behaviour. The second model classifies daily behavioural patterns as incubating or non-incubating, using daily sitting proportions, nest attendance, their temporal trends, and additional individual-level variables, including sex and tag type. Both models also provide prediction confidence scores, which are retained for subsequent analyses. The Random Forest models are loaded from pre-trained model files and are not trained within the App.

**Breeding date estimation:** A Generalized Additive Model (GAM), implemented using the mgcv package (`gam`), is fitted separately for each individual-year combination to model the daily probability of incubation. The model uses a binomial distribution and a penalised smooth function of time, with observations weighted according to their Random Forest classification confidence scores. Egg-laying and hatching dates are inferred from the resulting predicted probability curve using user-defined thresholds. Laying is estimated as the first upward crossing of the laying probability threshold, whereas hatching is estimated as the last downward crossing of the hatching probability threshold.

**Incubation duration and breeding outcome:** Incubation period duration is calculated as the number of days between the estimated laying and hatching dates. Breeding outcomes are subsequently classified using user-defined duration thresholds, distinguishing between single clutches, second clutches, failed breeding and no breeding. Individual-year combinations for which only one of the two dates can be estimated are classified as unclassified breeding.

**Implementation and dependencies:** The workflow is implemented in R and relies primarily on the move, nestR, tidymodels, ranger, data.table, dplyr, slider and mgcv packages, alongside additional packages for data manipulation and statistical calculations. The workflow processes data separately for each individual and breeding year, although some intermediate datasets are handled jointly. Computational requirements depend on the volume of tracking data and the number of individuals and years analysed. Temporal subsampling, data filtering and intermediate file storage are used to reduce memory requirements and facilitate processing.

**Assumptions and limitations:** The accuracy of the estimates depends on the availability and quality of GPS and accelerometer data, the correct identification of nest locations, and the applicability of the pre-trained RF models to the input data. In particular, differences in species, tag manufacturers, accelerometer sampling configurations and breeding behaviour may affect model performance. The GAM estimates breeding dates indirectly from predicted incubation behaviour rather than from direct observations of reproductive events. Consequently, probability thresholds and incubation duration criteria should be adapted and, where possible, validated against independent observations for the target species. Individual-year combinations with insufficient observations to fit the GAM are not assigned predicted breeding dates.
