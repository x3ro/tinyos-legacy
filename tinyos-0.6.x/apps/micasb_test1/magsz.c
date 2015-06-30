/****************************************************************************
									tab:4
 * MAGSZ.c - v030702
 MAGSIMU	MAGNETOMETER MOTE SIMULATOR FOR RADIO TESTING
 SPECIAL HACK FOR RENEEs

 ENVIROMENT
 Compiler	avr-gcc		v2.97
 OS			TOS 		v0.051
 TARGET		ATM103
 HW			MICA Sensor Rev B 

SENSOR INFO
Number of Channels	2 (x,Y)
ADC Channel 		1,2	
Power Control		PW5		(mica) PW4 (RENE)

MAGNETOMETER SPECIFICATIONS 
---caution: these values are based on MICA SENSOR component values asof 02Feb02
SENSOR		Honeywell HMC1002
SENSITIVITY			3.2mv/Vex/gauss
EXCITATION			3.0V (nominal)
AMPLIFIER GAIN		2262
	Stage 1			29
	Stage 2			78	
ADC Input			22mV/mgauss
ADC Sensitivity		6.4cnts/mgauss
ADC Resolution		0.13mgauss/bit		
---------------------------------------------------------------------------
REVISION HISTORY
* Date:         Author:  Comments:
04feb02	mm	created from accel_rec and MAGS
12feb02	mm	Time over threshold before asserting message
19feb02 mm	Move in AXONN radio inteface
			Merge w/ PWA message building code
22feb02	mm	copied from magsy as baseline
07mar02	mm	tracking baseline code
*****************************************************************************/

#include "tos.h"
#include "dbg.h"
#include "sensorboard.h"
#include "MAGSZ.h"

#define	MAG_OFFSET_MIDSCALE     128
#define MAG_ADC_MIDSCALE	512
#define	MAG_ADC_ALMOSTMAX	700	   //only 50% fs range due to instrumentation amp rails
#define MAG_ADC_ALMOSTMIN	300

#define	I2C_IDLE                0		//I2C not busy
#define	I2C_POTX                1		//I2C Busy writing to Mag X pot
#define	I2C_POTY                2		//I2C Busy writing to Mag Y pot

//Data Acquisition modes/states
#define	DM_IDLE		0	        //nothing
#define	DM_AUTOZERO_START	1	//start autozeroing
#define	DM_AUTOZERO	2	        //autozero the magnetometers
#define	DM_NORMAL	4	        //standard daq
#define DM_STARTUP	5	        //startup holdoff

//Event Detection states
#define	EV_UNDER	0	//under threshold
#define	EV_OVER		1       //over threshold
#define	EV_IDLE	        0	//no signal detected
#define	EV_ADC 	        1	//ADC data over Amplitude threshold
#define EV_TIME	        2	//Data over Time and Amplitude threshold

#define BUFR_SHIFT_BITS 2
//NOTE: gcc doesn't process "#define BUFR_WSAMPLES (2 << BUFR_SHIFT_BITS)" properly
// so following define must be hand-entered for any change to BUFR_SHIFT_BITS
#define BUFR_WSAMPLES 4                 // history buffer size


//--- Magnetometer Thresholds	6.4 ADCCounts/milliGauss (0.13mgauss/bit)(nominal)
#define MAGX_THRESHOLD 10        //trigger threshold offset from quiescent baseline in adc counts)
#define MAGY_THRESHOLD 10        //trigger threshold offset from quiescent (in adc counts)
#define	TIME_OVER_MIN	3	 //time over threshold to qualify as an event (noise suppress)
#define TIME_UNDER_MIN	-3	 //time under threshold to qualify as event removed NOTE SIGN!!!
#define	TIME_OVER_MAX 120	 //over threshold for so long should establish a new baseline
#define	RE_ZERO_COUNT	30	 //#of samples in saturation requiring a re-zero of mag
#define	STARTUP_HOLDOFF 120	 // Clock ticks for startup to complete before autozeroing

