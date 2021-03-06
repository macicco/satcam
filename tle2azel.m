function [t,sataer,satlla] =tle2azel(tle,camlla,tstart,tend,camname,dtSec)
%% (0) load Charles Rino's SatOrbit
addpath('SGP4') % http://www.mathworks.com/matlabcentral/fileexchange/28888-satellite-orbit-computation
addpath('GPS_CoordinateXforms') %http://www.mathworks.com/matlabcentral/fileexchange/28813-gps-coordinate-transformations

min_per_day=60*24;
%% (1) run SGP4 for satellite
try
satrec = twoline2rvMOD(tle{1},tle{2});
catch excp, display('It looks like you need to install Charles Rino''s SatOrbit:')
    display('http://www.mathworks.com/matlabcentral/fileexchange/28888-satellite-orbit-computation')
    display('and Charles Rino''s GPS Coordinate Transforms:')
    display('www.mathworks.com/matlabcentral/fileexchange/28813-gps-coordinate-transformations')
    fclose('all');
    rethrow(excp)
end
fprintf('\n')
fprintf('Satellite ID %5i \n',satrec.satnum)
fprintf('Observer 1: %s Lat=%6.4f Lon %6.4f Alt=%3.1f m\n',...
            camname,camlla(1),camlla(2),camlla(3))

                
if (satrec.epochyr < 57)
    Eyear= satrec.epochyr + 2000;
else
    Eyear= satrec.epochyr + 1900;
end

%converts the day of the year, days, to the equivalent month, day, hour, minute and second.
[Emon,Eday,Ehr,Emin,Esec] = days2mdh(Eyear,satrec.epochdays);

try
    Epoch = datetime([Eyear,Emon,Eday,Ehr,Emin,Esec]); 
    tsince = (tstart-Epoch):seconds(dtSec):(tend-Epoch);
    tsinceMinutes = minutes(tsince);    
catch
    Epoch = datenum([Eyear,Emon,Eday,Ehr,Emin,Esec]); 
    tsince = (tstart-Epoch):dtSec/86400:(tend-Epoch);
    tsinceMinutes = tsince*min_per_day; %[minutes]
end
npts= length(tsince);
display(['Epoch time is: ',datestr(Epoch)])
xsat_ecf=zeros(3,npts);
%vsat_ecf=zeros(3,npts);
%% propagate
for n=1:npts
   [satrec, xsat_ecf(:,n)]=spg4_ecf(satrec,tsinceMinutes(n));
end

%Scale state vectors to mks units
xsat_ecf=xsat_ecf*1000;  %m
%vsat_ecf=vsat_ecf*1000;  %mps

sat_llh=ecf2llhT(xsat_ecf);            %ECF to geodetic (llh)  
%sat_tcs=llh2tcsT(sat_llh,origin_llh);  %llh to tcs at origin_llh
%sat_elev=atan2(sat_tcs(3,:),sqrt(sat_tcs(1,:).^2+sat_tcs(2,:).^2));
%% Identify visible segments: 
%notVIS=find(sat_tcs(3,:)<0);
%VIS=setdiff([1:npts],notVIS);
%sat_llh(:,notVIS)=NaN;
%sat_tcs(:,notVIS)=NaN;
%% (2) convert to azimuth/elevation from a site
t(:,1) = Epoch+tsince;

satlla(:,1) = rad2deg(sat_llh(2,:));
satlla(:,2) = rad2deg(sat_llh(1,:));
satlla(:,3) = sat_llh(3,:);

[sataer(:,1), sataer(:,2), sataer(:,3)] = ecef2aer(xsat_ecf(1,:),xsat_ecf(2,:),xsat_ecf(3,:),...
                                                    camlla(1),camlla(2),camlla(3),...
                                                    referenceEllipsoid('wgs84'),'degrees');
%sanity check
if all(sataer(:,2)<0)
    error('The satellite is always below the horizon, something seems amiss with your time, parameters, or calibration')
end

end %function