%{
aod.PatchedLikelihood (computed) # my newest table
-> aod.Spikes
kernel_method       : int unsigned    # The cell number
-----
real_likelihood     : double          # Likelihood of the fluorescence

fp_likelihood       : longblob        # Likelihood with dropped spikes
fp_mean_likelihood  : longblob        # Mean likelihood with dropped spikes
fp_num              : longblob        # Number of spikes dropped
fn_likelihood       : longblob        # Likelihood with added spikes
fn_mean_likelihood  : longblob        # Mean likelihood with added spikes
fn_num              : longblob        # Number of spikes added
spike_count_fisher  : double          # Fisher information
spike_count_std     : double          # Standard deviation of spike count

shifted_likelihood      : longblob    # Likelihood with shifted spikes
shifted_mean_likelihood : longblob    # Mean likelihood with shifted spikes
shifted_tau             : longblob    # Time shifted by
tau_fisher              : double      # Fisher information for spike time
tau_std                 : double      # Expected std of spike time
%}

classdef PatchedLikelihood < dj.Relvar & dj.Automatic

	properties(Constant)
		table = dj.Table('aod.PatchedLikelihood')
		popRel = aod.Spikes * aod.Traces  % !!! update the populate relation
	end

	methods
		function self = PatchedLikelihood(varargin)
			self.restrict(varargin)
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
            key.kernel_method = 0;
            
            tuple = key;

            ts = fetch(aod.TracePreprocessSet & key & 'preprocess_method_num=1')

            %% Process it
            dat = fetch(aod.Traces & ts, '*');
            times = getTimes(aod.TracePreprocess & ts & 'preprocess_method_num=1');

            cell_num = fetch1(aod.PatchedCell & ts, 'cell_num');

            m = arrayfun(@(x) mean(x.trace), dat);
            v = arrayfun(@(x) var(diff(x.trace))/2, dat);

            b = robustfit(m,v)

            % Convert to approximate photon counts
            traces_calibrated = (cat(2,dat.trace) + b(1) / b(2)) / b(2);
            m = mean(traces_calibrated); v = var(diff(traces_calibrated,[],1))/2;
            plot(m,v,'.'); refline
            drawnow

            % Get the spike times
            sp = fetch(aod.Spikes & ts, '*');



            %% Compute data likelihood for real spikes
            tau = 500;
            scale = 12;
            
            binned = hist(sp.times, times);
            smoothed = conv(binned,exp(-(times - times(1)) / tau));
            smoothed(length(times)+1:end) = [];
            smoothed = smoothed';

            scaled_smoothed = smoothed*scale;

            trace = traces_calibrated(:,cell_num);
            trace_resid = trace - scaled_smoothed;
            slow_part = convmirr(trace_resid, hamming(1000) / sum(hamming(1000)));
            tuple.real_likelihood = sum(log(poisspdf(round(trace), scaled_smoothed+slow_part)));
            
            %% Compute data likelihood shifting each spike

            jitter_tau = -500:10:500
            for i = 1:length(sp.times)
                for j = 1:length(jitter_tau)
                    fake_times = sp.times;
                    fake_times(i) = fake_times(i) + jitter_tau(j);
                    binned = hist(fake_times, times);

                    smoothed = conv(binned,exp(-(times - times(1)) / tau));
                    smoothed(length(times)+1:end) = [];
                    smoothed = smoothed';

                    scaled_smoothed = smoothed*scale;

                    trace = traces_calibrated(:,cell_num);
                    trace_resid = trace - scaled_smoothed;
                    slow_part = convmirr(trace_resid, hamming(1000) / sum(hamming(1000)));
                    tuple.shifted_likelihood(i,j) = sum(log(poisspdf(round(trace), scaled_smoothed+slow_part)));
                end
            end
            
            %% Compute data likelihood for false negatives

            for j = 1:20
                for i = 1:100
                    fake_times = sp.times(1) + rand(j,1) * range(sp.times);
                    binned = hist([sp.times; fake_times], times);

                    smoothed = conv(binned,exp(-(times - times(1)) / tau));
                    smoothed(length(times)+1:end) = [];
                    smoothed = smoothed';

                    scaled_smoothed = smoothed*scale;

                    trace = traces_calibrated(:,cell_num);
                    trace_resid = trace - scaled_smoothed;
                    slow_part = convmirr(trace_resid, hamming(1000) / sum(hamming(1000)));
                    tuple.fn_likelihood(i,j) = sum(log(poisspdf(round(trace), scaled_smoothed+slow_part)));
                end
                j
            end

            %% Compute data likelihood for false positives
            % (by testing likelihoood with spikes removed)

            for j = 1:20
                for i = 1:100
                    fake_times = sp.times;
                    idx = randperm(length(sp.times)); idx(j+1:end) = [];
                    fake_times(idx) = [];
                    binned = hist(fake_times, times);

                    smoothed = conv(binned,exp(-(times - times(1)) / tau));
                    smoothed(length(times)+1:end) = [];
                    smoothed = smoothed';

                    scaled_smoothed = smoothed*scale;

                    trace = traces_calibrated(:,cell_num);
                    trace_resid = trace - scaled_smoothed;
                    slow_part = convmirr(trace_resid, hamming(1000) / sum(hamming(1000)));
                    tuple.fp_likelihood(i,j) = sum(log(poisspdf(round(trace), scaled_smoothed+slow_part)));
                end
                j
            end

            %% Plot jitter spike trace

            % fit quadratic to the data
            x = repmat(jitter_tau, size(shifted_likelihood,1), 1);
            X = [x(:) x(:).^2];
            b = robustfit(X, shifted_likelihood(:));

            cla; hold on
            m = mean(shifted_likelihood);
            s = std(shifted_likelihood);
            errorbar(jitter_tau, m, s)
            plot(jitter_tau, b(1) + b(2) * jitter_tau + b(3) * jitter_tau.^2, 'k')
            hold off

            tau_fisher = -b(3)
            expected_jitter_std = sqrt(1/tau_fisher)
            
            %% Plot
            m_fn = mean(fn_likelihood);
            m_fp = mean(fp_likelihood);
            s_fn = std(fn_likelihood);
            s_fp = std(fp_likelihood);

            % linear fit to each side
            r_fn = robustfit(reshape(repmat((1:20)',1,100),[],1),fn_likelihood(:))
            r_fp = robustfit(reshape(-repmat((1:20)',1,100),[],1),fp_likelihood(:))

            cla; hold on
            l = [fliplr(m_fp) real_likelihood m_fn];
            e = [fliplr(s_fp) 0 s_fn];
            errorbar(-20:20, l, e);
            plot(-20:0, r_fp(1)+r_fp(2)*(-20:0), 'k', ...
                0:20, r_fn(1)+r_fn(2)*(0:20), 'k');
            hold off

            xlabel('\Delta num spikes');
            ylabel('Log likelihood');

            fisher = r_fp(2) - r_fn(2);
            title(sprintf('Fisher information = %d, Var = %d', fisher, 1/fisher))

            tuple.shifted_mean_likelihood = mean(tuple.shifted_likelihood);
            tuple.shifted_tau = jitter_tau;
            tuple.tau_fisher = tau_fisher;
            tuple.tau_std = sqrt(1/tau_fisher);

            tuple.fp_mean_likelihood = mean(tuple.fp_likelihood,1);
            tuple.fp_num = -(1:20);
            tuple.fn_mean_likelihood = mean(fn_likelihood,1);
            tuple.fn_num = 1:20;   
            tuple.spike_count_fisher = r_fp(2) - r_fn(2);
            tuple.spike_count_std = sqrt(1 / tuple.spike_counter_fisher);

            self.insert(tuple)
		end
	end
end
