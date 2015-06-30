/**
 * Copyright (c) 2008 - George Mason University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL GEORGE MASON UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF GEORGE MASON
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * GEORGE MASON UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND GEORGE MASON UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * @author Leijun Huang <lhuang2@gmu.edu>
 **/

/**
 * This configuration wraps the STM25P block storage read/write access
 * to provide the old LoggerRead/LoggerWrite interfaces (on 16-byte 
 * entries).
 * See LoggerM.nc for implementation.
 */

includes BlockStorage;
includes Logger;

configuration Logger {
  provides {
    interface LoggerInit;
    interface LoggerRead;
    interface LoggerWrite;
  }
}

implementation {
  components Main, LoggerM, BlockStorageC, FlashWPC;

  LoggerInit = LoggerM.LoggerInit;
  LoggerRead = LoggerM.LoggerRead;
  LoggerWrite = LoggerM.LoggerWrite;

  Main.StdControl -> FlashWPC;

  LoggerM.Mount -> BlockStorageC.Mount[BLOCKSTORAGE_CLIENTID];
  LoggerM.BlockRead -> BlockStorageC.BlockRead[BLOCKSTORAGE_CLIENTID];
  LoggerM.BlockWrite -> BlockStorageC.BlockWrite[BLOCKSTORAGE_CLIENTID];
  LoggerM.FlashWP -> FlashWPC;
}
