%{
aod.UniqueCells (computed) # my newest table
-> aod.QualitySet
-----
duplicates : longblob # list of duplicate cells
%}

classdef UniqueCells < dj.Relvar & dj.AutoPopulate
	properties(Constant)
		table = dj.Table('aod.UniqueCells')
        popRel = aod.QualitySet;
	end

	methods
		function self = UniqueCells(varargin)
			self.restrict(varargin)
        end
    end
    
    methods (Access=protected)
        
        function makeTuples(self, key)
            
            tuple = key;
                        
            cp = fetch(aod.CellPos & key & 'scan="Pre"', '*');
            tq = fetch(aod.TraceQuality & key, '*');
            
            snr = [tq.snr];
            
            d = @(i,j) sqrt((cp(i).cell_center_x - cp(j).cell_center_x).^2 + ...
                (cp(i).cell_center_y - cp(j).cell_center_y).^2 + ...
                (cp(i).cell_center_z - cp(j).cell_center_z).^2);
            
            N = length(cp);
            dm = zeros(N);
            for i = 1:N
                for j = i+1:N
                    dm(i,j) = d(i,j);
                    dm(j,i) = dm(i,j);
                end
            end
            
            identical = sparse(dm < 5);
            
            good_ids = [];
            accounted = zeros(1,N);
            duplicates = {};
            for i = 1:N
                if accounted(i), continue, end
                dist = bfs(identical, i);
                if max(dist) == 0
                    good_ids = [good_ids i];
                    accounted(i) == 1;
                else
                    % double clicked cell, find favorite
                    possible = find(dist > 0);
                    assert(all(accounted(possible)==0), 'Some logic is flawed here');
                    possible = [i; possible];
                    [~,best] = max(snr(possible));
                    
                    good_ids = [good_ids possible(best)];
                    accounted(possible) = 1;
                    
                    duplicates = [duplicates, {possible}];
                    
                end
            end			
            
            tuple.duplicates = duplicates;
            self.insert(tuple)
            for i = 1:length(good_ids)
                tuple = key;
                tuple.cell_num = good_ids(i);
                insert(aod.UniqueCell, tuple);
            end
            
		end
	end
end
