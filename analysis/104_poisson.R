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
bkg_colour <- "gray99"
filepath <- "C:/Users/RuthCostello/Documents/GitHub/covid_collateral_imd/output/cvd"

# import data -------------------------------------------------------------
all_files <- list.files(filepath, pattern = "an_")
outcomes <- stringr::str_remove_all(all_files, c("an_|.csv"))
outcome_of_interest_namematch <- bind_cols("outcome" = outcomes,
                                           "outcome_name" = (c("Heart Failure", "Myocardial Infarction", "Stroke", "Venous Thromboembolism")) # nolint
                                           )

plot_order <- c(1, 2, 3, 4)
for(ii in 1:length(outcomes)){
  load_file <- read.csv(paste0(filepath, "/", paste0("an_", outcomes[ii], ".csv"))) # nolint
  assign(outcomes[ii], load_file)
}

# function to generate data for table 3 one outcome at a time # nolint
tab3_function <- function(outcome){
  df_outcome <- get(outcome)
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
  stbp_noLdn <- predicted_vals_nointervention$se.fit	
  predicted_vals_noLdn <- predicted_vals_nointervention$fit	
  
  ## standard errors
  df_se <- bind_cols(stbp = stbp, 
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
      # probline
      predicted_vals = exp(pred)/denom,
      probline_noLdn = exp(pred_noLdn)/denom,
      #
      uci = exp(upp)/denom,
      lci = exp(low)/denom,
      uci_noLdn = exp(upp_noLdn)/denom,
      lci_noLdn = exp(low_noLdn)/denom
    )
  sigdig <- 2
  model_out <- signif(ci.exp(po_model2)[2,], sigdig)
  
  tab3_dates <- bind_cols("weekPlot" = df_outcome$date, df_se) %>%
            drop_na() %>% 
           # estimated number of weekly ooutcomes with NO LOCKDOWN
           mutate(col1 = paste0(prettyNum(probline_noLdn*1e6,big.mark=",",digits = 0, scientific=FALSE), 
                         " (", prettyNum(lci_noLdn*1e6,big.mark=",",digits = 0, scientific=FALSE), 
                         " - ", prettyNum(uci_noLdn*1e6,big.mark=",",digits = 0, scientific=FALSE),")",
           # estimated number of weekly ooutcomes with LOCKDOWN
           col3 = paste0(prettyNum(predicted_vals*1e6,big.mark=",",digits = 0, scientific=FALSE), 
                         " (", prettyNum(lci*1e6,big.mark=",",digits = 0, scientific=FALSE), 
                         " - ", prettyNum(uci*1e6,big.mark=",",digits = 0, scientific=FALSE),")"))
    ) %>%
    ## filter to post-lockdown data only
    filter(weekPlot >= start_lockdown) %>%
    ## calculate cumulative sum of predicted vals with/without lockdown 
    mutate(cumsum_ldn = cumsum(predicted_vals*1e6),
           lci_cumsum_ldn = cumsum(lci*1e6),
           uci_cumsum_ldn = cumsum(uci*1e6),
           cumsum_noLdn = cumsum(probline_noLdn*1e6),
           lci_cumsum_noLdn = cumsum(low_noLdn*1e6),
           uci_cumsum_noLdn = cumsum(upp_noLdn*1e6),
           prettyNum(uci*1e6,big.mark=",",digits = 0, scientific=FALSE),
           ## weekly difference in Lockdown vs No lockdown
           col5 = prettyNum(signif((probline_noLdn*1e6) - (predicted_vals*1e6),3), big.mark=",", digits = 0, scientific=FALSE),
           ## cumulative sum of Lockdown vs No lockdown
           col6 = prettyNum(signif((cumsum_noLdn) - (cumsum_ldn),3), big.mark=",", digits = 0, scientific=FALSE)
    )  %>%
    ## censor data if it is too small
    mutate(diff_predicted = (probline_noLdn*1e6) - (predicted_vals*1e6),
           cumsum_diff_predicted = (cumsum_noLdn) - (cumsum_ldn)) %>%
    mutate_at(.vars = c("col5"), ~ifelse(diff_predicted < 10 & diff_predicted > 0,
                                         "<10", 
                                         ifelse(diff_predicted < 100 & diff_predicted > 0,
                                                "<100",
                                                ifelse(diff_predicted > -10 & diff_predicted < 0,
                                                       ">-10",
                                                       ifelse(diff_predicted > -100 & diff_predicted < 0,
                                                              ">-100",
                                                              .)
                                                )))
    ) %>%
    mutate_at(.vars = c("col6"), ~ifelse(cumsum_diff_predicted < 10 & cumsum_diff_predicted > 0,
                                         "<10", 
                                         ifelse(cumsum_diff_predicted < 100 & cumsum_diff_predicted > 0,
                                                "<100",
                                                ifelse(cumsum_diff_predicted > -10 & cumsum_diff_predicted < 0,
                                                       ">-10",
                                                       ifelse(cumsum_diff_predicted > -100 & cumsum_diff_predicted < 0,
                                                              ">-100",
                                                              .)
                                                )))
    ) %>%
    ## only keep the data for 1 month and 2 months post lockdown
    filter(days2 == min(days2) | 
             days3 == min(days3)) 
  
  rate_diff <- tab3_dates %>% 
    mutate(rate_diff = (exp(pred)/denom) - (exp(pred_noLdn)/denom),
           chisq_stat = (exp(pred) - (((exp(pred)+exp(pred_noLdn))*denom)/(denom+denom)))^2 / (((exp(pred)+exp(pred_noLdn))*denom*denom)/(denom^2)),
           lci_rd = rate_diff - 1.96*(sqrt((rate_diff^2)/chisq_stat)),
           uci_rd = rate_diff + 1.96*(sqrt((rate_diff^2)/chisq_stat))
    ) %>%
    select(rate_diff, lci_rd, uci_rd)
  
  
  tab3_fmt <- tab3_dates %>% 
    bind_cols(rate_diff) %>%
    mutate(outcome = outcome_of_interest_namematch$outcome_name[outcome_of_interest_namematch$outcome == outcome]) %>%
    select(outcome, weekPlot, starts_with("col")) %>%
    pivot_wider(values_from = starts_with("col")) %>%
    mutate_at("weekPlot", ~as.character(format.Date(., "%d-%b"))) %>%
    mutate_at("outcome", ~ifelse(row_number(.)==2, "", .))
  return(tab3_fmt)
}

tab3 <- NULL
for(ii in plot_order){
  tab3 <- bind_rows(tab3,
                    tab3_function(outcomes[ii]))
  tab3[nrow(tab3) + 1,] <- ""
}
tab3
write.csv(tab3, file = here::here("./output/table3.csv"), row.names = F)