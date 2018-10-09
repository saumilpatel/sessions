
function [x,y,z,t] = trackMotion3D(fn, analysischan) 

%% test function computeshifts
% requires z:\libraries\matlab in path
%run(getLocalPath('/lab/libraries/hdf5matlab/setPath.m')) ;

downsampleFactor = 1 ; % skip frames if > 1
numFramesToAverageForRef = 10 ; % frames to average to determine the reference frame against which motion is computed
useMultiCore = true ;
postRefStartFrameTime = 0 ; % N secs to skip before analyzing motion signals, in many cases, right after starting the point scan, there is a slight drift

fn2 = findFile(RawPathMap, fn)
br = aodReader(fn2, 'Motion');
br1 = AodMotionCorrectionReader(fn2) ; % if motion was corrected by using aod offsets, this is where they would be read

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

end

% compute position shifts of a 3d object present in the sampled set of
% planes.
% data consists of a single "motion frame"
% data and refdata have to be same size
% variable argument parameters: initial_spaceconstant (def=5)
function [shifts, outrefparams] = computeshifts(data, motcoordinates, gridsize, calibparams, refparams, needsref, varargin)

%% preprocessing
% [d1,d2] = size(data) ;
% data = reshape(data,gridsize,gridsize,gridsize) ;
% for ii=1:gridsize
%     td = data(:,:,ii) ;
%     data(:,:,ii) = (td - mean(td(:)))/std(td(:)) ;
% end ;
% data = reshape(data,d1,d2) ;
% data = (data - min(data(:)))/(max(data(:))-min(data(:))) ;
% th = 0.25 ; % arbitrary selection by trial and error
% data = data.*(data>th) ;

%%
params.initial_spaceconstant = 5 ;
params = parseVarArgs(params, varargin{:}, 'strict');

shifts = nan(1,3) ;
outrefparams = nan(1,8) ;

% functions to fit 3-d gaussian, non-oriented - need to later include
% orientation
gref = @(x,cx,cy,cz) x(1)+(x(2)*exp(-(((cx-x(3)).^2/(2*x(4)^2))...
                                +((cy-x(5)).^2/(2*x(6)^2))+((cz-x(7)).^2/(2*x(8)^2))))) ;
gdat = @(x,cx,cy,cz,sigmax,sigmay,sigmaz) x(1)+(x(2)*exp(-(((cx-x(3)).^2/(2*sigmax^2))...
                                +((cy-x(4)).^2/(2*sigmay^2))+((cz-x(5)).^2/(2*sigmaz^2))))) ;
fref = @(x,cx,cy,cz,y) sum((y - gref(x,cx,cy,cz)).^2) ;
fdat = @(x,cx,cy,cz,sigmax,sigmay,sigmaz,y) sum((y - gdat(x,cx,cy,cz,sigmax,sigmay,sigmaz)).^2) ;
options = optimset('MaxFunEvals', 1000000, 'MaxIter', 100000) ;

% range of motion coordinates
x_min = min(motcoordinates(:,1)) ;
y_min = min(motcoordinates(:,2)) ;
z_min = min(motcoordinates(:,3)) ;
x_max = max(motcoordinates(:,1)) ;
y_max = max(motcoordinates(:,2)) ;
z_max = max(motcoordinates(:,3)) ;

% interpolation grid to regularize the motion sampling
xg = linspace(x_min,x_max,gridsize) ;
yg = linspace(y_min,y_max,gridsize) ;
zg = linspace(z_min,z_max,gridsize) ;
[yg, xg, zg] = meshgrid(xg,yg,zg) ;
xg = reshape(xg, [], 1) ;
yg = reshape(yg, [], 1) ;
zg = reshape(zg, [], 1) ;

cx=xg ;
cy=yg ;
cz=zg;

% first motion "frame" is the reference frame, get params of reference
% frame
spaceconstant = params.initial_spaceconstant ; % initial space constant 5 for cells, 10 for small pollens
if(needsref)
    y = data ;
    try
        refparams = fminsearch(@(x) fref(x,cx,cy,cz,y),[min(y(:)) max(y(:))-min(y(:)) (max(xg)+min(xg))/2 spaceconstant (max(yg)+min(yg))/2 spaceconstant (max(zg)+min(zg))/2 spaceconstant]',options) ; 
    catch
        return ;
    end ;
end ;

% compute shifts in current motion frame relative to reference
sigmax = refparams(4) ; % assume that the space constants of the gaussian during simulated motion remains same as the space constants for reference
sigmay = refparams(6) ;
sigmaz = refparams(8) ;
y = data ;
try
    X = fminsearch(@(x) fdat(x,cx,cy,cz,sigmax,sigmay,sigmaz,y),[min(y(:)) max(y(:))-min(y(:)) refparams(3) refparams(5) refparams(7)]') ;
    shifts(1) = (X(3) - refparams(3)) ;
    shifts(2) = (X(4) - refparams(5)) ;
    shifts(3) = (X(5) - refparams(7)) ;
catch
    return ;
end ;

% apply calibration
for ii=1:3
    shifts(ii) = calibparams(ii,1)+(calibparams(ii,2)*shifts(ii)) ;
end ;
outrefparams = refparams ;

end