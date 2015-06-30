includes WSN;

#ifndef ADJUVANT_SERVICE_ENABLED_DEFAULT
#define ADJUVANT_SERVICE_ENABLED_DEFAULT TRUE
#endif

#ifndef ADJUVANT_STATUS_DEFAULT
#define ADJUVANT_STATUS_DEFAULT FALSE
#endif

#ifndef ADJUVANT_VALUE_DEFAULT
#define ADJUVANT_VALUE_DEFAULT 2
#endif

module Adjuvant_Settings {
   provides {
      interface Settings;   /* For GenericSetting */
      interface AdjuvantSettings;   /* For DSDV_SoI_Metric */
   }
   uses {
      /* Retrieve from external module if the magic number (255) is
         defined. We want to utilize the default event in case the
         external module is not hookup */
      event uint16_t getAdjuvantValue();
   }
}

implementation {

   /* Set by Metric module at the init, update by Setting at run time */
   bool     amAdjuvantNode;
   bool     isServiceEnabled;
   uint16_t valueFunc;

   enum {
      SETTING_FLAG_SOI_ENABLED      = 0x1,
      SETTING_FLAG_MAKE_ADJUVANT    = 0x2,
      SETTING_FLAG_MAKE_NONADJUVANT = 0x4
   };


   /* AdjuvantSettings */

   default event void AdjuvantSettings.enableSoI(bool ToF) {
      return;
   }

   default event void AdjuvantSettings.enableAdjuvantNode(bool ToF) {
      return;
   }

   command void AdjuvantSettings.init() {
      isServiceEnabled = ADJUVANT_SERVICE_ENABLED_DEFAULT;
      amAdjuvantNode = ADJUVANT_STATUS_DEFAULT;
      valueFunc = ADJUVANT_VALUE_DEFAULT;

#ifdef ADJUVANT_NODE_ID
      if (TOS_LOCAL_ADDRESS == ADJUVANT_NODE_ID) {
         // Debug under Simulator, I'm by default the adj. node
         amAdjuvantNode = TRUE;
         // ask the external module the adjuvant value
         // debug: valueFunc = 255;
         valueFunc = ADJUVANT_VALUE_DEFAULT;
      }
#endif
   }

   command uint16_t AdjuvantSettings.getAdjuvantValue() {
      return  (valueFunc == 255 ? signal getAdjuvantValue() : valueFunc);
   }

   command bool AdjuvantSettings.isServiceEnabled() {
      return isServiceEnabled;
   }

   command bool AdjuvantSettings.amAdjuvantNode() {
      return (isServiceEnabled && amAdjuvantNode);
   }

   /* HSNValue */

   default event uint16_t getAdjuvantValue() {
      /* Return default value func if the TinyDB is not connected */
      return valueFunc;
   }

   /* SoISetting */

   command result_t Settings.updateSetting(uint8_t *buf, uint8_t *len) {

      uint8_t i;

      if ((*len < 3) || (*len < buf[2] + 3)) {
         return FAIL;
      }

      if ((buf[0] & SETTING_FLAG_SOI_ENABLED) == 0) {
         isServiceEnabled = FALSE;
         signal AdjuvantSettings.enableSoI(FALSE);
      } else {
         if (! isServiceEnabled) {
            isServiceEnabled = TRUE;
            signal AdjuvantSettings.enableSoI(TRUE);
         }

         for (i=0; i< buf[2]; i++) {
            // WARNING: casting an address to a byte
            if (buf[i+3] == (uint8_t) TOS_LOCAL_ADDRESS) {
               if (buf[0] & SETTING_FLAG_MAKE_ADJUVANT) {
                  valueFunc = buf[1];  /* used if TinyDB is not wired */
                  amAdjuvantNode = TRUE;
                  signal AdjuvantSettings.enableAdjuvantNode(TRUE);
               }
               if (buf[0] & SETTING_FLAG_MAKE_NONADJUVANT) {
                  amAdjuvantNode = FALSE;
                  signal AdjuvantSettings.enableAdjuvantNode(FALSE);
               }
            }
         }
      }

      *len = buf[2] + 3;
      return SUCCESS;
   }

   command result_t Settings.fillSetting(uint8_t *buf, uint8_t *len) {
      if (*len < 2) {
         return FAIL;
      }

      buf[0] = 0;

      if (isServiceEnabled == TRUE) {
         buf[0] &= SETTING_FLAG_SOI_ENABLED;
      }

      if (amAdjuvantNode == TRUE) {
         buf[0] &= SETTING_FLAG_MAKE_ADJUVANT;
      }

      // No longer wire PrimarySphereID anymore
      //buf[1] = signal AdjuvantSettings.getPrimarySphereID();
      buf[1] = 0xFF;

      *len = 2;

      return SUCCESS;
   }

}

