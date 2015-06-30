
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 1996-2000 Intel Corporation 
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
 * Authors:  Alec Woo Su Ping 
 *           Intel Research Berkeley Lab
 *
 */
/* 
 * Implementation for MicasbTest1 application.
 *
 * MicasbTest1 is an application that test out the magnetometer, accelerometer, and temperature sensor.
 * It demonstrates how to access the data from each individual sensors, how to perform real time 
 * "calibration", and how to filter and process sensory data for the magnetometer.  
 *
 * The test cases for the accelerometer and the temperature sensor is very simple.  The raw 10 bit data from
 * these sensors are sent over the UART for visual inspection.  The format of the packet looks like
 * the following: (30 bytes long, each sensor value is 2 bytes long)
 *
 * [TEMP ACCEL_X ACCEL_Y] [TEMP ACCEL_X ACCEL_Y] [TEMP ACCEL_X ACCEL_Y] [TEMP ACCEL_X ACCEL_Y] [TEMP ACCEL_X ACCEL_Y]
 *
 *
 * For the magnetometer, one can visually look at the LEDs to see if it is working.
 * RED - self calibration is being done
 * GREEN - idle -> no magnetic field event detected
 * Yellow - event triggered:  either X or Y axis has event detected. 
 *
 */


/****************************************************************************
									tab:4
SENSOR INFO
Number of Channels	2 (x,Y)

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
*****************************************************************************/

