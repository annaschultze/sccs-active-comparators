/*==============================================================================
DO FILE NAME: 		 00b_create_merged_analysis_file.do		
PROJECT: 			 SCCS Active Comparators Working Group
DATE: 				 10/12/2020
AUTHOR:				 Anna Schultze (Adapted from Ian Douglas)		
VERSION:			 Stata 16.1

DESCRIPTION OF FILE: This modifies code to create two interim datasets for SUL and
					 GLI analyses. 
					 These are then merged, and remaining data management done on this file. 				
					 This - rather than simply appending datasets - is required to avoid duplication 
					 of unexposed rows and due to the age split. Where patients are exposed to say, 6 months 
					 of gli and 1 month of SU during a calendar year appending the datasets s
					 will results in duplication of rows. To ensure these are split appropriately, 
					 the split needs to occur after the exposure periods have been determined, 
					 which necessitates re-shaping the raw files. 
DEPENDENCIES: 		 Do file 00  					 
DATASETS USED:		 All in $Datadir; additional ones read from $Rawdir based 
					 on old code are: 
						- patients details.dta 
						- exposure periods - multiple fracture case series - censor last presc.dta
						
DATASETS CREATED:	 merged_analysis_file.dta
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
log using $Projectdir\log\00b_create_merged_analysis_file, replace t

/* Modify Glitazone analytical file============================================*/

version 9

set more off
use "$Rawdir\patient details", clear
drop if glit_too_late==1
keep pateid birthyear end_uts 
*assume all born 1st July
gen birthday=1
gen birthmonth=7
gen dob= mdy(birthmonth, birthday, birthyear)
format dob %d
keep pateid dob end_uts 
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

*drop fracture prior to regstart_12 - 12 months after UTS and start of follow-up 
drop if fracture_date<=regstart_12

* replace period end w. end of FU (option for FU construction)
* replace period_end = end_uts

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
sort pateid period_start1
by pateid: gen count=_n
by pateid: egen cutp2=max(period_end)

*generate exposure group cutpoints
gen drugstart=period_start if exposed==1
by pateid: egen drugstart1 = max(drugstart)
gen trash=period_end-period_start if exposed==1
by pateid: egen exlength=max(trash)
drop trash drugstart
rename drugstart1 drugstart

drop  exposed dob site armfoothand regstart1 period_start1 period_end1 count

*generate the exposure group cut points
generate cutp56 = drugstart - 1
generate cutp57 = drugstart + exlength

drop drugstart

save "$Datadir\glitazone_analysis_file_interim", replace 

/* Modify SU analytical file===========================================*/
clear
set more off

** Read in raw data and only include those who are glitazone exposed 
use "$Rawdir\patient details", clear
drop if glit_too_late==1
keep if exposed==1
keep pateid birthyear exposed indexdate end_uts

** Create dob to be able to create age 
*assume all born 1st July
gen birthday=1
gen birthmonth=7
gen dob= mdy(birthmonth, birthday, birthyear)
format dob %d
keep pateid dob indexdate exposed end_uts 
sort pateid

** Create two new variables, there is just one row per patient so these are actually
** just copies of the glitazone (all = 1) and index date variables 
by pateid: egen glitazone=max(exposed)
by pateid: egen index=max(indexdate)
format index %d
drop exposed indexdate
** this and code above implies duplicates, but there are none
duplicates drop
sort pateid

merge pateid using "$Rawdir\Fracture case series analysis\exposure periods - sulphonylureas - multiple fracture case series - censor last presc"
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

*generate exposure group cutpoints
gen drugstart=period_start if exposed==1
by pateid: egen drugstart1 = max(drugstart)
gen trash=period_end-period_start if exposed==1
by pateid: egen exlength=max(trash)
drop trash drugstart
rename drugstart1 drugstart

drop exposed dob site armfoothand regstart1 period_start1 period_end1 count

*generate the exposure group cut points - single exposure group
generate cutp56 = drugstart - 1
generate cutp57 = drugstart + exlength

drop drugstart

save "$Datadir\su_analysis_file_interim", replace 

/* Create merged analytical file==============================================*/
* Create new cut points in SU file and reshape to wide
clear 
use "$Datadir\su_analysis_file_interim"

