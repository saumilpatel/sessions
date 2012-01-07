function p = rawToSource(sDb, in)

for i = 1:length(sDb.source)
    p = strrep(in, '/raw', sDb.source{i});
    if ~isempty(strfind(p,'%d.h5'))
        p1 = sprintf(p,0);
    else
        p1 = p;
    end
    if exist(p1, 'file')
        break;
    end
end
p = getGlobalPath(p);
