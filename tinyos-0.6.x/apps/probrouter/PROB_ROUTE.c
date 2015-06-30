/*									tab:4
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 * Authors:		Alec Woo
 *
 *
 */


//this components explores routing topology and then broadcasts back
// light readings.

#include "tos.h"
#include "PROB_ROUTE.h"

extern short TOS_LOCAL_ADDRESS;

#define MAX_NUM_NEIGHBORS 32
#define MOTE_REFRESH_RATE 32 // 64 seconds
#define BS_REFRESH_RATE 16  // 16 seconds

#define START_OF_LOG  1
#define END_OF_LOG   81
#define MAX_LINES 16384
#define BASELINE 16384

#define LOG_ENTRY_SIZE 16

#define COMMAND_LED_ON            1
#define COMMAND_LED_OFF           2

typedef struct {
  short src;
  char hop_count;
  char exp_id;
  short prob;
  char potSetting;
  char command;
}routemsg;

// Assume each log packet is 16 bytes long
typedef struct{
  char type;
  char exp_id;
  char totalExpRecv;
  char decision;
  short route;
  char level;
  short signal_strength;
  short my_id;
  char padding[19];
}logbuf_t;


#ifdef RENE
void decrease_r() {
    SET_UD_PIN();
    CLR_POT_SELECT_PIN();
    SET_INC_PIN();
    CLR_INC_PIN();
    SET_POT_SELECT_PIN();
}

void increase_r() {
    CLR_UD_PIN();
    CLR_POT_SELECT_PIN();
    SET_INC_PIN();
    CLR_INC_PIN();
    SET_POT_SELECT_PIN();
}


void set_pot(char value) {
    unsigned char i;
    for (i=0; i < 200; i++) {
        decrease_r();
    }
    for (i=0; i < value; i++) {
        increase_r();
    }
    SET_UD_PIN();
    SET_INC_PIN();
}
#endif



#define TOS_FRAME_TYPE PROB_ROUTE_obj_frame
TOS_FRAME_BEGIN(PROB_ROUTE_obj_frame) {
	TOS_Msg route_buf;	
	TOS_Msg data_buf;	
	TOS_MsgPtr msg;
	char data_send_pending;
	char route_send_pending;
	unsigned short prob;
	char set;
	short route;
	short neighbors[MAX_NUM_NEIGHBORS];
	char  hop_count[MAX_NUM_NEIGHBORS];
	logbuf_t logBuf;
	char logstep;
	char reportstep;
	char logCounter;
	char log_record[LOG_ENTRY_SIZE];
	char lastLogLine;
	char potSetting;
	char start_new_exp;
	int ll;
}
TOS_FRAME_END(PROB_ROUTE_obj_frame);


char TOS_COMMAND(PROB_ROUTE_INIT)(){
   //initialize sub components
   TOS_CALL_COMMAND(PROB_ROUTE_SUB_INIT)();
   VAR(msg) = &VAR(route_buf);
   VAR(data_send_pending) = 0;
   VAR(route_send_pending) = 0;
   ((routemsg *)&VAR(data_buf).data)->src = TOS_LOCAL_ADDRESS;   
   VAR(potSetting) = 50;
   set_pot(VAR(potSetting));
#ifndef BASE_STATION
   //set rate for sampling.
   TOS_CALL_COMMAND(PROB_ROUTE_SUB_CLOCK_INIT)(255,0x5);
   VAR(set)=0;
   VAR(route) = 0;
   VAR(logstep) = 0;
   VAR(reportstep) = 0;
   VAR(lastLogLine) = START_OF_LOG;
   VAR(logBuf).type = 0x88;
   VAR(logBuf).totalExpRecv = 0;

#else
   TOS_CALL_COMMAND(PROB_ROUTE_SUB_CLOCK_INIT)(255,0x5);
   VAR(set) = BS_REFRESH_RATE;
   VAR(route) = TOS_UART_ADDR;
   ((routemsg *)&VAR(data_buf).data)->src = TOS_LOCAL_ADDRESS;
   ((routemsg *)&VAR(data_buf.data))->hop_count = 1;
   ((routemsg *)&VAR(data_buf).data)->exp_id = 1;
   ((routemsg *)&VAR(data_buf).data)->prob = 65535;
#endif

   //clear LED3 when the clock ticks.
   TOS_CALL_COMMAND(PROB_ROUTE_LED3_OFF)();

   return 1;
}

char TOS_COMMAND(PROB_ROUTE_START)(){
  return 1;
}


char TOS_COMMAND(PROB_ROUTE_APPEND_LOG) (char *data) {
    int line;
    char ret;
    line = VAR(ll);
    if (line == MAX_LINES) {
	line = -1;
    } 
    line++; 
    ret = TOS_CALL_COMMAND(PROB_ROUTE_WRITE_LOG)((short)(BASELINE + line), data);
    if (ret)
	VAR(ll) = line;
    return ret;
}

