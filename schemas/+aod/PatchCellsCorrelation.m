%{
aod.PatchCellsCorrelation (computed) # my newest table
-> aod.TraceSet
-> aod.TracePreprocessSet
-> aod.Spikes
-----
taus                  : longblob      # Time constants checked
r2                    : longblob      # Array of R2 values
best_cell             : int unsigned  # The index of the best cell
best_tau              : int unsigned  # The tau of the best cell in ms
best_r2               : double        # The R2 of the best cell
%}

classdef PatchCellsCorrelation < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('aod.PatchCellsCorrelation')
		popRel = aod.Spikes * aod.TracePreprocessSet & 'preprocess_method_num > 1'; %aod.TracePreprocessMethod('preprocess_method_name="hp20"'));
	end

	methods
		function self = PatchCellsCorrelation(varargin)
			self.restrict(varargin)
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
            
            tuple = key;
            tuple.taus = 100:200:5000;
                       
            % Get the patch data          
            patchData = fetch(aod.Spikes & key,'*');
            traceData = fetch(aod.TracePreprocess & rmfield(key,'cell_num'),'*');
            traces = cat(2,traceData.trace);

            tuple.r2 = zeros(length(traceData),length(tuple.taus));

            fs = traceData(1).fs;
            t = traceData(1).t0 + 1000*(0:size(traces,1)-1) / traceData(1).fs;
            
            for k = 1:length(tuple.taus)
                
                % Work up predicted trace based on spike times
                r = @(t) (exp(-(t .* (t > 0)) / tuple.taus(k)) .* (t > 0));
                predicted = zeros(size(t));
                for j = 1:length(patchData.times)
                    predicted = predicted + r(t - patchData.times(j));
                end
                
                % Filter the predicted trace the same way
                ds = 1;
                highPass = 0.1;
                dt = 1 / fs;
                h = hamming(round(1/(dt*ds)/highPass)*2+1);
                h = h/sum(h);
                predicted = (predicted' - convmirr(predicted',h))';  %  dF/F where F is low pass
                
                % Regress all the traces at this time constant
                %[~,R2] = aod.PatchCellsCorrelation.regress(traces, predicted', 0);
                [~,R2] = aod.PatchCellsCorrelation.regress(bsxfun(@minus,traces,mean(traces)), predicted', 0);
                
                tuple.r2(:,k) = R2';
                
                plot(tuple.taus,tuple.r2);
                drawnow;
            end
            
            % Find the best combination of cell and tau for this
            [tuple.best_r2,best_idx] = max(tuple.r2(:));
            [tuple.best_cell tuple.best_tau] = ind2sub(size(tuple.r2),best_idx);
            tuple.best_tau = tuple.taus(tuple.best_tau);
            
            plot(tuple.taus,tuple.r2)
            drawnow

			self.insert(tuple)
        end
    end
    
    methods (Static)
        function [B, R2, Fp, dof] = regress(X, G, addDoF)
            % Linear regression
            %
            % INPUTS:
            %   X      TxN matrix of signals, where T is the # samples and N is # of signals
            %   G      TxK matrix of predictors where K is the number of modeled predictors
            %   addDoF additional degrees of freedom that are not included in the
            %          design matrix, e.g. when multiple design matrices
            %
            % OUTPUTS:
            %   B    regression cofficients of the model predictors.
            %   R2   real-valued relative response amplitude, e.g. dF/F
            %   Fp   p-value of each predictor computed from t-distribution
            %   dof  degrees of freedom in residual based on autocorrelation
            
            assert(size(G,1)==size(X,1))
            assert(isreal(X))
            
            B = (G/(G'*G))'*X;              % regression coefficients
            R2 = sum(X.^2);                 % initial variance
            xf = abs(fft(X));               % power spectrum
            dof = sum(xf).^2./sum(xf.^2);   % degrees of freedom in original signal
            X = X - G*B;                    % residual
            R2 = 1-sum(X.^2)./R2;           % R-squared
            dof1 = size(B,1)+addDoF;        % degrees of freedom in model
            Fp = 1-fcdf(R2.*dof/dof1, dof1, dof);   % p-value of the F distribution
        end
	end
end
