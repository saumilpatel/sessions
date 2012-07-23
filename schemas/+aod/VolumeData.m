%{
aod.VolumeData (imported) # A scan site

->acq.AodVolume
---
stack_ch1  : longblob   # The actual volume data from ch1
stack_ch2  : longblob   # The actual volume data from ch2
x_coords   : longblob   # The x coordinates
y_coords   : longblob   # The x coordinates
z_coords   : longblob   # The x coordinates
x_res      : int unsigned # The number of x coordinates
y_res      : int unsigned # The number of y coordinates
z_res      : int unsigned # The number of z coordinates
%}

classdef VolumeData < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('aod.VolumeData');
        popRel = acq.AodVolume;
    end

    methods 
        function self = AodVolume(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)   
        function makeTuples( this, key )            
            tuple = key;
            
            volReader = getFile(acq.AodVolume(key));
            
            tuple.x_coords = volReader.x;
            tuple.y_coords = volReader.y;
            tuple.z_coords = volReader.z;
            
            tuple.x_res = length(tuple.x_coords);
            tuple.y_res = length(tuple.y_coords);
            tuple.z_res = length(tuple.z_coords);
            
            tuple.stack_ch1 = volReader(:,:,:,:,1);
            tuple.stack_ch2 = volReader(:,:,:,:,2);

            insert(aod.VolumeData, tuple);
        end
    end
end
