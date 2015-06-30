from config import *
import packet, moteGps
from fpformat import fix


def magPacket():

    p = packet.packet()

    p.addField( "address" , 2 , packet.UINT , BROADCAST_ADDR )
    p.addField( "amType" , 1 , packet.UINT , MAG_AM_TYPE )
    p.addField( "groupID" , 1 , packet.UINT , GROUP_ID )

    p.addField( "length" , 1 , packet.UINT , MAG_PAYLOAD_LENGTH )
    
    p.addField( "magSum" , 4 , packet.UINT , 1 )
    p.addField( "magXSum88" , 4 , packet.INT )
    p.addField( "magYSum88" , 4 , packet.INT )
    p.addField( "magNumReporting" , 1 , packet.UINT , 1 )
    p.addField( "hopsLeft" , 1 , packet.UINT , 0 )
    p.addField( "originAddress" , 2 , packet.UINT )
    p.addField( "originSequence" , 1 , packet.UINT )
    p.addField( "protocol" , 1 , packet.UINT )

    p.addField( "zeroPadding0" , 4 , packet.UINT , 0 )
    p.addField( "zeroPadding1" , 4 , packet.UINT , 0 )
    p.addField( "zeroPadding2" , 3 , packet.UINT , 0 )
    p.addField( "crc" , 2 , packet.UINT , 1 )

    return p



def cRoutePacket():

    p = packet.packet()

    p.addField( "address" , 2 , packet.UINT , BROADCAST_ADDR )
    p.addField( "amType" , 1 , packet.UINT , C_ROUTE_AM_TYPE )
    p.addField( "groupID" , 1 , packet.UINT , GROUP_ID )

    p.addField( "length" , 1 , packet.UINT , C_ROUTE_PAYLOAD_LENGTH )
    
    p.addField( "type" , 1 , packet.UINT , C_ROUTE_TYPE )
    p.addField( "dest" , 1 , packet.UINT )
    p.addField( "crumb" , 2 , packet.UINT )
    p.addField( "len" , 1 , packet.UINT , C_ROUTE_LEN )
    p.addField( "magSum" , 4 , packet.UINT , 1 )
    p.addField( "magXSum88" , 4 , packet.INT )
    p.addField( "magYSum88" , 4 , packet.INT )
    p.addField( "magNumReporting" , 1 , packet.UINT , 1 )
    p.addField( "originAddress" , 2 , packet.UINT )
    p.addField( "originSequence" , 1 , packet.UINT )
    p.addField( "protocol" , 1 , packet.UINT , C_ROUTE_PROTOCOL )

    p.addField( "zeroPadding0" , 4 , packet.UINT , 0 )
    p.addField( "zeroPadding1" , 3 , packet.UINT , 0 )
    p.addField( "crc" , 2 , packet.UINT , 1 )

    return p












def findMagPacket( buffer , protocol = 82 , address = UART_ADDR ):

    #convert the bytes to a dictionary of values
    p = magPacket()
    p.setPacketBytes( buffer , packet.LSBF )
    packetDict = p.makeDict()
    
    #get the gps coordinate center of mass
    #magSumGps = moteGps.mote88ToGps( (packetDict["magXSum88"], packetDict["magYSum88"]) )

    #add the floating point mote coordinate to the packet dictionary
    packetDict["magXSumFloat"] = float(packetDict["magXSum88"]) / 256
    packetDict["magYSumFloat"] = float(packetDict["magYSum88"]) / 256

    #Can we compute the center of mass?
    if packetDict["magSum"] == 0:
        return None
    else:
        #packetDict[ "gpsX" ] = magSumGps[0] / packetDict["magSum"]
        #packetDict[ "gpsY" ] = magSumGps[1] / packetDict["magSum"]
        packetDict[ "magObjectX" ] = packetDict["magXSumFloat"] / packetDict["magSum"]
        packetDict[ "magObjectY" ] = packetDict["magYSumFloat"] / packetDict["magSum"]
    
    #check the validity of the packet
    if ( packetDict["address"] == address ) and \
       ( packetDict["amType"] == MAG_AM_TYPE ) and \
       ( packetDict["groupID"] == GROUP_ID ) and \
       ( packetDict["length"] == MAG_PAYLOAD_LENGTH ) and \
       ( packetDict["protocol"] == protocol ) and \
       ( packetDict["crc"] == 1 ) :
        return packetDict
    else:
        return None




def findCRoutePacket( buffer ):

    #convert the bytes to a dictionary of values
    p = cRoutePacket()
    p.setPacketBytes( buffer , packet.LSBF )
    packetDict = p.makeDict()

    #get the gps coordinate center of mass
    #magSumGps = moteGps.mote88ToGps( (packetDict["magXSum88"], packetDict["magYSum88"]) )

    #add the floating point mote coordinate to the packet dictionary
    packetDict["magXSumFloat"] = float(packetDict["magXSum88"]) / 256
    packetDict["magYSumFloat"] = float(packetDict["magYSum88"]) / 256

    #Can we compute the center of mass?
    if packetDict["magSum"] == 0:
        return None
    else:
        #packetDict[ "gpsX" ] = magSumGps[0] / packetDict["magSum"]
        #packetDict[ "gpsY" ] = magSumGps[1] / packetDict["magSum"]
        packetDict[ "magObjectX" ] = packetDict["magXSumFloat"] / packetDict["magSum"]
        packetDict[ "magObjectY" ] = packetDict["magYSumFloat"] / packetDict["magSum"]
    
    #check the validity of the packet
    if ( packetDict["address"] == UART_ADDR ) and \
       ( packetDict["amType"] == C_ROUTE_AM_TYPE ) and \
       ( packetDict["groupID"] == GROUP_ID ) and \
       ( packetDict["length"] == C_ROUTE_PAYLOAD_LENGTH ) and \
       ( packetDict["protocol"] == C_ROUTE_PROTOCOL )  and \
       ( packetDict["type"] == C_ROUTE_TYPE ) and \
       ( packetDict["len"] == C_ROUTE_LEN ) and \
       ( packetDict["crc"] == 1 ):
        return packetDict
    else:
        return None




def makeMagPacketBytes( x , y , originSequence = 0 , protocol = 82 , address = BROADCAST_ADDR ):
    #given (x,y) in ( gps , meters , floating point ) coordinates make a mag packet

    #convert to mote coordinates
    ( magXSum88 , magYSum88 ) = moteGps.gpsToMote88( (x,y) )

    #print "Converting " +fix(x,0)+ ","+fix(y,0)+"(gps,mm) to "+fix(float(magXSum)/256,2)+","+\
    #      fix(float(magYSum)/256,2)+"(mote,m)"

    #make the packet
    p = magPacket()
    p.setFieldValue( "address" , address )
    p.setFieldValue( "magXSum88" , magXSum88 )
    p.setFieldValue( "magYSum88" , magYSum88 )
    p.setFieldValue( "originAddress" , ORIGIN_ADDR )
    p.setFieldValue( "originSequence" , originSequence )
    p.setFieldValue( "protocol" , protocol )  #2 ...3(always send), 4(only send if you are close to me)

    return p.getPacketBytes( packet.LSBF )
