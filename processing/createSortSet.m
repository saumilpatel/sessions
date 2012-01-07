function sortKeys = createSortSet(detectKeys, sortMethod)
% Create clustering sets for given detection set.
%   sortKeys = createSortSet(detectKeys) creates clustering sets for all
%   detectKeys. The default_sort_method from EphysTypes is used.
%
%   sortKeys = createSortSet(detectKeys, sortMethod) creates clustering
%   sets with a non-default sort method.
%
% AE 2011-11-11

sortKeys = fetch(detect.Params(detectKeys));
if nargin < 2 || isempty(sortMethod)
    [sortKeys.sort_method_num] = deal(fetchn(acq.Ephys(detectKeys) * acq.EphysTypes, 'default_sort_method'));
else
    [sortKeys.sort_method_num] = deal(fetch1(sort.Methods(struct('sort_method_name', sortMethod)), 'sort_method_num'));
end
insert(sort.Params, sortKeys);
