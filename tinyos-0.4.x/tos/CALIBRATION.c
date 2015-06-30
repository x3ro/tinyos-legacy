/*									tab:4
 * CALIBRATION.comp
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
 * Authors:		Sam Madden
 
	Stores calibration information for sensors in the EEPROM.

	Calibration layer supports the CALIBRATION_REQUEST active message,
	which can initiate one of four calibration commands, as follows.
	Each command accepts a sensor id (0-3 maximum)

	1) map a raw sensor reading into a calibrated value
	2) specify a mapping from a raw sensor reading and a calibrated value
	3) set all calibrated data to zero
	4) linearly interpolate zero values between non-zero values

	Each calibrated value is given two bytes of storage, and stored at
	an offset equal to its raw sensor value.

	Each sensor is assumed to be 10 bits, so each table occupies (2 ^ 10) * 2 bytes == 2kb of storage
	
 */
#include "tos.h"
#include "CALIBRATION.h"

#include "CALIBRATION_MSG.h"
#include <math.h>

//where to start writing calibration data into EEPROM
//kEEPROM_BLOCK_SIZE * kSTART_LINE == offset in bytes
#define kSTART_LINE 512 //half way into eeprom
#define kMAX_SENSORS 4
#define kBYTES_PER_ENTRY 2

#define NUM_LINES(bitsPerEntry) ((short)((pow2((bitsPerEntry)+1/*mult result by kBYTES_PER_ENTRY*/-4/*div by kEEPROM_BLOCK_SIZE*/))))
//defines for commands in CALIBRATION_REQUEST
#define kZERO_MODE 0
#define kINTERP_MODE 1
#define kWRITE_MODE 2
#define kIDLE_MODE 3
#define kREAD_MODE 4
#define kEEPROM_BLOCK_SIZE 16


#define TOS_FRAME_TYPE CALIBRATION_frame
TOS_FRAME_BEGIN(CALIBRATION_frame) {
  char pending; //1 byte

  //ick -- share these since they're both big and not
  //used at the same time
  union {
    TOS_Msg msg; //37 bytes
    char data[kEEPROM_BLOCK_SIZE];
  };

  short starts[kMAX_SENSORS];  //8 bytes
  char bits[kMAX_SENSORS];     //4 bytes
  short next_start;  //1 
  short line;
  
  union { //weird -- these must never be used in the same pieces of code
    short last_line;  //2
    short offset;
  };

  short value; //data to write -- 2

  short lastvalue; //last non-interpreted value read --2 
  short lastvalueline;  //line which contained last non-interpreted value --2
  short nextvalue; //next non-interpreted value -- 2
  short distance; //distance to next non-interpreted value --2
  short total_distance; //total number of zeros
  char jump_back; //should start at lastvalueline

  char mode; //1


  short write_delay; //2 bytes

} //1 + 37 + 8 + 4 + 1 + 2 + 2 + 2 + 2 + 2 + 2 + 1 + 2 = 66 -- hmm

TOS_FRAME_END(CALIBRATION_frame);

void interp_data();
short pow2(short exp);

//init calibration tables for the four sensors
//assuming each has 10-bit values
char TOS_COMMAND(CALIB_INIT)() {

  VAR(pending) = 0;  
  VAR(mode) = kIDLE_MODE;
  VAR(next_start) = kSTART_LINE;

  TOS_CALL_COMMAND(CALIB_INIT_SENSOR)(0, 10);
  TOS_CALL_COMMAND(CALIB_INIT_SENSOR)(1, 10);
  TOS_CALL_COMMAND(CALIB_INIT_SENSOR)(2, 10);
  TOS_CALL_COMMAND(CALIB_INIT_SENSOR)(3, 10);

  TOS_CALL_COMMAND(CALIB_CLOCK_INIT)(11, 3);
  VAR(write_delay) = -1;
  TOS_CALL_COMMAND(CALIB_INIT_SUB)();
  
  return 1;
}

