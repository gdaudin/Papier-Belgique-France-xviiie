
*Version 2 : 21 juillet -- Ajustant pour prendre en compte les quantités plus nombreuses
*Version 4 -- 2 septembre Ajoutant Poméranie suèdoise
global dir /Users/guillaumedaudin/Documents/Recherche/Commerce XVIIIe-XIXe Europe/Sound/Travail statistique

*local geography Sound
*local geography Sweden
*local geography Russia
*local geography SouthBaltic
*local geography Denmark

*local var_SD taxes
*local var_SD SD_kg
*local var_SD nbr_obs

capture program drop Sound_prepare_BDD
program Sound_prepare_BDD
	args geography
**Exemple : Sound_prepare_BDD Sound



*****
**Agrégation
******

use "$dir/BDD_SUND_FR.dta",clear

if "`geography'"=="Sweden" {
	drop if (small_category_importateur!="Sweden and Finland" & st_name_importateur!="Stralsund" & st_name_importateur!="Greifswald") & exportsimports=="Exports"
	drop if (small_category_exportateur!="Sweden and Finland" & st_name_exportateur!="Stralsund" & st_name_exportateur!="Greifswald") & exportsimports=="Imports"
}

if "`geography'"=="Russia" {
	drop if (small_category_importateur!="Esthonia" & small_category_importateur!="Kurland" & small_category_importateur!="Livland" & small_category_importateur!="Russia around St. Petersburg") & exportsimports=="Exports"
	drop if (small_category_exportateur!="Esthonia" & small_category_exportateur!="Kurland" & small_category_exportateur!="Livland" & small_category_exportateur!="Russia around St. Petersburg") & exportsimports=="Imports"
}

if "`geography'"=="SouthBaltic" {
	drop if (small_category_importateur!="South Baltic: East Prussia to Lubeck") & exportsimports=="Exports"
	drop if (small_category_exportateur!="South Baltic: East Prussia to Lubeck") & exportsimports=="Imports"
}

if "`geography'"=="Denmark" {
	drop if (small_category_importateur!="Denmark") & exportsimports=="Exports"
	drop if (small_category_exportateur!="Denmark") & exportsimports=="Imports"
}

collapse (sum) quantity_final taxes (count) nombre_observations = id_doorvaart, by(année exportsimports sitc_rev2 u_conv)
generate sourceFRSD="Sound"
rename quantity_final quantity_SD

rename année year


save "$dir/BDD_SUND_FR_aggreg2.dta", replace


*****************************

use "$dir/BDD_FR_NORD.dta", clear

if "`geography'"=="Sweden" {
	keep if pays_corriges=="Suède"
}

if "`geography'"=="Russia" {
	keep if pays_corriges=="Russie"
}

if "`geography'"=="SouthBaltic" {
	keep if pays_corriges=="Nord" | pays_corriges =="| pays_corriges=="Pologne" | pays_corriges=="Prusse" | strmatch(pays_corriges,"*hanséatique*")==1
}

if "`geography'"=="Denmark" {
	keep if pays_corriges=="Danemark"
}




collapse (sum) quantity_final value, by(year exportsimports sitc_rev2 u_conv sourceFRSD)

save "$dir/BDD_FR_NORD_aggreg.dta", replace
*******

use "$dir/BDD_FR_NORD_aggreg.dta", replace

rename quantity_final quantity_FR

append using "$dir/BDD_SUND_FR_aggreg2.dta"


replace sitc_rev2 = "0: Foodstuff, various" if sitc_rev2=="0"
replace sitc_rev2 = "0a: Foodstuff, European" if sitc_rev2=="0a"
replace sitc_rev2 = "0b: Foodstuff, Exotic" if sitc_rev2=="0b"
replace sitc_rev2 = "1: Beverages and tobacco" if sitc_rev2=="1"
replace sitc_rev2 = "2: Raw materials" if sitc_rev2=="2"
replace sitc_rev2 = "3: Fuels" if sitc_rev2=="3"
replace sitc_rev2 = "4: Oils" if sitc_rev2=="4"
replace sitc_rev2 = "5: Chemicals" if sitc_rev2=="5"
replace sitc_rev2 = "6: Manuf. goods, by material" if sitc_rev2=="6"
replace sitc_rev2 = "6a: Manuf. goods, linen" if sitc_rev2=="6a"
replace sitc_rev2 = "6b: Manuf. goods, wool" if sitc_rev2=="6b"
replace sitc_rev2 = "6c: Manuf. goods, silk" if sitc_rev2=="6c"
replace sitc_rev2 = "6d: Manuf. goods, coton" if sitc_rev2=="6d"
replace sitc_rev2 = "7: Machinery and transport goods" if sitc_rev2=="7"
replace sitc_rev2 = "8: Misc. manuf. goods" if sitc_rev2=="8"
replace sitc_rev2 = "9: Other (incl. weapons)" if sitc_rev2=="9"
replace sitc_rev2 = "9a: Species" if sitc_rev2=="9a"

save "$dir/BDD_abso.dta", replace

end



************************************************************************************************
capture program drop Sound_prepare_BDD_unit
program Sound_prepare_BDD_unit
	args geography var_SD
**Exemple : Sound_prepare_BDD Sound SD_kg


use "$dir/BDD_abso.dta", clear


replace u_conv="" if sourceFRSD=="France"
rename nombre_observations nbr_obs


if "`var_SD'"=="SD_kg" {
	collapse (sum) value quantity_SD, by(sitc_rev2 u_conv year sourceFRSD exportsimports)
	drop if value==0 & u_conv!="kg"
	rename quantity_SD SD_kg
}


