%{
aod.GratingModulation (computed) # A scan site

->aod.TuningCurve
---
modulation_power      : double   # The mean power of modulation
modulation_mag        : double   # The mean vector modulation magnitude 
modulation_phase      : double   # The mean vector modulation phase
mean_dc               : double   # The mean DC component
trial_responses       : longblob # The individual complex modulation
trial_means           : longblob # The individual trial means
%}

classdef GratingModulation < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('aod.GratingModulation');
        popRel = aod.TracePreprocessed * acq.AodStimulationLink * stimulation.MultiDimInfo('speed > 0');
    end

    methods 
        function self = TuningCurve(varargin)
            self.restrict(varargin{:})
        end
    
        function makeTuples( this, key )            
            tuple = key;
            
            tuning = fetch(aod.TuningCurve & key, '*');
            trace = fetch(aod.TracePreprocessed & key, '*');

            event = fetch(stimulation.StimTrialEvents(key, 'event_type="showSubStimulus"'),'*');
            trials = fetch(stimulation.StimTrials(key),'*');
            conditions = fetch(stimulation.StimConditions(key),'*');

            assert(length(event) == length(trials), 'Code not written for multiple presentations');
            
            ori = arrayfun(@(x) conditions(x.trial_params.conditions).condition_info.orientation, trials);
            preferred_trials = find(ori == tuning.preferred_orientation);
            
            trace_t = trace.t0 + 1000 * (0:length(trace.trace)-1) / trace.fs;
            for i = 1:length(preferred_trials)
                trial_idx = preferred_trials(i);
                trial_key = key;
                trial_key.trial_num = trial_idx;
                
                on_time = fetch1(stimulation.StimTrialEvents(trial_key, 'event_type="showStimulus"'),'event_time');
                off_time = fetch1(stimulation.StimTrialEvents(trial_key, 'event_type="endStimulus"'),'event_time');
                
                pre_idx = find(trace_t >= (on_time-1000) & trace_t <= on_time);
                idx = find(trace_t >= on_time & trace_t <= off_time);

                t = (0:length(idx)-1) / trace.fs; % in seconds
                
                % Experiment stopped prematurely
                if isempty(t)
                    break;
                end
                
                stim_f = conditions(trials(trial_idx).trial_params.conditions).condition_info.speed;
                psi = conditions(trials(trial_idx).trial_params.conditions).condition_info.initialPhase;

                % TODO check sign of psi
                reference = exp(j * 2 * pi * stim_f * t + psi);
                
                tuple.trial_means(i) = mean(trace.trace(idx)) - mean(trace.trace(pre_idx));
                tuple.trial_responses(i) = reference * trace.trace(idx) / length(idx);
            end
            
            tuple.mean_dc = mean(tuple.trial_means);
            tuple.modulation_power = mean(abs(tuple.trial_responses));
            tuple.modulation_mag = abs(mean(tuple.trial_responses));
            tuple.modulation_phase = angle(mean(tuple.trial_responses));
            
            if tuple.mean_dc < 0
            %    keyboard
            end
            insert(aod.GratingModulation, tuple);
        end
    end
end
