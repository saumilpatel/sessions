
function [x,y,z,t] = trackMotion3D(fn, analysischan) 

%% test function computeshifts
% requires z:\libraries\matlab in path
run(getLocalPath('/lab/libraries/hdf5matlab/setPath.m')) ;

analyzenthframe = 1 ; % skip frames if > 1
numframestoaverageforref = 10 ; % frames to average to determine the reference frame against which motion is computed
usemulticore = true ;
postrefstartframetime = 0 ; % N secs to skip before analyzing motion signals, in many cases, right after starting the point scan, there is a slight drift

br = aodReader(fn, 'Motion') ;
br1 = AodMotionCorrectionReader(fn) ; % if motion was corrected by using aod offsets, this is where they would be read

dat = br(:,:,:) ;
numsamples = br1.sz ;
duration = numsamples(:,1)/br1.Fs ; % sec

%numframes = size(dat,1) ;
%numchans = size(dat,3) ;
% motion_fs = br.Fs ;
motion_fs = size(dat,1)/duration ; % this is based on the temporal sampling rate
delta_t = analyzenthframe/motion_fs ;

numplanes = br.planes ;
coordinates = br.motionCoordinates ;

% get pmt chan data
dat2 = squeeze(dat(:,:,analysischan)) ;
clearvars dat ;
gridsize = sqrt(size(dat2,2)/numplanes) ;

% frame number to start from
postrefstartframe = max(round(postrefstartframetime*motion_fs),1) ;

% chop off the first N secs
dat2 = dat2(postrefstartframe:end, :) ;

needreference = true ; % first get a reference frame
refparams = [] ;
calibparams = [0 1; 0 1; 0 1] ; % dont apply any calibration
shifts = zeros(size(dat2,1),3); % store motion vectors here
dat2(1,:) = mean(dat2(1:numframestoaverageforref,:)) ; % average frames for computing reference
[shifts(1,:), refparams] = computeshifts(dat2(1,:)',coordinates,gridsize,calibparams,refparams,needreference) ; % this position of the fitted sphere is treated as the reference

% setup for parallel processing
if (usemulticore)
    try
        mypool = parpool ; % use max processors
    catch
        fprintf('Unable to start parallel pool, single processor will be used') ;
        usemulticore = false ;
    end
end 

% take into account frames to skip, i.e. sampling rate of motion,
% downsample with averaging
adat = zeros(size(dat2)) ;
if (analyzenthframe>1)
    count = 0 ;
    for ii=numframestoaverageforref+analyzenthframe:analyzenthframe:size(dat2,1)
        count = count + 1 ;
        for jj=ii-analyzenthframe+1:ii
            adat(count,:) = adat(count,:) + dat2(jj,:) ;
        end 
        adat(count,:) = adat(count,:) / analyzenthframe ;
    end
else
    adat = dat2(numframestoaverageforref+1:end,:) ;
    count = size(adat,1);
end

needreference=false ; % no need for a reference, start computing positions relative to the reference of spheres in subsequent motion frames
if (usemulticore)
    parfor ii=1:count
        [shifts(ii+numframestoaverageforref,:)] = computeshifts(adat(ii,:)',coordinates,gridsize,calibparams,refparams,needreference) ;  
    end 
    delete(mypool) ;
else
    for ii=1:count
        [shifts(ii+numframestoaverageforref,:)] = computeshifts(adat(ii,:)',coordinates,gridsize,calibparams,refparams,needreference) ; 
        if (rem(count,100)==0)
            fprintf('Processed %d frames', count) ;
        end 
    end 
end 
x = squeeze(shifts(numframestoaverageforref+1:end,2)) ;
y = squeeze(shifts(numframestoaverageforref+1:end,1)) ;
z = squeeze(shifts(numframestoaverageforref+1:end,3)) ;
t=((0:1:length(x)-1)*delta_t)+(numframestoaverageforref/motion_fs) ; % the first motion position is after the last frame used for reference calculations