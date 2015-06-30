#!/bin/bash

echo "Make sure that build/pc/main.exe is running"
java net.tinyos.sim.SimDriver -nosf -script "simPIRDetect.py" -scriptargs "sampleFiles/GGB_InputData"
#java net.tinyos.sim.SimDriver -nosf -script "simPIRDetect.py" -scriptargs "samplefiles/XSM_11samplepktsInputData"
#java net.tinyos.sim.SimDriver -nosf -script "simPIRDetectBatch.py" -scriptargs "testdir"


# I've observed some weird behavior, where the Java simulation
# variable 'motes' does not get reset between simulations.  This seems
# to be a race condition where the simulator does not update tython in
# time.  Not sure if using this option to java will make the race
# condition worse, so keeping it out for now.
# -Dpython.cachedir=/tmp/jython.cache
