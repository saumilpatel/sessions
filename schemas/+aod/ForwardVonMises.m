%{
aod.ForwardVonMises (computed) # A scan site

->aod.ForwardTuning
---
von_r2    : double   # fraction of variance explained (after gaussinization)
von_fp    : double   # p-value of F-test (after gaussinization)
sharpness : double   # tuning sharpness
pref_dir  : double   # (radians) preferred direction
peak_amp1 : double   # dF/F at preferred direction
peak_amp2 : double   # dF/F at opposite direction
von_base  : double   # dF/F base
%}

classdef ForwardVonMises < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('aod.ForwardVonMises');
        popRel = aod.ForwardTuning;
    end
    
    methods
        function self = ForwardVonMises(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access=protected)
        function makeTuples( this, key )
            % Import a spike set
            
            tuple = key;
            
            ft = fetch(aod.ForwardTuning & key, '*');
            
            conditions = fetch(stimulation.StimConditions & acq.AodStimulationLink(key),'*');
            phi = unique(arrayfun(@(x) x.orientation, [conditions.condition_info]));
            
            % Only supports direction tuning
            if max(phi) <= 180, return, end
            
            von = fit(trove.VonMises2, ft.b);
            F = von.compute(von.phi);  % fitted tuning curves
            C = ft.regress_cov^0.5;
            rv = sum((C*(ft.b'-F)').^2)./sum((C*ft.b).^2);  % fraction increase in variance due to fit
            R2 = max(0,1-rv)'.*ft.r2(:);   % update R2 for the fit
            vonDoF = 5;   % degrees of freedom in the von Mises curve
            Fp = 1-fcdf(ft.r2.*(ft.dof-vonDoF)/vonDoF, vonDoF, (ft.dof-vonDoF));   % p-value of the F distribution
            
            tuple.von_r2    = R2;
            tuple.von_fp    = Fp;
            tuple.pref_dir  = von.w(:,5);
            tuple.sharpness = von.w(:,4);
            tuple.peak_amp1 = von.w(:,2);
            tuple.peak_amp2 = von.w(:,3);
            tuple.von_base  = von.w(:,1);
            
            insert(aod.ForwardVonMises, tuple);
        end
    end
end
