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
local outcomes "mi_admission stroke_admission heart_failure_admission vte_admission"
*local file "has_t1_diabetes has_t2_diabetes population has_asthma has_copd has_copd"
forvalues i=1/4 {
    local this_outcome: word `i' of `outcomes'
    
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
    format(%dM-CY) labsize(small)) ytitle("Percentage") xtitle("Date") ylabel(0(0.01)0.03, labsize(small) ///
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
    format(%dM-CY) labsize(small)) ytitle("Absolute difference") xtitle("Date") ylabel(-0.01(0.005)0.01, labsize(small) ///
    angle(0)) yscale(r(0) titlegap(*10)) xmtick(##6) legend(row(1) size(small) ///
    title("IMD categories", size(small))) graphregion(fcolor(white))

    graph export ./output/graphs/line_`this_outcome'_diff_imd.svg, as(svg) replace
    * Export data file for output checking 
    export delimited using ./output/graphs/line_data_`this_outcome'_diff_imd.csv
    }

