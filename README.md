# Drought Impacts On Motile Invertebrates of the Rocky Intertidal

## Description
This repository contains all of the necessary code to implement a simple analysis on the impacts of drought on motile invertebrate abundance and diversity in the rocky intertidal zone of coast range ecoregion in California. This project used data from the Multi-Agency Rocky Intertidal Network (MARINe) and the U.S. Drought Monitor. The project used fixed effects linear models to compare drought condition in the year observations were taken and the previous year to abundance and diversity of motile invertebrates. The drought-inverts-pdf.pdf file contains a summary of the analysis. 

## How to Implement This Project
In order to recreate the analysis follow these steps
#### Step 1. 
Request data access from MARINe through a form available on their [website](https://marine.ucsc.edu/explore-the-data/index.html). Once you have access, download the motile-invertebrate-counts.csv file. 

#### Step 2.
Download the shape files for the time period you are interested in from U.S. Drought Monitor's [website](https://droughtmonitor.unl.edu/)

**NOTE: You will need to update the file paths in each of the following file to reflect the location of the data on your computer.** 

#### Step 3. 
Run the drought_data_wrangle.R file, this reads in and compiles the shape files into a dataframe and saves the file to your computer. 
  **NOTE: After downloading you will need to unzip the shapefiles.**
  
#### Step 4. 
Run the invert_data_wrangle1.R file. It is recommended that this be done on a remote server if possible. If not possible be patient, it takes approximately 36 hours to finish. This also save the resulting data frame with the drought condition for each observation in the invert counts data to your computer. 

#### Step 5. 
Run the invert_data_wrangle2.R file. This cleans up the data frame created in the previous step.

#### Step 6. 
You are now set up to run the drought_inverts_pdf.qmd file and view the analysis steps.

## Planned edits
- Update the drought_data_wrangle R script to read in and compile the shape files more efficiently. 
- Update method of joining drought data to invertebrate count data finsish faster. 
- Expand analysis to include other outcome variables incluidng invert size and distribution.
- Expand analysis to include additional dependent variables. 
- Expand analysis to include observations from the summer sampling season. 

