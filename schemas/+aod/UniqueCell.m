%{
aod.UniqueCell (computed) # my newest table
-> aod.UniqueCells
-> aod.Traces
-----
%}

classdef UniqueCell < dj.Relvar

	properties(Constant)
		table = dj.Table('aod.UniqueCell')
	end

	methods
		function self = UniqueCell(varargin)
			self.restrict(varargin)
		end

		function makeTuples(self, key)
		%!!! compute missing fields for key here
			self.insert(key)
		end
	end
end
