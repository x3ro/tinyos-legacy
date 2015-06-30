-------------------------------------------------------------------------------
06/09/2003, Modified by Cory Sharp
-------------------------------------------------------------------------------
For this copy in minitasks/03/uva/EnviroTrack/, I've deleted and modified files
so that it compiles only when the EnviroTrack is in minitasks/03/ucb/.  You can
accomplish this by originally checking it out in the uva/ directory then just
moving EnviroTrack to the ucb/ directory.  Don't worry, CVS will do the right
thing for commits.


-------------------------------------------------------------------------------
06/05/2003, Modified by Liqian Luo to integrate mobile routing into EnviroTrack
-------------------------------------------------------------------------------
All changed codes is wrapped by "0506B" and "0506E"

<changed EnviroTrack files>
ECMM.nc

-------------------------------------------------------------------------------
06/04/2003, Modified by Liqian Luo to integrate mobile routing into EnviroTrack
-------------------------------------------------------------------------------
All changed codes is wrapped by "0406B" and "0406E"

<changed EnviroTrack files>
ECMM.nc
Enviro.nc
Tracking.h
TrackingM.nc
SysSync.h

<changed DD files>
DirectedDiffusion.h
DirectedDiffusionM.nc (I also comment all leds calls)

-------------------
EnviroTrack Files
-------------------
ECM.h
ECM.nc
ECMM.nc
EMM.h
EMM.nc
EMMM.nc
Enviro.h
Enviro.nc
GetLeader.nc
Local.nc
LocalM.nc
MagAutoBiasM.nc
MagAxesSpecific.nc
MagBiasActuator.nc
MagC.nc
MagFuseBiasM.nc
MagHood.h
MagMovingAvgM.nc
MagSensor.h
MagSensor.nc
MagSensorM.nc
MagSumXYM.nc
MagU16C.nc
moving_average.h
SysSync.h
SysSync.nc
SysSyncC.nc
SysSyncM.nc
SystemParameters.h
TimedLeds.nc
TimedLedsC.nc
TimedLedsM.nc
Tracking.h
Tracking.nc
TrackingM.nc
Triang.h
Triang.nc
TriangM.nc
U16Sensor.nc

-------------------
GF Routing Files
-------------------
BC.nc
BCM.nc
Beacon.nc
GF.h
GF.nc
GFM.nc
UVARouting.h
NestArch.h
Packets.h
RoutingC.nc
RoutingM.nc
RoutingReceive.nc
RoutingSendByAddress.nc
RoutingSendByBroadcast.nc
RoutingSendByLocation.nc
common_structs.h

-------------------
Directed Diffusion Files
-------------------
Interest.nc
DirectedDiffusion.h
DirectedDiffusion.nc
DirectedDiffusionM.nc
RoutingDD.nc
RoutingDDReceiveDataMsg.nc
RoutingSendByEventSig.nc
RoutingSendByMobileID.nc

------------------------------------------------------------------------------
Work Flow
------------------------------------------------------------------------------

--------
Phase 1
--------
synchronize clock and set parameters.

By adding this phase, we can tune parameters by reprogramming only the
base station instead of all motes.

Tunable Parameters include:
        DEFAULT_GridX = 10,
        DEFAULT_GridY = 8,
        DEFAULT_SENSE_CNT_THRESHOLD  = 3,
///ENVIRO_WORKING_CLOCK_RATE/(DEFAULT_SENSE_CNT_THRESHOLD+1)=32/(3+1)=8
sampling per second
        DEFAULT_SEND_CNT_THRESHOLD = 15,
//ENVIRO_WORKING_CLOCK_RATE/(DEFAULT_SENSE_CNT_THRESHOLD+1) report to base
per second
        DEFAULT_MagThreshold = 8,
        DEFAULT_RECRUIT_THRESHOLD = 8, //EMM_WORKING_CLOCK_RATE/50 reduce it
can make group managment faster
        DEFAULT_EVENTS_BEFORE_SENDING = 4, // 2 report per second to the
leader
        //for GF
        DEFAULT_BEACON_INCLUDED = 0,//if it is 1, beacon function is used.
If it is 0, beacon is closed.

---------
Phase 2
---------
1. establish GF routing through beaconing. However, it seems if we open the
beacon of GF, EnviroTrack can not work, so currently we close the GF beacon.

2. start Directed Diffusion

--------
Phase 3
--------
Tracking.

A sample estimation report received by base station is as follows:

<header>
7e 00 03 7d 1c 02 00 ff ff 00 00 00 00 25 02

<payload>
00 00 | 01 00 | 13 00 | 00 01 | 00 00 | 63 00 | 02 00 | 1c 00 | 01
group | port  | lGrp  | x     | y     | event | leader| seqNo | conlevel

payload format:
  uint16_t group;       //BASE_GROUP=0:SystemParameters.h
  uint16_t port;        //TRACKING_INFO_MSG=1:Tracking.h
  uint16_t lGroup;      //local group id:produced in EMMM.nc
  uint16_t x;           //Estimated target position.x*256
  uint16_t y;           //Estimated target position.y*256
  uint16_t eventRec;    //PHOTO_EVENT=99:SystemParameters.h
  uint16_t leaderID;    //leader ID
  uint16_t currentDataSeqNo;    //sequence number
  uint8_t confidenceLevel;      //confidence level

Sample reports(only payload included):
00 00 01 00 1c 00 00 03 00 00 63 00 03 00 01 00 01 01
00 00 01 00 1c 00 00 03 00 00 63 00 03 00 02 00 01 01
00 00 01 00 1c 00 80 02 00 00 63 00 03 00 03 00 02 01
00 00 01 00 1c 00 80 02 00 00 63 00 03 00 04 00 02 01
00 00 01 00 1c 00 80 02 00 00 63 00 03 00 05 00 02 01
00 00 01 00 1c 00 00 02 00 00 63 00 03 00 06 00 03 01
00 00 01 00 1c 00 00 02 00 00 63 00 03 00 07 00 03 01
00 00 01 00 1c 00 00 02 00 00 63 00 03 00 08 00 02 01
00 00 01 00 1c 00 00 01 00 00 63 00 01 00 09 00 01 01
00 00 01 00 1c 00 00 01 00 00 63 00 01 00 0a 00 01 01
00 00 01 00 1c 00 00 01 00 00 63 00 01 00 0b 00 01 01
00 00 01 00 1c 00 00 01 00 00 63 00 01 00 0c 00 01 01
00 00 01 00 1c 00 00 01 00 00 63 00 01 00 0d 00 01 01
00 00 01 00 1c 00 00 01 00 00 63 00 01 00 0e 00 01 01

