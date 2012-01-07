%{
clustering.VariationalSU (computed) # Links a spikes to the variational clustering

-> ephys.Spikes
-> clustering.VariationalClustering
---
variationalsu_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef VariationalSU < dj.Relvar
    properties(Constant)
        table = dj.Table('clustering.VariationalSU');

        % Criterion for SU
        min_snr = 4;
        max_fp = 0.1;
        max_fn = 0.1;
        min_spikes = 1000;
    end
    
    methods 
        function self = VariationalSU(varargin)
            self.restrict(varargin{:})
        end
        
        % No makeTuples implemented - inserted from Spikes.makeTuples
        
        function plot( this )
            assert(count(this) == 1, 'Only can show one cluster');
            vsu = fetch(this, '*');
            vc = fetch(clustering.VariationalClustering(vsu),'*');
            su = fetch(ephys.SingleUnit(vsu),'*');
            data = vc.model.Features.data;
            spikes = vc.model.ClusterAssignment.data{su.cluster_number};
            other = setdiff(1:size(data,1), spikes);
            subplot(121)
            quickProject(data(spikes,:),data(other,:));
            spikes = spikes(1:10:end);
            other = other(1:50:end);
            xlabel('Projection');
            ylabel('Count');
            subplot(122)
            plot3(data(other,1),data(other,2),data(other,3),'.',data(spikes,1),data(spikes,2),data(spikes,3),'.','MarkerSize',3)
            xlabel('Feature 1'); ylabel('Feature 2'); zlabel('Feature 3');
            %subplot(133);
            %wf = getWaveforms(clustering.VariationalClustering(vsu));
            %plot(1:40,wf.data{1}(:,spikes))
        end
    end
end
