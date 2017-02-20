%{
aod.ScanMotion (computed) # my newest table
-> acq.AodScan
-----
t : longblob # Time of the motion trace
x : longblob # x coordinate of the motion trace
y : longblob # y coordinate of the motion trace
z : longblob # z coordinate of the motion trace
%}

classdef ScanMotion < dj.Relvar & dj.Automatic

	properties(Constant)
		table = dj.Table('aod.ScanMotion')
		popRel = acq.AodScan  % !!! update the populate relation
	end

	methods
		function self = ScanMotion(varargin)
			self.restrict(varargin)
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
		
            tuple = key;
            
            fn = char(fetchn(acq.AodScan & key, 'aod_scan_filename')) ; % get the filename from db
            oldversion = aod.checkFileversion(fn) ; % check if motion data is in old format, i.e. 2 planes or in new format, i.e. a volume
            if (oldversion)
                br = getFile(acq.AodScan & key,'Motion');
                motionData = br(:,:,:);
                [T D P] = size(motionData);
                mot = reshape(motionData,[T 10 20 P]);
                mot = permute(mot, [4 2 3 1]);
                t = br(:,'t');
                coordinates = br.motionCoordinates;


                [xpos,ypos,zpos,details] = aod.trackMotion(mot, t, coordinates);
            else
                % returned positions in microns and time in secs
                % the motion data channel is hardcoded to 2, should be eventually guided by some info in the database
                [xpos,ypos,zpos,t] = aod.trackMotion3D(fn, 2); 
            end
            tuple.x = xpos;
            tuple.y = ypos;
            tuple.z = zpos;
            tuple.t = t;
            
			self.insert(tuple)
		end
	end
end
