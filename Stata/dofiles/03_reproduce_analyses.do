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

use "$Datadir\glitazone_analysis_file"

* Unexposed row 
summarize totalevents if exgr == 0 
file write tablecontent (r(min)) _tab 

summarize years if exgr == 0 
file write tablecontent (r(min)) _tab 

file write tablecontent ("Baseline") _n

* Exposed row and effect estimates 

summarize totalevents if exgr == 1 
file write tablecontent _tab (r(min)) _tab 

summarize years if exgr == 1 
file write tablecontent (r(min)) _tab 

xi: xtpoisson nevents i.exgr i.agegr, fe i(indiv) offset(loginterval) irr
file write tablecontent (round(r(table)[1,1]),0.01) _tab 
file write tablecontent (r(table)[2,1]) _tab 
file write tablecontent (round(r(table)[5,1]),0.01) (" - ") (round(r(table)[6,1]),0.01) _n

/* Sulphonylureas=============================================================*/
file write tablecontent "Sulphonylureas" _tab 
use "$Datadir\SU_analysis_file"

sort exgr
by exgr: egen days=total(interval)
gen years = days/365.25
by exgr: egen totalevents=total(nevents)
by exgr: tab totalevents years

* Unexposed row 
summarize totalevents if exgr == 0 
file write tablecontent (r(min)) _tab 

summarize years if exgr == 0 
file write tablecontent (r(min)) _tab 

file write tablecontent ("Baseline") _n

* Exposed row and effect estimates 

summarize totalevents if exgr == 1 
file write tablecontent _tab (r(min)) _tab 

summarize years if exgr == 1 
file write tablecontent (r(min)) _tab 

xi: xtpoisson nevents i.exgr i.agegr, fe i(indiv) offset(loginterval) irr
file write tablecontent (round(r(table)[1,1]),0.01) _tab 
file write tablecontent (r(table)[2,1]) _tab 
file write tablecontent (round(r(table)[5,1]),0.01) (" - ") (round(r(table)[6,1]),0.01) _n

* Close table output 

file close tablecontent

* Close log 

log close 


