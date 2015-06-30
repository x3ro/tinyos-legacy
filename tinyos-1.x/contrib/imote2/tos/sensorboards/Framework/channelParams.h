#ifndef __CHANNNEL_PARAMS_H__
#define __CHANNNEL_PARAMS_H__

//structure that records the capabilities of our various channels

typedef struct{
  uint32_t numElements;
  uint32_t elements[];
} supportedFeatureList32_t;

typedef struct{
  uint32_t commonFeature;
  uint32_t numElements;
  uint32_t elements[];
} supportedCommonFeatureList32_t;


typedef struct{
  uint32_t numElements;
  uint8_t elements[];
} supportedFeatureList8_t;


typedef struct{
  uint32_t element;
  supportedFeatureList32_t featureList;
}supportedCompoundFeatures32_t;

typedef struct{
  uint32_t numElements;
  supportedCompoundFeatures32_t elements[];
} supportedFeatureMap_t;

/*************************************
 * Structure that defines the capabilities of each sampling channel
 * 
 * @element maxSamplingRate should contain the maximum support sampling rate on this channel
 * @element supportedSensorTypes must contain a pointer to a supportedCommonFeatureList structure that contains the
 *          supported sensortypes.  The common element of each FeatureList entry should contain the physical channel that this set 
 *          of sensors is connected to
 * @element supportedSamplingRates may contain a pointer to a supportedFeatureList structure that contains the
 *          supported samplingRates.  If this pointer is NULL, it implies that any arbitrary integer sampling
 *          rate is supported by this channel
 ************************************/

typedef struct{
  uint32_t maxSamplingRate;
  const supportedCommonFeatureList32_t *supportedSensorTypes;
  const supportedFeatureList32_t *supportedSamplingRates;
  const supportedFeatureList8_t *supportedSampleWidths;
} channelParam_t;

typedef struct{
  const supportedFeatureList8_t *simulChannelGroup;
} dataChannelParam_t;



#endif // __CHANNNEL_PARAMS_H__
