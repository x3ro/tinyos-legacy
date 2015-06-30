Revision 1.1	May 13, 1004
Author: Sandip Bapat 

Application: Integrated Acoustic Detector 
Lib components used: AcousticSensor, Timesync, GridRouting, ReliableComm

Notes:

This application integrates an Acoustic Detector with Timesync, Routing and Reliable transport.

The Acoustic detector produces start and stop events corresponding to when a noise-producing target enters and leaves its detection range respectively. The Aggregator module timestamps each detection event, assigns a sequece number and sends it in a message using the communication stack.

The GridRouting module provides the routing tree and the ReliableComm module, which uses implicit-ack based retransmissions, ensures that messages are delivered with high probability to the base station.



