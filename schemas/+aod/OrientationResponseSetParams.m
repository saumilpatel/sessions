%{
aod.OrientationResponseSetParams (manual) # Parameters for binning data by orientation
-> acq.AodStimulationLink
-> aod.TracePreprocessSet
-> aod.UniqueCells
-> stimulation.MultiDimInfo
bin_duration : double # The duration of the response to bin
lag          : double # How long after the stimulus to bin
-----
%}

classdef OrientationResponseSetParams < dj.Relvar

	properties(Constant)
		table = dj.Table('aod.OrientationResponseSetParams')
	end

	methods
		function self = OrientationResponseSetParams(varargin)
			self.restrict(varargin)
		end
    end
    
    methods (Static)
        function createDefaults
            defaultParams = struct('lag',0,'bin_duration',500);
            sets = fetch((aod.TracePreprocessSet('preprocess_method_num != 1') & aod.UniqueCells) * ...
                (acq.AodStimulationLink & stimulation.MultiDimInfo('num_orientations>=8 AND block_design=1')) - ...
                aod.OrientationResponseSetParams(defaultParams));
            for i = 1:length(sets)
                insert(aod.OrientationResponseSetParams, dj.struct.join(sets(i),defaultParams));
            end
        end
        
        function createDefaultsMultidim
            defaultParams = struct('lag',0,'bin_duration',100);
            sets = fetch((aod.TracePreprocessSet('preprocess_method_num != 1') & aod.UniqueCells) * ...
                (acq.AodStimulationLink & stimulation.MultiDimInfo('num_orientations>=8 AND block_design=0')) - ...
                aod.OrientationResponseSetParams(defaultParams));
            for i = 1:length(sets)
                insert(aod.OrientationResponseSetParams, dj.struct.join(sets(i),defaultParams));
            end
            
        end
        
    end
end
