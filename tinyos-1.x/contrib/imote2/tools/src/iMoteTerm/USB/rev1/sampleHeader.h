#ifndef __SAMPLEHEADER_H__
#define __SAMPLEHEADER_H__


typedef struct sampleHeader {
  unsigned char logicalNodeId;		/* Intel logical nodeId, mote generating sample*/
  unsigned char channelId; 		/* channelId generating the sample.  This is VirtualChannel */
  unsigned char acquisitionNum;	/* Ordinal # of the acquisition for the query: e.g.1st, 2nd, 3rd */	
  unsigned char gSEFilterType;        	/* filler for header due to 32 bit boundary */
  unsigned char sensorType;		/* sensorType - Robbie creating enum */
  unsigned char sampleWidth;	        	/* bit width of sample data used for parsing sample body */
  unsigned short queryGroupId;  	/* UniqueId of the query group being satisfied by this sample record */
  unsigned char acquisitionCount;	/* Total # of acquisitions needed to satisfy the query group */
  unsigned char desiredUOM; 	        	/* Unit of Measure the user wants. See EngineeringUnits.h */
  unsigned char outputUOM; 		/* Unit of Measure of the data on this sample record. See EngineeringUnits.h   */
  unsigned char engineeringUOM;	/* Native UOM the sensor takes its readings in. See EngineeringUnits.h */
  float conversionVal;	       	 /* Conversion of volts/EU to convert voltage reading the EU for the sensor */
  float sensorZero;		/* Zero stop of the sensor.  */
  unsigned long samplingRate;	/* Rate at which samples are taken */
  unsigned long numSamples; 	        	/* numSamples in this chunk */ 
  unsigned long function;		/* post processing function applied to data.  Robbie creating function bitmap */
  unsigned long long microSecTimeStamp;		/* micro-second accurate time stamp using time sync*/
  unsigned long wallClockTimeStamp;	/* second accurate wall clock stamp */
  
  float ADCScale;		/* Scaling used for Analog to Digital conversion */
  float ADCOffset;		/* Offset used for Analog to Digital conversion */
  unsigned long sequenceID;		/* unique number identifying the capture */
  unsigned long sampleOffset;		/* The offset of the 1st sample of this block within the total number of samples */
  unsigned long totalSamples; 		/* total number of samples in an acquisition */
} sampleHeader_t; 


#endif //__SAMPLEHEADER_H__
