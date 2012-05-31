%{
aod.TracePreprocessed (imported) # A scan site

->aod.TracePreprocessedSetParam
->aod.Traces
---
trace           : longblob          # The unfiltered trace
t0              : double            # The starting time
fs              : double            # Sampling rate
%}

classdef TracePreprocessed < dj.Relvar
    properties(Constant)
        table = dj.Table('aod.TracePreprocessed');
    end
    
    methods 
        function self = TracePreprocessed(varargin)
            self.restrict(varargin{:})
        end
    
        function makeTuples( this, key )
            % Import a spike set
            
            aodTraces = fetch(aod.Traces(key),'*');

            for i = 1:length(aodTraces)
                tuple = key;
                tuple.cell_num = aodTraces(i).cell_num;
                
                aodTrace = aodTraces(i);
                method = fetch1(aod.TracePreprocessedSetMethod(key), 'preprocessed_method_name');
                
                t0 = aodTrace.t0;
                fs = aodTrace.fs;
                trace = aodTrace.trace;
                
                % Process the trace
                switch (method)
                    case 'raw'
                        
                    case 'ds20'        % Downsample to 20 Hz
                        ds = round(fs / 20);
                        assert(ds > 1);
                        trace = decimate(trace,ds,'fir');
                        fs = fs / ds;
                    case 'ds5'         % Downsample to 5 Hz
                        ds = round(fs / 5);
                        assert(ds > 1);
                        trace = decimate(trace,ds,'fir');
                        fs = fs / ds;
                    case 'pc20'         % Downsample to 5 Hz
                        if ~exist('pc', 'var')
                            dat = cat(2,aodTraces.trace);
                            [c p] = princomp(dat);
                            pc = p(:,1) * c(:,1)';
                        end
                        trace = trace - pc(:,i);
                        ds = round(fs / 20);
                        assert(ds > 1);
                        trace = decimate(trace,ds,'fir');
                        fs = fs / ds;
                    case 'fast_oopsi'   % Run the voegelstein fast oopsi method                
                        if ~exist('pc', 'var')
                            dat = cat(2,aodTraces.trace);
                            [c p] = princomp(dat);
                            pc = p(:,1) * c(:,1)';
                        end

                        trace = trace - pc(:,i);

                        ds = round(fs / 20);
                        dt = 1 / fs;

                        ds_trace = decimate(trace,ds);
                        highPass = 0.1;
        
                        k = hamming(round(1/(dt*ds)/highPass)*2+1);
                        k = k/sum(k);
                        trace = ds_trace - convmirr(ds_trace,k);  %  dF/F where F is low pass
  
                        fs = fs / ds;
                        trace = fast_oopsi(trace, struct('dt',dt * ds));
                    otherwise
                        error('Unknown processing method');
                end
                    
                tuple.t0 = t0;
                tuple.trace = (trace - mean(trace)) / mean(trace);
                tuple.fs = fs;
                
                insert(this,tuple);
            end
        end
    end
end
