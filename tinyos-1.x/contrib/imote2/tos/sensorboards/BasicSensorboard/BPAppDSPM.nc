#define NUM_DSP_CHANNELS (2)

module BPAppDSPM{

  provides {
    interface StdControl;
    interface BulkTxRx[uint8_t instance] as ProcessedData;
    interface DSPManager[uint8_t instance];
  }
  uses {
    interface BulkTxRx[uint8_t instance] as Data;
  }
}
implementation {
#include "postprocessingFunctions.h"

  vibStates_t gVibStates[NUM_DSP_CHANNELS];

  result_t parseTypeValItem(vibStates_t *vs,sampleHeader_t *psh,TypeValItem* paramList, uint16_t whichFunction);
  result_t parsePostProcessingFunction(vibStates_t *vs, sampleHeader_t *sh,TypeValItem *paramList,uint32_t function);
  
  
  command result_t StdControl.init() {
      return SUCCESS;
  }
 
  command result_t StdControl.start() {
        
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t DSPManager[uint8_t instance].initPostProcessing(uint8_t channel, 
							  uint32_t samplingRate, 
							  uint32_t numSamples, 
							  uint8_t sampleWidth, 
							  bool streaming, 
							  uint32_t warmup, 
							  uint32_t type, 
							  uint32_t function, 
							  TypeValItem *other){
    
    trace(DBG_USR1,"initVibration:  NumOutputPts=%d NumCaptPts=%d\r\n",
	  gVibState[instance].NumOutputPts, gVibState[instance].NumCaptPts);
    initVibration(&gVibStates[instance], 1);
    trace(DBG_USR1,"initVibration:  NumRtCaptPts=%d ResampFactor=%f\r\n",
	  gVibState[instance].NumRtCaptPts, gVibState[instance].ResampFactor);
    
    return FAIL;
  }
  
  command result_t DSPManager.isSupportedFunction[uint8_t instance](uint32_t function){
    
  }

  command result_t DSPManager.getDataStorageSize(uint32_t *requestedSize, uint32_t *minimumSize){

  }
    
  command result_t ProcessedData.BulkTxRx[uint8_t instance](BulkTxRxBuffer_t *TxRxBuffer, uint16_t NumBytes){
    return FAIL;
  }
  command result_t ProcessedData.BulkTransmit[uint8_t instance](uint8_t *TxBuffer, uint16_t NumBytes){
    return FAIL;
  }
  command result_t ProcessedData.BulkReceive[uint8_t instance](uint8_t *RxBuffer, uint16_t NumBytes){
    return FAIL;
  }
  
 
  async event uint8_t *Data.BulkReceiveDone[uint8_t instance](uint8_t *RxBuffer, uint16_t NumBytes){
    return NULL;
  }
    
  async event uint8_t *Data.BulkTransmitDone[uint8_t instance](uint8_t *TxBuffer, uint16_t NumBytes){
    return NULL;
  }

  async event BulkTxRxBuffer_t *Data.BulkTxRxDone[uint8_t instance](BulkTxRxBuffer_t *TxRxBuffer, uint16_t NumBytes){
    return NULL;
  }

  
  result_t parsePostProcessingFunction(vibStates_t *vs, sampleHeader_t *sh, TypeValItem *paramList,uint32_t function){
       
    //make sure that things are zero'd out to help prevent again left over state and for cleanness below
    vs->FftFlag = 0;
    vs->GseFlag = 0;
    vs->Navg = 1;  //default to 1....0 and 1 averages are the same...but postprocessing code is broken at 0

    switch(GET_SPECTRUM_CALC(function)){
    case SPECTRUM_NONE:
      break;
    case SPECTRUM_FFT:
      trace(DBG_USR1,"doing FFT\r\n");
      vs->FftFlag = 1;
      vs->GseFlag = 0;
      //get FFT parameters...this will fill in NumOutputPoints
      parseTypeValItem(vs,sh,paramList,FI_FUNCTION_FFT);
      parseTypeValItem(vs,sh,paramList,FI_FUNCTION_AVG);
      
      vs->WinFunc = GET_WINDOW_CALC(function);
      if(vs->WinFunc > 2){
	trace(DBG_USR1,"WARNING:  GenericSampling.prepare passed unknown window function %d...defaulting to rect%d\r\n",
	      GET_WINDOW_CALC(function));
	vs->WinFunc = WIN_RECTANGULAR;
      }
    
      break;
    case SPECTRUM_GSE:
      vs->FftFlag = 1;
      vs->GseFlag = 1;
      //get GSE parameters...this will fill in NumOutputPoints and the filterfrequency
      parseTypeValItem(vs,sh,paramList,FI_FUNCTION_GSE);
      //this will fil in the number of averages
      parseTypeValItem(vs,sh,paramList,FI_FUNCTION_AVG);
      vs->NumCaptPts = vs->NumOutputPts*2.56;
      vs->WinFunc = GET_WINDOW_CALC(function);
      if(vs->WinFunc > 2){
	trace(DBG_USR1,"WARNING:  GenericSampling.prepare passed unknown window function %d...defaulting to rect%d\r\n",
	      GET_WINDOW_CALC(function));
	vs->WinFunc = WIN_RECTANGULAR;
      }
      
      break;
    default:
      trace(DBG_USR1,"WARNING:  GenericSampling.prepare postprocessing function contains invalid SpectrumCalc %d\r\n",
	    GET_SPECTRUM_CALC(function));
    } 
    return SUCCESS;
  }
#endif 
  
  result_t parseTypeValItem(vibStates_t *vs,sampleHeader_t *sh,TypeValItem* paramList, uint16_t whichFunction){
    
    int i;
    for(i=0; i<paramList->count;i++){
      switch(paramList->functionInfo[i].function){
      case FI_FUNCTION_BOARD:
	if(whichFunction == FI_FUNCTION_BOARD){
	  default:
	    break; //ignore FI_FUNCTION_BOARD parameters here
	  }
	}
	break;
      case FI_FUNCTION_FFT:
	if(whichFunction == FI_FUNCTION_FFT){
	  if(vs==NULL){
	    trace(DBG_USR1,"ASSERT:  GenericSampling.parseTypeValItem passed NULL VibrationState pointer\r\n");
	    return FAIL;
	  }
	  if(sh==NULL){
	    trace(DBG_USR1,"ASSERT:  GenericSampling.parseTypeValItem passed NULL SamplingHeader pointer\r\n");
	    return FAIL;
	  }
	  switch(paramList->functionInfo[i].paramname) {
	  case FIF_FFT_NUMOUTPUTSAMPLES:
	    vs->NumOutputPts = paramList->functionInfo[i].paramval;
	    sh->numSamples = paramList->functionInfo[i].paramval;
	    trace(DBG_USR1,"FFT will have %d outputpoints\r\n",vs->NumOutputPts);
	    break;
	  default:
	  }
	}
	break;
      case FI_FUNCTION_GSE:
	if(whichFunction == FI_FUNCTION_GSE){
	  if(vs==NULL){
	    trace(DBG_USR1,"ASSERT:  GenericSampling.parseTypeValItem passed NULL vibStates pointer\r\n");
	    return FAIL;
	  }
	  if(sh==NULL){
	    trace(DBG_USR1,"ASSERT:  GenericSampling.parseTypeValItem passed NULL sampleHeader pointer\r\n");
	    return FAIL;
	  }
	  switch(paramList->functionInfo[i].paramname) {
	  case FIF_GSE_FILTERFREQ:
	    trace(DBG_USR1,"WARNING:  GenericSampling.prepare unable to utilize filterfreq %d for gSE measurement\r\n",
		  paramList->functionInfo[i].paramval);
	    sh->gSEFilterType = paramList->functionInfo[i].paramval;
	    break;
	  default:
	  }
	}
	break;
      case FI_FUNCTION_AVG:
	if(whichFunction == FI_FUNCTION_AVG){
	  if(vs==NULL){
	    trace(DBG_USR1,"ASSERT:  GenericSampling.parseTypeValItem passed NULL SamplingHeader pointer\r\n");
	    return FAIL;
	  }
	  switch(paramList->functionInfo[i].paramname) {
	  case FIF_AVG_NUMAVERAGES:
	    vs->Navg = paramList->functionInfo[i].paramval;
	    trace(DBG_USR1,"PostProcessing will do %d averages\r\n",vs->Navg);
	    break;
	  default:
	  }
	}
	break;
      default:
	trace(DBG_USR1,"WARNING:  GenericSampling.prepare passed unknown TypeValItem.functionInfo[i].function");
      }
      
    }
    return SUCCESS;
  }

}
