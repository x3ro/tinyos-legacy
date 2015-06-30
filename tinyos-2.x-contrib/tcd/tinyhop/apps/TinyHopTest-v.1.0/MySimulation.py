# TOSSIM python script for the simulation of the HoppingTest application 
# using TinyHop and HoppingEngineM components to perform routing.
# Topologies for the network of nodes are available under folder Topologies/
# with the form: node1  node2  gain
# Also the meyer_heavy noise file from TOSSIM is employed which is a list of 
# noise values taken from the meyer library at Berkeley. 

# * @author Ricardo Simon Carbajo <carbajor {tcd.ie}>
# * @date   February 13 2009 
# * Computer Science
# * Trinity College Dublin

import sys
from random import *
from TOSSIM import *

t = Tossim([])
r = t.radio();

##########
#TOPOLOGY
##########

f = open("Topologies/NEW-12nodes-70db.txt", "r")


lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    if (s[0] == "gain"):
      #if (((int(s[1])) <= 30) & ((int(s[2])) <= 30)):
        print " ", s[1], " ", s[2], " ", s[3];
        r.add(int(s[1]), int(s[2]), float(s[3]));
	numNodes=int(s[1]);

######################
#NOISE TRACE & BOOTING
######################

noise = open("Noise/meyer-heavy-short.txt", "r")
#noise = open("Noise/meyer-heavy-medium.txt", "r")
#noise = open("Noise/meyer-heavy.txt", "r")

lines = noise.readlines()
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    for i in range(0, numNodes+1):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(0, numNodes+1):
  print "Creating noise model for ",i;
  t.getNode(i).createNoiseModel();

for i in range(0, numNodes+1):
  #bootTime=randint(1000,2000) * 1;
  #bootTime=(31 + t.ticksPerSecond() / 10) * i + 1;
  #bootTime=4 * t.ticksPerSecond() + 242119;
  #bootTime=i * 2351217 + 23542399;
  bootTime=(i* 1000000)+ randint(1000,2000);
  
  t.getNode(i).bootAtTime(bootTime);
  print "Boot Time for Node ",i, ": ",bootTime; 

#########
#CHANNELS
#########

#Log of what is going on in TinyHop & its application TinyHopTest
hop = open("Simulations/logHoppingEngineM.txt", "w")
t.addChannel("HoppingEngineM", hop);

#A complete log about what is going on at the low level, packets lost, snr, noise,...
#gain = open("Simulations/logGain.txt", "w")
#t.addChannel("CpmModelC,SNR", gain);
#t.addChannel("CpmModelC,SNRLoss", gain);
#t.addChannel("CpmModelC", gain);
#t.addChannel("HoppingEngineM", gain);
#t.addChannel("CpmModelC,Tal", gain);     #Return the noise value from the hash table created through meyer_heavy file

#Log of the hops and which packets are received or lost and how local repaired is done.
usr = open("Simulations/logTinyHopTest.txt", "w")
t.addChannel("TinyHopTest", usr);


##########
#EXEC LOOP
##########

print "Starting Simulation ..."

t.runNextEvent();
time=t.time();
            # 1000000000000 = 100 seconds
while (time + 4900000000000 > t.time()):
  t.runNextEvent();

print "Simulation Finished"