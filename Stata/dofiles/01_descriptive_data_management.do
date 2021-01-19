/*==============================================================================
DO FILE NAME: 		 01_data_management.do		
PROJECT: 			 SCCS Active Comparators Working Group
DATE: 				 29/10/2020
AUTHOR:				 Anna Schultze				
VERSION:			 Stata 16.1
DESCRIPTION OF FILE: This file reads in analysis files for glitazones and SU data
					 It merges in descriptive data, and outputs files that can 
					 be used in descriptive analyses 
					 
DATASETS USED:		 $Datadir\glitazone_analysis_file.dta 
					 $Datadir\SU_analysis_file.dta
					 $Rawdir\patient details.dta
					 $Rawdir\exposure periods - multiple fracture case series - censor last presc.dta
DATASETS CREATED:	 $Datadir/giltazone_descriptives_file.dta
					 $Datadir/giltazone_descriptives_file.dta
					 
DEPENDENCIES: 		 00_data_exploration.do (sets globals, creates datasets)
OTHER OUTPUT: 		 log file (directed to log folder)	
EDITS: 				 adapt to using the single merged dataset created in 00b instead (19 Jan 2021 )	
==============================================================================*/

/* Housekeeping===============================================================*/ 

clear 

* Open a log file
cap log close
log using $Projectdir\log\01_data_management, replace t

/* Create descriptive file====================================================*/ 

use "$Datadir\merged_analysis_file"
count 

* sum of events per individual 
bysort indiv: egen fracturecount = total(nevent)

* create variable for ever exposed to gli/su 

bysort indiv: egen ever_gli = max(gli_exgr)
bysort indiv: egen ever_su = max(su_exgr)

* want to create a file with one row per patient for descriptions of chars 
* keep other variables for FU and number of fractures already created 
keep indiv fracturecount ever_* 
duplicates drop 

rename indiv pateid 

* This is now a file of all the case IDs that I want characteristics for  
* Merge in characteristics 
merge 1:m pateid using "$Rawdir\patient details.dta" 
keep if _merge == 3 

bysort pateid: gen nval = _n == 1 
count if nval

* One row for exposed and one for unexposed periods 

/* Variables to describe:
 
	- sex 
	- birthyear  
	
*/ 

keep pateid sex birthyear fracturecount ever_* 
duplicates drop 

tab sex 

* Calculate birthdate, assuming everyone is born on July 1st 
gen birthday=1
gen birthmonth=7
gen dob= mdy(birthmonth, birthday, birthyear)
format dob %d

* Merge in the start date for the exposure period 
merge 1:m pateid using "$Rawdir\Fracture case series analysis\exposure periods - multiple fracture case series - censor last presc"
keep if _merge == 3

* Calculate age at first exposure period .This is UTS and should be the same in both datasets. 
gen age_at_exp = round((regstart_12 - dob)/365.25,2)

summarize age_at_exp if sex == 1
summarize age_at_exp if sex == 2

keep pateid sex age_at_exp fracturecount ever_* 

duplicates drop 

describe 

label var pateid "Patient ID"
label var fracturecount "Number of Fractures, per person"
label var sex "Gender"
label var age_at_exp "Age at Start of FU (UTS + 365 days)"
label var ever_gli "Ever Exposed to Glitazone"
label var ever_su "Ever Exposed to Sulphonylureas"

describe 

save "$Datadir\merged_descriptives_file", replace 

* Close log 
log close 

