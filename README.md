# Pc_Spread_Model
This repository includes code for a spatial model of the spread of Phytophthora cinnamomi driven by climate and landscape characteristics, as is described in the manuscript "How Important is Overland Flow for the Spread of Phytophthora cinnamomi?". In the model, the spread of the plant pathogen Phytophthora cinnamomi from an initial landscape is predicted due to local spread (i.e., root-to-root), as well as potential long-distance spread via transport in overland flow.

The code is implemented in MATLAB (R2018A). In order to run the model code, information about the initial diseased patch and the site must be supplied. Here I have provided an example of one of the patches (Patch 1) as well as climate data for the site. Complete patch and site data can be downloaded from (https://www.hydroshare.org/resource/a010a9c248284240a44180d339a2cba2/) and imported into MATLAB. Patch data were collected from prior studies of aerial images, climate data from local weather stations, and elevation data from local agencies (for full sources and metadata please see hydroshare link).

Author Info: jvwilkening@berkeley.edu 
Date: 1/23/2020

# Code
main_Pc_spread_model.m - Contains model code; where patch, site information, and parameters must be specified

example_patch.mat - Contains disease patch files (inital and final), patch topography, and "streams" file that defines areas of non-growth

Spain_climate_data.mat  - Contains climate info for the site of Patch 1

example_parameter_sets.mat - Example parameter set for tuned model parameters

plot_patch_output.m - Script for plotting model output of infected area along with actual observed initial and final patch boundaries

Other scripts are helper scripts called within the model. Scripts used in the D-infinity flow routing algorithm were developed by Steve Eddins (see citation below).

Steve Eddins (2020). Upslope area functions (https://www.mathworks.com/matlabcentral/fileexchange/15818-upslope-area-functions), MATLAB Central File Exchange. Retrieved January 23, 2020.