//we use the clock module to make we wait 
//long enough between EEPROM writes
void TOS_EVENT(CALIB_CLOCK_EVENT)(){
    if (VAR(write_delay) > 0) 
	VAR(write_delay)--;
    if (VAR(write_delay) == 0) {
	TOS_SIGNAL_EVENT(WRITE_DONE)(1);
    }
    
}

char TOS_COMMAND(CALIB_START)() {
  return 1;
}

/* initialize the calibraton information for the specified sensor id 
   assuming the sensor uses bitsPerEntry bits per sample.
*/	
char TOS_COMMAND(CALIB_INIT_SENSOR)(int sid, int bitsPerEntry) {
  VAR(bits)[sid] = bitsPerEntry & 0xFF;
  VAR(starts)[sid] = VAR(next_start);
  VAR(next_start) = VAR(next_start) + NUM_LINES(bitsPerEntry);
  return 1;
}

/* zero the calibration data for the specified sensor id 
   may require substantial time to complete as it must overwrite
   the entire calibration table with zeros
*/
char TOS_COMMAND(ZERO_DATA)(int sid) {
  int i;


  if (VAR(mode) != kIDLE_MODE) return 0; //failure
  VAR(line) = VAR(starts)[sid];
  VAR(last_line) = VAR(line) + NUM_LINES(VAR(bits)[sid]);
  // fprintf (stderr, "calling ZERO_DATA, curline = %d, lastline = %d\n", VAR(line), VAR(last_line));
  VAR(mode) = kZERO_MODE;
  for (i = 0; i < kEEPROM_BLOCK_SIZE; i++) {
    VAR(data)[i] = 0;
  }
  return TOS_CALL_COMMAND(CALIB_EEPROM_WRITE)(VAR(line), VAR(data));
}

/* add the specified reading to the table */
char TOS_COMMAND(ACCESS_BYTE)(char mode, int sid, int key, short value) {
  if (VAR(mode) != kIDLE_MODE) return 0; //failure
  VAR(mode) = mode;
  //the line to write
  VAR(line) = ((key >> (4 -1))&0x1FF) + VAR(starts)[sid]; //ick! 4-1 = log_2(kEEPROM_BLOCK_SIZE/kBYTES_PER_ENTRY) 
  //the offset into the line to put data at
  VAR(offset) = (key & 0x07) << 1;  //* 2 for kBYTES_PER_ENTRY
  //the data to put, in write mode
  VAR(value) = value;
  // fprintf (stderr, "writing %d to offset %d of line %d\n", value, VAR(offset), VAR(line));

  //even in write mode, we begin by reading old data
  return TOS_CALL_COMMAND(CALIB_EEPROM_READ)(VAR(line), VAR(data));
}

/* perform interpolation between the current calibration readings and
   non installed readings.
   may require substantial time to complete as it must write
   out the entire calibration table to eeprom
*/	
char TOS_COMMAND(INTERPOLATE)(int sid) {
  if (VAR(mode) != kIDLE_MODE) return 0; //failure
  VAR(mode) = kINTERP_MODE;
  VAR(line) = VAR(starts)[sid];
  VAR(last_line) = VAR(line) + NUM_LINES(VAR(bits)[sid]);
  //  fprintf (stderr, "Interpolating from %d to %d\n", VAR(line), VAR(last_line));

  //the last data reading
  VAR(value) = 0;
  VAR(lastvalueline) = -1;
  VAR(distance) = 0;
  VAR(nextvalue) = 0;
  VAR(lastvalue) = 0;
  VAR(jump_back) = 0;

  return TOS_CALL_COMMAND(CALIB_EEPROM_READ)(VAR(line), VAR(data));
}


/*
  handler which is called when EEPROM write is finished
  when write is done, depending on the command do:
  if zero:  write zero to the next row of data
  if interp: read the next row of data, interpolate it
  if write: return
 */
