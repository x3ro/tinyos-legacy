/**
 * Copyright (c) 2005 - Michigan State University.
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL MICHIGAN STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF MICHIGAN
 * STATE UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * MICHIGAN STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND MICHIGAN STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * Configuration file for MNP module
 * 
 * Authors: Limin Wang, Sandeep Kulkarni
 * 
 */

includes Mnp;

configuration MnpC
{
  provides interface Mnp;
  provides interface StdControl;
}

implementation{
  components MnpM, GenericComm, EEPROM, LedsC, TimerC, RandomLFSR; // CC1000ControlM;

  Mnp = MnpM.Mnp;

  StdControl = MnpM.StdControl;
  
  MnpM.ReceiveMsg -> GenericComm.ReceiveMsg[AM_MnpMsg_ID];
  MnpM.SendMsg    -> GenericComm.SendMsg[AM_MnpMsg_ID];  
  MnpM.GenericCommCtl -> GenericComm;
  MnpM.Leds -> LedsC;
  MnpM.EEPROMControl -> EEPROM;
  MnpM.EEPROMRead -> EEPROM.EEPROMRead;
  MnpM.EEPROMWrite -> EEPROM.EEPROMWrite[EEPROM_ID];
  MnpM.Timer -> TimerC.Timer[unique("Timer")];
  MnpM.Random -> RandomLFSR.Random;
//  MnpM.CC1000Control -> CC1000ControlM; 
}

//end
