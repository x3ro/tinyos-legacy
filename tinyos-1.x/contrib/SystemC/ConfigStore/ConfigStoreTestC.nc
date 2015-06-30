/*
 * "Copyright (c) 2003 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:		Philip Levis
 * Date last modified:  6/16/03
 *
 */

configuration ConfigStoreTestC {}
implementation {
  components ConfigStoreTestM, ConfigStoreC, GenericComm, Main, LedsC;

  Main.StdControl -> ConfigStoreTestM;
  ConfigStoreTestM.NetworkControl -> GenericComm;
  ConfigStoreTestM.ConfigStoreControl -> ConfigStoreC;
  ConfigStoreTestM.ConfigRead -> ConfigStoreC;
  ConfigStoreTestM.ConfigWrite -> ConfigStoreC;
  
  //ConfigStoreTestM.ReceiveWrite -> GenericComm.ReceiveMsg[32];
  //ConfigStoreTestM.ReceiveRead -> GenericComm.ReceiveMsg[33];
  ConfigStoreTestM.SendMsg -> GenericComm.SendMsg[34];

  ConfigStoreC.Leds -> LedsC;
}
