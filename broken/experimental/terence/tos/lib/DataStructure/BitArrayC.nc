/**
 * Author: Terence Tong
 * This simulate we have a bit array using a uint8_t array
 * you can basically do this bit array[6]
 * array[4] = 0;
 * array[2] = 1;
 * bit x = array[3];
 */
#include "fatal.h"

module BitArrayC {
	provides {
		interface BitArray;
	}
}


implementation {
	

#ifndef DS_INVALID
#define DS_INVALID -1
#endif


  /*////////////////////////////////////////////////////////*/
  /**
   * This is going to put in the header in the array. return back the
	 * bit array pointer with (input size (bytes) - header size (bytes)) * 8 number
	 * of bits avaialbe. There is a macro defined for you to caluclate how much int you need
	 * say you want a bit array of 50 bits, you do uint8_t array[BITARRAY_SIZE(50)]
	 * then you initialise it by initBitArray(array, BITARRAY_SIZE(50))
	 * I need to seperate the macro into other file due to limitation of nesc compiler
	 * (as of september, 2002)
   * @author: terence
   * @param: emptyint, a uint8_t array
	 * @param: size, number of bytes in a uint8_t array
   * @return: bitarray pointer
   */
	command BitArrayPtr BitArray.initBitArray(uint8_t emptyint[], uint8_t size) {	
		BitArrayPtr bitarray = (BitArrayPtr) emptyint;
		int maxSize = (size - sizeof(BitArray_t)) * 8, i;
		if (maxSize <= 0) { FATAL("BitArray, Size too Small"); return (BitArrayPtr) DS_INVALID; } 
		for (i = 0; i < size; i++)
			emptyint[i] = 0;
		bitarray->maxSize = maxSize;
		bitarray->items = &emptyint[sizeof(BitArray_t)];
		return bitarray;
	}

	/*////////////////////////////////////////////////////////*/
  /**
   * bit array[10]; array[2] = 1 => saveBitArray(2, 1, array) 
   * @author: terence
   * @param: bitIndex, the index (int bit) of the array
	 * @param: value, the value that you want to save 0 or 1?
	 * @param: bitarray, the pointer for the array
   * @return: success other DS_INVALID
   */
	command uint8_t BitArray.saveBitInArray(uint8_t bitIndex, uint8_t value, BitArrayPtr bitarray) {
		uint8_t arrayIndex, internalOffset, bitMask;
		if (bitIndex >= bitarray->maxSize) {FATAL("BitArray, Out of Bound"); return DS_INVALID; }
		arrayIndex = bitIndex / 8;
		internalOffset = bitIndex % 8;
		if (value == 0) { // need to and it
			bitMask = 0xff & ~(1 << (8 - internalOffset - 1)); // 110111111
			bitarray->items[arrayIndex] = bitarray->items[arrayIndex] & bitMask;
		} else if (value == 1) { // need to or it
			bitMask = value << (8 - internalOffset - 1); // 00100000
			bitarray->items[arrayIndex] = bitarray->items[arrayIndex] | bitMask;
		} else {
			FATAL("BitArray, Input Value is not 1 or 0");
			return DS_INVALID;
		}
		return SUCCESS;
	}
  /*////////////////////////////////////////////////////////*/
  /**
   * bit x = array[3] => readBitInArray(3, array)
   * @author: terence
   * @param: bitIndex, the index (int bit) you want to read
	 * @param: bitarray, the bitarray pointer
   * @return: result 1 or 0
   */
	command uint8_t BitArray.readBitInArray(uint8_t bitIndex, BitArrayPtr bitarray) {
		uint8_t arrayIndex, internalOffset;
		if (bitIndex >= bitarray->maxSize) { FATAL("BitArray, Out of Bound"); return DS_INVALID;}
		arrayIndex = bitIndex / 8;
		internalOffset = bitIndex % 8;
		return (bitarray->items[arrayIndex] >> (8 - internalOffset - 1)) & 1;
	}
  /*////////////////////////////////////////////////////////*/
  /**
   * is this array empty
   * @author: terence
   * @param: bitarray, bitarray pointer
   * @return: 1 if empty
   */
	command uint8_t BitArray.isEmpty(BitArrayPtr bitarray) {
		return (bitarray->maxSize == 0);
	}
	
	command void BitArray.print(BitArrayPtr bitarray) {
		// don't need debug if you are not pc
		int i;
#ifdef PLATFORM_PC
#ifdef DBG_USR3		
			printf("bitarray ptr with maxSize %d: ", bitarray->maxSize);
			for (i = 0; i < bitarray->maxSize; i++) {
				printf("%d ", call BitArray.readBitInArray(i, bitarray));
			}
			printf("\n");
#endif
#endif
	}


}
