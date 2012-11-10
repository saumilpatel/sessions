%{
aod.DesignMatrixParams (lookup) # my newest table
stimulus_time_resolution   :    int    # Time step
-----
%}

classdef DesignMatrixParams < dj.Relvar

	properties(Constant)
		table = dj.Table('aod.DesignMatrixParams')
	end

	methods
		function self = DesignMatrixParams(varargin)
			self.restrict(varargin)
		end
	end
end
