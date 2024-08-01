
	* Purpose: Downloading, Extracting, Cleaning, Saving the cleaned Mouza Census (2020)
	
	* Date Created: August 1, 2024
	* Date Modified: August 1, 2024
	
	* Author: Fahad Mirza
	
	
********************************************************************************
********************************************************************************

	
	* Create main and sub-directory to store the Mouza Census along with extracted file
	capture noisily mkdir "./Mouza_Census_2020"
	capture noisily mkdir "./Mouza_Census_2020/Mouza_Census_2020_SPSS_Unzipped"
	
	* Download the file from PBS website and save it to the main directory created above 
	copy https://www.pbs.gov.pk/sites/default/files/agriculture/mouza_census_2020/mc2020.spss.rar "./Mouza_Census_2020/mc2020_spss.rar"

	* Extract the RAR file and save it in the sub-directory to import into Stata
	* Note: You need to have WinRAR installed before doing this.
	* After installing, provide path for the WinRar Installation in the code below.
	* You can download WinRAR from here: https://www.win-rar.com/fileadmin/winrar-versions/winrar/winrar-x64-701.exe
	! "C:/Program Files/WinRAR/WinRAR.exe" x -ibck "./Mouza_Census_2020/mc2020_spss.rar" *.* "./Mouza_Census_2020/Mouza_Census_2020_SPSS_Unzipped/"
	
	* Where:
	* 	x 		means to extract files from archive file
	* 	-ibck 	means to run WinRAR in background
	* 	*.* 	means to extract all files within the archive file
	
	* The code above asks for location of WinRAR installation, then asks where the RAR file is
	* and then asks where you want to save the extracted files
	
	
