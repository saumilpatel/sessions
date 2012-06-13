%{
aod.CellPos (imported) # A scan site

->aod.TraceQuality
->acq.AodVolume
---
scan             : enum('Pre','Post')  # Whether this is a pre or post scan
cell_center_x    : double   # Center of the cell in this volume
cell_center_y    : double   # Center of the cell in this volume
cell_center_z    : double   # Center of the cell in this volume
clicked_p1=null  : longblob # Plane with idx1 set to zero
clicked_p2=null  : longblob # Plane with idx2 set to zero
clicked_p3=null  : longblob # Plane with idx3 set to zero
cell_location_x  : double   # Location of the point in this volume
cell_location_y  : double   # Location of the point in this volume
cell_location_z  : double   # Location of the point in this volume
centered_p1=null : longblob # Plane with idx1 set to zero
centered_p2=null : longblob # Plane with idx1 set to zero
centered_p3=null : longblob # Plane with idx1 set to zero
%}

classdef CellPos < dj.Relvar
    properties(Constant)
        table = dj.Table('aod.CellPos');
    end
    
    methods 
        function self = CellPos(varargin)
            self.restrict(varargin{:})
        end
    end
end
