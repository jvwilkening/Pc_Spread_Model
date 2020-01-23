function [X] = biomass_runoff_transport(X, runoff_depth, t_storm, nx, ny, alpha, E, T, A, dx, dy, eff_depth_prop, S, roughness)
total_pathogen_change=zeros(nx,ny);
q_storm=runoff_depth/t_storm;

%find cells with pathogen
donor_cells=zeros(nx,ny);
for i=1:nx
    for j=1:ny
        if X(i,j)>50 %pathogen present
            donor_cells(i,j)=1; %mark cell as donor
        end
    end
end

%calculate transport from each donor cell to downslope cells
for i=1:nx
    for j=1:ny
        if donor_cells(i,j)>0 %cell is a donor
            clear I
            deposition_factors=zeros(nx,ny); %stores grid to store deposition elements of downslope cells
            downslope_cells=0; %counter for number of downslope cells
            sum_u_j=0; %used to find mean u_j
            sum_u_ij=0; %used to find mean u_ij
            i_source=i;
            j_source=j;
            I=influence_map(E,T, i,j, 1); %finds fraction of flow that goes to downslope cells
            if S(i_source,j_source) == 0
                slope_source=.001;
            else
                slope_source=S(i_source,j_source);
            end
            Kr_source=sqrt(slope_source)/roughness; %kinematic resistance factor at source cell
            u_source=Kr_source*(q_storm*A(i_source,j_source)/(Kr_source*dy))^(2/5); %flow velocity at source cell
            mobilization=alpha*dx*q_storm*t_storm*A(i_source,j_source); %mobilization term at source cell
            
            for i=1:nx %loop to find all downslope cells of donor
                for j=1:ny
                    if I(i,j)>0 && i~=i_source && j~=j_source %finds downslope cells
                        downslope_cells=downslope_cells+1; %counter for downslope cells
                        source_distance=sqrt(((i_source-i)*dx)^2+((j_source-j)*dy)^2); %euclidean distance between i and j
                        if S(i,j) == 0
                            slope=.001;
                        else
                            slope=S(i,j);
                        end
                        Kr_j=sqrt(slope)/roughness; %kinematic resistance factor at downslope cell
                        u_j=Kr_j*(q_storm*A(i,j)/(Kr_j*dy))^(2/5); %flow velocity at downslope cell
                        u_ij=(u_j+u_source)/2; %mean velocity between i and j
                        deposition_factors(i,j)=exp(-alpha*source_distance/u_ij)*I(i,j)/u_j; %deposition factor at j
                        if isnan(deposition_factors(i,j))== 1
                               pause()
                        end
                        sum_u_j=sum_u_j+u_j; 
                        sum_u_ij=sum_u_ij+u_ij;
                    end
                end
            end
            
            %finds mean u_j and u_ij in domain
            mean_uij=sum_u_ij/downslope_cells; 
            mean_uj=sum_u_j/downslope_cells;
            
            inf_sum=transport_inf_sum(dx, mean_uij, mean_uj, alpha); %finds theoretical non-domain bound sum
            domain_sum=sum(sum(deposition_factors)); %sum of deposition factors in domain
            domain_frac=domain_sum/inf_sum; %fractiion of biomass captured in domain
            source_mass_loss=eff_depth_prop*X(i_source,j_source)*dx*dy; %mass mobilized by runoff at source cell
            C_io=source_mass_loss*domain_frac/(mobilization*domain_sum); %concentration of biomass in runoff at source cell
            
            pathogen_change_step=C_io*mobilization*deposition_factors/(dx*dy); %change in per area biomass density at downslope cells due to deposition from runoff
            
            %update overall pathogen density change plots
            total_pathogen_change=total_pathogen_change+pathogen_change_step; %biomass deposited to downslope cells
            total_pathogen_change(i_source, j_source)=total_pathogen_change(i_source, j_source)-(source_mass_loss/(dx*dy)); %biomass mobilized from source cell
           
        end
    end
end

                
%update biomass to return            
X=X+total_pathogen_change;