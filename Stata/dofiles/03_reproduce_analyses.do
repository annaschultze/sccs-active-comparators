/*==============================================================================
DO FILE NAME: 		 03_reproduce_analyses.do		
PROJECT: 			 SCCS Active Comparators Working Group
DATE: 				 02/11/2020
AUTHOR:				 Anna Schultze				
VERSION:			 Stata 16.1
DESCRIPTION OF FILE: This file reads in the relevant analytical datasets for 
					 each drug. 
					 Models are fitted to reproduce the main results from the 
					 published paper, and these are outputted to a table.
					 
DATASETS USED:		 Glitazones: 
					 SU: "$Datadir\SU_analysis_file"
DATASETS CREATED:	 None. 

DEPENDENCIES: 		 00_data_preparation.do  
OTHER OUTPUT: 		 table2.txt (directed to output folder)
					 log file (directed to log folder)
EDITS: 				 change to run only on merged dataset (19 Jan 2021)
==============================================================================*/

/* Housekeeping===============================================================*/ 

clear 

* Open a log file

cap log close
log using $Projectdir\log\03_reproduce_analyses, replace t

/* Open a text file===========================================================*/ 
*  results are written to this text file (row per row)
cap file close tablecontent
file open tablecontent using $Projectdir\output\table2.txt, write text replace

file write tablecontent ("Table 2: Reproduction of results from the paper") _n
file write tablecontent _tab ("Number of Fractures") _tab ("Personyears of Follow-up") _tab ("Age-adjusted Rate Ratio") _tab ("Standard Error") _tab ("95%CI") _n 

/* Glitazones=================================================================*/ 
file write tablecontent "Thiazolidinediones" _tab 

use "$Datadir\merged_analysis_file"

* generate total FU and events by drug exposure 
sort gli_exgr
by gli_exgr: egen gli_days=total(interval)
gen gli_years = gli_days/365.25
by gli_exgr: egen gli_totalevents=total(nevents)
by gli_exgr: tab gli_totalevents gli_years

* Unexposed row 
summarize gli_totalevents if gli_exgr == 0 
file write tablecontent (r(min)) _tab 

summarize gli_years if gli_exgr == 0 
file write tablecontent (r(min)) _tab 

file write tablecontent ("Baseline") _n

* Exposed row and effect estimates 

summarize gli_totalevents if gli_exgr == 1 
file write tablecontent _tab (r(min)) _tab 

summarize gli_years if gli_exgr == 1 
file write tablecontent (r(min)) _tab 

xi: xtpoisson nevents i.gli_exgr i.agegr, fe i(indiv) offset(loginterval) irr
file write tablecontent (round(r(table)[1,1]),0.01) _tab 
file write tablecontent (r(table)[2,1]) _tab 
file write tablecontent (round(r(table)[5,1]),0.01) (" - ") (round(r(table)[6,1]),0.01) _n

/* Sulphonylureas=============================================================*/
file write tablecontent "Sulphonylureas" _tab 

sort su_exgr
by su_exgr: egen su_days=total(interval)
gen su_years = su_days/365.25
by su_exgr: egen su_totalevents=total(nevents)
by su_exgr: tab su_totalevents su_years

* Unexposed row s
summarize su_totalevents if su_exgr == 0 
file write tablecontent (r(min)) _tab 

summarize su_years if su_exgr == 0 
file write tablecontent (r(min)) _tab 

file write tablecontent ("Baseline") _n

* Exposed row and effect estimates 

summarize su_totalevents if su_exgr == 1 
file write tablecontent _tab (r(min)) _tab 

summarize su_years if su_exgr == 1 
file write tablecontent (r(min)) _tab 

xi: xtpoisson nevents i.su_exgr i.agegr, fe i(indiv) offset(loginterval) irr
file write tablecontent (round(r(table)[1,1]),0.01) _tab 
file write tablecontent (r(table)[2,1]) _tab 
file write tablecontent (round(r(table)[5,1]),0.01) (" - ") (round(r(table)[6,1]),0.01) _n

* Close table output 

file close tablecontent

* Close log 

log close 


