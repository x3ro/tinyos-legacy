function t = gradientAscent(t, numIterations, stressCutoff)
%t = gradientAscent(t, numIterations, stressCutoff)
%this function iteratively improves node positions using gradient ascent.
%It uses t.xyEstimate as a set of initial positions (or invents one if it is empty).
%It returns the final estimate for each node in t.xyEstimate.
%
%t - a single testCase
%stressCutoff - a universally acceptable stress level, e.g. 1

%first, initialize the xy vector
npts = length(t.kd);
xmin=t.bx(1);
xmax=t.bx(2);
ymin=t.bx(3);
ymax=t.bx(4);
topRightCorner=xmax+1i*ymax; %use imaginary numbers
centerPoint=topRightCorner/2;
if isempty(t.xyEstimate)
    xy=[rand(npts,1)+1i*rand(npts,1)]*2-1+centerPoint; %initialize all positions to the centerpoint
else
    xy=t.xyEstimate(:,1)+1i*t.xyEstimate(:,2); %or initialize to user option
end
if nargin<=1 | isempty(numIterations) numIterations=0.1; end
if nargin<=2 | isempty(stressCutoff) stressCutoff=1; end

S=(t.kd-eye(npts))>=0;
S = double(S);

alpha = 0.1;
ngrad = 200;
numiter=1;
obj = 1.0e20*ones(ngrad,1);
xybig = zeros(npts,ngrad);

gradient = zeros(npts,1);
[objnew,sM,dM]=findGlobalAbsoluteStress(xy,t.kd,S);
gradient(:) = sum(dM./(abs(dM)+eps).*sign(sM));
ograd=gradient;
obj(1) = objnew;
xybig(:,1) = xy;

for ij=2:ngrad  
   mobileNodes = vectorFind(setDiff(t.nodeIDs, t.anchorNodes), t.nodeIDs);
   xy(mobileNodes) = xy(mobileNodes) - alpha  * gradient(mobileNodes);
   xy = min(max(real(xy),xmin),xmax) + j * min(max(imag(xy),ymin),ymax);
   
   [s,sM,dM]=findGlobalAbsoluteStress(xy,t.kd,S);
   gradient(:) = sum(dM./(abs(dM)+eps).*sign(sM));
   
   obj(ij) = s;
   xybig(:,ij) = xy;
   if( obj(ij) > obj(ij-1) )
       xy = xybig(:,ij-1);
       alpha = alpha *2 / 3;
       gradient=ograd;
   end
   [bestobj,index] = min(obj);
   if bestobj < stressCutoff
      break
   end
   ograd = gradient;
   numiter=numiter+1;
end

disp(['Numiter = ' num2str(numiter)])
[bestobj,index] = min(obj);
xy = xybig(:,index);
t.xyEstimate=[real(xy) imag(xy)];

