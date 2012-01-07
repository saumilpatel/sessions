classdef RawPathMap < handle
    % Remaps raw data path task-dependent to a machine-specific location.
    %   file = findFile(RawPathMap, file)
    %   file = toSource(RawPathMap, file)
    %   file = toTemp(RawPathMap, file)
    %
    % AE 2011-10-10
    
    properties
        search = RawPathMap.getSearchPath()
        temp = RawPathMap.getTempPath()
    end
    
    methods
        function self = RawPathMap(varargin)
        end
        
        function outFile = findFile(self, file)
            % Find raw data file using machine-specific search path
            %   file = findFile(RawPathMap, file) searches different
            %   locations for the file and returns the first match. First
            %   the search path (map.search) is used, then the temporary
            %   location (map.temp), and finally at_scratch.
            assert(~isempty(regexp(file, '^(/|\\)raw', 'once')), 'Not a raw data file: %s', file)
            loc = [self.search, {getLocalPath('/at_scratch')}];
            for i = 1:numel(loc)
                outFile = strrep([loc{i}, file(5:end)], '\', '/');
                if exist(sprintf(strrep(outFile, filesep, '/'), 0), 'file')  % sprintf in case of HDF5 family file
                    return
                end
            end
            error('File not found: %s', file)
        end
        
        function file = to(~, file, target)
            % Map /raw to an arbitrary location
            %   file = to(RawPathMap, file, target)
            assert(~isempty(regexp(file, '^(/|\\)raw', 'once')), 'Not a raw data file: %s', file)
            file = strrep([target file(5:end)], '\', '/');
        end
        
        function file = toTemp(self, file)
            % Map /raw to the temporary location (typically on local drive)
            %   file = toTemp(RawPathMap, file)
            assert(~isempty(regexp(file, '^(/|\\)raw', 'once')), 'Not a raw data file: %s', file)
            file = strrep([self.temp file(5:end)], '\', '/');
        end
    end
    
    methods (Static = true, Access = private)
        function search = getSearchPath()
            if exist('rawmap.mat', 'file')
                search = getfield(load('rawmap'), 'search'); %#ok
            else
                search = {'M:', 'N:', 'O:', 'P:', getLocalPath('/at_scratch')};
            end
        end
            
        function temp = getTempPath()
            if exist('rawmap.mat', 'file')
                temp = getfield(load('rawmap'), 'temp'); %#ok
            else
                temp = '/tmp';
            end
        end
    end
end



