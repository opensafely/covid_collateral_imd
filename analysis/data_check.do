cap log using ./logs/check.log, replace

* Checking join: Count number of patients in DM study definition 

import delimited using ./output/measures/input_dm_2018-03-01.csv

safetab diabetes_subgroup

import delimited using ./output/measures/joined/input_dm_2018-03-01.csv

safetab diabetes_subgroup

import delimited using ./output/measures/input_dm_2018-03-01.csv

safetab diabetes_subgroup

import delimited using ./output/measures/joined/input_dm_2018-03-01.csv

safetab diabetes_subgroup