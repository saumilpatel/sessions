function [Mu,C,Pi,LL] = MoG1(X,M,varargin)
% Mixture of Gaussian fitting using EM.
%
% [Mu,C,Pi,LL] = MoG1(X,K,params);
%
% Original 2005-04 Dilan Görür
% Modified 2008-07-15 AE

% constants
N = length(X);

% input params
params.cycles = 1000;
params.mu = repmat(mean(X),M,1) .* randn(M,1);
for i = 1:2:length(varargin)
	params.(varargin{i}) = varargin{i+1};
end

Mu = params.mu;
cX = var(X,1);
C = repmat(cX,M,1);
Pi = ones(M,1)/M;
H = zeros(N,M);
const = -0.5*log(2*pi);

LL = zeros(1,params.cycles);

for i = 1:params.cycles;

	%%%% E Step %%%%
	for j = 1:M
		Xj = (X - ones(N,1) * Mu(j));
		H(:,j) = Pi(j) * exp(const - 0.5*sum(Xj/C(j).*Xj,2) - sum(log(sqrt(C(j)))));
	end
		
	%%%% Compute log likelihood %%%%
	Hsum = sum(H,2);
	lik = sum(log(Hsum+(Hsum==0) * exp(-744)));% log likelihood code here
	LL(i) = lik;								% store values

	%%%% M Step %%%%
	H = H ./ repmat(Hsum,1,M);
    H(Hsum == 0,:) = 0;
	for j = 1:M
		Mu(j) = sum(X.*H(:,j),1) / sum(H(:,j));
		Xj = (X - ones(N,1)*Mu(j));
		C(j) = (H(:,j).*Xj)' * Xj / sum(H(:,j));
		Pi(j) = sum(H(:,j)) / sum(sum(H));
	end						
end
