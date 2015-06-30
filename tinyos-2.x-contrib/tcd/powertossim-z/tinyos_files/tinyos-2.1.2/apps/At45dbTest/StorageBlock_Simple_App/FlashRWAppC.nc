/*
 * Copyright (c) 2008 Trinity College Dublin.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Trinity College Dublin nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL TRINITY
 * COLLEGE DUBLIN OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Reads and writes from the flash periodically.  Based on the implementation
 * of Block storage test application by David Gay at:
 * /apps/tests/storage/Block/RandRWC.nc
 *
 * @author Ricardo Simon Carbajo
 */

#include "StorageVolumes.h"


configuration FlashRWAppC { }
implementation {
  components FlashRWC, new BlockStorageC(VOLUME_BLOCKTEST),
    MainC, LedsC;
 
  MainC.Boot <- FlashRWC;
  
  FlashRWC.BlockRead -> BlockStorageC.BlockRead;
  FlashRWC.BlockWrite -> BlockStorageC.BlockWrite;
  FlashRWC.Leds -> LedsC;
  
  components new TimerMilliC() as TimerMilliCWrite;
  components new TimerMilliC() as TimerMilliCRead;
  FlashRWC.MilliTimerWrite -> TimerMilliCWrite;
  FlashRWC.MilliTimerRead -> TimerMilliCRead;
}
