function [fuseY,plikH,plikVM] = fuse_detection(rawY)

% Copyright (c) 2005 Songhwai Oh

global gvs 

res = fuse_detection_mex(gvs.grid,gvs.sw,rawY);
fuseY = res.fuseY';
plikH = reshape(res.plikH,gvs.grid.xN,gvs.grid.yN); 
plikVM = reshape(res.plikVM,gvs.grid.xN,gvs.grid.yN); 

%%%%%%%%%%%%%%%%%%%%
% 
% function [fuseY,plikH,plikVM] = fuse_detection(rawY)
%
% % Copyright (c) 2005 Songhwai Oh
% 
% global gvs 
% 
% plik = -inf*ones(1,gvs.grid.N);
% plikval = -inf*ones(1,gvs.grid.N);
% for n=1:length(gvs.grid.cluster);
%     delegate = gvs.grid.cluster{n}(1);
%     sensV = gvs.grid.sensV{delegate};
%     if ~isempty(sensV)
%         sensDetect = intersect(sensV,rawY);
%         sensUndetect = setdiff(sensV,sensDetect);
%         %sensOther = setdiff(1:gvs.sw.N,sensV);
%         if length(sensDetect)>=max(gvs.grid.num_min_detections,floor(1/2*length(sensV)))
%             plik(gvs.grid.cluster{n}) ...
%                 = sum(log(gvs.sw.Pd(sensDetect))) ...
%                 + sum(log(1-gvs.sw.Pd(sensUndetect))); 
%         end
%         plikval(gvs.grid.cluster{n}) ...
%             = sum(log(gvs.sw.Pd(sensDetect))) ...
%             + sum(log(1-gvs.sw.Pd(sensUndetect))); 
%     end
% end
% if ~isempty(find(plik>-inf))
%     plik(plik==-inf) = min(plik(plik>-inf));
% end
% plik_min = min(plik);
% plikC = plik;
% plikVM = reshape(plikval,gvs.grid.xN,gvs.grid.yN); 
% %plikC(plik<mean(plik)+3*std(plik)) = plik_min;
% plikH = reshape(plikC,gvs.grid.xN,gvs.grid.yN); 
% if ~isempty(find(plikH(:)>-inf))
%     %locmax = localmaxima(plikH,gvs.grid.localmaxima_scale/gvs.grid.unitlen,1000,8);
%     locmax = localmaxima_v(plikH,gvs.grid.localmaxima_scale/gvs.grid.unitlen,1000,8);
% else
%     locmax = [];
% end
% fuseY = [];
% for n=1:size(locmax,1)
%     meas = gvs.grid.unitlen*locmax(n,:)-gvs.grid.unitlen/2;
%     if all(meas'<gvs.sw.SR(:,2)) & all(meas'>gvs.sw.SR(:,1))
%         fuseY = [fuseY; meas];
%     end
% end
