
function [x,y,z,t] = trackMotion3D(fn, analysischan) 

%% test function computeshifts
% requires z:\libraries\matlab in path
run(getLocalPath('/lab/libraries/hdf5matlab/setPath.m')) ;

downsampleFactor = 1 ; % skip frames if > 1
numFramesToAverageForRef = 10 ; % frames to average to determine the reference frame against which motion is computed
useMultiCore = true ;
postRefStartFrameTime = 0 ; % N secs to skip before analyzing motion signals, in many cases, right after starting the point scan, there is a slight drift

br = aodReader(fn, 'Motion') ;
br1 = AodMotionCorrectionReader(fn) ; % if motion was corrected by using aod offsets, this is where they would be read

dat = br(:,:,:) ;
numSamples = br1.sz ;
duration = numSamples(:,1)/br1.Fs ; % sec

motion_fs = size(dat,1)/duration ; % this is based on the temporal sampling rate
delta_t = downsampleFactor/motion_fs ;

numPlanes = br.planes ;
coordinates = br.motionCoordinates ;

% get pmt chan data
dat2 = squeeze(dat(:,:,analysischan)) ;
clearvars dat ;
gridSize = sqrt(size(dat2,2)/numPlanes) ;

% frame number to start from
postRefStartFrame = max(round(postRefStartFrameTime*motion_fs),1) ;

% chop off the first N secs
dat2 = dat2(postRefStartFrame:end, :) ;

needReference = true ; % first get a reference frame
refparams = [] ;
calibparams = [0 1; 0 1; 0 1] ; % dont apply any calibration
shifts = zeros(size(dat2,1),3); % store motion vectors here
dat2(1,:) = mean(dat2(1:numFramesToAverageForRef,:)) ; % average frames for computing reference
[shifts(1,:), refparams] = computeshifts(dat2(1,:)',coordinates,gridSize,calibparams,refparams,needReference) ; % this position of the fitted sphere is treated as the reference

% setup for parallel processing
if (useMultiCore)
    try
        mypool = parpool ; % use max processors
    catch
        fprintf('Unable to start parallel pool, single processor will be used') ;
        useMultiCore = false ;
    end
end 

% take into account frames to skip, i.e. sampling rate of motion,
% downsample with averaging
adat = zeros(size(dat2)) ;
if (downsampleFactor>1)
    count = 0 ;
    for ii=numFramesToAverageForRef+downsampleFactor:downsampleFactor:size(dat2,1)
        count = count + 1 ;
        adat(count,:) = adat(count,:) + sum(dat2(ii-downsampleFactor+1:ii,:)) ;
        adat(count,:) = adat(count,:) / downsampleFactor ;
    end
else
    adat = dat2(numFramesToAverageForRef+1:end,:) ;
    count = size(adat,1);
end

needReference=false ; % no need for a reference, start computing positions relative to the reference of spheres in subsequent motion frames
if (useMultiCore)
    parfor ii=1:count
        shifts(ii+numFramesToAverageForRef,:) = computeshifts(adat(ii,:)',coordinates,gridSize,calibparams,refparams,needReference) ;  
    end 
    delete(mypool) ;
else
    for ii=1:count
        shifts(ii+numFramesToAverageForRef,:) = computeshifts(adat(ii,:)',coordinates,gridSize,calibparams,refparams,needReference) ; 
        if (rem(count,100)==0)
            fprintf('Processed %d frames', count) ;
        end 
    end 
end 
x = squeeze(shifts(numFramesToAverageForRef+1:end,2)) ;
y = squeeze(shifts(numFramesToAverageForRef+1:end,1)) ;
z = squeeze(shifts(numFramesToAverageForRef+1:end,3)) ;
t=((0:1:length(x)-1)*delta_t)+(numFramesToAverageForRef/motion_fs) ; % the first motion position is after the last frame used for reference calculations