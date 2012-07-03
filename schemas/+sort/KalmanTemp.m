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
        minPerCluster = 500;
        maxTotal = 10000;
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
            
            % Things to parse down:
            % Waveforms, SpikeTimes, Features
            idx = 1:length(model.SpikeTimes.data);
            r = randperm(length(idx));
            idx = idx(r(1:min(this.maxTotal, end)));
            for i = 1:1:length(model.ClusterAssignment.data)
                % For each cluster if less than the minimum number of
                % points available try to add more
                if length(intersect(idx,model.ClusterAssignment.data{i})) < this.minPerCluster
                    idx = setdiff(idx,model.ClusterAssignment.data{i});
                    r = randperm(length(model.ClusterAssignment.data{i}));
                    r = r(1:min(end,this.minPerCluster));
                    idx = [idx, model.ClusterAssignment.data{i}(r)];
                end
            end
            
            idx = sort(idx);
            
            model.SpikeTimes.data = model.SpikeTimes.data(idx);
            model.Waveforms.data = cellfun(@(x) x(:,idx), model.Waveforms.data, 'UniformOutput', false);
            model.Features.data = model.Features.data(idx,:);
            
            model.Y = model.Y(:,idx);
            model.t = model.t(idx);
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
