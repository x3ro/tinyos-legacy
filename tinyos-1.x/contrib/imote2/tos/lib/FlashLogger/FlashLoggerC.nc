// $Id: FlashLoggerC.nc,v 1.1 2006/10/11 00:11:09 lnachman Exp $

/*									tab:4
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
 * 
 * Ported to Imote2 by Junaith Ahemed Shahahbdeen. The file provides the
 * wiring for the flash logger implementation.
 */

includes BlockStorage;

#ifdef KAJIMA_APP
  includes TestFlashFS;
#endif

configuration FlashLoggerC 
{
  provides 
  {
    interface FileMount [blockstorage_t blockId];
    interface FileRead [blockstorage_t blockId];
    interface FileWrite [blockstorage_t blockId];
  }
}

implementation 
{
  components FlashLoggerM, Main, StorageManagerC, LedsC as Leds;

#ifdef KAJIMA_APP
  components TestFlashFSM, BluSHC, FormatStorageC;
#endif

  FileMount = FlashLoggerM.Mount;
  FileRead = FlashLoggerM.BlockRead;
  FileWrite = FlashLoggerM.BlockWrite;

  Main.StdControl -> StorageManagerC;

  FlashLoggerM.SectorStorage -> StorageManagerC.SectorStorage;
  FlashLoggerM.ActualMount -> StorageManagerC.Mount;
  FlashLoggerM.StorageManager -> StorageManagerC.StorageManager;
  FlashLoggerM.Leds -> Leds;

#ifdef KAJIMA_APP
  Main.StdControl -> TestFlashFSM;

  TestFlashFSM.FormatStorage -> FormatStorageC.FileStorage;
  TestFlashFSM.Leds -> Leds;

  TestFlashFSM.Mount -> FlashLoggerM.Mount[FLASH_INTERFACE];
  TestFlashFSM.BlockWrite -> FlashLoggerM.BlockWrite[FLASH_INTERFACE];
  TestFlashFSM.BlockRead -> FlashLoggerM.BlockRead[FLASH_INTERFACE];

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
#endif
}
