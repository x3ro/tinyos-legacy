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
 * Authors:     Mark Yarvis, York Liu
 *
 */

includes WSN;
includes WSN_Settings;
includes WSN_Messages;

configuration GenericSettingsHandler {
   provides {
      interface StdControl as Control;
      interface Piggyback;            // provides piggybacked settings feedback
   }
   uses {
      interface Settings[uint8_t id]; // interface to settings clients
   }
}

implementation {
   components GenericSettingsHandlerM, 
#if PLATFORM_MICA2 || PLATFORM_MICA2DOT
              CC1000ControlM, 
#else
              PotC, 
#endif
              Flood, 
              LedsC,
	      ResetC;

   Control = GenericSettingsHandlerM.Control;
   Piggyback = GenericSettingsHandlerM.Piggyback;
   Settings = GenericSettingsHandlerM.Settings;

   GenericSettingsHandlerM.Intercept -> Flood.Intercept[APP_ID_SETTINGS];
   GenericSettingsHandlerM.MultiHopMsg -> Flood;
   GenericSettingsHandlerM.TransportControl -> Flood;
   GenericSettingsHandlerM.Reset -> ResetC;

   // locally handled settings types
   GenericSettingsHandlerM.Settings[SETTING_ID_PROGVER] 
                              -> GenericSettingsHandlerM.ProgramVersion;
   GenericSettingsHandlerM.Settings[SETTING_ID_SETVER] 
                              -> GenericSettingsHandlerM.SettingsVersion;
   GenericSettingsHandlerM.Settings[SETTING_ID_POTSET] 
                              -> GenericSettingsHandlerM.PotSet;
   GenericSettingsHandlerM.Settings[SETTING_ID_BUILD_DATE] 
                              -> GenericSettingsHandlerM.BuildDate;
   GenericSettingsHandlerM.Settings[SETTING_ID_FEEDBACK_LIST] 
                              -> GenericSettingsHandlerM.FeedbackList;
   GenericSettingsHandlerM.Settings[SETTING_ID_FEEDBACK_ID] 
                              -> GenericSettingsHandlerM.FeedbackID;
   GenericSettingsHandlerM.Settings[SETTING_ID_RESET] 
                              -> GenericSettingsHandlerM.ResetMote;
   GenericSettingsHandlerM.Settings[SETTING_ID_FREQSET] 
                              -> GenericSettingsHandlerM.FreqSet;

#if PLATFORM_MICA2 || PLATFORM_MICA2DOT
   GenericSettingsHandlerM.CC1000Control -> CC1000ControlM;
   GenericSettingsHandlerM.RadioControl -> CC1000ControlM;
#else
   GenericSettingsHandlerM.Pot -> PotC;
#endif

   GenericSettingsHandlerM.Leds -> LedsC;
}
