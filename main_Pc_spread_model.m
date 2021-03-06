%% Main Pc Model Code
%To use, change settings in first section for site and patch inputs
%Further patch and climate data can be downloaded from
%https://www.hydroshare.org/resource/a010a9c248284240a44180d339a2cba2/ and
%imported into matlab file formats
%% Model Set-Up
clear all
close all

%Load patch and site data
load('example_patch.mat') %load dtms and patch info
load('example_parameter_sets.mat') %loads parameter sets (1st column=d, 2nd column=\Delta r, 3rd column=Dmax, 4th column = alpha)
parameter_sets=parameter_sets;
load('Spain_climate_data.mat') %loads temp, precipitation, and ET (based on Hargreaves) data
patchnum=1; %patch number for file name
elevation=patch1_dtm; %specify patch dtm
[xdim, ydim]=size(elevation); %finds dimensions of dtm/patch

%If patch has areas of non-growth, use first line with "streams" file; if
%not use second line
streams=patch1_streams; %identifies location of non-growth
%streams=ones(xdim, ydim);%all areas suitable for pathogen growth


initialpatch=patch1_1981; %starting disease patch
finalpatch=patch1_1984; %final disease patch
theta_initial=.4082; %theta from summer spin up test


overland_transport=1; %=1 then uses overland transport, =0 turns off overland transport
bottom_drainage=0; %=1 than leakage at bottom boundary; if impermeable set =0 for no drainage



%choose parameter sets to run, can be single or multiple (each will save
%separate output)
param_set_start=1; 
param_set_end=1;


%set time for model to run
start_year=1981;%input start date for model
start_month=3;
start_day=1;

final_year=1984; %input end date for model
final_month=8;
final_day=1;

%Discretization
dt =1;       % Temporal increment (days), should be in same increment as climate forcing data
dx=1;           % x-direction Spatial increment (should match elevation grid)
dy=1;           %y-direction spatial increment (should match elevation grid)

%Infection settings
sourcestrength=1; %assume this is max population size for logistic growth curve
infection_point=0.5; %portion of initial source strength for cell to be considered infected


%define soil properties (sandy loam)
psi_s=-2.10; %Saturation water potential (kPa)
b=4.90; %Retention curve exponent
n=0.43; %porosity
thetawp=0.18; %Soil water content at wilting point [-]
thetastar=0.46; %Soil water content at complete stomatal opening [-]
k_sat= 64368; %saturated hydraulic conductivity, should be in mm/time increment equivalent to time step
z = 700; % soil depth in mm
interaction_depth=20; %depth of interaction with overland flow (mm)

nz = n*z;       % depth times porosity
eff_depth_prop=interaction_depth/z; %proportion of depth that will be cleared with overland flow


%finds indices of start and end dates to use for weather data
start_index=find_index(start_year, start_month, start_day, year, month, day); %finds index of starting date in climate data
final_index=find_index(final_year, final_month, final_day, year, month, day); %finds index of final date in climate data

%domain size set-up
x = 1:dx:xdim;     % x-direction Spatial domain
nx = length(x); % number of x steps

y= 1:dy:ydim;      %y-direction spatial domain
ny= length(y);    %number of y steps



%% Overland Flow Setup with D-Infinity Algorithms
elevation=fill_sinks(elevation); %fill inner sinks in DTM
[R, S] = dem_flow(elevation); %find direction of flow from each cell (R)


T = flow_matrix(elevation, R); %T defines flow between cells
A=upslope_area(elevation,T); %find upslope area of each cell

B=reshape(A,1,numel(A)); %find ascending order of upslope areas to use as order for cells in overflow function
B=sort(B);
B=unique(B);



%% Loop through parameter sets
trial=0;
for test=param_set_start:param_set_end
    test
    trial=trial+1;
