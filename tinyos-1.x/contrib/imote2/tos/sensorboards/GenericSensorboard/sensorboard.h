#ifndef __BASIC_SENSORBOARD_H__
#define __BASIC_SENSORBOARD_H__

/*
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 */
#include "config.h"
#include "channelParams.h"
#include "sensorTypes.h"

const char mySensorboardName[] = "GenericSensorboard";

#define MAX_SAMPLING_RATE (100000)

/*
 * Supported sensor types
 */


//DO NOT CHANGE THESE DEFINITIONS. IF NEW ONES ARE NEEDED, ADD THEM!!!
#define SENSORTYPE_DC5Vpp ANALOG_SENSOR(SENSOR_ANALOG_DCCOUPLED, \
SENSOR_ANALOG_VOLTAGE, \
SENSOR_ANALOG_SINGLEENDED, \
SENSOR_ANALOG_RANGE_PLUSMINUS2P5V)

#define SENSORTYPE_DC10Vpp ANALOG_SENSOR(SENSOR_ANALOG_DCCOUPLED, \
SENSOR_ANALOG_VOLTAGE, \
SENSOR_ANALOG_SINGLEENDED, \
SENSOR_ANALOG_RANGE_PLUSMINUS5V)

#define SENSORTYPE_DC20Vpp ANALOG_SENSOR(SENSOR_ANALOG_DCCOUPLED, \
SENSOR_ANALOG_VOLTAGE, \
SENSOR_ANALOG_SINGLEENDED, \
SENSOR_ANALOG_RANGE_PLUSMINUS10V)

#define SENSORTYPE_AC5Vpp ANALOG_SENSOR(SENSOR_ANALOG_ACCOUPLED, \
SENSOR_ANALOG_VOLTAGE, \
SENSOR_ANALOG_SINGLEENDED, \
SENSOR_ANALOG_RANGE_PLUSMINUS2P5V)

#define SENSORTYPE_AC10Vpp ANALOG_SENSOR(SENSOR_ANALOG_ACCOUPLED, \
SENSOR_ANALOG_VOLTAGE, \
SENSOR_ANALOG_SINGLEENDED, \
SENSOR_ANALOG_RANGE_PLUSMINUS5V)

#define SENSORTYPE_AC20Vpp ANALOG_SENSOR(SENSOR_ANALOG_ACCOUPLED, \
SENSOR_ANALOG_VOLTAGE, \
SENSOR_ANALOG_SINGLEENDED, \
SENSOR_ANALOG_RANGE_PLUSMINUS10V)


#define SENSORTYPE_CURRENTLOOP ANALOG_SENSOR(SENSOR_ANALOG_DCCOUPLED, \
SENSOR_ANALOG_CURRENT, \
SENSOR_ANALOG_DIFFERENTIAL, \
SENSOR_ANALOG_RANGE_PLUS5V)


//THE FIRST NUMBER MUST MATCH THE TOTAL NUMBER OF ELEMENTS IN THE SECOND INITIALIZER FOR ALL ELEMENTS TO BE RECOGNIZED!
//first element in the comondFeatureList for a sensor is the PhysicalChannel that it maps to
const supportedCommonFeatureList32_t channel0Sensors = {1,0,{0}};

const supportedCommonFeatureList32_t channel1Sensors = {1,1,{SENSORTYPE_DC10Vpp}};
const supportedFeatureList8_t channel1Widths = {1,{16}};

const supportedCommonFeatureList32_t channel2Sensors = {1,1,{SENSORTYPE_DC10Vpp}};
const supportedFeatureList8_t channel2Widths = {1,{16}};

const supportedCommonFeatureList32_t channel3Sensors = {1,1,{SENSORTYPE_DC10Vpp}};
const supportedFeatureList8_t channel3Widths = {1,{16}};

const supportedCommonFeatureList32_t channel4Sensors = {1,1,{SENSORTYPE_DC10Vpp}};
const supportedFeatureList8_t channel4Widths = {1,{16}};

const supportedFeatureList8_t simulChannelGroup0 = {1,{0}};
const supportedFeatureList8_t simulChannelGroup1 = {4,{1,2,3,4}};

/*****************************
 * Channel Capabilities Table
 ****************************/
const channelParam_t channelCapabilitiesTable[TOTAL_CHANNELS] = {
  {MAX_SAMPLING_RATE, &channel0Sensors, NULL, NULL},
  {MAX_SAMPLING_RATE, &channel1Sensors, NULL, &channel1Widths},
  {MAX_SAMPLING_RATE, &channel2Sensors, NULL, &channel2Widths},
  {MAX_SAMPLING_RATE, &channel3Sensors, NULL, &channel3Widths},
  {MAX_SAMPLING_RATE, &channel4Sensors, NULL, &channel4Widths}};
 


/*****************************
 * Data Channel Capabilities Table
 ****************************/
const dataChannelParam_t dataChannelCapabilitiesTable[TOTAL_DATA_CHANNELS] = {
  {&simulChannelGroup0},
  {&simulChannelGroup1}};

#endif //__SENSORBOARD_H__
