# source this file in your .profile

# monstro stuff
export MONSTROROOT=$TOSROOT/contrib/ucb/apps/Monstro
export PYTHONPATH=$MONSTROROOT/libGps/src:$MONSTROROOT/lib:$PYTHONPATH
export CLASSPATH=$MONSTROROOT/libGps/src:$CLASSPATH
export LD_LIBRARY_PATH=$MONSTROROOT/libGps/src:$LD_LIBRARY_PATH

# pytos
export PYTHONPATH=$TOSROOT/contrib/python:$PYTHONPATH
export CLASSPATH=$TOSROOT/contrib/python/pytos:$CLASSPATH
