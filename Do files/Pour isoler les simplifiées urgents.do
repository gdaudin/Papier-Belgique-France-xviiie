

version 14

**pour mettre les bases dans stata + mettre à jour les .csv
** version 2 : pour travailler avec la nouvelle organisation

global dir "/Users/guillaumedaudin/Documents/Recherche/Commerce International Français XVIIIe.xls/Balance du commerce/Retranscriptions_Commerce_France"
cd "$dir"
capture log using "`c(current_time)' `c(current_date)'"

import delimited "toflit18_data_GIT/traitements_marchandises/SITC/travail_sitcrev3.csv",  encoding(UTF-8) clear varname(1) stringcols(_all)  

	foreach variable of var * {
		capture	replace `variable'  =usubinstr(`variable',"  "," ",.)
		capture	replace `variable'  =usubinstr(`variable',"  "," ",.)
		capture	replace `variable'  =usubinstr(`variable',"  "," ",.)
		capture	replace `variable'  =usubinstr(`variable',"…","...",.)
		capture replace `variable'  =usubinstr(`variable'," "," ",.)/*Pour espace insécable*/
		replace `variable' =usubinstr(`variable',"’","'",.)
		capture	replace `variable'  =ustrtrim(`variable')
	}




bys marchandises_simplification : drop if _n!=1
capture drop urgent
generate urgent=.


foreach file in /*
		*/ "~/Documents/Recherche/Commerce XVIIIe-XIXe Europe/Belgique/Papier Ann - Loïc/Statistiques/Stata/RG_base courante.dta"/*
		*/ "~/Documents/Recherche/Commerce XVIIIe-XIXe Europe/Belgique/Papier Ann - Loïc/Statistiques/Stata/RG_1774 courante.dta" /*
		*/ {

	merge 1:m marchandises_simplification using  "`file'"
	capture drop blouk
	capture drop urgent
	generate blouk = 1 if _merge !=1
	bys marchandises_simplification : egen urgent = max(blouk)
	drop blouk
	bys marchandises_simplification : drop if _n!=1
	replace obsolete="no" if _merge==2 
	bys marchandises_simplification : drop if _n!=1

	drop _merge

}
drop  unit-product




	merge 1:m marchandises_simplification using "Données Stata/bdd courante.dta"
	drop numrodeligne-pays_simplification marchandises_norm_ortho-prix_calcul
	capture drop blouk
	capture drop blink
	generate blouk = 1 if strmatch(pays_grouping,"Flandre*")==1
	bys marchandises_simplification : egen blink = max(blouk)
	replace urgent=blink
	drop blouk blink
	bys marchandises_simplification : drop if _n!=1
	replace obsolete="no" if _merge==2 
	drop _merge

drop pays_grouping

replace urgent=. if (sitc18_rev3 != "0k" & sitc18_rev3 != "6" & sitc18_rev3 != "???" & sitc18_rev3 != "????")

drop marchandises

save "Données Stata/travail_sitcrev3.dta", replace
generate sortkey = ustrsortkey(marchandises_simplification, "fr")
sort sortkey
drop sortkey
export delimited "Données Stata/travail_sitcrev3.csv", replace
