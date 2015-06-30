includes NeighborList;

module DSDV_SoI_MetricM
{
   provides {
      interface StdControl;
      interface RouteUpdate;
      interface RouteLookup;
      interface Router;
   }
   uses {
      interface StdControl as QualityControl;
      interface NeighborQuality;
      interface Neighbors;
      interface Piggyback;
      interface SoI_Msg;
      interface SphereControl;
      interface AdjuvantSettings;
      interface Leds;
      interface Intercept as SoIPlugin;  // append a list of adjuvant nodes
      event void triggerRouteAdvertisement();
   }
}

implementation {
   enum {
      MAX_COST=65535L,
      NO_SPHERE = INVALID_NODE_ID,
      ROUTE_TABLE_LEN = 10
   };

   typedef struct {
      uint16_t fixed;
      uint16_t variable;
   } __attribute__ ((packed)) Cost;

   typedef struct {
      wsnAddr sphereID;
      Cost cost;
   } __attribute__ ((packed)) SphereMetric;

   typedef struct {
      SphereMetric primary;
      SphereMetric secondary;
      uint8_t piggyback[1];
   } __attribute__ ((packed)) SoI_Metric_Payload;

   enum {
      SOI_METRIC_PAYLOAD_LEN = offsetof(SoI_Metric_Payload, piggyback)
   };

   SphereMetric primary;
   wsnAddr primaryNextHop;

   SphereMetric secondary;
   wsnAddr secondaryNextHop;

   wsnAddr dest;

   bool amAdjuvantNode;
   bool isSoIEnabled;
   wsnAddr sphereID;

   typedef struct {
      wsnAddr sphereID;
      wsnAddr nextHop;
   } routeTableEntry_t;

   routeTableEntry_t secondaryRouteTable[ROUTE_TABLE_LEN];

   inline void invalidateSphereMetric(SphereMetric * metric) {
      metric->sphereID = NO_SPHERE;
      metric->cost.fixed = MAX_COST;
      metric->cost.variable = 0;
   }

   inline void copySphereMetric(SphereMetric * to, SphereMetric * from) {
      to->sphereID = from->sphereID;
      to->cost.fixed = from->cost.fixed;
      to->cost.variable = from->cost.variable;
   }

   inline void enableSoI() {
      if (isSoIEnabled) {
         return;
      }

      isSoIEnabled = TRUE;
      amAdjuvantNode = FALSE;
      invalidateSphereMetric(&secondary);
      secondaryNextHop = INVALID_NODE_ID;
   }

   inline void disableSoI() {
      isSoIEnabled = FALSE;
   }

   inline void makeAdjuvantNode() {
      if (amAdjuvantNode) {
         return;
      }

      amAdjuvantNode = TRUE;

      invalidateSphereMetric(&secondary);
      secondaryNextHop = INVALID_NODE_ID;

      call SphereControl.setAmAdjuvantNode(TRUE);
   }

   inline void makeNonAdjuvantNode() {
      if (amAdjuvantNode == FALSE) {
         return;
      }

      amAdjuvantNode = FALSE;

      invalidateSphereMetric(&secondary);
      secondaryNextHop = INVALID_NODE_ID;

      call SphereControl.setAmAdjuvantNode(FALSE);
   }

#define DEBUG
#ifdef DEBUG
   void fail() {
      uint16_t i;

      while (1) {
         call Leds.redOn();
         call Leds.yellowOn();
         call Leds.greenOn();

#ifndef PLATFORM_PC
         for (i=0; i<20000; i++) {
            asm volatile ("sleep" ::);
         }
#endif

         call Leds.redOff();
         call Leds.yellowOff();
         call Leds.greenOff();

#ifndef PLATFORM_PC
         for (i=0; i<20000; i++) {
            asm volatile ("sleep" ::);
         }
#endif
      }
   }
   void fail1() {
      uint16_t i;
      while(1)
      {
          call Leds.redToggle();
#ifndef PLATFORM_PC
         for (i=0; i<20000; i++) {
            asm volatile ("sleep" ::);
         }
#endif
      }
   }

#endif

   void invalidateSecondaryRouteCache() {
      uint8_t i;
      for (i=0; i<ROUTE_TABLE_LEN; i++) {
         secondaryRouteTable[i].nextHop = INVALID_NODE_ID;
      }

   }

   void addSecondaryRoute(wsnAddr id, wsnAddr nextHop) {
      uint8_t i;
      uint8_t removeEntry = 0xFF;

      if (nextHop == INVALID_NODE_ID) {
         return;
      }

      // look for an existing entry for this sphere id
      for (i=0; i<ROUTE_TABLE_LEN; i++) {
         if ((secondaryRouteTable[i].sphereID == id) &&
             (secondaryRouteTable[i].nextHop != INVALID_NODE_ID)) {
            // found the item
            removeEntry = i;
            break;
         }
      }

      if (removeEntry == 0xFF) {
         // look for an empty slot
         for (i=0; i<ROUTE_TABLE_LEN; i++) {
            if (secondaryRouteTable[i].nextHop == INVALID_NODE_ID) {
               // found an empty slot
               removeEntry = i;
               break;
            }
         }
      }

      if (removeEntry == 0xFF) {
         // default is to remove last entry
         removeEntry = ROUTE_TABLE_LEN-1;
      }

      // move the table down to fill in entry at removeEntry
      for (i=0; i<removeEntry; i++) {
         secondaryRouteTable[i+1].sphereID = secondaryRouteTable[i].sphereID;
         secondaryRouteTable[i+1].nextHop = secondaryRouteTable[i].nextHop;
      }

      // insert new entry at the top
      secondaryRouteTable[0].sphereID = id;
      secondaryRouteTable[0].nextHop = nextHop;
   }

   wsnAddr lookupSecondaryRoute(wsnAddr id){
      uint8_t i;

      for (i=0; i<ROUTE_TABLE_LEN; i++) {
         if ((secondaryRouteTable[i].nextHop != INVALID_NODE_ID) &&
             (secondaryRouteTable[i].sphereID == id)) {
            return secondaryRouteTable[i].nextHop;
         }
      }
      // not found
      return INVALID_NODE_ID;
   }

   command result_t StdControl.init() {
      primaryNextHop = INVALID_NODE_ID;
      invalidateSphereMetric(&primary);

      secondaryNextHop = INVALID_NODE_ID;
      invalidateSphereMetric(&secondary);

      dest = INVALID_NODE_ID;

      call AdjuvantSettings.init();
      isSoIEnabled = call AdjuvantSettings.isServiceEnabled();
      sphereID = TOS_LOCAL_ADDRESS; // only valid when amAdjuvantNode is TRUE
      amAdjuvantNode = call AdjuvantSettings.amAdjuvantNode();
      call SphereControl.setAmAdjuvantNode(amAdjuvantNode);

      call SphereControl.setSphereMembership(primary.sphereID);

      invalidateSecondaryRouteCache();

      return call QualityControl.init();
   }

   command result_t StdControl.start() {
      return call QualityControl.start();
   }

   command result_t StdControl.stop() {
      return call QualityControl.stop();
   }

   inline uint16_t hopCost(wsnAddr node) {
      return call NeighborQuality.getNeighborQuality(node);
   }

   void newRound() {
      dbg(DBG_ROUTE, "New round\n");

      if (isSoIEnabled) {
         secondary.cost.fixed = MAX_COST;
         secondary.cost.variable = 0;
      }
      primary.cost.fixed = MAX_COST;
      primary.cost.variable = 0;

      invalidateSecondaryRouteCache();
   }

   command void RouteUpdate.newDest(wsnAddr newDest) {
      if (newDest != dest) {
         newRound();

         primaryNextHop = INVALID_NODE_ID;
         secondaryNextHop = INVALID_NODE_ID;
         invalidateSphereMetric(&primary);
         invalidateSphereMetric(&secondary);
         dest = newDest;
      }
   }

   command void RouteUpdate.receivedMetric(wsnAddr src,
                                           uint8_t *metricPayload,
                                           uint8_t len) {
      call Piggyback.receivePiggyback(src, (metricPayload +
                                                SOI_METRIC_PAYLOAD_LEN),
                                                len - SOI_METRIC_PAYLOAD_LEN);
   }

   // sum up cost elements and prevent overflow
   inline uint16_t sumCost(uint16_t a, uint16_t b) {
      uint16_t sum = a;

      sum+=b;
      if((sum >= a) && (sum >= b))
         return sum;
      else //overflow occured
         return MAX_COST;
   }

   inline uint16_t adjuvantValue(uint16_t cost) {
      uint16_t adjValue = call AdjuvantSettings.getAdjuvantValue();

      if (adjValue != 0)
         cost /= call AdjuvantSettings.getAdjuvantValue();

      if (cost == 0) {
         return 1;
      } else {
         return cost;
      }
   }

   command bool RouteUpdate.evaluateMetric(wsnAddr src,
                                         uint8_t * rawMetricPayload, bool isNewRound, bool forceNewRound) {
      bool ret = FALSE;
      SoI_Metric_Payload *metricPayload =
                                 (SoI_Metric_Payload *) rawMetricPayload;
      uint16_t primaryCost;
      uint16_t secondaryCost;
      uint16_t newPrimaryCost;
      uint16_t newSecondaryCost;

      if (isNewRound) {
         newRound();
      }

      metricPayload->primary.cost.variable =
                 sumCost(metricPayload->primary.cost.variable, hopCost(src));
      metricPayload->secondary.cost.variable =
                 sumCost(metricPayload->secondary.cost.variable, hopCost(src));

      primaryCost = sumCost(primary.cost.fixed, primary.cost.variable);
      secondaryCost = sumCost(secondary.cost.fixed, secondary.cost.variable);
      newPrimaryCost = sumCost(metricPayload->primary.cost.fixed,
                                       metricPayload->primary.cost.variable);
      newSecondaryCost = sumCost(metricPayload->secondary.cost.fixed,
                                         metricPayload->secondary.cost.variable);

      if (amAdjuvantNode) {
         // The above cost computation is wrong for an adjuvant node; redo!
         // Need to compare the costs that will be advertised!
         primaryCost = sumCost(primary.cost.fixed,
                               adjuvantValue(primary.cost.variable));
         secondaryCost = sumCost(secondary.cost.fixed,
                                 adjuvantValue(secondary.cost.variable));
         newPrimaryCost = sumCost(metricPayload->primary.cost.fixed,
                    adjuvantValue(metricPayload->primary.cost.variable));
         newSecondaryCost = sumCost(metricPayload->secondary.cost.fixed,
                  adjuvantValue(metricPayload->secondary.cost.variable));

         if (sphereID != metricPayload->primary.sphereID) {
            if (newPrimaryCost < primaryCost) {
               copySphereMetric(&primary, &(metricPayload->primary));
               primaryNextHop = src;
               ret = TRUE;
            }
                // v-- is secondary info valid?
         } else if (metricPayload->primary.sphereID != NO_SPHERE) {
            // It must be that metricPayload->secondary.sphereID is not the
            // local sphere, because the metricPayload->primary.sphereID was!
            if (newSecondaryCost < primaryCost) {
               copySphereMetric(&primary, &(metricPayload->secondary));
               primaryNextHop = src;
               ret = TRUE;
            }
         }

      } else if (isSoIEnabled) {  // non-adjuvant node

         // Determine our new primary sphere
         // call Leds.yellowToggle();
         if (newPrimaryCost < primaryCost) {  // the new primary is better!
            if (primary.sphereID != metricPayload->primary.sphereID) {
               // Rupdate wasn't sent from the same sphere.
               // Slide primary to secondary.
               copySphereMetric(&secondary, &primary);
               secondaryNextHop = primaryNextHop;
               // patch up secondary cost; it's used again later
               secondaryCost = primaryCost;
            }
            copySphereMetric(&primary, &(metricPayload->primary));
            primaryNextHop = src;

            ret = TRUE;
         }

         // Determine our new secondary sphere
         if (primary.sphereID == NO_SPHERE) { // I'm not in a sphere
            // I no longer need a secondary
            invalidateSphereMetric(&secondary);
            secondaryNextHop = INVALID_NODE_ID;
            // only return TRUE if the primary changed, so don't set ret here
         } else if ((primary.sphereID != metricPayload->primary.sphereID) &&
                    (newPrimaryCost < secondaryCost)) {
            // neighbor's primary is better than our secondary
            copySphereMetric(&secondary, &(metricPayload->primary));
            secondaryNextHop = src;
            ret = TRUE;
         } else if ((metricPayload->primary.sphereID != NO_SPHERE) &&
                    (newSecondaryCost < secondaryCost)) {
            // incoming secondary info is valid, and
            // neighbor's secondary is better than our secondary
            copySphereMetric(&secondary, &(metricPayload->secondary));
            secondaryNextHop = src;
            ret = TRUE;
         }

         if ((ret == TRUE) && (primary.sphereID != NO_SPHERE)) {
            addSecondaryRoute(secondary.sphereID, secondaryNextHop);
         }

      } else {   // isSoIEnabled == FLASE
         if (newPrimaryCost < primaryCost) {
            copySphereMetric(&primary, &(metricPayload->primary));
            primaryNextHop = src;
            ret = TRUE;
         }
      }

#if SHOW_SPHERE
      if (primary.sphereID != NO_SPHERE) {
         call Leds.yellowOn();
      } else {
         call Leds.yellowOff();
      }
#endif

      if (ret == TRUE) {
         call SphereControl.setSphereMembership(primary.sphereID);
      }
      dbg(DBG_USR2,"pri fixed %x pri var %x sec fixed %x sec var %x \n",metricPayload->primary.cost.fixed,
                        metricPayload->primary.cost.variable,
                        metricPayload->secondary.cost.fixed,
                        metricPayload->secondary.cost.variable);
      return ret;
   }

   command uint8_t RouteUpdate.encodeMetric(uint8_t * rawMetricPayload,
                                            uint8_t len) {
      SoI_Metric_Payload *metricPayload =
                                 (SoI_Metric_Payload *) rawMetricPayload;

#ifndef PLATFORM_EMSTAR /* need to fix if want to run emstar as sink! */
#if SINK_NODE || PLATFORM_PC
      if (TOS_LOCAL_ADDRESS == 0) {
         metricPayload->primary.sphereID = NO_SPHERE;
         metricPayload->primary.cost.fixed = 0;
         metricPayload->primary.cost.variable = 0;
         metricPayload->secondary.sphereID = NO_SPHERE;
      } else
#endif
#endif
      if (amAdjuvantNode) {
         metricPayload->primary.sphereID = sphereID;
         metricPayload->primary.cost.variable = 0;
         metricPayload->primary.cost.fixed =
                   sumCost(primary.cost.fixed,
                           adjuvantValue(primary.cost.variable));

// Should an adjuvant node xmit secondary info?
         invalidateSphereMetric(&(metricPayload->secondary));
//         copySphereMetric(&(metricPayload->secondary), &primary);
      } else {
         copySphereMetric(&(metricPayload->primary), &primary);
         if (metricPayload->primary.sphereID != NO_SPHERE) {
            copySphereMetric(&(metricPayload->secondary), &secondary);
         } else {
            invalidateSphereMetric(&(metricPayload->secondary));
         }
      }

      return SOI_METRIC_PAYLOAD_LEN +
             call Piggyback.fillPiggyback((wsnAddr) TOS_BCAST_ADDR,
                                          metricPayload->piggyback,
                                          len-SOI_METRIC_PAYLOAD_LEN);
   }

   command wsnAddr RouteLookup.getNextHop(TOS_MsgPtr m, wsnAddr target) {
      wsnAddr packetSphereID = call SoI_Msg.getSphereID(m);

      if (target != dest) {
         return INVALID_NODE_ID;
      }

      if ((isSoIEnabled == TRUE) &&               // soi is on
          (amAdjuvantNode == FALSE) &&            // not an adjuvant node
          (packetSphereID != primary.sphereID)) { // not to my adjuvant node
         // the packet is not going to my adjuvant node, forward out of sphere
         return lookupSecondaryRoute(packetSphereID);
      } else {
         return primaryNextHop;
      }
   }

   command wsnAddr RouteLookup.getRoot() {
      return dest;
   }

   command result_t RouteUpdate.setUpdateInterval(uint8_t interval) {
      call Neighbors.setUpdateInterval(interval);
      return SUCCESS;
   }

   /* AdjuvantSettings */
   event void AdjuvantSettings.enableSoI(bool YoN) {
      if (YoN)
         enableSoI();
      else
         disableSoI();
   }

   event void AdjuvantSettings.enableAdjuvantNode(bool YoN) {
      if (YoN)
         makeAdjuvantNode();
      else
         makeNonAdjuvantNode();
   }

   /* SoIPlugin */

   event PacketResult_t SoIPlugin.intercept(TOS_MsgPtr m, void *data, uint16_t len) {

      /* In normal case TR_PLUGIN_LEN = 2, stores the Adj. node bits
         Sometimes you can make TR_PLUGIN_LEN = 3 to put one HSNValue before
         Adj. bits. Payload |TR|HSNValue(1)|Adj.Bits(2)|SettingsFB(1)| */

      uint16_t *bits;
#ifdef TR_PLUGIN_LEN
      uint8_t *adjValue;
      if (TR_PLUGIN_LEN >= 3) {
         bits = data + 1;
         adjValue = data;
      } else
#endif
         bits = data;
      if (len >= 2) {
         *bits <<= 1;
         if (amAdjuvantNode) {
            *bits |= 1;
#ifdef TR_PLUGIN_LEN
            if (TR_PLUGIN_LEN >= 3)
               *adjValue = call AdjuvantSettings.getAdjuvantValue();
#endif
         }
      }
      return SUCCESS;
   }

   command uint16_t Router.getSendMetric(wsnAddr target) {
      if (dest == target) {
         if (amAdjuvantNode) {
            return sumCost(primary.cost.fixed,
                           adjuvantValue(primary.cost.variable));
         } else {
            return sumCost(primary.cost.fixed, primary.cost.variable);
         }
      } else {
         return MAX_COST;
      }
   }

   command wsnAddr Router.getNextHop(wsnAddr target) {
      // TODO: This needs to be FIX!!!!!!! DUMMY FUNCTION NOW!!!
      return primaryNextHop; // secondaryNextHop;
   }

   command wsnAddr Router.getRoot() {
      return dest;
   }

   command void Router.triggerRouteAdvertisement() {
      signal triggerRouteAdvertisement();
   }

   command void Router.triggerRouteForward(bool forward) {
     // dummy... since interface requires it.
     // no one seems to use it yet
   }

}