if "`var_SD'"=="taxes" | "`var_SD'"=="nbr_obs" {
	collapse (sum) value `var_SD', by(sitc_rev2 year sourceFRSD exportsimports)
}


drop if `var_SD' ==0 & value==0


generate source="`var_SD'" if `var_SD' !=0
replace source="FRvalues" if value !=0

save "$dir/BDD_`var_SD'.dta", replace


end
************************************************************************************************
**********
***Exploitation quantity FR et SD
***********

capture program drop Sound_absolute
program Sound_absolute
	args geography
**Exemple : Sound_absolute Sound






use "$dir/BDD_abso.dta", clear

keep if year==1750 | year==1771 | year==1772 | year==1774 | year==1775 | year==1776 | year==1777 | year==1779 | year==1780 | year==1782 | year==1787 | year==1789

collapse (sum) quantity_FR quantity_SD value, by(sitc_rev2 u_conv year sourceFRSD exportsimports)

drop if quantity_FR==0 & quantity_SD==0 & value==0

***Wikipedia (1 danish rigsdaler = 4/37th of Cologne Mark (233.856 fine silver))
replace quantity_SD = quantity_SD*4*233.856/37/1000 if u_conv=="rigsdaler"
*replace quantity_SD =. if u_conv=="rigsdaler"
replace quantity_FR = value*4.505/1000 if sourceFRSD=="France" & u_conv == ""
replace u_conv="silver kg" if u_conv=="rigsdaler" | u_conv==""

replace quantity_SD = quantity_SD/100 if u_conv=="cm"
replace u_conv="m" if u_conv=="cm"

replace u_conv="pieces" if u_conv=="pcs"

replace value=. if value==0
replace quantity_FR=. if quantity_FR ==0
replace quantity_SD=. if quantity_SD ==0



/*
graph bar (sum) quantity_FR quantity_SD if u_conv=="kg" , over(sourceFRSD) by(exportsimports) title("`geography', kg, 1750-1789 (-)")
graph export "$dir/Graphiques transversaux/`geography'/Graph_Tot_kg_1750-1789.png", replace 
graph save "$dir/Graphiques transversaux/`geography'/Graph_tot_kg_1750-1789.gph", replace 

graph bar (sum) quantity_FR quantity_SD if u_conv=="pcs" , over(sourceFRSD) by( exportsimports) title("`geography', pcs, 1750-1789 (-)") 
graph export "$dir/Graphiques transversaux/`geography'/Graph_Tot_pcs_g-1789.png", replace 
graph save "$dir/Graphiques transversaux/`geography'/Graph_Tot_pcs_1750-1789.gph", replace 

graph bar (sum) quantity_FR quantity_SD if (u_conv=="silver_kg") , over(sourceFRSD) by(exportsimports) title("`geography', silver kg, 1750-1789 (-)") 
graph export "$dir/Graphiques transversaux/`geography'/Graph_Tot_silver_1750-1789.png", replace 
graph save "$dir/Graphiques transversaux/`geography'/Graph_Tot_silver_1750-1789.gph", replace 
*/

save "$dir/Blouk.dta", replace

collapse (sum) quantity_FR quantity_SD,by (u_conv sourceFRSD exportsimports)


generate quantity = max(quantity_FR,quantity_SD)
drop quantity_FR quantity_SD

reshape wide quantity, i(u_conv exportsimports) j(sourceFRSD) string
sort exportsimports u_conv

format quantity* %11.0fc

display "***************`geography' -- Total *********************************"

list



export excel using "/Users/guillaumedaudin/Documents/Recherche/Commerce XVIIIe-XIXe Europe/Sound/Travail statistique/Tableaux/`geography'.xls", firstrow(variables) replace






use "$dir/Blouk.dta", clear

levelsof sitc_rev2, local(liste_sitc_rev2)
preserve
foreach secteur of local liste_sitc_rev2 {
	keep if sitc_rev2 == "`secteur'"
	
	collapse (sum) quantity_FR quantity_SD,by (u_conv sourceFRSD exportsimports)


	generate quantity = max(quantity_FR,quantity_SD)
	drop quantity_FR quantity_SD

	reshape wide quantity, i(u_conv exportsimports) j(sourceFRSD) string
	sort exportsimports u_conv

	format quantity* %11.0fc

	display "***************`geography' -- `secteur' *********************************"

	list

	export excel using "/Users/guillaumedaudin/Documents/Recherche/Commerce XVIIIe-XIXe Europe/Sound/Travail statistique/Tableaux/`geography'--`secteur'.xls", firstrow(variables) replace
	restore
	preserve
}



end





/*
levelsof sitc_rev2, local(liste_sitc_rev2)
levelsof exportsimports, local(expimp)

foreach secteur of local liste_sitc_rev2 {
	foreach dir of local expimp {

		capture graph bar (sum) quantity_FR quantity_SD if sitc_rev2 =="`secteur'" & u_conv=="kg" & exportsimports=="`dir'", over(sourceFRSD) title("`geography', `secteur', `dir', kg, 1780")  
		capture  graph export "$dir/Graphiques transversaux/`geography'/Graph_`dir'_`secteur'_kg_1780.png", replace 
		capture  graph save   "$dir/Graphiques transversaux/`geography'/Graph_`dir'_`secteur'_kg_1780.gph", replace  

		capture graph bar (sum) quantity_FR quantity_SD if sitc_rev2 =="`secteur'" & u_conv=="pcs" & exportsimports=="`dir'", over(sourceFRSD) title("`geography', `secteur', `dir', pcs, 1780") 
		capture  graph export "$dir/Graphiques transversaux/`geography'/Graph_`dir'_`secteur'_pcs_1780.png", replace 
		capture  graph save   "$dir/Graphiques transversaux/`geography'/Graph_`dir'_`secteur'_pcs_1780.gph", replace 

		capture graph bar (sum) value if sitc_rev2 =="`secteur'" & (u_conv=="rigsdaler" | sourceFRSD=="France") & exportsimports=="`dir'", over(sourceFRSD) title("`geography', `secteur', `dir', silver kg, 1780") 
		capture  graph export "$dir/Graphiques longitudinaux/`geography'/Graph_`dir'_`secteur'_silver_1780.png", replace
		capture  graph save   "$dir/Graphiques longitudinaux/`geography'/Graph_`dir'_`secteur'_silver_1780.gph", replace
	}
}


*/



************************************************************************************************************************


**********
***Exploitation valeur FR et autres
***********



**********
***Exploitation -- Longitudinal
***********


******Pour la France

capture program drop Fr_longi
program Fr_longi 
	args geography
	
local var_SD = "SD_kg"
	
use "$dir/BDD_`var_SD'.dta", clear


generate number = max(`var_SD',value)
drop sourceFRSD value `var_SD'
rename number number_norm

drop u_conv
reshape wide number_norm, i(year exportsimports sitc_rev2) j(source) string



label variable number_normFRvalues "French data"

label variable number_norm`var_SD' "Sound data"

quietly levelsof sitc_rev2, local(liste_sitc_rev2)



foreach secteur of local liste_sitc_rev2 {
	preserve
	capture generate ln_number =ln(number_normFRvalues)
	capture noisily regress ln_number year if year<=1789 & sitc_rev2=="`secteur'" & exportsimports=="Exports"
	
	if _rc==0 {
 *		estimate store Fr_`geography'_`secteur'_Exp_0
		clear
		set obs 1
		capture matrix Coef = e(b)
		capture matrix VCov = e(V)
		generate Geography="`geography'"
		generate var="France"
		generate Timetrend = Coef[1,1]
		generate sd= VCov[1,1]^0.5
		generate ImportExport ="Exports"
		generate sitc_rev2 ="`secteur'"
		generate adj=0
		append using "$dir/Graphiques longitudinaux/Timetrend.dta"
		save "$dir/Graphiques longitudinaux/Timetrend.dta", replace
	
	}
	restore
		
	
	
	preserve
	capture generate ln_number =ln(number_normFRvalues)
	capture noisily regress ln_number year if year<=1789 & sitc_rev2=="`secteur'" & exportsimports=="Imports"
	
	if _rc==0 {
*		estimate store Fr_`geography'_`secteur'_Imp_0
		clear
		set obs 1
		capture matrix Coef = e(b)
		capture matrix VCov = e(V)
		generate Geography="`geography'"
		generate var="France"
		generate Timetrend = Coef[1,1]
		generate sd= VCov[1,1]^0.5
		generate ImportExport ="Imports"
		generate sitc_rev2 ="`secteur'"
		generate adj=0
		append using "$dir/Graphiques longitudinaux/Timetrend.dta"
		save "$dir/Graphiques longitudinaux/Timetrend.dta", replace
	
	}
	restore
	
	
	
	
}



*******SECTORIEL AJUSTÉ


collapse (sum) number_normFRvalues number_norm`var_SD', by(exportsimports sitc_rev2 year)




foreach secteur of local liste_sitc_rev2 {

	preserve
	quietly summarize number_normFRvalues if exportsimports=="Exports" & sitc_rev2=="`secteur'", det
	replace number_normFRvalues = . if number_normFRvalues>=r(p95) | number_normFRvalues<=r(p5)
	
	
	capture generate ln_number =ln(number_normFRvalues)
	capture noisily regress ln_number year if year<=1789 & sitc_rev2=="`secteur'" & exportsimports=="Exports"
	
	if _rc==0 {
*		estimate store Fr_`geography'_`secteur'_Exp_1
		clear
		set obs 1
		capture matrix Coef = e(b)
		capture matrix VCov = e(V)
		generate Geography="`geography'"
		generate var="France"
		generate Timetrend = Coef[1,1]
		generate sd= VCov[1,1]^0.5
		generate ImportExport ="Exports"
		generate sitc_rev2 ="`secteur'"
		generate adj=1
		append using "$dir/Graphiques longitudinaux/Timetrend.dta"
		save "$dir/Graphiques longitudinaux/Timetrend.dta", replace
	
	}
	restore
	
	preserve	
	quietly summarize number_normFRvalues if exportsimports=="Imports" & sitc_rev2=="`secteur'", det
	replace number_normFRvalues = . if number_normFRvalues>=r(p95) | number_normFRvalues<=r(p5)
		
	capture generate ln_number =ln(number_normFRvalues)
	capture noisily regress ln_number year if year<=1789 & sitc_rev2=="`secteur'" & exportsimports=="Imports"

	if _rc==0 {
*		estimate store Fr_`geography'_`secteur'_Imp_1
		clear
		set obs 1
		capture matrix Coef = e(b)
		capture matrix VCov = e(V)
		generate Geography="`geography'"
		generate var="France"
		generate Timetrend = Coef[1,1]
		generate sd= VCov[1,1]^0.5
		generate ImportExport ="Imports"
		generate sitc_rev2 ="`secteur'"
		generate adj=1
		append using "$dir/Graphiques longitudinaux/Timetrend.dta"
		save "$dir/Graphiques longitudinaux/Timetrend.dta", replace
	}
	restore
		
}


