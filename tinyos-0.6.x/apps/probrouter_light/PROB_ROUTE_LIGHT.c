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
 * Authors:		Alec Woo
 *
 *
 * $Log: PROB_ROUTE_LIGHT.c,v $
 * Revision 1.1.1.1  2001/09/26 21:55:14  szewczyk
 *
 *
 * Revision 1.15  2001/08/13 18:25:45  gdeepak
 * Added Logging stuff. Corresponding description file for logging
 * is probrouter_light_uart.desc
 *
 * Revision 1.14  2001/08/12 05:50:32  alecwoo
 * Fix MAXLEVEL to have 20 hop counts.
 *
 * Revision 1.13  2001/08/12 05:36:01  alecwoo
 * Clean up code and use 8 ticks per second.
 *
 * Revision 1.12  2001/08/11 02:41:54  alecwoo
 * Enhance with MODE level calculation.
 *
 * Revision 1.11  2001/08/11 01:34:28  alecwoo
 * Fix the LED Blink Wave.
 *
 */


/* This component discovers the network and handles BS command for blinking GREEN LED depending 
   on the level of the network, turning YELLOW LED on and off, and changing the RF transmission 
   pot settings. */

#include "tos.h"
#include "PROB_ROUTE_LIGHT.h"

extern short TOS_LOCAL_ADDRESS;

//Deepak added to integrate with WAKEUP.c 
//in probrouter_light_wakeup.desc
#define AM_MSG_PROB_ROUTE_UPDATE 8 

#define MOTE_REFRESH_RATE 16 // 2 second with a tick8ps

// Meaning of commands
#define COMMAND_LED_ON            1
#define COMMAND_LED_OFF           2
#define COMMAND_BLINK_WAVE        3

#define MAXLEVEL                  10
#define HISTORYSIZE               5

// Network depth constant
#define MAXLEVEL                  20
// History size for mode calculation
#define HISTORYSIZE               10

/* Deepak added
   Define for Logging only.
*/
#undef LOGGING
//#define LOGGING

// Route Message Structure
typedef struct {
  short src;
  char hop_count;
  char exp_id;
  short prob;
  char potSetting;
  char command;
  char LEDduration;
  char LEDdelay;
  char waveDir;
}routemsg_t;


/* Temporary added until POT.c is finalized */
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
#ifdef PROB_ROUTE
	unsigned short prob;
#endif //PROB_ROUTE
	char set;
	short route;
	char potSetting;
	unsigned short counter;
	unsigned short duration;
	unsigned char direction;
	unsigned char led_state;
	unsigned char level;
	char wave; 
#ifdef MODE_LEVEL
	unsigned char mode[MAXLEVEL];
	unsigned char window;
#endif //MODE_LEVEL

#ifdef LOGGING
	// For logging only
	char log_buf[16];
	char log_buf_index;
	char log_pending;
#endif //LOGGING
}
TOS_FRAME_END(PROB_ROUTE_obj_frame);


char TOS_COMMAND(PROB_ROUTE_INIT)(){
  int i;
   //initialize sub components
   TOS_CALL_COMMAND(PROB_ROUTE_SUB_INIT)();
   VAR(msg) = &VAR(route_buf);
   VAR(data_send_pending) = 0;
   VAR(route_send_pending) = 0;

   // Initialize settings
   VAR(potSetting) = 72;
   set_pot(VAR(potSetting));
   VAR(set)=0;
   VAR(route) = 0;
   //Heartbeat counter
   VAR(led_state) = 0;
   // Initialize RED Led for heartbeat
   CLR_RED_LED_PIN();

#ifdef LOGGING
   //Logging initialization
   VAR(log_buf_index) = 0;
   VAR(log_pending) = 0;
#endif //LOGGING

   //set rate for clock
   TOS_CALL_COMMAND(PROB_ROUTE_SUB_CLOCK_INIT)(tick8ps);

   return 1;
}

char TOS_COMMAND(PROB_ROUTE_START)(){
  return 1;
}


