%{
aod.PatchingSite (manual) # A scan site
->aod.TraceQuality
---
pipette_x     : double      # The x coordinate of the pipette
pipette_y     : double      # The y coordinate of the pipette
pipette_z     : double      # The z coordinate of the pipette
trace_fs      : double      # The sampling rate of the trace
trace         : longblob    # The trace from the cell
spike_times   : longblob    # Vector of spike times
%}

classdef PatchingSite < dj.Relvar
    properties(Constant)
        table = dj.Table('aod.PatchingSite');
        %popRel = acq.AodScan & acq.SessionsCleanup
    end
    
    properties
        slice = 0;
        vol = [];
        scanKey = [];
    end
    
    methods (Static)
        function mouseClick(hObject, eventdata)
            dat = guidata(hObject);
            this = dat.obj;
            vol = this.vol;
            
            point = get(gca,'CurrentPoint');
            coord = [point(1,1:2) vol.z(this.slice)];           

            set(gcf,'KeyPressFcn', []);
            
            uiresume(gcf);
            
            visualizeTraces(this, coord);
        end
        
        function keyPress (hObject, eventdata)
            dat = guidata(hObject);
            this = dat.obj;
            
            vol = this.vol; %#ok<PROP>

            if isfield(eventdata, 'Key') && strcmp(eventdata.Key,'uparrow') == 1
                this.slice = this.slice + 1;
            elseif isfield(eventdata, 'Key') && strcmp(eventdata.Key,'downarrow') == 1
                this.slice = this.slice - 1;
            end
            
            if this.slice < 1
                this.slice = 1;
            end
            if this.slice > length(vol.z)   %#ok<PROP>
                this.slice = length(vol.z); %#ok<PROP>
            end
            
            dat.obj = this;
            guidata(hObject, dat);
            h = imagesc(vol.x,vol.y,vol(:,:,this.slice)'); %#ok<PROP>
            set(h, 'ButtonDownFcn',@aod.PatchingSite.mouseClick);
            colormap gray
        end
    end
    methods 
        function self = PatchingSite(varargin)
            self.restrict(varargin{:})
        end
        
        function locatePatchingSite( this, scanKey )
            pre_vol = acq.AodVolume & aod.CellPos('scan="Pre"', scanKey);
            assert( count(pre_vol) > 0, 'No prevolume found.  Is the qualityset imported?' );
            assert( count(pre_vol) == 1, 'Only one pre volume sholud be found' );
            vol = getFile(pre_vol);
            
            this.vol = vol;
            this.slice = round(mean(vol.z));
            this.scanKey = scanKey;
            
            handles = struct('obj',this);
            guidata(gcf,handles);
            set(gcf,'KeyPressFcn',@aod.PatchingSite.keyPress);
            aod.PatchingSite.keyPress(gcf,struct);
            uiwait(gcf);
        end

        function visualizeTraces( this, coord )
            % Plot all the traces ranked by distance to cell
            ephys = getFile(acq.AodScan & this.scanKey, 'Temporal');
            cells = fetch(pro(aod.CellPos('scan="Pre"') & this.scanKey, ...
                sprintf('SQRT(POW(cell_center_x - %f,2) + POW(cell_center_y - %f,2) + POW(cell_center_z - %f,2))->dist', ...
                coord(1),coord(2),coord(3))), 'dist');
            cells = dj.struct.sort(cells,'dist');
            traces = fetch(aod.Traces & cells,'*');
            
            ephys_trace = ephys(:,2);
            ephys_time = ephys(:,'t');
            [st si x] = detectSpikes(-ephys_trace, getSamplingRate(ephys));
            
            ds = 20;
            traces_t = 1000 * (1:length(traces(1).trace)) / traces(1).fs;
            traces_t = traces_t(1:ds:end);
            for i = 1:length(traces)
                traces_mat(:,i) = decimate(traces(i).trace,ds);
            end
            
            traces_mat = bsxfun(@minus, traces_mat, mean(traces_mat,1));
            traces_mat = bsxfun(@rdivide, traces_mat, range(traces_mat));
            traces_mat = traces_mat / 3;
            
            plot(traces_t, bsxfun(@plus,traces_mat * 4,0:size(traces_mat,2)-1), ...
                repmat(st, length(traces), 1), bsxfun(@plus,0:length(traces)-1,zeros(length(st),1))', 'k.')
            
        end

        function makeTuples( this, key )
            
            error('Not done yet');
            
            % Import a spike set
            tuple = key;

            asr = getFile(acq.AodScan(key), 'Functional');
            try
                amr = getFile(acq.AodScan(key), 'Motion');
                tuple.num_planes = amr.planes;
            catch
                tuple.num_planes = 0;
            end
            
            tuple.num_cells = size(asr,2);
            insert(this,tuple);
            
            makeTuples(aod.Traces, key, asr);
        end
    end
end
