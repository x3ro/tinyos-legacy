import sys, time, KeyPress
import pytos.tools.Rpc as Rpc
import pytos.tools.RamSymbols as RamSymbols
import pytos.util.NescApp as NescApp




def hexColor( t ) :
    
    t = int(t)
    if t < 128 :
        c = 255 - t
    else :
        c = 127
    cHex = hex(c)
    cHex = cHex[2:]
    return "#FF%s%s" % (cHex,cHex)
    

def updateDict( msgs , name , d ):
    for msg in msgs :
        val = msg.value["value"].value
        nodeID = msg.parentMsg.parentMsg.sourceAddress

        if nodeID in d :
            valDict = d[ nodeID ]
        else :
            valDict = {}
        valDict.update({ name : [ val , time.time() ] })
        d.update({ nodeID : valDict })



def makePage( state , colNames ):

    header = """
<html>
    
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<meta http-equiv="refresh" content="3"/>
<title>Watch</title>
</head>
    
<body>
<table border=1>"""

    footer = """
</table>
</body>"""


    header += "<tr><th>Node ID"
    for valName in colNames :
        header += "<th>%s" % valName
    header += "<th>Last Response (seconds)"


    content = ""
    nodeIds = state.keys()
    nodeIds.sort()
    for nodeId in nodeIds :
        valDict = state[ nodeId ]
        content += "<tr><th>%s" % nodeId
        minDelta = sys.maxint
        for valName in colNames :
            if valName in valDict :
                valTime = valDict[ valName ]
                deltaTime = time.time() - valTime[1]
                if minDelta > deltaTime :
                    minDelta = deltaTime
                content += "<td bgcolor=\"%s\">%s" % (hexColor(deltaTime),valTime[0])
            else :
                content += "<td> -- "
        content += "<td bgcolor=\"%s\">%d\n" % (hexColor(minDelta),minDelta)

    return header + content + footer




if __name__ == "__main__" :
    def usage() :
        print """watch.py RAM_NAME1 RAM_NAME2 ...

        example: python watch.py PrometheusM.volCap PrometheusM.volBatt PrometheusM.bCharging PrometheusM.bRunningOnBatt"""
        sys.exit(0)



    if len(sys.argv) < 2 :
        usage()


    ramNames = sys.argv[1:]


    TIMEOUT = 2
    LOGFILENAME = "test.log"
    WEBFILENAME = "test.html"
    buildDir = "telosb"
    port = "sf@localhost:9001"
    app = NescApp.NescApp( buildDir , port , tosbase=True )



    kp = KeyPress.KeyPress()
    print "Press 'q' to quit"
    state = {}
    done = False
    while not done :

        # query for new values in ram
        for ramName in ramNames :
            cmd = "app.ramSymbols.%s" % ramName
            updateDict( eval(cmd).peek( timeout=TIMEOUT ) , ramName , state )
            if kp.getChar() == "q" :
                done = True


        # write the HTML file
        f = file( WEBFILENAME , 'w' )
        f.write( makePage( state , ramNames ) )
        f.close()

        time.sleep( 10 )
        if kp.getChar() == "q" :
            done = True


