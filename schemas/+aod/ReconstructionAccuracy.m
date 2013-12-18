%{
aod.ReconstructionAccuracy (computed) # my newest table
-> aod.Spikes
-> aod.Traces
-----
trace      : longblob # reconstructed trace
trace_t    : longblob # the trace time
r          : double   # correlation coefficient
ll         : double   # the likelihood of the spike train
gain       : double   # the gain to convert to firing rate
skewness   : double   # the skewness fo the trace
iqr        : double   # interquartile range (in delta F / F)
%}

classdef ReconstructionAccuracy < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('aod.ReconstructionAccuracy')
        popRel = aod.Spikes*aod.Traces
    end
    
    methods
        function self = ReconstructionAccuracy(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            
            tuple = key;
            
            pc = false;
            if pc
                traces = fetchn(aod.Traces & rmfield(key, 'cell_num'), 'trace');
                traces = cat(2,traces{:});
                [c p] = princomp(traces);
                trace = fetch(aod.Traces * aod.Spikes & key, '*');
                trace.trace = trace.trace - p(:,1) * c(trace.cell_num,1);
            else
                trace = fetch(aod.Traces * aod.Spikes & key, '*');
            end
            
            ds = round(trace.fs / 100);
            dt = 1 / trace.fs;
            ds_trace = decimate(trace.trace,ds);
            highPass = 0.1;
            k = hamming(round(1/(dt*ds)/highPass)*2+1);
            k = k/sum(k);
            filtered_trace = ds_trace - convmirr(ds_trace,k);  %  dF/F where F is low pass
            fs = trace.fs / ds;
            dt = 1 / fs;

            gam = 1 - dt / 2;
            lam = 10;
            sigma = sqrt(var(diff(filtered_trace)) / 2 / ds);
            
            fr = fast_oopsi(filtered_trace, ...
                struct('dt',dt,'est_lam',0,'est_gam',0,'fast_iter_max',0),...
                struct('gam',gam,'lam',lam,'sig',sigma));
            
            tuple.trace = fr;
            tuple.trace_t = trace.t0 + (0:length(fr)-1) / fs * 1000;
            [tuple.ll tuple.gain] = aod.PatchedCellOopsiSweep.scoreReconstruction(fr, fs, trace);
            [tuple.r]= aod.PatchedCellOopsiSweep.scoreCorrelation(fr, fs, trace);

            tuple.skewness = skewness(filtered_trace);
            tuple.iqr = diff(quantile(filtered_trace,[0.25 0.99])) / ...
                diff(quantile(filtered_trace,[0.25 0.75]));
            
           self.insert(tuple)
        end
    end
end
