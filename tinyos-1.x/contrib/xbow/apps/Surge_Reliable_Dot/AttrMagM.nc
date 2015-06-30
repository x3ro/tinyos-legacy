// $Id: AttrMagM.nc,v 1.1 2004/03/15 19:30:39 jlhill Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

module AttrMagM {
    provides interface StdControl;
    uses {
        interface Timer;
		interface MagSetting;
        interface StdControl as MagControl;
        interface ADC as MagX;
		interface ADC as MagY;
		interface AttrRegister as AttrMagX;
		interface AttrRegister as AttrMagY;
    }
}
implementation {
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
 	EV_IDLE	=0,		//no signal detected
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
   	TIME_OVER_MAX  =120,	    //over threshold for so long should establish a new baseline
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
  bool isRunning;
  uint16_t maxMagX, maxMagY;


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
	    }
	    else{
	      avgMagX = avgMagXSum >> BASELINE_SHIFT_BITS;
	      avgMagY = avgMagYSum >> BASELINE_SHIFT_BITS;
	    }
	  }  // end baseline averaging
      else //------- DAQMode states --------------------------------------
      { 
	     // Have baseline data in avg vars - Handle DAQStates	  
	    switch( DAQMode ) 
	    {
	    case DM_AUTOZERO_START: 
		  //--AUTOZERO_START
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
		    //CLR_GREEN_LED_PIN();
	      }  
	      else { //set next bit in offset pots and measure ADC response
		    cMagXOffset =  cMagXOffset |  cAZBit;
		    cMagYOffset =  cMagYOffset |  cAZBit;
		    //set Offset and measure baseline data
		    I2CBusy = I2C_POTX;		  //I2C bus will be busy setting pot
		    //CLR_RED_LED_PIN();                                 //led on
		    call MagSetting.gainAdjustX( cMagXOffset);
		    // WRITE_DONE Event will initiate ADC baseline measurement  
	      } //if cAZBit
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
		  if ( iTimerThreshold > TIME_OVER_MIN) {	   //Are we over the threshold yet?
		     iTimerThreshold = 0;	//reset the count - it now reflects elapsed time over
		    NextEV = EV_OVER;	//trigger event
		  }
		  break;
		case EV_OVER:				
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
	    if(  EVState) == EV_UNDER ) {			
		  if( iTimerThreshold > TIME_OVER_MIN) {	   //Are we over the threshold yet?
		    iTimerThreshold = 0;	//reset the count
		    NextEV = EV_OVER;	//trigger event
		  }
	    }// EV_UNDER
#endif //new
	      //--------------------------process message-----------------------
	    if( EVState >= EV_OVER)  // it is a real signal   
		{ // Event Detected  
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


/*****************************************************************************
 *   SimpleInit.init
 *   - init all states
****************************************************************************/
command result_t StdControl.init() {
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

  call MagControl.init();

  isRunning = FALSE;
  maxMagX = 0;
  maxMagY = 0;
  if (call AttrMagX.registerAttr("mag_x", UINT16, 2) != SUCCESS)
  	return FAIL;
  if (call AttrMagY.registerAttr("mag_y", UINT16, 2) != SUCCESS)
  	return FAIL;
  dbg(DBG_BOOT, ("MAGSZ is initialized.\n"));

  return SUCCESS;
}

command result_t StdControl.start(){
	return SUCCESS;
}

void startMag()
{
  // Turn on magnetometer
  //SET_MAG_CTL_PIN();
	call MagControl.start();
   isRunning = TRUE;
   InitSampling();
   DAQMode = DM_STARTUP;	  //wait for system to settle down
   iTimerThreshold = STARTUP_HOLDOFF;
   call Timer.start(TIMER_REPEAT, 32);
}

void stopMag()
{
  call Timer.stop();
  isRunning = FALSE;
}

command result_t StdControl.stop() {
  stopMag();
  return SUCCESS;
}

//*****************************************************************************
//  CLOCK_EVENT
// - clock triggered
// - check if sampling enabled
// - start ADC for  Magnetomer A
//*****************************************************************************
event result_t Timer.fired()
{
  
  if ( DAQMode == DM_STARTUP ) {	
    //idle until startup of radio etc has finished
    iTimerThreshold--;
    if (!iTimerThreshold)
       DAQMode = DM_AUTOZERO_START;		// do an autozero
  }
  
  if( iTimeinSaturation>RE_ZERO_COUNT && (DAQMode==DM_NORMAL) ){ 
     DAQMode = DM_AUTOZERO_START;	  //start autozero operation
     iTimeinSaturation = 0;
  }
  
  // if (call MagX.getData() == FAIL)
  	// call SounderControl.start();
  // return SUCCESS;
  return call MagX.getData(); //start ADC for X -maps to Event-2  
}

//*****************************************************************************
// MAGSZ_DATA_EVENT_2
// - x axis ADC data ready
// - start ADC for magnetometer B
//*****************************************************************************

async event result_t MagX.dataReady(uint16_t data){
   bufr_data.adata[ bufr_data.index].x_val = data;
   if (maxMagX < data)
       maxMagX = data;
   return call  MagY.getData(); //get data for MagnetometerB
}

//*****************************************************************************
// MAGSZ_DATA_EVENT_3
// - y axis ADC data ready
// - place data into next available buffer location
//*****************************************************************************
async event result_t MagY.dataReady(uint16_t data){
  bufr_data.adata[ bufr_data.index].y_val = data;
   if (maxMagY < data)
       maxMagY = data;
  post FILTER_DATA();

  return SUCCESS;  
}

//*****************************************************************************
// Magnetometer Offset support services
// - Acknowledgement of write pot operation
//*****************************************************************************
event result_t MagSetting.gainAdjustXDone(bool success) {
  // Offset has been updated, clear busy flag  
  if(  I2CBusy==I2C_POTX) { //update MAG Y POT
     I2CBusy = I2C_POTY;
     call MagSetting.gainAdjustY( cMagYOffset);
  } 
  return SUCCESS;
}

event result_t MagSetting.gainAdjustYDone(bool success) {
   I2CBusy = I2C_IDLE;  
  if(  DAQMode == DM_AUTOZERO)	//Autozeroing so force a new ADC baseline acq
     bufr_data.minCount = 0;  //force a new 4-sample average
  return SUCCESS;
}


/*****************************************************************************
 * InitSampling
 * - sets frame parameters and led associated with sampling and triggering back 
 *   to their initial values
 *****************************************************************************/
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

}

event result_t AttrMagX.startAttr()
{
	if (!isRunning)
		startMag();
	return call AttrMagX.startAttrDone();
}

event result_t AttrMagX.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
{
	*errorNo = SCHEMA_RESULT_READY;
	if(maxMagX == 0) maxMagX = 0x23;
	*(uint16_t*)resultBuf = maxMagX;
	*(uint16_t*)resultBuf = cMagXOffset;
	maxMagX = 0;
	return SUCCESS;
}

event result_t AttrMagX.setAttr(char *name, char *attrVal)
{
	return FAIL;
}

event result_t AttrMagY.startAttr()
{
	if (!isRunning)
		startMag();
	return call AttrMagY.startAttrDone();
}

event result_t AttrMagY.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
{
	*errorNo = SCHEMA_RESULT_READY;
	*(uint16_t*)resultBuf = maxMagY;
	maxMagY = 0;
	*(uint16_t*)resultBuf = cMagYOffset;
	return SUCCESS;
}

event result_t AttrMagY.setAttr(char *name, char *attrVal)
{
	return FAIL;
}

} // end of implemnetation