TOS_MsgPtr TOS_MSG_EVENT(PROB_ROUTE_UPDATE)(TOS_MsgPtr msg){
    char* data = msg->data;
    TOS_MsgPtr tmp;
    unsigned short prob;
    int i;

#ifndef BASE_STATION


  // save data for logging later  
  VAR(logBuf).exp_id = ((routemsg *)data)->exp_id;  
  for (i=0; i < MAX_NUM_NEIGHBORS; i++){
    if (VAR(neighbors)[i] == 0 || VAR(neighbors)[i] == ((routemsg *)data)->src){
      VAR(neighbors)[i] = ((routemsg *)data)->src;
      VAR(hop_count)[i] = ((routemsg *)data)->hop_count;
      break;
    }	
  }

  if (((routemsg *)data)->command == COMMAND_LED_ON) {
    TOS_CALL_COMMAND(PROB_ROUTE_LED1_ON)();
  }
  else if (((routemsg *)data)->command == COMMAND_LED_OFF) {
    TOS_CALL_COMMAND(PROB_ROUTE_LED1_OFF)();
  }

  // Turn Green LED on whenever I hear a message
  TOS_CALL_COMMAND(PROB_ROUTE_LED2_ON)();

  // If I don't have a route,
  if (VAR(set) == 0){
    // set my route
    VAR(route) = ((routemsg *)data)->src;
    VAR(set) = MOTE_REFRESH_RATE;

    // save data for logging later
    VAR(logBuf).level = ++(((routemsg *)data)->hop_count);
    VAR(logBuf).route = VAR(route);
    VAR(logBuf).totalExpRecv++;
    VAR(logBuf).signal_strength = msg->strength;
    VAR(logBuf).my_id = TOS_LOCAL_ADDRESS;

    // Does it has the new probability? If so, set it.
    VAR(prob) = ((routemsg *)data)->prob;
    
    // Throw a coin for forwarding
    if (VAR(prob) >= (unsigned short) TOS_CALL_COMMAND(PROB_ROUTE_NEXT_RAND)()){

      // Set the pot
      if (((routemsg *)data)->potSetting != VAR(potSetting)){
	VAR(potSetting) = ((routemsg *)data)->potSetting;
	set_pot(VAR(potSetting));
      }

      // set up the broadcast message
      ((routemsg *)data)->src = TOS_LOCAL_ADDRESS;
      VAR(logBuf).decision = 1;      

      // Start sending
      if (VAR(route_send_pending) == 0){
	VAR(route_send_pending) = TOS_CALL_COMMAND(PROB_ROUTE_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(PROB_ROUTE_UPDATE),msg);
	tmp = VAR(msg);
	VAR(msg) = msg;

	// Turn Yellow LED on if I forward
	TOS_CALL_COMMAND(PROB_ROUTE_LED3_ON)();
	return tmp;
      }
    }
  }


#endif

  return msg;
}

void TOS_EVENT(PROB_ROUTE_SUB_CLOCK)(){
  unsigned int tmp;

  // Heart Beat
  TOS_CALL_COMMAND(PROB_ROUTE_LED1_TOGGLE)();

  // Decrement to refresh
  if (VAR(set) != 0) {
    VAR(set)--;

    if (VAR(set) == 0){
#ifndef BASE_STATION
      TOS_CALL_COMMAND(PROB_ROUTE_LED2_OFF)();
      TOS_CALL_COMMAND(PROB_ROUTE_LED3_OFF)();
      
      // Start logging
      VAR(logstep) = 1;
      TOS_CALL_COMMAND(PROB_ROUTE_APPEND_LOG)((char*) &VAR(logBuf)); 
      //TOS_CALL_COMMAND(PROB_ROUTE_LED2_ON)();
#else
      VAR(set) = BS_REFRESH_RATE;
      if (VAR(data_send_pending) == 0 && VAR(start_new_exp) == 1){
	VAR(data_send_pending) = TOS_CALL_COMMAND(PROB_ROUTE_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(PROB_ROUTE_UPDATE),&VAR(data_buf));
	VAR(start_new_exp) = 0;
	TOS_CALL_COMMAND(PROB_ROUTE_LED3_TOGGLE)();
      }    
#endif
    }
  }
}


