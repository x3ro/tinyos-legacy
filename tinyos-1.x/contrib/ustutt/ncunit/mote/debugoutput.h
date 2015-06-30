/**
 * Copyright (c) 2007, Institute of Parallel and Distributed Systems
 * (IPVS), Universität Stuttgart. 
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the
 *    distribution.
 * 
 *  - Neither the names of the Institute of Parallel and Distributed
 *    Systems and Universität Stuttgart nor the names of its contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 */
#ifndef DEBUG_OUTPUT_H
#define DEBUG_OUTPUT_H


#define DBG_MODE(x) (x)
enum {
  DBG_ALL =		0xff,

/*====== Core mote modes =============*/
  DBG_BOOT =		DBG_MODE(0),	/* the boot sequence		*/
  DBG_CLOCK =		DBG_MODE(1),	/* clock        		*/
  DBG_TASK =		DBG_MODE(2),	/* task stuff			*/
  DBG_SCHED =		DBG_MODE(3),	/* switch, scheduling		*/
  DBG_SENSOR =		DBG_MODE(4),	/* sensor readings              */
  DBG_LED =	 	DBG_MODE(5),	/* LEDs         		*/
  DBG_CRYPTO =	        DBG_MODE(6),	/* Cryptography/security        */

/*====== Networking modes ============*/
  DBG_ROUTE =		DBG_MODE(7),	/* network routing       	*/
  DBG_AM =		DBG_MODE(8),	/* Active Messages		*/
  DBG_CRC =		DBG_MODE(9),	/* packet CRC stuff		*/
  DBG_PACKET =		DBG_MODE(10),	/* Packet level stuff 		*/
  DBG_ENCODE =		DBG_MODE(11),   /* Radio encoding/decoding      */
  DBG_RADIO =		DBG_MODE(12),	/* radio bits                   */

/*====== Misc. hardware & system =====*/
  DBG_LOG =	   	DBG_MODE(13),	/* Logger component 		*/
  DBG_ADC =		DBG_MODE(14),	/* Analog Digital Converter	*/
  DBG_I2C =		DBG_MODE(15),	/* I2C bus			*/
  DBG_UART =		DBG_MODE(16),	/* UART				*/
  DBG_PROG =		DBG_MODE(17),	/* Remote programming		*/
  DBG_SOUNDER =		DBG_MODE(18),   /* SOUNDER component            */
  DBG_TIME =	        DBG_MODE(19),   /* Time and Timer components    */
  DBG_POWER =	        DBG_MODE(20),   /* Power profiling      */


/*====== Simulator modes =============*/
  DBG_SIM =	        DBG_MODE(21),   /* Simulator                    */
  DBG_QUEUE =	        DBG_MODE(22),   /* Simulator event queue        */
  DBG_SIMRADIO =	DBG_MODE(23),   /* Simulator radio model        */
  DBG_HARD =	        DBG_MODE(24),   /* Hardware emulation           */
  DBG_MEM =	        DBG_MODE(25),   /* malloc/free                  */
//DBG_RESERVED =	DBG_MODE(26),   /* reserved for future use      */

/*====== For application use =========*/
  DBG_USR1 =		DBG_MODE(27),	/* User component 1		*/
  DBG_USR2 =		DBG_MODE(28),	/* User component 2		*/
  DBG_USR3 =		DBG_MODE(29),	/* User component 3		*/
  DBG_TEMP =		DBG_MODE(30),	/* Temorpary testing use	*/

  DBG_ERROR =		DBG_MODE(31),	/* Error condition		*/
  DBG_NONE =		0,		/* Nothing                      */

  DBG_DEFAULT =	     DBG_ALL	  	/* default modes, 0 for none	*/
};

//static void debug(uint8_t level, char* formatString, ...);

#endif

