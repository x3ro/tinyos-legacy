function state = testU(u,x)
% testU(u,x)

global plotState;
global dT;
u = reshape(u,[2,numel(u)/2]);

A = [ 1 0 dT 0;
      0 1 0 dT;
      0 0 1 0;
      0 0 0 1];
Gd = [dT^2/2 0;
      0     dT^2/2;
      dT     0;
      0     dT];
  
state = x;
for i = 2:size(u,2)+1
  state(:,i) = A*state(:,i-1) + Gd*u(:,i-1);
end

figure(plotState.TestUfignum);
cmap = jet(size(u,2));
hold on;
for i = 1:size(state,2)-1
    plot(state(1,[i i+1]),state(2,[i i+1]),'o-',...
        'MarkerFaceColor',cmap(i,:));
end
plot(state(1,end),state(2,end),'rx');
hold off;
colorbar;