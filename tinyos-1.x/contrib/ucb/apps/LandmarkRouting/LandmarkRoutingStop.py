from net.tinyos.message.avrmote import BaseTOSMsg
import simtime
delay = simtime.onesec
data = [0,208,7,0,0]
pursuerNode = 102

for i in range (2,len(motes)):
    if i.getID() == pursuerNode:
        continue
    msg = BaseTOSMsg()
    msg.set_addr(i)
    msg.set_type(99)
    msg.set_group(221)
    msg.set_length(5)
    msg.set_data(data)
    comm.sendRadioMessage(i, sim.getTossimTime() + delay, msg)
    delay += 10
