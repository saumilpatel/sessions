%{
aod.EventEnergy (computed) # my newest table
-> aod.Traces
-----
z_score   : double   # the z-score of the event energy
p_val     : double   # p-val versus shuffled data
score     : double   # the score for this trace
shuffled  : longblob # shuffled data
%}

classdef EventEnergy < dj.Relvar & dj.Automatic

	properties(Constant)
		table = dj.Table('aod.EventEnergy')
		popRel = aod.Traces  % !!! update the populate relation
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
            times = getTimes(aod.TracePreprocess('preprocess_method_num=1') & key);
            
            %% Preprocess data
            highPass = 0.0001;
            dt = mean(diff(times));
            k = hamming(round(1/(dt)/highPass)*2+1);
            k = k/sum(k);
            trace = trace - convmirr(trace,k);  %  dF/F where F is low pass
            
            %% Plot data
            calc = h(300,times((times - times(1)) < 1200));
            calc = calc / sum(calc);
            calc = calc - mean(calc);
            calc = fliplr(calc);
            
            filtered = convmirr(trace,calc');
            
            %% Score data
            score = var(filtered .* (filtered > 0));
            
            for i = 1:1000
                trace_rand = trace(1+floor(length(trace)*rand(length(trace),1)));
                filtered_rand = convmirr(trace_rand,calc');
                score_rand(i) = var(filtered_rand .* (filtered_rand > 0));
            end
            
            tuple.z_score = (score - mean(score_rand)) / std(score_rand);
            tuple.p_val = mean(score < score_rand);
            tuple.score = score;
            score.shuffled = score_rand;

            %% Visualize
            subplot(211);
            plot(times-100*dt,filtered*4+100,times,trace);
            drawnow
            subplot(212);
            cla; hist(score_rand,100);
            plot([score scrore],ylim(),'k','LineWidth',5);

            self.insert(tuple)
		end
	end
end
