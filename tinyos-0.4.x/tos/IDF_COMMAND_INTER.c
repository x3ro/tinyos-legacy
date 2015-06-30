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
 * $Log: IDF_COMMAND_INTER.c,v $
 * Revision 1.16  2001/08/29 23:42:54  smadden
 * merge from IDF branch
 *
 * Revision 1.15.2.7  2001/08/24 10:32:27  alecwoo
 * Fix the blink_red_led problem.
 *
 * Revision 1.15.2.6  2001/08/22 21:29:57  alecwoo
 * Combine shutdown and proximity into the same mechanism in command
 * interpretation.
 * Add a field in going to proximity such that it can go forever.
 *
 * Revision 1.15.2.5  2001/08/22 21:18:44  jlhill
 * *** empty log message ***
 *
 * Revision 1.15.2.4  2001/08/22 20:02:02  alecwoo
 * Increase the delay for entering proximity.
 *
 * Revision 1.15.2.3  2001/08/22 06:41:26  alecwoo
 * Reset the internal flags for proximity and discoverLed.
 *
 * Revision 1.15.2.2  2001/08/22 06:38:11  alecwoo
 * Blink Yellow LED during Discover Phase.
 * Delay going into proximity mode to allow forwarding to occur.
 *
 * Revision 1.15.2.1  2001/08/21 21:12:58  gdeepak
 * changed to hook up RF_PROXIMITY
 *
 * Revision 1.15  2001/08/21 18:49:11  alecwoo
 * Define macRandomDelay in SEC_DED_RADIO_BYTE.c and extern it here.
 *
 * Revision 1.14  2001/08/21 06:32:58  alecwoo
 * When RED is turned on, it now only on for 25% duty cycle.
 *
 * Revision 1.13  2001/08/21 04:26:32  alecwoo
 * Make sure both LEDs won't be on at the same time.
 *
 * Revision 1.12  2001/08/21 01:37:55  gdeepak
 * Decouple 2 leds for dot
 *
 * Revision 1.11  2001/08/21 01:04:11  alecwoo
 * Fix the extreme case of maxLevel == myLevel
 *
 * Revision 1.10  2001/08/20 23:54:37  alecwoo
 * Minor change: add a (int) cast parathese.
 *
 * Revision 1.9  2001/08/20 23:46:33  alecwoo
 * Small change in masking the bits for extracting data from the packet.
 *
 * Revision 1.8  2001/08/20 23:35:38  alecwoo
 * Shrink the message payload to be 7 bytes.
 * Clean up the code.
 *
 * Revision 1.7  2001/08/20 08:46:14  alecwoo
 * Shrink the flood message size to deal with clock screw in the dot.
 *
 * Revision 1.6  2001/08/20 02:54:45  alecwoo
 * Remove unnecessary fields (probability and refresh rate).
 *
 * Revision 1.5  2001/08/18 00:23:38  alecwoo
 * Fixed depth of network (level) calculation such that maxlevel won't be
 * mistaken as maxlevel -1.
 *
 * Revision 1.4  2001/08/17 21:44:24  alecwoo
 * The level to be displayed in the wave demo
 * is only changed when you do a discovery command.
 *
 * Revision 1.3  2001/08/17 04:00:54  alecwoo
 * Change to use 32ticks/s and disable PROXIMITY for now.
 *
 * Revision 1.2  2001/08/17 02:01:21  alecwoo
 * Seperate level between flood and command_inter.
 *
 * Revision 1.1  2001/08/17 01:06:45  alecwoo
 * Sepearte Flodding component from command interpreter component.
 *
 *
 */

/* This component estimate the current level of the node and interpret BS command 
   in turing Yellow LED on/off and do the wave demo */

#include "tos.h"
#include "IDF_COMMAND_INTER.h"

#define MODE_LEVEL  // use MODE for level estimation

// Route Message Structure
typedef struct {
    unsigned char hop_count;   // hop count from the source (1 byte)
    unsigned char seqno;       // sequence number to distinguish old messages (1 byte)
    unsigned char potSetting;  // pot setting on the radio (1 byte)
    unsigned char command_historySize;   // command (3 bit) from the BS and history Size (5 bit) for mode calculation
    unsigned char LEDduration_LEDdelay;  // duration (4 bit) and delay (4 bit) to turn on the RED LED for wave demo
    unsigned char waveDir_Level;         /* direction of the wave demo (backward or forward) (1 bit),
                                            maximum level of the tree (7 bit) or
					    level to be turned on for the wave demo (7 bit)
					    if command == COMMAND_BLINK_LEVEL 
					 */
    unsigned char macRandomDelay;       // set the MSB of the MAC random delay value (8 bit)
}routemsg_t;

// Meaning of the commands
#define COMMAND_CLEAR_HISTORY     0
#define COMMAND_LED_ON            1
#define COMMAND_LED_OFF           2
#define COMMAND_BLINK_WAVE        3
#define COMMAND_DISCOVER          4
#define COMMAND_START_PROXIMITY   5
#define COMMAND_START_SHUTDOWN    6
#define COMMAND_BLINK_LEVEL       7


