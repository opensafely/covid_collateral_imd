/* ===========================================================================
Do file name:   102_graphs.do
Project:        COVID Collateral IMD
Date:           04/04/2023
Author:         Ruth Costello
Description:    Generates line graphs of percentage of each outcome and strata per month
==============================================================================*/
cap log using ./logs/graphs.log, replace
cap mkdir ./output/graphs

* CVD outcomes only
* file local:  population
local outcomes "mi_admission heart_failure_admission"
*local file "has_t1_diabetes has_t2_diabetes population has_asthma has_copd has_copd"
forvalues i=1/2 {
    local this_outcome: word `i' of `outcomes'
    *local population: word `i' of `file'
* Generates graphs for each outcome
* IMD
        import delimited using ./output/measures/measure_`this_outcome'_imd_rate.csv, numericcols(4) clear
        * IMD shouldn't be missing 
        count if imd==0 | imd==.
        * drop missings (should only be in dummy data)
        drop if imd==0 | imd==.
        * Generate percentage of population with outcome
        gen percent = value*100
        * Format date
        gen dateA = date(date, "YMD")
        drop date
        format dateA %dD/M/Y
        * reshape dataset so columns with percentage for each IMD category 
        reshape wide value percent population `this_outcome', i(dateA) j(imd)
        describe
        * Labelling IMD variables
        label var percent1 "IMD 1"
        label var percent2 "IMD 2"
        label var percent3 "IMD 3"
        label var percent4 "IMD 4"
        label var percent5 "IMD 5"

        * Generate line graph
        graph twoway line percent1 percent2 percent3 percent4 percent5 date, tlabel(01Mar2018(120)31Dec2021, angle(45) ///
        format(%dM-CY) labsize(small)) ytitle("Percentage") xtitle("Date") ylabel(#5, labsize(small) ///
        angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) ///
        title("IMD categories", size(small))) graphregion(fcolor(white))

        graph export ./output/graphs/line_`this_outcome'_imd.svg, as(svg) replace

        * Plotting first derivative i.e. difference between current percent and previous months percent
        forvalues j=1/5 {
            sort dateA
            gen first_derivative`j' = percent`j' - percent`j'[_n-1]
            }
        * Label variables 
        label var first_derivative1 "IMD 1"
        label var first_derivative2 "IMD 2"
        label var first_derivative3 "IMD 3"
        label var first_derivative4 "IMD 4"
        label var first_derivative5 "IMD 5"
        * Plot this
        graph twoway line first_derivative1 first_derivative2 first_derivative3 first_derivative4 first_derivative5 date, tlabel(01Mar2018(120)31Dec2021, angle(45) ///
        format(%dM-CY) labsize(small)) ytitle("Absolute difference") xtitle("Date") ylabel(#5, labsize(small) ///
        angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) ///
        title("IMD categories", size(small))) graphregion(fcolor(white))

        graph export ./output/graphs/line_`this_outcome'_diff_imd.svg, as(svg) replace
        * Export data file for output checking 
        export delimited using ./output/graphs/line_data_`this_outcome'_diff_imd.csv
    
        /* Migration status
        import delimited using ./output/measures/measure_`this_outcome'_migration_status_rate.csv, numericcols(4) clear
        * migration status shouldn't be missing 
        count if migration_status==.
        * drop missings (should only be in dummy data)
        drop if migration_status==.
        * Generate percentage with outcome
        gen percent = value*100 
        * Format date
        gen dateA = date(date, "YMD")
        drop date
        format dateA %dD/M/Y
        * reshape dataset so columns with percentage for each migration category  
        reshape wide value percent `population' `this_outcome', i(dateA) j(migration_status)
        describe
        
        label var percent0 "Non-migrant"
        label var percent1 "Migrant"

        * Generate line graph
        graph twoway line percent0 percent1 date, tlabel(01Mar2018(120)31Dec2021, angle(45) ///
        format(%dM-CY) labsize(small)) ytitle("Percentage") xtitle("Date") ylabel(#5, labsize(small) ///
        angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) ///
        title("Migration status", size(small))) graphregion(fcolor(white))

        graph export ./output/graphs/line_`this_outcome'_migration_status.svg, as(svg) replace

        * Plotting first derivative i.e. difference between current percent and previous months percent
        forvalues j=0/1 {
            sort dateA
            gen first_derivative`j' = percent`j' - percent`j'[_n-1]
            }

         * Label variables 
        label var first_derivative0 "Non-migrant"
        label var first_derivative1 "Migrant"

        * Plot this
        graph twoway line first_derivative0 first_derivative1 date, tlabel(01Mar2018(120)31Dec2021, angle(45) ///
        format(%dM-CY) labsize(small)) ytitle("Difference (%)") xtitle("Date") ylabel(#5, labsize(small) ///
        angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) ///
        title("Migration status", size(small))) graphregion(fcolor(white))

        graph export ./output/graphs/line_`this_outcome'_diff_migration_status.svg, as(svg) replace
        * Export data file for output checking 
        export delimited using ./output/graphs/line_data_`this_outcome'_diff_migration_status.csv
        */
    }

* Stroke 
import delimited using ./output/measures/measure_stroke_admission_imd_rate.csv, numericcols(4) clear
* IMD shouldn't be missing 
count if imd==0 | imd==.
* drop missings (should only be in dummy data)
drop if imd==0 | imd==.
* Generate percentage of population with outcome
gen percent = value*100
* Format date
gen dateA = date(date, "YMD")
drop date
format dateA %dD/M/Y
* reshape dataset so columns with percentage for each IMD category 
reshape wide value percent population stroke_admission, i(dateA) j(imd)
describe
* Labelling IMD variables
label var percent1 "IMD 1"
label var percent2 "IMD 2"
label var percent3 "IMD 3"
label var percent4 "IMD 4"
label var percent5 "IMD 5"

* Generate line graph
graph twoway line percent1 percent2 percent3 percent4 percent5 date, tlabel(01Mar2018(120)31Dec2021, angle(45) ///
format(%dM-CY) labsize(small)) ytitle("Percentage") xtitle("Date") ylabel(0(0.01)0.03, labsize(small) ///
angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) ///
title("IMD categories", size(small))) graphregion(fcolor(white))

graph export ./output/graphs/line_stroke_admission_imd.svg, as(svg) replace

* Plotting first derivative i.e. difference between current percent and previous months percent
forvalues j=1/5 {
    sort dateA
    gen first_derivative`j' = percent`j' - percent`j'[_n-1]
    }
* Label variables 
label var first_derivative1 "IMD 1"
label var first_derivative2 "IMD 2"
label var first_derivative3 "IMD 3"
label var first_derivative4 "IMD 4"
label var first_derivative5 "IMD 5"
* Plot this
graph twoway line first_derivative1 first_derivative2 first_derivative3 first_derivative4 first_derivative5 date, tlabel(01Mar2018(120)31Dec2021, angle(45) ///
format(%dM-CY) labsize(small)) ytitle("Absolute difference") xtitle("Date") ylabel(#5, labsize(small) ///
angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) ///
title("IMD categories", size(small))) graphregion(fcolor(white))

graph export ./output/graphs/line_stroke_admission_diff_imd.svg, as(svg) replace
* Export data file for output checking 
export delimited using ./output/graphs/line_data_stroke_admission_diff_imd.csv

* VTE 
import delimited using ./output/measures/measure_vte_admission_imd_rate.csv, numericcols(4) clear
* IMD shouldn't be missing 
count if imd==0 | imd==.
* drop missings (should only be in dummy data)
drop if imd==0 | imd==.
* Generate percentage of population with outcome
gen percent = value*100
* Format date
gen dateA = date(date, "YMD")
drop date
format dateA %dD/M/Y
* reshape dataset so columns with percentage for each IMD category 
reshape wide value percent population vte_admission, i(dateA) j(imd)
describe
* Labelling IMD variables
label var percent1 "IMD 1"
label var percent2 "IMD 2"
label var percent3 "IMD 3"
label var percent4 "IMD 4"
label var percent5 "IMD 5"

* Generate line graph
graph twoway line percent1 percent2 percent3 percent4 percent5 date, tlabel(01Mar2018(120)31Dec2021, angle(45) ///
format(%dM-CY) labsize(small)) ytitle("Percentage") xtitle("Date") ylabel(0 (0.005)0.02, labsize(small) ///
angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) ///
title("IMD categories", size(small))) graphregion(fcolor(white))

graph export ./output/graphs/line_vte_admission_imd.svg, as(svg) replace

* Plotting first derivative i.e. difference between current percent and previous months percent
forvalues j=1/5 {
    sort dateA
    gen first_derivative`j' = percent`j' - percent`j'[_n-1]
    }
* Label variables 
label var first_derivative1 "IMD 1"
label var first_derivative2 "IMD 2"
label var first_derivative3 "IMD 3"
label var first_derivative4 "IMD 4"
label var first_derivative5 "IMD 5"
* Plot this
graph twoway line first_derivative1 first_derivative2 first_derivative3 first_derivative4 first_derivative5 date, tlabel(01Mar2018(120)31Dec2021, angle(45) ///
format(%dM-CY) labsize(small)) ytitle("Absolute difference") xtitle("Date") ylabel(#5, labsize(small) ///
angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) ///
title("IMD categories", size(small))) graphregion(fcolor(white))

graph export ./output/graphs/line_vte_admission_diff_imd.svg, as(svg) replace
* Export data file for output checking 
export delimited using ./output/graphs/line_data_vte_admission_diff_imd.csv