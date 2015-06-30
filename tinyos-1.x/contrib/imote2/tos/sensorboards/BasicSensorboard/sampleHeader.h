#ifndef __SAMPLEHEADER_H__
#define __SAMPLEHEADER_H__


typedef struct {
  uint8_t logicalNodeId;		/* Intel logical nodeId, mote generating sample*/
  uint8_t channelId; 		/* channelId generating the sample.  This is VirtualChannel */
  uint8_t acquisitionNum;	/* Ordinal # of the acquisition for the query: e.g.1st, 2nd, 3rd */	
  uint8_t gSEFilterType;        	/* filler for header due to 32 bit boundary */
  uint8_t sensorType;		/* sensorType - Robbie creating enum */
  uint8_t sampleWidth;	        	/* bit width of sample data used for parsing sample body */
  uint16_t queryGroupId;  	/* UniqueId of the query group being satisfied by this sample record */
  uint8_t acquisitionCount;	/* Total # of acquisitions needed to satisfy the query group */
  uint8_t desiredUOM; 	        	/* Unit of Measure the user wants. See EngineeringUnits.h */
  uint8_t outputUOM; 		/* Unit of Measure of the data on this sample record. See EngineeringUnits.h   */
  uint8_t engineeringUOM;	/* Native UOM the sensor takes its readings in. See EngineeringUnits.h */
  float conversionVal;	       	 /* Conversion of volts/EU to convert voltage reading the EU for the sensor */
  float sensorZero;		/* Zero stop of the sensor.  */
  uint32_t samplingRate;	/* Rate at which samples are taken */
  uint32_t numSamples; 	        	/* numSamples in this chunk */ 
  uint32_t function;		/* post processing function applied to data.  Robbie creating function bitmap */
  uint64_t microSecTimeStamp;		/* micro-second accurate time stamp using time sync*/
  uint32_t wallClockTimeStamp;	/* second accurate wall clock stamp */
  
  float ADCScale;		/* Scaling used for Analog to Digital conversion */
  float ADCOffset;		/* Offset used for Analog to Digital conversion */
  uint32_t sequenceID;		/* unique number identifying the capture */
  uint32_t sampleOffset;		/* The offset of the 1st sample of this block within the total number of samples */
  uint32_t totalSamples; 		/* total number of samples in an acquisition */
} sampleHeader_t __attribute__((packed, aligned(32))); 


#endif //__SAMPLEHEADER_H__
