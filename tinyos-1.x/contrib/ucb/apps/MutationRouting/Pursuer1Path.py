from simcore import *
from net.tinyos.sim.event import RadioMsgSentEvent

pursuer1 = sim.__driver.pluginManager.getPlugin("1Plugin")
#pursuerNode = 102
#pursuerMote = motes[pursuerNode]

if not pursuer1.isRegistered():
    sim.loadPlugin("Pursuer1Plugin")

if sim.__driver.getScriptArgs() != None:
    pmatch = sim.__driver.getScriptArgs().split(' ')
    for pi in pmatch:
        pm = pi.split('=')
        if pm[0] == "-pursuer":
            pf = open(pm[1], 'r')
else:
    pf = open('p1path', 'r')

xplabel = pursuer1.parameterPane.getComponent(1)
yplabel = pursuer1.parameterPane.getComponent(3)
pursuer1.parameterPane.getComponent(10).setSelected(0)
poldline = "0," + xplabel.getText() + "," + yplabel.getText()
pline = pf.readline()
pm = pline.split(',')
xplabel.setText(pm[1])
yplabel.setText(pm[2])
pursuer1.update()

def pposition(event):
    global pline, poldline, xplabel, yplabel, pursuer1
    #print line
    pmatch = pline.split(',')
    ptime = long(pmatch[0])
    #time = (time / 4000.0) / 1000.0
    #print str(time) + ", " + str(sim.__driver.getTossimTime())
    while ptime <= sim.__driver.getTossimTime():
        poldline = pline
        pline = pf.readline()
        if pline == None:
            #print  "End of input file (simulation paused)"
            sim.pause()
        pmatch = pline.split(',')
        ptime = long(pmatch[0])
        #time = (time / 4000.0) / 1000.0
        #print "\t" + str(time)
    #print oldline
    pmatch = poldline.split(',')
    xp = pmatch[1]
    yp = pmatch[2][:-1]
    xplabel.setText(xp)
    yplabel.setText(yp)
    pursuer1.update()

p1p = interp.addEventHandler(pposition, RadioMsgSentEvent)
