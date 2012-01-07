function processSortJobs(n)
% Process spike sorting jobs
%   processSortJobs() runs using four workers
%   processSortJobs(n) uses n workers
%
% AE 2011-11-02

if ~nargin, n = 4; end
matlabpool close force % in case something is still oopen from a crash
matlabpool('open', n)
parfor i = 1:n
    parPopulate(sort.Automatic, sort.Jobs);
end
matlabpool('close')
