function [f, x, y] = kernelDensity2D(data, varargin)
%[f, x, y] = kernelDensity2D(data, x, y, nXPoints=25, nYPoints=25, sigma=1, weights)

%This function does a data smoothing using a gaussian kernel.  It is
%similar to ksdensity except that it takes a 2D data vector instead of a
%1D.  
%
%The first parameter is a k x 2 array of (x,y) points.  
%
%The second and third parameters are suggested x and y arrays.  If x or y
%are of the form [min max] then an array of size npoints between min and
%max is used.  If either is [], a minimal [min max] array is used.
%
%Sigma is the stdv of the gaussian kernel used.
%
%Weights is a k x 1 array indicating how much each point should be weighted.
%
%
%You can use surf(x,y,f) on the return args.



if length(varargin)>2  & ~isempty(varargin{3})
    nXPoints =varargin{3};
else
    nXPoints = 25;
end

if length(varargin)>3  & ~isempty(varargin{4})
    nYPoints =varargin{4};
else
    nYPoints = 25;
end

if length(varargin)>0 & ~isempty(varargin{1})
    x  = varargin{1};
	xmin=min(x);
	xmax=max(x);
    if length(x)==2
    	x = xmin:(xmax-xmin)/(nXPoints-1):xmax;
    else
        nXPoints = length(x);
    end
else
	xmin=min(data(:,1));
	xmax=max(data(:,1));
	x = xmin:(xmax-xmin)/(nXPoints-1):xmax;
end

if length(varargin)>1 & ~isempty(varargin{2})
    y =varargin{2};
	ymin=min(y);
	ymax=max(y);
    if length(y)==2
		y = ymin:(ymax-ymin)/(nYPoints-1):ymax;
    else
        nYPoints = length(y);
    end       
else
	ymin=min(data(:,2));
	ymax=max(data(:,2));
	y = ymin:(ymax-ymin)/(nYPoints-1):ymax;
end

if length(varargin)>4 & ~isempty(varargin{5})
    sigma = varargin{5};
else
    sigma = min((xmax-xmin)/(nXPoints-1), (ymax-ymin)/(nYPoints-1));
end

if length(varargin)>5 & ~isempty(varargin{6})
    weights = varargin{6};
else
    weights = ones(size(data, 1), 1);
end

f=zeros(length(x));
dist=zeros(length(x));

while ~isempty(data)
    for r = 1:length(x)
        for c = 1:length(y)
            dist(c,r)= sqrt( (x(r)-data(1,1))^2 + (y(c)-data(1,2))^2);
        end 
    end
    indices = logical(data(:,1)==data(1,1) & data(:,2)==data(1,2) & weights(:)==weights(1));
    numPoints = size(indices,1);
    f(:,:) = f(:,:) + numPoints*weights(1)*normpdf(dist, 0, sigma);
    data(indices, :) = [];
    weights(indices) = [];
end
