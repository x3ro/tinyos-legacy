function locmax = localmaxima_v(X,nbhd_dist,precision,conn)

% Copyright (c) 2005 Songhwai Oh

if nargin<2, precision=100; end
if nargin<3, conn=8; end

A = X;
%A = A * precision;
minA = min(A(A>-inf));
A(A==-inf) = minA;
if all(A(:)==minA)
    locmax = [];
    return
end

% combine connected local max
[M,N] = size(X);
[cx,cy] = find(A>minA);
cand = zeros(length(cx),2);
cand(:,1) = cx; cand(:,2) = cy;
clusters = cell(1,length(cx));
values = cell(1,length(cx));
unused_cand = ones(1,length(cx));
for n=1:size(cand,1)
    if unused_cand(n)
        clusters{n} = cand(n,:);
        values{n} = A(cand(n,1),cand(n,2))-minA;
        unused_cand(n) = 0;
        thiscand = cand(n,:);
        for m=1:size(thiscand,1)
            unused = find(unused_cand>0);
            distM = (cand(unused,:)-repmat(thiscand(m,:),size(unused,2),1)).^2;
            distM = sum(distM,2);
            nbhd = find(distM<nbhd_dist^2);
            goodcand = cand(unused(nbhd),:);
            clusters{n} = [clusters{n}; goodcand];
            for nv=1:size(goodcand,1)
                values{n} = [values{n}; A(goodcand(nv,1),goodcand(nv,2))-minA];
            end
            unused_cand(unused(nbhd))=0;
        end
    end
end
locmax = [];
for n=1:size(cand,1)
    if ~isempty(clusters{n})
        cluster_center = sum(clusters{n}.*repmat(values{n},1,2),1) ./ sum(values{n});
        %cluster_center = sum(clusters{n},1) ./ size(clusters{n},1);
        locmax = [locmax; cluster_center];
    end
end