// Default maximum network depth constant
#define MAXLEVEL                  64
// Default history size for mode calculation
#define HISTORYSIZE               15
// With tick16ps
#define CLOCK_TICK_PER_HALF_SEC   8

// This variable is only used for exprimental purposes
// set the MAC random delay value in SEC_DED_RADIO_BYTE.c
extern unsigned short macRandomDelay; 

// Frame of the component
#define TOS_FRAME_TYPE IDF_COMMAND_INTER_obj_frame
TOS_FRAME_BEGIN(IDF_COMMAND_INTER_obj_frame) {
    char potSetting;          // this is pot setting
    unsigned short counter;   // counter for delaying the RED led wave
    unsigned short duration;  // counter for controlling RED led turn on time
    unsigned char  direction; // flag for wave direction
    unsigned char  myLevel;   // this is my level in the tree
    char wave;                // internal flag to signal wave is going on
    unsigned char maxLevel;   // remember the currnet setting of the maximum network depth
    unsigned char led_state;          // use to store state for blinking the LED
    unsigned char blinkRedLed;        // blink the LED
    unsigned char discoverLed;        // blink the yellow LED for discovery
    unsigned int  prox_shutdown_counter;  // internal counter to delay going into proximity mode
    unsigned char prox_shutdown_command;  // flag to distinguish shutdown or proximity
    unsigned char prox_mode;              // remeber the mode for proximity 
#ifdef MODE_LEVEL
    unsigned char mode[MAXLEVEL];  // array to store the history for mode calculation
    unsigned char window;          // window size of the mode history
    unsigned char historySize;     // history for mode calculation
    unsigned char list[MAXLEVEL];  // list to store message order for mode cal.
#endif //MODE_LEVEL
}
TOS_FRAME_END(IDF_COMMAND_INTER_obj_frame);


char TOS_COMMAND(IDF_COMMAND_INTER_INIT)(){
    //initialize sub components
    TOS_CALL_COMMAND(IDF_COMMAND_INTER_SUB_INIT)();
    
    // Initialize settings
    VAR(potSetting) = 70;
    VAR(historySize) = HISTORYSIZE;

    // Turn on RED LED when on
    CLR_RED_LED_PIN();

    //set rate for clock
    TOS_CALL_COMMAND(IDF_COMMAND_INTER_SUB_CLOCK_INIT)(tick16ps);
    
    return 1;
}

char TOS_COMMAND(IDF_COMMAND_INTER_START)(){
    return 1;
}


