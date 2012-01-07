function br = getEphysFile(sDb, ephys, varargin)

for i = 1:length(ephys)
    fn = [getLocalPath(rawToSource(sDb, ephys(i).ephys_path))];
    br(i) = baseReader(fn,varargin{:});
end
