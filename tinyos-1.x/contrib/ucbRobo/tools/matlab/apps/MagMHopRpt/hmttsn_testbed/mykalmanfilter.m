function [xest,logliksum,Pcov] = ...
    mykalmanfilter(T,track,xinit,yall,drawfigure,plotdot,linewidth,mytext)

% Copyright (c) 2003-2004 Songhwai Oh

global G
if nargin<5, drawfigure=0; end
if nargin<6, plotdot='b:'; end
if nargin<7, linewidth=2; end
if nargin<8, mytext=''; end

xest = zeros(4,T);
Pcov = zeros(4,4,T);
loglik = zeros(1,T);
if length(track)>T
    track(T+1:length(track)) = 0;
end
vtrack = find(track>0);
if isempty(vtrack),
    logliksum=0;
    return;
end
xest(:,vtrack(1)) = xinit;
Pcov(:,:,vtrack(1)) = eye(4); 
if drawfigure 
    %plot(yall{vtrack(1)}(track(vtrack(1)),1),yall{vtrack(1)}(track(vtrack(1)),2),'bo','MarkerSize',10);
end

% filtering
for t=2:length(vtrack)
    dT = vtrack(t)-vtrack(t-1);
    Amat = [1 0 dT 0; 0 1 0 dT; 0 0 1 0; 0 0 0 1];
    Gmat = [dT^2/2 0; 0 dT^2/2; dT 0; 0 dT];
    xpred = Amat*xest(:,vtrack(t-1));
    Ppred = Amat*Pcov(:,:,vtrack(t-1))*Amat' + Gmat*G.Qcov*Gmat';
    innov = (yall{vtrack(t)}(track(vtrack(t)),:)' - G.Cmat*xpred);
    Bmat = G.Cmat*Ppred*G.Cmat' + G.Rcov;
    invBmat = inv(Bmat);
    %fprintf(1,'B = [ %.20f %.20f;\n     %.20f %.20f ]\n', Bmat);
    %fprintf(1,'invB = [ %.20f %.20f;\n         %.20f %.20f ]\n', invBmat);
    K_1 = Ppred*G.Cmat'*invBmat;
    xest(:,vtrack(t)) = xpred + K_1*innov;
    Pcov(:,:,vtrack(t)) = Ppred - K_1*G.Cmat*Ppred;
    loglik(vtrack(t)) = mvnormpdf(innov,zeros(2,1),Bmat,1);
    if drawfigure 
        plot([xest(1,vtrack(t-1)) xest(1,vtrack(t))]',...
             [xest(2,vtrack(t-1)) xest(2,vtrack(t))]',plotdot,'LineWidth',linewidth);
        if length(mytext)>0
            if t==2
                text([xest(1,vtrack(t-1))]'+[.05,.05]',[xest(2,vtrack(t-1))]'-[.15,.15]',...
                    sprintf('(%d)',vtrack(t-1)));
                    %sprintf('%s(%d)',mytext,vtrack(t-1)));
            end
            text([xest(1,vtrack(t))]'+[.05,.05]',[xest(2,vtrack(t))]'-[.15,.15]',...
               sprintf('(%d)',vtrack(t)));
               %sprintf('%s(%d)',mytext,vtrack(t)));
        end
        %plot(yall{vtrack(t)}(track(vtrack(t)),1),yall{vtrack(t)}(track(vtrack(t)),2),'bo','MarkerSize',5);
    end
end
logliksum = sum(loglik(:));
