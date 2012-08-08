%{
class_discrimination.Performance (computed) # Multiple variable regression for decision and posterior

-> class_discrimination.ClassDiscriminationExperiment
---
orientation       : longblob     # The orientation in each bin
prob_a            : longblob     # The probability of oselect A in that bin
num               : longblob     # The number of trials in each bin
%}

classdef Performance < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('class_discrimination.Performance');
        popRel = class_discrimination.ClassDiscriminationExperiment
        bins = 20;
    end
    
    methods
        function self = Performance(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)
        function makeTuples( this, key )
            % Compute the performance
            tuple = key;
            
            orientation_bins = linspace(0,360,class_discrimination.Performance.bins);
            tuple.orientation = (orientation_bins(1:end-1) + orientation_bins(2:end)) / 2;
            
            [selected_class orientation] = ...
                fetchn(class_discrimination.ClassDiscriminationTrial(key),...
                'selected_class', 'orientation');
            
            for i = 1 : length(orientation_bins) - 1
                idx = find(orientation > orientation_bins(i) & orientation <= orientation_bins(i+1));
                tuple.num(i) = length(idx);
                tuple.prob_a(i) = mean(cellfun(@(x) x=='A', selected_class(idx)));
            end
            
            insert(this,tuple);
        end
    end
end
