%{
aod.GratingModulation (computed) # A scan site

->aod.TuningCurve
---
modulation_power      : double   # The mean power of modulation
modulation_mag        : double   # The mean vector modulation magnitude 
modulation_phase      : double   # The mean vector modulation phase
mean_dc               : double   # The mean DC component
trial_responses       : longblob
%}

classdef GratingModulation < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('aod.GratingModulation');
        popRel = aod.TracePreprocessed * acq.AodStimulationLink * stimulation.MultiDimInfo;
    end

    methods 
        function self = TuningCurve(varargin)
            self.restrict(varargin{:})
        end
    
        function makeTuples( this, key )            
            tuple = key;
            
            tuning = fetch(aod.TuningCurve & key, '*');
            trace = fetch1(aod.TracePreprocessed & key, '*');

            event = fetch(stimulation.StimTrialEvents(key, 'event_type="showSubStimulus"'),'*');
            trials = fetch(stimulation.StimTrials(key),'*');
            conditions = fetch(stimulation.StimConditions(key),'*');

            assert(length(event) == length(trials), 'Code not written for multiple presentations');
            
            ori = arrayfun(@(x) conditions(x.trial_params.conditions).condition_info.orientation, trials);
            preferred_trials = find(ori == tuning.preferred_orientation);
            
            for i = 1:length(preferred_trials)
                trial_idx = preferred_trials(i);
                trial_key = key;
                trial_key.trial_num = trial_idx;
                
                on_time = fetch1(stimulation.StimTrialEvents(trial_key, 'event_type="showStimulus"'),'event_time');
                off_time = fetch1(stimulation.StimTrialEvents(trial_key, 'event_type="endStimulus"'),'event_time');
                        
                idx = (trace.t0 + 1000 * length(trace.trace) / trace.fs) >= on_time & ...
                    (trace.t0 + 1000 * length(trace.trace) / trace.fs) <= off_time;

                t = (0:length(idx)-1) / trace.fs; % in seconds
                stim_f = conditions(trials(trial_idx).trial_params.conditions).condition_info.speed;
                psi = conditions(trials(trial_idx).trial_params.conditions).condition_info.initial_phase;

                % TODO check sign of psi
                reference = exp(j * 2 * pi * stim_f * t + psi);
                
                dc(i) = mean(trace.trace(idx));
                tuple.trial_responses(i) = reference * trace.trace(idx) / length(idx);
            end
            
            tuple.mean_dc = mean(dc);
            tuple.modulation_power = mean(abs(tuple.trial_responses));
            tuple.modulation_mag = abs(mean(tuple.trial_responses));
            tuple.modulation_phase = angle(mean(tuple.trial_responses));
            
            insert(aod.GratingModulation, tuple);
        end
    end
end
