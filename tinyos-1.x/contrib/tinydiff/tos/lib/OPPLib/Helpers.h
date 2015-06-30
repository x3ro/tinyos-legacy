/*
  Header file for help function implementation
*/
#ifndef __HELPERS_INC_
#define __HELPERS_INC_


#include "OnePhasePull.h"

// Handles the event of arriving interest message to a node
void updateGradientList( uint16_t * cur,  uint8_t * csize, 
			 uint16_t * new,  uint8_t * nsize ,uint8_t  maxSize ); 
// Pre: cur is a list of unique values to be updated 
//      csize is the number of elements in the cur list
//      new is a new list to update cur 
//      nsize is the number of elements in the new list
//      maxSize is the maximum number of elements in the updated array

#endif
