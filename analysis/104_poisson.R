# load the packages
library(foreign)
library(tsModel)
library(lmtest)
library(Epi)
library(multcomp)
library(splines)
library(vcd)
library(here)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(patchwork)
library(lubridate)
bkg_colour <- "gray99"

here::here()

# import data -------------------------------------------------------------
all_files <- list.files(here::here("output/cvd"), pattern = "an_")
outcomes <- stringr::str_remove_all(all_files, c("an_|.csv"))
outcome_of_interest_namematch <- bind_cols("outcome" = outcomes,
                                           "outcome_name" = (c("Heart Failure", "Myocardial Infarction", "Stroke", "Venous Thromboembolism")) # nolint
                                           )

plot_order <- c(1, 2, 3, 4)
for(ii in 1:length(outcomes)){
  load_file <- read.csv(paste0(here::here("output/cvd/"), paste0("an_", outcomes[ii], ".csv"))) # nolint
  assign(outcomes[ii], load_file)
}

# function to generate data for table 3 one outcome at a time # nolint
tab3_function <- function(outcome){
  df_outcome <- get(outcome)
  # convert dateA variable to R accepted format
  df_outcome$dateA <- lubridate::as_date(df_outcome$dateA, format = "%d/%B/%y")
  
  start_lockdown = as.Date("2020-03-23")
  end_post_lockdown_period = as.Date("2022-12-31")
  # Taken out code for creating variables as I have done this in Stata
  ## model Poisson 
  po_model1 <- glm(numOutcome ~ offset(log(population)) + postcovid + imd + time + imd:postcovid, family=quasipoisson, data = df_outcome)
  # get lagged residuals
  lagres1 <- lag(residuals(po_model1))
  
  ## full model with lagged residuals
  po_model2 <- glm(numOutcome ~ offset(log(population)) + postcovid + time + imd + imd:postcovid  + lagres1, family=quasipoisson, data = df_outcome)
  
  ## adjust predicted values
  pearson_gof <- sum(residuals(po_model2, type = "pearson")^2)
  df <- po_model2$df.residual
  deviance_adjustment <- pearson_gof/df
  po_lagres_timing <- bind_cols("time" = df_outcome$time,
                                "lagres1" = lagres1, "imd" = df_outcome$imd)
  
  ## data frame to predict values from 
  outcome_pred <- df_outcome %>%
    left_join(po_lagres_timing, by = c("imd" = "imd", "time" = "time"))
  
  ## predict values
  pred1 <- predict(po_model2, newdata = outcome_pred, se.fit = TRUE, interval="confidence", dispersion = deviance_adjustment)
  predicted_vals <- pred1$fit
  stbp <- pred1$se.fit
  
  ## predict values if no lockdown 
  outcome_pred_nointervention <- outcome_pred %>%
    mutate_at("postcovid", ~(.=0)) 
  predicted_vals_nointervention <- predict(po_model2, newdata = outcome_pred_nointervention, se.fit = TRUE, dispersion = deviance_adjustment) 
  predicted_vals_noLdn <- predicted_vals_nointervention$fit	
  stbp_noLdn <- predicted_vals_nointervention$se.fit	
  
  ## standard errors
  df_se <- bind_cols(imd = as.character(df_outcome$imd), 
                     stbp = stbp,
                     pred = predicted_vals, 
                     stbp_noLdn = stbp_noLdn, 
                     pred_noLdn = predicted_vals_noLdn, 
                     denom = df_outcome$population) %>%
    mutate(
      #CIs
      upp = pred + (1.96*stbp),
      low = pred - (1.96*stbp),
      upp_noLdn = pred_noLdn + (1.96*stbp_noLdn),
      low_noLdn = pred_noLdn - (1.96*stbp_noLdn),
    )
  sigdig <- 2
  model_out <- signif(ci.exp(po_model2)[2,], sigdig)
  
  # bind predictions with dates and set a pre/post-lockdwon variable
  tab3_merge <- bind_cols("weekPlot" = df_outcome$date, 
                          "postcovid" = df_outcome$postcovid,
                          df_se)
  
  # how many post-lockdown months of data are there? 
  months_post <- (table(tab3_merge$postcovid)/5)[2]
  months_pre <- (table(tab3_merge$postcovid)/5)[1]
  # create a variable to filter all of the post-lockdown and the relevant period pre lockdown
  tab3_merge$select <- 1
  tab3_merge$select[1:(months_pre-months_post)] <- 0
  
  tab3_cumsum <- tab3_merge %>% 
    filter(select == 1) %>% 
    ungroup() %>% 
    group_by(postcovid, imd) %>% 
    ## calculate cumulative sum of predicted vals with/without lockdown 
    summarise(cumsum_ldn = sum(pred),
           lci_cumsum_ldn = sum(low),
           uci_cumsum_ldn = sum(upp),
           cumsum_noLdn = sum(pred_noLdn),
           lci_cumsum_noLdn = sum(low_noLdn),
           uci_cumsum_noLdn = sum(upp_noLdn),
           .groups = "keep"
    ) %>% 
    # estimated number of weekly outcomes with NO LOCKDOWN
    mutate(cumsum_no_lockdown = paste0(prettyNum(cumsum_noLdn, big.mark=",",format = "f", digits = 3, scientific=FALSE),  # digits = 3 is sig. dig.
                         " (", prettyNum(lci_cumsum_noLdn, big.mark=",",digits = 3, scientific=FALSE), 
                         " - ", prettyNum(uci_cumsum_noLdn, big.mark=",",digits = 3, scientific=FALSE),")"),
           # estimated number of weekly outcomes with LOCKDOWN
           cumsum_with_lockdown = paste0(prettyNum(cumsum_ldn, big.mark=",",digits = 3, scientific=FALSE), 
                         " (", prettyNum(lci_cumsum_ldn, big.mark=",",digits = 3, scientific=FALSE), 
                         " - ", prettyNum(uci_cumsum_ldn, big.mark=",",digits = 3, scientific=FALSE),")")
           )
  
  tab3_fmt <- tab3_cumsum %>% 
    ungroup() %>% 
    mutate(outcome = outcome_of_interest_namematch$outcome_name[outcome_of_interest_namematch$outcome == outcome]) %>%
    select(outcome, imd, postcovid, cumsum_no_lockdown, cumsum_with_lockdown) %>%
    mutate(postcovid = ifelse(postcovid == 0, "pre", "post")) %>% 
    pivot_wider(id_cols = c(outcome, imd), names_from = postcovid, values_from = c(cumsum_no_lockdown, cumsum_with_lockdown)) %>%
    mutate_at("outcome", ~ifelse(row_number(.)>1, "", .)) %>% 
    # drop the cumsum_with_lockdown_pre: it is identical to cumsum_no_lockdown_post and it makes no sense to predict a lockdown pre covid
    dplyr::select(-cumsum_with_lockdown_pre) 
  
  return(tab3_fmt)
}

tab3 <- NULL
for(ii in plot_order){
  tab3 <- bind_rows(tab3,
                    tab3_function(outcomes[ii]))
  tab3[nrow(tab3) + 1,] <- ""
}

write.csv(tab3, file = here::here("./output/table3.csv"), row.names = F)
