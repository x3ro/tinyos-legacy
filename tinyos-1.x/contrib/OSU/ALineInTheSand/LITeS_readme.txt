/**
 * Copyright (c) 2003 - The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.

 Author: Sandip Bapat (bapat@cis.ohio-state.edu)
 Revision: 1
 Last modified: 12/1/2003
 */

Contents
- Overview of the LITeS system
- Module descriptions
	- Magnetometer
 	- MIR
	- GridRouting
	- ReliableComm
	- Reporter
- Compilation and Installation Instructions



Overview
---------
This document provides a high-level overview of the various components in the LITeS software. LITeS or "A Line In The Sand", demonstrated successfully in August 2003, is a classification and tracking system implemented using MICA2 sensor nodes developed at Berkeley. The system is capable of accurately detecting, classifying and tracking three types of intruders - armed dismounts (soldier carrying a gun), unarmed dismounts (civilians) and vehicles (car, tank). The system uses magnetometers and micropower impulse radar (MIR) or motion sensors. While all three intruder types will be detected by the motion sensors, roughly speaking, the absence of a magnetic disturbance is used to distinguish civilians from soldiers and vehicles, whereas the amount of metallic content and hence the amount of magnetic disturbance created by a soldier and a vehicle is used as a discriminator to classify them accurately.

The basic idea used for classification and tracking is of an influence field. Roughly speaking, the influence field of a target can be defined as the number of sensors that can detect it at the same time. A vehicle has a much larger magnetic influence field than a soldier does. We exploit this fact to distnguish between the two. 


Module descriptions
--------------------
The LITeS system is made up of several components wired together to achieve the desired functionality. A high level description of these components is given below:


* Magnetometer sensing and processing - This component uses the Honeywell 2 axis magnetometer found on the Mica2 sensor board to detect variations in the earth's magnetic field. This module first performs the task of sampling the magnetometer outputs. It is worth noting that the X axis and Y axis readings have been separated to minimize false positives in detection. The sampled values are then passed through a low pass filter to smoothen out the effects of noise. These smoothed values are then buffered in a window and passed through a moving statistics module that computes various statistical functions on this window. One of the functions used in the system is a moving variance. Whenever the variance exceeds a certain threshold, an event is said to be detected. This threshold value is decided by analyzing the data collected during experiments with the different intruder types. Additional information on the specific filtering algorithms, statistical metrics, etc used in the magnetometer based processing can be found in the Magsensor folder.

* MIR sensing and processing - This module uses the Advantaca micropower impulse radar or MIR sensor to detect motion of an intruder as it passes through the sensor's field of view. The Advantaca MIR has a digital as well as analog output. In order to minimize false positives and false negatives in detection, the LITeS system uses the analog signals from the MIR for detection. The structure of this module is quite similar to the magnetometer processing module in that it performs similar sampling, filtering, buffering and statistic calculation functions. However the algorithms and statistical measures used for doing this are different from those used in the magnetometer module. Additional information about this processing can be found in the MIRsensor folder.

* Time synchronization - Whenever a detection takes place at an individual sensor node, it needs to be stamped with the current global time so that the classifier can correlate all detections occuring at the same time to calculate the influence field. In order to do this, the nodes need to maintain time values that are synchronized over the entire network. The time synchronization or timesync service provides this global clock synchronization. Information about the algorithm used for timesync, accuracy provided, etc can be found in the Timesync folder.

* GridRouting - The local timestamped detections need to be communicated to a central classifier node which may not be its direct communication range. For this reason, a multi-hop routing service called GridRouting is used. In GridRouting, the network is modeled as a logical grid of nodes. The GridRouting service assumes the presence of a neighborhood detection service and provides some nice security and stabilization properties by imposing certain restrictions on the choice of parents and routes. GridRouting is also flexible and efficient in the sense that a link need not be a single hop in the logical grid, rather it can be a function of the transmission power of the nodes, i.e. the links can be dilated to reduce the number of hops in the network. More details on the GridRouting protocol and the properties provided by it can be found in the GridRouting folder.

* Reliable communication - The medium of communication in the LITeS system is wireless. The basic communication mechanism is broadcast and we do not assume directional antennae or frequency hopping. Due to this, messages from nodes get lost due to collision if they are transmitted at the same time. This is a major problem as it affects the reliability of messages over a single hop and consequently the end-to-end reliability of messages over the network. To achieve an acceptable reliability of communications, an implicit acknowledgement based reliable communication service, ReliableComm, is used. The basic idea behind ReliableComm is that each node listens to the communications of its parent whenever it sends some data intended for the classifier to its parent. If a node receives the forwarded message from the parent, it knows that its message has been received and forwarder. If it does not see the forwarded message in some bounded period of time, it assumes that the message was lost and retransmits it. The service is flexible and can be tuned easily in order to provide the degree of reliablity desired in the amount of end-to-end latency acceptable to the application. Additional documentation about this service can be found in the ReliableComm folder.

* Reporter - The reporter service is the high level module that accepts detection events from the magnetometer and motion sensors, composes the message to be sent to the classifier by adding a sequence number, type of event detected (start/end), type of sensor and other such information that can help the classifier make its decision. The Reporter module then passes the message to the GridRouting service which is responsible for routing the message to the classifier.


Compilation and Installation Instructions
=========================================

Non base station motes:

a) Magnetometer based motes
1. Copy all the files from the GridRouting, ReliableComm, TimeSync and MagSensor folders into a single folder
2. Use the Makefile from the MagSensor folder to compile the application.

b) MIR based motes
1. Copy all the files from the GridRouting, ReliableComm, Timesync and MIRSensor folders into a single folder
2. Use the Makefile from the MIRSensor folder to compile the application 

Base station
1. Copy only the files from the GridRouting and ReliableComm folders into a single folder
2. Use the Makefile from the GridRouting folder to compile the application
3. The base station should have node id 0.
