/*                                                                      tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *
 */
/*                                                                      tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:     Mark Yarvis, York Liu, Nandu Kushalnagar
 *
 */

includes WSN;

module GenericSettingsHandlerM {
   provides {
      interface StdControl as Control;
      interface Settings as ProgramVersion;  // local settings
      interface Settings as SettingsVersion; // local settings
      interface Settings as PotSet;          // local settings
      interface Settings as BuildDate;       // local settings
      interface Settings as FeedbackList;    // local settings
      interface Settings as FeedbackID;      // local settings
      interface Settings as ResetMote;       // local settings
      interface Settings as FreqSet;  // local settings
      interface Piggyback;            // provide piggybacked settings feedback
   }
   uses {
      interface Intercept;            // handle settings messages
      interface MultiHopMsg;
      interface Settings[uint8_t id]; // interface to settings clients
#if PLATFORM_MICA2 || PLATFORM_MICA2DOT
      interface StdControl as RadioControl;
      interface CC1000Control;
#else
      interface Pot;
#endif
      interface StdControl as TransportControl;
      interface Leds;
      interface Reset;
   }
}

implementation {
   enum {
#ifdef CONST_GSET_MAX_FEEDBACK_VALUES
      GSET_MAX_FEEDBACK_VALUES = CONST_GSET_MAX_FEEDBACK_VALUES
#else
      GSET_MAX_FEEDBACK_VALUES = 20
#endif
   };

   uint8_t settingsVer;
   uint8_t progVer;
   uint8_t txRes;
   uint8_t radioFreq;
   uint8_t feedbackID;
   uint8_t feedbackLen;
   uint8_t feedbackProps[GSET_MAX_FEEDBACK_VALUES];

   command result_t Control.init() {
      settingsVer = 0;
      progVer = PROGVER;
      txRes = TXRES_VAL;

      feedbackID = 0;

      feedbackProps[0] = SETTING_ID_SETVER;
      feedbackProps[1] = SETTING_ID_POTSET;
      feedbackProps[2] = SETTING_ID_PROGVER;
      feedbackProps[3] = SETTING_ID_BUILD_DATE;
      feedbackLen = 4;

      return call TransportControl.init();
   }

   void setPower(int val) {
#if PLATFORM_MICA2 || PLATFORM_MICA2DOT
      call CC1000Control.SetRFPower(val);
#else
      call Pot.set(val);
#endif
   }

   command result_t Control.start() {
      setPower(txRes);
      return call TransportControl.start();
   }

   command result_t Control.stop() {
      return call TransportControl.stop();
   }

   command result_t PotSet.updateSetting(uint8_t *buf, uint8_t *len) {
      txRes = *buf;
      setPower(txRes);
      *len = 1; // let the caller know how much space this setting took
      return SUCCESS;
   }

   command result_t PotSet.fillSetting(uint8_t *buf, uint8_t *len) {
      *buf = txRes;
      *len = 1; // let the caller know how much space this setting took
      return SUCCESS;
   }

   command result_t FreqSet.updateSetting(uint8_t *buf, uint8_t *len) {
      radioFreq = *buf;
#if PLATFORM_MICA2 || PLATFORM_MICA2DOT
      call RadioControl.stop();
      call CC1000Control.TunePreset(radioFreq);
      call RadioControl.start();
#endif
      *len = 1; // let the caller know how much space this setting took
      return SUCCESS;
   }

   command result_t FreqSet.fillSetting(uint8_t *buf, uint8_t *len) {
      *buf = radioFreq;
      *len = 1; // let the caller know how much space this setting took
      return SUCCESS;
   }

   command result_t ProgramVersion.updateSetting(uint8_t *buf, uint8_t *len) {
      progVer = *buf;
      *len = 1; // let the caller know how much space this setting took
      return SUCCESS;
   }

   command result_t ProgramVersion.fillSetting(uint8_t *buf, uint8_t *len) {
      *buf = progVer;
      *len = 1; // let the caller know how much space this setting took
      return SUCCESS;
   }

   // normally the feedback ID is set when the feedback list is set, 
   // but this is ok too
   command result_t FeedbackID.updateSetting(uint8_t *buf, uint8_t *len) {
      feedbackID = *buf;
      *len = 1; // let the caller know how much space this setting took
      return SUCCESS;
   }

   command result_t FeedbackID.fillSetting(uint8_t *buf, uint8_t *len) {
      *buf = feedbackID;
      *len = 1; // let the caller know how much space this setting took
      return SUCCESS;
   }

   command result_t SettingsVersion.updateSetting(uint8_t *buf, uint8_t *len) {
      settingsVer = *buf;
      *len = 1; // let the caller know how much space this setting took
      return SUCCESS;
   }

   command result_t SettingsVersion.fillSetting(uint8_t *buf, uint8_t *len) {
      *buf = settingsVer;
      *len = 1; // let the caller know how much space this setting took
      return SUCCESS;
   }

   command result_t BuildDate.updateSetting(uint8_t *buf, uint8_t *len) {
      *len = 3;
      return SUCCESS;
   }

   command result_t BuildDate.fillSetting(uint8_t *buf, uint8_t *len) {
      if (*len < 3) {
         return FAIL;
      }

      *(buf++) = BUILD_MONTH;
      *(buf++) = BUILD_DAY;
      *(buf++) = BUILD_YEAR;
      *len = 3;

      return SUCCESS;
   }

   command result_t FeedbackList.updateSetting(uint8_t *buf, uint8_t *len) {
      uint8_t i;

      if (*len < 2) {
         return FAIL;
      }

      feedbackID = *(buf++);
      feedbackLen = *(buf++);

      if ((feedbackLen > GSET_MAX_FEEDBACK_VALUES) || 
          (*len < feedbackLen + 2)) {
         return FAIL;
      }

      for (i=0; i<feedbackLen; i++) {
         feedbackProps[i] = *(buf++);
      }

      // let the caller know how much space this setting took
      *len = feedbackLen + 2;

      return SUCCESS;
   }

   command result_t FeedbackList.fillSetting(uint8_t *buf, uint8_t *len) {
      uint8_t i;

      if (*len < feedbackLen+2) {
         return FAIL;
      }

      *(buf++) = feedbackID;
      *(buf++) = feedbackLen;

      for (i=0; i<feedbackLen; i++) {
         *(buf++) = feedbackProps[i];
      }

      // let the caller know how much space this setting took
      *len = feedbackLen + 2;

      return SUCCESS;
   }

   command result_t ResetMote.updateSetting(uint8_t *buf, uint8_t *len) {
      // This comes before Flood layer forward it ... this is bad, then
      // the mote doesn't have a chance to relay the settings before reset
      call Reset.reset();
      *len = 0; // let the caller know how much space this setting took
      return SUCCESS;
   }

   command result_t ResetMote.fillSetting(uint8_t *buf, uint8_t *len) {
      *len = 0; // let the caller know how much space this setting took
      return SUCCESS;
   }

   event result_t Intercept.intercept(TOS_MsgPtr m, void *payload, uint16_t msg_len) {
      uint8_t * buf = payload;
      uint8_t len = (uint8_t)msg_len;
      wsnAddr dest = call MultiHopMsg.getDest(m);

      dbg(DBG_USR3, ("GenericSettingsHandler Intercept.intercept\n"));

      if ((dest != (wsnAddr) TOS_LOCAL_ADDRESS) && 
          (dest != (wsnAddr) TOS_BCAST_ADDR)) {
         return SUCCESS;
      }

#if ! DISABLE_LEDS
      call Leds.yellowToggle();
      call Leds.yellowToggle();
      call Leds.yellowToggle();
#endif

      while (len > 0) {
         uint8_t id = *(buf++);
         uint8_t usedLen = (--len);

         if (call Settings.updateSetting[id](buf, &usedLen) == SUCCESS) {
            len -= usedLen;
            buf += usedLen;
         } else {
            len = 0;
         }
      }

      // forward settings messages
      return SUCCESS;
   }

   command result_t Piggyback.receivePiggyback(wsnAddr addr, uint8_t *buf,
                                                             uint8_t len) {
      // this isn't typically going to get called
      return SUCCESS;
   }

   default command result_t Settings.fillSetting[uint8_t id](uint8_t * buf, 
                                                              uint8_t *len) {
      return FAIL;
   }

   default command result_t Settings.updateSetting[uint8_t id](uint8_t * buf, 
                                                              uint8_t *len) {
      return FAIL;
   }

   command result_t Piggyback.fillPiggyback(wsnAddr addr, uint8_t *buf, 
                                                            uint8_t len) {
      uint8_t i;

      for (i=0; i<len; i++) {
         buf[i] = 0;
      }

      for (i=0; i<feedbackLen; i++) {
         uint8_t lenUsed = len;

         if (call Settings.fillSetting[feedbackProps[i]](buf, &lenUsed) 
                                                            == SUCCESS) {
            buf += lenUsed;
            len -= lenUsed;
         } else {
            len = 0;
         }

         if (len == 0) {
            return SUCCESS;
         }
      }
      return SUCCESS;
   }

}
