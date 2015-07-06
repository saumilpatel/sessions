%{
detect.Sets (imported) # Set of electrodes to detect spikes

-> detect.Params
---
detect_set_path : VARCHAR(255) # folder containing spike files
%}

classdef Sets < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('detect.Sets');
        popRel = detect.Params;
    end
    
    methods 
        function self = Sets(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)        
        function makeTuples(~, key)
            method = fetch1(detect.Params(key) * detect.Methods, 'detect_method_name');
            spikesCb = eval(['@spikes' upper(method(1)) method(2 : end)]);
            spikesFile = 'Sc%d.Htt';
            lfpCb = []; muaCb = []; pathCb = [];
            useTemp = true;
            switch method
                case 'Tetrodes'
                    lfpCb = @extractLfpTetrodes;
                    muaCb = @extractMuaTetrodes;
                    pathCb = @extractPath;
                case 'TetrodesV2'
                    lfpCb = @extractLfpTetrodes;
                    muaCb = @extractMuaTetrodes;
                    pathCb = @extractPath;
                case 'SiliconProbes'
                    % defaults
                case 'SiliconProbesV2'
                    % defaults
                case 'Utah'
                    spikesFile = 'Sc%03u.Hsp';
                case 'MultiChannelProbes'
                    rel = acq.Ephys * pro(acq.EphysTypes, 'array_id') * detect.ChannelGroupMembers;
                    [channels, electrodes] = fetchn(rel & key, ...
                        'channel_num', 'electrode_num', 'ORDER BY electrode_num, channel_num');
                    assert(~isempty(channels), 'No channels found. Channel groups not populated for this array?')
                    electrodes = unique(electrodes);
                    channels = reshape(channels, [], numel(electrodes))';
                    spikesCb = @(sourceFile, spikesFile) spikesMultiChannelProbes(sourceFile, spikesFile, channels);
%                     lfpCb = @extractLfpMultiChannelProbes;
%                     muaCb = @extractMuaMultiChannelProbes;
%                     pathCb = @extractPath;
            end

            % if not in toolchain mode, don't extract LFP
            if ~fetch1(detect.Params(key), 'use_toolchain')
                lfpCb = [];
                muaCb = [];
                pathCb = [];
                useTemp = false;
            end

            processSet(key, spikesCb, spikesFile, lfpCb, muaCb, pathCb, useTemp);
        end
    end
end
