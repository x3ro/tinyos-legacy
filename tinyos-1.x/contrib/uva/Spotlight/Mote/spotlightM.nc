

includes spotlight;

module spotlightM
{
  provides interface StdControl;
  uses {
    interface Timer as samplingTimer;
    interface Timer as ReTransmissionTimer;
    interface Timer as WaitForAckTimer;
    interface Leds;
    interface StdControl as SensorControl;
    interface ADC;
    interface StdControl as CommControl;
    interface SendMsg as TxDataMsg;
    //    interface ReceiveMsg as RxDataMsg;    
    interface ReceiveMsg as RxConfigMsg;       

    interface ReceiveMsg as ResetCounterMsg;
    interface ReceiveMsg as ReportAckMsg;
    
    interface GlobalTime;
    interface Reset;
    interface Random;

	  #ifdef PLATFORM_XSM2  
	  interface Photo;
	  #endif    
  }
}
implementation
{

  enum {
    DEST_ADDR = 0,
    RAW_DATA_BATCH = 10,
    MAX_SCAN_NUMBER = 30,
    WAIT_FOR_ACK_INTERVAL = 4000,
    BACK_OFF_INTERVAL = 500,
    RETRANSMIT_NUMBER = 4,
    DEFAULT_THRESHOLD = 700, 
    DELTA = 100, //used to detect the  rising edge
    MAX_COUNT_ACK_RETRANS = 3
  };
 
  uint8_t reporting;
  uint8_t packetReadingNumber;
  uint16_t readingNumber;
  
  TOS_Msg outBuffer; // for report
  uint8_t outBufferPending;
  uint8_t MsgSeqNo;  
  uint8_t ackPending;

  uint8_t delta;
  uint8_t ledCounter;
  
  /* buffer for one scan */  
  uint16_t RawDataBuffer[RAW_DATA_BATCH]; //use to find out the maximum value from 10 recent reading to improve accuracy
  uint32_t TimeStampBuffer[RAW_DATA_BATCH];//conresponding timestamp for each reading.  
  
  /* arrays to store the maximum value over multiple scan */  

  uint8_t ScanID[MAX_SCAN_NUMBER];
  uint32_t MaxTimeStampBuffer[MAX_SCAN_NUMBER]; 
  uint16_t bufferIndex;
  uint16_t header, tail;
    
  uint8_t rawDataIndex; //the buffer is full up to rawDataIndex   
  uint8_t hitIndex; // RawDataBuffer[hitIndex] stores the maximum value  
  
  
  uint16_t DetectionThreshold = DEFAULT_THRESHOLD;
  uint32_t randomDelay = 0;
  
  uint8_t ReTxNumber = RETRANSMIT_NUMBER;
  uint8_t ReTxAckNumber = MAX_COUNT_ACK_RETRANS;
  
  uint8_t Calibration(uint16_t rawData);
  uint8_t Buffering(uint16_t rawData);//record the maximum value in last 10 readings 
  uint8_t RecordMaxValue( uint16_t rawData);//record the maximum value since the last report
  void show(uint8_t startValue, uint32_t delay, uint8_t endValue);   

  /**
   * Used to initialize this component.
   */
  command result_t StdControl.init() {
    
    uint8_t i;
    
    call Leds.init();
    call Leds.yellowOff(); call Leds.redOff(); call Leds.greenOff();

    //turn on the sensors so that they can be read.
    call SensorControl.init();

    call CommControl.init();
    
    atomic {
      packetReadingNumber = 0;
      readingNumber = 0;
      rawDataIndex = 0;
      outBufferPending = FALSE;
      MsgSeqNo = 0;
      ackPending = FALSE;
      delta = DELTA;
      ledCounter = 0;
    }
    
    atomic {
      for(i = 0 ; i < RAW_DATA_BATCH; i++){
	RawDataBuffer[i] = 0;     
      }
    }
    dbg(DBG_BOOT, "OSCOPE initialized\n");
    
    atomic {
      for(i = 0 ; i < MAX_SCAN_NUMBER; i++){
	ScanID[i] = 0;  
	MaxTimeStampBuffer[i] = 0;   
      }
      header = tail = 0;
    }
    

    
    return SUCCESS;
  }

  /**
   * Starts the SensorControl and CommControl components.
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.start() {
    call SensorControl.start();    
    call CommControl.start();
    
    #ifdef PLATFORM_XSM2  
	 call Photo.On();
	 #endif  
	 
    call samplingTimer.start(TIMER_REPEAT, 1);
    
#ifdef SPOTLIGHT_DEBUG    
    header = MAX_SCAN_NUMBER-1;
    randomDelay = call Random.rand() % BACK_OFF_INTERVAL+20;
    call ReTransmissionTimer.start(TIMER_ONE_SHOT,randomDelay);   
#endif
        
    return SUCCESS;
  }

  /**
   * Stops the SensorControl and CommControl components.
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.stop() {
    call SensorControl.stop();
    call samplingTimer.stop();
    call ReTransmissionTimer.stop();
    call CommControl.stop();
    return SUCCESS;
  }

  /********************************************************/
  task void dataTask() {
  
    struct ReportMsg *report = (struct ReportMsg *)outBuffer.data;
    int i=0;
         
    //sending busy
    if(outBufferPending) return;
         
    outBufferPending = TRUE;
           
    atomic {
     
      memset(report,0,sizeof(struct ReportMsg));
     
      report->type = REPORT_REPLY;
      report->moteID = TOS_LOCAL_ADDRESS;
      
      i = 0;
      for(bufferIndex = tail; bufferIndex != header && i < MAX_STAMPS;
	  bufferIndex = (bufferIndex+1)%MAX_SCAN_NUMBER) {
	
        report->ScanID[i] = ScanID[bufferIndex];
        report->timeStamp[i] = MaxTimeStampBuffer[bufferIndex];    
        dbg(DBG_USR1,"readings from %d\n",bufferIndex); 
        i++;
	
      }
      
      report->size = i;               
    }
            
    dbg(DBG_USR1,"Sendout readings from % to %d\n",tail,header);
               
    if( call TxDataMsg.send(DEST_ADDR, sizeof(struct ReportMsg),&outBuffer)){
    } else {
      randomDelay = call Random.rand() % BACK_OFF_INTERVAL+20;
      call ReTransmissionTimer.start(TIMER_ONE_SHOT,randomDelay);    
      outBufferPending = FALSE;		
    }
    
    return;     
  }
  
  /**
   * Signalled when data is ready from the ADC. Stuffs the sensor
   * reading into the current packet, and sends off the packet when
   * BUFFER_SIZE readings have been taken.
   * @return Always returns SUCCESS.
   */
  async event result_t ADC.dataReady(uint16_t data) {
     
#ifdef PLATFORM_PC      
    data = DEFAULT_THRESHOLD+1;     
#endif
     
     
    /* calibration the raw data */
    if(Calibration(data)) return FALSE;
       
#ifdef REACTIVE
    /* record the max value */
    RecordMaxValue(data);
#else
    /* buffer a set of data */
    if(!Buffering(data)) return FALSE;                
    post dataTask();
#endif
    
    return SUCCESS;
  }

  /**
   * Signalled when the previous packet has been sent.
   * @return Always returns SUCCESS.
   */
  event result_t TxDataMsg.sendDone(TOS_MsgPtr sent, result_t success) {
       
    outBufferPending = FALSE;

    // DELETE THE NEXT LINE RADU
    //reporting = FALSE;
    
#ifdef PLATFORM_PC
    success = SUCCESS;
#endif
    
    if(success){
      randomDelay = call Random.rand() % WAIT_FOR_ACK_INTERVAL + 20;
      ackPending = TRUE;
      //ReTxAckNumber = MAX_COUNT_ACK_RETRANS;
      call WaitForAckTimer.start(TIMER_ONE_SHOT, randomDelay);
      dbg(DBG_USR1,"Waiting For Ack");
      call Leds.greenToggle();
    } else {
      randomDelay = call Random.rand() % BACK_OFF_INTERVAL+20;
      call ReTransmissionTimer.start(TIMER_ONE_SHOT, randomDelay);          
      dbg(DBG_USR1,"Continue to send from %d to %d \n",tail,header);
    }
                
    return SUCCESS;
  }
  
  /**
   * Signalled when the report_request has been sent out by base.
   * @return The free TOS_MsgPtr. 
   */
  //  event TOS_MsgPtr RxDataMsg.receive(TOS_MsgPtr m) {    
  // return m;
  // }

  event TOS_MsgPtr ReportAckMsg.receive(TOS_MsgPtr m) {

    struct ReportAckMsg *msg = (struct ReportAckMsg *) m->data;

    call Leds.yellowToggle();
    
    /* this ack is not for me */
    if(msg->dest != TOS_LOCAL_ADDRESS)
      return m;

    tail =  bufferIndex;

    ackPending = FALSE;
    call WaitForAckTimer.stop();
    
    /* continue to send if there is more data in the buffer */
    if(tail != header ) {
      randomDelay = call Random.rand() % BACK_OFF_INTERVAL+20;
      call ReTransmissionTimer.start(TIMER_ONE_SHOT,randomDelay);          
      dbg(DBG_USR1,"Continue to send from %d to %d \n",tail,header);
    } else {
      reporting = FALSE;
    }

   
    return m;
  }

  /********************************************************/
  event TOS_MsgPtr RxConfigMsg.receive(TOS_MsgPtr m) {
    uint8_t i;
    struct ConfigMsg *Config = (struct ConfigMsg *)m->data;  
    uint8_t duplicated;
    
    atomic{
      switch(Config->type){
      case CONFIG_REQUEST:
	if(reporting == FALSE){
	  reporting = TRUE;	    
	  ReTxNumber = RETRANSMIT_NUMBER;
	  ReTxAckNumber = MAX_COUNT_ACK_RETRANS;
	  randomDelay = call Random.rand() % BACK_OFF_INTERVAL+20;
	  call ReTransmissionTimer.start(TIMER_ONE_SHOT, randomDelay);   
	}
	break;
	
      case CONFIG_CLEAR:
	for(i = 0 ; i < RAW_DATA_BATCH; i++){
	  RawDataBuffer[i] = 0;     
	}      		      	     
	break;
	
      case CONFIG_INIT:
	for(i = 0 ; i < RAW_DATA_BATCH; i++){
	  RawDataBuffer[i] = 0;     
	}  
	call samplingTimer.stop();
	call samplingTimer.start(TIMER_REPEAT,1);
	call ReTransmissionTimer.stop();
	call WaitForAckTimer.stop();
	//DetectionThreshold = DEFAULT_THRESHOLD;
	ackPending = FALSE;
	outBufferPending = FALSE;
	reporting = FALSE;
	header = tail = bufferIndex = 0;	     		      	     
	break;
	
      case CONFIG_RESTART:    
	call Reset.reset();
	break;
	
      case CONFIG_RECONFIG:
        call Leds.greenToggle();
	//call samplingTimer.stop();
	//call samplingTimer.start(TIMER_REPEAT, Config->samplingInterval);
	// Radu: configurability of DELTA seems to be more important
	delta = Config->samplingInterval;
	DetectionThreshold = Config->DetectionThreshold * 10;	
	header = tail = bufferIndex = 0;	     		      
	break;
	
      case CONFIG_STORE:
	call Leds.redOff(); 	  
	duplicated = FALSE;
	for(bufferIndex = tail; bufferIndex != header;
	    bufferIndex = (bufferIndex+1)%MAX_SCAN_NUMBER){
	  if(Config->ScanID == ScanID[bufferIndex]){
	    duplicated = TRUE;
	  }
	}
	
	//the buffer is not full	         
	if( (header+1)%MAX_SCAN_NUMBER != tail && !duplicated) {
	  if( DetectionThreshold < RawDataBuffer[hitIndex])          
	    MaxTimeStampBuffer[header]= TimeStampBuffer[hitIndex];
	  else {
	    MaxTimeStampBuffer[header]= 0;
	  }	         
	  ScanID[header]= Config->ScanID;
	  header = (header+1)%MAX_SCAN_NUMBER;	         
	  /* clear the content and ready for next scan */     
	  for(i = 0 ; i < RAW_DATA_BATCH; i++){
	    RawDataBuffer[i] = 0;   
	 	    	   	 	    	       
	  }
	  
	}

	  for(i = 0 ; i < RAW_DATA_BATCH; i++){
	    RawDataBuffer[i] = 0;
	  }

	break;
	
      default: break;
      }
    }
    return m; 	       
  }

  /********************************************************/
  event result_t WaitForAckTimer.fired() {     
    
    dbg(DBG_USR1, "WaitForAckTimer fired\n");
    if(ackPending) {
       call Leds.yellowToggle();
      ackPending = FALSE;

      if(ReTxAckNumber > 0) {
	ReTxAckNumber--;
	randomDelay = call Random.rand() % BACK_OFF_INTERVAL+20;	
	call ReTransmissionTimer.start(TIMER_ONE_SHOT, randomDelay);
      }
    }

    return SUCCESS;
  }

  /********************************************************/
  event result_t ReTransmissionTimer.fired() {     
     
    dbg(DBG_USR1,"ReTransmissionTimer fired\n");
     
    if(!(post dataTask()))
      call ReTransmissionTimer.start(TIMER_ONE_SHOT,200); 
            
    return SUCCESS;
  }
      

  /**
   * Signalled when the clock ticks.
   * @return The result of calling ADC.getData().
   */
  event result_t samplingTimer.fired() {
    return call ADC.getData();
  }

  /**
   * Signalled when the reset message counter AM is received.
   * @return The free TOS_MsgPtr. 
   */
  event TOS_MsgPtr ResetCounterMsg.receive(TOS_MsgPtr m) {
    atomic {
      readingNumber = 0;
    }
    return m;
  }
  

  uint8_t Calibration(uint16_t rawData){ return FALSE; }

  uint8_t RecordMaxValue(uint16_t rawData){      
    atomic{
      hitIndex = 0;

      if( DEFAULT_THRESHOLD < rawData) {
	if(ledCounter > 50) {
	  call Leds.redToggle();
	  ledCounter = 0;
	} else ledCounter++;
      }
      
      if(RawDataBuffer[hitIndex] + delta /*DELTA*/ < rawData){
	       
	//if(rawData > DetectionThreshold) call Leds.redOn();  
	       
	RawDataBuffer[hitIndex] = rawData;
	call GlobalTime.getGlobalTime(&(TimeStampBuffer[hitIndex]));
	TimeStampBuffer[hitIndex] = call GlobalTime.jiffy2ms(TimeStampBuffer[hitIndex]); 
	//call Leds.redToggle();      
      }
    }
    return SUCCESS;
  }
  

  /* whether sufficent data is collect to make a report */
  uint8_t Buffering(uint16_t rawData){ 
    
    uint8_t SelectionDone = FALSE;
    uint16_t MaxValue;
    uint8_t i;
    
    /* buffer RAW_DATA_BATCH number of data */
    atomic{
    
      if( rawDataIndex < RAW_DATA_BATCH){
	RawDataBuffer[rawDataIndex] = rawData;
	call GlobalTime.getGlobalTime(&(TimeStampBuffer[rawDataIndex]));
	TimeStampBuffer[rawDataIndex] = call GlobalTime.jiffy2ms(TimeStampBuffer[rawDataIndex]);  
	rawDataIndex++;
	SelectionDone = FALSE;
      }
     
      if(rawDataIndex == RAW_DATA_BATCH){
        rawDataIndex = 0;     
	MaxValue = RawDataBuffer[0];
        for(i = 1; i < RAW_DATA_BATCH;i++){
	  if(MaxValue <  RawDataBuffer[i]){
	    MaxValue = RawDataBuffer[i]; 
	    hitIndex = i;
	  }       
        }
        SelectionDone = TRUE;
      }
    } 
           
    return SelectionDone;
    
  }
  
  void show(uint8_t startValue, uint32_t delay, uint8_t endValue){
    call Leds.set(startValue);
    TOSH_uwait(delay);
    call Leds.set(endValue);     
  }    
}