module MicasbTest1M {
    provides interface StdControl;
    uses {
        interface Clock;
        interface Leds;
	interface MagSetting;
        interface StdControl as CommControl;
        interface StdControl as AccelControl;
        interface StdControl as TempControl;
        interface ADC as AccelX;
	interface ADC as AccelY;
        interface StdControl as MagControl;
        interface ADC as MagX;
	interface ADC as MagY;
        interface ADC as TempADC;
	interface SendMsg as Send;
    }
}
implementation {
  // declar module static variables here
  
  enum {
    MAG_OFFSET_MIDSCALE = 128,
    MAG_ADC_MIDSCALE  = 512,
    MAG_ADC_ALMOSTMAX = 700,   //only 50% fs range due to instrumentation amp rails
    MAG_ADC_ALMOSTMIN =	300
  };
  
  enum{
    I2C_IDLE = 0,//I2C not busy
    I2C_POTX ,	 //I2C Busy writing to Mag X pot
    I2C_POTY  	 //I2C Busy writing to Mag Y pot
  };
  
  //Data Acquisition modes/states
  enum {
    DM_IDLE	=	0,	    //nothing
    DM_AUTOZERO_START,	//start autozeroing
    DM_AUTOZERO	,       //autozero the magnetometers
    DM_UNDEFINED ,
    DM_NORMAL,	        //standard daq
    DM_STARTUP 	        //startup holdoff
  };
  
  //Event Detection states
  enum {
    EV_UNDER=0, 	//under threshold
    EV_OVER	=1,     //over threshold
    EV_IDLE	=0,	//no signal detected
    EV_ADC  =   1,	//ADC data over Amplitude threshold
    EV_TIME	=   2	//Data over Time and Amplitude threshold
  };
  
  enum {
    BUFR_SHIFT_BITS =2,
    //NOTE: gcc doesn't process "    BUFR_WSAMPLES (2 << BUFR_SHIFT_BITS)" properly
    // so following define must be hand-entered for any change to BUFR_SHIFT_BITS
    BUFR_WSAMPLES= 4                 // history buffer size
  };

  //--- Magnetometer Thresholds	6.4 ADCCounts/milliGauss (0.13mgauss/bit)(nominal)
  enum {
    MAGX_THRESHOLD = 10,        //trigger threshold offset from quiescent baseline in adc counts)
    MAGY_THRESHOLD = 10,        //trigger threshold offset from quiescent (in adc counts)
    TIME_OVER_MIN  = 3,	        //time over threshold to qualify as an event (noise suppress)
    TIME_UNDER_MIN =-3,	        //time under threshold to qualify as event removed NOTE SIGN!!!
    TIME_OVER_MAX  =120,	//over threshold for so long should establish a new baseline
    RE_ZERO_COUNT  =30,	        //#of samples in saturation requiring a re-zero of mag
    STARTUP_HOLDOFF=120,        // Clock ticks for startup to complete before autozeroing
    
    BASELINE_COUNT = 32,        //# of BUFR_WSAMPLES-averaged data:beware of overflows
    BASELINE_SHIFT_BITS =5      // must keep this value consistent with previous value
  };
  
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
  void InitSampling();
  
  /* Define the module variables  */  
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


  /**
   *  Task for filtering the 2 axis data from the magnetometer and performm event detection.
   *  
   *  @return returns void.
   **/
  task void FILTER_DATA(){
    int xsum, ysum;
    int i;
    char NextDAQMode;
    char NextEV; 
    
    // Default next DAQMode state is current state
    NextDAQMode = DAQMode;
    NextEV = EVState;	//default is to stay in current state
    
    //increment buffer array index
    bufr_data.index++;
    if (bufr_data.index >= BUFR_WSAMPLES)
      bufr_data.index = 0;
    //Test threshold
    
    //test whether the buffer has been filled at least once. 
    if(bufr_data.minCount < (BUFR_WSAMPLES-1)){
      //if not, increment buffer count
      bufr_data.minCount++;
    }else
      //if so, calculate averages and set led appropriately.
      {
	//calculate averages
	xsum = 0;
	ysum = 0;
	for(i=0;i<BUFR_WSAMPLES;i++)  {
	    xsum += bufr_data.adata[i].x_val;
	    ysum += bufr_data.adata[i].y_val;
	}
	xsum = xsum >> BUFR_SHIFT_BITS;
	ysum = ysum >> BUFR_SHIFT_BITS;
	bufr_data.xsum = xsum;
	bufr_data.ysum = ysum;
	
	//either use data for baseline averaging or for threshold test
	if(baselineCount < BASELINE_COUNT) {
	  if(baselineCount==0 ) {	 //initialize average
	    avgMagXSum = 0;
	    avgMagYSum = 0;
	  }
	  //when baselineCount reaches limit, perform 16x4 sample average
	  
	  baselineCount++;
	  avgMagXSum += xsum;
	  avgMagYSum += ysum;
	  if(baselineCount < BASELINE_COUNT)	{
	    bufr_data.minCount = 0;  //start next 4-sample average
	    //turn off all leds but 1 to keep PS offsets balanced
	    TOSH_SET_RED_LED_PIN();
	    TOSH_SET_YELLOW_LED_PIN();
	    TOSH_CLR_GREEN_LED_PIN();       //LED ON  (RED LED on MICA)
	  }
	  else{
	    avgMagX = avgMagXSum >> BASELINE_SHIFT_BITS;
	    avgMagY = avgMagYSum >> BASELINE_SHIFT_BITS;
	    TOSH_SET_GREEN_LED_PIN();       //LED OFF  (RED LED on MICA)
	  }
	}  // end baseline averaging
	else //------- DAQMode states --------------------------------------
	  { 
	    // Have baseline data in avg vars - Handle DAQStates	  
	    switch( DAQMode ) 
	      {
	      case DM_AUTOZERO_START: 
		//--AUTOZERO_START
		call Leds.redOn();       //Red led on
		cMagXOffset = MAG_OFFSET_MIDSCALE;
		cMagYOffset = MAG_OFFSET_MIDSCALE;
		cAZBit = MAG_OFFSET_MIDSCALE; //set MSB	-!!NOTE:using int because no unsignedchar???
		I2CBusy = I2C_POTX;		  //I2C bus will be busy setting pot X
		
		call MagSetting.gainAdjustX(cMagXOffset); 
		// WRITE_DONE Event will initiate ADC baseline measurement 
		NextDAQMode = DM_AUTOZERO;	 // change state
		//dmazstart
		break; //azstart
		
	      case DM_AUTOZERO:  //--AUTOZERO_OPERATION
		if( I2CBusy ){
		  break;
		}	 //no can do
		// Evaluate ADC data
		if( (xsum)<MAG_ADC_MIDSCALE) {	//Mag X Offset
		  //clear previous bit in offset pot 
		  cMagXOffset = cMagXOffset& ~cAZBit;
		}
		if( (ysum)<MAG_ADC_MIDSCALE) {	//Mag Y offset
		  //clear previous bit in offset pot 
		  cMagYOffset= cMagYOffset & ~cAZBit;
		}
		
		cAZBit = cAZBit>>1;	// Set next bit in offset pots
		
		if( cAZBit==0) {	// autozero operation finished
		  baselineCount= 0; 	//Establish a new base line for threshold detection
		  NextDAQMode = DM_NORMAL;	//return to general data acquisition

		}  
		else { //set next bit in offset pots and measure ADC response
		  cMagXOffset =  cMagXOffset |  cAZBit;
		  cMagYOffset =  cMagYOffset |  cAZBit;
		  //set Offset and measure baseline data
		  I2CBusy = I2C_POTX;		  //I2C bus will be busy setting pot

		  call MagSetting.gainAdjustX( cMagXOffset);
		  // WRITE_DONE Event will initiate ADC baseline measurement  
		} //if cAZBit
		call Leds.redToggle();  //led on
		break;//DM_AUTOZERO
		
	      case DM_NORMAL:			//---DM_NORMAL
		
		//Do NOT evaluate data if in trigger hold-off 
		if( bufr_data.trgHoldoffCount > 0){
		  bufr_data.trgHoldoffCount--;
		  iTimerThreshold = 0; //reset the count
		  NextEV = EV_UNDER;	//clear the Event 
		  bufr_data.minCount = 0;	//force buffer to flush during holdoff
		  break;
		}	// don't evaluate adc data during RF transmission & holdoff
		
		// Update moving average baseline
		avgMagXSum = xsum +  avgMagXSum - ( avgMagXSum>>BASELINE_SHIFT_BITS);
		avgMagX =  avgMagXSum >> BASELINE_SHIFT_BITS;
		avgMagYSum = ysum +  avgMagYSum - ( avgMagYSum>>BASELINE_SHIFT_BITS);
		avgMagY=  avgMagYSum >> BASELINE_SHIFT_BITS;
		
		//	state = EV_IDLE;
		if((xsum > ( avgMagX+MAGX_THRESHOLD))
		   || (xsum < ( avgMagX-MAGX_THRESHOLD))) {
		  iTimerThresholdCummulative++;	
		  iTimerThreshold++;  //update time over
		}
		else if((ysum > ( avgMagY+MAGY_THRESHOLD))
			|| (ysum < ( avgMagY-MAGY_THRESHOLD))) {
		  iTimerThresholdCummulative++;	
		  iTimerThreshold++;  //update time over
		}
		//state = EV_ADC;
		else {
		  iTimerThreshold--;
		  iTimerThresholdCummulative--;
		}
	      
	      
		if(  iTimerThreshold < TIME_UNDER_MIN-2)
		  iTimerThreshold = TIME_UNDER_MIN-2;	//dont let the counter underflow
		
		if ( iTimerThresholdCummulative < 0)
		  iTimerThresholdCummulative = 0;	//dont let the counter underflow
		
		// Check if ADC is close to saturation
		if( xsum>MAG_ADC_ALMOSTMAX 	|| xsum<MAG_ADC_ALMOSTMIN ||
		    ysum>MAG_ADC_ALMOSTMAX || ysum<MAG_ADC_ALMOSTMIN)
		  iTimeinSaturation++;
		else
		  iTimeinSaturation = 0;	//clear count if drop out of saturation
		
		/*
		  State Machine for Event Detection
		*/
		
		switch( EVState) 
		  {
		  case EV_UNDER:	   			
		    call Leds.yellowOff();       //LED off  (Yellow LED on MICA)
		    call Leds.greenOn();       //LED On  (Green LED on MICA)
		  if ( iTimerThreshold > TIME_OVER_MIN) {	   //Are we over the threshold yet?
		    iTimerThreshold = 0;	//reset the count - it now reflects elapsed time over
		    NextEV = EV_OVER;	//trigger event
		  }
		  break;
		case EV_OVER:				
		  call Leds.yellowOn();       // led ON  (Yellow LED on MICA)
		  call Leds.greenOff();       //LED Off  (Green LED on MICA)
		  if(  iTimerThreshold<TIME_UNDER_MIN) { //Are we still over the threshold ?
		    iTimerThreshold = 0; //reset the count
		    //	 iTimerThresholdCummulative) = 0;
		    NextEV = EV_UNDER;	//been under for awhile  
		  }
		  if(  iTimerThresholdCummulative > TIME_OVER_MAX) { //been on too long
		    baselineCount = 0;	//Establish a new BASELINE measure state
		    iTimerThreshold = 0;
		    iTimerThresholdCummulative = 0;
		    NextEV = EV_UNDER;
		  }
		  break;
		  default: NextEV = EV_UNDER ; break;	 //should never get here!
		  }//switch EVState
		
#ifdef new
		if(  EVState == EV_UNDER ) {			
		  call Leds.yellowOff();       //LED off  (Yellow LED on MICA)
		  call Leds.greenOn();       //LED On  (Green LED on MICA)
		  if( iTimerThreshold > TIME_OVER_MIN) {	   //Are we over the threshold yet?
		    iTimerThreshold = 0;	//reset the count
		    NextEV = EV_OVER;	//trigger event
		  }
		}// EV_UNDER
#endif //new
		//--------------------------process message-----------------------
		if( EVState >= EV_OVER)  // it is a real signal   
		  { // Event Detected  
		    call Leds.yellowOn();       // led ON  (Yellow LED on MICA)
		    call Leds.greenOff();       //LED Off  (Green LED on MICA)
		    if(  iTimerThresholdCummulative > TIME_OVER_MAX) { //been on too long
		      baselineCount = 0;	//Establish a new BASELINE measure state
		      iTimerThreshold = 0;
		      iTimerThresholdCummulative = 0;
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
    DAQMode = NextDAQMode;		//update state
    EVState = NextEV;		//update Event state
  }
  
  
  /**
   * Initialize this and all low level components used in this application.
   * 
   * @return returns <code>SUCCESS</code> or <code>FAIL</code>
   */
  command result_t StdControl.init() {
    result_t ret;
    samp_on = 1;            //Enable sampling on init
    DAQMode = DM_NORMAL;    //DAQ MOde
    EVState = EV_UNDER;
    cAZBit  = 0;
    I2CBusy = I2C_IDLE;     // clear I2C commbus busy flag
    
    iTimeinSaturation = 0;	//reset saturation flag
    iTimerThreshold = 0;
    iTimerThresholdCummulative = 0;
    
    // initialized bufferdata to look like mag - static info
    bufr_data.xsum = 0;
    bufr_data.ysum = 500;
    avgMagX = 511;
    avgMagY = 512;
    
    msgPtr = & buffer1;
    oldmsgPtr = & buffer2;
    msgIndex = 0;
    stepdown = 6;
    
    InitSampling();
    
    ret = call CommControl.init();        //initialize lower components
    ret &= call TempControl.init();       //initialize temperature component
    ret &= call AccelControl.init();      //initialize accelerometer
    ret &= call MagControl.init();
    
    ret &= call Clock.setRate(64, 0x02); /* every 16 milli seconds */
    
    ret &= call Leds.init();
    call Leds.redOff();
    call Leds.greenOff();
    call Leds.yellowOff();
    dbg(DBG_BOOT, ("MAGSZ is initialized.\n"));
    
    return ret;
  }

  /**
   * Start this component.
   * 
   * @return returns <code>SUCCESS</code>
   */
  command result_t StdControl.start(){
    DAQMode = DM_STARTUP;	  //wait for system to settle down
    iTimerThreshold = STARTUP_HOLDOFF;
    
    return SUCCESS;
  }

  /**
   * Stop this component.
   * 
   * @return returns <code>SUCCESS</code>
   */
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  /**
   *  In response to the <code>Clock.fire</code> event, it checks to see if 
   *  the startup phase has finished or not, is sampling enabled  and issues command 
   *  to starting sampling the magnetometer (X axis first or Magnetometer A pin).
   *  
   *  @return returns <code>SUCCESS</code>
   *
   **/
  event result_t Clock.fire(){
    
    if ( DAQMode == DM_STARTUP ) {	
      //idle until startup of radio etc has finished
      iTimerThreshold--;
      if (!iTimerThreshold)
	DAQMode = DM_AUTOZERO_START;		// do an autozero
    }
    
    if( samp_on == 0){
      //call Leds.redOff();         //red led off
      return SUCCESS;               //break loop if not sampling  
    }
    
    if( iTimeinSaturation>RE_ZERO_COUNT && (DAQMode==DM_NORMAL) ){ 
      DAQMode = DM_AUTOZERO_START;	  //start autozero operation
      iTimeinSaturation = 0;
    }
    
    call MagX.getData(); //start ADC for X -maps to Event-2  
    
    return SUCCESS;
  }

  /**
   *  In response to the <code>MagX.dataReady</code> event, it stores the sample
   *  and issues command to sample the magnetometer's Y axis. (Magnetometer B pin)
   *  
   *  @return returns <code>SUCCESS</code>
   *
   **/
  event result_t MagX.dataReady(uint16_t data){
    bufr_data.adata[ bufr_data.index].x_val = data;
    call  MagY.getData(); //get data for MagnetometerB
    return SUCCESS;  
  }

  /**
   *  In response to the <code>MagY.dataReady</code> event, it stores the sample
   *  and issues a task to filter and process the stored magnetometer data.
   *
   *  It also has a schedule which starts sampling the Temperture and Accelormeter depending
   *  on the stepdown counter.
   * 
   *  @return returns <code>SUCCESS</code>
   **/
  event result_t MagY.dataReady(uint16_t data){
    bufr_data.adata[ bufr_data.index].y_val = data;
    post FILTER_DATA();
    stepdown--;
    
    if ( stepdown == 4){
      call TempADC.getData();
    }else if ( stepdown == 2){
      call AccelX.getData();
    }else if ( stepdown == 0){
      call AccelY.getData();
      stepdown = 6;
    }
    return SUCCESS;  
  }
  
  /**
   *  In response to the <code>TempADC.dataReady</code> event, it stores the sample
   *  which will be sent out to the UART as a message.
   *  
   *  @return returns <code>SUCCESS</code>
   *
   **/
  event result_t TempADC.dataReady(uint16_t data){
    short * mp = (short *)&( msgPtr->data[0]);
    mp[(int) msgIndex++] = data;
    return SUCCESS;
  }

  /**
   *  In response to the <code>AccelX.dataReady</code> event, it stores the sample
   *  which will be sent out to the UART as a message.
   *  
   *  @return returns <code>SUCCESS</code>
   *
   **/
  event result_t AccelX.dataReady(uint16_t  data){
    uint16_t * mp = (uint16_t *) &( msgPtr->data[0]);
    mp[(int) msgIndex++] = data;
    return SUCCESS;
  }



  /**
   *  In response to the <code>AccelY.dataReady</code> event, it stores the sample
   *  to the message buffer.  If the message buffer is full, sent it out to the UART.
   *  
   *  @return returns <code>SUCCESS</code>
   *
   **/
  event result_t AccelY.dataReady(uint16_t data){
    TOS_MsgPtr tmp;
    uint16_t * mp = (uint16_t *) &( msgPtr->data[0]);
    mp[(int) msgIndex++] = data;
    if ( msgIndex == 15)
      {
	call Send.send(TOS_BCAST_ADDR, 29,  msgPtr);
	msgIndex = 0;
	tmp =  oldmsgPtr;
	oldmsgPtr =  msgPtr;
	msgPtr= tmp;
      }
    return SUCCESS;
  }

  /**
   *  Response to the <code>Send.sendDone</code> event.  Simply returns.
   *  
   *  @return returns <code>SUCCESS</code>
   *
   **/
  event result_t Send.sendDone(TOS_MsgPtr sent_msgptr, result_t success){
    /*
      if( oldmsgPtr == sent_msgptr){	//pointing to the same structure as sent?
      printf("Message has been sent\n");
      }
    */
    return SUCCESS;
  }

  /**
   *  In response to the <code>MagSetting.gainAdjustXDone</code> event,
   *  start adjusting the Y axis.
   *
   *  @return returns <code>SUCCESS</code> of <code>FAIL</code>
   *
   **/
  event result_t MagSetting.gainAdjustXDone(bool success) {
    char ret;
    // Offset has been updated, clear busy flag  
    
    if(  I2CBusy==I2C_POTX) { //update MAG Y POT
      I2CBusy = I2C_POTY;
      ret = call MagSetting.gainAdjustY( cMagYOffset);
      return ret;
    } 
    return SUCCESS;
  }

  /**
   *  In response to the <code>MagSetting.gainAdjustYDone</code> event,
   *  Force a new 4-sample average if we are doing autozeroing.
   *
   *  @return returns <code>SUCCESS</code>
   *
   **/
  event result_t MagSetting.gainAdjustYDone(bool success) {
    I2CBusy = I2C_IDLE;  
    if(  DAQMode == DM_AUTOZERO)	//Autozeroing so force a new ADC baseline acq
      bufr_data.minCount = 0;  //force a new 4-sample average
    return SUCCESS;
  }


  /**
   * Module scoped method.  
   * It sets frame parameters to their initial values.
   *
   * @return returns <code>SUCCESS</code>
   **/
  void InitSampling()
    {
      int i;
      
      avgMagX = 0;
      avgMagY = 0;
      baselineCount = 0;
      
      //Init buffer contents
      bufr_data.index = 0;
      bufr_data.minCount = 0;
      
      bufr_data.xsum = 0;
      bufr_data.ysum = 0;
      bufr_data.trgHoldoffCount = 0;
      for(i=0;i<BUFR_WSAMPLES;i++)
	{
	  bufr_data.adata[i].x_val = 0;
	  bufr_data.adata[i].y_val = 0;
	}
      
      call Leds.greenOff();   //clear led
    }
  
} // end of implemnetation
