function xinit = get_xinit(track,yall)

% Copyright (c) 2003-2004 Songhwai Oh

global G

vtrack = find(track>0);
xinit = zeros(4,1);
if length(vtrack)>1
    d = vtrack(2)-vtrack(1);
    xdelta = [yall{vtrack(2)}(track(vtrack(2)),1)-yall{vtrack(1)}(track(vtrack(1)),1),...
              yall{vtrack(2)}(track(vtrack(2)),2)-yall{vtrack(1)}(track(vtrack(1)),2)]./(d*G.F_T);
    xinit = [yall{vtrack(1)}(track(vtrack(1)),1),yall{vtrack(1)}(track(vtrack(1)),2),...
            xdelta(1),xdelta(2)]';
else
    xinit = [yall{vtrack(1)}(track(vtrack(1)),1),yall{vtrack(1)}(track(vtrack(1)),2),0,0]';
end