#define BASELINE_COUNT  32       //# of BUFR_WSAMPLES-averaged data:beware of overflows
#define BASELINE_SHIFT_BITS 5    // must keep this value consistent with previous value

/*  Data stored for each sample reading */
typedef struct {
  short x_val;  
  short y_val;  
}magsz_data_struct;

typedef struct {
  int index;         // array address to which next sample will be stored
  int minCount;      // when count reaches BUFR_WSAMPLES, averaging can start
  int xsum;          // most-recent sum of x mag values
  int ysum;          // ditto for y
  int trgHoldoffCount;  //number of samples to delay after trigger before testing again
  magsz_data_struct adata[BUFR_WSAMPLES];   // 4 data points per eprom write => 16 bytes
}bufr_data_struct;

//local function declarations
void InitSampling(void);
 
/* Define the TOS Frame and variables it owns */
#define TOS_FRAME_TYPE MAGSZ_frame
TOS_FRAME_BEGIN(MAGSZ_frame) 
{
  TOS_Msg buffer1;           // double buffer
  TOS_Msg buffer2;           // double buffer
  TOS_MsgPtr msgPtr;         //temperature message buffer
  TOS_MsgPtr oldmsgPtr;      //accelerometer message buffer
  char msgIndex;            // index to the array
  char msg_pending;         // true if message pending
  char stepdown;            // scaling variable
  
  char samp_on;
  char DAQMode;		    //Data Aquisition state
  char EVState;		    //Event state

  char cMagXOffset;	    //Magnetometer offset
  char cMagYOffset;	    //Magnetometer offset
  char I2CBusy;	            //flag indicating offset POT is being written to
  int  cAZBit;		    //bit mask for Autozero operation
  int  iTimeinSaturation;   // #of sequentialsamples accumulated in saturation  
  int  iTimerThresholdCummulative;
  int  iTimerThreshold;	    //##of sequential over threshold -  
  int avgMagX;              //n-second base level average of magnetometer values, continuously updated
  int avgMagY;
  int avgMagXSum;	    //summed baseline - simplifies computation of moving average
  int avgMagYSum;

  int baselineCount;        // 16 4-sample averages are averaged to get baseline  
  bufr_data_struct bufr_data;   //stores magnetometer data for averaging for threshold detection
}
TOS_FRAME_END(MAGSZ_frame);