%%Reset arrays and parameters for trial

    %set parameters for trial
    d = parameter_sets(test, 1);       % Mortality rate
    growth_temp=parameter_sets(test, 2); %temperature dependence of growth
    if overland_transport==1
        alpha=parameter_sets(test, 4); %overland transport parameter
    else
        alpha=0;
    end
    D=parameter_sets(test, 3); %diffusion coefficient

    t_storm=0; %storm time
    overland=0; %used to call overland flow function (=1) 
    oversat=0; %flag for when saturation occurs
    infil_excess=0; %flag for if infiltration excess overland occurs
    precip_excess=0; %precipitation that doesn't infiltrate to do infiltration excess

    Xold = zeros(nx, ny);
    Xmax = zeros(nx, ny);
    Xnew=Xold;

    for i=1:nx %define starting disease patch
        for j=1:ny
            if initialpatch(i,j)>0
                Xold(i,j)=sourcestrength;
            end
        end
    end
    
    
    
    %initialize arrays for numerical terms
    dX2dx2 = zeros(nx,ny);
    dX2dy2 = zeros(nx,ny);
    dXdx = zeros(nx,ny);
    dXdy = zeros(nx,ny);
    dXdt= zeros(nx, ny);
    dthetadt= zeros(nx, ny);

    %initialize soil moisture arrays
    thetaOld = zeros(nx, ny);
    thetaOld(:,:) = theta_initial; %start soil moisture based on spin up test
    thetaNew=thetaOld;


    %% Computations 

    for t=start_index:dt:final_index %loop over time
        ET=ETmax(t);

        %precipitation at given time from site data
        P=Precip_CHIRPS(t);
        Precip_next=Precip_CHIRPS(t+1);

        
        %keep track of storm length
        if P>0
            t_storm=t_storm+dt;
            if Precip_next>0
                end_storm=0;
            else
                end_storm=1;
            end
        else
            t_storm=0;
        end
        
        %check for infiltration excess runoff generation
        if P > k_sat
            infil_excess=1;
            precip_excess=precip_excess+(P-k_sat);
            overland=1;
            P=k_sat; %effective precipitation equal to Ksat
        end
        

        %adjusts growth rate based on average temperature of day
        r=-.171+growth_temp*T_mean(t);


        %Enforce boundary conditions at x and y limits 

        dX2dx2(1,:) = (Xold(2,:)-2*Xold(1,:))/(2*dx.^2);
        dX2dy2(1,2:(ny-1)) = (Xold(1,(1:ny-2))-2*Xold(1,2:(ny-1))+Xold(1,(3:ny)))/(dy.^2);
        dX2dx2(nx,:) = (Xold(nx,:)-2*Xold((nx-1),:))/(2*dx.^2);
        dX2dy2(nx,2:(ny-1)) = (Xold(nx,(1:ny-2))-2*Xold(nx,2:(ny-1))+Xold(nx,(3:ny)))/(dy.^2);
        dX2dy2(:,1) = (-2*Xold(:,1)+Xold(:,2))/(2*dy.^2);
        dX2dx2(2:nx-1, 1)=(Xold(1:nx-2,1)-2*Xold(2:nx-1,1)+Xold(3:nx,1))/(dx.^2);
        dX2dy2(:,ny) = (Xold(:,ny)-2*Xold(:,ny-1))/(2*dy.^2);
        dX2dx2(2:nx-1, ny)=(Xold(1:nx-2,ny)-2*Xold(2:nx-1,ny)+Xold(3:nx,ny))/(dx.^2);


        for j=2:ny-1 %loop over y 
            for i=2:nx-1 %loop over x

                dX2dx2(i,j) = (Xold(i-1,j)-2*Xold(i,j)+Xold(i+1,j))/(dx.^2);
                dX2dy2(i,j) = (Xold(i,j-1)-2*Xold(i,j)+Xold(i,j+1))/(dy.^2);

            end
        end

        for j=1:ny
            for i=1:nx

                if thetaOld(i,j)<=thetawp, g = 0; %find actual ET rate based on theta
                elseif thetaOld(i,j)>thetawp && thetaOld(i,j)<=thetastar; g = ET*(thetaOld(i,j)-thetawp)/(thetastar-thetawp);
                else g = ET; 
                end
                
                if bottom_drainage == 1
                    leakage=k_sat*(theta_Old(i,j).^(2*b+3)); %leakage at bottom boundary
                else
                    leakage=0; %impermeable bottom boundary no leakage
                end
                
                dthetadt(i,j) = 1/(n*z)*(P-g-leakage); %change in theta
                
                thetaNew(i,j) = thetaOld(i,j) + dthetadt(i,j)*dt; %new theta value

                potential = psi_s * thetaOld(i,j).^(-b); %calculate soil water potential

                  tj = Phyto_scaling(potential); %scaling factor for phytophthora growth and diffusion dependent on soil moisture state

                
                saved_precip(t-start_index+1)=P;
                
                %change in biomass: (diffusion in x)+(diffusion in y)+net
                %logistic growth
                if (r*tj-d)<0 && (sourcestrength-Xold(i,j))<0
                    dXdt(i,j) = dX2dx2(i,j)*D*tj+dX2dy2(i,j)*D*tj+abs((r*tj-d))*Xold(i,j)*((sourcestrength-Xold(i,j))/sourcestrength);
                else
                    dXdt(i,j) = dX2dx2(i,j)*D*tj+dX2dy2(i,j)*D*tj+(r*tj-d)*Xold(i,j)*((sourcestrength-Xold(i,j))/sourcestrength); 
                end

                %find new biomass
                Xnew(i,j)=Xold(i,j)+dXdt(i,j)*dt;

                %corrects for case if biomass became less than zero
                if Xnew(i,j) <0 || isnan(Xnew(i,j))==1
                    Xnew(i,j)=0;
                end
                
               

            end
        end


        %biomass will not survive in streams
        Xnew=Xnew.*streams;

        %check if any of the grid points are oversaturated
        for i=1:nx
            for j=1:ny
                if thetaNew(i,j)>1
                    overland=1; %will call overland flow functions
                    oversat=1;
                    break
                end
            end
        end

        %if any grid point is above saturation, calls the overland flow
        %will only do transport when t_storm >= 1 day or if it's the end of
        %the current storm
        %function which gives updated theta and biomass
        if overland ==1 && overland_transport==1
            if t_storm >= 1 || end_storm == 1
                mean_theta=mean(mean(thetaNew));
                if infil_excess == 1 && oversat ==1 %both infiltration excess and saturation excess contribute to runoff
                    runoff_depth=precip_excess/1000 + (mean_theta-1)*n*z/1000; %runoff depth in m
                elseif infil_excess ==1 && oversat==0 %only infiltration excess 
                    runoff_depth=precip_excess/1000;
                else %only saturation excess
                    runoff_depth=(mean_theta-1)*n*z/1000; %runoff depth in m
                end
                [Xnew] = biomass_runoff_transport(Xnew, runoff_depth, t_storm, nx, ny, alpha, elevation, T, A, dx, dy, eff_depth_prop, S, 1.0);
                overland=0;
                infil_excess=0;
                precip_excess=0;
                oversat=0;
                t_storm=0;
                thetaNew(:,:)=1;
            end
        elseif oversat==1 && overland_transport~=1 %if overland transport off just updates water balance
            thetaNew(:,:)=1;
            overland=0;
            oversat=0;
        elseif infil_excess==1 && overland_transport~=1 %if overland transport off just updates water balance
            overland=0;
            precip_excess=0;
            infil_excess=0;
        end

        %update maximum biomass values
        for i=1:nx
            for j=1:ny
                if Xnew(i,j)>Xmax(i,j)
                    Xmax(i,j)=Xnew(i,j);
                end
            end
        end


        %update biomass and soil moisture arrays for next time iteration
        thetaOld=thetaNew;
        Xold=Xnew;

    end
    
    
    %record end result info
    
    both_infect(trial)=0;
    both_healthy(trial)=0;
    false_positive(trial)=0;
    false_negative(trial)=0;
    orientation(trial)=0;
    eccentricity(trial)=0;
    majaxis(trial)=0;
    minaxis(trial)=0;
    correct_ratio(trial)=0;
    percent_growth_predicted(trial)=0;
    patch_area(trial)=0;

    
    
    %find infected cells
    for i=1:nx
            for j=1:ny
                if Xmax(i,j)>(infection_point*sourcestrength)
                    infectedcells(i,j)=1; %cell considered infected
                else
                    infectedcells(i,j)=0; %cell not considered infected
                end
            end
    end
    

    
    %find error
    for i=1:nx
        for j=1:ny
            if infectedcells(i,j)==1 && finalpatch(i,j)==1
                both_infect(trial)=both_infect(trial)+1;
            elseif infectedcells(i,j)==0 && finalpatch(i,j)==0
                both_healthy(trial)=both_healthy(trial)+1;
            elseif infectedcells(i,j)==1 && finalpatch(i,j)==0
                false_positive(trial)=false_positive(trial)+1;
            elseif infectedcells(i,j)==0 && finalpatch(i,j)==1
                false_negative(trial)=false_negative(trial)+1;
            end
        end
    end
    
    actual_growth=sum(sum(finalpatch-initialpatch));
    initial_infection=sum(sum(initialpatch));
    
    patch_area(trial)=sum(sum(infectedcells));
    
    correct_ratio(trial)=(both_infect(trial)-initial_infection)/false_positive(trial);
    percent_growth_predicted(trial)=(both_infect(trial)-initial_infection)/actual_growth;
    
    
    %image analysis of patch
    
    model_image=mat2gray(infectedcells);
    patch_image=regionprops(model_image, 'Orientation', 'Eccentricity', 'MajorAxisLength', 'MinorAxisLength');
    orientation(trial)=patch_image.Orientation;
    eccentricity(trial)=patch_image.Eccentricity;
    majaxis(trial)=patch_image.MajorAxisLength;
    minaxis(trial)=patch_image.MinorAxisLength;

    %% Save Results


    filename=sprintf('Patch %d Output', patchnum);

    save(filename, 'infectedcells', 'Xmax');
    
    filename2=sprintf('Patch %d Errors', patchnum);
    
    save(filename2, 'both_infect', 'both_healthy', 'false_positive', 'false_negative', 'correct_ratio', 'percent_growth_predicted', 'eccentricity', 'orientation', 'majaxis', 'minaxis');
    
        

end