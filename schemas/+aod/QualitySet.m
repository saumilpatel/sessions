%{
aod.QualitySet (imported) # A scan site

->aod.TraceSet
---
%}

classdef QualitySet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('aod.QualitySet');
        popRel = aod.TraceSet
    end
    
    methods 
        function self = QualitySet(varargin)
            self.restrict(varargin{:})
        end
    
        function makeTuples( this, key )
            % Import a spike set
            tuple = key;
            
            pre_vol = pro(acq.AodScan & key, (acq.AodScan * pro(acq.AodVolume)) & 'aod_volume_start_time <  aod_scan_start_time', 'MAX(aod_volume_start_time)->aod_volume_start_time');
            post_vol = pro(acq.AodScan & key, (acq.AodScan * pro(acq.AodVolume)) & '(aod_volume_start_time >  aod_scan_stop_time)', 'MIN(aod_volume_start_time)->aod_volume_start_time');
            
            pre = fetch(acq.AodVolume & pre_vol, '*');
            post = fetch(acq.AodVolume(post_vol), '*');
            
            as = fetch(acq.AodScan(key), '*');

            if ~isempty(pre)
                disp('Found pre scan');

                %% Checks over the volumes
                if (as.aod_scan_start_time - pre.aod_volume_start_time) > (6 * 60000)
                    warning('Pre scan volume stale')
                end

                if pre.x_coordinate == 0 || pre.y_coordinate == 0 || pre.z_coordinate == 0
                    warning('No coordinate in the pre scan');
                    pre_dist = NaN;
                else
                    pre_dist = sqrt((pre.x_coordinate - as.x_coordinate).^2 + (pre.y_coordinate - as.y_coordinate).^2 + ...
                        (pre.z_coordinate - as.z_coordinate).^2);
                end

                if pre_dist > 10
                    warning('Pre scan too far away')
                end

                % Process the cell position in the preceding volume
                [original_coordinates cell_coordinates] = ...
                    aod.QualitySet.processCellPositions(key, pre_vol);
                cellPosPre = fetch(acq.AodVolume(pre_vol) * aod.Traces(key));
                cellPosPre = dj.struct.sort(cellPosPre,'cell_num');
                for i = 1:length(cellPosPre)
                    idx = cellPosPre(i).cell_num;
                    cellPosPre(idx).cell_center_x = cell_coordinates(idx,1);
                    cellPosPre(idx).cell_center_y = cell_coordinates(idx,2);
                    cellPosPre(idx).cell_center_z = cell_coordinates(idx,3);
                    cellPosPre(idx).cell_location_x = original_coordinates(idx,1);
                    cellPosPre(idx).cell_location_y = original_coordinates(idx,2);
                    cellPosPre(idx).cell_location_z = original_coordinates(idx,3);
                    cellPosPre(idx).scan = 'Pre';
                end
            end

            if ~isempty(post)
                disp('Found post scan');

                if (post.aod_volume_start_time - as.aod_scan_stop_time) > (4 * 60000)
                    warning('Post scan volume stale')
                end
                
                if post.x_coordinate == 0 || post.y_coordinate == 0 || post.z_coordinate == 0
                    warning('No coordinate in the pre scan');
                    post_dist = NaN;
                else
                    post_dist = sqrt((post.x_coordinate - as.x_coordinate).^2 + (post.y_coordinate - as.y_coordinate).^2 + ...
                        (post.z_coordinate - as.z_coordinate).^2);
                end
                
                if post_dist > 10
                    warning('Post scan too far away')
                end

                % Process the cell position in the preceding volume
                [original_coordinates cell_coordinates] = ...
                    aod.QualitySet.processCellPositions(key, post_vol);
                cellPosPost = fetch(acq.AodVolume(post_vol) * aod.Traces(key));
                cellPosPost = dj.struct.sort(cellPosPost,'cell_num');
                for i = 1:length(cellPosPost)
                    idx = cellPosPost(i).cell_num;
                    cellPosPost(idx).cell_center_x = cell_coordinates(idx,1);
                    cellPosPost(idx).cell_center_y = cell_coordinates(idx,2);
                    cellPosPost(idx).cell_center_z = cell_coordinates(idx,3);
                    cellPosPost(idx).cell_location_x = original_coordinates(idx,1);
                    cellPosPost(idx).cell_location_y = original_coordinates(idx,2);
                    cellPosPost(idx).cell_location_z = original_coordinates(idx,3);
                    cellPosPost(idx).scan = 'Post';
                end
            end

            t = fetch(aod.Traces(key));
            t = dj.struct.sort(t,'cell_num');
            for i = 1:length(t)
                traceQualityTuple(i) = dj.struct.join(dj.struct.join(key,t(i)), ...
                    struct('pre_position_distance',1e6,'post_position_distance',1e6,'snr',0));
                if exist('cellPosPre','var')
                    traceQualityTuple(i).pre_position_distance = sqrt( ...
                        (cellPosPre(i).cell_center_x - cellPosPre(i).cell_location_x).^2 + ...
                        (cellPosPre(i).cell_center_y - cellPosPre(i).cell_location_y).^2 + ...
                        (cellPosPre(i).cell_center_z - cellPosPre(i).cell_location_z).^2 ...
                        );
                end
                if exist('cellPosPost','var')
                    traceQualityTuple(i).post_position_distance = sqrt( ...
                        (cellPosPost(i).cell_center_x - cellPosPost(i).cell_location_x).^2 + ...
                        (cellPosPost(i).cell_center_y - cellPosPost(i).cell_location_y).^2 + ...
                        (cellPosPost(i).cell_center_z - cellPosPost(i).cell_location_z).^2 ...
                        );
                end
            end

            insert(this,tuple);
            insert(aod.TraceQuality, traceQualityTuple);
            if exist('cellPosPost','var'), insert(aod.CellPos, cellPosPost); end
            if exist('cellPosPre','var'), insert(aod.CellPos, cellPosPre); end
        end
    end

    methods (Static)
        function [original_coordinates cell_coordinates cellPlanes] = processCellPositions(traceSet, volumeScan)
            % Get the location of cells in the volume relative to where the
            % cell center was
            
            asr = getFile(acq.AodScan(traceSet));
            coordinates = asr.coordinates;
            
            vol = getFile(acq.AodVolume(volumeScan));
            dat = vol(:,:,:);
            x = vol.x;
            y = vol.y;
            z = vol.z;
            
            % Create a segmenter
            seg = aod.Segmenter(dat, x, y, z);
            for i = 1:size(coordinates,1)
                seg = addClick(seg, coordinates(i,1), coordinates(i,2), coordinates(i,3));
                
                [p1 p2 p3] = originalCutOut(seg, i);
                cellPlanes(i).clicked_p1 = p1; %#ok<*AGROW>
                cellPlanes(i).clicked_p2 = p2;
                cellPlanes(i).clicked_p3 = p3;

                subplot(231); imagesc(p1'); colormap gray
                subplot(232); imagesc(p2'); colormap gray
                subplot(233); imagesc(p3'); colormap gray

                [p1 p2 p3] = centeredCutOut(seg, i);
                cellPlanes(i).centered_p1 = p1;
                cellPlanes(i).centered_p2 = p2;
                cellPlanes(i).centered_p3 = p3;

                subplot(234); imagesc(p1'); colormap gray
                subplot(235); imagesc(p2'); colormap gray
                subplot(236); imagesc(p3'); colormap gray
                
                drawnow
                pause(0.5)
            end
            
            original_coordinates = seg.click_coordinates;
            cell_coordinates = seg.centered_coordinates;
        end
    end

end
