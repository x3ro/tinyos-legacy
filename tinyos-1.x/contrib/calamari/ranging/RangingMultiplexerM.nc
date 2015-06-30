includes LocalizationConfig;

module RangingMultiplexerM
{
  provides interface RangingTransmitter;
  provides interface RangingReceiver;
  
  uses interface RangingTransmitter as RSSIRangingTransmitter;
  uses interface RangingReceiver as RSSIRangingReceiver;
  uses interface RangingTransmitter as UltrasoundRangingTransmitter;
  uses interface RangingReceiver as UltrasoundRangingReceiver;
}
implementation
{
  
  command result_t RangingTransmitter.send(uint16_t rangingId,
					   uint8_t rangingBatchNumber,
					   uint8_t rangingSequenceNumber,
					   bool initiateRangingSchedule) {
    if(G_Config.rangingTech == RSSI)
      return call RSSIRangingTransmitter.send(rangingId,
					      rangingBatchNumber,
					      rangingSequenceNumber,
					      initiateRangingSchedule);
    //    else if(G_Config.rangingTech == ULTRASOUND)
      //mica2      return call UltrasoundRangingTransmitter.send(rangingId,
      //						    rangingBatchNumber,
      //						    rangingSequenceNumber,
      //						    initiateRangingSchedule);
    else return FAIL; 
  }

  command result_t RangingTransmitter.cancel(){
    if(G_Config.rangingTech == RSSI)
      return call RSSIRangingTransmitter.cancel();
    //    else if(G_Config.rangingTech == ULTRASOUND)
      //mica2      return call UltrasoundRangingTransmitter.cancel();
    else return FAIL; 
  }

  event void RSSIRangingTransmitter.sendDone(result_t success) {
    if(G_Config.rangingTech == RSSI)
      signal RangingTransmitter.sendDone(success);
  }

  event void UltrasoundRangingTransmitter.sendDone(result_t success) {
    if(G_Config.rangingTech == ULTRASOUND)
      signal RangingTransmitter.sendDone(success);
  }

  event result_t RSSIRangingReceiver.receive(uint16_t actuator,
					     uint16_t receivedRangingId,
					     uint16_t batchNumber,
					     uint16_t sequenceNumber) {
    if(G_Config.rangingTech == RSSI)
      return signal RangingReceiver.receive(actuator,
					    receivedRangingId,
					    batchNumber,
					    sequenceNumber);
    else
      return FAIL;
  }

  event result_t UltrasoundRangingReceiver.receive(uint16_t actuator,
						   uint16_t receivedRangingId,
						   uint16_t batchNumber,
						   uint16_t sequenceNumber) {
    if(G_Config.rangingTech == ULTRASOUND)
      return signal RangingReceiver.receive(actuator,
					    receivedRangingId,
					    batchNumber,
					    sequenceNumber);
    else
      return FAIL;
  }

  uint16_t ultrasoundLinearCalibration(uint16_t distance){
    /**  distance*scale - bias **/
    uint16_t scaledDistance = distance*G_Config.ultrasoundRangingScale;
    return scaledDistance>G_Config.ultrasoundRangingBias ?
      scaledDistance-G_Config.ultrasoundRangingBias : 0;
  }

  uint16_t RSSILinearCalibration(uint16_t distance){
    /**  distance*scale - bias **/
    uint16_t scaledDistance = distance*G_Config.RSSIRangingScale;
    return scaledDistance>G_Config.RSSIRangingBias ?
      scaledDistance-G_Config.RSSIRangingBias : 0;
  }
  
  event void RSSIRangingReceiver.receiveDone(uint16_t actuator,
					     uint16_t receivedRangingId,
					     uint16_t distance,
					     bool initiateRangingSchedule) {
    distance = RSSILinearCalibration(distance);
    if(G_Config.rangingTech == RSSI)
      signal RangingReceiver.receiveDone(actuator,
					 receivedRangingId,
					 distance,
					 initiateRangingSchedule);
  }
  
  event void UltrasoundRangingReceiver.receiveDone(uint16_t actuator,
						   uint16_t receivedRangingId,
						   uint16_t distance,
						   bool initiateRangingSchedule) {   
    distance = ultrasoundLinearCalibration(distance);
    if(G_Config.rangingTech == ULTRASOUND)
      signal RangingReceiver.receiveDone(actuator,
					 receivedRangingId,
					 distance,
					 initiateRangingSchedule);
  }
}
