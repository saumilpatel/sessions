%{
aod.TracePreprocess (imported) # A scan site

->aod.TracePreprocessSet
->aod.Traces
---
trace           : longblob          # The unfiltered trace
t0              : double            # The starting time
fs              : double            # Sampling rate
%}

classdef TracePreprocess < dj.Relvar
    properties(Constant)
        table = dj.Table('aod.TracePreprocess');
    end
    
    methods 
        function self = TracePreprocess(varargin)
            self.restrict(varargin{:})
        end
        
        function times = getTimes( this )
            % Get the times for the selected traces, ensuring they are
            % identical
            
            assert(count(this) >= 1, 'No traces selected');

            [t0 fs] = fetchn(this, 't0', 'fs');
            assert(unique(t0) == t0(1) && unique(fs) == fs(1), 'Traces with different times selected');
            t0 = unique(t0);
            fs = unique(fs);
            keys = fetch(this);
            trace = fetch1(this & keys(1), 'trace');
            
            times = t0 + (0:length(trace)-1) * 1000 / fs;
        end
    end
    
    methods(Access=protected)
        function makeTuples( this, key )
            % Import a spike set
            
            
            aodTraces = fetch(aod.Traces(key),'*');

            for i = 1:length(aodTraces)
                tuple = key;
                tuple.cell_num = aodTraces(i).cell_num;
                
                aodTrace = aodTraces(i);
                method = fetch1(aod.TracePreprocessMethod(key), 'preprocess_method_name');
                
                t0 = aodTrace.t0;
                fs = aodTrace.fs;
                trace = aodTrace.trace;
                
                f0_offset =  mean(trace);
                f0_scale = mean(trace);
                
                % Process the trace
                switch (method)
                    case 'raw'
                        
                    case 'hp20'
                        ds = round(fs / 20);
                        ds_trace = decimate(trace,ds,'fir');
                        highPass = 0.1;
                        dt = 1 / fs;
                        k = hamming(round(1/(dt*ds)/highPass)*2+1);
                        k = k/sum(k);
                        trace = ds_trace - convmirr(ds_trace,k);  %  dF/F where F is low pass
                        
                        f0_offset = 0;

                        assert(ds > 1);
                        fs = fs / ds;                        
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
                tuple.trace = (trace - f0_offset) / f0_scale;
                tuple.fs = fs;
                
                insert(this,tuple);
            end
        end
    end
end
