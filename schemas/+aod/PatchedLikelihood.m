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

classdef PatchedLikelihood < dj.Relvar & dj.AutoPopulate

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

            tau = 500;
            shuffles = 500;

            tuple = key;

            ts = fetch(aod.TracePreprocessSet & key & 'preprocess_method_num=1');

            %% Process it
            dat = fetch(aod.Traces & ts, '*');
            times = getTimes(aod.TracePreprocess & ts & 'preprocess_method_num=1');

            cell_num = fetch1(aod.PatchedCell & ts, 'cell_num');

            m = arrayfun(@(x) mean(x.trace), dat);
            v = arrayfun(@(x) var(diff(x.trace))/2, dat);

            b = robustfit(m,v);

            % Convert to approximate photon counts
            traces_calibrated = (cat(2,dat.trace) + b(1) / b(2)) / b(2);
            m = mean(traces_calibrated); v = var(diff(traces_calibrated,[],1))/2;
            plot(m,v,'.'); refline
            drawnow

            % Get the spike times
            sp = fetch(aod.Spikes & ts, '*');



            %% Compute best amplitude scale
            scales = logspace(-1,2,40);
            binned = hist(sp.times, times);
            smoothed = conv(binned,exp(-(times - times(1)) / tau));
            smoothed(length(times)+1:end) = [];
            smoothed = smoothed';

            for i = 1:length(scales)
                scaled_smoothed = smoothed*scales(i);

                trace = traces_calibrated(:,cell_num);
                trace_resid = trace - scaled_smoothed;
                slow_part = convmirr(trace_resid, hamming(1000) / sum(hamming(1000)));
                scale_likelihood(i) = sum(log(poisspdf(round(trace), scaled_smoothed+slow_part)));
            end
            
            [~,idx] = max(scale_likelihood);
            scale = scales(idx);

            %% Compute data likelihood for real spikes            
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

            jitter_tau = -500:50:500;
            output_len = 0;
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
                if mod(i,10) == 0
                    fprintf(repmat('\b',1,output_len))
                    output_len = fprintf('Jittering %d/%d spike',i,length(sp.times));
                end
            end
            fprintf('\n');
            %% Compute data likelihood for false negatives
            
            output_len = 0;
            for j = 1:10
                for i = 1:shuffles
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
                fprintf(repmat('\b',1,output_len))
                output_len = fprintf('Testing false negative %d/%d spike',j,20);
            end
            fprintf('\n');
            %% Compute data likelihood for false positives
            % (by testing likelihoood with spikes removed)

            output_len = 0;
            for j = 1:10
                for i = 1:length(sp.times)
                    fake_times = sp.times;
                    if j == 1
                        fake_times(i) = [];
                    else
                        idx = randperm(length(sp.times)); idx(j+1:end) = [];
                        fake_times(idx) = [];
                    end
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
                fprintf(repmat('\b',1,output_len))
                output_len = fprintf('Testing false positive %d/%d spikes',j,20);
            end
            fprintf('\n');

            %% Plot jitter spike trace
            figure(2);
            % fit quadratic to the data
            x = repmat(jitter_tau, size(tuple.shifted_likelihood,1), 1);
            X = [x(:) x(:).^2];
            b = robustfit(X, tuple.shifted_likelihood(:));

            cla; hold on
            m = mean(tuple.shifted_likelihood);
            s = std(tuple.shifted_likelihood);
            errorbar(jitter_tau, m, s)
            plot(jitter_tau, b(1) + b(2) * jitter_tau + b(3) * jitter_tau.^2, 'k')
            hold off
            drawnow

            tau_fisher = -b(3)
            expected_jitter_std = sqrt(1/tau_fisher)
            
            %% Plot
            figure(3);
            m_fn = mean(tuple.fn_likelihood,1);
            m_fp = mean(tuple.fp_likelihood,1);
            s_fn = std(tuple.fn_likelihood,[],1);
            s_fp = std(tuple.fp_likelihood,[],1);

            % linear fit to each side
            r_fn = robustfit(reshape(repmat((1:size(tuple.fn_likelihood,2)),size(tuple.fn_likelihood,1),1),[],1),tuple.fn_likelihood(:))
            r_fp = robustfit(reshape(-repmat((1:size(tuple.fp_likelihood,2)),size(tuple.fp_likelihood,1),1),[],1),tuple.fp_likelihood(:))
% 
%             cla; hold on
%             l = [fliplr(m_fp) tuple.real_likelihood m_fn];
%             e = [fliplr(s_fp) 0 s_fn];
%             errorbar(-20:20, l, e);
%             plot(-20:0, r_fp(1)+r_fp(2)*(-20:0), 'k', ...
%                 0:20, r_fn(1)+r_fn(2)*(0:20), 'k');
%             hold off
% 
%             xlabel('\Delta num spikes');
%             ylabel('Log likelihood');
%             ylim('auto');
%             xlim('auto')
%             fisher = r_fp(2) - r_fn(2);
%             title(sprintf('Fisher information = %d, Var = %d', fisher, 1/fisher))
%             drawnow

            %% Store result
            tuple.shifted_mean_likelihood = mean(tuple.shifted_likelihood);
            tuple.shifted_tau = jitter_tau;
            tuple.tau_fisher = tau_fisher;
            tuple.tau_std = sqrt(1/tau_fisher);

            tuple.fp_mean_likelihood = mean(tuple.fp_likelihood,1);
            tuple.fp_num = -(1:20);
            tuple.fn_mean_likelihood = mean(tuple.fn_likelihood,1);
            tuple.fn_num = 1:20;   
            tuple.spike_count_fisher = r_fp(2) - r_fn(2);
            tuple.spike_count_std = sqrt(1 / tuple.spike_count_fisher);

            self.insert(tuple)
		end
	end
end
