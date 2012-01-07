function t = dateToLabviewTime(d, varargin)
% Convert date string into LabView timestamp.
%   d = labviewTimeToDate(t, [format]) converts the date string d into a
%   LabView timestamp t. The optional input specifies the format of the
%   date string.

days = datenum(d, varargin{:}) - datenum('01-Jan-1904');
t = uint64(days * 24 * 60 * 60 * 1000);
