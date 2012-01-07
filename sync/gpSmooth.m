function f = gpSmooth(x,y)
% runs a gp smoothing on input data
% 
% JC 2010-06-05


sigma_obs = 1; %std(diff(y));
sigma_kernel = 10;

K = covariance(x,x,1/sigma_kernel^2);
L = chol(K + sigma_obs^2 * eye(size(K,1)));
alpha = L' \ (L \ y);
f = K' * alpha;
return;

for i = 1:size(K,2)
    v = L \ K(:,i);
    Var(i) = K(i,i) - v' * v;
end

f2 = -1/2 * y' * alpha - sum(log(diag(K))) - size(K,1)/2 * log(2 * pi)

%cla
%patch([x; flipud(x)],[(f+2*sqrt(Var)'); flipud(f - 2*sqrt(Var)')],[.9 .9 .9],'EdgeColor','none')
%hold on
plot(x,y,x,f)

function K = covariance(x1,x2,prec)

K = zeros(size(x1,1),size(x2,1));
for i = 1:size(x1,1)
    d = bsxfun(@minus,x1(i,:),x2);
    K(i,:) =  sum(exp(- 1/2 * (d * prec) .* d),2)';
end

