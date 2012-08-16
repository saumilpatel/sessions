function genConditionalRunFile(n, condition)

fid = fopen(sprintf('run%d', n), 'w');
for i = 1:n
    fprintf(fid, '%d, %s\n', i, condition);
end
fclose(fid);
