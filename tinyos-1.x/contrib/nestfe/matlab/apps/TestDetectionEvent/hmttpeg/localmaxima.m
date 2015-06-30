function locmax = localmaxima(X,nbhd_dist,precision,conn)

% Copyright (c) 2005 Songhwai Oh

if nargin<2, precision=100; end
if nargin<3, conn=8; end

% find local max
A = X;
A(A==-inf) = min(A(A>-inf));
A = A * precision;
regmax = imregionalmax(round(A),conn);
if all(regmax(:))
    locmax = [];
    return
end

% combine connected local max
[M,N] = size(X);
[cx,cy] = find(regmax>0);
cand = zeros(length(cx),2);
cand(:,1) = cx; cand(:,2) = cy;
clusters = cell(1,length(cx));
unused_cand = ones(1,length(cx));
for n=1:size(cand,1)
    if unused_cand(n)
        clusters{n} = cand(n,:);
        unused_cand(n) = 0;
        thiscand = cand(n,:);
        for m=1:size(thiscand,1)
            unused = find(unused_cand>0);
            distM = (cand(unused,:)-repmat(thiscand(m,:),size(unused,2),1)).^2;
            distM = sum(distM,2);
            nbhd = find(distM<=nbhd_dist^2);
            clusters{n} = [clusters{n}; cand(unused(nbhd),:)];
            unused_cand(unused(nbhd))=0;
        end
    end
end
nlocmax = 0;
locmax = [];
for n=1:size(cand,1)
    if ~isempty(clusters{n})
        nlocmax = nlocmax + 1;
        cluster_center = sum(clusters{n},1) ./ size(clusters{n},1);
        locmax = [locmax; cluster_center];
    end
end