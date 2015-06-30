#$Id: simPIRDetect.py,v 1.2 2005/07/19 17:47:46 phoebusc Exp $
# First, run in a separate window:
#   build/pc/main.exe -b=1 -gui 5 # assuming 5 nodes in your file
# Then, run like this at TestPIRDetectNoReg directory:
#   java net.tinyos.sim.SimDriver -nosf -script "simPIRDetect.py" -scriptargs "filename simLogName"
#
# This script will:
#   1) Figure out the number of nodes that have data in the "filename" argument.
#   2) Feed in adc readings from "filename" to the parallel simulation
#   3) Collect simulation output in "filename"_output
#
# INPUT:
# - See parseInput.py for Input file format for parsing... you will need to
#   edit the arguments used in the script to call parseInput.parseFile()
#
# OUTPUT:
# - Dumps Raw Oscope Messages in "filename"_output
# - Alternately, if you can also use tossim-radio on the SerialForwarder
#   and Listen.java to dump Oscope output to a file
# - Appends to simLog file with important messages (ex. file skipped)
#
# NOTE:
# - Look at ADCread() for how to cleanup and end simulation
# - Does not actually process last piece of data injected by ADC,
#   because resets simulator.  Not perceived to be a big problem.

from simcore import *
from net.tinyos.sim.event import DebugMsgEvent
from net.tinyos.sim.event import ADCDataReadyEvent
from net.tinyos.sim.event import UARTMsgSentEvent
from net.tinyos.sim.event import RadioMsgSentEvent
from net.tinyos.sim.event import SimEventBus
from net.tinyos.sim.event import TossimInitEvent

from net.tinyos.oscope import oscilloscope
from net.tinyos.oscope import OscopeMsg

from os.path import isfile
from time import sleep
import parseInput

#### Global Variables ####
ADCport = 1 # default PIR Sensor Port
out = "" # file handle for output file

simLogname = "simPIRDetect_messages" # for noting skipped files, etc.

# not strictly necessary to list here, but for reader reference
simLog = None
filename = ""
outFilename = ""


## 1) calls function to parse input data and store in
##    (data,nodeState,minSeqNo,maxSeqNo)
## 2) sets up remaining global variables (see global declaration)
## 3) Checks that TOSSIM simulation has enough nodes for script
##      aborts/proceeds to next file if not
## 4) opens output file for writing
## 5) registers event handlers with simulator
def setupSim():
    global data, nodeState, minSeqNo, maxSeqNo, currentSeqNo
    global numNodes, totalFinished, out

    print("Preparing to simulate using " + filename)
    dataList = parseInput.parseFile("xsm",filename)

    data = dataList[0]
    nodeState = dataList[1]
    minSeqNo = dataList[2]
    maxSeqNo = dataList[3]
    currentSeqNo = {}
    for i in nodeState.keys():
        currentSeqNo[i] = 0
    totalFinished = 0
    numNodes = len(nodeState)

    sleep(1) #make sure that the simulator has time to update 'motes'
    # Check that we have more simulated motes than the largest moteID
    # otherwise, the script will never end. (use 'motes' from simcore)
    if (max(nodeState.keys()) >= len(motes)):
        simLog.write("Skipping file %s.\n" %filename)
        simLog.write("\t File has largest mote ID = %d.  The simulator is only simulating %d nodes.\n"
                       %(max(nodeState.keys()), len(motes)))
        simLog.write("\t The simulator needs to simulate 1 node more than the largest mote ID.\n")
        print("Skipping file %s." %filename)
        print("\t File has largest mote ID = %d.  The simulator is only simulating %d nodes."
              %(max(nodeState.keys()), len(motes)))
        print("\t The simulator needs to simulate 1 node more than the largest mote ID.")
    else:
        out = open(outFilename,'w')
        print("Outputting to %s" %outFilename)
        print "Simulation with " + str(numNodes) + " nodes"

        #uart_event = interp.addEventHandler(printUART, UARTMsgSentEvent)
        radio_event = interp.addEventHandler(printRadio, RadioMsgSentEvent)
        dbg_event = interp.addEventHandler(printDBG, DebugMsgEvent)
        adc_event = interp.addEventHandler(ADCread, ADCDataReadyEvent)
        init_event = interp.addEventHandler(handleInit, TossimInitEvent)
        sim.resume() #in case we miss an init_event signaled earlier



