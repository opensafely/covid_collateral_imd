/*==============================================================================
DO FILE NAME:			baseline_tables.do
PROJECT:				COVID collateral IMD 
DATE: 					17 February 2023 
AUTHOR:					R Costello
						adapted from R Mathur and K Wing	
DESCRIPTION OF FILE:	Produce a table of baseline characteristics for 3 years (2019, 2020, 2021)
DATASETS USED:			output/measures/tables/input_tables_*
DATASETS CREATED: 		None
OTHER OUTPUT: 			Results in csv: baseline_table*.csv 
						Log file: logs/table1_descriptives
USER-INSTALLED ADO: 	 
  (place .ado file(s) in analysis folder)	
  
 Notes:
 Table 1 population is people who are in the study population on 1st January 2019, 2020 & 2021
 ==============================================================================*/

adopath + ./analysis/ado 

capture log close
log using ./logs/table1_descriptives.log, replace

cap mkdir ./output/tables

* Create  baseline tables for 3 years
forvalues i=2019/2021 {
  * Import csv file
    import delimited ./output/input_static_`i'-01-01.csv, clear
    *update variable with missing so that 0 is shown as unknown (just for this table)
    *(1) IMD
    replace imd=6 if imd==0

    * Create age categories
    egen age_cat = cut(age), at(18, 40, 60, 80, 120) icodes
    label define age 0 "18 - 40 years" 1 "41 - 60 years" 2 "61 - 80 years" 3 ">80 years"
    label values age_cat age
    bys age_cat: sum age

    *generate a binary rural urban (with missing assigned to urban)
    generate urban_rural_bin=.
    replace urban_rural_bin=1 if urban_rural<=4|urban_rural==.
    replace urban_rural_bin=0 if urban_rural>4 & urban_rural!=.
    label define urban_rural_bin 0 "Rural" 1 "Urban"
    label values urban_rural_bin urban_rural_bin
    safetab urban_rural_bin urban_rural, miss
    label var urban_rural_bin "Rural-Urban"
    
    preserve
    * Create baseline table
    table1_mc, vars(age_cat cat \ sex cat \ imd cat \ urban_rural_bin cat  \  ///
    has_t1_diabetes cat  \ has_t2_diabetes cat \ has_asthma cat \ has_copd cat ) clear
    export delimited using ./output/tables/baseline_table_`i'.csv
    * Rounding numbers in table to nearest 5
    destring _columna_1, gen(n) ignore(",") force
    destring _columnb_1, gen(percent) ignore("-" "%" "(" ")")  force
    gen rounded_n = round(n, 5)
    keep factor level rounded_n percent
    export delimited using ./output/tables/baseline_table_`i'_rounded.csv
    restore
    preserve
    * table by migration status
    table1_mc, vars(age_cat cat \ sex cat \ imd cat \ urban_rural_bin cat  \  ///
    has_t1_diabetes cat  \ has_t2_diabetes cat \ has_asthma cat \ has_copd cat ) by(migration_status) clear
    export delimited using ./output/tables/baseline_table_migration_`i'.csv
    destring _columna_1, gen(n1) ignore(",") force
    destring _columna_0, gen(n0) ignore(",") force
    destring _columnb_1, gen(percent1) ignore("-" "%" "(" ")")  force
    destring _columnb_0, gen(percent0) ignore("-" "%" "(" ")")  force
    gen rounded_n1 = round(n1, 5)
    gen rounded_n0 = round(n0, 5)
    keep factor level rounded_n0 percent0 rounded_n1 percent1
    export delimited using ./output/tables/baseline_table_migration_`i'_rounded.csv
    restore
    
    gen imd_1 = (imd==1)
    gen imd_2 = (imd==2)
    gen imd_3 = (imd==3)
    gen imd_4 = (imd==4)
    gen imd_5 = (imd==5)

    preserve
    table1_mc, vars(age_cat cat \ sex cat \ urban_rural_bin cat  \  ///
    has_t1_diabetes cat  \ has_t2_diabetes cat \ has_asthma cat \ has_copd cat) by(imd) clear
    export delimited using ./output/tables/baseline_table_imd`i'.csv
    destring _columna_1, gen(n1) ignore(",") force
    destring _columnb_1, gen(percent1) ignore("-" "%" "(" ")") force
    destring _columna_2, gen(n2) ignore(",") force
    destring _columnb_2, gen(percent2) ignore("-" "%" "(" ")") force
    destring _columna_3, gen(n3) ignore(",") force
    destring _columnb_3, gen(percent3) ignore("-" "%" "(" ")") force
    destring _columna_4, gen(n4) ignore(",") force
    destring _columnb_4, gen(percent4) ignore("-" "%" "(" ")") force
    destring _columna_5, gen(n5) ignore(",") force
    destring _columnb_5, gen(percent5) ignore("-" "%" "(" ")") force
    gen rounded_n1 = round(n1, 5)
    gen rounded_n2 = round(n2, 5)
    gen rounded_n3 = round(n3, 5)
    gen rounded_n4 = round(n4, 5)
    gen rounded_n5 = round(n5, 5)
    keep factor level rounded_n1 percent1 rounded_n2 percent2 rounded_n3 percent3 rounded_n4 percent4 rounded_n5 percent5
    export delimited using ./output/tables/baseline_table_imd`i'_rounded.csv
    restore
    }

* Close log file 
log close