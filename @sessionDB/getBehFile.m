function br = getBehFile(sDb, beh, varargin)

for i = 1:length(beh)
    fn = [getLocalPath(rawToSource(sDb, beh(i).beh_path))];
    br(i) = baseReader(fn,varargin{:});
end