TOS_MsgPtr TOS_MSG_EVENT(PROB_ROUTE_UPDATE)(TOS_MsgPtr msg){
    routemsg_t * rmsg = (routemsg_t *) msg->data;
    TOS_MsgPtr tmp;
    unsigned short prob;
    int i;   
    unsigned char max=0;

    tmp = msg; //Set tmp to msg initially

#ifdef LOGGING
  // Add pkt info to log_buf
  if (VAR(log_buf_index) < 15) {
    VAR(log_buf)[VAR(log_buf_index)] = (char)(rmsg->src >> 8);
    VAR(log_buf)[VAR(log_buf_index)+1] = (char)(rmsg->src);
    VAR(log_buf)[VAR(log_buf_index)+2] = rmsg->hop_count;
    VAR(log_buf)[VAR(log_buf_index)+3] = rmsg->exp_id;
    VAR(log_buf_index) = VAR(log_buf_index)+4;
  }
#endif

  // If my route expires
  if (VAR(set) == 0){
    
    // Process incoming commands
    switch(rmsg->command){
    case COMMAND_LED_ON:
      CLR_YELLOW_LED_PIN();
      break;
    case COMMAND_LED_OFF:
      SET_YELLOW_LED_PIN();
      break;
    case COMMAND_BLINK_WAVE:
      if (VAR(wave) == 0){
	CLR_YELLOW_LED_PIN();	
	VAR(wave) = 1;
      }
      break;
    default:
      break;
    }
    
    // set my route and hop count
    VAR(route) = rmsg->src;
    VAR(level) = ++(rmsg->hop_count);     
    
    // Refresh my route time constant
    VAR(set) = MOTE_REFRESH_RATE;  
    
    // set up forward message
    rmsg->src = TOS_LOCAL_ADDRESS;   
    
    // limit a node's level
    if (VAR(level) >= MAXLEVEL-1){
      VAR(level) = MAXLEVEL-1;
    }
    
#ifdef MODE_LEVEL      
    if (VAR(window) < HISTORYSIZE)
      VAR(window)++;
    
    VAR(mode)[(int)VAR(level)]++;
    for (i = 0; i < MAXLEVEL; i++){
      if (VAR(mode)[i] > max){
	max = i;
      }
      if (VAR(window) > HISTORYSIZE && VAR(mode)[i] > 0){
	VAR(mode)[i]--;
      }
    }
    VAR(level) = max;
#endif
    
    // process incoming blink command settings
    if (VAR(wave) == 1){
      VAR(wave) = 2;
      VAR(direction) = rmsg->waveDir;
      if (VAR(direction) == 0){
	// delay = b*level
	VAR(counter) = (unsigned short) (rmsg->LEDdelay) * (unsigned short) VAR(level);
      }else{
	// reverse:
	// delay = (maxlevel-level)*b
	// fix this MAXLEVEL..
	VAR(counter) = (unsigned short) (rmsg->LEDdelay) * (unsigned short) (MAXLEVEL - VAR(level));
      }
      // duration = ab
      VAR(duration) = rmsg->LEDduration;
    }
    
#ifdef PROB_ROUTE
    // Does it has the new probability? If so, set it.
    VAR(prob) = rmsg->prob;
    if (VAR(prob) >= (unsigned short) TOS_CALL_COMMAND(PROB_ROUTE_NEXT_RAND)()){
#endif	
      // Set the pot
      if (rmsg->potSetting != VAR(potSetting)){
	VAR(potSetting) = rmsg->potSetting;
	set_pot(VAR(potSetting));
      }
      
      // Start sending
      if (VAR(route_send_pending) == 0){
	VAR(route_send_pending) = TOS_CALL_COMMAND(PROB_ROUTE_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(PROB_ROUTE_UPDATE),msg);
	tmp = VAR(msg);
	VAR(msg) = msg;
	//	return tmp;
      }
    }
    
#ifdef PROB_ROUTE
  }
#endif
  
#ifdef LOGGING
  //For logging only:
  //If buffer filled up, write out to EEPROM
  if (VAR(log_buf_index)==16) {
    TOS_CALL_COMMAND(PROB_ROUTE_SUB_APPEND_LOG)((char *)&VAR(log_buf)[0]);
  }
#endif  

  return tmp;
}

void TOS_EVENT(PROB_ROUTE_SUB_CLOCK)(){
  unsigned int tmp;
  
  // Heart Beat
  if ((++VAR(led_state))&0x8) SET_RED_LED_PIN();
  else CLR_RED_LED_PIN();
  
  // If wave is started, start counting delay
  // wave is turning on GREEN LED
  if (VAR(wave) == 2){
    if (VAR(counter) != 0){
      VAR(counter)--;
      if (VAR(counter) == 0){
	CLR_GREEN_LED_PIN();
      }
    }else{
      if (VAR(duration) != 0){
	VAR(duration)--;
	if (VAR(duration) == 0){
	  SET_GREEN_LED_PIN();
	  VAR(wave) = 0;
	}
      }
    }
  }
  
  // Decrement to refresh route
  if (VAR(set) != 0) {
    VAR(set)--;     
  }
 
}

char TOS_EVENT(PROB_ROUTE_SEND_DONE)(TOS_MsgPtr data){
  if(data == VAR(msg)) VAR(route_send_pending) = 0;
  if(data == &VAR(data_buf)) {
    VAR(data_send_pending) = 0;
  }
  return 1;
}

TOS_MsgPtr TOS_EVENT(PROB_ROUTE_LOG_REPORT)(TOS_MsgPtr msg){
  return msg;
}

#ifdef LOGGING
char TOS_EVENT(PROB_ROUTE_APPEND_LOG_DONE)(char success){
  VAR(log_buf_index) = 0;
  return 1;
}
#endif //LOGGING
