/* 
 * Author:		Josh Herbach
 *                      Robbie Adler
 * Revision:	1.0
 * Date:		09/02/2005
 */

#include "PXA27XUSBClient.h"
includes usb;
includes usbhid;

module PXA27XUSBClientM {
  provides {
    interface StdControl as StdControl;
  }
  uses {
    interface PXA27XGPIOInt as USBAttached;
    interface PXA27XInterrupt as USBInterrupt;
    interface HPLUSBClientGPIO;
    interface PXA27XDMAChannel as Endpoint1DMAChannel;
    interface PXA27XDMAChannel as Endpoint2DMAChannel;
  }
}
implementation {
#include "paramtask.h"

  ptrqueue_t outgoingControlQueue;
  ptrqueue_t outgoingQueue;

  void receiveDone(uint32_t arg);
  DEFINE_PARAMTASK(receiveDone); 

  task void sendDone();

  int GetDataFromEndpoint(uint8_t endpoint, uint8_t *pData, uint32_t numBytes);

  /*
   * resetState resets the USBClient control state.  This includes setting the state back to the init state
   * and flushing all queues
   */
  static void resetState();
  
  /*
   *flushOutgoingControlQueue flushes the data stored in the outgoingControlQueue;
   */  
  static void flushOutgoingControlQueue();

  /*
 * sendControlIn handles sending a queued control message.
 */
  static void sendControlIn(USBData_t *pUSBData);
  /*
   * handleControlSetupStage processes setup requests from the host PC.
   */
  task void handleControlSetupStageTask();

  /*
   * handleControlPacketComplete continues the processing of incomplete packets and cleans 
   * up after completed packets
   */
  task void handleControlPacketComplete();


  /*
   * isAttached() checks if the mote is attached over USB to a power source
   * (assumed to be a host PC).
   */
  void isAttached();

  
  USBDevice_t *gUSBDevicePtr;
  
  norace static uint8_t *gRxBuffer;
  norace static uint32_t gRxBufferNumBytes;

  norace static uint32_t state = 0; /*State of the USB device: either 0, POWERED,
			       DEFAULT, or CONFIGURED*/
  
  result_t configureUSBClient(){
    //number of configurations is stored in the device descriptor
    int configurations, interfaces, descriptors;
    int currentHWDescriptor = 1; //0 is reserved for control endpoint
    
    if(gUSBDevicePtr == NULL){
#if DEBUG
      trace(DBG_USR1,"USB DEVICE found invalid device structure\r\n"); 
#endif
      return FAIL;
    }
    
    for(configurations = 0; configurations < gUSBDevicePtr->deviceDescriptor.bNumConfigurations; configurations++){
      //traverse through each configuration...must have at least 2
      USBConfiguration_t *pConfiguration = gUSBDevicePtr->pUSBConfigurations[configurations]; 
      for(interfaces = 0;  interfaces < pConfiguration->configurationDescriptor.bNumInterfaces; interfaces++){
	USBInterface_t *pInterface = pConfiguration->pUSBInterfaces[interfaces];
	for(descriptors = 0; descriptors < pInterface->interfaceDescriptor.bNumEndpoints && pInterface->pEndpointDescriptors != NULL; descriptors++){
	  //need packet size, direction, type, endpoint #, interface #, config #
	  USBEndpointDescriptor_t *pEndpoint = &(pInterface->pEndpointDescriptors[descriptors]);
	  
	  UDCCR_X(currentHWDescriptor) =  UDCCRAX_EE |  UDCCRAX_DE | UDCCRAX_MPS(pEndpoint->wMaxPacketSize) | ((pEndpoint->bEndpointAddress & 0x80) ? UDCCRAX_ED: 0) | UDCCRAX_ET( (pEndpoint->bmAttributes) & 0x3) | UDCCRAX_EN(pEndpoint->bEndpointAddress & 0x3) | UDCCRAX_AISN(pInterface->interfaceDescriptor.bAlternateSetting) | UDCCRAX_IN(pInterface->interfaceDescriptor.bInterfaceID) | UDCCRAX_CN(pConfiguration->configurationDescriptor.bConfigurationValue);
	  //enable this endpoint for PC interrupts
	  //USB_ENABLE_ENDPOINT_IRQ(currentHWDescriptor,USBIRQ_PC);
	  //UDCCSR_X(currentHWDescriptor) = UDCCSRAX_DME;
	  currentHWDescriptor++;
	  
	  
	}
      }
    }
    return SUCCESS;
  }

  void resetState(){
    flushOutgoingControlQueue();
  }
  
  int USBHAL_isUSBConfigured() __attribute__((C,spontaneous)){
    
    uint32_t tempState;
    atomic{
      tempState = state;
    }
    
    return (tempState == CONFIGURED) ? 1:0;
  }
  
  command result_t StdControl.init() {
    static uint8_t init=0;
    
    
    CKEN |= CKEN_CKEN11;
    UDCCR = 0;
    UDCCRA = 0;
    UDCCRB = 0;
    UDCICR0 = 0;
    UDCICR1 = 0;

    //disable the main interrupt before we enable different interrupt sources 
    call USBInterrupt.disable();
        
    if(init == 0){//one time initilization because of allocated memory
      
      initptrqueue(&outgoingQueue, defaultQueueSize);
      initptrqueue(&outgoingControlQueue, defaultQueueSize);
      
      initializeUSBStack();
      //GET THE USBDevice_t!!!!
      gUSBDevicePtr = getUSBDevice();
      configureUSBClient();
      call USBInterrupt.allocate();
      //request a non-permanent channel
    }
    
    call HPLUSBClientGPIO.init();      
    
    UDCICR1 |= USBIRQ_RS;  //reset irq enabled     
    UDCICR1 |= USBIRQ_CC;  //change configuration irq enabled
      
    //need to enable the interrupts for our endpoints
    
    USB_ENABLE_ENDPOINT_IRQ(0,USBIRQ_PC);
    
    atomic{
      state = 0;
    }
    resetState();
    
    return SUCCESS;
  }
  
  task void isAttachedTask(){
    isAttached();
  }
  
  command result_t StdControl.start() {
    call USBInterrupt.enable();
    call USBAttached.enable(TOSH_BOTH_EDGE);
    
    post isAttachedTask();
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    call USBInterrupt.disable();
    call USBAttached.disable();
    atomic state = 0;
    return SUCCESS;
  }
  
  async event void USBAttached.fired()
  {
    post isAttachedTask();
    call USBAttached.clear();
  }
  
  task void printUSBIRQSourceError(){
    trace(DBG_USR1,"ERROR:  USBClient was interrupted but was not able to find the source!\r\n");
  }
  
  async event void USBInterrupt.fired(){
    uint32_t statusreg, udcisr0, udcisr1;
    uint32_t irqsource, endpointSource=0, endpointIrq=0;
    
    //save the interrupt source registers so that we accurately decode the source of this irq
    udcisr0 = UDCISR0;
    udcisr1 = UDCISR1;

#if DEBUG_INTERRUPT   
    trace(DBG_USR1,"Interrupt - UDCISRs: %#4.4x %#4.4x \r\n", udcisr1, udcisr0);
#endif

    //figure out which USB interrupt caused this interrupt
    //there are 6 major options...1 of the first 5 irq sources or one of the endpoint source
    if(udcisr1 & USBIRQ_CC){
      //configuration change
      UDCISR1 = USBIRQ_CC;  //clear the CC interrupt
      irqsource = USBIRQ_CC;
    }
    else if(udcisr1 & USBIRQ_SOF){
      //Start of Frame
      UDCISR1 = USBIRQ_SOF;  //clear the interrupt
      irqsource = USBIRQ_SOF;
    }
    else if(udcisr1 & USBIRQ_RU){
      //resume
      UDCISR1 = USBIRQ_RU;  //clear the interrupt
      irqsource = USBIRQ_RU;
    }
    else if(udcisr1 & USBIRQ_SU){
      //suspend
      UDCISR1 = USBIRQ_SU;  //clear the interrupt
      irqsource = USBIRQ_SU;
    }
    else if(udcisr1 & USBIRQ_RS){
      //reset
      UDCISR1 = USBIRQ_RS;  //clear the interrupt
      irqsource = USBIRQ_RS;
      resetState();
      state = DEFAULT;
      return;
    }
    else{
      //must be one of the endpoint sources...let the code later on clear it because it's encoded
      irqsource = 0; //use 0 for an endpoint
      if(udcisr1){
	//a descriptor in udcisr1 caused this interrupt
	endpointSource = ((31 - _pxa27x_clzui(udcisr1)) >> 1)+16;
	endpointIrq = USB_GET_ENDPOINT_IRQ(endpointSource);
	UDCISR(endpointSource) = endpointIrq << USB_IRQ_OFFSET(endpointSource);
      }
      else if(udcisr0){
	//a descriptor in udcisr0 caused this interrupt
	endpointSource = ((31 - _pxa27x_clzui(udcisr0)) >> 1);
	endpointIrq = USB_GET_ENDPOINT_IRQ(endpointSource);
	UDCISR(endpointSource) = endpointIrq << USB_IRQ_OFFSET(endpointSource);
      }
      else{
	//MAJOR ISSUE....we got interrupted without finding the source!!!
	post printUSBIRQSourceError();
	return;
      }
    }
    
    switch(irqsource){
    case USBIRQ_CC:
      post handleControlSetupStageTask();
      break;
    case 0:
      //we got an interrupt from some endpoint
      switch(endpointSource){
	
      case 0:
	statusreg = UDCCSR0;
	if(statusreg & UDCCSR0_SA){
	  post handleControlSetupStageTask();
	}
	else{
	  post handleControlPacketComplete();
	}
	break;
	
      default:
	//trace(DBG_USR1,"interrupt %#x from endpoint %d\r\n",endpointIrq,endpointSource);
	  
	break;
      }
      break;
    default:
      //unexpected state
      break;
    }
  }
  
  
  task void handleControlPacketComplete(){
    int controlQueueStatus;
    
    USBData_t *pUSBData = peekptrqueue(&outgoingControlQueue, &controlQueueStatus);
    
    if(controlQueueStatus == 0){
      //this is most likely expected...it will depend on context
#if DEBUG_CONTROL_ENDPOINT      
      trace(DBG_USR1,"USBClient.handleControlPacketComplete found no queued data\r\n");
#endif      
      return;
    }
        
    if(pUSBData->index == pUSBData->len){
      //if this packet has completely been sent, we free it's resources
#if DEBUG_CONTROL_ENDPOINT
      trace(DBG_USR1,"control packet send complete\r\n");
#endif      
      if((pUSBData->index) % (pUSBData->fifosize) == 0){
	//need to handle the special case where we need to send a 0-length data packet
	UDCCSR0 = UDCCSR0_IPR;
      }
      pUSBData = popptrqueue(&outgoingControlQueue, &controlQueueStatus);
      free(pUSBData->src);
      free(pUSBData);
    } 
    else if(pUSBData->index < pUSBData->len){
      //if the packet still has data left to send...we continue sending it
#if DEBUG_CONTROL_ENDPOINT 
     trace(DBG_USR1,"continuing control packet send\r\n");          
#endif 
     sendControlIn(pUSBData);
    }
    else{
      //invalid state...free resources and report the error
      trace(DBG_USR1,"ERROR:  USBClient.handleControlPacketComplete found invalid state in queued data\r\n");
      //pop the data out of the queue
      trace(DBG_USR1,"control packet send complete\r\n");
      pUSBData = popptrqueue(&outgoingControlQueue, &controlQueueStatus);
      free(pUSBData->src);
      free(pUSBData);
    }
  }

  task void handleControlSetupStageTask(){
    USBSetupDataUnion_t setupData;
  
    //clearIn();
      
    //packet is always 8 bytes....read it into our union
    setupData.rawData[0] = UDCDR0;
    setupData.rawData[1] = UDCDR0;
  
    //#if DEBUG
#if 0
    trace(DBG_USR1,"hCS; bmRequestType=%#x bRequest=%#x, wValue=%#x, wIndex=%#x, wLength=%#x\r\n", 
	  setupData.USBSetupData.bmRequestType,
	  setupData.USBSetupData.bRequest,
	  setupData.USBSetupData.wValue,
	  setupData.USBSetupData.wIndex,
	  setupData.USBSetupData.wLength);
#endif
    
    UDCCSR0 = UDCCSR0_OPC;
    UDCCSR0 = UDCCSR0_SA; 
 
    handleControlSetupStage(&(setupData.USBSetupData));
  }
 
  void USBHAL_sendControlDataToHost(USBData_t *pUSBData) __attribute__((C,spontaneous)){
    //save the data structure in the outgoing control queue.  This is necessary because it might take
    //multiple transactions to transfer our data.  
    if(pushptrqueue(&outgoingControlQueue, pUSBData) == 0){
      trace(DBG_USR1,"ERROR:  USBClient.SendDeviceDescriptor found outgoingControlQueue full\r\n");
      free(pUSBData->src);
      free(pUSBData);
      return;
    }
    
    sendControlIn(pUSBData);
  }
  
  void sendControlIn(USBData_t *pUSBData){
    uint16_t i = 0;
    int controlQueueStatus;
    
    assert(pUSBData);
    
    while( (pUSBData->index < pUSBData->len) && (i < pUSBData->fifosize)){
      if(((pUSBData->len - pUSBData->index) > 3) && ((pUSBData->fifosize - i) > 3)){
	UDCDR0 = *(uint32_t *)(pUSBData->src + pUSBData->index);
	pUSBData->index += 4;
	i += 4;
      }
      else{
	UDCDR0_8 = *(pUSBData->src + pUSBData->index);
	pUSBData->index++;
	i++;
      }
    }
    
    //the usb hardware automatically sends the packet if it fifosize bytes long.  
    //If it is smaller, we must set IPR
    
    if(i<pUSBData->fifosize){
      UDCCSR0 = UDCCSR0_IPR;
    }
    
    if(pUSBData->index == pUSBData->len){
      //if this packet has completely been sent, we free it's resources
#if DEBUG_CONTROL_ENDPOINT      
      trace(DBG_USR1,"control packet send complete\r\n");
#endif
      if( (pUSBData->index) % (pUSBData->fifosize) == 0){
      //exception.  If we're done, and the last packet sent is a multiple
      // of the fifo size, we must send a 0 length packet at the end
      
#if DEBUG_CONTROL_ENDPOINT
	trace(DBG_USR1,"expecting to continue control packet send with 0 length data packet\r\n");          
#endif
      }
      else{
	pUSBData = popptrqueue(&outgoingControlQueue, &controlQueueStatus);
	free(pUSBData->src);
	free(pUSBData);
      } 
    }
    else if(pUSBData->index < pUSBData->len){
      //if the packet still has data left to send...we continue sending it
#if DEBUG_CONTROL_ENDPOINT
      trace(DBG_USR1,"expecting to continue control packet send\r\n");          
#endif
    }
    else{
      //invalid state...free resources and report the error
      trace(DBG_USR1,"ERROR:  USBClient.handleControlPacketComplete found invalid state in queued data\r\n");
      //pop the data out of the queue
#if DEBUG_CONTROL_ENDPOINT
      trace(DBG_USR1,"control packet send complete\r\n");
#endif      
      pUSBData = popptrqueue(&outgoingControlQueue, &controlQueueStatus);
      free(pUSBData->src);
      free(pUSBData);
    }
  }  
  
  int USBHAL_sendDataToEndpoint(uint8_t endpoint, uint8_t *pData, uint32_t numBytes) __attribute__((C, spontaneous)){
    numBytes=64;
    call Endpoint1DMAChannel.setSourceAddr((uint32_t)pData);
    call Endpoint1DMAChannel.setTargetAddr((0x40600300) + endpoint * 4);
    call Endpoint1DMAChannel.enableSourceAddrIncrement(TRUE);
    call Endpoint1DMAChannel.enableTargetAddrIncrement(FALSE);
    call Endpoint1DMAChannel.enableSourceFlowControl(FALSE);
    call Endpoint1DMAChannel.enableTargetFlowControl(TRUE);
    call Endpoint1DMAChannel.setTransferLength(numBytes);
    call Endpoint1DMAChannel.setMaxBurstSize(DMA_8ByteBurst);
    call Endpoint1DMAChannel.setTransferWidth(DMA_4ByteWidth);
    
    UDCCSR_X(endpoint) = UDCCSRAX_DME;
    
    call Endpoint1DMAChannel.requestChannel(DMAID_USB_END0+endpoint,DMA_Priority3 | DMA_Priority4, FALSE); 
    
    return 1;
  }
  
  event result_t Endpoint1DMAChannel.requestChannelDone(){
    call Endpoint1DMAChannel.run(DMA_ENDINTEN);
    return SUCCESS;
  }
  
  async event void Endpoint1DMAChannel.startInterrupt(){
    
    return;
  }

  async event void Endpoint1DMAChannel.stopInterrupt(uint16_t numBytesSent){
    
    //we're done!
    return;
  }
  async event void Endpoint1DMAChannel.eorInterrupt(uint16_t numBytesSent){
    
    return;
  }

  task void sendDone(){
    sendDataToEndpointDone(1);
  }

  
  async event void Endpoint1DMAChannel.endInterrupt(uint16_t numBytesSent){
    if(numBytesSent < 64){
      //set short packet
      UDCCSR_X(1) = UDCCSRAX_SP;
    }
    post sendDone();
    
    return;
  }

  int GetDataFromEndpoint(uint8_t endpoint, uint8_t *pData, uint32_t numBytes){
    UDCCSR_X(endpoint) = UDCCSRAX_DME;
    call Endpoint2DMAChannel.setSourceAddr((0x40600300) + endpoint * 4);
    call Endpoint2DMAChannel.setTargetAddr((uint32_t)pData);
    call Endpoint2DMAChannel.enableSourceAddrIncrement(FALSE);
    call Endpoint2DMAChannel.enableTargetAddrIncrement(TRUE);
    call Endpoint2DMAChannel.enableSourceFlowControl(TRUE);
    call Endpoint2DMAChannel.enableTargetFlowControl(FALSE);
    call Endpoint2DMAChannel.setTransferLength(numBytes);
    call Endpoint2DMAChannel.setMaxBurstSize(DMA_32ByteBurst);
    call Endpoint2DMAChannel.setTransferWidth(DMA_4ByteWidth);
    
    call Endpoint2DMAChannel.requestChannel(DMAID_USB_END0+endpoint,DMA_Priority3 | DMA_Priority4, FALSE); 
    
    return 1;
  }
  
  event result_t Endpoint2DMAChannel.requestChannelDone(){
    call Endpoint2DMAChannel.run(DMA_ENDINTEN);
    return SUCCESS;
  }
  
  async event void Endpoint2DMAChannel.startInterrupt(){
    
    return;
  }

  void receiveDone(uint32_t arg){
    bufferInfo_t *pBI = (bufferInfo_t *)arg;
    if(pBI == NULL){
      return;
    }
   
    invalidateDCache(pBI->pBuf, pBI->numBytes);
    receiveDataFromEndpoint(2, pBI);
  }

  async event void Endpoint2DMAChannel.stopInterrupt(uint16_t numBytesSent){
    return;
  }
  
  async event void Endpoint2DMAChannel.eorInterrupt(uint16_t numBytesSent){
    
    return;
  }
  
  async event void Endpoint2DMAChannel.endInterrupt(uint16_t numBytesSent){
    
    bufferInfo_t *pBI = getNewBufferInfoForEndpoint(2);
    uint8_t *newBuffer = getNewBufferForEndpoint(2);
    assert(pBI);

    if(newBuffer){
      //we want to do another read of gRxNumBytes)
      //we should still have our DMA channel, so just all set size and run!
      call Endpoint2DMAChannel.setTargetAddr((uint32_t)newBuffer);
      call Endpoint2DMAChannel.setTransferLength(gRxBufferNumBytes);
      call Endpoint2DMAChannel.run(DMA_ENDINTEN);  
    }
    
    pBI->pBuf = gRxBuffer;
    pBI->numBytes = gRxBufferNumBytes;
    POST_PARAMTASK(receiveDone,pBI);
        
    gRxBuffer = newBuffer;
        
    return;
  }


  void isAttached(){
   
    if(call HPLUSBClientGPIO.checkConnection() == SUCCESS){
#if DEBUG
      uint32_t tempState;
      atomic{
	tempState = state;
      }
      trace(DBG_USR1,"Device Attached and Powered %d;\r\n", tempState);
#endif
      //enable the USB Client
      UDCCR |= UDCCR_UDE;
     
      //make sure that we don't have an configuration error
      if((UDCCR & UDCCR_EMCE) != 0){
#if DEBUG
	trace(DBG_USR1,"Memory Configuration Issue");
#else
	;
#endif
      }
      atomic state = POWERED;
    }
    else{
      trace(DBG_USR1,"Device Removed;\r\n");
      //clearIn();
      //clearOut();
      UDCCR &= ~UDCCR_UDE;
      atomic state = 0;
    }
  }
 

  void flushOutgoingControlQueue(){
    
    int controlQueueStatus;
    USBData_t *pUSBData;
    
    do{
      pUSBData = popptrqueue(&outgoingControlQueue, &controlQueueStatus);
      if( (controlQueueStatus == 1) && (pUSBData != NULL) ){
	free(pUSBData->src);
	free(pUSBData);
      }
    }
    while(controlQueueStatus);
  }

  void USBHAL_enableConfiguration(uint8_t configNum) __attribute__((C,spontaneous)){
    UDCCR |= UDCCR_SMAC;
    
    while(UDCCR & UDCCR_SMAC){
      //spin while the HW reconfigures memory
      ;
    }
    
    if((UDCCR & UDCCR_EMCE) == 0){
      uint8_t *newBuffer;
      atomic state = CONFIGURED;
      newBuffer =  getNewBufferForEndpoint(2);
      if(newBuffer){
	atomic{
	  gRxBuffer = newBuffer;
	  gRxBufferNumBytes = 64;
	  GetDataFromEndpoint(2, gRxBuffer, gRxBufferNumBytes);
	}
      }
    }
    else{
#if DEBUG
      trace(DBG_USR1,"Error: Memory configuration\r\n");
#else
      ;
#endif     
    }
  }

  void USBHAL_sendStall() __attribute__((C,spontaneous)){
    UDCCSR0 = UDCCSR0_FST;
  }

}
