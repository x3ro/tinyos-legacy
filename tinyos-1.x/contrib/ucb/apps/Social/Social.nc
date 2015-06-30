/*									tab:4
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 *
 * Social-network application. This application is a combined person tracker
 * (like Ident) and social-network builder (i.e., it keeps track of which
 * other people you spend time with). The PC-side application is in 
 * net.tinyos.social and logs the social-network information to a database.
 */
includes SocialMsg;
configuration Social { }
implementation
{
  components Main, SocialM, GenericComm as Comm, Checkpoint, IdentC, TimerC;
  components PotC, LedsC, RangeC, EEPROM;

  Main.StdControl -> SocialM;

  SocialM.SubControl -> IdentC;
  SocialM.SubControl -> Comm;
  SocialM.SubControl -> TimerC;

  SocialM.CheckpointInit -> Checkpoint;
  SocialM.CheckpointRead -> Checkpoint;
  SocialM.CheckpointWrite -> Checkpoint;

  SocialM.Ident -> IdentC;
  SocialM.Timer -> TimerC.Timer[unique("Timer")];
  SocialM.Pot -> PotC;
  SocialM.Leds -> LedsC;

  SocialM.SendSocialMsg -> Comm.SendMsg[AM_DATAMSG];
  SocialM.ReceiveIdMsg -> Comm.ReceiveMsg[AM_IDENTMSG];
  SocialM.ReceiveReqDataMsg -> Comm.ReceiveMsg[AM_REQDATAMSG];
  SocialM.ReceiveRegisterMsg -> Comm.ReceiveMsg[AM_REGISTERMSG];

  IdentC.Leds -> LedsC;
  IdentC.Timer -> TimerC.Timer[unique("Timer")];
  IdentC.SendIdMsg -> Comm.SendMsg[AM_IDENTMSG];
  IdentC.ReceiveIdMsg -> Comm.ReceiveMsg[AM_IDENTMSG];
  IdentC.Range -> RangeC;

  Checkpoint.EEPROMRead -> EEPROM;
  Checkpoint.EEPROMWrite -> EEPROM.EEPROMWrite[unique("EEPROMWrite")];
  Checkpoint.EEPROMControl -> EEPROM;
}