TOS_TASK(FILTER_DATA){

  int xsum, ysum;
  int i;
  char NextDAQMode;
  char NextEV; 
  
  // Default next DAQMode state is current state
  NextDAQMode = VAR(DAQMode);
  NextEV = VAR(EVState);	//default is to stay in current state
  
  //increment buffer array index
  VAR(bufr_data).index++;
  if (VAR(bufr_data).index >= BUFR_WSAMPLES)
    VAR(bufr_data).index = 0;
  
  //Test threshold
  
  //test whether the buffer has been filled at least once. 
  if(VAR(bufr_data).minCount < (BUFR_WSAMPLES-1)){
    //if not, increment buffer count
    VAR(bufr_data).minCount++;
  }else
    //if so, calculate averages and set led appropriately.
    {
      //calculate averages
      xsum = 0;
      ysum = 0;
      for(i=0;i<BUFR_WSAMPLES;i++)
	{
	  xsum += VAR(bufr_data).adata[i].x_val;
	  ysum += VAR(bufr_data).adata[i].y_val;
	}
      xsum = xsum >> BUFR_SHIFT_BITS;
      ysum = ysum >> BUFR_SHIFT_BITS;
      VAR(bufr_data).xsum = xsum;
      VAR(bufr_data).ysum = ysum;
      
      //either use data for baseline averaging or for threshold test
      if(VAR(baselineCount) < BASELINE_COUNT)
	{
	  if(VAR(baselineCount==0) )
	    {						  //initialize average
	      VAR(avgMagXSum) = 0;
	      VAR(avgMagYSum) = 0;
	    }
	  //when baselineCount reaches limit, perform 16x4 sample average
	  
	  VAR(baselineCount)++;
	  VAR(avgMagXSum) += xsum;
	  VAR(avgMagYSum) += ysum;
	  if(VAR(baselineCount) < BASELINE_COUNT)	{
	    VAR(bufr_data).minCount = 0;  //start next 4-sample average
	    //turn off all leds but 1 to keep PS offsets balanced
	    SET_RED_LED_PIN();
	    SET_YELLOW_LED_PIN();
	    CLR_GREEN_LED_PIN();       //LED ON  (RED LED on MICA)
	  }
	  else{
	    VAR(avgMagX) = VAR(avgMagXSum) >> BASELINE_SHIFT_BITS;
	    VAR(avgMagY) = VAR(avgMagYSum) >> BASELINE_SHIFT_BITS;
	    SET_GREEN_LED_PIN();       //LED OFF  (RED LED on MICA)
	  }
	}  // end baseline averaging
      else //------------------------ DAQMode states --------------------------------------
	{ 
	  // Have baseline data in avg vars - Handle DAQStates	  
	  switch( VAR(DAQMode) ) 
	    {
	      
	    case DM_AUTOZERO_START:{ 		 //--AUTOZERO_START
	      CLR_RED_LED_PIN();                                 //led on
	      VAR(cMagXOffset) = MAG_OFFSET_MIDSCALE;
	      VAR(cMagYOffset) = MAG_OFFSET_MIDSCALE;
	      VAR(cAZBit) = MAG_OFFSET_MIDSCALE;//set MSB	-!!NOTE:using int because no unsignedchar???
	      VAR(I2CBusy) = I2C_POTX;		  //I2C bus will be busy setting pot X
	      //CLR_RED_LED_PIN();                                 //led on
	      TOS_CALL_COMMAND(MAGSZ_SET_POT_X)(VAR(cMagXOffset));
			  	              // WRITE_DONE Event will initiate ADC baseline measurement 
	      NextDAQMode = DM_AUTOZERO;	 // change state
	    } //dmazstart
	    break; //azstart
	    
	    case DM_AUTOZERO:  //--AUTOZERO_OPERATION
	      if( VAR(I2CBusy) ){
		break;
	      }	 //no can do
	      // Evaluate ADC data
	      if( (xsum)<MAG_ADC_MIDSCALE) {	//Mag X Offset
		//clear previous bit in offset pot 
		VAR(cMagXOffset) = VAR(cMagXOffset) & ~VAR(cAZBit);
	      }
	      if( (ysum)<MAG_ADC_MIDSCALE) {	//Mag Y offset
		//clear previous bit in offset pot 
		VAR(cMagYOffset) = VAR(cMagYOffset) & ~VAR(cAZBit);
	      }
	      
	      VAR(cAZBit) = VAR(cAZBit)>>1;	// Set next bit in offset pots
	      
	      if( VAR(cAZBit)==0) {	// autozero operation finished
		VAR(baselineCount) = 0; 	//Establish a new base line for threshold detection
		NextDAQMode = DM_NORMAL;	//return to general data acquisition
		//CLR_GREEN_LED_PIN();
	      }  
	      else { //set next bit in offset pots and measure ADC response
		VAR(cMagXOffset) = VAR(cMagXOffset) | VAR(cAZBit);
		VAR(cMagYOffset) = VAR(cMagYOffset) | VAR(cAZBit);
		//set Offset and measure baseline data
		VAR(I2CBusy) = I2C_POTX;		  //I2C bus will be busy setting pot
		//CLR_RED_LED_PIN();                                 //led on
		TOS_CALL_COMMAND(MAGSZ_SET_POT_X)(VAR(cMagXOffset));
		// WRITE_DONE Event will initiate ADC baseline measurement  
	      } //if cAZBit
	      TOS_CALL_COMMAND(RED_LED_TOGGLE)();	//RED on MICA
	      //				CLR_YELLOW_LED_PIN();                                 //led on
	      break;//DM_AUTOZERO
	      
	    case DM_NORMAL:			//---DM_NORMAL
	      //SET_RED_LED_PIN();                                 //led on
	      //TOS_CALL_COMMAND(RED_LED_TOGGLE)();	//RED on MICA
	      
	      //Do NOT evaluate data if in trigger hold-off 
	      if(VAR(bufr_data).trgHoldoffCount > 0){
		VAR(bufr_data).trgHoldoffCount--;
		VAR(iTimerThreshold) = 0; //reset the count
		NextEV = EV_UNDER;	//clear the Event 
		VAR(bufr_data).minCount = 0;	//force buffer to flush during holdoff
		break;
	      }	// don't evaluate adc data during RF transmission & holdoff
	      
	      // Update moving average baseline
	      VAR(avgMagXSum) = xsum + VAR(avgMagXSum) - (VAR(avgMagXSum)>>BASELINE_SHIFT_BITS);
	      VAR(avgMagX) = VAR(avgMagXSum) >> BASELINE_SHIFT_BITS;
	      VAR(avgMagYSum) = ysum + VAR(avgMagYSum) - (VAR(avgMagYSum)>>BASELINE_SHIFT_BITS);
	      VAR(avgMagY) = VAR(avgMagYSum) >> BASELINE_SHIFT_BITS;
	      
	      //	state = EV_IDLE;
	      if((xsum > (VAR(avgMagX)+MAGX_THRESHOLD))
		 || (xsum < (VAR(avgMagX)-MAGX_THRESHOLD))) {
		VAR(iTimerThresholdCummulative)++;	
		VAR(iTimerThreshold)++;  //update time over
	      }
	      else if((ysum > (VAR(avgMagY)+MAGY_THRESHOLD))
		      || (ysum < (VAR(avgMagY)-MAGY_THRESHOLD))) {
		VAR(iTimerThresholdCummulative)++;	
		VAR(iTimerThreshold)++;  //update time over
	      }
	      //state = EV_ADC;
	      else {
		VAR(iTimerThreshold)--;
		VAR(iTimerThresholdCummulative)--;
	      }
	      
	      
	      if( VAR(iTimerThreshold) < TIME_UNDER_MIN-2)
		VAR(iTimerThreshold) = TIME_UNDER_MIN-2;	//dont let the counter underflow

	      if( VAR(iTimerThresholdCummulative) < 0)
		VAR(iTimerThresholdCummulative) = 0;	//dont let the counter underflow
	      
	      // Check if ADC is close to saturation
	      if( xsum>MAG_ADC_ALMOSTMAX 	|| xsum<MAG_ADC_ALMOSTMIN ||
		  ysum>MAG_ADC_ALMOSTMAX || ysum<MAG_ADC_ALMOSTMIN)
		VAR(iTimeinSaturation)++;
	      else
		VAR(iTimeinSaturation) = 0;	//clear count if drop out of saturation
	      
	      /*
	        State Machine for Event Detection
		Case(EVstate)
		EV_UNDER:	No event detected
		EV_OVER		An EVENT has been detected	
	      */

	      switch(VAR(EVState)) 
		{
		case EV_UNDER:	   			
		  SET_YELLOW_LED_PIN();       //LED off  (Yellow LED on MICA)
		  CLR_GREEN_LED_PIN();       //LED On  (Green LED on MICA)
		  if( VAR(iTimerThreshold) > TIME_OVER_MIN) {	   //Are we over the threshold yet?
		    VAR(iTimerThreshold) = 0;	//reset the count - it now reflects elapsed time over
		    NextEV = EV_OVER;	//trigger event
		  }
		  break;
		case EV_OVER:				
		  CLR_YELLOW_LED_PIN();       // led ON  (Yellow LED on MICA)
		  SET_GREEN_LED_PIN();       //LED Off  (Green LED on MICA)
		  if( VAR(iTimerThreshold)<TIME_UNDER_MIN) { //Are we still over the threshold ?
		    VAR(iTimerThreshold) = 0; //reset the count
		    //	VAR(iTimerThresholdCummulative) = 0;
		    NextEV = EV_UNDER;	//been under for awhile  
		  }
		  if( VAR(iTimerThresholdCummulative) > TIME_OVER_MAX) { //been on too long
		    VAR(baselineCount) = 0;	//Establish a new BASELINE measure state
		    VAR(iTimerThreshold) = 0;
		    VAR(iTimerThresholdCummulative) = 0;
		    NextEV = EV_UNDER;
		  }
		  break;
		default:NextEV = EV_UNDER ; break;	 //should never get here!
		}//switch EVState
	      
#ifdef new
	      if( VAR(EVState) == EV_UNDER ) {			
		SET_YELLOW_LED_PIN();       //LED off  (Yellow LED on MICA)
		CLR_GREEN_LED_PIN();       //LED On  (Green LED on MICA)
		if( VAR(iTimerThreshold) > TIME_OVER_MIN) {	   //Are we over the threshold yet?
		  VAR(iTimerThreshold) = 0;	//reset the count
		  NextEV = EV_OVER;	//trigger event
		}
	      }// EV_UNDER
#endif //new
	      //--------------------------process message-----------------------
	      if(VAR(EVState) >= EV_OVER)  // it is a real signal   
		{ // Event Detected  
		  CLR_YELLOW_LED_PIN();       // led ON  (Yellow LED on MICA)
		  SET_GREEN_LED_PIN();       //LED Off  (Green LED on MICA)
		  if( VAR(iTimerThresholdCummulative) > TIME_OVER_MAX) { //been on too long
		    VAR(baselineCount) = 0;	//Establish a new BASELINE measure state
		    VAR(iTimerThreshold) = 0;
		    VAR(iTimerThresholdCummulative) = 0;
		    NextEV = EV_UNDER;
		  }		 
		} //event detected
	      break; //DM_NORMAL
	      
	    default:
	      //should never get here
	      NextDAQMode = DM_NORMAL;
	      break;
	    }	//switch DAQMode
	}  //else DAQModes
    }	//baseline>baseline count
  
  
  VAR(DAQMode) = NextDAQMode;		//update state
  VAR(EVState) = NextEV;		//update Event state

}