**************TOTAL


collapse (sum) number_normFRvalues number_norm`var_SD', by(year exportsimports)

label variable number_normFRvalues "French data"

replace number_normFRvalues=. if number_normFRvalues==0


sort year


preserve
capture generate ln_number =ln(number_normFRvalues)
capture noisily regress ln_number year if year<=1789  & exportsimports=="Exports"

if _rc==0 {
*	estimate store Fr_`geography'_Total_Exp_0
	clear
	set obs 1
	capture matrix Coef = e(b)
	capture matrix VCov = e(V)
	generate Geography="`geography'"
	generate var="France"
	generate Timetrend = Coef[1,1]
	generate sd= VCov[1,1]^0.5
	generate ImportExport ="Exports"
	generate sitc_rev2 ="Total"
	generate adj=0
	append using "$dir/Graphiques longitudinaux/Timetrend.dta"
	save "$dir/Graphiques longitudinaux/Timetrend.dta", replace
	
	}
restore



preserve
capture generate ln_number =ln(number_normFRvalues)
capture noisily regress ln_number year if year<=1789  & exportsimports=="Imports"

if _rc==0 {
 *	estimate store Fr_`geography'_Total_Imp_0
	clear
	set obs 1
	capture matrix Coef = e(b)
	capture matrix VCov = e(V)
	generate Geography="`geography'"
	generate var="France"
	generate Timetrend = Coef[1,1]
	generate sd= VCov[1,1]^0.5
	generate ImportExport ="Imports"
	generate sitc_rev2 ="Total"
	generate adj=0
	append using "$dir/Graphiques longitudinaux/Timetrend.dta"
	save "$dir/Graphiques longitudinaux/Timetrend.dta", replace
	
	}
restore




********TOTAL AJUSTÉ

preserve
quietly summarize number_normFRvalues if exportsimports=="Exports", det
replace number_normFRvalues = . if number_normFRvalues>=r(p95) | number_normFRvalues<=r(p5)


capture generate ln_number =ln(number_normFRvalues)
capture noisily regress ln_number year if year<=1789  & exportsimports=="Exports"

if _rc==0 {
*	estimate store Fr_`geography'_Total_Exp_1
	clear
	set obs 1
	capture matrix Coef = e(b)
	capture matrix VCov = e(V)
	generate Geography="`geography'"
	generate var="France"
	generate Timetrend = Coef[1,1]
	generate sd= VCov[1,1]^0.5
	generate ImportExport ="Exports"
	generate sitc_rev2 ="Total"
	generate adj=1
	append using "$dir/Graphiques longitudinaux/Timetrend.dta"
	save "$dir/Graphiques longitudinaux/Timetrend.dta", replace
	
	}
restore


preserve
quietly summarize number_normFRvalues if exportsimports=="Imports", det

replace number_normFRvalues = . if number_normFRvalues>=r(p95) | number_normFRvalues<=r(p5)

capture generate ln_number =ln(number_normFRvalues)
capture noisily regress ln_number year if year<=1789  & exportsimports=="Imports"
*capture estimate store Fr_`geography'_Total_Imp_1   
if _rc==0 {
	clear
	set obs 1
	capture matrix Coef = e(b)
	capture matrix VCov = e(V)
	generate Geography="`geography'"
	generate var="France"
	generate Timetrend = Coef[1,1]
	generate sd= VCov[1,1]^0.5
	generate ImportExport ="Imports"
	generate sitc_rev2 ="Total"
	generate adj=1
	append using "$dir/Graphiques longitudinaux/Timetrend.dta"
	save "$dir/Graphiques longitudinaux/Timetrend.dta", replace	
	}
