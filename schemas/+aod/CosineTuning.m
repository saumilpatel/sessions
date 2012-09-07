%{
aod.CosineTuning (computed) # my newest table
-> aod.OrientationResponseSet
-> aod.TracePreprocess
-----
mean_firing            : double # The mean response magnitude
orientation_preference : double # The orientation preference
orientation_magnitude  : double # The magnitude of cosine tuning
significance           : double # The p-value
r2                     : double # The rsquared
%}

classdef CosineTuning < dj.Relvar & dj.Automatic

	properties(Constant)
		table = dj.Table('aod.CosineTuning')
		popRel = aod.OrientationResponseSet*aod.TracePreprocessSet  % !!! update the populate relation
	end

	methods
		function self = CosineTuning(varargin)
			self.restrict(varargin)
		end
	end

	methods(Access=protected)

        function makeTuples(self, key)
            data = fetch(aod.OrientationResponseSet & key, '*');
                        
            ori = data.orientation;
            responses = data.responses;            
            
            % To use the complex projection below need equal presentations
            orientations = unique(ori);
            count = hist(ori,orientations);
            presentations = min(count);
            excess = find(count > presentations);
            todel = [];
            for i = 1:length(excess)
                todel = [todel find(ori == orientations(excess(i)),1,'last')];
            end
            ori(todel) = [];
            responses(todel,:) = [];
            
            SHUFFLES = 10000;
            n = 2; % 2 params

            mean_removed = bsxfun(@minus,responses,mean(responses,1));
            ss = sum(mean_removed.^2,1);

            r2_shuffled = zeros(SHUFFLES, size(responses,2));
            for k = 1:SHUFFLES
                rand_ori = ori(1+floor(rand(size(ori))*size(ori,1)));
                ori_tune = mean(bsxfun(@times,mean_removed,exp(j * rand_ori * 2 * pi / 180)),1);
                ori_pred = real(bsxfun(@times,ori_tune, conj(exp(j * rand_ori * 2 * pi / 180))));
                ss_resid = sum(bsxfun(@minus,mean_removed,ori_pred).^2,1);
                r2_shuffled(k,:) = 1 - ss_resid ./ ss;
            end
            
            ori_tune = mean(bsxfun(@times,mean_removed,exp(j * ori * 2 * pi / 180)),1);
            ori_pred = real(bsxfun(@times,ori_tune, conj(exp(j * ori * 2 * pi / 180))));
            ss_resid = sum(bsxfun(@minus,mean_removed,ori_pred).^2,1);
                        
            r2 = 1 - ss_resid ./ ss;            
            p = (mean(bsxfun(@lt,r2,r2_shuffled),1));
            
            means = mean(responses);
            for i = 1:length(data.cell_nums)
                tuple = key;
                tuple.cell_num = data.cell_nums(i);
                tuple.mean_firing = means(i);
                tuple.orientation_preference = mod(angle(ori_tune(i)) / (2*pi) * 180, 180);
                tuple.orientation_magnitude = abs(ori_tune(i));
                tuple.significance = p(i);
                tuple.r2 = r2(i);
                self.insert(tuple);
            end
		end
    end
    
    methods
        function plot(self)
            assert(count(self) == 1, 'Only for one tuning curve');
            persistent data;
            if isempty(data) || ~isequal(data.key, fetch(aod.OrientationResponseSet & self))
            	data.key = fetch(aod.OrientationResponseSet & self);
                data.data = fetch(aod.OrientationResponseSet & self, '*');
            end
            
            ori = data.data.orientation;
            responses = data.data.responses;            
            responses = bsxfun(@minus,responses,mean(responses,1));
            
            cell = fetch(self,'*');
            idx = find(data.data.cell_nums == cell.cell_num);
            plot(ori,responses(:,idx),'.',1:360,cos(2*pi*2*(1:360)/360 - cell.orientation_preference / 180 * 2*pi)*cell.orientation_magnitude);
            title(sprintf('Preferred orientation %d', round(cell.orientation_preference)))
            xlabel('Orientation (deg)');
        end
    end
end
