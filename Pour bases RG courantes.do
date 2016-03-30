version 14

**pour utiliser les agrégation sur les données Belges

global dir "~/Documents/Recherche/Commerce XVIIIe-XIXe Europe/Belgique/Papier Ann - Loïc/Statistiques/Stata"
cd "$dir"

use RG_base.dta, clear

drop dutchtranslation product
rename originalfrenchname marchandises

merge m:1 marchandises using "~/Documents/Recherche/Commerce International Français XVIIIe.xls/Balance du commerce/Retranscriptions_Commerce_France/Données Stata/bdd_revised_marchandises_normalisees_orthographique.dta", keep(3) nogenerate
merge m:1 marchandises_norm_ortho using "~/Documents/Recherche/Commerce International Français XVIIIe.xls/Balance du commerce/Retranscriptions_Commerce_France/Données Stata/bdd_revised_marchandises_simplifiees.dta",keep(3) nogenerate
merge m:1 marchandises_simplification using "~/Documents/Recherche/Commerce International Français XVIIIe.xls/Balance du commerce/Retranscriptions_Commerce_France/Données Stata/travail_sitcrev3.dta",keep(3) nogenerate


save "RG_base courante.dta", replace


use RG_base.dta, clear


use RG_1774.dta, clear
drop dutchtranslation
rename originalfrenchname marchandises

merge m:1 marchandises using "~/Documents/Recherche/Commerce International Français XVIIIe.xls/Balance du commerce/Retranscriptions_Commerce_France/Données Stata/bdd_revised_marchandises_normalisees_orthographique.dta", keep(3) nogenerate
merge m:1 marchandises_norm_ortho using "~/Documents/Recherche/Commerce International Français XVIIIe.xls/Balance du commerce/Retranscriptions_Commerce_France/Données Stata/bdd_revised_marchandises_simplifiees.dta",keep(3) nogenerate
merge m:1 marchandises_simplification using "~/Documents/Recherche/Commerce International Français XVIIIe.xls/Balance du commerce/Retranscriptions_Commerce_France/Données Stata/travail_sitcrev3.dta",keep(3) nogenerate

save "RG_1774 courante.dta", replace


