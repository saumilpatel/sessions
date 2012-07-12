classdef MoKsmInterface < SpikeSortingHelper & ClusteringHelper & MoKsm

	methods
        
		function self = MoKsmInterface(varargin)
            % MoKsmInterface constructor
            
            self = self@SpikeSortingHelper(varargin{:});
            self = self@ClusteringHelper();
            self = self@MoKsm(varargin{:});
        end
        
        
        function self = updateInformation(self)
            % Update the ClusterAssignment and ContaminationMatrix
            
            ids = cluster(self);
            N = length(unique(ids));
            self.ClusterAssignment.data = cell(N,1);
            for i = 1:length(unique(ids))
                self.ClusterAssignment.data(i) = {find(ids == i)};
            end
            
            [pairwise, n] = overlap(self);
            self.ContaminationMatrix.data.pairwise = pairwise;
            self.ContaminationMatrix.data.n = n;
            
            if isempty(self.GroupingAssignment)
                self.GroupingAssignment(1).data = num2cell(1:length(self.ClusterAssignment.data));
                self.ClusterTags.data = cell(1,length(self.ClusterAssignment.data));
            end
        end
        
        
        function self = fit(self)
            % Fits the model
            
            self = fit@MoKsm(self, self.Features.data, self.SpikeTimes.data);
        end

        
        function self = delete(self, ids)
            % Delete cluster with given id(s).
            
            modelIds = [self.GroupingAssignment.data{ids}];
            assert(numel(modelIds) > 0, 'Nothing to delete.')
            assert(numel(ids) < numel(self.GroupingAssignment.data), 'Can''t delete all clusters.')
            
            % Delete clusters from mixture model
            self = deleteCluster(self, modelIds);
            
            % Remove the pointer to the deleted clusters and decrement all
            % others that are greater than it.  Need to go from back to
            % front in case something has multiple clusters before it
            self.GroupingAssignment.data(ids) = [];
            self.ClusterTags.data(ids) = [];
            for i = sort(modelIds, 'descend')
                self.GroupingAssignment.data = cellfun(@(x) x - (x > i), ...
                    self.GroupingAssignment.data, 'UniformOutput', false);
            end
            
            % Reclassify all the points into the remaining clusters
            self = updateInformation(self);
        end

        
        function self = split(self, id)
            % Split cluster with given id.
        
            assert(length(id) == 1, 'Only split one cluster at a time');
            group = length(self.GroupingAssignment.data{id}) > 1;
            
            switch(group)
                case true % For groups simply split apart into raw clusters
                    clusterIds = self.GroupingAssignment.data{id};
                    self.GroupingAssignment.data(id) = [];
                    self.ClusterTags.data(id) = [];
                    
                    self.GroupingAssignment.data(end+1:end+length(clusterIds)) = num2cell(clusterIds);
                    self.ClusterTags.data(end+1:end+length(clusterIds)) = cell(1,length(clusterIds));
                    % No need to rerun updateInformation as cluster
                    % assignments unchanged
                case false
                    self = splitCluster(self, id);
                    self.GroupingAssignment.data{end + 1} = numel(self.priors);
                    self.ClusterTags.data{end + 1} = [];
                    self = updateInformation(self);
            end
        end

        
        function self = merge(self, ids)
            % Merge clusters with given ids.
            
            modelIds = [self.GroupingAssignment.data{ids}];
            assert(numel(modelIds) > 1, 'Merge needs at least two model components.')
            
            % Do merge in mixture model
            self = mergeClusters(self, modelIds);
            
            % Remove the pointer to the deleted clusters and decrement all
            % others that are greater than it.  Need to go from back to
            % front in case something has multiple clusters before it. The
            % merged cluster's id is the minimum of its original ids.
            newId = min(ids);
            removedIds = setdiff(ids, newId);
            newModelId = min(modelIds);
            removedModelIds = setdiff(modelIds, newModelId);
            self.GroupingAssignment.data(removedIds) = [];
            self.GroupingAssignment.data(newId) = {newModelId};
            self.ClusterTags.data(removedIds) = [];
            self.ClusterTags.data(newId) = {[]};
            for i = sort(removedModelIds, 'descend')
                self.GroupingAssignment.data = cellfun(@(x) x - (x > i), ...
                    self.GroupingAssignment.data, 'UniformOutput', false);
            end
            
            % Reclassify all the points into the remaining clusters
            self = updateInformation(self);
        end

        
        function self = group(self, ids)
            % Group clusters.
            
            finalGroup = cat(2, self.GroupingAssignment.data{ids});
            
            % Delete previous groups and tags
            self.GroupingAssignment.data(ids) = [];
            self.ClusterTags.data(ids) = [];
            
            % Create new one
            self.GroupingAssignment.data(end+1) = {finalGroup};
            self.ClusterTags.data(end+1) = {[]};
        end

        
        function self = refit(self)
            % Refit the complete data set again
            
            self = refit@MoKsm(self);
            self = updateInformation(self);
        end

        
        function self = compress(self, varargin)
            % Remove any information that can be recomputed and doesn't
            % need to be stored on disk
            
            self = compress@SpikeSortingHelper(self, varargin{:});
            self = compress@MoKsm(self);
        end
        
        
        function self = uncompress(self)
            % Recreate any information that compress strips out
        
            self = uncompress@SpikeSortingHelper(self);
            self = uncompress@MoKsm(self, self.Features.data', self.SpikeTimes.data);
        end
        
    end

end
