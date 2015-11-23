function intensevals= RunSatCrossTime(event)
%%
% compares points from satazel for points satellite crosses in DMCdata
% examples:
% RunSatCrossTime('11Apr2013_irid91')
% RunSatCrossTime('1Mar2014_irid30')

makeplots = {'pix'}; %'lla','azel'
addpath('../histutils/Matlab')

%% Parameters 
rowcol=[512,512];

switch event
    case '14Apr2013T0824'
        dpath = '~/data/2013-04-14/2013-04-14T07-00-CamSer7196_frames';
        fps = 50;
        camstart = 
    case '11Apr2013T1045'
        dpath = '~/data/2013-04-11/2013-04-11T07-00-CamSer1387_frames_403709-1-405509.DMCdata';
        fps = 30; % camera 1387 for 11 Apr 2013
        camstart = [2013 04 11 7 0 11];
        satappear = [2013 04 11 10 45 12]; %from STK
        % iridium 91, 11 March 2013
        % tle in satcam-data/sat_27372_test.txt
        usecam = 1;
        calfn = '../histfeas/precompute/hst1cal.h5'; 
        TLEfn = '../satcam-data/stkAllComm_2013-04-10.tle';
        satnum=27372;
        trange = [-5 18]; %let's look from 5 seconds before satAppear to 20 seconds after satAppear.
    case '31Mar2014_irid30'
        dpath = '/media/aurora1/HST2014image/2014-03-31/2014-03-31T06-12-CamSer7196.DMCdata';
        fps = 53; %from .xml file for 31 mar 2014 ultra
        camstart = [2014 3 31 6 12 23]; %from .nmea file
        satappear = [2014 3 31 12 29 4]; %from STK Access calcuation
        % iridium 30, 31 march 2014, TLE from STK .sa file
%        tle in sat_24949_test.txt
        usecam = 0;
        calfn = '2014-03-31T06-12-CamSer7196_cal.mat';
    otherwise, error('i don''t have this case defined')
end
%% camera locations

switch usecam
    case 0
        camlla = [65.1186367, -147.432975, 500]; % HST0, this is new Ultra serial number 7196 at Davis Science Operation Center
        camname = 'HST0';
    case 1
        camlla = [65.12657, -147.496908333, 208]; %HST1, this is old Ixon serial number 1387 at MF radar site
        camname='HST1';
end %switch usecam  
%% load satellite TLE
% get tle (can also just cut and paste)
tle = gettle(TLEfn,satnum);
 dtsec = 0.5; %time step in seconds
%% adjust start playback time to satellite
try
    satappear = datetime(satappear);
    camstart = datetime(camstart);
    tstart = satappear + seconds(trange(1));
    tend   = satappear + seconds(trange(2));
catch
    tstart = datenum([satappear(1:5) satappear(6)+trange(1)]);
    tend   = datenum([satappear(1:5) satappear(6)+trange(2)]);  
    satappear = datenum(satappear);
    camstart = datenum(camstart);
end
%% load satellite data
[sataer, satlla, satpix] = satazel(camlla,camname,tle,tstart,tend,dtsec,calfn,makeplots);
%sanity check
if isempty(satpix)
    error('I can''t proceed since the satellite is not detected in the FOV. Is the az/el calibration correct for this date?')
end
%%
intensevals = pixelcrossing(dpath,satpix,satappear,camstart,fps,tstart,trange,rowcol);
%%
if ~nargout,clear,end
end %function
