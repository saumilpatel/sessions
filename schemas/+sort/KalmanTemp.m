%{
sort.KalmanTemp (computed) # my newest table
-> sort.KalmanAutomatic
-----
temp_model: LONGBLOB # The finalized model
kalmantemp_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef KalmanTemp < dj.Relvar
    
    properties(Constant)
        table = dj.Table('sort.KalmanTemp')
    end
    
    methods
        function self = KalmanTemp(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples( this, key, model )
            % Cluster spikes
            %
            % JC 2011-10-21
            tuple = key;
            
            model = updateInformation(model);
            
            idx = sort([model.train model.test]);
            [~, model.train] = ismember(model.train, idx);
            [~, model.test] = ismember(model.test, idx);
            model.SpikeTimes.data = model.SpikeTimes.data(idx);
            model.Waveforms.data = cellfun(@(x) x(:, idx), model.Waveforms.data, 'UniformOutput', false);
            model.Features.data = model.Features.data(idx, :);
            
            model.Y = model.Y(:, idx);
            model.t = model.t(idx);
            
             % block ids for all data points
            [~, model.blockId] = histc(model.t, model.mu_t);
            
            model = updateInformation(model);
            
            % Things to remove:
            model.tt = [];
            model.Y = [];
            model.t = [];
                        
            tuple.temp_model = saveStructure(model);
            insert(sort.KalmanTemp, tuple);
        end
        
        function model = getModel(self)
            assert(count(self) == 1, 'Only for scalar relvars');
            
            % Things to copy on load
            % Features -> X
            % SpikeTimes -> t

            model = fetch1(self,'temp_model');
            model.Y = model.Features.data';
            model.t = model.SpikeTimes.data';
        end
    end
end
