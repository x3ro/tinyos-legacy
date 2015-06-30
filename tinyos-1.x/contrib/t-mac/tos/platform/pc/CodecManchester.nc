/*
 * Copyright (c) 2002-2004 the University of Southern California
 * Copyright (c) 2004 TU Delft/TNO
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement 
 * is hereby granted, provided that the above copyright notice and the
 * following two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * COPYRIGHT HOLDERS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE COPYRIGHT HOLDERS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
 * IS ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDERS HAVE NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Wei Ye (S-MAC version), Tom Parker (T-MAC modifications)
 * Manchester encoding module for the PC
 * Not strictly necessary for most TOSSIM scenarios, but included anyways
 *
 */

/**
 * @author Wei Ye
 * @author Tom Parker
 */

module CodecManchester
{
   provides {
      interface StdControl;
      interface RadioEncoding as Codec;
   }
}

implementation
{
   //table for performing the encoding.
   char encodeTab[] /*__attribute__((C))*/ = {
      0x55,
      0x56,
      0x59,
      0x5a,
      0x65,
      0x66,
      0x69,
      0x6a,
      0x95,
      0x96,
      0x99,
      0x9a,
      0xa5,
      0xa6,
      0xa9,
      0xaa
   };

   // declare constants and variables
   enum { IDLE_STATE, DECODING_BYTE };

   char state;
   char error;
   uint8_t decodedVal;
   uint8_t bitVal;

   char radio_decode_thread(char data);
   
   
   command result_t StdControl.init()
   {
      state = IDLE_STATE;
      return SUCCESS;
   }
   
   
   command result_t StdControl.start()
   {
      return SUCCESS;
   }
   
   
   command result_t StdControl.stop()
   {
      return SUCCESS;
   }
   
   
   command result_t Codec.decode(char data)
   {
      if(state == IDLE_STATE) {
         state = DECODING_BYTE;
         decodedVal = 0;
         bitVal = 0x80;
         error = radio_decode_thread(data);
      } else if (state == DECODING_BYTE) {
         error |= radio_decode_thread(data);
         signal Codec.decodeDone(decodedVal, error);
         state = IDLE_STATE;
      }
      return SUCCESS;
   }
   
   
   command result_t Codec.encode_flush()
   {
      return SUCCESS;
   }


   command result_t Codec.encode(char data)
   {
      char high, low;
	  dbg(DBG_RADIO,"Encoding %02X\n",(unsigned char)data);
	  //dbg(DBG_RADIO,"High byte = %X (%X)\n",(data & 0xF0) >> 4,encodeTab[1]);
      if(state == IDLE_STATE){
         low = encodeTab[(unsigned int)(data & 0xF)];
         //high = encodeTab[(unsigned int)((data >> 4) & 0xf)];
         high = encodeTab[(unsigned int)((data & 0xF0) >> 4)];
         signal Codec.encodeDone(high);  // high byte is sent first
         signal Codec.encodeDone(low);
         return SUCCESS;
      }
      return FAIL;	
   }


   char radio_decode_thread(char data)
   {
      uint8_t mask, i, temp;
      char error1 = 0;
      mask = 0x80;
      for (i = 0; i < 4; i++) {
         temp = data & mask;
         if((data << 1 & mask) == temp) error1 = 1;
         if (temp) decodedVal += bitVal;
         bitVal >>= 1;
         mask >>= 2;
      }
      return error1;
   }

} // end of implementation
