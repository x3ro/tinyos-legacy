import os, re, time, Config



def findMotes() :

    comList = []
    moteList = os.popen("motelist").readlines()
    if len(moteList) > 2 :

        moteList = moteList[2:]
        for moteDesc in moteList :

            if Config.PLATFORM == "win32" :
                results = re.search( "COM(?P<comNum>\d+)\s+Telos" , moteDesc )
                if results :
                    comList.append( "serial@COM%s:telos" % results.group("comNum") )
            elif Config.PLATFORM == "linux" :
                results = re.search( "\s+(?P<dev>/dev/[^\s]+)\s+" , moteDesc )
                if results :
                    comList.append( "serial@%s:telos" % results.group("dev") )

    return comList



def getResources( dummy = False , retryPeriod = 0.5 ) :
    """Set retryPerid = 0 to only try once"""

    resources = {}


    # --------------------------------------------------
    # Add GPS
    # --------------------------------------------------
    import Gps
    if Config.IS_MONSTRO :
        resources.update({ "gps" : Gps.getGps( dummy = dummy ) })
    else :
        resources.update({ "gps" : Gps.getGps( dummy = True ) })


    if not dummy :

        # --------------------------------------------------
        # Add roboMote
        # --------------------------------------------------
        import RoboMote

        # find the com ports associated with motes
        done = False
        while not done :

            moteComs = findMotes()
            if (not moteComs) and (retryPeriod > 0) :
                time.sleep(retryPeriod)
                continue

            roboMote = None
            for i in range(len(moteComs)-1,-1,-1) :
                moteCom = moteComs[i]
                if RoboMote.isRoboMote( moteCom ) :
                    del moteComs[i] 
                    roboMote = RoboMote.RoboMote( moteCom )
                    done = True
                    break

            if not roboMote :
                if ( retryPeriod > 0 ) :
                    time.sleep(retryPeriod)
                    continue
                else :
                    raise RoboMote.RoboMoteException , "Could not connect to the mote providing RoboMote"

        # Add the roboMote to the resource list
        resources.update({ "roboMote" : roboMote })


    return resources



if __name__ == "__main__" :
    print findMotes()
