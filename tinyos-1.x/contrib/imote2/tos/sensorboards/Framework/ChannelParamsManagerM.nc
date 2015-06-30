/**
 *@author Robbie Adler
 **/
#include "frameworkconfig.h"

module ChannelParamsManagerM {
  provides{
    
    interface StdControl;
    interface ChannelParamsManager[uint8_t instance];
  }
}

implementation{
  
#include "postprocessingFunctions.h"
#include "sampleHeader.h"

#define SAMPLEHEADER_UNUSED(sampleheader) (sampleheader->channelId == INVALID_CHANNEL_ID)
  
  /********
   *this module is completely dependent on the SampleHeader_t structure.  If it changes, all  
   *code-level changes should be isolated to this module
   *
   **********/
  sampleHeader_t gSampleHeaders[TOTAL_DATA_CHANNELS];
   
  result_t parseTypeValItem(sampleHeader_t *psh,TypeValItem* paramList, uint16_t whichFunction);
  result_t parsePostProcessingFunction(sampleHeader_t *sh,TypeValItem *paramList,uint32_t function);

  command result_t StdControl.init(){
    int i;

    for(i=0; i<TOTAL_DATA_CHANNELS; i++){
      //initialize our sampleInfo_t structures so that their channelId's are invalid
      gSampleHeaders[i].channelId = INVALID_CHANNEL_ID;
    }
    return SUCCESS;
  }
  
  command result_t StdControl.start(){
  
    return SUCCESS;
  }

  command result_t StdControl.stop(){
  
    return SUCCESS;
  }
  
  result_t getDataChannelFromSensorType(uint8_t channel, uint32_t type, uint8_t *phyChannel)  {
    const supportedCommonFeatureList32_t *feature;
        
    feature = channelCapabilitiesTable[channel].supportedSensorTypes;
    if((feature != NULL) && (phyChannel != NULL)){
      *phyChannel=feature->commonFeature;
      return SUCCESS;
    }
    return FAIL;
  }  
  
  result_t getParameterStorage(uint8_t channel, sampleHeader_t **ppSh, uint8_t dataChannel){
    
    if(channel >= TOTAL_CHANNELS){
      return FAIL;
    }
    if(ppSh == NULL){
      return FAIL;
    }
    
    *ppSh = &(gSampleHeaders[dataChannel]);
    if(SAMPLEHEADER_UNUSED((*ppSh))){
      //found one that is unused!!
      return SUCCESS;
    }
    else{
      if((*ppSh)->channelId == channel){
	//we've already prepared this channel set...print a warning message...but allow the prepare to be overwritten
	trace(DBG_USR1,"Warning:  GenericSampling.prepare used on existing prepared channel...overwriting config\r\n");
	return SUCCESS;
      }
    }
    trace(DBG_USR1,"FAIL:  GenericSampling.prepare has exceeded its simultaneous channel limit\r\n");
    *ppSh = NULL;
    return FAIL;
  }
  
  command size_t ChannelParamsManager.getHeaderSize[uint8_t instance](){
    return sizeof(sampleHeader_t);
  }
  
  command result_t ChannelParamsManager.storeParams[uint8_t instance](uint8_t channel,
								      uint32_t samplingRate, 
								      uint32_t numSamples, 
								      uint8_t sampleWidth, 
								      bool streaming, 
								      uint32_t type, 
								      uint32_t function, 
								      TypeValItem *other){
    sampleHeader_t *sh;
    
    if(instance >= TOTAL_DATA_CHANNELS){
      return FAIL;
    }
    
    if(getParameterStorage(channel, &sh, instance) == FAIL){
      return FAIL;
    }
    trace(DBG_USR1,"Info:  StoringParameters for data channel %d\r\n",instance);

    //we should have previous done all of our error checking..start filling in fields

    sh->channelId = channel; 		/* channelId generating the sample.  This is VirtualChannel */
    sh->samplingRate = samplingRate;	/* Rate at which samples are taken */
    sh->totalSamples = numSamples; 	        /* Time: numSamples, FFT on mote: numOfLines */
    sh->sampleWidth = sampleWidth;        /* bit width of sample data used for parsing sample body */
    //sh->samplePadding = need to fill out based on a table of values;
    sh->sensorType = type;	        /* sensorType */
    sh->function = function;		/* post processing function applied to data. */  
        
    //fill out the misc fields of the sampleheader
    if(parseTypeValItem(sh,other,FI_FUNCTION_BOARD) != SUCCESS){
      return FAIL;
    }
    if(parsePostProcessingFunction(sh,other,function) != SUCCESS){
      return FAIL;
    }
        
    return SUCCESS;
    
  }
    
  //sadly, this module needs to be aware of the postProcessingFunction because some parts of our sampleHeader are
  //determined from the postProcessingFunction.  Since this module is responsible for maintaining the sampleHeader,
  //it is responsible for parsing the postProcessingFunction and the TypeValItem list to pull out fields required
  //by the sampleHeader
  result_t parsePostProcessingFunction(sampleHeader_t *sh, TypeValItem *paramList,uint32_t function){
    sh->gSEFilterType = 0; //initialize
        
    switch(GET_SPECTRUM_CALC(function)){
    case SPECTRUM_NONE:
      break;
    case SPECTRUM_FFT:
          //get FFT parameters...this will fill in NumOutputPoints
      parseTypeValItem(sh,paramList,FI_FUNCTION_FFT);
      parseTypeValItem(sh,paramList,FI_FUNCTION_AVG);
      break;
    case SPECTRUM_GSE:
      parseTypeValItem(sh,paramList,FI_FUNCTION_GSE);
      //this will fil in the number of averages
      parseTypeValItem(sh,paramList,FI_FUNCTION_AVG);
      break;
    default:
      trace(DBG_USR1,"WARNING:  GenericSampling.prepare postprocessing function contains invalid SpectrumCalc %d\r\n",
	    GET_SPECTRUM_CALC(function));
    } 
    return SUCCESS;
  }
  
  result_t parseTypeValItem(sampleHeader_t *sh,TypeValItem* paramList, uint16_t whichFunction){
    
    int i;

    if(sh==NULL){
      trace(DBG_USR1,"ASSERT:  GenericSampling.parseTypeValItem passed NULL SamplingHeader pointer\r\n");
      return FAIL;
    }
    
    for(i=0; i<paramList->count;i++){
      switch(paramList->functionInfo[i].function){
      case FI_FUNCTION_BOARD:
	if(whichFunction == FI_FUNCTION_BOARD){
	  switch(paramList->functionInfo[i].paramname) {
	  case FIF_BOARD_LOGICALNODEID:	/* Intel logical nodeId, mote generating sample*/
	    sh->logicalNodeId = paramList->functionInfo[i].paramval;
	    break;
	  case FIF_BOARD_QUERYGROUPID:  	/* UniqueId of the query group being satisfied by this sample record */
	    sh->queryGroupId=paramList->functionInfo[i].paramval;
	    break;	    
	  case FIF_BOARD_ACQUISITIONNUM:/* Ordinal # of the acquisition for the query: e.g.1st, 2nd, 3rd */	
	    sh->acquisitionNum=paramList->functionInfo[i].paramval;	
	    break;	    
	  case FIF_BOARD_ACQUISITIONCOUNT:	/* Total # of acquisitions needed to satisfy the query group */
	    sh->acquisitionCount=paramList->functionInfo[i].paramval;
	    break;	
	  case FIF_BOARD_DESIREDUOM:/* Unit of Measure the user wants. See EngineeringUnits.h */
	    sh->desiredUOM=paramList->functionInfo[i].paramval; 	        
	    break;	
	  case FIF_BOARD_ENGINEERINGUOM:/* Native UOM the sensor takes its readings in. See EngineeringUnits.h */
	    sh->engineeringUOM=paramList->functionInfo[i].paramval;	
	    break;	
	  case FIF_BOARD_OUTPUTUOM:/* Unit of Measure of the data on this sample record. See EngineeringUnits.h   */
	    //sh->outputUOM=paramList->functionInfo[i].paramval; 		
	    break;
	  case FIF_BOARD_CONVERSIONVAL:/* Conversion of volts/EU to convert voltage reading the EU for the sensor */
	    memcpy(&(sh->conversionVal),&(paramList->functionInfo[i].paramval),4);
	    break;	
	  case FIF_BOARD_SENSORZERO:/* Zero stop of the sensor.  */
	    memcpy(&(sh->sensorZero),&(paramList->functionInfo[i].paramval),4);
	    break;
	  default:
	  }
	}
	break;
      case FI_FUNCTION_FFT:
	if(whichFunction == FI_FUNCTION_FFT){
	  switch(paramList->functionInfo[i].paramname) {
	  case FIF_FFT_NUMOUTPUTSAMPLES:
	    sh->numSamples = paramList->functionInfo[i].paramval;
	    trace(DBG_USR1,"FFT will have %d outputpoints\r\n",sh->numSamples);
	    break;
	  default:
	  }
	}
	break;
      case FI_FUNCTION_GSE:
	if(whichFunction == FI_FUNCTION_GSE){
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
	break;
      default:
	trace(DBG_USR1,"WARNING:  GenericSampling.prepare passed unknown TypeValItem.functionInfo[i].function");
      }
    }
    return SUCCESS;
  }

  command result_t ChannelParamsManager.writeSampleHeader[uint8_t instance](uint8_t *buffer){
    
    memcpy(buffer,&gSampleHeaders[instance],sizeof(sampleHeader_t));
    return SUCCESS;
  }

  command result_t ChannelParamsManager.setNumSamples[uint8_t instance](uint16_t numSamples){
    
    gSampleHeaders[instance].numSamples= numSamples;
    return SUCCESS;
  }

  command result_t ChannelParamsManager.incrementSampleOffset[uint8_t instance](uint16_t numSamples){
    
    gSampleHeaders[instance].sampleOffset += numSamples;
    return SUCCESS;
  }

  command result_t ChannelParamsManager.setSampleOffset[uint8_t instance](uint32_t numSamples){
    
    gSampleHeaders[instance].sampleOffset = numSamples;
    return SUCCESS;
  }

  command result_t ChannelParamsManager.setMicroTimestamp[uint8_t instance](uint64_t timeStamp){
    
    gSampleHeaders[instance].microSecTimeStamp = timeStamp;
    return SUCCESS;
  }

  command result_t ChannelParamsManager.setWallTimestamp[uint8_t instance](uint32_t timeStamp){
    
    if(gSampleHeaders[instance].sampleOffset == 0){
      gSampleHeaders[instance].wallClockTimeStamp = timeStamp;
    }
    return SUCCESS;
  }

  command result_t ChannelParamsManager.setADCScale[uint8_t instance](float ADCScale){
    
    gSampleHeaders[instance].ADCScale = ADCScale;
    return SUCCESS;
  }

  command result_t ChannelParamsManager.setADCOffset[uint8_t instance](float ADCOffset){
    
    gSampleHeaders[instance].ADCOffset = ADCOffset;
    return SUCCESS;
  }

  command result_t ChannelParamsManager.setSequenceID[uint8_t instance](uint32_t ID){
    
    gSampleHeaders[instance].sequenceID = ID;
    return SUCCESS;
  }

  command result_t ChannelParamsManager.setOutputUOM[uint8_t instance](uint8_t UOM){
    
    gSampleHeaders[instance].outputUOM = UOM;
    return SUCCESS;
  }

}
