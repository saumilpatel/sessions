%{
aod.PatchedCell (manual) # my newest table
-> acq.AodScan
-> acq.AodVolume
cell_num        : int unsigned      # The cell number
-----

%}

classdef PatchedCell < dj.Relvar

	properties(Constant)
		table = dj.Table('aod.PatchedCell')
	end

	methods
		function self = PatchedCell(varargin)
			self.restrict(varargin)
		end
	end
end
