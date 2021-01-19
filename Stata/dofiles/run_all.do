/*==============================================================================
DO FILE NAME: 		 run_all.do		
PROJECT: 			 SCCS Active Comparators Working Group
DATE: 				 03/11/2020
AUTHOR:				 Anna Schultze				
VERSION:			 Stata 16.1

DESCRIPTION OF FILE: Lead do file which: 
					   - sets globals 
					   - runs all other do files in order 
==============================================================================*/

/* Housekeeping===============================================================*/ 
clear 

* Create globals for directories 

global Projectdir "J:\EHR-Working\AnnaS\Projects\02_SCCS_Active_Comparator\sccs-active-comparators\Stata"
global Datadir "Z:\GPRD_GOLD\Ian\Studies\Glitazones\Files for Anna"
global Rawdir "Z:\GPRD_GOLD\Ian\Studies\Glitazones\Stata Files"

cd $Projectdir 
pwd

/* Run all files==============================================================*/ 

do dofiles\00a_data_exploration.do
do dofiles\00b_create_merged_analysis_file.do
do dofiles\01_descriptive_data_management.do
do dofiles\02_descriptive_statistics.do
do dofiles\03_reproduce_analyses.do
do dofiles\04a_active_comparator_simple.do
do dofiles\04b_active_comparator_interaction.do

