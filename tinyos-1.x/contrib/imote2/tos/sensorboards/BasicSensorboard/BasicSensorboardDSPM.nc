
module BasicSensorboardDSPM{

  provides {
    interface StdControl;
    interface BulkTxRx as ProcessedData;
    interface DSPManager;
  }
  uses {
    interface SSP;
    interface BulkTxRx as AccelData;
    interface PXA27XGPIOInt as RDYInterrupt;
  }
}
implementation {
    
  command result_t StdControl.init() {
      return SUCCESS;
  }
 
  command result_t StdControl.start() {
        
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t ProcessedData.BulkTxRx(BulkTxRxBuffer_t *TxRxBuffer, uint16_t NumBytes){
    return FAIL;
  }
  command result_t ProcessedData.BulkTransmit(uint8_t *TxBuffer, uint16_t NumBytes){
    return FAIL;
  }
  command result_t ProcessedData.BulkReceive(uint8_t *RxBuffer, uint16_t NumBytes){
    return FAIL;
  }
  
 
  async event uint8_t *AccelData.BulkReceiveDone(uint8_t *RxBuffer, uint16_t NumBytes){
    return NULL;
  }
    
  async event uint8_t *AccelData.BulkTransmitDone(uint8_t *TxBuffer, uint16_t NumBytes){
    return NULL;
  }

  async event BulkTxRxBuffer_t *AccelData.BulkTxRxDone(BulkTxRxBuffer_t *TxRxBuffer, uint16_t NumBytes){
    return NULL;
  }
}
