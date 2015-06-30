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
 * Query Assembler - gather multiple messages sent from a remote
 * Link User into a singel query
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/
 

configuration QueryAssemblerC {
  provides {
    interface StdControl;
    interface ProcessCmd as ProcessQuery[uint8_t id];
  }
}
implementation {
  components
      //Main
      QueryAssemblerM
    , QueryProcessorC
    , UllaCoreC
    , QueryM
		, UllaAllocC // parameterized-interface version of TinyAlloc
    , LedsC
    ;

  
  StdControl = QueryAssemblerM;

  QueryAssemblerM.Leds -> LedsC;
  QueryAssemblerM.UllaAlloc -> UllaAllocC.QauAlloc;
	
	QueryAssemblerM.Query -> QueryM;

	QueryAssemblerM.UqpIf -> UllaCoreC.UqpIf[REMOTE_LU]; // REMOTE_LU
  ProcessQuery = QueryAssemblerM;
      
}
