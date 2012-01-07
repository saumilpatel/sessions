function genRunFile(n)
fid = fopen(sprintf('run%d', n), 'w');
for i = 1:n
    fprintf(fid, '%03d\n', i);
end
fclose(fid)

