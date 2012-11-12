%{
aod.DesignMatrix (computed) # my newest table
-> acq.AodStimulationLink
-> aod.TracePreprocessSet
-> aod.DesignMatrixParams
-----
times            : longblob # The time stamps of the data points
stimuli_matrix   : longblob # The design matrix for the stimuli
traces_matrix    : longblob # The matrix of traces
cell_nums        : longblob # The ids of the cells
patched_data     : bool     # Whether this object includes spikes
patched_trace    : longblob # If the cell was patched, this contains that cell
spikes_binned    : longblob # The vector of spike times
patched_cell_num : int      # The cell number of the patched cell
%}

classdef DesignMatrix < dj.Relvar & dj.Automatic

	properties(Constant)
		table = dj.Table('aod.DesignMatrix')
		popRel = (acq.AodStimulationLink & ...
            acq.Stimulation('exp_type="MoviesExperiment" OR exp_type="MultDimExperiment" OR exp_type="MouseMultiDim"')) ...
            * (aod.TracePreprocessSet & aod.UniqueCell) *aod.DesignMatrixParams
	end

	methods
		function self = DesignMatrix(varargin)
			self.restrict(varargin)
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
            
            tuple = key;

            tuple.times = getTimes(aod.TracePreprocess & aod.UniqueCell & key);
            
            % Create a matrix of the traces
            [traces, tuple.cell_nums] = fetchn(aod.TracePreprocess & aod.UniqueCell & key, 'trace', 'cell_num');
            tuple.traces_matrix = cat(2,traces{:});
            % Normalize the energy
            tuple.traces_matrix = bsxfun(@rdivide, tuple.traces_matrix, ...
                std(tuple.traces_matrix,[],1));
            
            % Get the stimulus design matrix
            [tuple.stimuli_matrix startTime endTime] = ...
                network.GlmHelper.makeDesignMatrix(tuple.times, key);

            % Throw away any bins outside this stimulus
            delBins = (tuple.times < startTime) | (tuple.times > endTime);
            tuple.times(delBins) = [];
            tuple.traces_matrix(delBins,:) = [];
            
            if count(aod.Spikes & key) == 1
                spikes = fetch1(aod.Spikes & key, 'times');
                tuple.spikes_binned = histc(spikes, tuple.times);
                tuple.patched_cell_num = fetch1(aod.Spikes & key, 'cell_num');
                tuple.patched_data = true;
                
                % Move this trace from the main matrix to a separate one
                idx = find(tuple.cell_nums == tuple.patched_cell_num);
                tuple.patched_trace = tuple.traces_matrix(:,idx);
                tuple.traces_matrix(:,idx) = [];
                tuple.cell_nums(idx) = [];
            else
                tuple.spikes_binned = [];
                tuple.patched_trace = [];
                tuple.patched_cell_num = -1;
                tuple.patched_data = false;
            end

			self.insert(tuple);
		end
	end
end
