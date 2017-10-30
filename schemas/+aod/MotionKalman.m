%{
aod.MotionKalman (computed) # my newest table
-> aod.ScanMotion
-> aod.TraceSet
kalman_q  : double # Drift parameter
kalman_r1 : double # Trace observation noise
kalman_r2 : double # Motion observation noise
-----
motion_t  : longblob # The kalman time step
motion_x  : longblob # The kalman x position
motion_y  : longblob # The kalman y position
motion_z  : longblob # The kalman z position
resid     : longblob # The residual traces
%}

classdef MotionKalman < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('aod.MotionKalman')
		popRel = aod.ScanMotion*aod.TraceSet
	end

	methods
		function self = MotionKalman(varargin)
			self.restrict(varargin)
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)

            tuple = key;
            
            % default kalman params
            tuple.kalman_q  = 1e-11;
            tuple.kalman_r1 = 1e2;
            tuple.kalman_r2 = 1e-7;
            
            % Fetch the requisite data
            trace = fetch(aod.Traces & key, '*');
            sm = fetch(aod.ScanMotion & key, '*');
            trace_t = getTimes(aod.Traces & key);
            
            traces = cat(2,trace.trace);
            y = bsxfun(@minus,traces,mean(traces,1));

            % Compute the matrix that predicts traces from position
            traces_smoothed = zeros(length(sm.t),size(traces,2));            
            for i = 1:length(sm.t)-1
                idx = find(trace_t > sm.t(i) & ...
                    trace_t <= sm.t(i+1));
                traces_smoothed(i,:) = mean(y(idx,:));
            end

            x_true = [sm.x sm.y sm.z];
            H1 = traces_smoothed' / x_true';
            
            % Initialize parameters
            F = diag([1 1 1]);
            Q = diag([1 1 1]) * tuple.kalman_q;
            H2 = diag([1 1 1]);
            R1 = diag(ones(size(H1,1),1)) * tuple.kalman_r1;
            R2 = diag(ones(3,1)) * tuple.kalman_r2;
            m_idx = 1;
            
            % Initial state
            x = zeros(size(traces,1),3);
            x(1,:) = [sm.x(1) sm.y(1) sm.z(1)]';
            P = Q;

            % Run the kalman filter
            for i = 2:size(traces,1)
                if mod(i,1000) == 0
                    disp(sprintf('%d/%d',i,size(traces,1)));
                    
                    subplot(311)
                    plot(sm.t,sm.x,trace_t,x(:,1))
                    subplot(312)
                    plot(sm.t,sm.y,trace_t,x(:,2))
                    subplot(313)
                    plot(sm.t,sm.z,trace_t,x(:,3))
                    
                    drawnow
                end
                x_pred = F * x(i-1,:)';
                P = F*P*F' + Q;
                
                y_resid = y(i,:)' - H1 * x_pred;
                S = H1*P*H1' + R1;
                K = P*H1'*S^-1;
                
                P = (eye(3) - K*H1) * P;
                
                x(i,:) = x_pred + K*y_resid;
                
                if m_idx <= length(sm.t) && sm.t(m_idx) < trace_t(i)
                    pos_resid = x_true(m_idx,:)' - H2 * x(i,:)';
                    S = H2*P*H2' + R2;
                    K = P*H2'*S^-1;
                    x(i,:) = (x(i,:)' + K*pos_resid)';
                    
                    P = (eye(3) - K*H2) * P;
                    
                    m_idx = m_idx+1;
                end
                
            end
            
            tuple.motion_t = trace_t;
            tuple.motion_x = x(:,1);
            tuple.motion_y = x(:,2);
            tuple.motion_z = x(:,3);

            tuple.resid = y - (H1 * x')';

            self.insert(tuple)
		end
	end
end
