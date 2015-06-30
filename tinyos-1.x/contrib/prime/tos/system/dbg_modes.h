/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 *
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:		Philip Levis (derived from work by Mike Castelle)
 * Date last modified:  6/25/02
 *
 */

/* 
 *   FILE: dbg_modes.h 
 * AUTHOR: Phil Levis (pal)
 *  DESCR: Definition of dbg modes and the bindings to DBG env settings. 
 */


#ifndef DBG_MODES_H
#define DBG_MODES_H

#define DBG_MODE(x)	(1ULL << (x))

enum {
  DBG_ALL =		(~0ULL),	/* umm, "verbose"		*/

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
//DBG_RESERVED =	DBG_MODE(20),   /* reserved for future use      */


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

#define DBG_NAMETAB \
	{"all", DBG_ALL}, \
	{"boot", DBG_BOOT|DBG_ERROR}, \
	{"clock", DBG_CLOCK|DBG_ERROR}, \
        {"task", DBG_TASK|DBG_ERROR}, \
	{"sched", DBG_SCHED|DBG_ERROR}, \
	{"sensor", DBG_SENSOR|DBG_ERROR}, \
	{"led", DBG_LED|DBG_ERROR}, \
	{"crypto", DBG_CRYPTO|DBG_ERROR}, \
\
        {"route", DBG_ROUTE|DBG_ERROR}, \
        {"am", DBG_AM|DBG_ERROR}, \
        {"crc", DBG_CRC|DBG_ERROR}, \
        {"packet", DBG_PACKET|DBG_ERROR}, \
        {"encode", DBG_ENCODE|DBG_ERROR}, \
        {"radio", DBG_RADIO|DBG_ERROR}, \
\
	{"logger", DBG_LOG|DBG_ERROR}, \
        {"adc", DBG_ADC|DBG_ERROR}, \
        {"i2c", DBG_I2C|DBG_ERROR}, \
        {"uart", DBG_UART|DBG_ERROR}, \
        {"prog", DBG_PROG|DBG_ERROR}, \
        {"sounder", DBG_SOUNDER|DBG_ERROR}, \
        {"time", DBG_TIME|DBG_ERROR}, \
\
        {"sim", DBG_SIM|DBG_ERROR}, \
        {"queue", DBG_QUEUE|DBG_ERROR}, \
        {"simradio", DBG_SIMRADIO|DBG_ERROR}, \
        {"hardware", DBG_HARD|DBG_ERROR}, \
        {"simmem", DBG_MEM|DBG_ERROR}, \
\
        {"usr1", DBG_USR1|DBG_ERROR}, \
        {"usr2", DBG_USR2|DBG_ERROR}, \
        {"usr3", DBG_USR3|DBG_ERROR}, \
        {"temp", DBG_TEMP|DBG_ERROR}, \
	{"error", DBG_ERROR}, \
\
        {"none", DBG_NONE}, \
        { NULL, DBG_ERROR } 

#define DBG_ENV		"DBG"

#endif 
