**Travail 26/03/2013
**Pour intégration de la BDD d'Ann
**Version 2 : Puis 17/04/2013 : intégrer la nouvelle version d'Ann
**Version 3 : 28/6/2013 : correction erreur dans RG_base + intégration changements dans les prix

version 14
 
insheet using "/Users/guillaumedaudin/Documents/Recherche/Commerce XVIIIe-XIXe Europe/Belgique/Papier Ann - Loïc/Statistiques/Nouvelle_version_Kopie van RG overzicht met vertalingv3-utf8.csv", clear name

replace unit=subinstr(unit,"'","",.)

cd "/Users/guillaumedaudin/Documents/Recherche/Commerce XVIIIe-XIXe Europe/Belgique/Papier Ann - Loïc/Statistiques/Stata"

destring import1759-transit1791, replace force

collapse (sum) import1759-transit1791, by(product originalfrenchname dutchtranslation unitofmeasure)

save blouk, replace

reshape long export, i(product originalfrenchname dutchtranslation unitofmeasure) j(year)

drop transit* import*

drop if export==0

save export.dta, replace

use blouk, clear

reshape long import, i(product originalfrenchname dutchtranslation unitofmeasure) j(year2)

drop transit* export*

drop if import==0
save import.dta, replace

use blouk, clear


reshape long transit, i(product originalfrenchname dutchtranslation unitofmeasure) j(year3)

drop import* export*

drop if transit==0

append using import.dta
append using export.dta

erase import.dta
erase export.dta 


replace year=year2 if year==.
replace year=year3 if year==.

drop year2 year3

generate exportimport=""
replace exportimport="export"  if export!=.
replace exportimport="import"  if import!=.
replace exportimport="transit" if transit!=.


rename transit quantity
replace quantity=import if quantity==.
replace quantity=export if quantity==.

drop import
drop export




rename unitofmeasure unit

replace  originalfrenchname= "moulons à faire des bâtiments" if dutchtranslation=="kalksteen voor de bouw"
replace  originalfrenchname= "tapisseries / pièce" if dutchtranslation=="tapijtwerk / stuk"

duplicates report originalfrenchname unit exportimport year unit


collapse (sum) quantity, by(product originalfrenchname dutchtranslation unit exportimport year)



save RG_base, replace




**********FIN IMPORTATION


/*

***********************
**Liste des biens
*************************

use RG_base, clear

keep originalfrenchname product dutchtranslation unit

bys originalfrenchname product dutchtranslation unit : keep if _n==1


save RG_produits_etape1.dta

**************************************************Utiliser la liste des biens classés par Ann ?

insheet using "/Users/guillaumedaudin/Documents/Recherche/Commerce XVIIIe-XIXe Europe/Belgique/Papier Ann - LoiÃàc/Statistiques/Envoi Ann Avril 2013/Translations and classification RG.csv", tab clear

replace alternativenames = alternativenames + "/" + v8 if alternativenames !="" & v8 !=""
replace alternativenames = v8 if alternativenames =="" & v8 !=""
drop v8

replace sitc18thc = string(sitc1digit) if sitc18thc==""

rename englishtranslation product
rename unitofmeasure unit

bys originalfrenchname unit : generate blouk = _N
list if blouk !=1



bys originalfrenchname dutchtranslation product unit : generate blink = _N
list if blink !=1

bys originalfrenchname dutchtranslation product unit : drop if _n!=1
drop blouk blink

merge m:m originalfrenchname dutchtranslation product unit using RG_produits_etape1.dta
drop _merge

save RG_produits_etape2.dta, replace




outsheet using RG_produits.csv, replace

***Je modifie dans LibreOffice pour faire correspondance avec les prix
*/

insheet using "/Users/guillaumedaudin/Documents/Recherche/Commerce XVIIIe-XIXe Europe/Belgique/Papier Ann - Loïc/Statistiques/RG_produits_modif-utf8.csv", clear name

replace unit=subinstr(unit,"'","",.)

replace alternativenames = alternativenames + "/" + v9 if alternativenames !="" & v9 !=""
replace alternativenames = v9 if alternativenames =="" & v9 !=""
drop v9

replace alternativenames = alternativenames + "/" + v10 if alternativenames !="" & v10 !=""
replace alternativenames = v10 if alternativenames =="" & v10 !=""
drop v10

