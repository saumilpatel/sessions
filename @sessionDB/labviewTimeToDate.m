function d = labviewTimeToDate(sDb,t)

days = double(t) / 1000 / 60 / 60 / 24;
d = datestr(days + datenum('01-Jan-1904'));