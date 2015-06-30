from simcore import *
from net.tinyos.sim.event import DebugMsgEvent

def wait(event):
    id = event.getMoteID()
    w = event.getMessage()
    if (w[0:4] == 'wait' and w[4] == ' '):
        #print w
        motes[id].setLabel(w[8:],10,2)

mrw = interp.addEventHandler(wait, DebugMsgEvent)
