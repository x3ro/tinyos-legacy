Author/Contact: miklos.maroti@vanderbilt.edu (Miklos Maroti, ISIS, Vanderbilt)

DESCRIPTION:

This package implements message time stamping on the MICA and MICA2 motes with 
25 microsecond average error using a single radio message. The maximum observed 
error between 4 motes is around 50 microseconds. The accuracy is limited by the 
resolution of the clock (32.768 KHz).

The clock used for mesasuring the local time is Timer/Counter0 using the external
32.768 KHz crystal. This provides 30.5 microsecond time resolution. This package
implements the same TimeStamping interface than the SysTimeStamping that uses the
CPU clock and provides 1 microsec accuracy.

Time stamping is performed both at the sender and receiver side. At the sender 
side the time stamp is included in the message at the time of transmission. At 
the receiver side the time stamp, which is the local time at the time of 
reception, is recorded. The experimental verification and calibration of this 
algorithm involved 4 motes. Each mote sent 1 message per second. The node id of 
the sender, the local time of the sender at the time of transmission, the node 
id of the receiver, and the local time of the receiver at the time of reception 
is recorded and reported to a base station. The base station collected 500 such 
data points and using linear regression calculated the skew and offset of the 
clocks of the motes. Then the absolute error is calculated for each data point 
between the predicted receive time (based on the local clock of the sender at 
transmission time, using the skews and offsets of the sender and receiver) and 
the measured receive time. 

USAGE:

The local time of the mote can be obtained using the LocalTime interface of the 
ClockC component. This clock has 32.768 KHz frequency. Time stamping of 
individual messages can be performed using the TimeStamping interface provided 
by the TimeStampingC component. Please read the documentation in this interface 
file.

TIMESYNC:

The TimeSyncC component (in the vu/lib directory) is compatible with this module 
as it only relies on the TimeStamping interface. If combined with this time 
stamping package, it yields 1 microsecond / hop accuracy in a connected multi- 
hop network.
