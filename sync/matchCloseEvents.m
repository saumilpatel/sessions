function [a b] = matchCloseEvents(a_in, b_in, varargin)

params.maxError = 5;
params.minFraction = 0.95;

a = [];
b = [];

a_in = sort(a_in);
b_in = sort(b_in);

b_point = 1;

multiple_hits = 0;
missed = 0;
for i = 1:length(a_in)
    idx = [];
    for j = b_point:length(b_in)
        if abs(b_in(j) - a_in(i)) < params.maxError % hit
            idx = j;
            b_point = j+1;
            break;
        elseif (b_in(j) - a_in(i)) > params.maxError % passed
            idx = [];
            b_point = j;
            break;
        end
    end
    
    if isempty(idx)
        missed = missed + 1;
    elseif ((b_point + idx) <= length(b_in)) && (abs(b_in(b_point + idx) - a_in(i)) < params.maxError)
        multiple_hits = multiple_hits + 1;
    elseif length(idx) == 1
        a = [a a_in(i)]; %#ok<AGROW>
        b = [b b_in(idx)]; %#ok<AGROW>
    end
end

%assert(length(a) / length(a_in) > params.minFraction && ...
%    length(b) / length(b_in) > params.minFraction, ...
%    'Failed to match too many events');
disp(['Missed ' num2str(missed) ' matches']);
disp(['Matched ' num2str(multiple_hits) ' events to two events']);
