// $Id: SimpleCmd.nc,v 1.3 2003/10/07 21:44:59 idgay Exp $

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
 * Configuration for SimpleCmd module.
 *
 * Author/Contact: tinyos-help@millennium.berkeley.edu
 * 
 * Description:
 *
 * SimpleCmd module demonstrates a simple command interpreter for TinyOS tutorial 
 * (Lesson 8 in particular).  It receives a command message from its RF interface,
 * which triggers a command interpreter task to execute the command.
 * When the command is finished executing, the component signals the upper 
 * layers with the received message and the status indicating whether the message
 * should be further processed. 
 *
 * As a simple version,  it can only interpret the follwoing commands:
 * Led_on (1), Led_off(2), radio_quieter(3), radio_louder(4), 
 * start_sensing(5), and read_log(6). Start sensing commands will trigger 
 * the Sensing.start interface while read log will read the EEPROM with 
 * a specific log line and broadcast the line over the radio when read is done.
 */
includes SimpleCmdMsg;

configuration SimpleCmd {
  provides interface ProcessCmd;
}
implementation {
  components Main, SimpleCmdM, SenseLightToLog, Logger,
    GenericComm as Comm, PotC, LedsC;

  Main.StdControl -> SimpleCmdM;
  SimpleCmdM.Leds -> LedsC;

  ProcessCmd = SimpleCmdM.ProcessCmd;

  SimpleCmdM.CommControl -> Comm;

  SimpleCmdM.ReceiveCmdMsg -> Comm.ReceiveMsg[AM_SIMPLECMDMSG];
  SimpleCmdM.SendLogMsg -> Comm.SendMsg[AM_LOGMSG];
  SimpleCmdM.LoggerRead -> Logger;
  SimpleCmdM.Pot -> PotC;
  SimpleCmdM.Sensing -> SenseLightToLog.Sensing;
}