restore



end



**********Pour les données Sound





capture program drop Sound_longi
program Sound_longi 
	args geography var_SD



use "$dir/BDD_`var_SD'.dta", clear
*keep if year==1750 | year==1752 | year==1754 | year==1757 | year==1759 | year==1761 | year==1767 | year==1769| year==1771 | year==1772 | year==1774 | year==1775 | year==1776 | year==1777 | year==1780 | year==1787 | year==1789


generate number = max(`var_SD',value)
drop sourceFRSD value `var_SD'

*generate blouk = number if year==1750
*bys exportsimport source sitc_rev2: egen number_1750=max(blouk)
*drop blouk
*generate number_norm = number / number_1750
*drop number number_1750
rename number number_norm

if "`var_SD'"=="SD_kg" {
	drop u_conv
	reshape wide number_norm, i(year exportsimports sitc_rev2) j(source) string
	
}


if "`var_SD'"=="taxes" | "`var_SD'"=="nbr_obs" {
	reshape wide number_norm, i(year exportsimports sitc_rev2) j(source) string
}




label variable number_normFRvalues "French data"

label variable number_norm`var_SD' "Sound data"

quietly levelsof sitc_rev2, local(liste_sitc_rev2)



foreach secteur of local liste_sitc_rev2 {

	capture corr number_normFRvalues number_norm`var_SD' if exportsimports=="Exports" & sitc_rev2=="`secteur'"
	local corr : display %3.2f r(rho)
	display `corr'
	

	twoway (connected number_norm`var_SD' year if exportsimports=="Exports" & sitc_rev2=="`secteur'", yaxis(1)) (connected number_normFRvalues year if exportsimports=="Exports" & sitc_rev2=="`secteur'", yaxis(2)), yscale(range(0 2)) title("French Exports, `geography', `var_SD', `secteur'") subtitle("Corr : `corr'")
	graph export "$dir/Graphiques longitudinaux/`geography'/Graph_Exports_`secteur'_`var_SD'.png", replace as(png)
	graph save "$dir/Graphiques longitudinaux/`geography'/Graph_Exports_`secteur'_`var_SD'.gph", replace
	
	preserve
	clear
	set obs 1
	generate Geography="`geography'"
	generate var_SD="`var_SD'"
	generate Correlation = `corr' 
	generate ImportExport ="Exports"
	generate sitc_rev2 ="`secteur'"
	generate adj=0
	append using "$dir/Graphiques longitudinaux/Correlations.dta"
	save "$dir/Graphiques longitudinaux/Correlations.dta", replace
	restore
	
	
	
	preserve
	capture generate ln_number =ln(number_norm`var_SD')
	capture noisily regress ln_number year if year<=1789 & sitc_rev2=="`secteur'" & exportsimports=="Exports"
	if _rc==0 {
		clear
		set obs 1
		capture matrix Coef = e(b)
		capture matrix VCov = e(V)
		generate Geography="`geography'"
		generate var="`var_SD'"
		generate Timetrend = Coef[1,1]
		generate sd= VCov[1,1]^0.5
		generate ImportExport ="Exports"
		generate sitc_rev2 ="`secteur'"
		generate adj=0
		append using "$dir/Graphiques longitudinaux/Timetrend.dta"
		save "$dir/Graphiques longitudinaux/Timetrend.dta", replace
	
	}
	restore
		
	
	
	capture corr number_normFRvalues number_norm`var_SD' if exportsimports=="Imports" & sitc_rev2=="`secteur'"
	local corr : display %3.2f r(rho)

	twoway (connected number_norm`var_SD' year if exportsimports=="Imports" & sitc_rev2=="`secteur'", yaxis(1)) (connected number_normFRvalues year if exportsimports=="Imports" & sitc_rev2=="`secteur'", yaxis(2)), yscale(range(0 2)) title("French Imports, `geography', `var_SD', `secteur'") subtitle("Corr : `corr'")
	graph export "$dir/Graphiques longitudinaux/`geography'/Graph_Imports_`secteur'_`var_SD'.png", replace as(png)
	graph save "$dir/Graphiques longitudinaux/`geography'/Graph_Imports_`secteur'_`var_SD'.gph", replace 
	
	
	preserve
	clear
	set obs 1
	generate Geography="`geography'"
	generate var_SD="`var_SD'"
	generate Correlation = `corr' 
	generate ImportExport ="Imports"
	generate sitc_rev2 ="`secteur'"
	generate adj=0
	append using "$dir/Graphiques longitudinaux/Correlations.dta"
	save "$dir/Graphiques longitudinaux/Correlations.dta", replace
	restore
	
	
	preserve
	capture generate ln_number =ln(number_norm`var_SD')
	capture noisily regress ln_number year if year<=1789 & sitc_rev2=="`secteur'" & exportsimports=="Imports"
*	capture estimate store `var_SD'_`geography'_`secteur'_Imports_0
	if _rc==0 {
		clear
		set obs 1
		capture matrix Coef = e(b)
		capture matrix VCov = e(V)
		generate Geography="`geography'"
		generate var="`var_SD'"
		generate Timetrend = Coef[1,1]
		generate sd= VCov[1,1]^0.5
		generate ImportExport ="Imports"
		generate sitc_rev2 ="`secteur'"
		generate adj=0
		append using "$dir/Graphiques longitudinaux/Timetrend.dta"
		save "$dir/Graphiques longitudinaux/Timetrend.dta", replace
	
	}
	restore
	
	
	
	
}



*******SECTORIEL AJUSTÉ


collapse (sum) number_normFRvalues number_norm`var_SD', by(exportsimports sitc_rev2 year)




foreach secteur of local liste_sitc_rev2 {

	preserve

	keep if exportsimports=="Exports" & sitc_rev2=="`secteur'"
	quietly summarize number_norm`var_SD', det
	replace number_norm`var_SD' = . if number_norm`var_SD'>=r(p95) | number_norm`var_SD'<=r(p5)

	quietly summarize number_normFRvalues, det
	replace number_normFRvalues = . if number_normFRvalues>=r(p95) | number_normFRvalues<=r(p5)

	capture corr number_normFRvalues number_norm`var_SD' if exportsimports=="Exports" & sitc_rev2=="`secteur'"
	local corr : display %3.2f r(rho)

	twoway (connected number_norm`var_SD' year if exportsimports=="Exports" & sitc_rev2=="`secteur'", yaxis(1)) (connected number_normFRvalues year if exportsimports=="Exports" & sitc_rev2=="`secteur'", yaxis(2)), yscale(range(0 2)) title("French Exports, `geography', `var_SD', trimmed, `secteur'") subtitle("Corr : `corr'")
	graph export "$dir/Graphiques longitudinaux/`geography'/Graph_Exports_`secteur'_`var_SD'_ADJ.png", replace as(png)
	graph save "$dir/Graphiques longitudinaux/`geography'/Graph_Exports_`secteur'_`var_SD'_ADJ.gph", replace
	
	
	clear
	set obs 1
	generate Geography="`geography'"
	generate var_SD="`var_SD'"
	generate Correlation = `corr' 
	generate ImportExport ="Exports"
	generate sitc_rev2 ="`secteur'"
	generate adj=1
	append using "$dir/Graphiques longitudinaux/Correlations.dta"
	save "$dir/Graphiques longitudinaux/Correlations.dta", replace	
	restore
	
	preserve
	
	
	keep if exportsimports=="Exports" & sitc_rev2=="`secteur'"
	quietly summarize number_norm`var_SD', det
	replace number_norm`var_SD' = . if number_norm`var_SD'>=r(p95) | number_norm`var_SD'<=r(p5)

	quietly summarize number_normFRvalues, det
	replace number_normFRvalues = . if number_normFRvalues>=r(p95) | number_normFRvalues<=r(p5)
	
	
	
	
	capture generate ln_number =ln(number_norm`var_SD')
	capture noisily regress ln_number year if year<=1789 & sitc_rev2=="`secteur'" & exportsimports=="Exports"
*	capture estimate store `var_SD'_`geography'_`secteur'_Exports_1
	if _rc==0 {
		clear
		set obs 1
		capture matrix Coef = e(b)
		capture matrix VCov = e(V)
		generate Geography="`geography'"
		generate var="`var_SD'"
		generate Timetrend = Coef[1,1]
		generate sd= VCov[1,1]^0.5
		generate ImportExport ="Exports"
		generate sitc_rev2 ="`secteur'"
		generate adj=1
		append using "$dir/Graphiques longitudinaux/Timetrend.dta"
		save "$dir/Graphiques longitudinaux/Timetrend.dta", replace
	
	}
	restore
	
	
	preserve
	keep if exportsimports=="Imports" & sitc_rev2=="`secteur'"
	quietly summarize number_norm`var_SD', det
	replace number_norm`var_SD' = . if number_norm`var_SD'>=r(p95) | number_norm`var_SD'<=r(p5)

	quietly summarize number_normFRvalues, det
	replace number_normFRvalues = . if number_normFRvalues>=r(p95) | number_normFRvalues<=r(p5)
	
	capture corr number_normFRvalues number_norm`var_SD' if exportsimports=="Imports" & sitc_rev2=="`secteur'"
	local corr : display %3.2f r(rho)

	twoway (connected number_norm`var_SD' year if exportsimports=="Imports" & sitc_rev2=="`secteur'", yaxis(1)) (connected number_normFRvalues year if exportsimports=="Imports" & sitc_rev2=="`secteur'", yaxis(2)), yscale(range(0 2)) title("French Imports, `geography', `var_SD', trimmed, `secteur'") subtitle("Corr : `corr'")
	graph export "$dir/Graphiques longitudinaux/`geography'/Graph_Imports_`secteur'_`var_SD'_ADJ.png", replace as(png)
	graph save "$dir/Graphiques longitudinaux/`geography'/Graph_Imports_`secteur'_`var_SD'_ADJ.gph", replace 

	clear
	set obs 1
	generate Geography="`geography'"
	generate var_SD="`var_SD'"
	generate Correlation = `corr' 
	generate ImportExport ="Imports"
	generate sitc_rev2 ="`secteur'"
	generate adj=1
	append using "$dir/Graphiques longitudinaux/Correlations.dta"
	save "$dir/Graphiques longitudinaux/Correlations.dta", replace
	restore
	
	
	
	
	preserve
	
	keep if exportsimports=="Exports" & sitc_rev2=="`secteur'"
	quietly summarize number_norm`var_SD', det
	replace number_norm`var_SD' = . if number_norm`var_SD'>=r(p95) | number_norm`var_SD'<=r(p5)

	quietly summarize number_normFRvalues, det
	replace number_normFRvalues = . if number_normFRvalues>=r(p95) | number_normFRvalues<=r(p5)
	
	
	
	capture generate ln_number =ln(number_norm`var_SD')
	capture noisily regress ln_number year if year<=1789 & sitc_rev2=="`secteur'" & exportsimports=="Imports"
*	capture estimate store `var_SD'_`geography'_`secteur'_Imports_1
	if _rc==0 {
		clear
		set obs 1
		capture matrix Coef = e(b)
		capture matrix VCov = e(V)
		generate Geography="`geography'"
		generate var="`var_SD'"
		generate Timetrend = Coef[1,1]
		generate sd= VCov[1,1]^0.5
		generate ImportExport ="Imports"
		generate sitc_rev2 ="`secteur'"
		generate adj=1
		append using "$dir/Graphiques longitudinaux/Timetrend.dta"
		save "$dir/Graphiques longitudinaux/Timetrend.dta", replace
	}
	restore
		
	
}


*/

/*
*local geography Sound
*local geography Sweden
local geography Russia
*local geography SouthBaltic
*local geography Denmark

local var_SD SD_kg
*local var_SD taxes
*local var_SD nbr_obs

*/

**************TOTAL


collapse (sum) number_normFRvalues number_norm`var_SD', by(year exportsimports)

label variable number_normFRvalues "French data"

label variable number_norm`var_SD' "Sound data"

replace number_normFRvalues=. if number_normFRvalues==0
replace number_norm`var_SD' =. if number_norm`var_SD' ==0

*generate bloukFR = number_normFRvalues if year==1750
*bys exportsimport: egen number_1750=max(bloukFR)
*drop bloukFR
*replace number_normFRvalues = number_normFRvalues / number_1750
*drop number_1750

*generate bloukSD = number_norm`var_SD' if year==1750
*bys exportsimport: egen number_1750=max(bloukSD)
*drop bloukSD
*replace number_norm`var_SD' = number_norm`var_SD' / number_1750
*drop number_1750


sort year

capture corr number_normFRvalues number_norm`var_SD' if exportsimports=="Exports"
local corr : display %3.2f r(rho)



preserve
clear
set obs 1
generate Geography="`geography'"
generate var_SD="`var_SD'"
generate Correlation = `corr' 
generate ImportExport ="Exports"
generate sitc_rev2 ="Total"
generate adj=0
append using "$dir/Graphiques longitudinaux/Correlations.dta"
save "$dir/Graphiques longitudinaux/Correlations.dta", replace
restore


preserve
capture generate ln_number =ln(number_norm`var_SD')
capture noisily regress ln_number year if year<=1789  & exportsimports=="Exports"
*capture estimate store `var_SD'_`geography'_Total_Exports_0
if _rc==0 {
	clear
	set obs 1
	capture matrix Coef = e(b)
	capture matrix VCov = e(V)
	generate Geography="`geography'"
	generate var="`var_SD'"
	generate Timetrend = Coef[1,1]
	generate sd= VCov[1,1]^0.5
	generate ImportExport ="Exports"
	generate sitc_rev2 ="Total"
	generate adj=0
	append using "$dir/Graphiques longitudinaux/Timetrend.dta"
	save "$dir/Graphiques longitudinaux/Timetrend.dta", replace
	
	}
restore




twoway (connected number_norm`var_SD' year if exportsimports=="Exports", yaxis(1)) (connected number_normFRvalues year if exportsimports=="Exports", yaxis(2)), yscale(range(0 2)) title("French Exports, `geography', `var_SD', Total") subtitle("Corr : `corr'")
graph export "$dir/Graphiques longitudinaux/`geography'/Graph_Exports_tot_`var_SD'.png", replace 
graph save "$dir/Graphiques longitudinaux/`geography'/Graph_Exports_tot_`var_SD'.gph", replace 


display "************`geography'*******"

capture corr number_normFRvalues number_norm`var_SD' if exportsimports=="Imports"
local corr : display %3.2f r(rho)

preserve
clear
set obs 1
generate Geography="`geography'"
generate var_SD="`var_SD'"
generate Correlation = `corr' 
generate ImportExport ="Imports"
generate sitc_rev2 ="Total"
generate adj=0
append using "$dir/Graphiques longitudinaux/Correlations.dta"
save "$dir/Graphiques longitudinaux/Correlations.dta", replace
restore



preserve
capture generate ln_number =ln(number_norm`var_SD')
capture noisily regress ln_number year if year<=1789  & exportsimports=="Imports"
*capture estimate store `var_SD'_`geography'_Total_Imports_0
if _rc==0 {
	clear
	set obs 1
	capture matrix Coef = e(b)
	capture matrix VCov = e(V)
	generate Geography="`geography'"
	generate var="`var_SD'"
	generate Timetrend = Coef[1,1]
	generate sd= VCov[1,1]^0.5
	generate ImportExport ="Imports"
	generate sitc_rev2 ="Total"
	generate adj=0
	append using "$dir/Graphiques longitudinaux/Timetrend.dta"
	save "$dir/Graphiques longitudinaux/Timetrend.dta", replace
	
	}
restore



twoway (connected number_norm`var_SD' year if exportsimports=="Imports", yaxis(1)) (connected number_normFRvalues year if exportsimports=="Imports", yaxis(2)), yscale(range(0 2)) title("French Imports, `geography', `var_SD', Total") subtitle("Corr : `corr'")
graph export "$dir/Graphiques longitudinaux/`geography'/Graph_Imports_tot_`var_SD'.png", replace 
graph save "$dir/Graphiques longitudinaux/`geography'/Graph_Imports_tot_`var_SD'.gph", replace 


********TOTAL AJUSTÉ

preserve
keep if exportsimports=="Exports"

quietly summarize number_norm`var_SD', det
replace number_norm`var_SD' = . if number_norm`var_SD'>=r(p95) | number_norm`var_SD'<=r(p5)

quietly summarize number_normFRvalues, det
replace number_normFRvalues = . if number_normFRvalues>=r(p95) | number_normFRvalues<=r(p5)

capture corr number_normFRvalues number_norm`var_SD' if exportsimports=="Exports"
local corr : display %3.2f r(rho)


twoway (connected number_norm`var_SD' year if exportsimports=="Exports", yaxis(1)) (connected number_normFRvalues year if exportsimports=="Exports", yaxis(2)), yscale(range(0 2)) title("French Exports, `geography', `var_SD', trimmed, Total") subtitle("Corr : `corr'")
graph export "$dir/Graphiques longitudinaux/`geography'/Graph_Exports_tot_`var_SD'_ADJ.png", replace 
graph save "$dir/Graphiques longitudinaux/`geography'/Graph_Exports_tot_`var_SD'_ADJ.gph", replace 



clear
set obs 1
generate Geography="`geography'"
generate var_SD="`var_SD'"
generate Correlation = `corr' 
generate ImportExport ="Exports"
generate sitc_rev2 ="Total"
generate adj=1
append using "$dir/Graphiques longitudinaux/Correlations.dta"
save "$dir/Graphiques longitudinaux/Correlations.dta", replace
restore


preserve


keep if exportsimports=="Exports"
quietly summarize number_norm`var_SD', det
replace number_norm`var_SD' = . if number_norm`var_SD'>=r(p95) | number_norm`var_SD'<=r(p5)
quietly summarize number_normFRvalues, det
replace number_normFRvalues = . if number_normFRvalues>=r(p95) | number_normFRvalues<=r(p5)


capture generate ln_number =ln(number_norm`var_SD')
capture noisily regress ln_number year if year<=1789  & exportsimports=="Exports"
*capture estimate store `var_SD'_`geography'_Total_Exports_1
if _rc==0 {
	clear
	set obs 1
	capture matrix Coef = e(b)
	capture matrix VCov = e(V)
	generate Geography="`geography'"
	generate var="`var_SD'"
	generate Timetrend = Coef[1,1]
	generate sd= VCov[1,1]^0.5
	generate ImportExport ="Exports"
	generate sitc_rev2 ="Total"
	generate adj=1
	append using "$dir/Graphiques longitudinaux/Timetrend.dta"
	save "$dir/Graphiques longitudinaux/Timetrend.dta", replace
	
	}
restore






display "*****************************`geography'***************************"

preserve
keep if exportsimports=="Imports"

quietly summarize number_norm`var_SD', det
replace number_norm`var_SD' = . if number_norm`var_SD'>=r(p95) | number_norm`var_SD'<=r(p5)

quietly summarize number_normFRvalues, det
replace number_normFRvalues = . if number_normFRvalues>=r(p95) | number_normFRvalues<=r(p5)

capture corr number_normFRvalues number_norm`var_SD' if exportsimports=="Imports"
local corr : display %3.2f r(rho)

twoway (connected number_norm`var_SD' year if exportsimports=="Imports", yaxis(1)) (connected number_normFRvalues year if exportsimports=="Imports", yaxis(2)), yscale(range(0 2)) title("French Imports, `geography', `var_SD', trimmed, Total") subtitle("Corr : `corr'")
graph export "$dir/Graphiques longitudinaux/`geography'/Graph_Imports_tot_`var_SD'_ADJ.png", replace 
graph save "$dir/Graphiques longitudinaux/`geography'/Graph_Imports_tot_`var_SD'_ADJ.gph", replace 


clear
set obs 1
generate Geography="`geography'"
generate var_SD="`var_SD'"
generate Correlation = `corr' 
generate ImportExport ="Imports"
generate sitc_rev2 ="Total"
generate adj=1
append using "$dir/Graphiques longitudinaux/Correlations.dta"
save "$dir/Graphiques longitudinaux/Correlations.dta", replace
restore

preserve

keep if exportsimports=="Imports"
quietly summarize number_norm`var_SD', det
replace number_norm`var_SD' = . if number_norm`var_SD'>=r(p95) | number_norm`var_SD'<=r(p5)
quietly summarize number_normFRvalues, det
replace number_normFRvalues = . if number_normFRvalues>=r(p95) | number_normFRvalues<=r(p5)

capture generate ln_number =ln(number_norm`var_SD')
capture noisily regress ln_number year if year<=1789  & exportsimports=="Imports"
*capture estimate store `var_SD'_`geography'_Total_Imports_1
if _rc==0 {
	clear
	set obs 1
	capture matrix Coef = e(b)
	capture matrix VCov = e(V)
	generate Geography="`geography'"
	generate var="`var_SD'"
	generate Timetrend = Coef[1,1]
	generate sd= VCov[1,1]^0.5
	generate ImportExport ="Imports"
	generate sitc_rev2 ="Total"
	generate adj=1
	append using "$dir/Graphiques longitudinaux/Timetrend.dta"
	save "$dir/Graphiques longitudinaux/Timetrend.dta", replace	
	}
restore



end



************************************************************************************************************************
**********
***Exploitation -- Transversal
***********
************************************************************************************************************************

capture program drop Sound_trans
program Sound_trans 
	args geography var_SD



use "$dir/BDD_`var_SD'.dta", clear
keep if year==1750 | year==1752 | year==1754 | year==1756 | year==1757 | year==1758 | year==1759 | year==1760 | year==1761 | year==1767 | year==1768 | year==1769 | year==1770 | year==1771 | year==1772 | year==1774 | year==1775 | year==1776 | year==1777 | year==1779 | year==1780 | year==1782 | year==1787 | year==1788 | year==1789


capture drop u_conv
generate  number = max(value, `var_SD')
format number %9.0fc
drop value `var_SD' sourceFRSD


replace source = "SD_Taxes" if source=="taxes"
replace source = "SD_kg" if source=="SD_kg"
replace source = "SD_cargos" if source=="nbr_obs"
replace source = "FR_Values" if source=="FRvalues"


replace sitc_rev2="0"  if sitc_rev2 == "0: Foodstuff, various"
replace sitc_rev2="0a" if sitc_rev2 == "0a: Foodstuff, European"
replace sitc_rev2="0b" if sitc_rev2 == "0b: Foodstuff, Exotic" 
replace sitc_rev2="1"  if sitc_rev2 == "1: Beverages and tobacco"
replace sitc_rev2="2"  if sitc_rev2 == "2: Raw materials"
replace sitc_rev2="3"  if sitc_rev2 == "3: Fuels"
replace sitc_rev2="4"  if sitc_rev2 == "4: Oils" 
replace sitc_rev2="5"  if sitc_rev2 == "5: Chemicals"
replace sitc_rev2="6"  if sitc_rev2 == "6: Manuf. goods, by material"
replace sitc_rev2="6a" if sitc_rev2 == "6a: Manuf. goods, linen"
replace sitc_rev2="6b" if sitc_rev2 == "6b: Manuf. goods, wool" 
replace sitc_rev2="6c" if sitc_rev2 == "6c: Manuf. goods, silk" 
replace sitc_rev2="6d" if sitc_rev2 == "6d: Manuf. goods, coton" 
replace sitc_rev2="7"  if sitc_rev2 == "7: Machinery and transport goods" 
replace sitc_rev2="8"  if sitc_rev2 == "8: Misc. manuf. goods" 
replace sitc_rev2="9"  if sitc_rev2 == "9: Other (incl. weapons)" 
replace sitc_rev2="9a" if sitc_rev2 == "9a: Species"

generate fr=0
replace fr=1 if source=="FR_Values"
bys year : egen pie_chart=max(fr)


preserve
keep if /*pie_chart==1 &*/ exportsimports=="Exports"
collapse (sum) number, by (year fr sitc_rev2)
reshape wide number, i(sitc year) j(fr)
capture corr number0 number1
local corr : display %3.2f r(rho)
clear
set obs 1
generate Geography="`geography'"
generate var_SD="`var_SD'"
generate Correlation = `corr' 
generate ImportExport ="Exports"
append using "$dir/Graphiques transversaux/Correlations.dta"
save "$dir/Graphiques transversaux/Correlations.dta", replace

restore




graph pie number if /*pie_chart==1 &*/ exportsimports=="Exports", over (sitc_rev2) by(source, legend(off) subtitle("Corr : `corr'", position (1))) /*
	*/ plabel(_all percen, format(%2.0f) color(white) gap(8)) plabel(_all name, color(white) gap(-8)) /*
	*/ title("French Exports, `geography'") 


	
graph export "$dir/Graphiques transversaux/`geography'/Graph_Exports_tot_`var_SD'.png", replace 
graph save   "$dir/Graphiques transversaux/`geography'/Graph_Exports_tot_`var_SD'.gph", replace 


preserve
keep if /*pie_chart==1 &*/ exportsimports=="Imports"
collapse (sum) number, by (year fr sitc_rev2)
reshape wide number, i(sitc year) j(fr)
capture corr number0 number1
local corr : display %3.2f r(rho)
clear
set obs 1
generate Geography="`geography'"
generate var_SD="`var_SD'"
generate Correlation = `corr' 
generate ImportExport ="Imports"
append using "$dir/Graphiques transversaux/Correlations.dta"
save "$dir/Graphiques transversaux/Correlations.dta", replace

restore




graph pie number if /*pie_chart==1 &*/ exportsimports=="Imports", over (sitc_rev2) by(source, legend(off) subtitle("Corr : `corr'", position (1))) /*
	*/ plabel(_all percen, format(%2.0f) color(white) gap(8)) plabel(_all name, color(white) gap(-8)) /*
	*/ title("French Imports, `geography'") 
graph export "$dir/Graphiques transversaux/`geography'/Graph_Imports_tot_`var_SD'.png", replace 
graph save   "$dir/Graphiques transversaux/`geography'/Graph_Imports_tot_`var_SD'.gph", replace 


*****Pour les tableaux de sortie

collapse (sum) number, by(exportsimports sitc_rev2 source)

egen total= total(number), by(exportsimports  source)

replace number = number / total
format number %9.2fc
drop total

collapse (sum) number, by(exportsimports sitc_rev2  source)

egen total= total(number), by(exportsimports  source)

replace number = number / total
format number %9.2fc
drop total

*drop u_conv

reshape wide number, i(exportsimports sitc_rev2) j(source) string
rename (_all) `geography'_=
rename `geography'_exportsimports exportsimports
rename `geography'_sitc_rev2 sitc_rev2

merge 1:1 exportsimports sitc_rev2 using "$dir/Graphiques transversaux/Composition.dta"
drop _merge
save "$dir/Graphiques transversaux/Composition.dta", replace


end

*************************
*Lancer les programmes
************************************************************************************


clear
set
generate Geography 		=""
generate ImportExport =""
generate var_SD		=""
generate Correlation	= . 
save "$dir/Graphiques transversaux/Correlations.dta", replace
generate sitc_rev2 =""
generate adj=.
save "$dir/Graphiques longitudinaux/Correlations.dta", replace

clear
generate exportsimports=""
generate sitc_rev2 =""
save "$dir/Graphiques transversaux/Composition.dta", replace

clear 
generate Geography=""
generate var=""
generate Timetrend =.
generate sd=.
generate ImportExport =""
generate sitc_rev2 =""
generate adj=.
save "$dir/Graphiques longitudinaux/Timetrend.dta", replace



foreach g in Sweden Denmark Russia /*Sound SouthBaltic */{
	Sound_prepare_BDD `g'
	Sound_absolute `g'
	
	foreach v in nbr_obs SD_kg taxes  {
		Sound_prepare_BDD_unit `g' `v'
	}

	Fr_longi `g'

	foreach v in nbr_obs SD_kg taxes  {
		Sound_longi `g' `v'
		Sound_trans `g' `v'
	}
}
		

use "$dir/Graphiques transversaux/Correlations.dta", clear
format Correlation %9.2fc
reshape wide Correlation, i(var_SD ImportExport) j(Geography) string
order ImportExport var_SD
sort ImportExport var_SD
save "$dir/Graphiques transversaux/Correlations.dta", replace
export excel using "$dir/Graphiques transversaux/Correlations.xls", firstrow(variables) replace




use "$dir/Graphiques transversaux/Composition.dta", clear
sort exportsimports sitc_rev2
export excel using "$dir/Graphiques transversaux/Composition.xls", firstrow(variables) replace

use "$dir/Graphiques longitudinaux/Correlations.dta", clear
format Correlation %9.2fc

generate id = Geography+"_"+var_SD+"_"+string(adj)
drop Geography var_SD adj
reshape wide Correlation, i(sitc_rev2 ImportExport) j(id) string
sort ImportExport sitc_rev2
replace sitc_rev2="0"  if sitc_rev2 == "0: Foodstuff, various"
replace sitc_rev2="0a" if sitc_rev2 == "0a: Foodstuff, European"
replace sitc_rev2="0b" if sitc_rev2 == "0b: Foodstuff, Exotic" 
replace sitc_rev2="1"  if sitc_rev2 == "1: Beverages and tobacco"
replace sitc_rev2="2"  if sitc_rev2 == "2: Raw materials"
replace sitc_rev2="3"  if sitc_rev2 == "3: Fuels"
replace sitc_rev2="4"  if sitc_rev2 == "4: Oils" 
replace sitc_rev2="5"  if sitc_rev2 == "5: Chemicals"
replace sitc_rev2="6"  if sitc_rev2 == "6: Manuf. goods, by material"
replace sitc_rev2="6a" if sitc_rev2 == "6a: Manuf. goods, linen"
replace sitc_rev2="6b" if sitc_rev2 == "6b: Manuf. goods, wool" 
replace sitc_rev2="6c" if sitc_rev2 == "6c: Manuf. goods, silk" 
replace sitc_rev2="6d" if sitc_rev2 == "6d: Manuf. goods, coton" 
replace sitc_rev2="7"  if sitc_rev2 == "7: Machinery and transport goods" 
replace sitc_rev2="8"  if sitc_rev2 == "8: Misc. manuf. goods" 
replace sitc_rev2="9"  if sitc_rev2 == "9: Other (incl. weapons)" 
replace sitc_rev2="9a" if sitc_rev2 == "9a: Species"
save "$dir/Graphiques longitudinaux/Correlations.dta", replace
export excel using "$dir/Graphiques longitudinaux/Correlations.xls", firstrow(variables) replace


****Utilisation des timetrend pour mesurer la proximité statistique des trends
use "$dir/Graphiques longitudinaux/Timetrend", clear
format Timetrend %9.2fc

generate id = Geography+"_"+string(adj)
drop Geography adj

preserve
keep if var=="France"
rename (Timetrend sd) Fr_=
save "$dir/Graphiques longitudinaux/Blouk.dta", replace
restore

drop if var=="France"
merge m:1 sitc_rev2 ImportExport id using "$dir/Graphiques longitudinaux/Blouk.dta"

erase "$dir/Graphiques longitudinaux/Blouk.dta"

drop _merge
drop if var=="France"

generate proxi = abs(normal((Fr_Timetrend-Timetrend)/(sd^2+ Fr_sd^2)^0.5)-0.5)*2
*Si je ne me trompe pas, cela devrait l'amplitude en % de l'intervale de confiance qui comprend à la fois 0 et la différence
*Plus c'est proche de 0, plus les trends sont proches
format proxi %9.2fc

drop Timetrend sd Fr_Timetrend Fr_sd


replace id = id+"_"+var
drop var


reshape wide proxi, i(sitc_rev2 ImportExport) j(id) string
sort ImportExport sitc_rev2


save "$dir/Graphiques longitudinaux/Timetrend--proxi.dta", replace
export excel "$dir/Graphiques longitudinaux/Timetrend--proxi.xls", replace firstrow(variable)




****Utilisation des timetrend pour mesurer les ratios
use "$dir/Graphiques longitudinaux/Timetrend", clear
format Timetrend %9.2fc

generate id = Geography+"_"+string(adj)
drop Geography adj

preserve
keep if var=="France"
rename (Timetrend sd) Fr_=
save "$dir/Graphiques longitudinaux/Blouk.dta", replace
restore

drop if var=="France"
merge m:1 sitc_rev2 ImportExport id using "$dir/Graphiques longitudinaux/Blouk.dta"

erase "$dir/Graphiques longitudinaux/Blouk.dta"

drop _merge
drop if var=="France"

generate ratio = (Fr_Timetrend-Timetrend)/Timetrend
format ratio %9.2fc

drop Timetrend sd Fr_Timetrend Fr_sd


replace id = id+"_"+var
drop var


reshape wide ratio, i(sitc_rev2 ImportExport) j(id) string
sort ImportExport sitc_rev2


save "$dir/Graphiques longitudinaux/Timetrend--ratio.dta", replace
export excel "$dir/Graphiques longitudinaux/Timetrend--ratio.xls", replace firstrow(variable)





*erase "$dir/blouk.dta" 





