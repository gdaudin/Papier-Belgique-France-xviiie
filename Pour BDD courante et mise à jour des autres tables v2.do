

version 14

**pour mettre les bases dans stata + mettre à jour les .csv
** version 2 : pour travailler avec la nouvelle organisation

cd "/Users/guillaumedaudin/Documents/Recherche/Commerce International Français XVIIIe.xls/Balance du commerce/Retranscriptions_Commerce_France"
global dir "/Users/guillaumedaudin/Documents/Recherche/Commerce International Français XVIIIe.xls/Balance du commerce/Retranscriptions_Commerce_France"
capture log using "`c(current_time)' `c(current_date)'"

import delimited "bdd_pays_4 juin 2015.csv",  encoding(UTF-8) clear varname(1) stringcols(_all)   

foreach variable of var pays pays_corriges pays_regroupes {
	replace `variable'  =usubinstr(`variable',char(201),"...",.)
	replace `variable'  =usubinstr(`variable',char(202)," ",.)
	replace `variable'  =ustrtrim(`variable')
}

capture destring nbr*, replace float
capture drop nbr_bdc* source_bdc
save "bdd_pays_old.dta", replace

**J'utilise stringcols(_all) parce que lorsqu'il rencontre les caractères non-numériques dans une variable qu'il a décidé d'être 
*** il met des cellules blanches à la place.

import delimited "bdd_marchandises_classifiees_24 juin 2015.csv",  encoding(UTF-8) clear varname(1) stringcols(_all)   
foreach variable of var  marchandises_simplifiees marchandises_tres_simplifiees {
	replace `variable'  =usubinstr(`variable',char(201),"...",.)
	replace `variable'  =usubinstr(`variable',char(202)," ",.)
	replace `variable'  =ustrtrim(`variable')
}
capture destring nbr*, replace float
capture drop nbr_bdc* source_bdc
save "bdd_marchandises_classifiees_old.dta", replace

import delimited "bdd_marchandises_simplifiees_15 juin 2015.csv",  encoding(UTF-8) clear varname(1) stringcols(_all)   
foreach variable of var  marchandises_norm_ortho marchandises_simplifiees {
	replace `variable'  =usubinstr(`variable',char(201),"...",.)
	replace `variable'  =usubinstr(`variable',char(202)," ",.)
	replace `variable'  =ustrtrim(`variable')
}
capture destring nbr*, replace float
capture drop nbr_bdc* source_bdc
save "bdd_marchandises_simplifiees_old.dta", replace





import delimited "bdd_marchandises_normalisation_orthographique_23 juin 2015.csv",  encoding(UTF-8) clear varname(1) stringcols(_all)  
foreach variable of var marchandises  marchandises_norm_ortho {
	replace `variable'  =usubinstr(`variable',char(201),"...",.)
	replace `variable'  =usubinstr(`variable',char(202)," ",.)
	replace `variable'  =ustrtrim(`variable')
}

capture destring nbr*, replace float
capture drop nbr_bdc* source_bdc
save "bdd_marchandises_normalisees_old.dta", replace


import delimited "bdd_centrale_3 juin 2015",  encoding(UTF-8) clear varname(1) stringcols(_all)  
foreach variable of var marchandises pays quantity_unit {
	replace `variable'  =usubinstr(`variable',char(201),"...",.)
	replace `variable'  =usubinstr(`variable',char(202)," ",.)
	replace `variable'  =ustrtrim(`variable')
}

