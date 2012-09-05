%{
aod.OrientationResponseSet (computed) # Population orientation responses by trial
-> aod.OrientationResponseSetParams
-----
cell_nums   : longblob # Store the order of the cell nums used (unique cells)
orientation : longblob # The orientation of each row
responses   : longblob # The trial responses (rows) for the cells (columns)
%}

classdef OrientationResponseSet < dj.Relvar & dj.Automatic
    
    properties(Constant)
        table = dj.Table('aod.OrientationResponseSet')
        popRel = aod.OrientationResponseSetParams  % !!! update the populate relation
    end
    
    methods
        function self = OrientationResponseSet(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            tuple = key;
            
            disp 'Sorting data';
            [trial_data tuple.cell_nums] = aod.OrientationResponseSet.tracesByOri(key, key.lag, key.bin_duration);
            
            tuple.responses = zeros(1:length(trial_data),count(aod.UniqueCell & key));
            for i = 1:length(trial_data)
                tuple.responses(i,:) = mean(trial_data(i).traces,1)
            end
            tuple.orientation = cat(1,trial_data.ori);
            self.insert(tuple)
        end
    end
    
    methods (Static)
        function [trial_data cell_num] = tracesByOri(key, lag, duration)
            % This method needs an array of stimulus condition numbers and
            % onset/offset times
            
            [traces cell_num] = fetchn(aod.TracePreprocess & aod.UniqueCell & key, 'trace', 'cell_num');
            traces = cat(2,traces{:});
            times = getTimes(aod.TracePreprocess & key);
            
            assert(length(times) == size(traces,1), 'WTF');
            
            trials = fetch(stimulation.StimTrials(key));
            conditions = fetch(stimulation.StimConditions(key),'*');
            
            oris = unique(arrayfun(@(x) x.orientation, [conditions.condition_info]));
            
            % Extract segment of trials for each stimulus
            trial_data = repmat(struct,length(trials),1);
            for i = 1:length(trials)
                trial_info = fetch1(stimulation.StimTrials(trials(i)), 'trial_params');
                event = fetch(stimulation.StimTrialEvents(trials(i), 'event_type="showSubStimulus"'),'*');
                onset = sort([event.event_time]);
                assert(length(onset) == 1, 'Appears to be a multidim stimulus');
                
                cond = trial_info.conditions;
                ori = conditions(cond).condition_info.orientation;
                condIdx = find(ori == oris);
                
                idx = find(times >= (onset + lag) & times < (onset + lag + duration));
                
                trial_data(i).ori = ori;
                trial_data(i).condIdx = condIdx;
                trial_data(i).traces = traces(idx,:);
            end
            
            % drop trials with no data
            idx = find(arrayfun(@(x) isempty(x.traces), trial_data));
            trial_data(idx) = [];
        end
    end
end
