from simcore import *
from net.tinyos.sim.event import RadioMsgSentEvent

pursuer1 = sim.__driver.pluginManager.getPlugin("1Plugin")

if not pursuer1.isRegistered():
    sim.loadPlugin("Pursuer1Plugin")

xplabel = pursuer1.parameterPane.getComponent(1)
yplabel = pursuer1.parameterPane.getComponent(3)
xplabel.setText("20")
yplabel.setText("80")
pursuer1.parameterPane.getComponent(10).setSelected(0)
pursuer1.update()

ppf = open('p1path', 'w')
ptime = 0

def pposition(event):
    global ptime
    xp = pursuer1.getXPosition()
    yp = pursuer1.getYPosition()
    pnewtime = event.getTime()
    if pnewtime != ptime:
        ppf.write(str(pnewtime) + ',' + str(xp) + ',' + str(yp) + "\n")
        ppf.flush()
        ptime = pnewtime;

p1pg = interp.addEventHandler(pposition, RadioMsgSentEvent)

def pstart(event):
    global pursuer1
    ptime = event.getTime()
    if (ptime >= 20 * 4000 * 1000):
        #pursuer1.parameterPane.getComponent(5).setText("0.5")
        pursuer1.parameterPane.getComponent(10).setSelected(1)
        pursuer1.update()
        interp.removeEventHandler(p1pgs)

p1pgs = interp.addEventHandler(pstart, RadioMsgSentEvent)
