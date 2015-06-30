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
/*
 * The WSN addresses are 8 bits, the iMote addresses are 32 bits
 * and they start with 0x85000.  For now, the WSN addresses are restricted
 * to 8 bits, they will change it to 16 which will be sufficient for iMotes
 * For now, assume range is 0x85100 - 0x85255.  Subtract/Add offset when
 * converting.
 * TODO : Need to fix when WSN moves to 16 bits
 */
//#define ADDR_OFFSET 0x85100
#define ADDR_OFFSET 0
#define TABLE_MAP 0
includes WSN;
module UtilitiesM {

   provides {
      command result_t iMoteToTOSAddr(uint32 Imote_Addr, uint16 *TOSAddr);
      command result_t TOSToIMoteAddr(uint16 TOSAddr, uint32 *Imote_Addr);
   }
}

implementation {

   uint16 TableImoteToTOS(uint32 imote_addr) {
      switch(imote_addr) {
         case 0x86140 :
            return 100;
         case 0x86132 :
            return 101;
         case 0x86289 :
            return 102;
         case 0x86259:
            return 103;
         case 0x86206:
            return 104;
         case 0x86202:
            return 105;
         case 0x86314:
            return 106;
         case 0x85064:
            return 107;
         case 0x86316:
            return 122;
         case 0x86208:
            return 123;
         case 0x86308:
            return 124;
         case 0x86266:
            return 125;
         default :
            return 199;
      }
   }

   uint32 TableTOSToImote(uint16 TOS_Addr) {
      switch(TOS_Addr) {
         case 100:
            return 0x86140;
         case 101:
            return 0x86132;
         case 102:
            return 0x86289;
         case 103:
            return 0x86259;
         case 104:
            return 0x86206;
         case 105:
            return 0x86202;
         case 106:
            return 0x86314;
         case 107:
            return 0x85064;
         case 122:
            return 0x86316;
         case 123:
            return 0x86208;
         case 124:
            return 0x86308;
         case 125:
            return 0x86266;
         default :
            return 0x86000;
      }
   }

   command result_t iMoteToTOSAddr(uint32 Imote_Addr, uint16 *TOSAddr) {
#if TABLE_MAP
      *TOSAddr = TableImoteToTOS(Imote_Addr);
#else
      uint32 temp;
      temp = Imote_Addr - ADDR_OFFSET;
      *TOSAddr = (uint16) temp;
#endif
      return SUCCESS; 
   }

   command result_t TOSToIMoteAddr(uint16 TOSAddr, uint32 *Imote_Addr) {
#if TABLE_MAP
      *Imote_Addr = TableTOSToImote(TOSAddr);
#else
      *Imote_Addr = ADDR_OFFSET + TOSAddr;
#endif
      return SUCCESS; 
   }
}
