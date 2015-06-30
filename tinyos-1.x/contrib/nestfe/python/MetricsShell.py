#!/usr/bin/python -i

# Copied over from PytosShell.py
#
# @author Phoebus Chen
#
# 
# This script loads the basic pytos environment for
# TestDetectionEvent, MetricsMote, and MarkSeq.  It also imports
# MetricsTools to interact with them properly.  The application
# directories and motecom are hardcoded into this script.
#
# USAGE: MetricsShell.py scriptType [appType] [buildTree]
#   scriptType is 'mon', 'lat', or 'tools'
#   appType (optional) is 'MetricsMote' or 'TestDetectionEvent'
#   buildTree (optional) is 'tree' or 'notree'
# ex.
# $     MetricsShell.py mon
# $     MetricsShell.py lat MetricsMote
# $     MetricsShell.py tools TestDetectionEvent notree
# Note that we cannot build a tree for 'MetricsMote', so the tree
# option is ignored.  appType must be specified for buildTree to be
# specified.  If an option is not passed in properly, the user will
# be prompted (except for scriptType... this defaults to 'tools)
#
# KNOWN BUG AND WORKAROUND:
# copy over contrib/nestfe/python/MetricsShell.py over to
# tools/python/apps before using it.  Otherwise, if you
# leave MetricsShell.py where it is you will get errors.
# This is a bug with environment paths used by pytos, not
# with this script.


import sys
import os
import pytos.util.NescApp as NescApp
import pytos.util.ParseArgs as ParseArgs
import pytos.util.KeyPress as KeyPress

def convPath(unixPath):
    """
    Converts path if necessary in Windows
    We wish to harness the path checking of ParseArgs, but ParseArgs
    needs the path to include the path from the harddrive to the cygwin
    root directory.  (ex. it needs /cygwin/opt/tinyos-1.x/... or
    c:/cygwin/opt/tinyos-1.x/.. or c:\\cygwin\\opt\\tinyos-1.x\\..)
    There is no standard way to know this (like a $CYG_HOME environment variable)
    so we must rely on cygpath -w
    """
    if sys.platform.startswith('win') or (sys.platform == 'cygwin'):
        # this assumes cygpath is still in your windows path
        return os.popen( "cygpath -w " + unixPath ).read()[:-1]
    else:
        return unixPath

def promptAppType(appType):
    """
    Check appType to see if it is valid.  If not, prompts user for a
    choice.  Returns appType.
    """
    banner = """
    Please choose the main application type:
    Press 't' for TestDetectionEvent with metrics (Kraken)
    press 'm' for MetricsMote
    """
    if not (appType in ("TestDetectionEvent", "MetricsMote")):
        print banner
        keyPress = KeyPress.KeyPress()
        while True :
            try :
                key = keyPress.getChar(blocking=True)
                if key == 't':
                    print "TestDetectionEvent selected"
                    appType = "TestDetectionEvent"
                    break
                if key == 'm':
                    print "MetricsMote selected"
                    appType = "MetricsMote"
                    break
                else :
                    print "key %s not understood." % key
                    print banner
            except Exception, e:
                if len(e.args)>0:
                    print e.args[0]
                else :
                    raise
                print "key %s not understood." % key
                print banner
    return appType

def promptBuildTree(appType,buildTree):
    """
    Checks if appType supports Drain trees (ex. appType ==
    'TestDetectionEvent') and if buildTree is valid ('tree',
    'notree').  If yes and no, prompts user whether to build a Drain
    tree .  Returns noTreeFlag.
    """
    # We never build a tree for MetricsMote
    if (appType == "TestDetectionEvent"):
        if (buildTree == 'tree'):
            noTreeFlag = False
        elif (buildTree == 'notree'):
            noTreeFlag = True
        else:
            banner2 = "Would you like to start a drain tree? (y/n)"
            print banner2
            keyPress = KeyPress.KeyPress()
            while True :
                try :
                    key = keyPress.getChar(blocking=True)
                    if key == 'y':
                        print "Drain Tree will be built"
                        noTreeFlag = False
                        break
                    if key == 'n':
                        print "Drain Tree will not be built"
                        noTreeFlag = True
                        break
                    else :
                        print "key %s not understood." % key
                        print banner2
                except Exception, e:
                    if len(e.args)>0:
                        print e.args[0]
                    else :
                        raise
                    print "key %s not understood." % key
                    print banner2
    else:
        noTreeFlag = True
    return noTreeFlag



## Main ##
# NOTATION/VARIABLE NAMES: c is for clicker (MarkSeq is a "clicker" mote)

#assumes tosroot is still in unix format, e.g.'/opt/tinyos-1.x'
tosroot = os.environ['TOSROOT'] 

mPath = convPath(tosroot+'/contrib/nestfe/nesc/apps/MetricsTools/MetricsMote/build/telosb')
kPath = convPath(tosroot+'/contrib/nestfe/nesc/apps/TestDetectionEvent/build/telosb')
cPath = convPath(tosroot+'/contrib/nestfe/nesc/apps/MetricsTools/MarkSeq/build/telosb')

# ParseArgs needs a dummy '\\' argument to work (using '' doesn't work)
mArgs = ParseArgs.ParseArgs(['\\', mPath, 'sf@localhost:9001'])
kArgs = ParseArgs.ParseArgs(['\\', kPath, 'sf@localhost:9001'])
cArgs = ParseArgs.ParseArgs(['\\', cPath, 'sf@localhost:9002'])

# Parses appType and buildTree input  arguments
if (len(sys.argv) > 2):
    appType = sys.argv[2]
else:
    appType = None
if (len(sys.argv) > 3):
    buildTree = sys.argv[3]
else:
    buildTree = None
appType = promptAppType(appType)
noTreeFlag = promptBuildTree(appType,buildTree)



# 'localCommOnly' is used in RoutingMessages.py to determine whether to build
# a Drain tree
if (appType == "MetricsMote"): # mApp
    app = NescApp.NescApp(mArgs.buildDir, mArgs.motecom, tosbase=True, localCommOnly=True)
elif (appType == "TestDetectionEvent"): #kApp
    app = NescApp.NescApp(kArgs.buildDir, kArgs.motecom, tosbase=True, localCommOnly=noTreeFlag)

#cApp = NescApp.NescApp(cArgs.buildDir, cArgs.motecom, tosbase=True, localCommOnly=False)

## Clean up environment ##
del tosroot
del mPath
del kPath
del cPath
del mArgs
del kArgs
del cArgs
del buildTree
del noTreeFlag
del convPath
del promptAppType
del promptBuildTree

if (appType != None):
    # MetricsTools requires app and appType to be defined
    if (sys.argv[1] == 'mon'):
        print "Monitoring Window"
        from MetricsMonitor import *
    elif (sys.argv[1] == 'lat'):
        print "Latency Window"
        from MetricsLatency import *
    else: # assume sys.argv[1] == 'tools'
        print "Tools Window"
        from MetricsTools import *
        from KrakenTools import *
        from TestDetectionEvent import *