char TOS_EVENT(IDF_COMMAND_INTER_PROCESS_MSG)(TOS_MsgPtr msg){
    routemsg_t * rmsg = (routemsg_t *) msg->data;
    int i;   
    // variables used for MODE calculation
    unsigned char max=0;
    unsigned char *oldestModeSamplePtr;
    unsigned char tmp;
    // Extract information from the packet
    unsigned char level = (rmsg->hop_count);
    unsigned char command = (((rmsg->command_historySize) & 0xe0) >> 5) & 0x07;
    unsigned char historySize =  (rmsg->command_historySize) & 0x1f;
    unsigned short LEDdelay = ((rmsg->LEDduration_LEDdelay) & 0x0f);
    unsigned short LEDduration = (((rmsg->LEDduration_LEDdelay) & 0xf0 >> 4) & 0x0f);

    // Process incoming commands
    switch(command){
    case COMMAND_LED_ON:
	SET_RED_LED_PIN();
	CLR_YELLOW_LED_PIN();
	break;
    case COMMAND_LED_OFF:
	SET_RED_LED_PIN();
	SET_YELLOW_LED_PIN();
	break;
    case COMMAND_BLINK_WAVE:
	// Start the wave state
	if (VAR(wave) == 0){
	    VAR(wave) = 1;
	}
	break;
    case COMMAND_START_PROXIMITY:
    case COMMAND_START_SHUTDOWN:
	if (VAR(prox_shutdown_counter) == 0){
	    VAR(prox_shutdown_counter) = 1;
	    VAR(prox_shutdown_command) = command;
	    VAR(prox_mode) = ((rmsg->waveDir_Level) & 0x80) >> 7;
	}	  
	break;
    case COMMAND_BLINK_LEVEL:
	// Blink RED LED depends on which level you are
	if (((rmsg->waveDir_Level) & 0x7f) == VAR(myLevel)){
	    VAR(blinkRedLed) = 1;
	    SET_YELLOW_LED_PIN();
	}else{
	    VAR(blinkRedLed) = 0;
	    SET_RED_LED_PIN();
	    SET_YELLOW_LED_PIN();
	}
	break;
    default:
	break;
    }

    // Don't blink Red LED if there is other command
    if (VAR(blinkRedLed) != 0 && command != COMMAND_BLINK_LEVEL){
	VAR(blinkRedLed) = 0;
	SET_RED_LED_PIN();
    }

    // Set the pot if it's a new setting
    if ((rmsg->potSetting) != VAR(potSetting)){
	VAR(potSetting) = (rmsg->potSetting);
	TOS_CALL_COMMAND(IDF_COMMAND_INTER_SET_POT)(VAR(potSetting));
    }
    
    //  Set the mac layer random delay value   
    macRandomDelay |= ((((unsigned short)(rmsg->macRandomDelay)) << 8) & 0xff00);

    // limit a node's level by MAXLEVEL from the BS
    // before doing MODE calculation
    if (level >= MAXLEVEL-1){
	level = MAXLEVEL-1;
    }     

#ifdef MODE_LEVEL      
    // This is to calculate mode from the hop_count field of the incoming message

    // Collect the latest sample for mode calculation
    VAR(list)[(int)VAR(window)] = level;      	
    VAR(mode)[(int)level]++;
    
    // find the mode
    for (i = 0; i < MAXLEVEL; i++){
	tmp = VAR(mode)[i];
	if (tmp > max){
	    max = tmp;
	    level = i;
	}
	if ((VAR(historySize) != historySize) || command == COMMAND_CLEAR_HISTORY){
	    // restart the mode calculation
	    // if history size is renewed
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
    
    // throw away the oldest mode sample
    oldestModeSamplePtr = (unsigned char *)&(VAR(mode)[(int)(VAR(list)[(int)VAR(window)])]);
    if ((*oldestModeSamplePtr)> 0){
	(*oldestModeSamplePtr)--;
    }
    
    // Update to the new history size
    VAR(historySize) = historySize;
    
#endif // MODE_LEVEL
    
    // Update to the new maximum network depth
    if (command != COMMAND_BLINK_LEVEL){
	VAR(maxLevel) = (rmsg->waveDir_Level) & 0x7f;
    }
    
    // Limit the level to this new maximum network depth for display
    if (level > VAR(maxLevel)){
	level = VAR(maxLevel);
    }
    
    // Renew my latest level estimation only if I am discovering the network
    if (command == COMMAND_DISCOVER){
	VAR(myLevel) = level;
	// Turn on the Yellow LED to display discover phase
	VAR(discoverLed) = 1;
    }
    
    // process incoming blink command settings for the wave demo
    if (VAR(wave) == 1){
	VAR(wave) = 2;
	VAR(direction) = (rmsg->waveDir_Level) & 0x80;
	// Delay Calculation
	if (VAR(direction) == 0){
	    /* forward direction:
	       delay = b*level */
	    VAR(counter) = (unsigned short) LEDdelay * (unsigned short) VAR(myLevel) * CLOCK_TICK_PER_HALF_SEC;
	}else{
	    /* reverse direction:
	       delay = (maxlevel-level)*b */
	    VAR(counter)= (unsigned short) LEDdelay * (unsigned short) (VAR(maxLevel) - VAR(myLevel)) * CLOCK_TICK_PER_HALF_SEC;
	    // Special case if VAR(maxLevel) == VAR(myLevel)
	    if (VAR(counter) == 0){
		VAR(counter) = 1;
	    }
	}
	// update the new Duration setting
	VAR(duration) = (unsigned short) LEDduration * CLOCK_TICK_PER_HALF_SEC;
    }
    
    return 1;
}

void TOS_EVENT(IDF_COMMAND_INTER_SUB_CLOCK)(){

    /* If wave is started, start counting delay,
       once delay reaches 0, turns on RED LED for the wave
       Once duration reaches 0, RED LED will be off.
    */
    if (VAR(wave) == 2){
	if (VAR(counter) != 0){
	    VAR(counter)--;
	    if (VAR(counter) == 0){
		CLR_RED_LED_PIN();
		SET_YELLOW_LED_PIN();
	    }
	}else{
	    if (VAR(duration) != 0){
		VAR(duration)--;
		if (VAR(duration) == 0){
		    SET_RED_LED_PIN();
		    SET_YELLOW_LED_PIN();
		    VAR(wave) = 0;
		}
	    }
	}
    }

    /* For displaying the level,
       blink the LED to save energy */
    if (VAR(blinkRedLed) == 1){
	if (VAR(led_state) < 4){
	    CLR_RED_LED_PIN();
	    VAR(led_state)++;
	}else{
	    SET_RED_LED_PIN();
	    VAR(led_state) = 0;
	}
    }

    // For displaying the discover phase
    if (VAR(discoverLed) != 0){
	CLR_YELLOW_LED_PIN();
	SET_RED_LED_PIN();
	if (++VAR(discoverLed) > 2){
	    SET_YELLOW_LED_PIN();
	    SET_RED_LED_PIN();
	    VAR(discoverLed) = 0;
	}
    }

    // Go to proximity mode after 1 sec

    if (VAR(prox_shutdown_counter) != 0){
	if (++VAR(prox_shutdown_counter) > 160){
	    if (VAR(prox_shutdown_command) == COMMAND_START_PROXIMITY)
		TOS_CALL_COMMAND(IDF_COMMAND_INTER_SET_PROXIMITY)(VAR(prox_mode));
	    else if (VAR(prox_shutdown_command) == COMMAND_START_SHUTDOWN)
		TOS_CALL_COMMAND(IDF_COMMAND_INTER_GO_SHUTDOWN)();
	    VAR(prox_shutdown_counter) = 0;
	}
    }

}
