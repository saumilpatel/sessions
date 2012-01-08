%{
clustering.VariationalClustering (computed) # Detection methods

-> ephys.ClusterSet
-> ephys.DetectionElectrode

---
model: LONGBLOB # The fitted model
variationalclustering_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef VariationalClustering < dj.Relvar
    properties(Constant)
        table = dj.Table('clustering.VariationalClustering');
    end
    
    methods 
        function self = VariationalClustering(varargin)
            self.restrict(varargin{:})
        end
        
        function tt = loadTT( this )
            % Load the TT file
            assert(count(this) == 1, 'Only call this for one VC');
            
            de = fetch(ephys.DetectionElectrode .* this, 'detection_electrode_filename');
            fn = getLocalPath(de.detection_electrode_filename);
            
            tt = ah_readTetData(fn);
        end
        
        function wf = getWaveforms( this )
            % Get and scale the waveforms
            tt = loadTT(this);
            
            if max(mean(tt.w{1},2)) > 1  % data originally was in raw values
                wf = cellfun(@(x) x / 2^23*317000, tt.w, 'UniformOutput',false);
            else % new data is in volts, convert to 
                wf = cellfun(@(x) x * 1e6, tt.w, 'UniformOutput', false);
            end
            
            wf = struct('data',{wf},'meta',struct('units', 'muV'));
        end

        function makeTuples( this, key )
            % Cluster spikes
            %
            % JC 2011-10-21
            
            tuple = key;
            
            de_keys = fetch(ephys.DetectionElectrode(key));
            
            for de_key = de_keys'
                de = fetch(ephys.DetectionElectrode(de_key), 'detection_electrode_filename');
            
                tuple = dj.utils.structJoin(de_key, key)
                
                % Get spike file
                fn = getLocalPath(de.detection_electrode_filename);
            
                disp(sprintf('Clustering spikes from %s',fn));
            
                tt = ah_readTetData(fn);            
                tuple.model = variationalClustering(tt); %,'graphical',0);
                tuple.model = rmfield(tuple.model, 'Waveforms');
                
                insert(this,tuple);
            end
            
        end
    end
end