char TOS_EVENT(WRITE_DONE)(char success) {
    if (VAR(write_delay) < 0) {
	VAR(write_delay) = 2;
	return 1;
    }
    VAR(write_delay) = -1;

  TOS_CALL_COMMAND(CALIB_RED_LED)();

  //if (!success) {
  //  return TOS_CALL_COMMAND(CALIB_EEPROM_WRITE)(VAR(line), VAR(data));
  //} else
  {
    switch (VAR(mode)) {
    case kINTERP_MODE:
      //read next block from EEPROM, do interpolation on it, write again
      if (!VAR(jump_back))
	VAR(line) ++;
      else VAR(line) = VAR(lastvalueline);
      
      if (VAR(line) < VAR(last_line)) {
	TOS_CALL_COMMAND(CALIB_EEPROM_READ)(VAR(line), VAR(data));
      } else {
	VAR(mode) = kIDLE_MODE;  //all done
	TOS_SIGNAL_EVENT(INTERP_DONE)();
      }
      break;
    case kZERO_MODE:
      //write the next line of zeros to the eeprom
      VAR(line) ++;
      if (VAR(line) < VAR(last_line)) {

	//fprintf(stderr, "zeroing %d\n", VAR(line));

	  //TOS_CALL_COMMAND(CALIB_GREEN_LED)();
	TOS_CALL_COMMAND(CALIB_EEPROM_WRITE)(VAR(line), VAR(data));
      } else {
	VAR(mode) = kIDLE_MODE; //all done
	TOS_SIGNAL_EVENT(ZERO_DONE)();
      }
      break;
    case kWRITE_MODE:
      VAR(mode) = kIDLE_MODE;  //just one line to write, all done
      TOS_SIGNAL_EVENT(ADD_DONE)();
      break;
    }
  }
  return 1;
}

/* handler which is called when EEPROM read is finished
   depending on mode, do:
   read: return data to user
   write: set appropriate bytes in line, write them out
   interp: interpolate the data, write it out
*/
char TOS_EVENT(READ_DONE)(char *data, char success) {
  //if (!success)
  //  return TOS_CALL_COMMAND(CALIB_EEPROM_READ)(VAR(line), VAR(data));

  if (VAR(mode) == kREAD_MODE) {
    VAR(mode) = kIDLE_MODE;
    TOS_SIGNAL_EVENT(LOOKUP_DONE)(*(short *)(&data[VAR(offset)]));
  } else if (VAR(mode) == kINTERP_MODE) {
    //interpolate and write out data
    interp_data();
    return TOS_CALL_COMMAND(CALIB_EEPROM_WRITE)(VAR(line), VAR(data));    
  } else { //assume mode = kWRITE_MODE
    //set the appropriate 2 bytes for value and write out data
    *(short *)(&VAR(data)[VAR(offset)]) = VAR(value);
    return TOS_CALL_COMMAND(CALIB_EEPROM_WRITE)(VAR(line), VAR(data));        
  }
  return 1;
}

//send a return result back to the user
 char TOS_EVENT(SEND_READING)(short data) {
   CalibrationMsg *msg = (CalibrationMsg*)(VAR(msg).data);
   
   TOS_CALL_COMMAND(CALIB_YELLOW_LED)();
   if (!VAR(pending)) {
     msg->sid = TOS_LOCAL_ADDRESS;
     msg->type = CALIB_MSG_REPLY_TYPE;
     msg->data = data;
     msg->line = VAR(line);
     msg->offset = VAR(offset);
     if (TOS_COMMAND(CALIB_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(CALIBRATION_REQUEST), &VAR(msg))) {
       VAR(pending) = 1;
       return 1;
     }
   }
   return 0;
 }

//acknowledge that the last command completed
 char TOS_EVENT(SEND_ACK)() {
   return TOS_SIGNAL_EVENT(SEND_READING)(0);
 }

