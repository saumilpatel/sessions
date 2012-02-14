function manualSortDone(sortKey, electrodeNum, comment)
% Flag manual spike sorting step as done
%   manualSortDone(sortKey, electrodeNum, comment)
%
% AE 2012-02-09

tuple = sortKey;
tuple.electrode_num = electrodeNum;
if nargin > 2
    tuple.manual_sort_comment = comment;
end
sortMethod = fetch1(sort.Params(tuple) * sort.Methods, 'sort_method_name');
switch sortMethod
    case 'TetrodesMoG'
        insert(sort.TetrodesMoGManual, tuple)
        fprintf('Marked electrode %d as done\n', electrodeNum)
    otherwise
        error('Not implemented for sort method %s!', sortMethod)
end
