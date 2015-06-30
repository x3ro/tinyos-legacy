#include "stdafx.h"
#include ".\dynqueue.h"
#include "assert.h"

CDynQueue::CDynQueue(void){
	iLength = 0;
	iPhysLength = 2;
	ppvQueue = (const void**)calloc(iPhysLength, sizeof(void*));
	assert(ppvQueue != NULL);
	index = 0;
}

CDynQueue::~CDynQueue(void){
	free(ppvQueue);
}

int CDynQueue::getLength(){
	return iLength;
}

void *CDynQueue::peek(){
	assert(iLength > 0);
	return (void*)(ppvQueue[index]);
}

void CDynQueue::shiftgrow(){
	//choosing to waste space over wasting time by not always shifting
	if(index > 2 && index > iPhysLength / 8){
		memmove((void *)ppvQueue, (void *)(ppvQueue + index), sizeof(void *) * iLength);
		index = 0;
	}
   else{
	   iPhysLength *= 2;
	   ppvQueue =  (const void**)realloc(ppvQueue, sizeof(const void*) * iPhysLength);
	   assert(ppvQueue != NULL);
   }
}

void CDynQueue::push(const void *pvItem){
	if(iLength == iPhysLength) //if <- is true, then index == 0
		shiftgrow();

	if(index > 0)
		index--;
	else//assumed index == 0
		memmove((void *)(ppvQueue + 1), (void *)ppvQueue, sizeof(void *) * iLength);
	ppvQueue[index] = pvItem;
	iLength++;
}

void CDynQueue::enqueue(const void *pvItem){
	if(iLength + index == iPhysLength)
		shiftgrow();
	
	ppvQueue[index + iLength] = pvItem;
	iLength++;
}

void *CDynQueue::dequeue(){
   const void *pvItem;
   assert(iLength > 0);
   
   pvItem = ppvQueue[index];
   ppvQueue[index] = NULL;
   
   iLength--;
   index++;
   return (void*)pvItem;
}
