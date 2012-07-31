%{
aod.ForwardTuning (imported) # A scan site

->aod.TracePreprocess
->stimulation.MultiDimInfo
---
r2                    : double     # The amount of variance explained
preferred_orientation : double     # The preferred orientation
b=null                : longblob   # Tuning curve
p                     : double     # The significance
dof                   : double     # The degrees of freedom
dofps                 : double     # The DoF per sec
regress_cov           : longblog   # The covariance of the regressor
%}

classdef ForwardTuning < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('aod.ForwardTuning');
        popRel = aod.TracePreprocessSet * (acq.AodStimulationLink * stimulation.MultiDimInfo);
    end

    methods 
        function self = ForwardTuning(varargin)
            self.restrict(varargin{:})
        end         
    end
    
    methods(Access=protected)
        function makeTuples( this, key )
            % Import a spike set

            tuple = key;

            [traces cell_num] = fetchn(aod.TracePreprocess & key, 'trace', 'cell_num');
            times = getTimes(aod.TracePreprocess & key);
            traces = cat(2,traces{:});

            [G oris] = aod.ForwardTuning.makeDesignMatrix(times, key);

            disp 'computing responses'
            [B,R2,pF,DoF] = aod.ForwardTuning.regress(traces, G, 0);
            
            tuple.regressor_cov = G'*G;
            % Parse the information into separate cells
            disp (['inserting results for ' num2str(length(cell_num)) ' traces']);
            for i = 1:length(cell_num)
                tuple = key;
                tuple.cell_num = cell_num(i);
                tuple.b = B(:,i);
                tuple.r2 = R2(i);
                tuple.p = pF(i);
                tuple.dof = DoF(i);
                tuple.dofps = DoF(i) / (range(times) / 1000);;
                tuple.regressor_cov = regress_cov;
                [~,idx] = max(tuple.b);
                tuple.preferred_orientation = oris(idx);
                insert(aod.ForwardTuning, tuple);
            end
            
        end       
    end

    methods(Static)
        function [G oris] = makeDesignMatrix(times, key)
            % This method needs an array of stimulus condition numbers and
            % onset/offset times
            
            alpha = @(x,a) (x>0).*x/a/a.*exp(-x/a);  % response shape

            
            trials = fetch(stimulation.StimTrials(key));
            conditions = fetch(stimulation.StimConditions(key),'*');

            oris = unique(arrayfun(@(x) x.orientation, [conditions.condition_info]));
            
            disp 'constructing design matrix...'
            G = zeros(length(times), length(oris), 'single');

            % Select the time constant of the alpha decay
            opt.tau = 1500;
            
            for i = 1:length(trials)
                trial_info = fetch1(stimulation.StimTrials(trials(i)), 'trial_params');
                event = fetch(stimulation.StimTrialEvents(trials(i), 'event_type="showSubStimulus"'),'*');
                onsets = sort([event.event_time]);
                for j = 1:length(onsets)
                    cond = trial_info.conditions(j);
                    onset = onsets(j);
                    ori = conditions(cond).condition_info.orientation;
                    condIdx = find(ori == oris);
                
                    idx = find(times >= onset & times < onset+6*opt.tau);
                    G(idx, condIdx) = G(idx, condIdx) + alpha(times(idx)-onset,opt.tau)';
                end
            end
        end

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
