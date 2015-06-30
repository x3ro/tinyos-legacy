includes VitalStats;

/**
 *  This interfaces allows many components to
 *  handle the arrival of periodic heartbeat
 *  packets, whatever they may be.  Provisions
 *  are also made for snooping non-heartbeat packets.
 *
 * @author Stan Rost
 **/
interface HeartBeatHandler {

  /**
   * Provides the average period of this heartbeat 
   *
   **/
  command uint32_t getPeriod();

  /**
   * Receive a heartbeat
   *
   * @param srcAddr Source of the heartbeat
   * @param vStats A VitalStats data structure
   *
   **/
  event void receiveHeartBeat(uint16_t srcAddr,
			      VitalStats *vStats);

  /**
   * Receive a non-heartbeat packet,
   * with no guarantees as to periodicity
   *
   * @param srcAddr Source of the packet 
   *
   **/
  //  event void receivePacket(uint16_t srcAddr);

}