foreach variable of var quantit value prix_unitaire { 
	replace `variable'  =usubinstr(`variable',",",".",.)
	replace `variable'  =usubinstr(`variable'," ","",.)
	replace `variable'  =usubinstr(`variable'," ","",.)
	replace `variable'  =usubinstr(`variable',char(202),"",.)
	edit  if missing(real(`variable')) & `variable' != ""
	display "---------Pas trop !-----------------"
	replace `variable' ="" if missing(real(`variable')) & `variable' != ""
}


destring numrodeligne  total leurvaleursubtotal_1 leurvaleursubtotal_2 leurvaleursubtotal_3  doubleaccounts, replace
destring quantit prix_unitaire value, replace


save "bdd_centrale.dta", replace
export delimited bdd_centrale.csv, replace


import delimited "Units N1_1er juin 2015.csv",  encoding(UTF-8) clear varname(1) stringcols(_all)  
foreach variable of var quantity_unit quantity_unit_ajustees {
	replace `variable'  =usubinstr(`variable',char(201),"...",.)
	replace `variable'  =usubinstr(`variable',char(202)," ",.)
	replace `variable'  =ustrtrim(`variable')
}

capture destring nbr*, replace float
capture drop nbr_bdc* source_bdc
save "Units N1_old.dta", replace


import delimited "Units N2_1er juin 2015.csv",  encoding(UTF-8) clear varname(1) stringcols(_all)  
foreach variable of var quantity_unit marchandises_normalisees n2_quantity_unit_ajustees {
	replace `variable'  =usubinstr(`variable',char(201),"...",.)
	replace `variable'  =usubinstr(`variable',char(202)," ",.)
	replace `variable'  =ustrtrim(`variable')
}
capture drop nbr_bdc* source_bdc
capture destring nbr*, replace float
save "Units N2_old.dta", replace

import delimited "Units N3_1er juin 2015.csv",  encoding(UTF-8) clear varname(1) stringcols(_all)  
foreach variable of var exportsimports quantity_unit marchandises_normalisees pays_corriges pays_regroupes n3_quantity_unit_ajustees {
	replace `variable'  =usubinstr(`variable',char(201),"...",.)
	replace `variable'  =usubinstr(`variable',char(202)," ",.)
	replace `variable'  =ustrtrim(`variable')
}

capture drop nbr_bdc* source_bdc
capture destring nbr*, replace float
save "Units N3_old.dta", replace













********* Procédure pour les nouveaux fichiers ************

***********Unit values
use "$dir/bdd_centrale.dta", clear
merge m:1 quantity_unit using "$dir/Units N1_old.dta"
drop numrodeligne-total leurvaleursubtotal_1-doubleaccounts

capture drop source_bdc
generate source_bdc=0
label variable source_bdc "1 si présent dans la source française, 0 sinon"
replace source_bdc=1 if _merge==3 | _merge==1
replace source_bdc=0 if _merge==2


foreach variable of var quantity_unit quantity_unit_ajustees  {
	capture drop nbr_bdc_`variable'
	generate nbr_bdc_`variable'=0
	label variable nbr_bdc_`variable' "Nbr de flux avec ce `variable' dans la source française"
	bys `variable' : replace nbr_bdc_`variable'=_N if (_merge==3 | _merge==1)
}

drop _merge
bys quantity_unit : keep if _n==1
save "Units N1.dta", replace
export delimited "Units N1.csv", replace


****Pays*************
use "$dir/bdd_centrale.dta", clear
merge m:1 pays using "$dir/bdd_pays_old.dta"
drop numrodeligne-marchandises value-doubleaccounts


capture drop source_bdc
generate source_bdc=0
label variable source_bdc "1 si présent dans la source française, 0 sinon"
replace source_bdc=1 if _merge==3 | _merge==1
replace source_bdc=0 if _merge==2


foreach variable of var pays pays_corriges pays_regroupes  {
	capture drop nbr_bdc_`variable'
	generate nbr_bdc_`variable'=0
	label variable nbr_bdc_`variable' "Nbr de flux avec ce `variable' dans la source française"
	bys `variable' : replace nbr_bdc_`variable'=_N if (_merge==3 | _merge==1)
}





drop _merge
bys pays : keep if _n==1
save "bdd_pays.dta", replace
export delimited bdd_pays.csv, replace




*************Marchandises normalisées

use "$dir/bdd_centrale.dta", clear

merge m:1 marchandises using "bdd_marchandises_normalisees_old.dta"

drop numrodeligne-sheet pays-doubleaccounts


capture drop source_bdc
generate source_bdc=0
label variable source_bdc "1 si présent dans la source française, 0 sinon"
replace source_bdc=1 if _merge==3 | _merge==1
replace source_bdc=0 if _merge==2


foreach variable of var marchandises marchandises_norm_ortho  {
	capture drop nbr_bdc_`variable'
	generate nbr_bdc_`variable'=0
	label variable nbr_bdc_`variable' "Nbr de flux avec ce `variable' dans la source française"
	bys `variable' : replace nbr_bdc_`variable'=_N if (_merge==3 | _merge==1)
}


drop _merge
bys marchandises : keep if _n==1

save "bdd_marchandises_normalisees.dta", replace
export delimited bdd_marchandises_normalisees_orthographique.csv, replace


******Marchandises simplifiées

use "$dir/bdd_centrale.dta", clear

merge m:1 marchandises using "bdd_marchandises_normalisees.dta"

drop numrodeligne-sheet pays-doubleaccounts _merge

merge m:1 marchandises_norm_ortho using "bdd_marchandises_simplifiees_old.dta"

keep marchandises_norm_ortho marchandises_simplifiees _merge

capture drop source_bdc=0
generate source_bdc=0
label variable source_bdc "1 si présent dans la source française, 0 sinon"
replace source_bdc=1 if _merge==3 | _merge==1
replace source_bdc=0 if _merge==2


foreach variable of var marchandises_norm_ortho marchandises_simplifiees {
	capture drop nbr_bdc_`variable'
	generate nbr_bdc_`variable'=0
	label variable nbr_bdc_`variable' "Nbr de flux avec ce `variable' dans la source française"
	bys `variable' : replace nbr_bdc_`variable'=_N if (_merge==3 | _merge==1)
}


drop _merge
bys marchandises_norm_ortho : keep if _n==1


save "bdd_marchandises_simplifiees.dta", replace
export delimited bdd_marchandises_simplifiees.csv, replace




******Marchandises classifiées

use "$dir/bdd_centrale.dta", clear

merge m:1 marchandises using "bdd_marchandises_normalisees.dta"

drop numrodeligne-sheet pays-doubleaccounts _merge

merge m:1 marchandises_norm_ortho using "bdd_marchandises_simplifiees.dta"

keep marchandises_norm_ortho marchandises_simplifiees

merge m:1 marchandises_simplifiees using "bdd_marchandises_classifiees_old.dta"


capture drop source_bdc=0
generate source_bdc=0
label variable source_bdc "1 si présent dans la source française, 0 sinon"
replace source_bdc=1 if _merge==3 | _merge==1
replace source_bdc=0 if _merge==2




foreach variable of var marchandises_simplifiees {
	capture drop nbr_bdc_`variable'
	generate nbr_bdc_`variable'=0
	label variable nbr_bdc_`variable' "Nbr de flux avec ce `variable' dans la source française"
	bys `variable' : replace nbr_bdc_`variable'=_N if (_merge==3 | _merge==1)
}


drop marchandises_norm_ortho

drop _merge
bys marchandises_simplifiees : keep if _n==1


save "bdd_marchandises_classifiees.dta", replace
export delimited bdd_marchandises_classifiees.csv, replace




****************************BDD courante

use "$dir/bdd_centrale.dta", clear

merge m:1 pays using "$dir/bdd_pays.dta"
drop if _merge==2
drop source_bdc-_merge

merge m:1 marchandises using "bdd_marchandises_normalisees.dta"
drop if _merge==2
drop source_bdc-_merge


merge m:1 marchandises_norm_ortho using "bdd_marchandises_simplifiees.dta"
drop if _merge==2
drop source_bdc-_merge




merge m:1 marchandises_simplifiees using "bdd_marchandises_classifiees.dta"
drop if _merge==2
drop classificationproduitsmdicinaux-_merge

generate value_calcul = quantit*prix_unitaire
generate prix_calcul = value/quantit


save "$dir/bdd courante", replace


***********************************************************************************************************************************
*keep if quantity_unit!=""
merge m:1 quantity_unit using "$dir/Units N1_v1.dta"
* 5 _merge==2 -> viennent de Hambourg
drop if _merge==2
drop _merge 
merge m:1 quantity_unit marchandises_normalisees using "$dir/Units N2_v1.dta"
drop if _merge==2
drop _merge
* 3 _merge==2 -> combinaisons nouvelles marchandises_normalisees-quantity_unit viennent de Hambourg (tonneaux de beurre et d'huile de baleine, quartiers d'eau de vie)
merge m:1 quantity_unit marchandises_normalisees exportsimports pays_corriges using "$dir/Units N3_v1.dta"
drop _merge
replace quantity_unit_ajustees = N2_quantity_unit_ajustees  if N2_quantity_unit_ajustees!=""
replace quantity_unit_ajustees = N3_quantity_unit_ajustees if N3_quantity_unit_ajustees!=""
replace u_conv=N2_u_conv if N2_u_conv!=""
replace u_conv=N3_u_conv if N3_u_conv!=""
replace q_conv=N2_q_conv if N2_q_conv!=.
replace q_conv=N3_q_conv if N3_q_conv!=.
replace Remarque_unit=N2_Remarque_unit if N2_Remarque_unit!=""
replace Remarque_unit =N3_Remarque_unit if N3_Remarque_unit!=""
drop N2_u_conv N3_u_conv N2_q_conv N3_q_conv N2_Remarque_unit N3_Remarque_unit
*** à la fin il y a 64 635 observations -> les 64 633 de départ + les 3 issues des combinaisons nouvelles marchandises_normalisees-quantity_unit venant de Hambourg
*********************************


save "$dir/bdd courante", replace


end
********
use "$dir/bdd courante", replace 

keep if year=="1750"
keep if direction=="Bordeaux"
keep if exportsimports=="Imports"
keep source sourcetype year exportsimports direction marchandises pays value quantit quantity_unit prix_unitaire probleme remarks quantit_unit pays_corriges marchandises_normalisees value_calcul prix_calcul
sort marchandises pays


export delimited using "/Users/guillaumedaudin/Documents/Recherche/Commerce International Français XVIIIe.xls/Balance du commerce/Retranscriptions_Commerce_France/Pour comparaison Bordeaux 1750.csv", replace



