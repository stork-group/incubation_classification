library(moveapps)
library(ggnewscale)
library(tidymodels)
library(dplyr)
library(moments)
library(ranger)
library(parsnip)
library(caret)
library(zoo)
library(readxl)
library(writexl)
library(tidyr)
library(randomForest)
library(slider)
library(ggplot2)
library(rsample)
library(tidyverse)
library(data.table)
library(mgcv)
library(tibble)
library(move2)
library(sf)
library(nestR)

rFunction <- function(data,
                      # time_start = "2022-01-01 00:00:00",
                      # time_end = "2026-09-30 23:59:59",
                      sea_start1 = "03-01",
                      sea_end1 = "05-31",
                      nest_cycle1 = 35,
                      buffer1 = 20,
                      min_pts1 = 2,
                      min_d_fix1 = 19,
                      min_consec1 = 2,
                      min_top_att1 = 1,
                      min_days_att1 = 1,
                      month_start = 2,
                      month_end = 6,
                      max_frequency = 10,
                      min_n_fix_day = 19,
                      nest_radius = 20,
                      min_acc_bouts_day = 5,
                      laying_threshold = 0.1,
                      hatching_threshold = 0.95,
                      min_inc_per_1clutch = 30,
                      min_inc_per_2clutch = 44,
                      filterData = FALSE, ...) {
  logger.info("Starting breeding date prediction workflow...")

  # Convert the move2 object into a standard data frame
  all_data_df <- as.data.frame(data)

  # Ensure standard identifier and timestamp columns are mapped correctly
  all_data_df$individual_local_identifier <- move2::mt_track_id(data)
  all_data_df$timestamp <- move2::mt_time(data)

  # Extract spatial coordinates from the move2 geometry column
  coords <- sf::st_coordinates(data)
  all_data_df$location_long <- coords[, 1]
  all_data_df$location_lat <- coords[, 2]

  # Extract track-level metadata (like sex) from track data table
  track_meta <- move2::mt_track_data(data)
  track_id_col <- move2::mt_track_id_column(data)
  if ("sex" %in% names(track_meta)) {
    all_data_df$sex <- track_meta$sex[match(all_data_df$individual_local_identifier, track_meta[[track_id_col]])]
  } else if (!"sex" %in% names(all_data_df)) {
    all_data_df$sex <- NA
  }

  if (!"device_type" %in% names(all_data_df)) {
    all_data_df$device_type <- "Unknown"
  }

  # Split cleanly into your required df_gps and df.acc dataframes
  df_gps <- all_data_df[, c("individual_local_identifier", "timestamp", "location_long", "location_lat", "sex", "device_type")]

  df.acc <- all_data_df[, intersect(
    c(
      "individual_local_identifier", "timestamp", "location_long", "location_lat",
      "acceleration_raw_x", "acceleration_raw_y", "acceleration_raw_z", "sex", "device_type"
    ),
    names(all_data_df)
  )]

  #Checks if it has acceleration data
  acc_cols <- c("acceleration_raw_x", "acceleration_raw_y", "acceleration_raw_z")
  has_acc_cols <- all(acc_cols %in% names(all_data_df))
  has_non_na_acc <- has_acc_cols && any(complete.cases(all_data_df[, acc_cols, drop = FALSE]))

  if (!has_acc_cols || !has_non_na_acc || nrow(df.acc) == 0) {
    logger.warn("No valid acceleration data found in input object. Returning original data object without running ACC/incubation models.")
	if (filterData) {
		logger.warn("Filtered dataset has 0 rows. Returning empty move2 object.")
		return(data[0, ])
	} else {
		return(data)
	}
  }

  logger.info(paste0("Successfully extracted ", nrow(df_gps), " GPS rows and ", nrow(df.acc), " acceleration rows directly from upstream move2 object."))


  # Detect raw bursts (per individual)
  df.acc <- df.acc |>
    arrange(individual_local_identifier, timestamp) |>
    group_by(individual_local_identifier) |>
    mutate(
      lag_time_diff = as.numeric(difftime(timestamp, lag(timestamp), units = "secs")),
      new_burst = is.na(lag_time_diff) | lag_time_diff > 1 | lag_time_diff < 0
    ) |>
    ungroup() |>
    mutate(raw_burst = cumsum(new_burst))

  # Split raw bursts into chunks of 9, keep complete chunks only
  # Keep bursts of 9 seconds, trim 10 seconds into 9 by dropping the last ACC,
  # and turn continuous sampling into discrete bursts of 9 seconds.
  # Remove all bursts with fewer than 9.
  df.acc.all <- df.acc |>
    group_by(raw_burst) |>
    mutate(chunk = (row_number() - 1) %/% 9) |>
    group_by(raw_burst, chunk) |>
    mutate(
      n = n(),
      burst = cur_group_id()
    ) |>
    ungroup() |>
    filter(n == 9) |>
    select(-new_burst, -raw_burst, -chunk)

  # Make the DF wide
  df.acc.all <- df.acc.all |>
    arrange(burst, timestamp) |>
    group_by(burst) |>
    mutate(burst_pos = row_number()) |>
    ungroup()

  names(df.acc.all)

  df.acc.wide <- df.acc.all |>
    pivot_wider(
      id_cols = c(individual_local_identifier, burst, sex, device_type),
      names_from = burst_pos,
      values_from = c(
        acceleration_raw_x, acceleration_raw_y,
        acceleration_raw_z, location_long, location_lat
      ),
      names_glue = "{.value}_{burst_pos}"
    )

  # Add timestamp to wide database
  names(df.acc.all)
  df.acc.first <- df.acc.all[which(df.acc.all$burst_pos == 1), c(1, 12, 2)]
  str(df.acc.first)
  str(df.acc.wide)
  df.acc.wide.ok <- df.acc.wide %>%
    left_join(
      df.acc.first %>%
        dplyr::select(
          individual_local_identifier,
          burst,
          timestamp
        ),
      by = c("individual_local_identifier", "burst")
    )

  # data.table::fwrite(df_gps, "gps_raw_data.csv", row.names = FALSE)
  # data.table::fwrite(df.acc.wide.ok, "acc_raw_data.csv", row.names = FALSE)


  ###############################################################################################
  #                                  Database preparation                                       #
  ###############################################################################################


  df_acc <- df.acc.wide.ok

  #Checks if it has the needed acceleration data
  if (nrow(df_acc) == 0) {
	logger.warn("No complete 9-sample acceleration bursts found. Returning original data object.")
	if (filterData) {
		logger.warn("Filtered dataset has 0 rows. Returning empty move2 object.")
		return(data[0, ])
	} else {
		return(data)
	}
  }
  ############################# NestR to get nest coordinates
  ############################################################

  # Create input df for nestR
  nest_input <- df_gps[, c(
    "individual_local_identifier",
    "timestamp",
    "location_long",
    "location_lat"
  )]

  # Match names to nestR input needs
  names(nest_input)[1] <- "burst"
  names(nest_input)[2] <- "date"
  names(nest_input)[3] <- "long"
  names(nest_input)[4] <- "lat"

  # Turn dates into dates
  nest_input$date <- as.POSIXct(nest_input$date,
    format = "%Y-%m-%d %H:%M:%S",
    tz = "UTC"
  )
  # Remove NAs
  nest_input <- nest_input[complete.cases(nest_input), ]

  # Reduce database size (1 fix every 20 mins)
  nest_input_reduced <- nest_input %>%
    arrange(burst, date) %>%
    mutate(
      time_bin = as.POSIXct(
        floor(as.numeric(date) / 1200) * 1200,
        origin = "1970-01-01",
        tz = "UTC"
      )
    ) %>%
    distinct(burst, time_bin, .keep_all = TRUE) %>%
    select(-time_bin)

  # Check data
  nest_input_reduced %>%
    count(burst, name = "n_fixes") %>%
    arrange(desc(n_fixes))

  # Turn df into chunks (ID -> ID x Year) to run separately
  nest_input_reduced <- nest_input_reduced %>%
    mutate(
      year = lubridate::year(date),
      burst = paste0(burst, "_", year)
    )

  # Run loop of nestR for each ID x Year and join everything
  bursts <- split(nest_input_reduced, nest_input_reduced$burst)
  nest_results <- lapply(names(bursts), function(b) {
    message("Processing: ", b)
    tryCatch(
      {
        find_nests(
          gps_data = bursts[[b]],
          sea_start = sea_start1,
          sea_end = sea_end1,
          nest_cycle = nest_cycle1,
          buffer = buffer1,
          min_pts = min_pts1,
          min_d_fix = min_d_fix1,
          min_consec = min_consec1,
          min_top_att = min_top_att1,
          min_days_att = min_days_att1,
          discard_overlapping = FALSE
        )
      },
      error = function(e) {
        message("Failed: ", b, " | ", conditionMessage(e))
        NULL
      }
    )
  })
  names(nest_results) <- names(bursts)

  # Join results in one object
  nest_locations <- bind_rows(
    lapply(nest_results, function(x) {
      if (is.null(x)) {
        return(NULL)
      }
      x$nests
    })
  )

  # Inspect results
  nest_locations %>%
    arrange(burst, desc(tot_vis)) %>%
    select(
      burst, long, lat,
      tot_vis, days_vis, consec_days,
      perc_days_vis, perc_top_vis
    )

  # Rank results
  nest_ranked <- nest_locations %>%
    group_by(burst) %>%
    arrange(
      desc(days_vis),
      desc(consec_days),
      desc(tot_vis),
      .by_group = TRUE
    ) %>%
    mutate(candidate_rank = row_number()) %>%
    ungroup()

  # Select best candidate
  nest_best <- nest_ranked %>%
    filter(candidate_rank == 1)

  # Create output data base
  nest_df <- nest_best[, c("burst", "long", "lat")]
  nest_df <- nest_df %>%
    mutate(
      year = as.integer(substr(burst, nchar(burst) - 3, nchar(burst))),
      burst = substr(burst, 1, nchar(burst) - 5)
    ) %>%
    select(burst, year, long, lat)

  # Match names to future steps
  names(nest_df)[1] <- "individual_local_identifier"
  names(nest_df)[3] <- "long_nest"
  names(nest_df)[4] <- "lat_nest"

  data.table::fwrite(nest_df, appArtifactPath("nest_df.csv"))


  ############################################################
  ############################################################

  # Turn timestamps into dates and create year column
  setDT(df_gps)
  setDT(df_acc)
  df_gps$timestamp <- as.POSIXct(df_gps$timestamp, format = "%Y-%m-%d %H:%M:%S")
  df_gps[, year := year(timestamp)]
  df_acc$timestamp <- as.POSIXct(df_acc$timestamp, format = "%Y-%m-%d %H:%M:%S")
  df_acc[, year := year(timestamp)]


  ## Filter by dates 1 Feb to 30 Jun (or last date of breeding if available)
  ## (adapt interval to your species)

  # GPS
  df_gps <- df_gps[
    month(timestamp) >= month_start &
      month(timestamp) <= month_end
  ]

  # ACC
  df_acc <- df_acc[
    month(timestamp) >= month_start &
      month(timestamp) <= month_end
  ]

  ## Filter fixes to a maximum frequency of one every 10 minutes per individual
  setDT(df_gps)
  setorder(df_gps, individual_local_identifier, timestamp)
  df_gps <- df_gps[
    ,
    {
      keep <- logical(.N)
      keep[1] <- TRUE

      last_kept <- timestamp[1]

      for (i in 2:.N) {
        if (difftime(timestamp[i], last_kept, units = "mins") >= max_frequency) {
          keep[i] <- TRUE
          last_kept <- timestamp[i]
        }
      }

      .SD[keep]
    },
    by = individual_local_identifier
  ]


  ## Filter only ID x days combos within at least "X" number of fixes (defined here as 19)

  # Determine fixes per ID x day combo
  fixes_per_day <- df_gps[
    ,
    .(n_fixes = .N),
    by = .(
      individual_local_identifier,
      date = as.Date(timestamp)
    )
  ]

  # Get combos of ID x date that have at least 19 fixes (threshold for this data set)
  fixes_per_day2 <- fixes_per_day[which(fixes_per_day$n_fixes >= min_n_fix_day), ] # Change cut threshold here

  # Filter ID x days combos with at least 19 fixes
  # GPS
  df_gps[, date := as.Date(timestamp)]
  names(df_gps)
  df_gps <- df_gps[
    fixes_per_day2,
    on = .(individual_local_identifier, date),
    nomatch = 0
  ]
  df_gps_to_save <- df_gps # prepare database to later calculate proportion of fixes at the nest

  # Create matching time window (+-30 seconds)
  df_gps[, `:=`(
    timestamp_min = timestamp - 30,
    timestamp_max = timestamp + 30
  )]

  # Match ACC records within the GPS time window
  df_acc <- df_acc[
    df_gps,
    on = .(
      individual_local_identifier,
      timestamp >= timestamp_min,
      timestamp <= timestamp_max
    ),
    nomatch = 0,
    allow.cartesian = TRUE
  ]

  ## Filter only fixes at the nest (20m-radius here; change to your needs)

  # Join nest lat long to GPS database
  nest_df_2 <- nest_df[, c(
    "individual_local_identifier", "year",
    "lat_nest", "long_nest"
  )]
  df_gps <- df_gps %>%
    left_join(
      nest_df_2 %>%
        dplyr::select(
          individual_local_identifier,
          year,
          lat_nest,
          long_nest
        ),
      by = c("individual_local_identifier", "year")
    )
  df_gps$lat_nest <- as.numeric(df_gps$lat_nest)
  df_gps$long_nest <- as.numeric(df_gps$long_nest)

  # Remove ID x Year combos without known nest locations
  df_gps <- df_gps[!is.na(df_gps$long_nest), ]

  # Remove locations outside 20m radius of nest from GPS database
  R <- 6371000 # Earth radius in meters
  df_gps <- df_gps[{
    lat1 <- location_lat * pi / 180
    lat2 <- lat_nest * pi / 180
    dlat <- (lat_nest - location_lat) * pi / 180
    dlon <- (long_nest - location_long) * pi / 180
    a <- sin(dlat / 2)^2 +
      cos(lat1) * cos(lat2) * sin(dlon / 2)^2
    distance_m <- 2 * R * asin(sqrt(a))
    distance_m <= nest_radius
  }]

  # Match the ACC database to current GPS database
  df_acc <- df_acc[
    df_gps,
    on = .(
      individual_local_identifier,
      timestamp >= timestamp_min,
      timestamp <= timestamp_max
    ),
    nomatch = 0,
    allow.cartesian = TRUE
  ]


  ## Create database for later calculating proportion at nest

  # Add nest status (at nest or not) to the database to save
  df_gps_to_save$nest_status <- ifelse(
    paste(df_gps_to_save$individual_local_identifier, df_gps_to_save$timestamp) %in%
      paste(df_gps$individual_local_identifier, df_gps$timestamp),
    "at_nest",
    "not_nest"
  )

  # Remove all ID x Year combos with unknown nest locations
  df_gps_to_save <- df_gps_to_save %>%
    anti_join(
      nest_df_2 %>%
        filter(is.na(long_nest)) %>%
        distinct(individual_local_identifier, year),
      by = c("individual_local_identifier", "year")
    )


  ## Save resulting data bases as csv
  # data.table::fwrite(df_gps, "gps_.csv", row.names = F)
  # data.table::fwrite(df_acc, "acc_.csv", row.names = F)
  # data.table::fwrite(df_gps_to_save, "gps_nest_status_.csv", row.names = F)


  ###############################################################################################
  #                                  Using RF Model 1                                           #
  ###############################################################################################

  # Load required functions
  source(getAuxiliaryFilePath("functions")) # From Vaadia et al. 2025

  # Import data bases
  acc <- df_acc

  # Keep only useful columns
  acc2 <- acc[, c(names(acc)[1:31], "timestamp"), with = FALSE]
  acc3 <- acc2[complete.cases(acc2[, 5:31]), ]

  # Filter only ID x days combos with a certain number of acc readings
  # Determine fixes per ID x day combo
  setDT(acc3)
  bouts_per_day <- acc3[
    ,
    .(n_bouts = .N),
    by = .(
      individual_local_identifier,
      date = as.Date(timestamp)
    )
  ]

  # Get combos of ID x date that have at least 5 bouts (threshold based on histogram)
  bouts_per_day2 <- bouts_per_day[which(bouts_per_day$n_bouts >= min_acc_bouts_day), ]

  # Filter ID x days combos with at least X bouts (here threshold is 5)
  acc3[, date := as.Date(timestamp)]
  acc3 <- acc3[
    bouts_per_day2,
    on = .(individual_local_identifier, date),
    nomatch = 0
  ]

  # Transform acc df from wide to long
  setDT(acc3)
  acc3_long <- data.table::melt(
    acc3,
    id.vars = c(
      "individual_local_identifier",
      "burst",
      "device_type",
      "sex",
      "timestamp",
      "date"
    ),
    measure = list(
      acc_x = 5:13,
      acc_y = 14:22,
      acc_z = 23:31
    ),
    variable.name = "ordinal"
  )

  # Keep only columns of interest for next steps
  unobs_raw_acc <- acc3_long[, c(
    "individual_local_identifier", "timestamp", "burst", "device_type", "sex",
    "acc_x", "acc_y", "acc_z"
  )]

  # Change column names to mach Random Forest model
  names(unobs_raw_acc)[1] <- "device_id"
  names(unobs_raw_acc)[2] <- "UTC_datetime"
  names(unobs_raw_acc)[3] <- "bout_id"

  ### Calculate statistical features for further analysis ###

  # Run calculations
  setDT(unobs_raw_acc)

  stat_feats <- unobs_raw_acc[
    ,
    {
      mx <- mean(acc_x)
      my <- mean(acc_y)
      mz <- mean(acc_z)

      sx <- sd(acc_x)
      sy <- sd(acc_y)
      sz <- sd(acc_z)

      cxy <- cov(acc_x, acc_y)
      cxz <- cov(acc_x, acc_z)
      cyz <- cov(acc_y, acc_z)

      .(
        mean_x = mx,
        mean_y = my,
        mean_z = mz,
        range_x = max(acc_x) - min(acc_x),
        range_y = max(acc_y) - min(acc_y),
        range_z = max(acc_z) - min(acc_z),
        sd_x = sx,
        sd_y = sy,
        sd_z = sz,
        skewness_x = skewness(acc_x),
        skewness_y = skewness(acc_y),
        skewness_z = skewness(acc_z),
        kurtosis_x = kurtosis(acc_x),
        kurtosis_y = kurtosis(acc_y),
        kurtosis_z = kurtosis(acc_z),
        max_x = max(acc_x),
        max_y = max(acc_y),
        max_z = max(acc_z),
        min_x = min(acc_x),
        min_y = min(acc_y),
        min_z = min(acc_z),
        norm_x = sqrt(sum(acc_x^2)),
        norm_y = sqrt(sum(acc_y^2)),
        norm_z = sqrt(sum(acc_z^2)),
        q25_x = quantile(acc_x, 0.25),
        q25_y = quantile(acc_y, 0.25),
        q25_z = quantile(acc_z, 0.25),
        q50_x = quantile(acc_x, 0.50),
        q50_y = quantile(acc_y, 0.50),
        q50_z = quantile(acc_z, 0.50),
        q75_x = quantile(acc_x, 0.75),
        q75_y = quantile(acc_y, 0.75),
        q75_z = quantile(acc_z, 0.75),
        cov_x_y = cxy,
        cov_x_z = cxz,
        cov_y_z = cyz,
        cor_x_y = cor(acc_x, acc_y),
        cor_x_z = cor(acc_x, acc_z),
        cor_y_z = cor(acc_y, acc_z),
        mean_diff_x_y = mx - my,
        mean_diff_x_z = mx - mz,
        mean_diff_y_z = my - mz,

        # OLD
        # sd_diff_x_y = sqrt(sx^2 + sy^2 - 2 * cxy),
        # sd_diff_x_z = sqrt(sx^2 + sz^2 - 2 * cxz),
        # sd_diff_y_z = sqrt(sy^2 + sz^2 - 2 * cyz),

        # NEW
        sd_diff_x_y = sqrt(max(0, sx^2 + sy^2 - 2 * cxy)),
        sd_diff_x_z = sqrt(max(0, sx^2 + sz^2 - 2 * cxz)),
        sd_diff_y_z = sqrt(max(0, sy^2 + sz^2 - 2 * cyz)),
        mean_amplitude_x = mean_amplitude(acc_x),
        mean_amplitude_y = mean_amplitude(acc_y),
        mean_amplitude_z = mean_amplitude(acc_z)
      )
    },
    by = .(device_id, bout_id, device_type)
  ]


  ## Prepare the dataset before the model use

  # Get wide database with vars of interest to join to stat feats
  names(acc3)[1] <- "device_id"
  acc4 <- acc3[, c(1:3, 5:31)]

  # Change names to match stat feats database
  names(acc4)[2] <- "bout_id"

  # Change col names to match RF model formula
  names(acc4)[4:30] <- sub("acceleration_raw", "acc", names(acc4)[4:30])

  # join all variables for each bout
  full_unobs_data <- left_join(acc4,
    stat_feats,
    by = c("device_id", "bout_id")
  )

  ## Behavioral classification of unobserved data

  # Import my model
  unobs_fit <- readRDS(getAuxiliaryFilePath("RF_Model_Sitting_Non_Sitting"))

  ## Apply the model to the unobserved dataset

  # Predict the behaviors
  predictions <- predict(unobs_fit, full_unobs_data)


  ## Generate a dataset of behaviorally annotated ACC bouts

  # Add the predictions to the main dataframe
  full_unobs_data <- cbind(full_unobs_data, predictions)

  ## Confidence Scores

  # Calculate a confidence score for each prediction
  full_scores <- predict(unobs_fit, full_unobs_data, type = "prob")

  # Add confidence scores to data base (highest per classification)
  full_unobs_data <- full_unobs_data %>%
    add_column(
      score = apply(full_scores, MARGIN = 1, FUN = max),
      .before = "device_id"
    )

  # Add UTC_datetime to database
  first_timestamps <- unobs_raw_acc %>%
    group_by(device_id, bout_id) %>%
    summarise(
      first_UTC_datetime = min(UTC_datetime),
      .groups = "drop"
    )

  full_unobs_data <- full_unobs_data %>%
    left_join(first_timestamps, by = c("device_id", "bout_id"))

  names(full_unobs_data)[82] <- "UTC_datetime"

  # Save as excel file the final full dataframe
  # data.table::fwrite(full_unobs_data, "behav_classif_sitting_non_sitting.csv")


  ###############################################################################################
  #                         Prepare data bases for next RF model                                #
  ###############################################################################################

  ## Create database of frequency of occurrence of behaviors over time (days) for each year x ID

  # Import dataset
  predicted_behs <- full_unobs_data

  # Reduce to columns of interest
  predicted_behs2 <- predicted_behs[, c("device_id", "UTC_datetime", ".pred_class")]

  # Add day and year column
  predicted_behs2$date <- as.POSIXct(as.Date(predicted_behs2$UTC_datetime, format = "%Y-%m-%d"))
  predicted_behs2$year <- year(predicted_behs2$UTC_datetime)
  predicted_behs2$month <- month(predicted_behs2$UTC_datetime)

  # Calculate daily proportions of sitting
  daily_sitting <- predicted_behs2 %>%
    group_by(device_id, year, date) %>%
    summarise(
      prop_sitting = mean(.pred_class == "sitting"),
      .groups = "drop"
    )

  # Save data base for later analysis
  # data.table::fwrite(daily_sitting, "daily_sitting_prop_.csv", row.names = F)

  ## Create database of nest use over time (days) for each year x ID

  # Import data
  df <- df_gps_to_save

  # Calculate proportions
  setDT(df)
  daily_nest_use <- df[
    ,
    .(
      n_fixes = .N,
      n_at_nest = sum(nest_status == "at_nest", na.rm = TRUE),
      prop_at_nest = mean(nest_status == "at_nest", na.rm = TRUE)
    ),
    by = .(individual_local_identifier, year, date)
  ]

  # Match names to daily nest use database
  names(daily_nest_use)[1] <- "device_id"

  # Save data base for later analysis
  daily_nest_use <- daily_nest_use[, c("device_id", "year", "date", "prop_at_nest")]
  # data.table::fwrite(daily_nest_use, "daily_nest_use_.csv", row.names = F)


  ###############################################################################################
  #                                  Using RF Model 2                                           #
  ###############################################################################################

  # Ensure matching date formats
  daily_nest_use[, date := as.IDate(date)]
  setDT(daily_sitting)
  daily_sitting[, date := as.IDate(date, tz = "UTC")]

  # Join databases OLD
  # df <- merge(
  #  daily_nest_use,
  #  daily_sitting,
  #  by = c("device_id", "year", "date"),
  #  all = TRUE
  # )
  # NEW
  df <- full_join(daily_nest_use, daily_sitting, by = c("device_id", "year", "date"))

  df <- data.frame(df)

  # Keep only ID x Day combos without NAs
  df <- df[complete.cases(df), ]

  ## Create new variables to use in the RF model

  # slope sitting of the last 5 days
  df <- df %>%
    arrange(device_id, date) %>%
    group_by(device_id) %>%
    mutate(
      sitting_slope_5d = slide_dbl(
        prop_sitting,
        ~ coef(lm(.x ~ seq_along(.x)))[2],
        .before = 4,
        .complete = TRUE
      )
    ) %>%
    ungroup()

  # slope at nest of the last 5 days
  df <- df %>%
    arrange(device_id, date) %>%
    group_by(device_id) %>%
    mutate(
      nest_slope_5d = slide_dbl(
        prop_at_nest,
        ~ coef(lm(.x ~ seq_along(.x)))[2],
        .before = 4,
        .complete = TRUE
      )
    ) %>%
    ungroup()


  ## Create device type & sex columns to use as var in model

  # Create device type and sex columns
  acc <- df_acc
  acc2 <- acc[, c("individual_local_identifier", "sex", "device_type")]
  names(acc2)[1] <- "device_id"

  # Join data bases
  device_types <- unique(acc2[, c("device_id", "sex", "device_type")])
  setDT(df)
  setDT(device_types)
  df[device_types, `:=`(
    device_type = device_type,
    sex = sex
  ), on = "device_id"]
  # OLD
  # df$device_type[is.na(df$device_type)] <- "YOUR_DEVICE_TYPE1"
  # NEW
  df$device_type[is.na(df$device_type) | df$device_type == "Unknown"] <- "YOUR_DEVICE_TYPE1"

  # Keep only rows that have no NAs
  df <- df[complete.cases(df), ]

  # Add month column
  df$month <- month(df$date)

  # Create database that will be used in RF
  full_unobs_data <- df

  ## Behavioral classification of unobserved data

  # Import my model
  unobs_fit <- readRDS(getAuxiliaryFilePath("RF_Model_Incubation"))

  ## Apply the model to the unobserved dataset

  # Predict the behaviors
  predictions <- predict(unobs_fit, full_unobs_data)

  ## Generate a dataset of behaviorally annotated ACC bouts

  # Add the predictions to the main dataframe
  full_unobs_data <- cbind(full_unobs_data, predictions)

  ## Confidence Scores

  # Calculate a confidence score for each prediction
  full_scores <- predict(unobs_fit, full_unobs_data, type = "prob")

  # Add confidence scores to data base (highest per classification)
  full_unobs_data <- full_unobs_data %>%
    add_column(
      score = apply(full_scores, MARGIN = 1, FUN = max),
      .before = "device_id"
    )


  ## Save as csv file the final full dataframe
  # data.table::fwrite(full_unobs_data, "incubation_prediction_.csv", row.names = F)


  ###############################################################################################
  #                                  Model incubation                                           #
  ###############################################################################################


  ## Import dataset with obs events and RF predictions
  df <- full_unobs_data

  ## Prepare data for GAM modeling

  # Create binary variable for incubation: 1=incubating, 0=non-incubating
  df$prob_inc_rf <- 1
  df$prob_inc_rf[which(df$.pred_class == "non_incubating")] <- 0

  # Turn dates into dates
  df$date <- as.Date(df$date)

  # Model laying and hatching dates based on RF predictions,
  # weighted by RF classification confidence score
  predicted_dates <- df %>%
    dplyr::group_by(device_id, year) %>%
    dplyr::group_modify(~ {
      dat <- .x %>%
        dplyr::arrange(date) %>%
        dplyr::mutate(
          date_num = as.numeric(date - min(date))
        ) %>%
        dplyr::filter(
          !is.na(prob_inc_rf),
          !is.na(score),
          !is.na(date_num)
        ) %>%
        dplyr::mutate(
          model_weight = score / mean(score)
        )

      # Check that there are enough observations to fit the model
      if (
        nrow(dat) < 6 ||
          length(unique(dat$date_num)) < 2
      ) {
        return(tibble::tibble(
          predicted_laying = as.Date(NA),
          predicted_hatching = as.Date(NA)
        ))
      }

      # Fit confidence-weighted GAM
      mod <- mgcv::gam(
        prob_inc_rf ~ s(date_num, k = 6, bs = "cs"),
        family = binomial,
        data = dat,
        weights = model_weight,
        method = "REML"
      )

      # Predict every date across the observed period
      prediction_grid <- tibble::tibble(
        date_num = seq(
          min(dat$date_num),
          max(dat$date_num),
          by = 1
        )
      )

      prediction_grid$prob <- predict(
        mod,
        newdata = prediction_grid,
        type = "response"
      )

      # Convert numeric dates back to Date
      prediction_grid$date <- as.Date(
        as.numeric(min(dat$date)) + prediction_grid$date_num,
        origin = "1970-01-01"
      )

      # --------------------------------------------------
      # Predict laying date: upward threshold of laying
      # --------------------------------------------------

      # If the smooth starts above laying threshold, laying may have
      # occurred before the first available observation.
      if (prediction_grid$prob[1] > laying_threshold) {
        predicted_laying <- as.Date(NA)
      } else {
        # Laying = first predicted probability > laying threshold
        laying_crossings <- which(
          prediction_grid$prob > laying_threshold
        )

        predicted_laying <- if (length(laying_crossings) == 0) {
          as.Date(NA)
        } else {
          prediction_grid$date[laying_crossings[1]]
        }
      }

      # --------------------------------------------------
      # Predict hatching date: downward threshold of hatching
      # --------------------------------------------------

      # Hatching = last downward crossing of hatching threshold:
      # previous date's probability > hatching threshold,
      # current date's probability < hatching threshold.
      downward_crossings <- which(
        seq_len(nrow(prediction_grid)) > 1 &
          prediction_grid$prob < hatching_threshold &
          dplyr::lag(
            prediction_grid$prob,
            default = NA_real_
          ) > hatching_threshold
      )

      predicted_hatching <- if (length(downward_crossings) == 0) {
        as.Date(NA)
      } else {
        prediction_grid$date[max(downward_crossings)]
      }

      # Return both dates
      tibble::tibble(
        predicted_laying = predicted_laying,
        predicted_hatching = predicted_hatching
      )
    }) %>%
    dplyr::ungroup()

  df <- df %>%
    dplyr::left_join(
      predicted_dates %>%
        dplyr::select(device_id, year, predicted_laying, predicted_hatching),
      by = c("device_id", "year")
    )

  ## Create columns for the incubation period duration in days
  df$inc_period <- round(as.numeric(abs(df$predicted_hatching - df$predicted_laying)))

  ## Classify the breeding for each ID x Year

  # Add breeding type column to df (change day thresholds according to your case)
  df$breeding_type <- "Single Clutch"

  # Classify breeding outcome based on incubation period duration
  df$breeding_type[which(df$inc_period >= min_inc_per_2clutch)] <- "Second Clutch"

  df$breeding_type[which(df$inc_period > 0 &
    df$inc_period < min_inc_per_1clutch)] <- "Failed Breeding"

  # Identify individual-years with at least 3 consecutive incubating observations
  incubation_evidence <- df %>%
    arrange(device_id, year, date) %>%
    group_by(device_id, year) %>%
    summarise(
      incubation_detected = any(
        rle(prob_inc_rf == 1)$lengths[
          rle(prob_inc_rf == 1)$values
        ] >= 3
      ),
      .groups = "drop"
    )

  # Add incubation evidence to the original dataframe
  df <- df %>%
    left_join(incubation_evidence, by = c("device_id", "year"))

  # Classify individual-years with both dates missing
  # as No Breeding or Unknown depending on incubation evidence
  df$breeding_type[
    is.na(df$inc_period) &
      is.na(df$predicted_laying) &
      is.na(df$predicted_hatching) &
      !df$incubation_detected
  ] <- "No Breeding"

  df$breeding_type[
    is.na(df$inc_period) &
      is.na(df$predicted_laying) &
      is.na(df$predicted_hatching) &
      df$incubation_detected
  ] <- "Unclassified breeding"

  # Classify individual-years with only one estimated date as Unknown
  df$breeding_type[
    is.na(df$predicted_laying) &
      !is.na(df$predicted_hatching)
  ] <- "Unclassified breeding"

  df$breeding_type[
    !is.na(df$predicted_laying) &
      is.na(df$predicted_hatching)
  ] <- "Unclassified breeding"

  # Remove auxiliary column
  df$incubation_detected <- NULL

  ## Save as excel file the final full dataframe
  write_xlsx(df, appArtifactPath("laying_hatching_predictions_daily_.xlsx"))


  ## Create a summary data frame for each ID x Year combo
  summary_df <- df[, c(
    "device_id", "year", "predicted_laying", "predicted_hatching",
    "inc_period", "breeding_type"
  )]
  summary_df <- dplyr::distinct(summary_df)

  ## Save as excel file the final summary dataframe
  write_xlsx(summary_df, appArtifactPath("laying_hatching_predictions_summary_.xlsx"))


  logger.info("Workflow completed successfully. Converting to move2 object and returning.")
  if (filterData) {
    ## Filter original database to keep only ID x Years that got predictions
    ## and add predictions to database
    original_df <- all_data_df
    original_df$timestamp <- as.POSIXct(
      original_df$timestamp,
      format = "%Y-%m-%d %H:%M:%S",
      tz = "UTC"
    )
    original_df$year <- year(original_df$timestamp)
    summary_df2 <- summary_df
    names(summary_df2)[1] <- "individual_local_identifier"
    original_df <- original_df %>%
      inner_join(
        summary_df2,
        by = c("individual_local_identifier", "year")
      )


    # Convert final output data frame back into a proper move2 object for MoveApps
    original_sf <- original_df[!is.na(original_df$location_long) & !is.na(original_df$location_lat), ]

    original_move2 <- move2::mt_as_move2(
      original_sf,
      coords = c("location_long", "location_lat"),
      time_column = "timestamp",
      track_id_column = "individual_local_identifier"
    ) |> sf::st_set_crs(4326)

    return(original_move2)
  } else {
    return(data)
  }
}
