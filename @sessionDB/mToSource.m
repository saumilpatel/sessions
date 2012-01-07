function p = mToSource(sDb, in)

for i = 1:length(sDb.source)
    p = strrep(in, 'm:', sDb.source{i});
    p = strrep(p, 'M:', sDb.source{i});
    if exist([p '0.h5'], 'file')
        break;
    end
end
p = getGlobalPath(p);
