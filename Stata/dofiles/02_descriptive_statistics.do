/*==============================================================================
DO FILE NAME: 		 02_descriptive_statistics.do		
PROJECT: 			 SCCS Active Comparators Working Group
DATE: 				 02/11/2020 
AUTHOR:				 Anna Schultze				
VERSION:			 Stata 16.1
DESCRIPTION OF FILE: This file reads in the datasets with patient characteristics 
					 for both the glitazone and the sulphonyurea analyses
					 It outputs descriptive tables. 
					 
DATASETS USED:		 $Datadir\glitazone_descriptives_file.dta
					 $Datadir\SU_descriptives_file.dta
DATASETS CREATED:	 None. 

DEPENDENCIES: 		 00_data_exploration.do 
				     01_data_management.do 
OTHER OUTPUT: 		 table1a.txt (directed to output folder)
					 table1b.txt (directed to output folder)
					 log file (directed to log folder)		
EDITS: 				 use just the merged analytical file 
==============================================================================*/

/* Housekeeping===============================================================*/ 

* Create globals for directories 

clear

* Open a log file

cap log close
log using $Projectdir\log\02_descriptive_statistics, replace t


/* Define programs to generate summary statistics ============================*/ 

cap prog drop summarisecat 
program define summarisecat
syntax, variable(varname) condition(string) 

	* Extract the value of the variable and print it (can change code to value label but variables here are counts)
	qui sum `variable' if `variable' `condition'
	file write tablecontent (r(min)) _tab
	
	* Create the overall denominator 
	cou
	local overalldenom=r(N)
	
	* Calculate number with characteristics, manually construct % and print to file 
	cou if `variable' `condition'
	local rowdenom = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	file write tablecontent %9.0gc (`rowdenom')  (" (") %3.1f (`colpct') (")") _tab
	
end

cap prog drop summarisecont
prog define summarisecont 
syntax, variable(varname) 
	
	qui summarize `variable', d
	file write tablecontent ("Median (IQR)") _tab 
	file write tablecontent (round(r(p50)),0.01) (" (") (round(r(p25)),0.01) ("-") (round(r(p75)),0.01) (")") _n
														
	qui summarize `variable', d
	file write tablecontent ("Mean (SD)") _tab 
	file write tablecontent (round(r(mean)),0.01) (" (") (round(r(sd)),0.01) (")") _n
						
	qui summarize `variable', d
	file write tablecontent ("Min, Max") _tab 
	file write tablecontent (round(r(min)),0.01) (", ") (round(r(max)),0.01) ("") _n
							
end

/* Summary Table============================================================*/

cap file close tablecontent
file open tablecontent using $Projectdir\output\table1.txt, write text replace

file write tablecontent ("Table 1: Demographic and Clinical Characteristics") _n

* Totals 

file write tablecontent "Total" _n

use "$Datadir\merged_descriptives_file"
count 
file write tablecontent _tab (r(N))
file write tablecontent _n

* Gender 
file write tablecontent "Gender" _n
summarisecat, variable(sex) condition("==2") 
file write tablecontent _n 

* Age 
file write tablecontent "Age at Exposure" _n
summarisecont, variable(age_at_exp) 
file write tablecontent _n 

* GLI exposure 
file write tablecontent "Glitazone Exposed" _n
summarisecat, variable(ever_gli) condition("==1") 
file write tablecontent _n 

* SU exposure 
file write tablecontent "Sulphonylurea Exposed" _n
summarisecat, variable(ever_su) condition("==1") 
file write tablecontent _n 

* Number of Fractures 
file write tablecontent "Number of Fractures" _n
summarisecat, variable(fracturecount) condition("==1") 
file write tablecontent _n 

summarisecat, variable(fracturecount) condition("==2") 
file write tablecontent _n 

summarisecat, variable(fracturecount) condition("==3") 
file write tablecontent _n 

summarisecat, variable(fracturecount) condition("==4") 
file write tablecontent _n 

* Close table output 
file close tablecontent

* Close log 
log close 




















