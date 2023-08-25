/* ===========================================================================
Do file name:   103_poisson_prep.do
Project:        COVID Collateral IMD
Date:           22/05/2023
Author:         Ruth Costello
Description:    Runs prep for poisson regression models in R
==============================================================================*/
cap log using ./logs/poisson_prep.log, replace
cap mkdir ./output/cvd

* outcomes local: 
* file local: 
local outcomes "mi_admission stroke_admission heart_failure_admission vte_admission"
forvalues i=1/4 {
    local this_outcome: word `i' of `outcomes'
    import delimited using ./output/measures/measure_`this_outcome'_imd_rate.csv, numericcols(4) clear
    * IMD shouldn't be missing 
    count if imd==0 | imd==.
    * drop missings (should only be in dummy data)
    drop if imd==0 | imd==.
    * Format date
    gen dateA = date(date, "YMD")
    drop date
    format dateA %dD/M/Y
    * Generate indicator if month is during pandemic
    gen postcovid=(dateA>=date("01/03/2020", "DMY"))
    sort imd date
    gen time_1 = _n if imd==1
    bys date (imd): egen time = max(time_1)
    drop time_1
    rename `this_outcome' numOutcome
    export delimited using ./output/cvd/an_`this_outcome'.csv
}