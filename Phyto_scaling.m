function tj = Phyto_scaling(potential);

if potential > -90;    
    tj = (18/90 * potential)./7;
elseif potential <-90 && potential >=-180
    tj = (-18 - (-90-potential)./(-90+180)*(50-18))./7;
elseif potential < -180 && potential >=-1080;
    tj = (-50-(-180-potential)./(-180+1080)*(52-50))./7;
elseif potential < -1080 && potential >=-2080
    tj = (-52-(-1080-potential)./(-1080+2080)*(47-52))./7;
elseif potential < -2080 && potential >=-3030
    tj = (-47 -(-2080-potential)./(-2080+3030)*(24-47))./7; 
elseif potential < -3030 && potential >=-3790
    tj = (-24 - (-3030-potential)./(-3030+3790)*(-24))./7;
elseif potential < -3790;
    tj = 0/7;
end

tj = -tj/(52/7);