/* handler for the CALIBRATION_REQUEST command
   checks msg->type, dispatches accordingly
   see system/inclue/CALIBRATION_MSG.h for the CalibrationMsg data structure
*/
TOS_MsgPtr TOS_MSG_EVENT(CALIBRATION_REQUEST)(TOS_MsgPtr msgptr) {
  CalibrationMsg* msg = (CalibrationMsg *)msgptr->data;
  //  TOS_CALL_COMMAND(CALIB_GREEN_LED)();
  switch (msg->type) {
  case (CALIB_MSG_ADD_TYPE):
    TOS_CALL_COMMAND(ACCESS_BYTE)(kWRITE_MODE,msg->sid, msg->reading, msg->data);
     break;
   case (CALIB_MSG_LOOKUP_TYPE):
     TOS_CALL_COMMAND(ACCESS_BYTE)(kREAD_MODE,msg->sid, msg->reading, 0);
     break;
   case (CALIB_MSG_INTERP_TYPE):
     TOS_CALL_COMMAND(INTERPOLATE)(msg->sid);
     break;
   case (CALIB_MSG_ZERO_TYPE): 
     TOS_CALL_COMMAND(ZERO_DATA)(msg->sid);
     break;
   }
   return msgptr;
 }

 char TOS_EVENT(CALIB_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg) {
   if (VAR(pending) && msg == &VAR(msg))
     VAR(pending) = 0;
   return 1;
 }


/* 
   interpolate a row of data.  since interpolation may occur
   across two rows of data, we may have to read in a previous
   after we've determined the range we're interpolating across.

   uses the following variables:

   lastvalue = last nonzero entry
   nextvalue = next nonzero entry
   distance = number of zero entries between lastvalue and nextvalue
   lastvalueline = line number where lastvalue occurred
   jump_back = indicates that the next line to read should be lastvalueline, rather 
               than line+1
   
   idea:
   scan forward, looking for first nonzero entry
   set lastvalue. lastvalueline
   continue forward scan, incrementing distance, looking for next nonzero entry
   set nextvalue, jump back to lastvalueline
*/
void interp_data() {
    short *p = (short *)VAR(data); //illegal?
    register char i;

    for (i = 0; i < (kEEPROM_BLOCK_SIZE / kBYTES_PER_ENTRY); i++) {
	register short val = *p;


	if (val == 0) { //need to interpolate
	    if (VAR(jump_back)) {
		p++;
		continue; //we jumped here, but haven't found nonzero value yet
	    }
	    if (VAR(nextvalue != 0)) { //have an interpolation value
		//interpolate
		p[0] = VAR(lastvalue) + 
		    ((VAR(nextvalue) - VAR(lastvalue))*(VAR(total_distance) - VAR(distance)))/VAR(total_distance); 
		VAR(distance) --;
		if (VAR(distance) == 0) {
		    VAR(lastvalue) = p[0];
		    VAR(lastvalueline) = VAR(line); 
		    VAR(nextvalue) = 0;
		}
	    } else if (VAR(lastvalue) != 0) { 
		//can't interpolate, since next value unknown,
		//so track distance since last value was seen
		VAR(distance)++; 
	    }
	} else { //val must be nonzero
	    //don't start interpolating until we find the first non-zero byte
	    //when we've jumped back
	    if (VAR(jump_back)) {  
		//on first interpolated value, save total distance
		VAR(total_distance) = VAR(distance) + 1;
		VAR(jump_back) = 0;
		p++;
		continue;
	    }
	    if (VAR(lastvalue) == 0) { //first value ever seen -- set lastvalue
		VAR(lastvalue) = val;
		VAR(lastvalueline) = VAR(line); 
	    }
	    else if (VAR(nextvalue == 0)) { //no next value yet
		VAR(nextvalue) = val;
		if (VAR(distance) > 0) {  //some back interpolation to do
		    //reread from lastvalueline
		    VAR(jump_back) = 1;
		    return;
		} else {
		    VAR(lastvalueline) = VAR(line); 
		    VAR(lastvalue) = VAR(nextvalue);
		    VAR(nextvalue) = 0;
		}
	    } //if we have both a next and a last value, that's weird
	}
	p++;
    }

}

//compute a power of 2
short pow2(short exp) {
  short result = 2;
  if (exp <= 0) return 1;
  return (result << (exp - 1));
}
