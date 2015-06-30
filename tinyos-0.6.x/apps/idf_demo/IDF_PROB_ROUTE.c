/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
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
 * $Log: IDF_PROB_ROUTE.c,v $
 * Revision 1.1.1.1  2001/09/26 21:55:13  szewczyk
 *
 *
 * Revision 1.10  2001/08/14 23:22:28  gdeepak
 * Changed parameters for accepting new packet
 *
 * Revision 1.9  2001/08/14 21:13:30  alecwoo
 * Use exp_id as seq number rather than using VAR(set) as timeout for route.
 *
 * Revision 1.8  2001/08/14 06:49:50  alecwoo
 * Put define MODE_LEVEL back to this file.
 *
 * Revision 1.7  2001/08/14 06:39:44  alecwoo
 * Fix a pointer bug in mode calculation and remove some initialization
 * of variables to save program space.
 *
 * Revision 1.6  2001/08/14 05:30:19  alecwoo
 * Fix the mode estiation code.
 *
 * Revision 1.5  2001/08/14 04:07:25  alecwoo
 * Added in the ability to set whether mode should be used for level estimation.
 *
 * Revision 1.4  2001/08/14 02:03:26  alecwoo
 * Remove turning on the Yellow LED during wave.
 *
 * Revision 1.3  2001/08/14 01:16:41  alecwoo
 * Integrate with POT component.
 * Add in the function to tune MAXLEVEL and MOTE_REFRESH_RATE.
 * Add in an experimental function to change the random delay used
 * at the MAC layer.
 *
 * Revision 1.2  2001/08/13 19:33:30  alecwoo
 * Update with the latest PROB_ROUTE.c
 *
 * Revision 1.1  2001/08/12 00:49:15  gdeepak
 * Separated out the IDF Demo version of files.
 *
 *
 */

 
/* This component discovers the network and handles BS command for blinking the GREEN LED as a 
   wave depending on deep a node is in the network, turning YELLOW LED on and off, and 
   changing the pot settings on the Radio. */  

#include "tos.h"
#include "IDF_PROB_ROUTE.h"

#define MODE_LEVEL
extern short TOS_LOCAL_ADDRESS;  // This is the ID of the mote retrieved from the EEPROM

//Deepak added to integrate with WAKEUP.c 
//in probrouter_light_wakeup.desc
#define AM_MSG_PROB_ROUTE_UPDATE 8 

#define MOTE_REFRESH_RATE 16 // Default value: this means 2 second with a tick8ps

// Meaning of commands
#define COMMAND_LED_ON            1
#define COMMAND_LED_OFF           2
#define COMMAND_BLINK_WAVE        3

// Maximum network depth constant
#define MAXLEVEL                  20
// History size for mode calculation
#define HISTORYSIZE               5

// This variable is only used for exprimental purposes
unsigned short macRandomDelay; // set the MAC random delay value

// Route Message Structure
typedef struct {
    short src;        // source of the message
    char hop_count;   // hop count of the source
    unsigned char exp_id;      // experiment id (for logging purposes in the future)
    short prob;       // probability of forwarding (not used)
    char potSetting;  // pot setting on the radio
    char command;     // command from the BS
    char LEDduration; // duration to turn on the GREEN LED for wave demo
    char LEDdelay;    // delay parameter to control when to turn on the GREEN LED for wave demo
    char waveDir;     // direction of the wave demo (backward or forward)
    unsigned char setRefreshRate;  // set the route refresh rate
    unsigned char maxLevel;        // maximum level of the tree
    unsigned short macRandomDelay; // set the MAC random delay value
    unsigned char historySize;     // set the history size
}routemsg_t;

// Frame of the component
#define TOS_FRAME_TYPE PROB_ROUTE_obj_frame
TOS_FRAME_BEGIN(PROB_ROUTE_obj_frame) {
    TOS_Msg route_buf;	   // route message buffer
    TOS_Msg data_buf;	   // data message buffer
    TOS_MsgPtr msg;          // message ptr
    char data_send_pending;  // flag to see if data buffer is sending
    char route_send_pending; // flag to see if route buffer is sending
#ifdef PROB_ROUTE
    unsigned short prob;     // forward probability
#endif //PROB_ROUTE
    unsigned char expid;       // discovery seq no
    short route;             // this is my route
    char potSetting;         // this is pot setting
    unsigned short counter;  // counter for delaying the GREEN led wave
    unsigned short duration; // counter for controlling GREEN led turn on time
    unsigned char direction; // flag for wave direction
    unsigned char level;     // this is my level in the tree
    char wave;               // internal flag to signal wave is going on
    unsigned char maxLevel;        // maximum level of the tree
#ifdef MODE_LEVEL
    unsigned char mode[MAXLEVEL];  // array to store the history for mode calculation
    unsigned char window;          // window size of the mode history
    unsigned char historySize;     // history for mode calculation
    unsigned char list[MAXLEVEL];  // list to store message order for mode cal.
#endif //MODE_LEVEL
}
TOS_FRAME_END(PROB_ROUTE_obj_frame);


