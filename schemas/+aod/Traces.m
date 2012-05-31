%{
aod.Traces (imported) # A scan site

->aod.TraceSet
cell_num        : int unsigned      # The cell number
---
x               : float             # X coordinate
y               : float             # Y coordinate
z               : float             # Z coordinate
trace           : longblob          # The unfiltered trace
t0              : double            # The starting time
fs              : double            # Sampling rate
%}

classdef Traces < dj.Relvar
    properties(Constant)
        table = dj.Table('aod.Traces');
        offset = -800 * 600;
    end
    
    methods 
        function self = Traces(varargin)
            self.restrict(varargin{:})
        end
    
        function makeTuples( this, key, asr )
            % Import a spike set
            
            disp(sprintf('Importing traces from %d cells', size(asr,2)));

            dat = asr(:,:);
            coordinates = asr.coordinates;
            for i = 1:size(dat,2)
                tuple = key;
                
                tuple.cell_num = i;
                tuple.x = double(coordinates(i,1)) / 146000000 * 100;
                tuple.y = double(coordinates(i,2)) / 146000000 * 100;
                tuple.z = double(coordinates(i,3)) / 70000 * 100;
                tuple.trace = dat(:,i) - this.offset;
                tuple.t0 = asr(1,'t');
                tuple.fs = getSamplingRate(asr);
            
                insert(this,tuple);
            end
        end
    end
end
