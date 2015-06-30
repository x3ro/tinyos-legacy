/**
 * Author: Terence Tong
 * Support fifoqueue operations, given a uint8_t array
 * 
 */
#include "fatal.h"

module FifoQueueC {
	provides {
		interface FifoQueue;
	}

}

implementation {

#ifndef DS_INVALID
#define DS_INVALID -1
#endif

  /*////////////////////////////////////////////////////////*/
  /**
   * This is going to put in the header in the array, return back the
	 * fifoqueue pointer. There is a macro defined for you to calcuate how much
	 * uint8 in order to get the numbers of pointers you need. so in order to 
	 * have a Fifoqueue with X pointers. you do uint8_t array[FIFOQUEUE_SIZE(X)]
	 * and initBitArray(array, FIFOQUEUE_SIZE(X))
	 * I need to seperate the macro into other file due to limitation of nesc compiler
	 * (as of september, 2002)
	 * I make no assumption on the sizeof(void *) in order to be portable
   * @author: terence
   * @param: emptyint, uint8_t array that we are going to initialise
	 * @param: size, the size (byte) of emptyint
   * @return: fifoqueue pointer
   */
	command QueuePtr FifoQueue.initQueue(uint8_t emptyint[], uint8_t size) {
		QueuePtr queue;
		int i, maxSize;
		maxSize = (size - sizeof(struct Queue_t)) / sizeof(void *);
		if (maxSize <= 0) { FATAL("FifoQueue, Not enough Space"); return (QueuePtr) DS_INVALID; } // not enought space retrun
		for (i = 0; i < size; i++) emptyint[i] = 0; // in case there is something on it
		queue = (QueuePtr) emptyint;
		queue->currentIndex = 0; // the first index is 0
		queue->queueSize = 0; // it is empty right now
		queue->maxSize = maxSize;
		queue->items = (void **) &emptyint[sizeof(struct Queue_t)]; 
		return queue;
	}
  /*////////////////////////////////////////////////////////*/
  /**
	 * return number of space available
   * @author: terence
   * @param: queue, fifoqueue pointer
   * @return: size of the array
   */
	command uint8_t FifoQueue.availableSpace(QueuePtr queue) {
		return queue->maxSize - queue->queueSize;
	}
  /*////////////////////////////////////////////////////////*/
  /**
	 * put the stuff at the end of the queue
   * @author: terence
   * @param: queue, fifoqueue pointer
	 * @param: item, the pointer that you want to put at the end of the queue
   * @return: SUCCESS if everything is allright
   */

	command uint8_t FifoQueue.enqueue(QueuePtr queue, void *item) {
		if (queue->queueSize >= queue->maxSize) {FATAL("FifoQueue, Out of Bound"); return DS_INVALID;}
		queue->items[(queue->currentIndex + queue->queueSize) % queue->maxSize] = item;
		queue->queueSize++;
		return SUCCESS;
	}
  /*////////////////////////////////////////////////////////*/
  /**
   * dequeue the the first element in the queue
   * @author: terence
   * @param: queue, the fifoqueue
   * @return: the first iterm in the fifoqueue
   */

	command void *FifoQueue.dequeue(QueuePtr queue) {
		void *element = queue->items[queue->currentIndex];
		if (call FifoQueue.isEmpty(queue)) { FATAL("FifoQueue, Queue is Empty"); return (void *) DS_INVALID; }
		queue->currentIndex++;
		if (queue->currentIndex == queue->maxSize)
			queue->currentIndex = 0;
		//		queue->currentIndex = (queue->currentIndex + 1) % queue->maxSize;
		queue->queueSize--;
		return element;
	}
  /*////////////////////////////////////////////////////////*/
  /**
   * get the first element of the queue without removing it
   * @author: terence
   * @param: queue, the fifoqueue
   * @return: the first element of the fifoqueue
   */
	command void *FifoQueue.getFirst(QueuePtr queue) {
		if (call FifoQueue.isEmpty(queue)) { FATAL("FifoQueue, Queue is Empty"); return (void *) DS_INVALID; }
		return queue->items[queue->currentIndex];
	}
  /*////////////////////////////////////////////////////////*/
  /**
   * is the queue empty?
   * @author: terence
   * @param: queue, the fifoqueue
   * @return: 1 if empty
   */
	command uint8_t FifoQueue.isEmpty(QueuePtr queue) {
		return (queue->queueSize == 0);
 	}
  /*////////////////////////////////////////////////////////*/
  /**
   * is the queue full?
   * @author: terence
   * @param: queue, the fifoqueue
   * @return: 1 if full
   */
	command uint8_t FifoQueue.isFull(QueuePtr queue) {
		return (queue->queueSize >= queue->maxSize);
	}

	command void FifoQueue.print(QueuePtr queue) {
		// don't need debug if you are not pc		
#ifdef PLATFORM_PC
			printf("fifoqueue ptr with maxSize %d, queueSize %d, currentIndex %d \n", queue->maxSize, queue->queueSize, queue->currentIndex); 
#endif
	}

}
