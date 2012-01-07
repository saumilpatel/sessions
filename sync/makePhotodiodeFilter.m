function win = makePhotodiodeFilter(Fs, refresh, nPeaks, sigma)
% Create matching filter for photodiode peak extraction.
%   win = makePhotodiodeFilter(Fs, refresh, nPeaks, sigma) creates a filter
%   for peak detection on the photodiode signal. The filter has zero phase
%   delay, so no compensation for filter delay is necessary (under the
%   assumption that the signal is sufficiently periodic within nPeaks
%   number of peaks).
%
%   Input arguments: 
%       Fs      -- sampling rate
%       refresh -- monitor refresh rate
%       nPeaks  -- number of peaks to use for the match filter
%       sigma   -- width of the Gaussian around each peak (1 = period)
%
% AE 2011-04-14

k = Fs / refresh;
n = k * nPeaks + 1;
mu = 1:nPeaks;
t = bsxfun(@minus, linspace(0, nPeaks, n), mu');
win = sum(exp(-t.^2 / sigma^2), 1) .* (1 - linspace(0, 1, n));
win = win - mean(win);