********************************************************************************	
********************************************************************************	
	
	* Convert the data to Stata format and apply variable labels

	* Importing SPSS File of Mouza Census 2020 into Stata
	import spss using "./Mouza_Census_2020/Mouza_Census_2020_SPSS_Unzipped/Mouza Census-2020.spss.sav", case(lower) clear
	
	* Renaming the variable
	rename _v1 v1
	
	* The variable label is stored in the first row of the data
	* This also requires a bit of cleaning as district code etc. are not labeled properly
	replace v1 = "Province Code" in 1
	replace v3 = "Division Code" in 1
	replace v5 = "District Code" in 1
	replace v7 = "Tehsil Code"   in 1
	replace v9 = "Village Code"  in 1
	
	
	* Applying variable label from the first row of data
	* Ensuring that there is no double inverted commas as that is an illegal operation
	foreach var of varlist * {
		
		replace `var' = subinstr(`var', `"""', "", .)
		label variable `var' "`=`var'[1]'"
	
	}	
	
	drop in 1
	
	* With the variable labels assigned, we now use the new first row to rename
	* variables
	
	foreach var of varlist * {
		
		replace `var' = subinstr(`var', `"""', "", .)		
		rename `var' `=`var'[1]'
	
	}	
	
	rename *, lower
	drop in 1
	
	* Destring the entire data and compress
	destring _all, replace
	
	* There are 2 variables that are numeric but contain a character causing it
	* not to convert to numeric due to them containing dashes
	foreach var of varlist p4q1112 p7q012 {
		
		replace `var' = subinstr(`var', "-", "", .)
		destring `var', replace
		
	}
	
	* Save the dataset in Stata format before cleaning it.
	save "./Mouza_Census_2020/Mouza_Census_2020_SPSS_Unzipped/00_Convert_SPSS_to_Stata.dta", replace	
	
	
********************************************************************************	
********************************************************************************

	* Cleaning the converted dataset 
	
	* Load the data
	cls
	use "./Mouza_Census_2020/Mouza_Census_2020_SPSS_Unzipped/00_Convert_SPSS_to_Stata.dta", clear
	
	* If settlements are 0 in the mouza then all observations should be missing
	egen value_total = rowtotal(p2q011-p3q031 p3q041-p3q0510 p3q071-p9q0227) if p1q10 == 0
	
	foreach var of varlist p2q011 - p9q0227 {
		
		replace `var' = . if value_total == 0
		
	}
	
	drop value_total

	* Value labels for type of mouza status
	label define p1q09 1 "Rural" 2 "Urban" 3 "Partly Urban" 4 "Forest" 5 "Unpopulated" , replace
	label values p1q09 p1q09
	
	* Value label for construction type
	label define p3q01 1 "Bricked" 2 "Mud Made" 3 "Bricks & Mud" 4 "Other" , replace
	label values p3q01 p3q01
		
	* Value label for Street status	
	label define p3q02 1 "Metaled" 2 "Concrete/Cement" 3 "Brick/Soling" 4 "Dirt" , replace
	label values p3q02 p3q02	
	
	* Cleaning for water course improvement scheme
	replace p3q031 = 0 if p3q031 == 2											// Replacing No with 0
	replace p3q032 = 2 if p3q032 == 0 											// Replacing 0 with value for private
	
	label define p3q031 1 "Yes" 0 "No" , replace
	label values p3q031 p3q031	
	
	label define p3q032 1 "Government" 2 "Private" , replace
	label values p3q032 p3q032	
	
	* Value label for taste of underground water
	label define p3q041 1 "Sweet" 2 "Brakish" , replace
	label values p3q041 p3q041	
	
	
	* Note: Check for better solution of p3q05 (Source of drinking water)
	forvalues i = 1/9 {
		
		replace p3q050`i' = 1 if !missing(p3q050`i')
		
	}
	
	replace p3q0510 = 1 if !missing(p3q0510)
	
	egen total_val = rowtotal(p3q0501 - p3q0510)
	order total_val, after(p3q0510)
	
	foreach var of varlist p3q0501 - p3q0510 {
		
		replace `var' = 0 if total_val > 0 & missing(`var')
		
	}
	
	drop total_val

	
	
	* Value label for Toilet facility
	replace p3q06 = 2 if p3q06 == 0 											// Replacing 0 with "Open Place" value 
	label define p3q06 1 "Inside House" 2 "Open Place" , replace
	label values p3q06 p3q06	
	
	
	* Value label for Cemented Drain & Sewerage System
	label define p3q071 1 "All" 2 "Mostly" 3 "Some" 4 "None" , replace
	label values p3q071 p3q071	
	
	label define p3q072 1 "All" 2 "Mostly" 3 "Some" 4 "None" , replace
	label values p3q072 p3q072	
	
	
	* Looping over the 8 options for Health facilities
	forvalues i = 1/8 {
	
		replace p3q08`i'1 = 0 if p3q08`i'1 == 2
		replace p3q08`i'2 = . if p3q08`i'1 == 1 								//Next question only applicable if answered no
		label define p3q08`i'1 1 "Yes" 0 "No", replace
		label values p3q08`i'1 p3q08`i'1
	
	}
	
	
	* Looping over the 6 options for Education facilities
	* For both boys and girls
	forvalues i = 1/2 {
		forvalues j = 1/6 {
			
			replace p4q1`i'`j'1 = 0 if p4q1`i'`j'1 == 2
			replace p4q1`i'`j'2 = . if p4q1`i'`j'1 == 1 						//Next question only applicable if answered no
			label define p4q1`i'`j'1 1 "Yes" 0 "No", replace
			label values p4q1`i'`j'1 p4q1`i'`j'1
				
		}
		
	}
	
	
	* Regular playgrounds in mouza for boys and girls 
	forvalues i = 1/7 {
		
		replace p4q021`i' = 1 if !missing(p4q021`i')
		
	}
		
	egen total_val = rowtotal(p4q0211 - p4q0217)
	order total_val, after(p4q0217)
	
	foreach var of varlist p4q0211 - p4q0217 {
		
		replace `var' = 0 if total_val > 0 & missing(`var')
		
	}
	
	drop total_val


	forvalues i = 1/7 {
		
		replace p4q022`i' = 1 if !missing(p4q022`i')
		
	}
		
	egen total_val = rowtotal(p4q0221 - p4q0227)
	order total_val, after(p4q0227)
	
	foreach var of varlist p4q0221 - p4q0227 {
		
		replace `var' = 0 if total_val > 0 & missing(`var')
		
	}
	
	drop total_val
	
	
	
	
	* Looping over 2 options of p5q01 (Vet healthcare facility in mouza)
	forvalues i = 1/2 {
		
		replace p5q01`i'1 = 0 if p5q01`i'1 == 2
		replace p5q01`i'2 = . if p5q01`i'1 == 1 								//Next question only applicable if answered no
		label define p5q01`i'1 1 "Yes" 0 "No", replace
		label values p5q01`i'1 p5q01`i'1		
		
	}
	
	replace p5q013 = 0 if p5q013 == 2
	label define p5q013 1 "Yes" 0 "No", replace
	label values p5q013 p5q013		
	
	
	* For questions on number of farms, replace 0 with missing as that will
	* drive down the values overall
	
	forvalues i = 2/4 {
		
		replace p5q02`i' = . if p5q02`i' == 0
		replace p5q02`i' = . if p5q021   == 1
		
	}
	
	
	*Note: Question number p5q03 on livestock information not in dataset
	
	
	* Value labels for Part 6 question 1 on Availability of electricity
	label define p6q011 1 "All" 2 "Mostly" 3 "Some" 4 "None" , replace
	label values p6q011 p6q011
	
	replace p6q012 = . if p6q011 < 4
	
	
	* Cleaning the alternate source of electricity variable
	forvalues i = 1/5 {
		
		replace p6q02`i' = 1 if !missing(p6q02`i')
		
	}
		
	egen total_val = rowtotal(p6q021 - p6q025)
	order total_val, after(p6q025)
	
	foreach var of varlist p6q021 - p6q025 {
		
		replace `var' = 0 if total_val > 0 & missing(`var')
		
	}
	
	drop total_val
	
	
	* Cleaning up the variables for fuel availability
	forvalues i = 1/5 {
		
		replace p6q03`i' = 1 if !missing(p6q03`i')
		
	}
		
	egen total_val = rowtotal(p6q031 - p6q035)
	order total_val, after(p6q035)
	
	foreach var of varlist p6q031 - p6q035 {
		
		replace `var' = 0 if total_val > 0 & missing(`var')
		
	}
	
	drop total_val	

	
	* Cleaning variable for road facility to mouza
	label define p6q041 1 "Metaled" 2 "Concrete/Cement" 3 "Brick/Soling" 4 "Dirt" , replace
	label values p6q041 p6q041
	
	
	* Cleaning up the variables for media sources in mouza
	forvalues i = 1/5 {
		
		replace p6q05`i' = 1 if !missing(p6q05`i')
		
	}
		
	egen total_val = rowtotal(p6q051 - p6q055)
	order total_val, after(p6q055)
	
	foreach var of varlist p6q051 - p6q055 {
		
		replace `var' = 0 if total_val > 0 & missing(`var')
		
	}
	
	drop total_val		
	
	
	* Cleaning variables p6q06 to p6q16
	forvalues i = 6/9 {
	
		replace p6q0`i'1 = 0 if p6q0`i'1 == 2
		replace p6q0`i'2 = . if p6q0`i'1 == 1 									//Next question only applicable if answered no
		label define p6q0`i'1 1 "Yes" 0 "No", replace
		label values p6q0`i'1 p6q0`i'1
	
	}	
	
	forvalues i = 10/12 {
	
		replace p6q`i'1 = 0 if p6q`i'1 == 2
		replace p6q`i'2 = . if p6q`i'1 == 1 									//Next question only applicable if answered no
		label define p6q`i'1 1 "Yes" 0 "No", replace
		label values p6q`i'1 p6q`i'1
	
	}	
	
	
	forvalues i = 13/16 {
		forvalues j = 1/3 {
	
		capture noisily replace p6q`i'`j'1 = 0 if p6q`i'`j'1 == 2
		capture noisily replace p6q`i'`j'2 = . if p6q`i'`j'1 == 1 				//Next question only applicable if answered no
		capture noisily label define p6q`i'`j'1 1 "Yes" 0 "No", replace
		capture noisily label values p6q`i'`j'1 p6q`i'`j'1
		
		}
	}		
	
	
	generate p6q1511 = 1 if p6q1512 == 0 , before(p6q1512) 
	replace  p6q1511 = 0 if p6q1512 > 0 & !missing(p6q1512) 
	replace  p6q1512 = . if p6q1512 == 0
	label define p6q1511 1 "Yes" 0 "No", replace
	label values p6q1511 p6q1511
	
	
	* Cleaning variable for Community grazing land in mouza
	
	replace p7q011 = 0 if p7q011 == 2
	replace p7q012 = . if p7q011 == 0 											//Next question only applicable if answered no
	label define p7q011 1 "Yes" 0 "No", replace
	label values p7q011 p7q011
	
	* Cleaning variable for Community forest in mouza
	
	replace p7q021 = 0 if p7q021 == 2
	replace p7q022 = . if p7q021 == 0 											//Next question only applicable if answered no
	label define p7q021 1 "Yes" 0 "No", replace
	label values p7q021 p7q021

	
	* Natural disasters faced in last 5 years
	replace p7q031 = 0 if p7q031 == 2
	label define p7q031 1 "Yes" 0 "No" , replace
	label values p7q031 p7q031
	
	forvalues i = 1/4 {
		
		replace p7q032`i' = 1 if !missing(p7q032`i')
		
	}
		
	egen total_val = rowtotal(p7q0321 - p7q0324)
	order total_val, after(p7q0324)
	
	foreach var of varlist p7q0321 - p7q0324 {
		
		replace `var' = 0 if total_val > 0 & missing(`var')
		
	}
	
	drop total_val	
	
	* Sources of credit in mouza
	forvalues i = 1/9 {
		
		replace p8q01`i' = 1 if !missing(p8q01`i')
		
	}
		
	egen total_val = rowtotal(p8q011 - p8q019)
	order total_val, after(p8q019)
	
	foreach var of varlist p8q011 - p8q019 {
		
		replace `var' = 0 if total_val > 0 & missing(`var')
		
	}
	
	drop total_val	
	
	
	* Cleaning from p8q021 to p8q052
	forvalues i = 2/5 {
	
		replace p8q0`i'1 = 0 if p8q0`i'1 == 2
		replace p8q0`i'2 = . if p8q0`i'1 == 1 									//Next question only applicable if answered no
		label define p8q0`i'1 1 "Yes" 0 "No", replace
		label values p8q0`i'1 p8q0`i'1
	
	}	
	
	
	* Cleaning for NGOs in mouza  	
	
	forvalues i = 1/5 {
		
		replace p8q061`i' = 1 if !missing(p8q061`i')
		replace p8q062`i' = 1 if !missing(p8q062`i')
		
	}
		
	egen total_val1 = rowtotal(p8q0611 - p8q0615)
	order total_val1, after(p8q0615)

	egen total_val2 = rowtotal(p8q0621 - p8q0625)
	order total_val2, after(p8q0625)
	
	foreach var of varlist p8q0611 - p8q0615 {
		
		replace `var' = 0 if total_val1 > 0 & missing(`var')
		
	}
	
	foreach var of varlist p8q0621 - p8q0625 {
		
		replace `var' = 0 if total_val2 > 0 & missing(`var')
		
	}	
	
	drop total_val*	
	
	
	* Cleaning industries in Mouza
	forvalues i = 1/5 {
		
		replace p9q01`i' = 1 if !missing(p9q01`i')
		
	}
		
	egen total_val = rowtotal(p9q011 - p9q015)
	order total_val, after(p9q015)
	
	foreach var of varlist p9q011 - p9q015 {
		
		replace `var' = 0 if total_val > 0 & missing(`var')
		
	}
	
	drop total_val
	
	
	* Cleaning the sources of employment of populace
	forvalues i = 1/2 {
		forvalues j = 1/7 {
			
			label define p9q02`i'`j' 1 "Mostly" 2 "Some" 3 "None" , replace
			label values p9q02`i'`j' p9q02`i'`j'
			
		}
		
	}	
	
	
********************************************************************************
********************************************************************************	

	* Saving the cleaned data
	save "./Mouza_Census_2020/Mouza_Census_2020_SPSS_Unzipped/01_Cleaned_Mouza_Census_2020.dta", replace





