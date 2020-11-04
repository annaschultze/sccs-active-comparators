/*==============================================================================
DO FILE NAME: 		 04a_active_comparator_simple.do		
PROJECT: 			 SCCS Active Comparators Working Group
DATE: 				 03/11/2020
AUTHOR:				 Anna Schultze				
VERSION:			 Stata 16.1
DESCRIPTION OF FILE: This file shows how to calculate a ratio of ratios using 
					 the "simple ratio" approach. 
					 
DATASETS USED:		 Glitazones: "$Datadir\Glitazones_analysis_file"
					 SU: "$Datadir\SU_analysis_file"
DATASETS CREATED:	 None. 

DEPENDENCIES: 		 00_data_preparation.do  
OTHER OUTPUT: 		 table3a.txt (directed to output folder)
					 log file (directed to log folder)		
==============================================================================*/

/* Housekeeping===============================================================*/ 

clear 

* Open a log file

cap log close
log using $Projectdir\log\04a_active_comparator_simple, replace t

/* Open a text file===========================================================*/ 
*  results are written to this text file (row per row)
cap file close tablecontent
file open tablecontent using $Projectdir\output\table3a.txt, write text replace

file write tablecontent ("Table 3: Active Comparator: Simple Ratio") _n
file write tablecontent _tab ("Age-adjusted Rate Ratio") _tab ("95%CI") _tab ("Ratio of Ratio") _tab ("95%CI")  _n 

/* Glitazones=================================================================*/ 
file write tablecontent "Thiazolidinediones" _tab 

use "$Datadir\glitazone_analysis_file"

* Extract summary information for table 
xi: xtpoisson nevents i.exgr i.agegr, fe i(indiv) offset(loginterval) irr 
file write tablecontent (round(r(table)[1,1]),0.01) _tab 
file write tablecontent (round(r(table)[5,1]),0.01) (" - ") (round(r(table)[6,1]),0.01) _n

* Calculations on log scale 
xi: xtpoisson nevents i.exgr i.agegr, fe i(indiv) offset(loginterval) 
local rr_doi = r(table)[1,1] 
local se_doi = (r(table)[2,1])  

sum(nevents) if exgr == 0
local doi_unexp_events = r(sum)
di `doi_unexp_events'

sum(nevents) if exgr == 1
local doi_exp_events = r(sum)
di `doi_exp_events'

/* Sulphonylureas=============================================================*/
file write tablecontent "Sulphonylureas" _tab 
use "$Datadir\SU_analysis_file"

* Extract summary information for table 
xi: xtpoisson nevents i.exgr i.agegr, fe i(indiv) offset(loginterval) irr 
file write tablecontent (round(r(table)[1,1]),0.01) _tab 
file write tablecontent (round(r(table)[5,1]),0.01) (" - ") (round(r(table)[6,1]),0.01) _tab

* Calculations on log scale 
xi: xtpoisson nevents i.exgr i.agegr, fe i(indiv) offset(loginterval) 
local rr_comp = r(table)[1,1] 
local se_comp = (r(table)[2,1]) 

sum(nevents) if exgr == 0
local comp_unexp_events = r(sum)
di `comp_unexp_events'

sum(nevents) if exgr == 1
local comp_exp_events = r(sum)
di `comp_exp_events' 

/* Calculate ratio============================================================*/

* Ratio 
gen ac_ratio = exp(`rr_doi')/exp(`rr_comp')

* 95%CI 
* Unclear why these calculations are not correct 
* Confirm with Nick? 
/* 
di `se_doi'
di `se_comp'

gen var_doi = `se_doi'^2 
gen var_comp = `se_comp'^2 

gen total_var = var_doi + var_comp 
gen total_se = sqrt(total_var)
gen log_ef = 1.96 * total_se 
gen ef = exp(log_ef)

gen lcl = ac_ratio - ef 
gen ucl = ac_ratio + ef
*/ 

* 95%CI - manual 

gen var_doi = (1/`doi_unexp_events') + (1/`doi_exp_events')
gen var_comp = (1/`comp_unexp_events') + (1/`comp_exp_events')

gen var_total = var_doi + var_comp 
gen se_total = sqrt(var_total) 
gen log_ef = 1.96 * se_total

gen lcl = exp((log(ac_ratio) - log_ef))
gen ucl = exp((log(ac_ratio) + log_ef))

file write tablecontent (round(ac_ratio),0.01) _tab (round(lcl),0.01) (" - ")  (round(ucl),0.01) 

* Close table output 

file close tablecontent

* Close log 

log close 



