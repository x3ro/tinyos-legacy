# $Id: parseInput.py,v 1.2 2005/07/19 17:47:46 phoebusc Exp $
## Parses input file of OscopeMsgs
# Supports:
# 1) Default TinyOS packets of OscopeMsgs
#    (with 10 samples or even 11 samples per packet)
# 2) Telos packets of OscopeMsgs
# 3) GGB dumped output
# See PIRDataFormat.txt for details on these data formats
#
# "Commenting" in input files:
# * OscopeMsg formats: ignores all lines that have less than 'offset'
#   bytes.  Assumes these are Connection Strings, timestamps,
#   or other comments
# * GGB format: ignores all lines without length of 8 'bytes' (space
#   separated columns)


# PRECONDITION: all data on channel 0 (else will give warnings)
# @param format   value:'xsm', 'xsm_extraPkt', 'telos', 'ggb
# @returns list of:
#          data             dictionary (nodeID_seqNo,value)
#          nodeState        dictionary (nodeID_seqNo,value)
#                             value = 1 for 'initialized' node
#                             can change to other values to indicate finished, etc.
#          minSeqNo         dictionary (nodeID_seqNo,value)
#          maxSeqNo         dictionary (nodeID_seqNo,value)
def parseFile(format,filename):
    data = {}
    nodeState = {}
    minSeqNo = {}
    maxSeqNo = {}

    f = open(filename)
    pktData = f.readlines()
    f.close()

    if (format == 'xsm_extraPkt'):
        offset = 5
        pktSamples = 11
        OscopeMsgFormat = True
    elif (format == 'xsm'):
        offset = 5
        pktSamples = 10
        OscopeMsgFormat = True
    elif (format == 'telos'):
        offset = 10
        pktSamples = 10
        OscopeMsgFormat = True
    elif (format == 'ggb'):
        offset = 0
        OscopeMsgFormat = False

    if OscopeMsgFormat:
        for i in range(0,len(pktData)):
            byteList = pktData[i].split()
            if len(byteList) > offset:
                nodeID = int(byteList[offset+1]+byteList[offset],16)
                if not(nodeState.has_key(nodeID)):
                    nodeState[nodeID] = 1
                    minSeqNo[nodeID] = int('FFFF',16)
                    maxSeqNo[nodeID] = 0
                ## parse sequence numbers
                seqNo = int(byteList[offset+3]+byteList[offset+2],16)
                maxSeqNo[nodeID] = max(maxSeqNo[nodeID], seqNo)
                seqNo = seqNo - pktSamples # subtract pktSamples since the
                          #seqNo is actually the last seqNo in the message
                minSeqNo[nodeID] = min(minSeqNo[nodeID], seqNo)            
                ## check input on channel 0
                chanNo = int(byteList[offset+5]+byteList[offset+4],16)
                if (chanNo != 0):
                    print "WARNING: input data not from channel 0, from channel" + str(chanNo)
                    print "  File: " + filename + ", Line: " + str(i)
                ## parse data
                for j in range(offset+6, len(byteList), 2):
                    value = byteList[j+1] + byteList[j]
                    key = str(nodeID) + '_' + str(seqNo+((j-offset+6)/2))
                    data[key] = int(value, 16)
    else: #currently, defaults to GGB format
        for i in range(0,len(pktData)):
            byteList = pktData[i].split()
            if len(byteList) == 8:
                nodeID = 1 # should be from filename... fix later
                if not(nodeState.has_key(nodeID)):
                    nodeState[nodeID] = 1
                    minSeqNo[nodeID] = int('FFFF',16)
                    maxSeqNo[nodeID] = 0
                ## parse sequence numbers
                seqNo = int(byteList[offset]) # first 'byte' is already in decimal format
                maxSeqNo[nodeID] = max(maxSeqNo[nodeID], seqNo)
                minSeqNo[nodeID] = min(minSeqNo[nodeID], seqNo) # should always be 1
                ## clicker sequence number currently not used
                ## parse data
                value = byteList[6] + byteList[5]
                key = str(nodeID) + '_' + str(seqNo)
                data[key] = int(value, 16)

    return [data,nodeState,minSeqNo,maxSeqNo]



# ## Testing Code
# a = parseFile("xsm","samplefiles/XSM_11samplepktsInputData")
# print "nodeState: "
# print a[1]
# print "minSeqNo: "
# print a[2]
# print "maxSeqNo: "
# print a[3]
