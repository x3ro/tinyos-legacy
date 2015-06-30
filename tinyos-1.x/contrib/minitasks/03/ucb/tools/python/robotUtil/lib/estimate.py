import math
from mathSupport import atan2


#--------------------------------------------------#
# isClose  --  are two pose close?
#--------------------------------------------------#
def isClose( pos1 , pos2 , r ):
    x1 = pos1.getX()
    y1 = pos1.getY()
    x2 = pos2.getX()
    y2 = pos2.getY()
    if ( (x1 - x2)**2 + (y1 - y2)**2 ) <= r**2:
        return True
    else:
        return False



#--------------------------------------------------#
# mean  --  average the last numAve points of x
#--------------------------------------------------#
def mean( x , numAve ):
    nx = min(len(x), numAve)
    xEst = 0
    for i in range(-1,-nx-1,-1) :
        xEst += x[i]
    xEst = (xEst + 0.0)/ nx
    return xEst



#--------------------------------------------------#
# estimateTheta  --  given a set of chronological
#  x,y values on a line, estimate theta
#  ( note it returns a value in (0,2*pi) )
#--------------------------------------------------#
def estimateTheta(x, y):

    #constants
    #intType = type(int())
    #floatType = type(float())

    #quick names
    #xx = x[-1]
    #yy = y[-1]
    #xt = type(xx)
    #yt = type(yy)
    
    #make sure nothing funny happens
    #if ((xt == intType) or (xt == floatType)) and ((yt == intType) or (yt == floatType)):
    #    return atan2( x[-1], y[-1])
    #else:
    #    return 0.0

    return atan2( x[-1] - x[-2] , y[-1] - y[-2] )



# def estimateTheta(x,y):

#     #determine the deltas
#     n = len(x) - 1
#     if n < 2 :
#         theta = 0
#         return theta
#     deltaX = []
#     deltaY = []
#     for i in range(0, n):
#         deltaX.append( x[i+1] - x[i] )
#         deltaY.append( y[i+1] - y[i] )
    
#     #determine what quadrant the deltas lie in (and, hence, how we should interpret the atan)
#     quadX = 0
#     quadY = 0
#     for i in range(0, n):
#         quadX += deltaX[i]
#         quadY += deltaY[i]
#     quadX = (quadX + 0.0) / n
#     quadY = (quadY + 0.0) / n
#     if quadX == 0 :

#         if quadY == 0:
#             theta = 0
#         else:
#             signQuadY = quadY / abs( quadY )
#             theta = math.pi * signQuadY / 2
#         return theta
    
#     else:

#         signQuadX = quadX / abs( quadX )
#         signQuadY = quadY / abs( quadY )
#         quadSign = signQuadX * signQuadY
#         quadShift = math.pi * (1 - signQuadX) / 2

#     #compute the average theta
#     theta = 0
#     for i in range(0, n):
#         theta += math.atan( quadSign * abs( deltaY[i] + 0.0 / deltaX[i] ) ) + quadShift
#     theta = (theta + 0.0) / n
#     return theta 
