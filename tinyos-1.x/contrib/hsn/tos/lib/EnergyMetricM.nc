// cost to send each packet
#define PACKET_SEND_COST 19

// cost to receive each packet
#define PACKET_RECEIVE_COST 11

// this is arbitrary
#define STARTING_ENERGY 65000L

module EnergyMetricM
{
   provides {
      interface StdControl;
      interface NeighborQuality;
      interface Piggyback;
      interface Settings as MetricSettings;
   }
   uses {
      interface StdControl as QualityControl;
      interface NeighborQuality as ActualNeighborQuality;
      interface Piggyback as NeighborQualPiggyback;
      interface NeighborAttr;
      interface AdjuvantSettings;
   }
}

implementation {

   uint8_t expNoRetransmission[NUM_QUALITY_LEVELS];
   bool amAdjuvantNode;

   command result_t StdControl.init() {
      /* Based on 3 maximum retransmissions. */
      //Normalized by a factor of 10
      expNoRetransmission[0] = 24;
      expNoRetransmission[1] = 14;
      expNoRetransmission[2] = 12;
      expNoRetransmission[3] = 11;

      /* Based on 2 maximum retransmissions */
      /*
      expNoRetransmission[0] = 18;
      expNoRetransmission[1] = 14;
      expNoRetransmission[2] = 11;
      expNoRetransmission[3] = 10;
      */

      call AdjuvantSettings.init();
      amAdjuvantNode = call AdjuvantSettings.amAdjuvantNode();

      return call QualityControl.init();
   }
   command result_t StdControl.start() {
      return call QualityControl.start();
   }

   command result_t StdControl.stop() {
      return call QualityControl.stop();
   }

   command uint16_t NeighborQuality.getNeighborQuality(wsnAddr addr) {
      uint8_t wallPower = 0;
      result_t ret;

      ret = call NeighborAttr.getAttr(addr, &wallPower);
      if(ret == FAIL) { //should never happen.
         wallPower = 0; //Assume it is not wall powered.
      }

      //If neighbor is wallpowered, the receive cost is zero.
      if(amAdjuvantNode && wallPower)//small number
         return 1;
      else if(amAdjuvantNode) // send cost is zero
         return (expNoRetransmission[call ActualNeighborQuality.getNeighborQuality(addr)]*PACKET_RECEIVE_COST);
      else if(wallPower) // receive cost is zero
         return (expNoRetransmission[call ActualNeighborQuality.getNeighborQuality(addr)]*PACKET_SEND_COST);
      else //both send and receive cost
      {
         dbg(DBG_USR2, "I am in right place \n");
         dbg(DBG_USR2, "Neighbor Attr is %d\n",call ActualNeighborQuality.getNeighborQuality(addr));
         return (expNoRetransmission[call ActualNeighborQuality.getNeighborQuality(addr)]*(PACKET_SEND_COST + PACKET_RECEIVE_COST));
      }
   }

   command uint8_t Piggyback.fillPiggyback(wsnAddr addr, uint8_t* energyStatus,
                                                                uint8_t len) {
     *(energyStatus + len-1) = (uint8_t)amAdjuvantNode; // Last byte of the piggyback
      call NeighborQualPiggyback.fillPiggyback(addr,
                                              energyStatus, len-1);
      return len;
   }

   // Get the energy status information from the neighbor.
   command result_t Piggyback.receivePiggyback(wsnAddr addr, uint8_t* buf,
                                               uint8_t len) {
      call NeighborAttr.setAttr(addr, buf[len-1]);
      return call NeighborQualPiggyback.receivePiggyback(addr, buf, len-1);
   }

   command result_t MetricSettings.updateSetting(uint8_t *buf, uint8_t *len) {
      uint8_t i;

      if (*len < NUM_QUALITY_LEVELS) {
         return FAIL;
      }

      for (i=0; i < NUM_QUALITY_LEVELS; i++) {
         expNoRetransmission[i] = buf[i];
      }

      *len = NUM_QUALITY_LEVELS;

      return SUCCESS;
   }

   command result_t MetricSettings.fillSetting(uint8_t *buf, uint8_t *len) {
      uint8_t i;

      if (*len < NUM_QUALITY_LEVELS) {
         return FAIL;
      }

      for (i=0; i < NUM_QUALITY_LEVELS; i++) {
         buf[i] = expNoRetransmission[i];
      }

      *len = NUM_QUALITY_LEVELS;

      return SUCCESS;
   }

   // SoI is always enabled since EnergyMetric is hooked up
   event void AdjuvantSettings.enableSoI(bool ToF) {
      return;
   }

   // make the node to be wall power
   event void AdjuvantSettings.enableAdjuvantNode(bool ToF)
   {
      if(ToF)
         amAdjuvantNode = TRUE;
      else
         amAdjuvantNode = FALSE;
   }
   
   // in case AdjuvantSettings is not wired with Adjuvant_Settings module
   // sometmies user is not interested to do so
   default command void AdjuvantSettings.init() {
      return;
   }

   default command bool AdjuvantSettings.amAdjuvantNode() {
      // default is NOT a wall power node
      return FALSE;
   }
}