##### Event Handlers Start #####

## Reads ADC values from 'data' and injects it to the ADCport of the
## appropriate mote.
## Also includes cleanup code to finish one simulation
def ADCread(event):
    global nodeState, currentSeqNo, totalFinished, out
    
    nodeID = event.getMoteID()
    thisTime = sim.__driver.getTossimTime()

    if not(nodeState.has_key(nodeID)):
        comm.setADCValue(nodeID,thisTime+1,ADCport,0)
        print("ADCread: nodeID %d has no input data, set ADCport to 0"
              %(nodeID))
        return
    
    seqNo = currentSeqNo[nodeID] + minSeqNo[nodeID]
    currentSeqNo[nodeID] += 1
    key = str(nodeID) + '_' + str(seqNo)
    print("seqNo: " + str(seqNo))
    print("maxSeqNo[%d]: %d" %(nodeID, maxSeqNo[nodeID]))
    #print("key: " + str(key))
    #print("data: " + str(data))
    if data.has_key(key):
        value = data[key]
        comm.setADCValue(nodeID,thisTime+1,ADCport,value)
    else:
        comm.setADCValue(nodeID,thisTime+1,ADCport,0)
        if (seqNo >= maxSeqNo[nodeID]):
            if (nodeState[nodeID] == 1):
                print("Finished nodeID: " + str(nodeID))
                nodeState[nodeID] = 2
                totalFinished += 1
            if (totalFinished == numNodes): ##SIMULATION FINISH CLEANUP CODE
                print("Ran out of ADC readings for all nodes in " + filename)
                print("Closing " + outFilename)
                finishSim()
        else: # we lost some data (data was set to 0)
            print("ADCread: input data for node %d at time %.2f, sequence number %d missing"
                  %(nodeID, (thisTime+1), seqNo))

	
### Helper function for printing
# make sure get two digits for each byte string
# dataHex is a 'hex number' with length 3 or 4
# (has '0x' before each string)
def twoHexDigits(dataHex):
    if (len(dataHex) == 4):
        return str(dataHex[2:])
    elif (len(dataHex) == 3):
        return "0" + str(dataHex[2:])
    else:
        print "2-digit Hex Conversion Error, wrong length input: " + dataHex
        return "00"


#def printRadio(event):
    #time = sim.__driver.getTossimTime()
    #secTime = (time / 4000.0) / 1000.0
    #out.write('time: ' + str(secTime) + "\n")
    #out.write(event.toString() + "\n")
    #print 'time: %.2f' %(secTime)
    #print event


def printRadio(event):
    print event
    msg = event.getMessage().dataGet()
    s = ""
    for i in range(0,len(msg)):
       s += twoHexDigits(hex(0xff & msg[i])) + " "
    s+= "\n"
    out.write(s)
    #out.flush()


def printDBG(event):
    thisTime = sim.__driver.getTossimTime()
    secTime = (thisTime / 4000.0) / 1000.0
    s = event.toString()
    if ((s.find(' - ') != -1) and
        ((s.find('TestPIRDetectM') != -1) or
         (s.find('OscopeM') != -1))):
        #out.write('time: ' + str(secTime) + "\n")
        #out.write(event.toString() + "\n")
        print('time: %.2f' %(secTime))
        print event


def handleInit(event):
    sim.resume()

##### Event Handlers Stop #####


## called by the main program or ADCread after
## to finish the simulation
def finishSim():
    simLog.write("Finished simulation on file %s\n" %filename)
    simLog.close()
    out.close()
    sim.stop()
    sim.exit()
    print("Finished simulation on file %s" %filename)



### Main Program ###
## remember, must start up TOSSIM as a separate process before starting
## this script
inputArg = sim.__driver.getScriptArgs()
argsList = inputArg.split()
if len(argsList) > 1:
    simLogname = argsList[1]
simLog = open(simLogname,'a') # for writing important, short output messages
filename = argsList[0]

if isfile(filename):
    outFilename = filename + "_output"
    setupSim()
else:
    print("%s is not a valid filename" %inputArg)