char TOS_EVENT(PROB_ROUTE_APPEND_LOG_DONE)(char success){
  int i;

  if (VAR(logstep) == 1){
    TOS_CALL_COMMAND(PROB_ROUTE_APPEND_LOG)(&(((char*) VAR(neighbors))[0])); 
    VAR(logstep) = 2;
  } else if (VAR(logstep) == 2){
    TOS_CALL_COMMAND(PROB_ROUTE_APPEND_LOG)(&(((char*) VAR(neighbors))[16])); 
    VAR(logstep) = 3;
  } else if (VAR(logstep) == 3){
    TOS_CALL_COMMAND(PROB_ROUTE_APPEND_LOG)(&(((char*) VAR(neighbors))[32])); 
    VAR(logstep) = 4;
  } else if (VAR(logstep) == 4){
    TOS_CALL_COMMAND(PROB_ROUTE_APPEND_LOG)(&(((char*) VAR(neighbors))[48])); 
    VAR(logstep) = 5;
  } else if (VAR(logstep) == 5){
    TOS_CALL_COMMAND(PROB_ROUTE_APPEND_LOG)(&(((char*) VAR(hop_count))[0])); 
    VAR(logstep) = 6;
  } else if (VAR(logstep) == 6){
    TOS_CALL_COMMAND(PROB_ROUTE_APPEND_LOG)(&(((char*) VAR(hop_count))[16])); 
    VAR(logstep) = 7;
  }else{
    //TOS_CALL_COMMAND(PROB_ROUTE_LED2_OFF)();
    VAR(logstep) = 0;
    VAR(lastLogLine) = VAR(lastLogLine) + 7;
    
    // Reset to high power transmission
    set_pot(50);
    VAR(decision) = 0;

    // Reset neighbors and hop_count
    for (i=0; i< MAX_NUM_NEIGHBORS; i++){
      VAR(neighbors)[i] = 0;
      VAR(hop_count)[i] = 0;
    }

  }
  return 1;
}


char TOS_EVENT(PROB_ROUTE_READ_LOG_DONE)(char * record, char success){
#ifdef APP_EEPROM_REPORT
#ifndef BASE_STATION
  int i;

  if (VAR(reportstep) == 1){
    // Only report the first half of the data after reading the log
    for (i=0; i < LOG_ENTRY_SIZE; i++){
      VAR(data_buf).data[i] = record[i];
    }
    VAR(reportstep) = 2;
    VAR(logCounter)++;
    TOS_CALL_COMMAND(PROB_ROUTE_READ_LOG)((short)(VAR(logCounter)+BASELINE), (char *)&VAR(log_record)[0]);
  } else{
    for (i=0; i < LOG_ENTRY_SIZE-2; i++){
      VAR(data_buf).data[i+16] = record[i];
    }
    VAR(reportstep) = 1;
    VAR(logCounter)++;
    // Send the data
    if (VAR(data_send_pending) == 0){
      //TOS_CALL_COMMAND(PROB_ROUTE_LED2_OFF)();
      VAR(data_send_pending) = TOS_CALL_COMMAND(PROB_ROUTE_SUB_SEND_MSG)(TOS_BCAST_ADDR, 
			         AM_MSG(PROB_ROUTE_REPORTBACK), &VAR(data_buf));
    }
  }
#endif
#endif // APP_EEPROM_REPORT
  return 1;
}




TOS_MsgPtr TOS_EVENT(PROB_ROUTE_LOG_REPORT)(TOS_MsgPtr msg){
  char i;

#ifdef APP_EEPROM_REPORT
#ifndef BASE_STATION
  if (VAR(reportstep) == 0){
    set_pot(50);
    VAR(reportstep) = 1;
    VAR(logCounter) = START_OF_LOG;
    if (VAR(lastLogLine) == VAR(logCounter)){
      VAR(logCounter) = msg->data[0];
      VAR(lastLogLine) = msg->data[1];
    }
    TOS_CALL_COMMAND(PROB_ROUTE_LED2_ON)();
    TOS_CALL_COMMAND(PROB_ROUTE_READ_LOG)((short)(VAR(logCounter)+BASELINE), (char *)&VAR(log_record)[0]);
  }
#endif
#endif // APP_EEPROM_REPORT
  return msg;
}

TOS_MsgPtr TOS_EVENT(PROB_ROUTE_REPORTBACK)(TOS_MsgPtr msg){

  return msg;
}



TOS_MsgPtr TOS_MSG_EVENT(PROB_ROUTE_CONTROL_SETTINGS)(TOS_MsgPtr msg){
  char* data = msg->data;


#ifdef BASE_STATION
  ((routemsg *)&VAR(data_buf).data)->exp_id = data[0];
  ((routemsg *)&VAR(data_buf).data)->potSetting = data[1];
  ((routemsg *)&VAR(data_buf).data)->prob = *((short *)&data[2]);

  if (VAR(potSetting) != data[1]){
    VAR(potSetting) = data[1];
    set_pot(VAR(potSetting));    
  }
  
  VAR(start_new_exp) = 1;
#endif
  return msg;
}


char TOS_EVENT(PROB_ROUTE_SEND_DONE)(TOS_MsgPtr data){
  if(data == VAR(msg)) VAR(route_send_pending) = 0;
  if(data == &VAR(data_buf)) {
    VAR(data_send_pending) = 0;
#ifdef APP_EEPROM_REPORT
    if (VAR(reportstep) != 0){
      if (VAR(logCounter) < VAR(lastLogLine)){
	TOS_CALL_COMMAND(PROB_ROUTE_READ_LOG)((short)(VAR(logCounter)+BASELINE), (char *)&VAR(log_record)[0]);
      }else{
	TOS_CALL_COMMAND(PROB_ROUTE_LED2_OFF)();
	VAR(reportstep) = 0;
	set_pot(VAR(potSetting));
      }
    }
#endif
  }
  return 1;
}
