import xdrlib

MSBF = 0  #most sign. byte first
LSBF = 1  #least sign. byte first
INT = 0
UINT = 1


def makeUnsignedChar( num , length ):
    p = xdrlib.Packer()
    p.reset()
    p.pack_uint( num )
    return p.get_buffer()[-length:]


def makeSignedChar( num , length ):
    p = xdrlib.Packer()
    p.reset()
    p.pack_int( num )
    return p.get_buffer()[-length:]


def makeUnsignedNumber( str ):
    num = 0;
    i = len(str) - 1
    for char in str:
        num += ord( char )*(2**(8*i))
        i -= 1
    return num


def makeSignedNumber( str ):

    if ord(str[1]) <= 127:  #the number is positive
        return makeUnsignedNumber( str )
    else:  #the number is negative
        m = len( str )
        return makeUnsignedNumber( str ) - 2**(8*m)


    

class packet:


    def __init__( self ):
        self.field = []



    def addField( self , fieldName , byteSize , type , value = 0 ):  # type = int or uint
        newField = [ fieldName , byteSize , type , value ]
        if byteSize > 4 :
            raise ValueError, "byteSize must be less than 5"
        self.field.append( newField )
        


    def setFieldValue( self , fieldName , value ):
        for field in self.field:
            if field[0] == fieldName :
                field[3] = value
                break



    def getFieldNames( self ):
        names = []
        for field in self.field:
            names.append( field[0] )
        return names



    def makeDict( self ):  #return a dictionary of name:value pairs
        dict = {}
        for field in self.field:
            dict[ field[0] ] = field[3]
        return dict

    

    def getFieldValue( self , fieldName ):
        value = None
        for field in self.field:
            if field[0] == fieldName :
                value = field[3]
                break
        return value
        


    def getPacketBytes( self , byteOrder ):  #suitable for sending over socket
        packet = ""
        for field in self.field:

            newBytes = ""
            if field[2] == INT:
                newBytes = makeSignedChar( field[3] , field[1] )
            elif field[2] == UINT:
                newBytes = makeUnsignedChar( field[3] , field[1] )

            if byteOrder == LSBF:
                revStr = lambda s:s and revStr(s[1:])+s[0]  #reverse the string
                newBytes = revStr(newBytes)

            packet += newBytes

        return packet



    def setPacketBytes( self , bytes , byteOrder ):  #suitable for applying to recieved socket data

        self.reset()
        bytesLeft = bytes[:]
        for field in self.field:

            currentBytes = bytesLeft[:field[1]]  #new bytes to operate on
            bytesLeft = bytesLeft[field[1]:]  #trim our buffer of incoming bytes

            if byteOrder == LSBF:
                revStr = lambda s:s and revStr(s[1:])+s[0]  #reverse the string
                currentBytes = revStr( currentBytes )

            if field[2] == INT:
                field[3] = makeSignedNumber( currentBytes )
            elif field[2] == UINT:
                field[3] = makeUnsignedNumber( currentBytes )



    def reset( self ):  #clear the value of all the fields
        for field in self.field:
            field[3] = None
