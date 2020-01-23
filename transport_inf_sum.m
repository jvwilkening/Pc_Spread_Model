function [inf_sum] = transport_inf_sum(dx, mean_uij, mean_uj, alpha)

elem_cutoff=.00001; %will continue to sum until next element is less than this cutoff
step_change=1;
inf_sum=0;
counter=0;

while step_change > elem_cutoff
    counter=counter+1;
    distance=counter*dx;
    step_change=exp(-alpha*distance/mean_uij)/mean_uj;
    inf_sum=step_change+inf_sum;
end