//*****************************************************************************
// MAGSZ_INIT
// - init all states
//*****************************************************************************
char TOS_COMMAND(MAGSZ_INIT)(void) {

  VAR(samp_on) = 1;            //Enable sampling on init
  VAR(DAQMode) = DM_NORMAL;    //DAQ MOde
  VAR(EVState) = EV_UNDER;
  VAR(cAZBit)  = 0;
  VAR(I2CBusy) = I2C_IDLE;     // clear I2C commbus busy flag

  VAR(iTimeinSaturation) = 0;	//reset saturation flag
  VAR(iTimerThreshold) = 0;
  VAR(iTimerThresholdCummulative) = 0;
  
  // initialized bufferdata to look like mag - static info
  VAR(bufr_data).xsum = 0;
  VAR(bufr_data).ysum = 500;
  VAR(avgMagX) = 511;
  VAR(avgMagY) = 512;

  VAR(msgPtr) = &VAR(buffer1);
  VAR(oldmsgPtr) = &VAR(buffer2);
  VAR(msgIndex) = 0;
  VAR(stepdown) = 6;

  InitSampling();
  
  TOS_CALL_COMMAND(MAGSZ_SUB_INIT)();        //initialize lower components-see *.desc
  TOS_CALL_COMMAND(MAGSZ_TEMP_INIT)();       //initialize temperature component
  TOS_CALL_COMMAND(MAGSZ_ACCEL_INIT)();      //initialize accelerometer
  TOS_CALL_COMMAND(MAGSZ_MAG_INIT)();      //initialize accelerometer

  TOS_CALL_COMMAND(MAGSZ_CLOCK_INIT)(64, 0x02); /* every 16 milli seconds */

  SET_RED_LED_PIN();     //clr LEDs
  SET_GREEN_LED_PIN();   
  SET_YELLOW_LED_PIN();

  printf("MAGSZ is initialized\n");
  dbg(DBG_BOOT, ("MAGSZ is initialized.\n"));

  return 1;
}

