%{
aod.EventEnergy (computed) # my newest table
-> aod.Traces
-----
z_score   : double   # the z-score of the event energy
p_val     : double   # p-val versus shuffled data
score     : double   # the score for this trace
shuffled  : longblob # shuffled data
iqr_z_score   : double   # the z-score of the event energy
iqr_ratio     : double   # p-val versus shuffled data
%}

classdef EventEnergy < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('aod.EventEnergy')
		popRel = ((aod.Traces & acq.SessionsCleanup) - acq.AodScanIgnore)
	end

	methods
		function self = EventEnergy(varargin)
			self.restrict(varargin)
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
            tuple = key;
            
            h = @(tau, time) [zeros(1,100) exp(-(time - time(1)) / tau)];
            
            %% Get data
            trace = fetch1(aod.Traces & key, 'trace');
            times = (0:length(trace)-1) / fetch1(aod.Traces & key, 'fs');
            
            %% Preprocess data
            highPass = 0.1;
            dt = mean(diff(times));
            k = hamming(round(1/(dt)/highPass)*2+1);
            k = k/sum(k);
            trace = trace - convmirr(trace,k);  %  dF/F where F is low pass
            
            %% Plot data
            calc = h(0.6,times((times - times(1)) < 1.200));
            calc = calc / sum(calc);
            calc = calc - mean(calc);
            calc = fliplr(calc);
            
            filtered = convmirr(trace,calc');
            
            %% Score data
            score = var(filtered .* (filtered > 0));
            
            iqr_rand = zeros(1,1000);
            score_rand = zeros(1,1000);
            for i = 1:size(score_rand,2)
                trace_rand = trace(1+floor(length(trace)*rand(length(trace),1)));
                filtered_rand = convmirr(trace_rand,calc');
                score_rand(i) = var(filtered_rand .* (filtered_rand > 0));
                iqr_rand(i) = quantile(filtered_rand, 0.999);
            end
            
            tuple.z_score = (score - mean(score_rand)) / std(score_rand);
            tuple.p_val = mean(score < score_rand);
            tuple.score = score;
            tuple.iqr_z_score = (quantile(filtered,0.999) - mean(iqr_rand)) / std(iqr_rand);
            tuple.iqr_ratio = quantile(filtered,0.999) / mean(iqr_rand);
            tuple.shuffled = score_rand;

            %% Visualize
            subplot(211);
            plot(times-100*dt,filtered*4+100,times,trace);
            subplot(212);
            cla; hist(score_rand,100); hold on
            plot([score score],ylim(),'k','LineWidth',5);
            drawnow

            self.insert(tuple)
		end
	end
end
