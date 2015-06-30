# Generic tools for interacting with Kraken Applications

import os, sys
from time import sleep
from __main__ import app


# Assumes that locationFile is in format of testbed programming
# configuration files in tinyos-1.x/contrib/testbed/testbed
# * format: mote <mote_id> <ip_address|host name> [<position x> <position y>]
#   ~ the <ip_address|host name> is ignored
#   ~ the positions must be integers.  Otherwise, they will be rounded
def locationSet(locationFile):
   """ Sets the position of motes using the locations in locationFile.
   """

   if locationFile.find('/') == -1 :
      cfgRoot = '/opt/tinyos-1.x/contrib/nestfe/configurations'
      if sys.platform.startswith('win') or (sys.platform == 'cygwin'):
         # this assumes cygpath is still in your windows path
         cfgRoot = os.popen( "cygpath -w " + cfgRoot ).read()[:-1]
         locationFile = cfgRoot + '\\' + locationFile
      else: # just assume its linux/unix
         locationFile = cfgRoot + '/' + locationFile

   print "Using locationFile at " + locationFile
   f = open(locationFile,'r')
   locationData = f.readlines()
   f.close()

   for i in range(0,len(locationData)):
      fieldList = locationData[i].split()
      if (len(fieldList) == 5) and (fieldList[0] == 'mote'):
         moteID = int(fieldList[1])
         ipAddr = fieldList[2] #not used
         xPos = int(round(float(fieldList[3])))
         yPos = int(round(float(fieldList[4])))
         app.RegistryC.Location.set.val.x = xPos
         app.RegistryC.Location.set.val.y = yPos
         print("setting address for mote %d, (x,y) = (%d,%d)"
               %(moteID,xPos,yPos))
         print app.RegistryC.Location.set(address=moteID)
         sleep(0.1)


## UNTESTED
def queryLoc(*moteIDs):
   """Queries the location of the motes.
   """

   for mote in moteIDs:
      print('>>>>> app.RegistryC.Location.get(address=%d)' %(mote))
      print app.RegistryC.Location.get(address=mote)
      sleep(0.1)


def queryVolt(*moteIDs):
   """Queries the voltages of the motes.
   """

   for mote in moteIDs:
      print('>>>>> app.PrometheusM.volCap.peek(address=%d)' %(mote))
      print app.PrometheusM.volCap.peek(address=mote)
      sleep(0.1)
      print('>>>>> app.PrometheusM.volBatt.peek(address=%d)' %(mote))
      print app.PrometheusM.volBatt.peek(address=mote)
      sleep(0.1)
