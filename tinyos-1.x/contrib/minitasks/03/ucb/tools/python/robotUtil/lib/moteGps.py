from config import *

# let the matrix M (3x3) take homogenous vectors in mote coordinates m=[xm ym 1]^t (in meters!)
# to homogenous vectors in GPS coordinates g=[xg yg 1]^t (in meters!)
# Futhermore, let the rows of M be denoted by the lists MOTE_TO_GPS_M1, MOTE_TO_GPS_M2, MOTE_TO_GPS_M3 so that
# xg = MOTE_TO_GPS_M1*m and yg = MOTE_TO_GPS_M2*m
# let Minv be its inverse with rows GPS_TO_MOTE_M1, GPS_TO_MOTE_M2, GPS_TO_MOTE_M3


def moteToGps( m ):

    #input values should be in (mote, meters, floating point)

    g0 = MOTE_TO_GPS_M1[0]*m[0] + MOTE_TO_GPS_M1[1]*m[1] + MOTE_TO_GPS_M1[2]*1  #convert to (gps, meters, floating point)
    g1 = MOTE_TO_GPS_M2[0]*m[0] + MOTE_TO_GPS_M2[1]*m[1] + MOTE_TO_GPS_M2[2]*1
    return ( g0 , g1 )

def mote88ToGps( m ):

    #input values should be in (mote, meters, 8.8 fixed point)

    m0 = float(m[0]) / 256  #convert to (mote, meters, floating point)
    m1 = float(m[1]) / 256
    g0 = MOTE_TO_GPS_M1[0]*m0 + MOTE_TO_GPS_M1[1]*m1 + MOTE_TO_GPS_M1[2]*1  #convert to (gps, meters, floating point)
    g1 = MOTE_TO_GPS_M2[0]*m0 + MOTE_TO_GPS_M2[1]*m1 + MOTE_TO_GPS_M2[2]*1
    return ( g0 , g1 )

def gpsToMote( g ):

    #input values should be in (gps, meters, floating point)

    m0 = GPS_TO_MOTE_M1[0]*g[0] + GPS_TO_MOTE_M1[1]*g[1] + GPS_TO_MOTE_M1[2]*1  #convert to (mote, meters, floating point)
    m1 = GPS_TO_MOTE_M2[0]*g[0] + GPS_TO_MOTE_M2[1]*g[1] + GPS_TO_MOTE_M2[2]*1
    return ( m0 , m1 )

def gpsToMote88( g ):

    #input values should be in (gps, meters, floating point)

    m0 = GPS_TO_MOTE_M1[0]*g[0] + GPS_TO_MOTE_M1[1]*g[1] + GPS_TO_MOTE_M1[2]*1  #convert to (mote, meters, floating point)
    m1 = GPS_TO_MOTE_M2[0]*g[0] + GPS_TO_MOTE_M2[1]*g[1] + GPS_TO_MOTE_M2[2]*1
    mm0 = int( m0 * 256 )  #convert to (mote, meters, 8.8 fixed point)
    mm1 = int( m1 * 256 )
    return ( mm0 , mm1 )







# def moteToGps( m ):

#     #input values should be in (mote, meters, 8.8 fixed point)
#     m0 = float(m[0]) / 256  #convert to (mote, meters, floating point)
#     m1 = float(m[1]) / 256
#     g0 = MOTE_TO_GPS_M1[0]*m0 + MOTE_TO_GPS_M1[1]*m1 + MOTE_TO_GPS_M1[2]*1  #convert to (gps, meters, floating point)
#     g1 = MOTE_TO_GPS_M2[0]*m0 + MOTE_TO_GPS_M2[1]*m1 + MOTE_TO_GPS_M2[2]*1
#     gg0 = g0 * 1000  #convert to (gps, mm, floating point)
#     gg1 = g1 * 1000

#     return ( gg0 , gg1 )

# def gpsToMote( g ):

#     #input values should be in (gps, mm, floating point)
#     g0 = float(g[0]) / 1000  #convert to (gps, meters, floating point)
#     g1 = float(g[1]) / 1000 
#     m0 = GPS_TO_MOTE_M1[0]*g0 + GPS_TO_MOTE_M1[1]*g1 + GPS_TO_MOTE_M1[2]*1  #convert to (mote, meters, floating point)
#     m1 = GPS_TO_MOTE_M2[0]*g0 + GPS_TO_MOTE_M2[1]*g1 + GPS_TO_MOTE_M2[2]*1
#     mm0 = int( m0 * 256 )  #convert to (mote, meters, 8.8 fixed point)
#     mm1 = int( m1 * 256 )

#     return ( mm0 , mm1 )

