/* ===========================================================================
Do file name:   102_graphs.do
Project:        COVID Collateral IMD
Date:           04/04/2023
Author:         Ruth Costello
Description:    Generates line graphs of rates of each outcome and strata per month
==============================================================================*/
cap log using ./logs/graphs.log, replace
cap mkdir ./output/graphs

* Generates graphs for each outcome
local outcomes "mi_admission stroke_admission heart_failure_admission vte_admission mh_admission dm_t1 dm_t2 dm_keto resp_asthma_exacerbation resp_copd_exacerbation resp_copd_exac_nolrti"
local file "joined joined joined joined joined dm dm dm resp resp resp"
forvalues i=1/11 {
    local this_outcome: word `i' of `outcomes'
    local this_folder: word `i' of `file'
* IMD
        import delimited using ./output/measures/joined/measure_`this_group'_admission_imd_rate.csv, numericcols(4) clear
        * IMD shouldn't be missing 
        count if imd==.
        * drop missings (should only be in dummy data)
        drop if imd==.
        * Generate rate per 100,000
        gen rate = value*100000 
        * Format date
        gen dateA = date(date, "YMD")
        drop date
        format dateA %dD/M/Y
        * reshape dataset so columns with rates for each ethnicity 
        reshape wide value rate population `this_group'_admission, i(dateA) j(imd)
        describe
        * Labelling ethnicity variables
        label var rate1 "IMD 1"
        label var rate2 "IMD 2"
        label var rate3 "IMD 3"
        label var rate4 "IMD 4"
        label var rate5 "IMD 5"

        * Generate line graph
        graph twoway line rate1 rate2 rate3 rate4 rate5 date, tlabel(01Jan2018(120)31Dec2021, angle(45) ///
        format(%dM-CY) labsize(small)) ytitle("Rate per 100,000") xtitle("Date") ylabel(#5, labsize(small) ///
        angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) ///
        title("Ethnic categories", size(small))) graphregion(fcolor(white))

        graph export ./output/graphs/line_`this_group'_admission_imd.svg, as(svg) replace

        * Plotting first derivative i.e. difference between current rate and previous months rate
        forvalues j=1/5 {
            sort dateA
            gen first_derivative`j' = rate`j' - rate`j'[_n-1]
            }
        * Label variables 
        label var first_derivative1 "IMD 1"
        label var first_derivative2 "IMD 2"
        label var first_derivative3 "IMD 3"
        label var first_derivative4 "IMD 4"
        label var first_derivative5 "IMD 5"
        * Plot this
        graph twoway line first_derivative1 first_derivative2 first_derivative3 first_derivative4 first_derivative5 date, tlabel(01Jan2018(120)31Dec2021, angle(45) ///
        format(%dM-CY) labsize(small)) ytitle("Difference per 100,000") xtitle("Date") ylabel(#5, labsize(small) ///
        angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) ///
        title("Ethnic categories", size(small))) graphregion(fcolor(white))

        graph export ./output/graphs/line_`this_group'_admission_diff_imd.svg, as(svg) replace
        * Export data file for output checking 
        export delimited using ./output/graphs/line_data_`this_group'_admission_diff_imd.csv
    }

foreach this_group in mi stroke heart_failure vte mh {
* Migration status
        import delimited using ./output/measures/joined/measure_`this_group'_admission_migration_status_rate.csv, numericcols(4) clear
        * IMD shouldn't be missing 
        count if migration_status==.
        * drop missings (should only be in dummy data)
        drop if migration_status==.
        * Generate rate per 100,000
        gen rate = value*100000 
        * Format date
        gen dateA = date(date, "YMD")
        drop date
        format dateA %dD/M/Y
        * reshape dataset so columns with rates for each ethnicity 
        reshape wide value rate population `this_group'_admission, i(dateA) j(migration_status)
        describe

        * Generate line graph
        graph twoway line rate0 rate1 date, tlabel(01Jan2018(120)31Dec2021, angle(45) ///
        format(%dM-CY) labsize(small)) ytitle("Rate per 100,000") xtitle("Date") ylabel(#5, labsize(small) ///
        angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) ///
        title("Ethnic categories", size(small))) graphregion(fcolor(white))

        graph export ./output/graphs/line_`this_group'_admission_migration_status.svg, as(svg) replace

        * Plotting first derivative i.e. difference between current rate and previous months rate
        forvalues j=0/1 {
            sort dateA
            gen first_derivative`j' = rate`j' - rate`j'[_n-1]
            }
       
        * Plot this
        graph twoway line first_derivative0 first_derivative1 date, tlabel(01Jan2018(120)31Dec2021, angle(45) ///
        format(%dM-CY) labsize(small)) ytitle("Difference per 100,000") xtitle("Date") ylabel(#5, labsize(small) ///
        angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) ///
        title("Ethnic categories", size(small))) graphregion(fcolor(white))

        graph export ./output/graphs/line_`this_group'_admission_diff_migration_status.svg, as(svg) replace
        * Export data file for output checking 
        export delimited using ./output/graphs/line_data_`this_group'_admission_diff_migration_status.csv
    }