//*****************************************************************************
// MAGSZ_START
// - send the start command
//*****************************************************************************
char TOS_COMMAND(MAGSZ_START)(void){
  // Turn on magnetometer
  //SET_MAG_CTL_PIN();
  VAR(DAQMode) = DM_STARTUP;	  //wait for system to settle down
  VAR(iTimerThreshold) = STARTUP_HOLDOFF;

  return 1;
}

//*****************************************************************************
// MAGSZ_CLOCK_EVENT
// - clock triggered
// - check if sampling enabled
// - start ADC for  Magnetomer A
//*****************************************************************************
void TOS_EVENT(MAGSZ_CLOCK_EVENT)(){
  
  if( VAR(DAQMode) == DM_STARTUP ) {	//idle until startup of radio etc has finished
    VAR(iTimerThreshold)--;
    if(!VAR(iTimerThreshold))
      VAR(DAQMode) = DM_AUTOZERO_START;		// do an autozero
  }
  
  if(VAR(samp_on) == 0){
    SET_RED_LED_PIN();         //red led off
    return;                    //break loop if not sampling  
  }

  if(VAR(iTimeinSaturation)>RE_ZERO_COUNT && (VAR(DAQMode)==DM_NORMAL) ){ 
    VAR(DAQMode) = DM_AUTOZERO_START;	  //start autozero operation
    VAR(iTimeinSaturation) = 0;
  }
  
  TOS_CALL_COMMAND(MAGSZ_GET_MAG_XDATA)(); //start ADC for X -maps to Event-2  
}

