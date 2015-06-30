// assume 10 sec epoch
#define EPOCH_LENGTH 10

// this is arbitrary
#define STARTING_ENERGY 65000L

// cost to receive an intent from each neighbor during an epoch
#define PER_NEIGHBOR_PER_EPOCH_RESYNC_COST 2

// cost to send one intent during an epoch
#define PER_EPOCH_FIXED_RESYNC_COST 3

// cost to send each packet
#define PACKET_SEND_COST 19

// cost to receive each packet
#define PACKET_RECEIVE_COST 11

module EnergyModelM
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
   uint16_t previousSent;     // # of packets sent, last time we checked
   uint16_t previousReceived; // # of packets received, last time we checked
   uint16_t timeSinceLastUpdate;
   uint16_t previousReport;

   bool     measureEnergy;
   uint16_t startEnergy;     // energy at last START time
   uint16_t stopEnergy;      // energy at last STOP time

   enum {
      ENERGY_MEASURE_STOP = 0x00,
      ENERGY_MEASURE_START = 0x01
   };

   command result_t Control.init() {
      remainingEnergy = STARTING_ENERGY;
      previousEnergy = remainingEnergy;
      measureEnergy = FALSE;
      startEnergy = 0;
      stopEnergy = 0;
      previousSent = 0;
      previousReceived = 0;
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

   void accountForReSyncOverhead() {
      uint16_t energy = 0;

      energy += PER_EPOCH_FIXED_RESYNC_COST;
      energy += PER_NEIGHBOR_PER_EPOCH_RESYNC_COST *
                                    call Neighbors.numNeighbors();

      // ammortize according to time since last updated
      energy = (energy * timeSinceLastUpdate / EPOCH_LENGTH);

      remainingEnergy -= energy;

      return;
   }

   void accountForSentMessages() {
      uint16_t tmp;
      uint16_t recentlySent;
      uint16_t recentlyReceived;

      tmp = call NetStat.sentMessages();
      recentlySent = tmp - previousSent;
      previousSent = tmp;

      tmp = call NetStat.receivedMessages();
      recentlyReceived = tmp - previousReceived;
      previousReceived = tmp;

      remainingEnergy -= (recentlySent * PACKET_SEND_COST) +
                         (recentlyReceived * PACKET_RECEIVE_COST);
   }

   command uint16_t EnergyConsumed() {

      uint16_t report;
      accountForSentMessages();
      accountForReSyncOverhead();
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
         report = startEnergy - remainingEnergy;
      } else
         report = startEnergy - stopEnergy;
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
         startEnergy = remainingEnergy;
         break;
      case ENERGY_MEASURE_STOP:
         if (measureEnergy) {   // don't multiple stop
            measureEnergy = FALSE;
            stopEnergy = remainingEnergy;
         }
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
         tmp = startEnergy - remainingEnergy;
      } else {
         tmp = startEnergy - stopEnergy;
      }
      buf[1] = (tmp & 0xFF);
      buf[0] = ((tmp >> 8) & 0xFF);
      *len = 2;
      return SUCCESS;
   }

}