char TOS_COMMAND(PROB_ROUTE_INIT)(){
    //initialize sub components
    TOS_CALL_COMMAND(PROB_ROUTE_SUB_INIT)();
    
    // Initialize settings
    VAR(msg) = &VAR(route_buf);
    //VAR(data_send_pending) = 0;
    VAR(route_send_pending) = 0;
    VAR(potSetting) = 72;
    VAR(expid)=0;
    VAR(route) = 0;
    VAR(maxLevel) = MAXLEVEL;
    VAR(historySize) = HISTORYSIZE;
    //macRandomDelay = 0x7ff;
    //set rate for clock
    TOS_CALL_COMMAND(PROB_ROUTE_SUB_CLOCK_INIT)(tick8ps);
    
    return 1;
}

char TOS_COMMAND(PROB_ROUTE_START)(){
    return 1;
}

// Handler for the discovery message.
// Command interpretation will be move up to one component later.
TOS_MsgPtr TOS_MSG_EVENT(PROB_ROUTE_UPDATE)(TOS_MsgPtr msg){
    routemsg_t * rmsg = (routemsg_t *) msg->data;
    TOS_MsgPtr tmp;
    int i;   
    unsigned char max=0;
    unsigned char *a;
    unsigned char maxModeLevel,b;


    // If my route expires
    if (((unsigned char)(VAR(expid) - (rmsg->exp_id))) > 4) {
	VAR(expid) = rmsg->exp_id;	   

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
		VAR(wave) = 1;
	    }else{
		CLR_YELLOW_LED_PIN();
	    }
	    break;
	default:
	    break;
	}

	// set my route and hop count
	VAR(route) = rmsg->src;
	VAR(level) = ++(rmsg->hop_count);     

	// set my new expected max level
	VAR(maxLevel) = (rmsg->maxLevel);

	/* Experimental use only:
	   Set the mac layer random delay value
	*/
	macRandomDelay = (rmsg->macRandomDelay);

	// set up forward message
	rmsg->src = TOS_LOCAL_ADDRESS;   

	// limit a node's level by MAXLEVEL
	if (VAR(level) >= VAR(maxLevel)-1){
	    VAR(level) = VAR(maxLevel)-1;
	}     

#ifdef MODE_LEVEL      
	// This is to calculate mode of the hop_count of the node
	VAR(list)[(int)VAR(window)] = VAR(level);      	
	VAR(mode)[(int)VAR(level)]++;

	for (i = 0; i < MAXLEVEL; i++){
	    b = VAR(mode)[i];
	    if (b > max){
		// find the mode
		max = b;
		maxModeLevel = i;
	    }
	    if (VAR(historySize) != (rmsg->historySize)){
		// restart the mode calculation
		//VAR(window) = 0;
		VAR(mode)[i] = 0;
		VAR(list)[i] = 0;
	    }
	}
	
	// increment the window circular index
	if (VAR(window) < VAR(historySize) - 1){
	    VAR(window)++;
	}else {
	    VAR(window) = 0;
	}

	// throw away the oldest one
	a = (unsigned char *)&VAR(mode)[VAR(list)[(int)VAR(window)]];
	if ((*a)> 0){
	    (*a)--;
	}
	
	// use the new history size
	VAR(historySize) = (rmsg->historySize);
	
	// Level is the mode
	VAR(level) = maxModeLevel;
#endif

	// process incoming blink command settings for the wave demo
	if (VAR(wave) == 1){
	    VAR(wave) = 2;
	    VAR(direction) = rmsg->waveDir;
	    if (VAR(direction) == 0){
		/* forward direction:
		   delay = b*level */
		VAR(counter) = (unsigned short) (rmsg->LEDdelay) * (unsigned short) VAR(level);
	    }else{
		/* reverse direction:
		   delay = (maxlevel-level)*b */
		VAR(counter)= (unsigned short) (rmsg->LEDdelay) * (unsigned short) (VAR(maxLevel) - VAR(level));
	    }
	    // duration = ab
	    VAR(duration) = rmsg->LEDduration;
	}
	
#ifdef PROB_ROUTE
	//set the new probability
	VAR(prob) = rmsg->prob;
	if (VAR(prob) >= (unsigned short) TOS_CALL_COMMAND(PROB_ROUTE_NEXT_RAND)()){
#endif	
	    // Set the pot
	    if (rmsg->potSetting != VAR(potSetting)){
		VAR(potSetting) = rmsg->potSetting;
		TOS_CALL_COMMAND(PROB_ROUTE_SET_POT)(VAR(potSetting));
	    }
		
	    // Start sending
	    if (VAR(route_send_pending) == 0){
		VAR(route_send_pending) = TOS_CALL_COMMAND(PROB_ROUTE_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(PROB_ROUTE_UPDATE),msg);
		tmp = VAR(msg);
		VAR(msg) = msg;
		return tmp;
	    }
	}// VAR(set == 0)
      
#ifdef PROB_ROUTE
    }
#endif
    
    return msg;
}

void TOS_EVENT(PROB_ROUTE_SUB_CLOCK)(){
    
    /* If wave is started, start counting delay,
       once delay reaches 0, turns on GREEN LED for the wave
       and turn off Yellow LED.  Once duration reaches 0, 
       GREEN LED will be off.
    */
    if (VAR(wave) == 2){
	if (VAR(counter) != 0){
	    VAR(counter)--;
	    if (VAR(counter) == 0){
		SET_YELLOW_LED_PIN();
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
 
}

//Event: finish sending a message.
char TOS_EVENT(PROB_ROUTE_SEND_DONE)(TOS_MsgPtr data){
    if(data == VAR(msg)) VAR(route_send_pending) = 0;
    if(data == &VAR(data_buf)) {
	VAR(data_send_pending) = 0;
    }
    return 1;
}
