function d = labviewTimeToDate(t, varargin)
% Convert LabView timestamp into a date string.
%   d = labviewTimeToDate(t, [format]) converts the LabView timestamp t
%   into a date string. The optional argument format specifies the format
%   of the string as in DATESTR.

days = double(t) / 1000 / 60 / 60 / 24;
d = datestr(days + datenum('01-Jan-1904'), varargin{:});
