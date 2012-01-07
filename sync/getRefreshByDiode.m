function refresh = getRefreshByDiode(x, Fs, refresh, varargin)
% Get high precision estimate of refresh rate using power spectrum.
%   refresh = getRefreshByDiode(x, Fs, refresh) computes the monitor
%   refresh rate from the photodiode signal x. Fs is the sampling rate of x
%   and refresh is an approximate guess for the refresh rate.
%
% Last update: AE 2011-04-14
% Original: % AE 2008-01-07

params.nFft = 2^22;
params.nHarmonics = 10;
params.guessPrecision = 0.05;
params = parseVarArgs(params,varargin{:});

% Detect the first n harmonics to get a decent estimate of the refresh rate
spectrum = abs(fft(x,params.nFft));
refresh(params.nHarmonics) = 0;
range = 1 + [-1 1] * params.guessPrecision;
for i = 1:params.nHarmonics
    b = round(params.nFft / Fs * refresh(1) * i * range);
    [foo, ndx] = max(spectrum(b(1):b(2))); %#ok<ASGLU>
    refresh(i) = (ndx + b(1) - 1) / params.nFft * Fs / i;
end
refresh = mean(refresh);
