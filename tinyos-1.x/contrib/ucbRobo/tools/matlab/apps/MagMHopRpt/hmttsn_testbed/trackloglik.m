function [loglik] = trackloglik(Tf,xtrack,xloglik,ny,zloglik)

% Copyright (c) 2003-2004 Songhwai Oh

global G
if nargin<5, zloglik=0; end

[T,K] = size(xtrack);
ktimes = zeros(K,2);
nnt = zeros(1,T);
nxt = zeros(1,T);
ndt = zeros(1,T);
for k=1:K
    det = find(xtrack(:,k)>0);
    ti = det(1);
    tf = det(length(det));
    ktimes(k,:) = [ti,tf];
    nnt(ti) = nnt(ti)+1;
    for t=ti:tf
        if xtrack(t,k)>0
            ndt(t) = ndt(t) + 1;
        end
    end
    if tf<T
        nxt(tf+1) = nxt(tf+1) + 1;
    end
end

net = 0;
logprior = nnt(1)*log(G.NTR) + (ny(1)-nnt(1))*log(G.FAR);
for t=2:T
    net = net + nnt(t-1) - nxt(t-1);
    nct = net - nxt(t);
    nut = net - nxt(t) + nnt(t) - ndt(t);
    nfa = ny(t) - ndt(t);
    logprior = logprior + nxt(t)*log(G.TTR) + nct*log(1-G.TTR) ...
                        + ndt(t)*log(G.DP) + nut*log(1-G.DP) ...
                        + nnt(t)*log(G.NTR) + nfa*log(G.FAR);
end                        
loglik = logprior + sum(xloglik(:));

