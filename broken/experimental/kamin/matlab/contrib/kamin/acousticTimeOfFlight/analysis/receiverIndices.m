function indices=receiverIndices(receiverID, numParams)
indices = [receiverID+numParams:receiverID+2*numParams-1];