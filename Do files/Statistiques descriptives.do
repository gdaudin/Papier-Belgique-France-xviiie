version 14

global dir "~/Documents/Recherche/Commerce XVIIIe-XIXe Europe/Belgique/Papier Ann - Loïc/Statistiques"
cd "$dir"



use "Stata/RG_base courante.dta", clear

codebook marchandises marchandises_norm_ortho marchandises_simplification
bys marchandises : drop if _n!=1
codebook marchandises marchandises_norm_ortho marchandises_simplification

bys marchandises_norm_ortho : drop if _n!=1
bys marchandises_simplification : gen blouk=1 if _N!=1

list marchandises_norm_ortho marchandises_simplification if blouk==1


use "~/Documents/Recherche/Commerce International Français XVIIIe.xls/Balance du commerce/Retranscriptions_Commerce_France/Données Stata/bdd courante.dta", clear



keep if strmatch(pays_grouping,"*Flandre*")==1
keep if sourcetype == "Objet Général" | sourcetype == "National par direction"
destring year, replace
replace exportsimports = "Imports" if exportsimports == "Importations"
replace exportsimports = "Exports" if exportsimports == "Exportations"

codebook marchandises marchandises_norm_ortho marchandises_simplification

codebook marchandises marchandises_norm_ortho marchandises_simplification
bys marchandises : drop if _n!=1
bys marchandises_simplification : gen blouk = _N
summarize blouk


sort marchandises marchandises_norm_ortho marchandises_simplification

list marchandises marchandises_norm_ortho marchandises_simplification if blouk==r(max)
list marchandises marchandises_norm_ortho marchandises_simplification if blouk==19
