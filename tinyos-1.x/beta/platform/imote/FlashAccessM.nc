/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

module FlashAccessM
{
  provides {
    interface StdControl as FlashControl;
    interface LoggerWrite as FlashWrite;
    interface LoggerRead as FlashRead;
  }
  uses {
    interface Leds;
  }
}

implementation{
   uint16_t curFlashWriteID, curFlashReadID;
   uint16_t rec_size=1024;

  command result_t FlashControl.init() {
   // TM_InitFlashControl();
  //  bool res =  TM_InitFlashDynamicDB();
    
    curFlashWriteID = TM_FLASH_LAST_USER_ID-TM_FLASH_MAX_RECS;
    curFlashReadID = TM_FLASH_LAST_USER_ID-TM_FLASH_MAX_RECS;
    call Leds.init();
  }


  command result_t FlashControl.start() {
  }

  command result_t FlashControl.stop() {
  }

  command result_t FlashRead.read(uint16_t ID, uint8_t *buffer){
    uint8_t *rd_ptr;
    result_t result;
    rd_ptr = TM_API_GetFlashReadPtr(ID);
    if(rd_ptr){
      result = SUCCESS;
      //call Leds.greenToggle();
    }
    else
      result = !SUCCESS;
    buffer = rd_ptr;
    return signal FlashRead.readDone(rd_ptr,result);
    }
   

  command result_t FlashRead.readNext(uint8_t *buffer){
      curFlashReadID++;
      return call FlashRead.read(curFlashReadID,buffer);
  }
 
  command result_t FlashRead.resetPointer(){
    curFlashReadID = TM_FLASH_LAST_USER_ID - TM_FLASH_MAX_RECS;     
    return SUCCESS;
  }

  command result_t FlashRead.setPointer(uint16_t ID){
    curFlashReadID = ID;
  }

  command result_t FlashWrite.append(uint8_t *buffer){
    curFlashWriteID++;
    return call FlashWrite.write(curFlashWriteID,buffer);
  }

  command result_t FlashWrite.write(uint16_t ID, uint8_t* buffer){
     uint8_t* wrt_ptr;
     result_t result;
     wrt_ptr = TM_API_GetFlashWritePtr(ID,rec_size);
     if(wrt_ptr){
       //memcpy(wrt_ptr,buffer,16);
       TM_API_FlashWriteDone(ID); 
       result=SUCCESS;
       //call Leds.greenToggle();
     }
     else{
       result=!SUCCESS;
       //call Leds.greenToggle();
     }
     return signal FlashWrite.writeDone(result); 
  }

  command result_t FlashWrite.resetPointer(){
    curFlashWriteID = TM_FLASH_LAST_USER_ID - TM_FLASH_MAX_RECS;
    return SUCCESS;
  }
 
  command result_t FlashWrite.setPointer(uint16_t ID){
    curFlashReadID = ID;
  }

}
