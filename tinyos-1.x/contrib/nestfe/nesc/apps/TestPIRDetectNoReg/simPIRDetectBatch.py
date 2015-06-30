#$Id: simPIRDetectBatch.py,v 1.1 2005/07/19 17:47:46 phoebusc Exp $
#
# NOT FULLY WORKING.  SEE NOTES.
#
# First, run in a separate window:
#   build/pc/main.exe -b=1 -gui 5 # assuming 5 nodes in your file
# Then, run like this at TestPIRDetectNoReg directory:
#   java net.tinyos.sim.SimDriver -nosf -script "simPIRDetect.py" -scriptargs "filename"
#
# This script will:
#   1) Figure out the number of nodes that have data in the "filename" argument.
#   2) Feed in adc readings from "filename" to the parallel simulation
#   3) Collect simulation output in files
#   4) never exit the simulator... just reset it for the next input file, if any
#
# INPUT:
# - If "filename" is a directory, processes all files in the directory
#   that do not end in '_output'.  Otherwise, just process the file.
# - See parseInput.py for Input file format for parsing
#
# OUTPUT:
# - Dumps Raw Oscope Messages
# - "filename"_output (or a directory worth of "filename"_output)
# - Alternately, if you can also use tossim-radio on the SerialForwarder
#   and Listen.java to dump Oscope output to a file
# - batchOut file with important messages for batch of simulations
#   (ex. files skipped)
#
# NOTE:
# - Currently, batch mode within simPIRDetect.py does not work properly because
#   of issues with getting sim.exec() working or finding a version of sim.reset()
#   that gets us back to the initial state of the simulator, with a certain number
#   of nodes started.
# - Look at ADCread() for how to cleanup and start next simulation with nextFile() 
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

from os import listdir
from os.path import isfile, isdir
from time import sleep
from re import search

import parseInput

#### Global Variables ####
ADCport = 1 # default PIR Sensor Port
out = None # file handle for output file
init_event = None # used to start the next simulation

# for batchs on directories
firstExecution = True
batchOutname = "simPIRDetect_messages" # for noting skipped files, etc.

# not strictly necessary to list here, but for reader reference
batchOut = None
filename = ""
outFilename = ""
dirname = ""
fileList = []


## Called for each separate simulation for setup
## 1) registers event handlers with simulator
## 2) calls function to parse input data and store in
##    (data,nodeState,minSeqNo,maxSeqNo)
## 3) sets up remaining global variables (see global declaration)
## 4) Checks that TOSSIM simulation has enough nodes for script
##      aborts/proceeds to next file if not
## 5) opens output file for writing
## - Note that some commands (like registering event handlers) 
##   must happen only once for all file simulations.
## - Aborting a simulation involves not registering the
##   init_event handler and processing the next file
def setupSim():
    global data, nodeState, minSeqNo, maxSeqNo, currentSeqNo
    global numNodes, totalFinished, out, firstExecution, init_event

    # only execute once for all input files
    if (firstExecution):
        #   uart_event = interp.addEventHandler(printUART, UARTMsgSentEvent)
        radio_event = interp.addEventHandler(printRadio, RadioMsgSentEvent)
        dbg_event = interp.addEventHandler(printDBG, DebugMsgEvent)
        adc_event = interp.addEventHandler(ADCread, ADCDataReadyEvent)
        firstExecution = False

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

    sleep(2) # wait for simulator to catch up and update 'motes'
    # Check that we have more simulated motes than the largest moteID
    # otherwise, the script will never end. (use 'motes' from simcore)
    if (max(nodeState.keys()) > len(motes)):
        batchOut.write("Skipping file %s.\n" %filename)
        batchOut.write("\t File has largest mote ID = %d.  The simulator is only simulating %d nodes.\n"
                       %(max(nodeState.keys()), len(motes)))
        batchOut.write("\t The simulator needs to simulate 1 node more than the largest mote ID.\n")
        print("Skipping file %s." %filename)
        print("\t File has largest mote ID = %d.  The simulator is only simulating %d nodes."
              %(max(nodeState.keys()), len(motes)))
        print("\t The simulator needs to simulate 1 node more than the largest mote ID.")
        nextFile()
    else:
        out = open(outFilename,'w')
        print("Outputting to %s" %outFilename)
        init_event = interp.addEventHandler(handleInit, TossimInitEvent)
        sim.resume() # in case the init event was signaled before scheduling the handler
        print "Simulation with " + str(numNodes) + " nodes"



##### Event Handlers Start #####

## Reads ADC values from 'data' and injects it to the ADCport of the
## appropriate mote.
## Also includes cleanup code to finish one simulation
def ADCread(event):
    global nodeState, currentSeqNo, totalFinished, out
    
    nodeID = event.getMoteID()
    thisTime = sim.__driver.getTossimTime()

    print nodeState
    if not(nodeState.has_key(nodeID)):
        comm.setADCValue(nodeID,thisTime+1,ADCport,0)
        print("ADCread: nodeID %d has no input data, set ADCport to 0"
              %(nodeID))
        return
    
    seqNo = currentSeqNo[nodeID] + minSeqNo[nodeID]
    currentSeqNo[nodeID] += 1
    key = str(nodeID) + '_' + str(seqNo)
    #print("seqNo: " + str(seqNo))
    #print("maxSeqNo[%d]: %d" %(nodeID, maxSeqNo[nodeID]))
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
                out.close()
                interp.removeEventHandler(init_event) # for next simulation
                sim.stop()
                sim.reset() #unfortunately, resets all motes to 0 again
                nextFile()
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
## finishing simulating with one file to call setupSim()
## for next simulation with proper filenames, or to finish
## the batch of simulations.
def nextFile():
    global filename, outFilename, fileList
    fileFlag = 0;
    while (len(fileList) > 0) and (fileFlag == 0):
        f = fileList.pop(0)
        f = dirname + '/' + f
        if (isfile(f) and (search('_output$',f) == None)):
            fileFlag = 1
            filename = f
            outFilename = filename + "_output"
            setupSim()
    # finishes immediately if last entries of fileList are directories
    if ((len(fileList) == 0) and (fileFlag == 0)):
        print "Finished simulation with file/all files in directory."
        batchOut.close()
        sim.exit()



### Main Program ###
## Currently, it is best to start up TOSSIM as a separate process
## I have not successfully gotten sim.exec() to work, even with multitest.py
## in tools/java/net/tinyos/sim/pyscripts
#sim.exec("build/pc/main.exe",numNodes,"-b=1")

batchOut = open(batchOutname,'w') # for writing important, short output messages
inputArg = sim.__driver.getScriptArgs()
if isfile(inputArg):
    dirname = "."
    fileList = [inputArg]
    nextFile()
elif isdir(inputArg): #directory looping
    dirname = inputArg
    fileList = listdir(inputArg)
    nextFile()
