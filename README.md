# ERSA2022 Demo
 
 ## Hi there!
 Hi there! Thank you for accessing this repository. The repo includes all the code and figures generated for this demonstration. Files are organised in a -hopefully- descriptive way. Files ending in `.ipynb` and `.R` contain the Jupyter Notebooks and R scripts used in each different phase of the demo. The file `environment.yml` allows you to import all the Python libraries you'll need to reproduce this code.
 
This is a demo version of my PhD project created for ERSA Summer School 2022. The demo focuses on the city of Caen (France), where the summer school took place.  Ideally, you should be able to reproduce this analysis in whichever location you want. To do that, you will only need to pick a study area of your choice, and download the data in the `01_data.ipynb` file.
 
## How to get the .pbf file
To use `r5r` we are going to need what's called a .pbf file.

To clip the downloaded .pbf file to our study area we need to get the appropriate .exe file from https://wiki.openstreetmap.org/wiki/Osmconvert, copy it to the folder where our .pbf file is stored, and follow the instructions.
