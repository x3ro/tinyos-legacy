/*									tab:4
 *
 *
 * "Copyright (c) 2002 and The Regents of the University 
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
 * Authors:	        Joe Polastre
 *
 *
 */

#include "tos.h"
#include "MICAWB_I2CTEMP.h"
#include "dbg.h"

#define IDLE                   99
#define SINGLE_PICK_CHANNEL    10
#define SINGLE_GET_SAMPLE      11
#define SINGLE_GOT_SAMPLE      12
#define MULT_PICK_CHANNEL      20

#define TOS_FRAME_TYPE MICAWB_I2CTEMP_obj_frame
TOS_FRAME_BEGIN(MICAWB_I2CTEMP_obj_frame) {
	char state;    /* current state of the i2c request */
        char addr;     /* destination address */
	char condition; /* set the condition command byte */
	char flags;    /* flags set on the I2C packets */
	short value;   /* value of the incoming ADC reading */
}
TOS_FRAME_END(MICAWB_I2CTEMP_obj_frame);

char TOS_COMMAND(I2CTEMP_INIT)()
{
  VAR(state) = IDLE;
  VAR(addr) = 0x4C;
  TOS_CALL_COMMAND(I2CTEMP_SUB_INIT)();
  return 1;
}

/** gets a single sample from the I2C ADC at addr on channel **/
char TOS_COMMAND(I2CTEMP_GET_SAMPLE)()
{
  if (VAR(state) == IDLE)
    {
      VAR(state) = SINGLE_GET_SAMPLE;
      VAR(flags) = 0x03;
      if (TOS_CALL_COMMAND(I2CTEMP_READ_PACKET)(VAR(addr), 2, VAR(flags)) == 0)

	/*      VAR(state) = SINGLE_PICK_CHANNEL;

      VAR(condition) = 0x00;

      VAR(flags) = 0x00; 

      if (TOS_CALL_COMMAND(I2CTEMP_WRITE_PACKET)(VAR(addr), 1, (char*)(&VAR(condition)), VAR(flags)) == 0)  */
	{
	  VAR(state) = IDLE;
	  return 0;
	}
      return 1;
    }
  return 0;
}

/* packet has been read from the I2C bus and needs to be evaluated */
char TOS_EVENT(I2CTEMP_READ_PACKET_DONE)(char length, char* data)
{
  /* got the sample, now process it, send the stop command, and signal */
  if (VAR(state) == SINGLE_GET_SAMPLE)
    {
      //TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
      VAR(state) = SINGLE_GOT_SAMPLE;
      VAR(value) = (data[0] << 8) & 0xff00;
      VAR(value) += (data[1] & 0xff);
      VAR(state) = IDLE;
      TOS_SIGNAL_EVENT(I2CTEMP_GET_SAMPLE_DONE)(VAR(value));
    }
  return 1;
}

/* packet has been writen to the I2C bus */
char TOS_EVENT(I2CTEMP_WRITE_PACKET_DONE)(char success)
{
  if (VAR(state) == SINGLE_PICK_CHANNEL)
    {
      VAR(state) = SINGLE_GET_SAMPLE;
      VAR(flags) = 0x03;
      if (TOS_CALL_COMMAND(I2CTEMP_READ_PACKET)(VAR(addr), 2, VAR(flags)) == 0)
	{
	  /* reading from the bus failed */
	  VAR(state) = IDLE;
	  TOS_SIGNAL_EVENT(I2CTEMP_GET_SAMPLE_DONE)(-1);
	}
      return 1;
    }
  return 1;
}
