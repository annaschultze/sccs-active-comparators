/*==============================================================================
DO FILE NAME: 		 00_data_exploration.do		
PROJECT: 			 SCCS Active Comparators Working Group
DATE: 				 28/10/2020
AUTHOR:				 Anna Schultze				
VERSION:			 Stata 16.1

DESCRIPTION OF FILE: This code reads in files provided by ID to reproduce  
					 the glitazone/sulphonylureas findings. 
					 There is investigative datamanagement undertaken to see
					 whether provided analytical files or do files can reproduce 
					 the published results. 
					 Finally, it outputs datasets required to reproduce results
					 
DEPENDENCIES: 		 None. This is the first do-file in a series intended to run 
					 in numerical order. 					 
DATASETS USED:		 All in $Datadir; additional ones read from $Rawdir based 
					 on old code are: 
						- patients details.dta 
						- exposure periods - multiple fracture case series - censor last presc.dta
						
DATASETS CREATED:	 Glitazones_analysis_file.dta
OTHER OUTPUT: 		 log file (directed to log folder)		
==============================================================================*/

/* Housekeeping===============================================================*/ 
clear 

* Create globals for directories 

global Projectdir "J:\EHR-Working\AnnaS\Projects\02_SCCS_Active_Comparator\sccs-active-comparators\Stata"
global Datadir "Z:\GPRD_GOLD\Ian\Studies\Glitazones\Files for Anna"
global Rawdir "Z:\GPRD_GOLD\Ian\Studies\Glitazones\Stata Files"

cd $Projectdir 
pwd

* Open a log file

cap log close
log using $Projectdir\log\00_data_exploration, replace t

/* Read in Data===============================================================*/ 
*  read in and explore data provided 

use "$Datadir\all_fractures_first"
describe  

use "$Datadir\exposure periods - sulphonylureas - multiple fracture case series - censor last presc"
describe  

use "$Datadir\glitazone type"
describe

use "$Datadir\multiple_fractures_all"
describe 

use "$Datadir\SU_analysis_file"
describe 

bysort indiv: gen nval = _n == 1 
count if nval

* patient count N + 1 that in published SU analysis (695) 

xi: xtpoisson nevents i.exgr i.agegr, fe i(indiv) offset(loginterval) irr

* one individual is dropped in the modelling process
* estimated HR matches that in paper. 
* SU analysis file final for SU analyses. 

* Provided datasets do not correspond to the analytical file for Glitazones. 

/* Create Glitazone analytical file============================================= 
  Code below is copied from ID's analytical do file 
  Z:\GPRD_GOLD\Ian\Studies\Glitazones\Files for Anna
  File name: case series analysis - sulphonylureas - multi fractures - any site - 1 year bands - glit users only
  Dataset locations are updated 
  Attempting to see whether running this produces the correct analytical file */ 
  
/*Copied code=================================================================*/

version 9

set more off
use "$Rawdir\patient details", clear
drop if glit_too_late==1
keep pateid birthyear 
*assume all born 1st July
gen birthday=1
gen birthmonth=7
gen dob= mdy(birthmonth, birthday, birthyear)
format dob %d
keep pateid dob 
duplicates drop
sort pateid
merge pateid using "$Rawdir\Fracture case series analysis\exposure periods - multiple fracture case series - censor last presc"
keep if _merge==3
drop _merge

sort pateid
*ADD IN FRACTURE DATES
joinby pateid using "$Rawdir\Medical Data\Fractures\multiple_fractures_all.dta"

*drop patients with unknown date of fracture (equates to 01jan2500)
drop if fracture_date==197232

*drop fracture prior to regstart_12
drop if fracture_date<=regstart_12

*drop fractures post end exposure
sort pateid exposed
by pateid: egen max_end=max(period_end)
drop if fracture_date>max_end

*format dates in terms of age
gen regstart1=regstart_12-dob
gen period_start1=period_start-dob
gen period_end1=period_end-dob
gen fracture_date1=fracture_date-dob
drop regstart_12 period_start period_end fracture_date

gen cutp1=regstart1
sort pateid period_start
by pateid: gen count=_n
by pateid: egen cutp2=max(period_end)

