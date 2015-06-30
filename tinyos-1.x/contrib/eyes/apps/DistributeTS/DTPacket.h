
#ifndef DTPACKET_H_INCLUDED
#define DTPACKET_H_INCLUDED

#include "DTClock.h"

typedef enum {
  	TIMESTAMP = 0x0000,
	TEMPSENSOR = 0x1000,
	LIGHTSENSOR = 0x2000
  } sensortype_t;
  
typedef struct DT_Packet
{
  /* time structure : s and us = 64 bit*/
    timeval tv;
  /* 4-bit field to indicate the sensortype : 0000=timestamp
  					      0001=temperature
					      0010=light	
			+ 12 bit Sensordata */
   
    uint16_t sensortype_data;    
  /* 12 bit Sensordata */
} DT_Packet;/* complete packet has 80 bit */

#endif
