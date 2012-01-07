function populateSortAutomatic(waitTime)

pause(waitTime) % make sure they don't all start at the same time
addpath /home/toliaslab/libraries/matlab
run /home/toliaslab/users/alex/projects/acquisition/setPath.m
parPopulate(sort.Automatic, sort.Jobs)

