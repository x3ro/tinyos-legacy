from simcore import *
from net.tinyos.message.avrmote import BaseTOSMsg
import simtime

if (sim.getTossimTime() < simtime.secs(12)):
    delay = 0
else:
    delay = simtime.onesec

if sim.__driver.getScriptArgs() != None:
    match = sim.__driver.getScriptArgs().split(' ')
    for i in match:
        m = i.split('=')
        if m[0] == '-rate':
            data = [1, int(m[1]) % 256, int(m[1])/256, 0, 0]
else:
    data = [1,208,7,0,0] # 2000 ms

for i in range (2,len(motes)):
    msg = BaseTOSMsg()
    msg.set_addr(i)
    msg.set_type(130)
    msg.set_group(221)
    msg.set_length(5)
    msg.set_data(data)
    if (sim.getTossimTime() < simtime.secs(12)):
        comm.sendRadioMessage(i, simtime.secs(12) + delay, msg)
    else:
        comm.sendRadioMessage(i, sim.getTossimTime() + delay, msg)
    delay += 10
