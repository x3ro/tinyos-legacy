from simcore import *
from net.tinyos.sim.event import LedEvent
import math

pursuer1 = sim.__driver.pluginManager.getPlugin("1Plugin")
evader = sim.__driver.pluginManager.getPlugin("EvaderPlugin")

eprev = 0
pprev = 0

if not pursuer1.isRegistered():
    sim.loadPlugin("Pursuer1Plugin")

if not evader.isRegistered():
    sim.loadPlugin("EvaderPlugin")

def closest(event):
    global eprev, pprev
    xe = evader.getXPosition()
    ye = evader.getYPosition()
    mindist = -1
    for i in motes:
	if eprev != 0 and eprev != i.getID() and radio.getLossRate(eprev, i.getID()) > .3:
	    continue
        x = i.getXCoord()
        y = i.getYCoord()
        newdist = math.sqrt(math.pow(xe-x,2) + math.pow(ye-y,2))
        if mindist == -1 or newdist < mindist:
            mindist = newdist
            emote = i

    #print str(emote.getID()) + " closest to evader"
    comm.setADCValue(emote.getID(),sim.getTossimTime()+10,74,1)
    comm.setADCValue(emote.getID(),sim.getTossimTime()+10,128,int(emote.getXCoord()))
    comm.setADCValue(emote.getID(),sim.getTossimTime()+10,129,int(emote.getYCoord()))

    xp = pursuer1.getXPosition()
    yp = pursuer1.getYPosition()
    mindist = -1
    for i in motes:
	if pprev != 0 and pprev != i.getID() and radio.getLossRate(pprev, i.getID()) > .3:
	    continue
        x = i.getXCoord()
        y = i.getYCoord()
        newdist = math.sqrt(math.pow(xp-x,2) + math.pow(yp-y,2))
        if mindist == -1 or newdist < mindist:
            mindist = newdist
            pmote = i

    #if pmote != emote:
        #print str(pmote.getID()) + " closest to pursuer1"
    comm.setADCValue(pmote.getID(),sim.getTossimTime()+10,74,2)
    comm.setADCValue(pmote.getID(),sim.getTossimTime()+10,128,int(pmote.getXCoord()))
    comm.setADCValue(pmote.getID(),sim.getTossimTime()+10,129,int(pmote.getYCoord()))

    for i in motes:
        if i.getID() != emote.getID() and i.getID() != pmote.getID():
            comm.setADCValue(i.getID(), sim.getTossimTime()+10,74,0)

    eprev = emote.getID()
    pprev = pmote.getID()

mrl = interp.addEventHandler(closest, LedEvent)
