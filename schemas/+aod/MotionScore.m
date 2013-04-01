%{
aod.MotionScore (computed) # my newest table
-> aod.ScanMotion

-----
std_d      : double     # Noise in displacement
std_x      : double     # Noise in x motion
std_y      : double     # Noise in y motion
std_z      : double     # Noise in z motion
trace_corr : double     # PC1 and motion correlation
%}

classdef MotionScore < dj.Relvar & dj.Automatic

	properties(Constant)
		table = dj.Table('aod.MotionScore')
		popRel = aod.ScanMotion  % !!! update the populate relation
	end

	methods
		function self = MotionScore(varargin)
			self.restrict(varargin)
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
            
            tuple = key;
            sm = fetch(aod.ScanMotion & key, '*');
            
            tuple.std_x = std(sm.x);
            tuple.std_y = std(sm.y);
            tuple.std_z = std(sm.z);
            
            d = sqrt((sm.x-mean(sm.x)).^2 + (sm.y-mean(sm.y)).^2 + (sm.z-mean(sm.z)).^2);
            tuple.std_d = std(d);

            trace = fetch(aod.TracePreprocess('preprocess_method_num=1') & key, '*');
            times = getTimes(aod.TracePreprocess('preprocess_method_num=1') & key);

            % compute corrcoef for motion and pc1
            [~,p] = princomp(cat(2,trace.trace));
            p(:,2:end) = [];
            p1 = interp1(times,p,sm.t);
            c = corrcoef(p1,d);
            tuple.trace_corr = c(1,2);

			self.insert(tuple)
		end
	end
end
