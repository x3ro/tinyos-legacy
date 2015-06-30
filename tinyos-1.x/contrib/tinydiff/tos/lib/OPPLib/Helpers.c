// implementation for help functions 

#include "Helpers.h"

// =================== update list by unique values =========

// mmysore: TODO: move out... not used
void updateGradientList( uint16_t * cur,  uint8_t * csize, 
			 uint16_t * new,  uint8_t * nsize ,uint8_t  maxSize ) 
// Pre: cur is a list of unique values to be updated 
//      csize is the number of elements in the cur list
//      new is a new list to update cur 
//      nsize is the number of elements in the new list
//      maxSize is the maximum number of elements in the updated array

// Post: cur is updated only by unique values.
//       csize is updated accordinaly 

// mmysore TODO: why does nsize need to be a pointer???
{
  uint8_t duplicate = 0; // Flag for duplicate element- 1 is duplicate
  uint8_t c;             // loop index for cur
  uint8_t n;             // loop index for new

  for ( n = 0; n < *nsize ; n++){
    duplicate = 0;
    for ( c = 0; c < *csize ; c++){
      if ( new[n] == cur[c] ){
	   duplicate = 1;
	   break;
      }

    }  // end inner
    if ( duplicate == 0){
      if (*csize >= maxSize) // keep max size
	return;
      cur[*csize] = new[n];
      (*csize)++;
    }
  } // end outer
  return;
}
