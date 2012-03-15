function [x,y] = matchEvents(x,y,varargin)
% AE 2008-01-08

params.tolerance = 20;
params.segLen = 200;
params.maxInitShift = 10;     % How much can the two vectors be misaligned at the beginning?
params.matchTolerance = 0.05;  % Allow events to be misplaced by 5% of frame rate
params.maxDeleteFrac = 0.05;   % Throw error if more than 5% deleted
params = parseVarArgs(params,varargin{:});

nx = length(x);
ny = length(y);
seg = 3:min([params.segLen+2,length(x),length(y)]);

% Make sure beginning is correct. Compute regression of the first few values and
% check if residuals are sufficiently small. If not, the beginnings don't match
b = myrobustfit(x(seg),y(seg));
r = b(1) + b(2) * x(seg) - y(seg);
if max(abs(r)) > params.tolerance
    % Find index offset by shifting a short segment of one signal over the other
    % and comparing inter-event interval times
    dx = diff(x);
    dy = diff(y);
    ndx = bsxfun(@plus,seg',0:min(nx-params.segLen-2,params.maxInitShift)-1);
    errX = mean(abs(bsxfun(@minus,dx(ndx),dy(seg))));
    [valX,offsetX] = min(errX);
    ndx = bsxfun(@plus,seg',0:min(ny-params.segLen-2,params.maxInitShift)-1);
    errY = mean(abs(bsxfun(@minus,dx(seg),dy(ndx))));
    [valY,offsetY] = min(errY);
    if valX < valY
        offsetY = 1;
    else
        offsetX = 1;
    end
    % Compute regression using the offset that produces the minimal error in
    % inter-event interval times
    b = myrobustfit(x(seg+offsetX-1),y(seg+offsetY-1));
    r = b(1) + b(2) * x(seg+offsetX-1) - y(seg+offsetY-1);
    if max(abs(r)) > params.tolerance
        error('matchEvents:beginOffsetError', ...
              ['Could not determine index offset at the beginning of the ', ...
               'sequence!'])
    else
        x = x(offsetX:end); 
        nx = length(x);
        y = y(offsetY:end);
        ny = length(y);
    end
end

% Now convert using initial regression parameters and try to match all existing
% events
[nx ny]
bx = x;
by = y;
n = params.segLen;
while n < min(nx,ny)
    % Use the current estimate of the regression parameters to convert a segment
    % twice as long as the last one
    z = b(1) + b(2) * x(1:min(end,2*n));
    index = interp1(y,1:ny,z,'linear','extrap');
    
    % Make sure that not two timestamps in x get matched to the same
    % timestamp in y. We had this problem arising when Psychtoolbox went
    % from high-precision time-stamping to low-precision (for unknown
    % reasons). It would then sometimes report two consecutive buffer swaps
    % with almost the exact same timestamp.
    doublet = find(diff(round(index)) == 0);
    if ~isempty(doublet)
        x(doublet+1) = [];
        index(doublet+1) = [];
        warning('matchEvents:doubletInX', ...
            ['Duplicate timestamp detected. This can happen when PTB goes '...
             'into low-precision timestamping mode. Check your timestamps '...
             'near %d!'],x(doublet(1)))
    end
    
    % find matched events
    offsets = mod(index + params.matchTolerance,1) - params.matchTolerance;
    % make sure index is within [0.5 ny+0.5] to prevent over-extrapolation
    matchedX = offsets < params.matchTolerance & index > 0.5 & index < ny + 0.5;
    [foo,unmatchedY] = setdiff(1:max(round(index(matchedX))), ...
                               round(index(matchedX)));
    x(~matchedX) = [];
    y(unmatchedY) = [];
    ny = length(y);
    % in case y has more events than can be found in x, we have to stop here
    if sum(matchedX) == n
        y = y(1:n);
        break
    end
    n = sum(matchedX);
    b = myrobustfit(x(1:n),y(1:n));
end
x(n+1:end) = [];
y(n+1:end) = [];

% since above is modulo-based we might still have missed some unmatched
% events. Thus, test residuals
resid = b(1) + b(2)*x - y;
x(abs(resid) > 5*std(resid)) = [];
y(abs(resid) > 5*std(resid)) = [];

% Make sure we didn't delete too many events
if length(x) / nx < 1-params.maxDeleteFrac || length(y) / ny < 1-params.maxDeleteFrac
    error('matchEvents:excessiveDeleting', ...
        'Matching of events failed. More than %d%% events were deleted. Check your timing!', ...
        params.maxDeleteFrac * 100);
end