*generate agegroup cutpoints (age 40 to 92 in 1 year bands)
gen  cutp3 = 14610
gen  cutp4 = 14975
gen  cutp5 = 15340
gen  cutp6 = 15705
gen  cutp7 = 16071
gen  cutp8 = 16436
gen  cutp9 = 16801
gen  cutp10 = 17166
gen  cutp11 = 17532
gen  cutp12 = 17897
gen cutp13 = 18262
gen cutp14 = 18627
gen cutp15 = 18993
gen cutp16 = 19358
gen cutp17 = 19723
gen cutp18 = 20088
gen cutp19 = 20454
gen cutp20 = 20819
gen cutp21 = 21184
gen cutp22 = 21549
gen cutp23 = 21915
gen cutp24 = 22280
gen cutp25 = 22645
gen cutp26 = 23010
gen cutp27 = 23376
gen cutp28 = 23741
gen cutp29 = 24106
gen cutp30 = 24471
gen cutp31 = 24837
gen cutp32 = 25202
gen cutp33 = 25567
gen cutp34 = 25932
gen cutp35 = 26298
gen cutp36 = 26663
gen cutp37 = 27028
gen cutp38 = 27393
gen cutp39 = 27759
gen cutp40 = 28124
gen cutp41 = 28489
gen cutp42 = 28854
gen cutp43 = 29220
gen cutp44 = 29585
gen cutp45 = 29950
gen cutp46 = 30315
gen cutp47 = 30681
gen cutp48 = 31046
gen cutp49 = 31411
gen cutp50 = 31776
gen cutp51 = 32142
gen cutp52 = 32507
gen cutp53 = 32872
gen cutp54 = 33237
gen cutp55 = 33603

*generate exposure group cutpoints
gen drugstart=period_start if exposed==1
by pateid: egen drugstart1 = max(drugstart)
gen trash=period_end-period_start if exposed==1
by pateid: egen exlength=max(trash)
drop trash drugstart
rename drugstart1 drugstart

drop  exposed dob site armfoothand regstart1 period_start1 period_end1 count

*number of age group cut points
local nage = 53

*generate the exposure group cut points
generate cutp56 = drugstart - 1
generate cutp57 = drugstart + exlength

drop drugstart

*create a comma separated list of age group cut points
local a=cutp3
local b=`nage'+2
while `b'>3{
local c = cutp`b'
local d = ",`c'`d'"
local b = `b' - 1
}
local a = "`a'`d'"

foreach var of varlist cutp*{
replace `var' = cutp1 if `var' < cutp1
replace `var' = cutp2 if `var' > cutp2
}

compress

rename fracture_date1 eventday
rename pateid indiv

duplicates report
duplicates report indiv eventday
duplicates drop

sort indiv eventday
reshape long cutp, i(indiv eventday) j(type)
sort indiv eventday cutp type

merge indiv using "$Rawdir\glitazone type.dta"
keep if _merge==3
drop _merge
sort indiv eventday cutp type

*number of adverse events within each interval
by indiv: generate int nevents = 1 if eventday > cutp[_n-1]+0.5 & eventday <= cutp[_n]+0.5
collapse (sum) nevents, by(indiv cutp type)

*intervals
by indiv: generate int interval = cutp[_n] - cutp[_n-1]

*age groups
by indiv: gen int agegr =irecode(cutp, `a')
********************COMMAND ABOVE GENERATE ERROR MESSAGE UNLESS WHOLE SECTION RUN AS ONE DO FILE

*exposure groups
generate exgr = type-`nage'-3 if type>`nage'+2
count if exgr>=.
local nmiss = r(N)
local nchange = 1
while `nchange'>0{
by indiv: replace exgr = exgr[_n+1] if exgr>=.
count if exgr>=.
local nchange = `nmiss'-r(N)
local nmiss = r(N)
}
replace exgr = 0 if exgr==.

drop cutp* type
drop if interval ==0 | interval==.

generate loginterval = log(interval)

/*Investigate resulting dataset===============================================*/

bysort indiv: gen nval = _n == 1 
count if nval

tab exgr
tab agegr

* N matches published N 

xi: xtpoisson nevents i.exgr i.agegr, fe i(indiv) offset(loginterval) irr

* HR does not reproduce the HR for glitazones, but it is close. 

xi: xtpoisson nevents i.exgr, fe i(indiv) offset(loginterval) irr

* unadjusted HR is reproduced 

/* Investigation shows discrepancy is caused by pooling of agecategories due to 
a capping of the maximum macro length in Stata IC instead of SE, resulting in 
the pooling of some age categories in the original run. 

if this code is run: 
replace agegr = 50 if agegr >= 41

then the model reproduces the published HR. 

the original pooling caused no error message and cannot be reproduced by 
changing the version history of Stata

*/ 

* check fracture and FU counts 

sort exgr
by exgr: egen days=total(interval)
gen years = days/365.25
by exgr: egen totalevents=total(nevents)
by exgr: tab totalevents years



* the FU time and totalevents matches the published paper. 
* this is the correct dataset

* save dataset as the final analytical dataset for glitazones.  

save "$Datadir\glitazone_analysis_file", replace 

* Close log file 
log close