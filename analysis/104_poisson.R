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
library(cowplot)
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
  
  ## Capture output
  capture.output(
    cat(outcome, rep("-", 20), "\n"), 
    broom::tidy(po_model1, exp = TRUE),
    cat("\n"),
    file = here::here("output/poisson_model_output.txt"),
    append = TRUE
  )
  
  ## adjust predicted values
  pearson_gof <- sum(residuals(po_model1, type = "pearson")^2)
  df <- po_model1$df.residual
  deviance_adjustment <- pearson_gof/df
  
  ## data frame to predict values from 
  outcome_pred <- df_outcome
  
  ## predict values
  pred1 <- predict(po_model1, newdata = outcome_pred, se.fit = TRUE, interval="confidence", dispersion = deviance_adjustment, type = "link")
  # predicted number of admissions per person, for each combination of outcome_pred (by lockdown, IMD, time, pre_post_covid, and lagres): all still on log scale
  predicted_vals <- pred1$fit
  stbp <- pred1$se.fit
  
  ## predict values if no lockdown 
  outcome_pred_nointervention <- outcome_pred %>%
    mutate_at("postcovid", ~(.=0)) 
  predicted_vals_nointervention <- predict(po_model1, newdata = outcome_pred_nointervention, se.fit = TRUE, dispersion = deviance_adjustment, type = "link") 
  predicted_vals_noLdn <- predicted_vals_nointervention$fit	
  stbp_noLdn <- predicted_vals_nointervention$se.fit	
  
  ## standard errors to get confidence estimates. 
  ## then exponentiate to get onto the predicted values scale
  df_se <- bind_cols(imd = as.character(df_outcome$imd), 
                     stbp = stbp,
                     pred = predicted_vals, 
                     stbp_noLdn = stbp_noLdn, 
                     pred_noLdn = predicted_vals_noLdn, 
                     denom = df_outcome$population) %>%
    mutate(
      #CIs
      upp = exp(pred + (1.96*stbp)),
      low = exp(pred - (1.96*stbp)),
      upp_noLdn = exp(pred_noLdn + (1.96*stbp_noLdn)),
      low_noLdn = exp(pred_noLdn - (1.96*stbp_noLdn)),
      pred = exp(pred),
      pred_noLdn = exp(pred_noLdn)
    )
  sigdig <- 2
  
  # bind predictions with dates and set a pre/post-lockdown variable
  tab3_merge <- bind_cols("weekPlot" = df_outcome$date, 
                          "postcovid" = df_outcome$postcovid,
                          df_se)
  
  # how many post-lockdown months of data are there? 
  months_post <- (table(tab3_merge$postcovid)/5)[2]
  months_pre <- (table(tab3_merge$postcovid)/5)[1]
  rows_to_remove <- (months_pre-months_post)*5
  # create a variable to filter all of the post-lockdown and the relevant period pre lockdown
  tab3_merge$select <- 1
  tab3_merge$select[1:rows_to_remove] <- 0
  
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
  
  df_plot <- df_outcome %>% 
    dplyr::select(dateA, imd, numOutcome) %>% 
    mutate(imd = as.character(imd)) %>% 
    left_join(tab3_merge, by = c("dateA"="weekPlot", "imd" = "imd")) %>% 
    filter(select == 1)
  
  plot_modelfit <- ggplot(df_plot, aes(x=dateA, y=numOutcome, group=imd, colour=imd, fill=imd)) +
    geom_line() +
    geom_ribbon(aes(ymin=low, ymax = upp), lty = 0, alpha = 0.4) +
    geom_ribbon(data = filter(df_plot, postcovid == 1), aes(ymin=low_noLdn, ymax = upp_noLdn), fill = "gray20", lty = 0, alpha = 0.4) +
    geom_vline(xintercept = start_lockdown, lty = 2, col = "gray40") +
    labs(colour = "IMD",
         fill = "IMD",
         x = "Month", 
         y = "Admissions") +
    facet_wrap(~imd, ncol = 1) +
    theme_bw() +
    theme(strip.background = element_blank(),
          legend.position = "none")
  
  if(outcome != "heart_failure_admission"){
    plot_modelfit <- plot_modelfit + 
      theme(axis.title.y = element_blank())
  }
  return(list(tab3_fmt, plot_modelfit))
}

model_outputs <- lapply(outcomes[plot_order], function(xx){tab3_function(xx)})

tab3 <- NULL
for(ii in plot_order){
  tab3 <- bind_rows(tab3,
                    model_outputs[[ii]][[1]])
  tab3[nrow(tab3) + 1,] <- ""
}

write.csv(tab3, file = here::here("./output/table3.csv"), row.names = F)


# combine plots  ----------------------------------------------------------
pdf(here::here("output/poisson_modelfits.pdf"), width = 10, height = 6)
cowplot::plot_grid(
  model_outputs[[1]][[2]], 
  model_outputs[[2]][[2]], 
  model_outputs[[3]][[2]], 
  model_outputs[[4]][[2]],
  nrow = 1, ncol = 4)
dev.off()
