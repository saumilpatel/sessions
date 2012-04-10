%{
sort.VariationalClusteringAutomatic (computed) # Detection methods

-> sort.Electrodes
---
model: LONGBLOB # The fitted model
variationalclusteringautomatic_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef VariationalClusteringAutomatic < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('sort.VariationalClusteringAutomatic');
        popRel = sort.Electrodes * sort.Methods('sort_method_name = "Utah"');
    end
    
    methods 
        function self = VariationalClusteringAutomatic(varargin)
            self.restrict(varargin{:})
        end
        
        function tt = loadTT( this )
            % Load the TT file
            assert(count(this) == 1, 'Only call this for one VC');
            
            de = fetch(detect.Electrodes .* this, 'detect_electrode_file');
            fn = getLocalPath(de.detect_electrode_file);
            
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
    end
    
    methods (Access=protected)
        function makeTuples( this, key )
            % Cluster spikes
            %
            % JC 2011-10-21
            
            tuple = key;
            
            de_keys = fetch(detect.Electrodes(key));
            
            for de_key = de_keys'
                de = fetch(detect.Electrodes(de_key), 'detect_electrode_file');
            
                tuple = dj.utils.structJoin(de_key, key)
                
                % Get spike file
                fn = getLocalPath(de.detect_electrode_file);
            
                disp(sprintf('Clustering spikes from %s',fn));
            
                tt = ah_readTetData(fn);            
                tuple.model = variationalClustering(tt); %,'graphical',0);
                tuple.model = rmfield(tuple.model, 'Waveforms');
                
                insert(this,tuple);
            end
        end
    end
end
