/*									tab:4
 *
 *
 * "Copyright (c) 2001 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:		Phil Levis (derived from work by Mike Castelle)
 *
 *
 */

/* 
 *   FILE: dbg_modes.h 
 * AUTHOR: Phil Levis (pal)
 *  DESCR: Definition of dbg modes and their binding to DBG env settings. 
 */


#ifndef DBG_MODES_H
#define DBG_MODES_H

#define DBG_MODE(x)	(1ULL << (x))


#define DBG_ALL		(~0ULL)		/* umm, "verbose"		*/

/******* Core mote modes **************/
#define DBG_BOOT	DBG_MODE(0)	/* the boot sequence		*/
#define DBG_CLOCK	DBG_MODE(1)	/* clock        		*/
#define DBG_TASK	DBG_MODE(2)	/* task stuff			*/
#define DBG_SCHED	DBG_MODE(3)	/* switch, scheduling		*/
#define DBG_SENSOR	DBG_MODE(4)	/* sensor readings              */
#define DBG_LED 	DBG_MODE(5)	/* LEDs         		*/
// #define DBG_RESERVED	DBG_MODE(6)	/* reserved for future use      */

/******* Networking modes *************/
#define DBG_ROUTE	DBG_MODE(7)	/* network routing       	*/
#define DBG_AM		DBG_MODE(8)	/* Active Messages		*/
#define DBG_CRC		DBG_MODE(9)	/* packet CRC stuff		*/
#define DBG_PACKET	DBG_MODE(10)	/* Packet level stuff 		*/
#define DBG_ENCODE	DBG_MODE(11)    /* Radio encoding/decoding      */
#define DBG_RADIO	DBG_MODE(12)	/* radio bits                   */

/******* Misc. hardware & system ******/
#define DBG_LOG   	DBG_MODE(13)	/* Logger component 		*/
#define DBG_ADC		DBG_MODE(14)	/* Analog Digital Converter	*/
#define DBG_I2C		DBG_MODE(15)	/* I2C bus			*/
#define DBG_UART	DBG_MODE(16)	/* UART				*/
#define DBG_PROG	DBG_MODE(17)	/* Remote programming		*/
#define DBG_SOUNDER     DBG_MODE(18)    /* SOUNDER component            */
// #define DBG_RESERVED    DBG_MODE(19)    /* reserved for future use      */
// #define DBG_RESERVED    DBG_MODE(20)    /* reserved for future use      */


/******* Simulator modes **************/
#define DBG_SIM         DBG_MODE(21)    /* Simulator                    */
#define DBG_QUEUE       DBG_MODE(22)    /* Simulator event queue        */
#define DBG_SIMRADIO    DBG_MODE(23)    /* Simulator radio model        */
#define DBG_HARD        DBG_MODE(24)    /* Hardware emulation           */
#define DBG_MEM         DBG_MODE(25)    /* malloc/free                  */
//#define DBG_RESERVED    DBG_MODE(26)    /* reserved for future use      */

/******* For application use **********/
#define DBG_USR1	DBG_MODE(27)	/* User component 1		*/
#define DBG_USR2	DBG_MODE(28)	/* User component 2		*/
#define DBG_USR3	DBG_MODE(29)	/* User component 3		*/
#define DBG_TEMP	DBG_MODE(30)	/* Temorpary testing use	*/

#define DBG_ERROR	DBG_MODE(31)	/* Error condition		*/
#define DBG_NONE	0		/* Nothing                      */

#define DBG_DEFAULT     DBG_ALL	  	/* default modes, 0 for none	*/

#define DBG_NAMETAB \
	{"all", DBG_ALL}, \
	{"boot", DBG_BOOT|DBG_ERROR}, \
	{"clock", DBG_CLOCK|DBG_ERROR}, \
        {"task", DBG_TASK|DBG_ERROR}, \
	{"sched", DBG_SCHED|DBG_ERROR}, \
	{"sensor", DBG_SENSOR|DBG_ERROR}, \
	{"led", DBG_LED|DBG_ERROR}, \
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
