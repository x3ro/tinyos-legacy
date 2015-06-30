function hh = newquiver(x,y, a,b)
%
% modified from quiver.m, included w/ matlab
%

% Arrow head parameters
alpha = 0.28; % Size of arrow head relative to the length of the vector
beta = 0.28;  % Width of the base of the arrow head relative to the length
autoscale = 0; % Autoscale if ~= 0 then scale by this.
plotarrows = 1; % Plot arrows
sym = '';

ls = '-';
ms = '';
col = '';


%ax = newplot;
%next = lower(get(ax,'NextPlot'));
%hold_state = ishold;

% Make velocity vectors
uu = [x;a;repmat(NaN,size(a),1)];
vv = [y;b;repmat(NaN,size(a),1)];

h1 = plot(uu(:),vv(:),[col ls]);


if plotarrows,
  % FIXME: this is buggy if u == v == 0 at any point!!

  % normalize vector lengths 
  u = (a-x);
  v = (b-y);
  len = sqrt(u.*u + v.*v);

  % avoid divide-by-zero errors
  len( find(len == 0) ) = NaN;

  u = u ./ len;
  v = v ./ len;
  
  % Make arrow heads and plot them
  hu = [a-alpha*(u+beta*(v+eps)); a; ...
        a-alpha*(u-beta*(v+eps)); ...
        repmat(NaN,size(u),1) ];
  hv = [b-alpha*(v-beta*(u+eps)); b; ...
        b-alpha*(v+beta*(u+eps)); ...
        repmat(NaN,size(v),1) ];
  hold on
  h2 = plot(hu(:),hv(:),[col ls]);
else
  h2 = [];
end

if ~isempty(ms), % Plot marker on base
  hu = x; hv = y;
  hold on
  h3 = plot(hu(:),hv(:),[col ms]);
  if filled, set(h3,'markerfacecolor',get(h1,'color')); end
else
  h3 = [];
end

%if ~hold_state, hold off, view(2); set(ax,'NextPlot',next); end

if nargout>0, hh = [h1;h2;h3]; end

