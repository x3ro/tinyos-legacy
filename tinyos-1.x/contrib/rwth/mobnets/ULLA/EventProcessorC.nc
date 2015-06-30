/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */
 
/**
 *
 * Ulla Event Processing - in charge of collecting the various
 * events from their sources (i.e. the link providers), delivering
 * them to the corresponding link users or applications.
 <p>
 * There are different sorts of events considered so far:
 *  - attribute events: correspond to a certain circumstance (e.g.
 *    crossing some threshold level)
 *  - link events: used to notify the ULLA core about the status of 
 *    the different link providers, allowing it to track them.
 *  - command completion events: used by the link providers to deliver
 *    the information generated after the completion of a particular 
 *    command, as requested by the application through the Ulla 
 *    Command Processing.
 <p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/

includes UQLCmdMsg;

configuration EventProcessorC {
  provides {
    interface StdControl;
    interface ProcessCmd as ProcessEvent[uint8_t channel];
  }
}
implementation {
  components
    EventProcessorM
    , LedsC
    ;

  StdControl = EventProcessorM;
	
  EventProcessorM.Leds -> LedsC;

  ProcessEvent = EventProcessorM;
  //AttributeEvent   = EventProcessorM;
  //LinkEvent        = EventProcessorM;
  //CompleteCmdEvent = EventProcessorM;  
  //EventProcessorM.RequestUpdate-> LLAC;
  
      
  

  
}
