// $Id: TestFlashFS.nc,v 1.1 2006/10/10 02:41:16 lnachman Exp $

/*									tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 */
includes TestFlashFS;
configuration TestFlashFS {
}

implementation 
{
  components Main, TestFlashFSM, LedsC, TimerC;
  components FormatStorageC;
  components BluSHC;
  components FlashLoggerC;

  Main.StdControl -> TestFlashFSM;
  Main.StdControl -> TimerC;

  TestFlashFSM.FormatStorage -> FormatStorageC.FileStorage;
  TestFlashFSM.Leds -> LedsC;

  TestFlashFSM.Mount -> FlashLoggerC.FileMount[FLASH_INTERFACE];
  TestFlashFSM.BlockWrite -> FlashLoggerC.FileWrite[FLASH_INTERFACE];
  TestFlashFSM.BlockRead -> FlashLoggerC.FileRead[FLASH_INTERFACE];

  BluSHC.BluSH_AppI[unique("BluSH")] -> TestFlashFSM.FSCreate;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestFlashFSM.FSClean;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestFlashFSM.NumFiles;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestFlashFSM.MntFiles;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestFlashFSM.FSInit;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestFlashFSM.FWrite;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestFlashFSM.FErase;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestFlashFSM.FRead;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestFlashFSM.FRseek;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestFlashFSM.FDel;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestFlashFSM.FList;
  BluSHC.BluSH_AppI[unique("BluSH")] -> TestFlashFSM.FClose;
}
