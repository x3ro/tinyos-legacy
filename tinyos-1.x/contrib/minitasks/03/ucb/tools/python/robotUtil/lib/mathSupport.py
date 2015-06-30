import math

#--------------------------------------------------#
# sign  --  returns values in {-1,0,1}
#--------------------------------------------------#
def sign( x ):
    if x == 0:
        return 0
    elif abs(x) == x:
        return 1
    else:
        return -1



#--------------------------------------------------#
# atan2  -- return value in (0,2*pi)
#--------------------------------------------------#
def atan2( x , y ):
    if (x == 0) and (y == 0):
        theta = 0
    elif (x == 0):
        theta = ( sign(y) * math.pi / 2 ) % (2*math.pi)
    elif (y == 0):
        theta = ( 1 - sign(x) ) * math.pi / 2
    else:
        theta = math.atan( float(y) / x )
        theta += math.pi * ( 1 - sign(x) ) / 2
        theta = theta % (2*math.pi)
    return theta