//*****************************************************************************
// MAGSZ_DATA_EVENT_2
// - x axis ADC data ready
// - start ADC for magnetometer B
//*****************************************************************************

char TOS_EVENT(MAGSZ_DATA_EVENT_2)(short data){
  VAR(bufr_data).adata[VAR(bufr_data).index].x_val = data;
  TOS_CALL_COMMAND(MAGSZ_GET_MAG_YDATA)(); //get data for MagnetometerB
  return 1;  
}

//*****************************************************************************
// MAGSZ_DATA_EVENT_3
// - y axis ADC data ready
// - place data into next available buffer location
//*****************************************************************************
char TOS_EVENT(MAGSZ_DATA_EVENT_3)(short data){
  
  VAR(bufr_data).adata[VAR(bufr_data).index].y_val = data;
  TOS_POST_TASK(FILTER_DATA);
  VAR(stepdown)--;
  if (VAR(stepdown) == 4){
    TOS_CALL_COMMAND(MAGSZ_GET_TEMP_DATA)();
  }else if (VAR(stepdown) == 2){
    TOS_CALL_COMMAND(MAGSZ_GET_ACCEL_XDATA)();
  }else if (VAR(stepdown) == 0){
    TOS_CALL_COMMAND(MAGSZ_GET_ACCEL_YDATA)();
    VAR(stepdown) = 6;
  }
  return 1;  
}

//*****************************************************************************
// MAGSZ_DATA_EVENT_4
// - temperature data ready
// - place data into next available buffer location
//*****************************************************************************
char TOS_EVENT(MAGSZ_DATA_EVENT_4)(short data){
  short * mp = (short *)&(VAR(msgPtr)->data[0]);
  mp[(int)VAR(msgIndex)++] = data;
  return 1;
}

