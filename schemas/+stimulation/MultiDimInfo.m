%{
stimulation.MultiDimInfo (computed) # A scan site

->stimulation.StimTrialGroup
---
num_orientations     : int unsigned   # number of orientations
orientations         : longblob       # number of orientations
speed                : double         # speed of the grating
sinusoidal           : bool           # if it is a sinusoidal grating
block_design         : bool           # if it is a block design
%}

classdef MultiDimInfo < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('stimulation.MultiDimInfo');
        popRel = stimulation.StimTrialGroup & acq.Stimulation('exp_type="MultDimExperiment" OR exp_type="MouseMultiDim"');
    end
    
    methods 
        function self = MultiDimInfo(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)
        function makeTuples( this, key )
            % Import a spike set
            tuple = key;
            
            stimInfo = fetch(stimulation.StimTrialGroup(key), '*');
            tuple.orientations = stimInfo.stim_constants.orientation;
            tuple.num_orientations = length(tuple.orientations);
            tuple.speed = stimInfo.stim_constants.speed;
            sub_stim = fetch(pro(stimulation.StimTrials, stimulation.StimTrialEvents(key, 'event_type="showSubStimulus"'),'COUNT(trial_num)->num_sub_stim'),'*');
            
            tuple.block_design = max([sub_stim.num_sub_stim]) == 1;
            if ~isfield(stimInfo.stim_constants, 'sinusoidal')
                tuple.sinusoidal = 1;
            else
                tuple.sinusoidal = stimInfo.stim_constants.sinusoidal;
            end

            insert(this,tuple);         
        end
        

    end
end
