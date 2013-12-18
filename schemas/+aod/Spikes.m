%{
aod.Spikes (imported) # my newest table
-> aod.PatchedCell
-----
num_spikes: int unsigned    # Number of spikes
times     : longblob        # The spike times
waveforms : longblob        # The spike waveforms
%}

classdef Spikes < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('aod.Spikes')
        
        popRel = aod.PatchedCell
    end
    
    methods
        function self = Spikes(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            tuple = key;
            
            br = getFile(acq.AodScan & key, 'Temporal');
            [tt fr] = aod.Spikes.detectSpikes(br);
            
            tuple.times = tt.t;
            tuple.waveforms = tt.w;
            tuple.num_spikes = length(tt.t);
            
            plot(fr(1:5:end,'t'),fr(1:5:end,2),tuple.times,zeros(size(tuple.times))-2e5,'.')
            abort = false
            keyboard
            if abort == false
                self.insert(tuple)
            end
        end
    end
       
    methods 
        function plot(self)
            assert(count(self) == 1, 'Only for one matching relvar');
            
            key = fetch(aod.Spikes & self);
            
            sp = fetch(self, '*');
            trace = fetch(aod.TracePreprocess(key) & aod.TracePreprocessMethod('preprocess_method_name="pc20"'), 'trace');
            times = getTimes(aod.TracePreprocess(key) & aod.TracePreprocessMethod('preprocess_method_name="pc20"'));
            
            mid = mean(times);
            plot((times - mid)/1000,(trace.trace - min(trace.trace)),(sp.times - mid)/1000,zeros(size(sp.times)), 'ok');
            
            xlim([0 60]);
        end

    end
    
    methods (Static)
        
        function [tt fr] = detectSpikes(br,varargin)
            params.channels = 2;
            params.width = .5;  % ms width
            params.length = 5; % ms
            params.preTime = 1; % ms
            params.postTime = 2; % ms
            params.estPartSize = 1e5;
            params.mainChunkSize = 1e7;
            params.nEstParts=20;
            params.refractory = 0.5;
            params.ctPoint = 2;  % IN MS
            params.windowSize = 2;  % IN MS
            params.ctPointAligned = 2; % IN MS
            params.windowSizeAligned = 2; % IN MS
            params.threshold = 10;
            params.inspect = 0;
            
            for i = 1:2:length(varargin)
                params.(varargin{i}) = varargin{i+1};
            end
            
            
            params.ctPoint = ceil(params.ctPoint / 1000 * getSamplingRate(br));
            params.ctPointAligned = ceil(params.ctPointAligned / 1000 * getSamplingRate(br));
            params.windowSize = ceil(params.windowSize / 1000 * getSamplingRate(br));
            params.windowSizeAligned = ceil(params.windowSizeAligned / 1000 * getSamplingRate(br));
            
            time = -params.length:1000/getSamplingRate(br):params.length;
            filt = exp(-time.^2/params.width^2);
            filt = filt / sum(filt.^2);
            filt = filt - mean(filt);
            
            wf = filterFactory.createBandpass(200,2200,16000,18000,getSamplingRate(br));
            fr = filteredReader(br,wf);
            
            params.istart = 1;
            params.iend = length(br) - 100000;
            % TO FIX: length(fr);
            
            samplesPerFrame = double(getSamplingRate(br));
            refractory = round(params.refractory / 1000 * getSamplingRate(br));
            
            % first get some randomly selected data to estimate parameter distribution
            fprintf('Estimating noise distribution ...\n')
            packRec = packetReader(fr, [1, 2], 'stride', [params.estPartSize, 1]);
            
            % approximate #samples using file size
            chunkStart = ceil(params.istart / params.estPartSize);
            chunkEnd   = ceil(params.iend  / params.estPartSize);
            chunks = chunkStart:chunkEnd;
            
            % randomly select some chunks of data
            r = randperm(min(params.nEstParts, length(chunks)));
            r = randperm(length(chunks));
            r = r(1:min(length(chunks),params.nEstParts));
            chunks = chunks(r);
            
            coeffs = packRec(chunks, params.channels);
            noiseSigmas = aod.Spikes.detect_estNoiseSigma(coeffs);
            
            if skewness(coeffs) > 0
                sign = 1;
            else
                sign = -1;
            end
            clear coeffs
            
            packRec = packetReader(fr, [1, 2], 'stride', [params.mainChunkSize, 1]);
            chunkStart = ceil(params.istart / params.mainChunkSize);
            chunkEnd   = ceil(params.iend  / params.mainChunkSize);
            chunks = chunkStart:chunkEnd;
            
            fprintf('Threshold: %f\n', noiseSigmas * params.threshold);
            
            tt.t = [];
            tt.w{1} = [];
            tt.h = [];
            tt.tstart = [];
            tt.tend = [];
            tt.aligned = 0;
            spikeShifts = [];
            for chunk=chunkStart:chunkEnd
                % read and filter data
                cont.wave = cell(1, 1);
                cont.wave{1} = sign * packRec(chunk,params.channels);
                cont.t = fr(packRec(chunk).indices,'t');
                
                raw.wave{1} = cont.wave{1};
                raw.t = cont.t;
                
                % detect spikes
                
                [spikeTimes] = aod.Spikes.detect_triggerAmplitude(cont, params.threshold, noiseSigmas, 'refractory', refractory);
                %extract spikes
                if isempty(spikeTimes)
                    fprintf('%g%s\n', 100 * (chunk-chunkStart+1) / (chunkEnd-chunkStart+1), '%');
                    continue
                end
                ttTemp = aod.Spikes.detect_extractSpikes(cont, spikeTimes, [], ...
                    'ctPoint', params.ctPoint, 'windowSize', params.windowSize);
                shifts = aod.Spikes.clus_align_COM(ttTemp, 10, 'ctPoint', params.ctPoint);
                %    clear ttTemp
                
                % Ignore shifts that go beyond the actual extracted frame.
                validShifts = (shifts > (-params.ctPoint)) & (shifts < (params.windowSize-params.ctPoint));
                spikeTimes = spikeTimes(validShifts) + shifts(validShifts);
                spikeTimes = spikeTimes( (spikeTimes >= params.ctPointAligned) & (spikeTimes <= (length(cont.wave{1}) - params.windowSizeAligned + params.ctPointAligned)) );
                
                % Implement refractoriness of trigger
                timeDiffs = diff(spikeTimes);
                smallDiffs = find(timeDiffs < refractory);
                while ~isempty(smallDiffs)
                    cleanIndexSet = setdiff(1:length(spikeTimes), 1+smallDiffs);
                    spikeTimes = spikeTimes(cleanIndexSet);
                    shifts = shifts(cleanIndexSet);
                    ttTemp.w{1} = ttTemp.w{1}(:,cleanIndexSet);
                    timeDiffs = diff(spikeTimes);
                    smallDiffs = find(timeDiffs < refractory);
                end
                clear timeDiffs
                
                % Now extract these spikes realigned
                tt = aod.Spikes.detect_extractSpikes(raw, ceil(spikeTimes), tt, ...
                    'ctPoint', params.ctPointAligned+1, 'windowSize', params.windowSizeAligned+2);
                spikeShifts = [spikeShifts; spikeTimes(:) - ceil(spikeTimes(:))];
                
                fprintf('%g%s\n', 100 * (chunk-chunkStart+1) / (chunkEnd-chunkStart+1), '%');
                
                if params.inspect
                    plot(br(packRec(chunk).indices,'t'), br(packRec(chunk).indices,1)+1500, raw.t,raw.wave{1}-1500,raw.t(ceil(spikeTimes)),zeros(size(spikeTimes)),'k.','MarkerSize',10);
                    
                    ylim([-2000 2000]);
                    pause
                end
            end
            tt = aod.Spikes.clus_resample_spikes(tt, spikeShifts, 'sampleLocs', 2:params.windowSizeAligned+1);
            tt.t = tt.t' + spikeShifts * 1e3 / getSamplingRate(br);
            
            tt.tstart = [];
            tt.tend = [];
            
            fprintf('\n')
        end
        
        function [sigma] = detect_estNoiseSigma(X)
            %Estimates the standard deviation of the noise in a recording by fitting a
            %Gaussian on the part of the distribution close to mean
            %
            %Usage: sigma = detect_estNoiseSigma(X)
            %       where X is a vector
            histBins = 100;
            
            %Enforce zero mean
            X = X - mean(X);
            maxAbs = max(abs(X));
            binWidth = 2 * maxAbs / (histBins - 1);
            c = linspace(-maxAbs, maxAbs, 100);
            h = hist(X, c);
            h = h / sum(h);                     %normalize => density function
            
            
            %standard normal distribution as an inline function
            f=inline('1/sqrt(2*pi)/sigma*exp(-x.^2/sigma^2/2)','sigma','x');
            options = optimset('MaxFunEvals', 10^25, 'TolFun',1e-20, ...
                'Display', 'off');
            [sigma, resnorm, residual, exitflag] = lsqcurvefit(f,std(X),c(45:55), ...
                h(45:55)/binWidth,[],[],options);
            
        end
        
        function [spikeTimes, evtChannel] = detect_triggerAmplitude(cont, threshold, noiseSigmas, varargin)
            
            nbChans = length(cont.wave);
            spikePositions = cell(1, nbChans);
            for ch=1:nbChans
                if (nargin > 2)
                    coeffSigma = noiseSigmas(ch);
                else
                    coeffSigma = detect_estNoiseSigma(cont.wave{ch});
                end
                
                sigmaThreshold = coeffSigma * threshold;
                summedThresholds = cont.wave{ch} > sigmaThreshold;	% only trigger on positive flank for now
                
                % Take the intersection of local maxima and super-threshold data points
                wwiDiff = diff(cont.wave{ch});
                wwiDiff = sign(wwiDiff);                  % binary slope
                maxiPos = diff(wwiDiff(2:end)) == -2 | (wwiDiff(1:end-2) == 1 & wwiDiff(2:end-1) == 0 & wwiDiff(3:end) == -1);                      % find possible local maxima
                
                % maxiPos = maxiPos & summedThresholds(3:end);
                spikePositions{ch} = intersect( find(maxiPos)'+1, find(summedThresholds)' );		% +1 compensates for the diffs
            end
            
            
            %Now merge spikeTimes on the four channels
            spikeTimes = unique([spikePositions{:}]);
            
            %Mark channel where the spike 'originated'
            if nargout > 1
                evtChannel = zeros(1, length(spikeTimes));
                for ch = 1:nbChans
                    [foo, ia] = intersect(spikeTimes, spikePositions{ch});
                    evtChannel(ia) = ch;
                end
            end
        end
        
        function [shifts] = clus_align_COM(tt,N,varargin)
            % Aligns spikes to their peak to reduce sampling jitter.
            % The method has been derived from the 'center of mass' approach
            % outlined in
            %   [Sahani: 'Latent Variable Models for Neural Data Analysis', 1999]
            % It will also remove spikes where the peak is too far from
            % the designated alginment point
            %
            % Syntax: [ttAligned, map] = clus_align_spikes(tt,N,...);
            % Parameters:            tt - the tt structure which contains the waveforms
            %                         N - spike waveforms will be interpolated N-fold
            %                             by cubic spline interpolation before resampling
            %
            % Optional:     'ctPoint',c - the peak of the spikes will be expected at
            %                             sample c
            %
            % Default settings: N=10, ctPoint=8, tolWindow=2
            %
            % Return values: ttAligned - contains the realigned waveforms
            %                      map - vector of indices s.t. the i'th spike in
            %                            tt has been mapped to the map(i)'th spike
            %                            in ttAligned. Discarded spikes are marked
            %                            by the value -1
            % AH 2006-02-05
            
            % default setting
            params.ctPoint = 11;     % by default all maximums should be aligned to the 8th sample point
            
            if nargin < 2
                N = 10;             % default to 10-fold cubic spline interpolation
            end
            packetSize = 15000;     % work in packets of 15000 spikes to reduce memory consumption
            
            % read parameters from the command line
            for i=1:2:length(varargin)
                params.(varargin{i}) = varargin{i+1};
            end
            
            ctPointInterpol = (params.ctPoint-1) * N;       % center point in interpol. coordinates
            [nbSamples nbSpikes] = size(tt.w{1});           % number of samples and spikes
            nbChans = length(tt.w);                         % number of channels
            
            %Precreate output arrays to avoid memory thrashing
            shifts = zeros(1, nbSpikes);
            
            % Iterate over all packages
            for packet = 1:1:ceil(size(tt.w{1},2) / packetSize)
                packetBegin = (packet-1) * packetSize + 1;
                packetEnd = min(packet*packetSize, nbSpikes);
                packetSize = packetEnd-packetBegin+1;
                CMnom = zeros(1, packetSize);        % nominator for the center of mass calculation
                CMdenom = zeros(1, packetSize);      % denominator for the center of mass calculation
                % Interpolate on all channels to determine the center of mass
                for ch=1:nbChans
                    % Interpolate N-fold with a cubic spline
                    wwi = interp1(1:nbSamples,tt.w{ch}(:,packetBegin:packetEnd),1:1/N:nbSamples,'spline');
                    if (packetSize == 1)
                        wwi = wwi';             % Inconsistent Matlab behaviour
                    end
                    % Find maximum closest to the designated center sample
                    wwiDiff = diff(wwi, 1, 1);
                    wwiDiff = wwiDiff ./ abs(wwiDiff);                  % binary slope
                    maxiPos = diff(wwiDiff) == -2;                      % find possible local maxima
                    % Now weigh this to find the maximum closest to the designated
                    % center sample
                    weightMat = size(maxiPos,1) - abs((1:size(maxiPos,1)) - ctPointInterpol + 2);
                    %weightedMaxima = maxiPos .* repmat(weightMat', 1, size(wwi,2));
                    weightedMaxima = bsxfun(@times, maxiPos, weightMat');
                    [foo maxChPos] = max(weightedMaxima, [], 1);
                    maxChPos = maxChPos + 2;                            % compensate for the two diff calls
                    maxChPos(maxChPos > size(wwi,1)) = size(wwi,1);     % avoid overflows
                    maxCh = wwi( sub2ind(size(wwi), maxChPos, 1:size(wwi,2)) );
                    % now maxChPos contains the positions of the local maxima closest
                    % to the designated center sample
                    % maxCh contains the values at these local maxima
                    
                    % Now we select a contiguous region of the spike, the whole of
                    % which lies above half of the maxCh value.
                    %aboveThresh = wwi >= repmat(0.5 * maxCh, size(wwi,1), 1);
                    aboveThresh = bsxfun(@ge, wwi, 0.5 * maxCh);
                    threshDiff = diff(aboveThresh, 1, 1);   % sample points which lie above the half of the max
                    % Only take those above threshold samples which build a contiguous
                    % block with the maximum (not so easy in Matlab in a vectorized
                    % form)
                    [posDerivR posDerivC] = find( threshDiff == 1 );
                    if (packetSize > 1)
                        selector = posDerivR >= maxChPos(posDerivC)';
                    else
                        selector = posDerivR >= maxChPos(posDerivC);
                    end
                    eraseIndices = sub2ind(size(threshDiff), posDerivR(selector), posDerivC(selector));
                    
                    [negDerivR negDerivC] = find( threshDiff == -1 );
                    if (packetSize > 1)
                        selector = negDerivR < maxChPos(negDerivC)';
                    else
                        selector = negDerivR < maxChPos(negDerivC);
                    end
                    eraseIndices = union(eraseIndices, sub2ind(size(threshDiff), negDerivR(selector), negDerivC(selector)));
                    
                    % Erase entries in the derivated matrix
                    threshDiff(eraseIndices) = 0;
                    rec = [zeros(1, size(threshDiff,2)); cumsum(threshDiff,1)];
                    %rec = rec - repmat( rec( sub2ind(size(rec), maxChPos, 1:size(rec,2))), size(rec,1), 1) + 1;
                    rec = bsxfun(@minus, rec + 1,  rec( sub2ind(size(rec), maxChPos, 1:size(rec,2))));
                    rec( rec < 0) = 0;
                    rec = logical(rec);
                    wwi(~rec) = 0;
                    % Update the nominator and denominator variables for the center of
                    % mass calculation
                    CMnom = CMnom + sum( bsxfun(@times, (1:1/N:nbSamples)', wwi), 1);
                    CMdenom = CMdenom + sum(wwi,1);
                end
                % Calculate center of mass
                CMass = CMnom ./ CMdenom;
                shifts(packetBegin:packetEnd) = CMass - params.ctPoint;
                fprintf('%7d spikes done\n',packetEnd);
            end
        end
        
        function [ttAligned] = clus_resample_spikes(tt, shift, varargin)
            % Aligns spikes to their peak to reduce sampling jitter.
            % The method has been derived from the 'center of mass' approach
            % outlined in
            %   [Sahani: 'Latent Variable Models for Neural Data Analysis', 1999]
            % It will also remove spikes where the peak is too far from
            % the designated alginment point
            %
            % Syntax: [ttAligned, map] = clus_align_spikes(tt,N,...);
            % Parameters:            tt - the tt structure which contains the waveforms
            %                         N - spike waveforms will be interpolated N-fold
            %                             by cubic spline interpolation before resampling
            %
            % Optional:     'ctPoint',c - the peak of the spikes will be expected at
            %                             sample c
            %             'tolWindow',t - all spikes where the estimated peak positions
            %                             deviates by more than t samples from the
            %                             point specified by the 'ctPoint' option will
            %                             be discarded
            %
            % Default settings: N=10, ctPoint=8, tolWindow=2
            %
            % Return values: ttAligned - contains the realigned waveforms
            %                      map - vector of indices s.t. the i'th spike in
            %                            tt has been mapped to the map(i)'th spike
            %                            in ttAligned. Discarded spikes are marked
            %                            by the value -1
            % AH 2006-02-05
            
            % default setting
            params.sampleLocs = 2:29; % number of points to extract
            packetSize = 15000;     % work in packets of 15000 spikes to reduce memory consumption
            
            % read parameters from the command line
            for i=1:2:length(varargin)
                params.(varargin{i}) = varargin{i+1};
            end
            
            [nbSamples nbSpikes] = size(tt.w{1});           % number of samples and spikes
            nbChans = length(tt.w);                         % number of channels
            
            %Precreate output arrays to avoid memory thrashing
            ttAligned.t = tt.t;
            ttAligned.h = tt.h;
            
            for i=1:nbChans
                ttAligned.w{i} = zeros(length(params.sampleLocs), nbSpikes);
            end
            
            % Init some variables
            lastPacketEnd = 0;
            sampleLocs = bsxfun(@plus, params.sampleLocs(:)', shift(:));
            
            % Iterate over all packages
            for packet = 1:1:ceil(size(tt.w{1},2) / packetSize)
                packetBegin = (packet-1) * packetSize + 1;
                packetEnd = min(packet*packetSize, nbSpikes);
                
                % align waveforms on each channel and store in the output
                % variables
                for ch=1:nbChans
                    ttAligned.w{ch}(:,packetBegin:packetEnd) = aod.Spikes.clus_interp_custom(1:nbSamples, tt.w{ch}(:,packetBegin:packetEnd), sampleLocs(packetBegin:packetEnd,:));
                end
                fprintf('%7d spikes done\n',packetEnd);
            end
            ttAligned.aligned = 1;
        end
        
        function [ret extrIdx] = detect_extractSpikes(cont, spikeTimes, tt, varargin)
            params.ctPoint = 8;	% Sample on which to center the waveform peak
            params.windowSize = 32;	% Number of samples to extract per spike
            
            for i=1:2:length(varargin)
                params.(varargin{i}) = varargin{i+1};
            end
            
            nbChannels = length(cont.wave);
            extrIdx = (spikeTimes >= params.ctPoint) & (spikeTimes <= (length(cont.wave{1}) - params.windowSize + params.ctPoint));
            spikeTimes = spikeTimes(extrIdx);
            res.w = cell(1, nbChannels);
            res.h = zeros(length(spikeTimes), nbChannels);
            res.t = zeros(1, length(spikeTimes));
            
            waveIndexer = repmat( (1:params.windowSize)', 1, length(spikeTimes) );
            waveIndexer = bsxfun(@plus, waveIndexer, spikeTimes(:)'- params.ctPoint);
            for ch=1:nbChannels
                res.w{ch} = cont.wave{ch}(waveIndexer);
                res.h(:,ch) = reshape(max(res.w{ch}, [], 1) - min(res.w{ch}, [], 1), [], 1);
            end
            res.t = reshape( cont.t(spikeTimes), 1, [] );
            
            % Make sure that all time indices are ascending
            [res.t sortIdx] = sort(res.t);
            for ch=1:nbChannels
                res.w{ch} = res.w{ch}(:, sortIdx);
            end
            res.h = res.h(sortIdx, :);
            
            if (nargin < 4) || isempty(tt)
                ret = res;
                clear ret.w
            else
                for ch=1:nbChannels
                    ret.w{ch} = horzcat(tt.w{ch}, res.w{ch});
                end
                ret.h = vertcat(tt.h, res.h);
                ret.t = horzcat(tt.t, res.t);
            end
        end
        
        function [v] = clus_interp_custom(X,Y, XX)
            % interpolate each row of Y, with original coordinates stored in X, by cubic spline
            % interplation and evaluate at the positions stored in XX
            % For each row you have to specify the positions where to sample from the
            % interpolant.
            % Why is this function necessary? Matlab's functions will evaluate all
            % interpolated curves at the same abscisses. But we want to align every
            % spike to its very own peak.
            % X   -   vector with the D abscisses where the values in Y were original
            %         sampled at
            % Y   -   D x n matrix
            % XX  -   n x m matrix with the positions where you want to sample
            %         from the interpolant
            %
            % AH 02-06-2006
            % refer to Matlab's ppval function, which is a bit easier to understand
            
            pp = spline(X,Y');               % Calculate piecewise polynomial
            [b,c,l,k,dd]=unmkpp(pp);         % Extract pp information
            
            nRows = size(XX,1);
            % for each data point, compute its breakpoint interval
            [ignored,index] = sort([repmat(b(1:l),nRows,1) XX], 2);
            clear ignored
            helperArr = repmat( 1:(l+size(XX,2)), nRows, 1)';
            %index = reshape(helperArr(index' > l), [], nRows)' - repmat(1:size(XX,2), nRows, 1);
            index = bsxfun(@minus, reshape(helperArr(index' > l), [], nRows)', repmat(1:size(XX,2), nRows, 1));
            index(index<1) = 1;
            
            % now go to local coordinates ...
            XX = reshape(XX, 1, []) - b( reshape(index, 1,[]));
            %index = (index - 1) * nRows + repmat((1:nRows)', 1, size(index,2));
            index = bsxfun(@plus, (index - 1) * nRows, (1:nRows)');
            index = index(:);
            
            % ... and apply nested multiplication:
            v = c(index,1);
            for i=2:k
                v = XX(:).*v + c(index,i);
            end
            v = reshape(v,nRows,[])';
        end
        
    end
end