//*****************************************************************************
// MAGSZ_DATA_EVENT_5
// - Accel X axis data ready
// - place data into next available buffer location
//*****************************************************************************
char TOS_EVENT(MAGSZ_DATA_EVENT_5)(short data){
  short * mp = (short *) &(VAR(msgPtr)->data[0]);
  mp[(int)VAR(msgIndex)++] = data;
  return 1;
}


//*****************************************************************************
// MAGSZ_DATA_EVENT_6
// - Accel Y axis data ready
// - place data into next available buffer location
//*****************************************************************************
char TOS_EVENT(MAGSZ_DATA_EVENT_6)(short data){
  TOS_MsgPtr tmp;
  short * mp = (short *) &(VAR(msgPtr)->data[0]);
  mp[(int)VAR(msgIndex)++] = data;
  if (VAR(msgIndex) == 15){
    TOS_CALL_COMMAND(MAGSZ_SEND_MSG)(TOS_UART_ADDR, 10, VAR(msgPtr));
    VAR(msgIndex) = 0;
    tmp = VAR(oldmsgPtr);
    VAR(oldmsgPtr) = VAR(msgPtr);
    VAR(msgPtr) = tmp;
  }
  return 1;
}

/*****************************************************************************
// MAGSZ_SUB_MESG_SEND_DONE
// - xmit message complete
Event indicating that a packet has been sent
Check if the packet is "owned" by this caller 
---CAUTION : ASSUMES THIS CALLER USED VAR(msgptr) and does NOT free msgptr until
			completion. Contents of msgptr CAN be changed (AXONN_PACKET makes local copy)
***************************************************************************** */
char TOS_EVENT(MAGSZ_MSG_SEND_DONE)(TOS_MsgPtr sent_msgptr){

  if(VAR(oldmsgPtr) == sent_msgptr){	//pointing to the same structure as sent?
    printf("Message has been sent\n");
  }
  return 1;
}

//*****************************************************************************
// Magnetometer Offset support services
// - Acknowledgement of write pot operation
//*****************************************************************************
char TOS_EVENT(MAGSZ_SET_POT_X_DONE) (char success) {
  // Offset has been updated, clear busy flag  
  if( VAR(I2CBusy)==I2C_POTX) { //update MAG Y POT
    VAR(I2CBusy) = I2C_POTY;
    TOS_CALL_COMMAND(MAGSZ_SET_POT_Y)(VAR(cMagYOffset));
  } 
  return 1;
}

char TOS_EVENT(MAGSZ_SET_POT_Y_DONE) (char success) {
  VAR(I2CBusy) = I2C_IDLE;  
  if( VAR(DAQMode) == DM_AUTOZERO)	//Autozeroing so force a new ADC baseline acq
    VAR(bufr_data).minCount = 0;  //force a new 4-sample average
  return 1;
}

//********************* local function definitions ****************************
//*****************************************************************************
// InitSampling
// - sets frame parameters and led associated with sampling and triggering back 
//   to their initial values
//*****************************************************************************
void InitSampling(void)
{
  int i;

  VAR(avgMagX) = 0;
  VAR(avgMagY) = 0;
  VAR(baselineCount) = 0;

  //Init buffer contents
  VAR(bufr_data).index = 0;
  VAR(bufr_data).minCount = 0;

  VAR(bufr_data).xsum = 0;
  VAR(bufr_data).ysum = 0;
  VAR(bufr_data).trgHoldoffCount = 0;
  for(i=0;i<BUFR_WSAMPLES;i++)
  {
    VAR(bufr_data).adata[i].x_val = 0;
    VAR(bufr_data).adata[i].y_val = 0;
  }

  SET_GREEN_LED_PIN();   //clear led
}

// end MAGSZ.c
/********************************************************************************************/
/************************************ ENDOFFILE *********************************************/