bys originalfrenchname dutchtranslation product: drop if _n!=1




save RG_produits_modif.dta, replace



**Et maintenant pour les prix

***********************
insheet using "/Users/guillaumedaudin/Documents/Recherche/Commerce XVIIIe-XIXe Europe/Belgique/Papier Ann - Loïc/Statistiques/Prices_v4-utf8.csv", clear 

reshape long prix, i(product_prix unit) j(year)
replace product_prix= subinstr(product_prix,char(45),";",1)
replace unit=subinstr(unit,char(127)," ",.)
replace unit=subinstr(unit,char(202)," ",.)
replace unit=subinstr(unit," "," ",.)

replace unit=subinstr(unit,"'","",.)

save RG_prix.dta, replace

***On met les product_prix dans la base
use RG_base, clear

replace originalfrenchname = trim(originalfrenchname)
replace dutchtranslation = trim(dutchtranslation)
replace product = trim(product)
replace unit=trim(unit)

merge m:1 originalfrenchname dutchtranslation product using  RG_produits_modif.dta

drop _merge

save RG_base.dta, replace


************************************
/*
**On met les prix dans la base initiale 

use RG_base, clear

replace originalfrenchname = trim(originalfrenchname)
replace dutchtranslation = trim(dutchtranslation)
replace product = trim(product)
replace unit=trim(unit)

merge m:1 originalfrenchname  dutchtranslation unit product using  RG_produits_modif.dta

drop _merge

merge m:1 product_prix unit year using  RG_prix.dta

drop if _merge==2

drop _merge
replace prix = 1 if unit=="guilders"

generate value = quantity*prix

save RG_base.dta, replace

*Voilà. La base initiale comprend les prix.

*/


***********************************************************************************
****POUR 1774
***********************************************************


insheet using "/Users/guillaumedaudin/Documents/Recherche/Commerce XVIIIe-XIXe Europe/Belgique/Papier Ann - Loïc/Statistiques/Belgian trade by departement/RG_1774_pourStata-utf8.csv", clear name

destring invoerbrussel-transitherve, replace force

preserve

reshape long invoer, i(dutchtranslation unit) j(bureau, string)

drop uitvoer* transit*

save import.dta, replace

restore
preserve

reshape long uitvoer, i(dutchtranslation unit) j(bureau2, string)

drop transit* invoer*
save export.dta, replace

restore

reshape long transit, i(dutchtranslation unit) j(bureau3, string)

drop invoer* uitvoer*


append using import.dta
append using export.dta

erase import.dta
erase export.dta


replace bureau=bureau2 if bureau==""
replace bureau=bureau3 if bureau==""

drop bureau2 bureau3

drop if invoer==. & uitvoer==. & transit ==.


generate quantity = invoer if invoer  !=.
replace quantity = uitvoer if uitvoer !=.
replace quantity = transit if transit !=.



generate exportimport=""
replace exportimport="export"  if uitvoer!=.
replace exportimport="import"  if invoer!=.
replace exportimport="transit" if transit!=.

drop invoer uitvoer transit

save RG_1774.dta, replace





**************************************************Noms en Français dans RG_1774


***J'ai intégré deux lignes dans RG_produits_modif : dutchtranslation
*molenstenen van 2 tot 3.000 pond
*molenstenen van 3 tot 4.000 pond
*Et pour les molenstenen, j'ai remplacé des "pounds" par des "ponds"
*J'ai rajouté charbon d



insheet using "/Users/guillaumedaudin/Documents/Recherche/Commerce XVIIIe-XIXe Europe/Belgique/Papier Ann - Loïc/Statistiques/Envoi Ann Avril 2013/prbl_with_RG_1774 (corrected)-utf8.csv", clear name

replace dutchtranslation=trim(dutchtranslation)

merge 1:m dutchtranslation using RG_1774.dta
replace dutchtranslation = corrected if corrected!=""
drop corrected
drop _merge



merge m:m dutchtranslation using RG_produits_modif.dta

replace originalfrenchname ="charbons de terre ou de pierre dits houille" if alternativenames=="charbons de terre dit houille/gros charbons de houilles"
drop _merge


save RG_1774.dta, replace

















