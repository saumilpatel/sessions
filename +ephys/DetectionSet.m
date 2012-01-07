%{
ephys.DetectionSet (computed) # Compute set to detection

-> ephys.DetectionSetParam
---
detection_set_directory     : varchar(255)                  # The location of the detected spikes
detectionset_ts=CURRENT_TIMESTAMP: timestamp                # automatic timestamp. Do not edit
%}

classdef DetectionSet < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.DetectionSet');
    end
    
    methods 
        function self = DetectionSet(varargin)
            self.restrict(varargin{:})
        end
        
        function import(self, detection_set_key)
            % Import a detection set (and required elements) from
            % the sessions schema
            
            ephys.DetectionSet; % connect to DetectionSet first
            
            ds = sessions.DetectionSet(detection_set_key);
            assert(count(ds) == 1, 'Only import one detection set at a time');
            
            if length(fetch(ephys.Subjects(fetch(sessions.Subjects .* ds)))) == 0 %#ok<*ISMT>
                insert(ephys.Sessions, fetch(sessions.Sessions .* ds, '*'));
            end

            if length(fetch(ephys.Sessions(fetch(sessions.Sessions .* ds)))) == 0 %#ok<*ISMT>
                insert(ephys.Sessions, fetch(sessions.Sessions .* ds, '*'));
            end

            if length(fetch(ephys.Stimulation(fetch(sessions.Stimulation .* ds)))) == 0
                insert(ephys.Stimulation, fetch(sessions.Stimulation .* ds, '*'));
            end

            %if length(ephys.BehaviorTraces(fetch(sessions.BehaviorTraces .* ds))) == 0
            %    insert(ephys.BehaviorTraces, fetch(sessions.BehaviorTraces .* ds, '*'));
            %end

            if length(fetch(ephys.Ephys(fetch(sessions.Ephys .* ds)))) == 0
                insert(ephys.Ephys, fetch(sessions.Ephys .* ds, '*'));
            end

            if length(fetch(ephys.EphysTimesSet(fetch(sessions.EphysTimesSet .* ds)))) == 0
                insert(ephys.EphysTimesSet, fetch(sessions.EphysTimesSet .* ds, '*'));
            end
            
            if length(fetch(ephys.EphysSetStimLink(fetch(sessions.EphysSetStimLink .* ds)))) == 0
                insert(ephys.EphysSetStimLink, fetch(sessions.EphysSetStimLink .* ds, '*'));
            end

            if length(fetch(ephys.DetectionSetParam(fetch(sessions.DetectionSetParam .* ds)))) == 0
                insert(ephys.DetectionSetParam, fetch(sessions.DetectionSetParam .* ds, '*'));
            end

            if length(fetch(ephys.DetectionSet(fetch(sessions.DetectionSet .* ds)))) == 0
                insert(ephys.DetectionSet, fetch(sessions.DetectionSet .* ds, '*'));
            end
            
            if length(fetch(ephys.DetectionElectrode(fetch(sessions.DetectionElectrode .* ds)))) == 0
                insert(ephys.DetectionElectrode, fetch(sessions.DetectionElectrode .* ds, '*'));
            end
            
        end
    end
end
