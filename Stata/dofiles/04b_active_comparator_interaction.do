/*==============================================================================
DO FILE NAME		 04b_active_comparator_interaction.do		
PROJECT			 SCCS Active Comparators Working Group
DATE				 03/11/2020
AUTHOR:				 Anna Schultze				
VERSION:			 Stata 16.1
DESCRIPTION OF FILEThis file shows how to calculate a ratio of ratios using 
					 the "interaction" approach 
					 
DATASETS USED:		 Glitazones"$Datadir\glitazone_analysis_file"
					 SU"$Datadir\SU_analysis_file"
DATASETS CREATED:	 $Datadir\total_analysis_file

DEPENDENCIES		 00_data_preparation.do  
OTHER OUTPUT		 table3b.txt (directed to output folder)
					 log file (directed to log folder)		
==============================================================================*/

/* Housekeeping===============================================================*/ 

clear 

* Open a log file

cap log close
log using $Projectdir\log\04b_active_comparator_interaction, replace t


/* Open a text file===========================================================*/ 
*  results are written to this text file (row per row)
cap file close tablecontent
file open tablecontent using $Projectdir\output\table3b.txt, write text replace

file write tablecontent ("Table 3Active ComparatorInteraction") _n
file write tablecontent _tab ("Model") _tab ("GLI - Rate Ratio") _tab ("95%CI") _tab ("SU - Rate Ratio") _tab ("95%CI") _tab ("ANY - Rate Ratio") _tab ("95%CI") _tab ("Interaction Term") _tab ("95%CI") _n 

/* Read in Data===============================================================*/ 
use "$Datadir\merged_analysis_file"

gen product = gli_exgr*any

/* Unadjusted Models=========================================================*/ 
file write tablecontent "UNADJUSTED" _n 
file write tablecontent "Model 1: Exposure = Glitazones" _tab 
xtpoisson nevents i.gli_exgr, fe i(indiv) offset(loginterval) irr 
file write tablecontent (round(r(table)[1,2]),0.01) _tab 
file write tablecontent (round(r(table)[5,2]),0.01) (" - ") (round(r(table)[6,2]),0.01) _n

file write tablecontent "Model 2: Exposure = Sulphonylureas" _tab 
xtpoisson nevents i.su_exgr, fe i(indiv) offset(loginterval) irr 
file write tablecontent _tab _tab (round(r(table)[1,2]),0.01) _tab 
file write tablecontent (round(r(table)[5,2]),0.01) (" - ") (round(r(table)[6,2]),0.01) _n

file write tablecontent "Model 3: Exposure = Any drug (either GLI or SU)" _tab 
xtpoisson nevents i.any, fe i(indiv) offset(loginterval) irr 
file write tablecontent _tab _tab _tab _tab (round(r(table)[1,2]),0.01) _tab 
file write tablecontent (round(r(table)[5,2]),0.01) (" - ") (round(r(table)[6,2]),0.01) _n

file write tablecontent "Model 4: Exposure = Any drug + Glitazones * Any drug Interaction Term" _tab 
xtpoisson nevents i.gli_exgr#i.any i.any, fe i(indiv) offset(loginterval) irr 
file write tablecontent _tab _tab _tab _tab _tab
file write tablecontent _tab _tab (round(r(table)[1,4]),0.01) _tab 
file write tablecontent (round(r(table)[5,4]),0.01) (" - ") (round(r(table)[6,4]),0.01) _n

file write tablecontent "Model 5: Exposure = Any drug + Manually Created Product Term" _tab 
xtpoisson nevents i.product i.any, fe i(indiv) offset(loginterval) irr 
file write tablecontent _tab _tab _tab _tab _tab
file write tablecontent _tab _tab (round(r(table)[1,2]),0.01) _tab 
file write tablecontent (round(r(table)[5,2]),0.01) (" - ") (round(r(table)[6,2]),0.01) _n
 
/* Adjusted Models=========================================================*/ 
file write tablecontent "ADJUSTED" _n 
file write tablecontent "Model 1: Exposure = Glitazones" _tab 
xtpoisson nevents i.gli_exgr i.agegr, fe i(indiv) offset(loginterval) irr 
file write tablecontent (round(r(table)[1,2]),0.01) _tab 
file write tablecontent (round(r(table)[5,2]),0.01) (" - ") (round(r(table)[6,2]),0.01) _n

file write tablecontent "Model 2: Exposure = Sulphonylureas" _tab 
xtpoisson nevents i.su_exgr i.agegr, fe i(indiv) offset(loginterval) irr 
file write tablecontent _tab _tab (round(r(table)[1,2]),0.01) _tab 
file write tablecontent (round(r(table)[5,2]),0.01) (" - ") (round(r(table)[6,2]),0.01) _n

file write tablecontent "Model 3: Exposure = Any drug (either GLI or SU)" _tab 
xtpoisson nevents i.any i.agegr, fe i(indiv) offset(loginterval) irr 
file write tablecontent _tab _tab _tab _tab (round(r(table)[1,2]),0.01) _tab 
file write tablecontent (round(r(table)[5,2]),0.01) (" - ") (round(r(table)[6,2]),0.01) _n

file write tablecontent "Model 4: Exposure = Any drug + Glitazones * Any drug Interaction Term" _tab 
xtpoisson nevents i.gli_exgr#i.any i.any i.agegr, fe i(indiv) offset(loginterval) irr 
file write tablecontent _tab _tab _tab _tab _tab
file write tablecontent _tab _tab (round(r(table)[1,4]),0.01) _tab 
file write tablecontent (round(r(table)[5,4]),0.01) (" - ") (round(r(table)[6,4]),0.01) _n

file write tablecontent "Model 5: Exposure = Any drug + Manually Created Product Term" _tab 
xtpoisson nevents i.product i.any i.agegr, fe i(indiv) offset(loginterval) irr 
file write tablecontent _tab _tab _tab _tab _tab
file write tablecontent _tab _tab (round(r(table)[1,2]),0.01) _tab 
file write tablecontent (round(r(table)[5,2]),0.01) (" - ") (round(r(table)[6,2]),0.01) _n
 
* Close table output 

file close tablecontent

* Close log 

log close 



