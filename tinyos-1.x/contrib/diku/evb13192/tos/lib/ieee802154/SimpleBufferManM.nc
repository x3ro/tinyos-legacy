/* Copyright (c) 2006, Jan Flora <janflora@diku.dk>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *  - Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *  - Neither the name of the University of Copenhagen nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
  @author Jan Flora <janflora@diku.dk>
*/

module SimpleBufferManM
{
	provides
	{
		interface StdControl;
		interface IeeeBufferManagement as BufferMng;
		interface BufferManDebug;
	}
	uses
	{
		interface FIFOQueue as Queue;
		interface Debug;
	}
}

#define POOL_SIZE_128_BYTE 8
#define POOL_SIZE_64_BYTE 5
#define POOL_SIZE_32_BYTE 5
#define POOL_SIZE_16_BYTE 5
#define POOL_SIZE_8_BYTE 30

implementation
{
	#define DBG_LEVEL 3
	#include "Debug.h"

	uint8_t bufPool128[POOL_SIZE_128_BYTE][128];
	uint8_t *queueBuffer128[POOL_SIZE_128_BYTE];
	uint8_t bufPool64[POOL_SIZE_64_BYTE][64];
	uint8_t *queueBuffer64[POOL_SIZE_64_BYTE];
	uint8_t bufPool32[POOL_SIZE_32_BYTE][32];
	uint8_t *queueBuffer32[POOL_SIZE_32_BYTE];
	uint8_t bufPool16[POOL_SIZE_16_BYTE][16];
	uint8_t *queueBuffer16[POOL_SIZE_16_BYTE];
	uint8_t bufPool8[POOL_SIZE_8_BYTE][8];
	uint8_t *queueBuffer8[POOL_SIZE_8_BYTE];

	// Queues that keep pointers to free memory blocks.
	FIFOQueue_t freeQueue128;
	FIFOQueue_t freeQueue64;
	FIFOQueue_t freeQueue32;
	FIFOQueue_t freeQueue16;
	FIFOQueue_t freeQueue8;

	// Debug
	#if DBG_LEVEL > 0
		uint8_t printCount = 0;
		void printUsageStats();
	#endif

	// Forward declarations
	FIFOQueue_t *getPool(uint8_t size);

	command result_t StdControl.init()
	{
		uint8_t i;
		// Initialize free queues.
		call Queue.initQueue(&freeQueue128, queueBuffer128, POOL_SIZE_128_BYTE);
		call Queue.initQueue(&freeQueue64, queueBuffer64, POOL_SIZE_64_BYTE);
		call Queue.initQueue(&freeQueue32, queueBuffer32, POOL_SIZE_32_BYTE);
		call Queue.initQueue(&freeQueue16, queueBuffer16, POOL_SIZE_16_BYTE);
		call Queue.initQueue(&freeQueue8, queueBuffer8, POOL_SIZE_8_BYTE);
		
		// Add all buffer pool elements to the free queues.
		for (i=0;i<POOL_SIZE_128_BYTE;i++) {
			call Queue.enqueue(&freeQueue128, bufPool128[i]);
		}
		for (i=0;i<POOL_SIZE_64_BYTE;i++) {
			call Queue.enqueue(&freeQueue64, bufPool64[i]);
		}
		for (i=0;i<POOL_SIZE_32_BYTE;i++) {
			call Queue.enqueue(&freeQueue32, bufPool32[i]);
		}
		for (i=0;i<POOL_SIZE_16_BYTE;i++) {
			call Queue.enqueue(&freeQueue16, bufPool16[i]);
		}
		for (i=0;i<POOL_SIZE_8_BYTE;i++) {
			call Queue.enqueue(&freeQueue8, bufPool8[i]);
		}
		return SUCCESS;
	}
	
	command result_t StdControl.start()
	{
		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	command result_t BufferMng.claim( uint8_t size, uint8_t **buffer )
	{
		
		FIFOQueue_t *freeQueue;

		if (size > 128) return FAIL;		
		freeQueue = getPool(size);
		return call Queue.dequeue(freeQueue, buffer);
	}
	
	command result_t BufferMng.release( uint8_t size, uint8_t *buffer )
	{
		FIFOQueue_t *freeQueue;
		
		if (size > 128) return FAIL;
		freeQueue = getPool(size);
		return call Queue.enqueue(freeQueue, buffer);
	}

	FIFOQueue_t *getPool(uint8_t size)
	{
		if (size > 64) {
			return &freeQueue128;
		}
		if (size > 32) {
			return &freeQueue64;
		}
		if (size > 16) {
			return &freeQueue32;
		}
		if (size > 8) {
			return &freeQueue16;
		}
		return &freeQueue8;
	}
	
#if DBG_LEVEL > 0
	command void BufferManDebug.printUsageStats()
	{
		uint8_t freeCount = 0;
		DBG_STR("-----------------",3);
		DBG_STR("Number of 128 byte buffers free:",3);
		freeCount = call Queue.elementCount(&freeQueue128);
		DBG_INT(freeCount,3);
		
		DBG_STR("Number of 64 byte buffers free:",3);
		freeCount = call Queue.elementCount(&freeQueue64);
		DBG_INT(freeCount,3);
		
		DBG_STR("Number of 32 byte buffers free:",3);
		freeCount = call Queue.elementCount(&freeQueue32);
		DBG_INT(freeCount,3);
		
		DBG_STR("Number of 16 byte buffers free:",3);
		freeCount = call Queue.elementCount(&freeQueue16);
		DBG_INT(freeCount,3);
		
		DBG_STR("Number of 8 byte buffers free:",3);
		freeCount = call Queue.elementCount(&freeQueue8);
		DBG_INT(freeCount,3);
		
		DBG_STR("-----------------",3);
	}
#endif
}
