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
 * Ulla Storage - maintains a cached version class definitions
 * (representing link definitions) as well as instances of these
 * classes (representing discovered links). Cashed versions of
 * known links are kept in the ULLA storage to enable applications
 * to quickly access the information regarding existing links,
 * without necessarily to have to talk to the underlying driver.
<p>
 * The assumption is that most of the time the information returned
 * for a query can be slightly out of date. For example, an application
 * requesting the bandwidth of a link does not need to receive the
 * bandwidth exactly at the instant of the query but can probably be
 * ok with a 2-second old information. Also, timestamps are associated
 * with all attributes of cached classes in order to implement a "lazy"
 * update strategy.
<p>
<p>
 * Technical Details - ByteEEPROM takes a buffer of arbitrary length
 * and uses it to read/write data to/from a flash. This buffer is
 * provided by the application, it depends on the user how much RAM
 * will be allocated for flash operations.
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/

includes UQLCmdMsg;
//includes UllaStorage;
//includes Storage;

configuration ULLAStorageC {
  provides {
    interface StdControl;
    interface StorageIf;
    //interface ReadFromStorage;
    //interface WriteToStorage;
  }
}
implementation {
  components
  	  //Main
      ULLAStorageM
    //, TinyAlloc
		, UllaAllocC
    , LedsC
    , TimerC
    ;

  //Main.StdControl -> ULLAStorageM;
  StdControl = ULLAStorageM;
  StorageIf = ULLAStorageM;
  
  //ULLAStorageM.MemAlloc -> TinyAlloc;
	ULLAStorageM.MemAlloc -> UllaAllocC.StorageAlloc;
  ULLAStorageM.ValidityTimer -> TimerC.Timer[unique("Timer")];
  ULLAStorageM.Leds -> LedsC;

}

