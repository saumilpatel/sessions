function b = myrobustfit(x, y)
% Adapted version of robustfit able to deal with large-valued inputs x.
% AE 2008-01-10

mx = mean(x);
b = robustfit(x - mx, y);
b(1) = b(1) - b(2) * mx;