rename fracture_date1 eventday
rename pateid indiv

duplicates report
duplicates report indiv eventday
duplicates drop

rename cutp56 cutp58 
rename cutp57 cutp59 

gen cutp60 = cutp2

keep indiv cutp* eventday 

sort indiv eventday
bysort indiv: gen counter = _n 

reshape wide eventday, i(indiv) j(counter)

duplicates drop 

save "$Datadir\SU_analysis_file_interim_wide", replace 

* Reshape to wide and merge in SU data
clear
use "$Datadir\glitazone_analysis_file_interim"

rename fracture_date1 eventday
rename pateid indiv

duplicates report
duplicates report indiv eventday
duplicates drop

keep indiv cutp* eventday 

sort indiv eventday
bysort indiv: gen counter = _n 

reshape wide eventday, i(indiv) j(counter)

merge 1:1 indiv using "$Datadir\SU_analysis_file_interim_wide"
 
gen analysis = "GLI" if _merge == 1 
replace analysis = "SUL" if _merge == 2
replace analysis = "ALL" if _merge == 3
drop _merge

gen flag = 1 if cutp60 != cutp2 & cutp60 != .

* apply SU censoring dates if earlier 
replace cutp2 = cutp60 if cutp60 < cutp2

* censor at initiation of the other drug, if already expsosed to one drug 
** censor at initiation of su if su started after initiation of gli
replace cutp2 = cutp58 if cutp58 != . & cutp58 > cutp56 
** su file alerady censored at gli initiation 

* reshape eventday to long again 
reshape long eventday, i(indiv) j(eventnumber)
drop eventnumber 

drop if eventday == . 

* age groups 

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

local nage = 53

local a=cutp3
local b=`nage'+ 2
while `b'>3{
local c = cutp`b'
local d = ",`c'`d'"
local b = `b' - 1
}
local a = "`a'`d'"
di `a'

foreach var of varlist cutp*{
replace `var' = cutp1 if `var' < cutp1
replace `var' = cutp2 if `var' > cutp2
}

reshape long cutp, i(indiv eventday) j(type)
sort indiv eventday cutp type

*number of adverse events within each interval
** Not clear why 0.5 is added here 
by indiv: generate int nevents = 1 if eventday > cutp[_n-1]+0.5 & eventday <= cutp[_n]+0.5
* this adds zeros for events and drops all variables not named 
collapse (sum) nevents, by(indiv analysis cutp type)

*determine interval length 
by indiv: generate int interval = cutp[_n] - cutp[_n-1]

*age groups
by indiv: gen int agegr =irecode(cutp, `a')

* Create glitazone exposure   
generate gli_exgr = 0 if type == 56 
replace gli_exgr = 1 if type == 57 

* everything between 57 and 56 should now be made a 1 
by indiv: replace gli_exgr =  1 if gli_exgr[_n-1] != . & gli_exgr >= . 

** now replace everything else with zeroes 
replace gli_exgr = 0 if gli_exgr == .
 
* Create SU exposure   
generate su_exgr = 0 if type == 58 
replace su_exgr = 1 if type == 59 

* everything between 58 and 59 should now be made a 1 
by indiv: replace su_exgr =  1 if su_exgr[_n-1] != . & su_exgr >= . 

** now replace everything else with zeroes 
replace su_exgr = 0 if su_exgr == .

** drop those with unnecessary intervals 
drop if interval == 0 | interval == .
generate loginterval = log(interval)

** drop those who no longer have outcomes during the follow-up due to the earlier censoring 
bysort indiv: egen any_event = sum(nevents)
drop if any_event == 0 

* create indicator variable for exposure to either drug 
gen any = 1 if gli_exgr == 1 | su_exgr == 1 
replace any = 0 if any == . 

* create variable for ever exposed to gli/su 
bysort indiv: egen ever_gli = max(gli_exgr)
bysort indiv: egen ever_su = max(su_exgr)

* drop if exposed to both (occurs only if start/stop dates exactly the same)
drop if ever_gli == 1 & ever_su == 1 

* output dataset
save "$Datadir\merged_analysis_file", replace 
  
* Close log file 
log close