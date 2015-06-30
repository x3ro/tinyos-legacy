// assume 10 sec epoch
#define EPOCH_LENGTH 5

// this is arbitrary
#define STARTING_ENERGY 65000L

// Sync listen cost 
#define PER_EPOCH_SYNC_RTS_CTS_LISTEN_COST 14

// cost to send each packet
#define PACKET_SEND_COST 17

// cost to receive each packet
#define PACKET_RECEIVE_COST 11

// cost to send broadcast packet
#define PACKET_BROADCAST_SEND_COST 8

module SMACEnergyModelM
{
   provides {
      interface StdControl as Control;
      interface Settings; 
      command uint16_t EnergyConsumed();  /* energy consumed since last epoch */
   }
   uses {
      interface Timer;
      interface Neighbors;
      interface NetStat;
      interface Intercept;
      interface MultiHopMsg;
   }
}

implementation {
   uint16_t remainingEnergy;
   uint16_t previousEnergy;
   uint16_t previousUnicastSent;     // # of packets sent, last time we checked
   uint16_t previousUnicastReceived; // # of packets received, last time we checked
   uint16_t timeSinceLastUpdate;
   uint16_t previousReport;
   uint16_t previousBroadcastSent;     // # of packets sent, last time we checked

   bool     measureEnergy;
   uint16_t periodEnergy;     // energy since last START time

   enum {
      ENERGY_MEASURE_STOP = 0x00,
      ENERGY_MEASURE_START = 0x01
   };

   command result_t Control.init() {
      remainingEnergy = STARTING_ENERGY;
      previousEnergy = remainingEnergy;
      measureEnergy = FALSE;
      periodEnergy = 0;
      previousUnicastSent = 0;
      previousUnicastReceived = 0;
      previousBroadcastSent = 0;
      previousReport = 0;
      return SUCCESS;
   }

   command result_t Control.start() {
      call Timer.start(TIMER_REPEAT, CLOCK_SCALE);
      return SUCCESS;
   }

   command result_t Control.stop() {
      call Timer.stop();
      return SUCCESS;
   }

// TODO: make sure NEIGHBOR_AGE_CACHE_TIMEOUT is turned on
   event result_t Timer.fired() {
      timeSinceLastUpdate++;
      return SUCCESS;
   }

   void accountForPerEpochCost() {
      uint16_t energy = PER_EPOCH_SYNC_RTS_CTS_LISTEN_COST;

      // ammortize according to time since last updated
      energy = (energy * timeSinceLastUpdate / EPOCH_LENGTH);

      remainingEnergy -= energy;

      return;
   }

   void accountForSentMessages() {
      uint16_t tmp;
      uint16_t recentlyUnicastSent;
      uint16_t recentlyUnicastReceived;
      uint16_t recentlyBroadcastSent;

      tmp = call NetStat.sentUnicastMessages();
      recentlyUnicastSent = tmp - previousUnicastSent;
      previousUnicastSent = tmp;

      tmp = call NetStat.receivedUnicastMessages();
      recentlyUnicastReceived = tmp - previousUnicastReceived;
      previousUnicastReceived = tmp;

      tmp = call NetStat.sentBroadcastMessages();
      recentlyBroadcastSent = tmp - previousBroadcastSent;
      previousBroadcastSent = tmp;

      remainingEnergy -= (recentlyUnicastSent * PACKET_SEND_COST) +
                         (recentlyUnicastReceived * PACKET_RECEIVE_COST) +
                         (recentlyBroadcastSent * PACKET_BROADCAST_SEND_COST);
   }

   command uint16_t EnergyConsumed() {

      uint16_t report;
      accountForSentMessages();
      accountForPerEpochCost();
      timeSinceLastUpdate=0;

      report = previousEnergy - remainingEnergy;
      previousEnergy = remainingEnergy;

      // smooth out the results
#if SMOOTH_ENERGY
      report = (report/2) + (previousReport/2);
      previousReport = report;
#endif

#if TINYDBSHIM_ENERGY_MEASURE
      if (measureEnergy) {
         report = periodEnergy - remainingEnergy;
      }
#endif

      return report;
   }

   /* originating node sends back the report within TraceRoute plugin */
   event result_t Intercept.intercept(TOS_MsgPtr msg, void* payload, uint16_t payloadLen) {
#ifndef PLATFORM_PC
      // only fill in on originating node
      if (call MultiHopMsg.getSource(msg) == (wsnAddr) TOS_LOCAL_ADDRESS) {
         uint16_t report;
         char * buf = payload;

         report = call EnergyConsumed();

         buf[1]=(report & 0xFF);
         buf[0]=((report >> 8) & 0xFF);
      }
#endif
      return SUCCESS;
   }

   /* 1 byte, 1 is start, 0 is stop */
   command result_t Settings.updateSetting(uint8_t *buf, uint8_t *len) {
      /* the remaining buf should be longer than need */
      if (*len < 1) {
         return FAIL;
      }
      call EnergyConsumed();
      switch (*buf) {
      case ENERGY_MEASURE_START:
         measureEnergy = TRUE;
         periodEnergy = remainingEnergy;
         break;
      case ENERGY_MEASURE_STOP:
         measureEnergy = FALSE;
         periodEnergy = periodEnergy - remainingEnergy;
         break;
      default:
      }

      *len = 1;   // used 1 bytes on this settings
      return SUCCESS;
   }

   /* send info back using piggyback, 2 bytes */
   command result_t Settings.fillSetting(uint8_t *buf, uint8_t *len) {
      uint16_t tmp; 
      if (*len < 2) {
         return FAIL;
      }
      if (measureEnergy) {
         call EnergyConsumed();
         tmp = periodEnergy - remainingEnergy;
         buf[1] = (tmp & 0xFF);
         buf[0] = ((tmp >> 8) & 0xFF);
      } else
         buf[0] = buf[1] = 0;
      *len = 2;
      return SUCCESS;
   }

}
