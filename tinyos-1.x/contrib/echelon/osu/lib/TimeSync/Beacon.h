enum { AM_BEACON=40, 
       AM_BEACON_PROBE=41,
       AM_PROBE_ACK=42
     };   // please change if needed

typedef struct beaconProbeMsg { 
  uint16_t count; 
  uint32_t RecClock;  // local clock at instant of receipt (just ClockL) 
  } beaconProbeMsg;
typedef beaconProbeMsg * beaconProbeMsgPtr;
typedef struct beaconProbeAck {
  uint16_t count;
  uint16_t sndId;    // id of sender
  timeSync_t Local;  // local clock for Ack (48 bit, H and L)
  timeSync_t Virtual; // virtual time for Ack (48 bit, H and L)
  } beaconProbeAck;
typedef beaconProbeAck * beaconProbeAckPtr; 

  /* In the initial Tsync implementation, one aspect of the
     following structures is not fully implemented:  
     mote id's are only one byte (but coerced to 2 bytes 
     for these structures).  */

// Structure of the Beacon Message
typedef struct beaconMsg 
{
  uint16_t sndId;     // Id of sender
  int16_t  prevDiff;  // difference of most recent received Beacon
  timeSync_t Local;   // local clock of sender (48 bit, H and L) 
  timeSync_t Virtual; // virtual time of sender (48 bit, H and L)
  uint32_t AdjClock;  // local clock at instant of sending (just ClockL) 
  uint32_t Dummy;  // Eventually remove this field (keep for Spy temporarily) 
} beaconMsg;	   // 24-byte payload

typedef beaconMsg * beaconMsgPtr;

