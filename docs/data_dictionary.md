# Data dictionary
## Dataset: Measure_dm_bp_meas_imd_rate dataset
For this dataset, each month (March 2018 to April 2022 (or later date)), the denominator adult population (18+) who meet the inclusion criteria will be extracted. The period prevalence of each outcome will be calculated across the study population each month. This will assume that a person is eligible in the denominator for the whole month if they are eligible on the 1st of the month. Each outcome will be analysed separately in the relevant study population (Diabetes, COPD, or general population) Each person will be counted only once each month, but people can appear in multiple months if they have repeated records of the outcome. 

| Variable    |Variable type          |	Description                                                                                      |
|------       |-------------          |---------------                                                                                   |
| IMD         |Categorical (1-5)      |	IMD quintile                                                                                     |
| bp_meas     |Numeric                | Number of people with the outcome – for this dataset it is blood pressure measurement (bp_meas). |
| population  |Numeric                |	Number of people in the whole population as of date                                              |
| value       |Value between 0 and 1  |	Proportion of population with the outcome                                                        |
| date        |Date	                  | Month of interest                                                                                |

