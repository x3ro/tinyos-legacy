from simcore import *
from net.tinyos.sim.event import RadioMsgSentEvent

pursuer1 = sim.__driver.pluginManager.getPlugin("1Plugin")
#evader = sim.__driver.pluginManager.getPlugin("EvaderPlugin")

if not pursuer1.isRegistered():
    sim.loadPlugin("Pursuer1Plugin")

#if not evader.isRegistered():
#    sim.loadPlugin("EvaderPlugin")

#xelabel = evader.parameterPane.getComponent(1)
#yelabel = evader.parameterPane.getComponent(3)
#xelabel.setText("5")
#yelabel.setText("95")
#evader.parameterPane.getComponent(10).setSelected(0)
#evader.update()
xplabel = pursuer1.parameterPane.getComponent(1)
yplabel = pursuer1.parameterPane.getComponent(3)
xplabel.setText("20")
yplabel.setText("80")
pursuer1.parameterPane.getComponent(10).setSelected(0)
pursuer1.update()

pf = open('p1path', 'w')
time = 0

def position(event):
    global time
    xp = pursuer1.getXPosition()
    yp = pursuer1.getYPosition()
    newtime = event.getTime()
    if newtime != time:
        pf.write(str(newtime) + ',' + str(xp) + ',' + str(yp) + "\n")
        pf.flush()
        time = newtime;

p1pg = interp.addEventHandler(position, RadioMsgSentEvent)

def start(event):
    global pursuer1
    time = event.getTime()
    if (time >= 20 * 4000 * 1000):
        pursuer1.parameterPane.getComponent(5).setText("0.5")
        pursuer1.parameterPane.getComponent(10).setSelected(1)
        pursuer1.update()
        interp.removeEventHandler(p1pgs)

p1pgs = interp.addEventHandler(start, RadioMsgSentEvent)
