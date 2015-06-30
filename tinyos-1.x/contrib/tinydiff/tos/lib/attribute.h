#ifndef _ATTRIBUTE_H_
#define _ATTRIBUTE_H_

typedef struct {
  uint8_t  key;		  // key
  uint8_t  op;            // operator as defined in ..
  uint16_t value;	  // Value 
 
} __attribute__ ((packed)) Attribute;

typedef Attribute *AttributePtr;

#endif


