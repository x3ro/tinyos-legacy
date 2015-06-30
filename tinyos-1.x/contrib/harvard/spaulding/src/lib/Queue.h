/*
 * Copyright (c) 2004
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/** 
 * Queue - Keeps a queue of <code>void*</code> pointers.
 * <p>
 * This class/interface implements a generic queue.  Note, that
 * it queues <code>void*</code>.  You have to provide the memory!
 * <p><code>
 * // ----- How to Use (example) -----                                                                
 * // (1) Allocate memory
 *    Queue Q;
 *    double* Qdata[QUEUE_SIZE]; // or may be declared as void*
 *
 * // (2) Initialize
 *    Queue_init(&Q, (void*) Qdata, QUEUE_SIZE);
 *
 * // (3) Use
 *    double a = 0.1;
 *    double b = 1.1;                
 *    Queue_enqueue(&Q, &a);
 *    Queue_enqueue(&Q, &b);
 *
 *    double *aa = Queue_dequeue(&Q);
 *    printf("Queue_dequeue(): %f\n", *aa);
 *    printf("Queue_dequeue(): %f\n", *(double*)Queue_dequeue(&Q) );
 * // ----- end of how to use -----     
 * </code>
 * @author Konrad Lorincz <konrad@eecs.harvard.edu>
 * @date   March 1, 2004
 */
#ifndef QUEUE_H
#define QUEUE_H   
#include "Iterator.h"    
#include "PrintfUART.h"


typedef struct Queue 
{
    void* *queuePtr;
    uint16_t enqueueNext;
    uint16_t dequeueNext;
    uint16_t size;
    uint16_t capacity;
    char name[32];    // usefull when printing the queue
} Queue;
typedef Queue* QueuePtr;



// =========================== Interface ==============================
/**
 * Initializes the Queue struct. <br>
 * <b>IMPORTANT:</b>  This function must be called
 * before the rest of the interface is used!  You must provide the memory:
 * i.e. both the Queue structure and the QueuePtr array
 *
 * @param QPtr  a pointer to the Queue struct on which to operate
 * @param QdataPtr[] a pointer to the void* array
 * @param cueueCapacity the size of the QdataPtr[] array
 */
inline void Queue_init(QueuePtr QPtr, void* QdataPtr[], uint16_t queueCapacity);

/**
 * Returns the number of message pointers that were enqueued.
 * @param QPtr  a pointer to the Queue struct on which to operate
 * @return the number of message pointers that were enqueued.
 */
inline uint16_t Queue_size(QueuePtr QPtr);

/**
 * Peaks at the front of the queue. NOTE: it does not remove it!
 * @param QPtr  a pointer to the Queue struct on which to operate
 * @return the void* pointer at the front of the queue, <code>NULL</code> if the queue is empty.
 */
inline void* Queue_front(QueuePtr QPtr);

/**
 * Adds the msgPtr to the queue.
 * @param QPtr  a pointer to the Queue struct on which to operate
 * @param objPtr  pointer to enqueue
 * @return <code>SUCCESS</code> if was added to queue, else <code>FAIL</code>
 */
inline result_t Queue_enqueue(QueuePtr QPtr, void* objPtr);

/**
 * Removes the next message pointer from the front of the queue.
 * @param QPtr  a pointer to the Queue struct on which to operate
 * @return the pointer removed, <code>NULL</code> if there was nothing to dequeue
 */
inline void* Queue_dequeue(QueuePtr QPtr);

/**
 * Removes the pointer from the queue if it exists in the queue.  If it doesn't exist
 * that it does nothing.
 * @param QPtr  a pointer to the Queue struct on which to operate
 * @param the pointer to remove from the queue
 */
inline void Queue_remove(QueuePtr QPtr, void* objPtr);
      
/**
 * Initializes an <code>Iterator</code> over this queue.  After the 
 * initialization, the iterator will "point" to the beginning of the queue.
 * @param QPtr  a pointer to the Queue struct on which to operate
 * @param itPtr  pointer to the iterator to initialize over this queue
 */
inline void Queue_iterInit(QueuePtr QPtr, Iterator *itPtr);

/**
 * Moves the iterator to the next object in the queue.  If no more objects exist,
 * then the <code>itPtr->nextObjPtr</code> will be set to <code>NULL</code>.
 * @param QPtr  a pointer to the Queue struct on which to operate
 * @param itPtr  pointer to the iterator
 */
inline void Queue_iterNext(QueuePtr QPtr, Iterator *itPtr);

/**
 * Removes the objectPtr where the Iterator points, and advances the iterator forward by one. *
 * @param QPtr  a pointer to the Queue struct on which to operate
 * @param itPtr  pointer to the iterator
 */
inline void* Queue_iterRemove(QueuePtr QPtr, Iterator *itPtr);



// ========================== Implementation ==========================
inline void Queue_init(QueuePtr QPtr, void* QdataPtr[], uint16_t queueCapacity)
{
    uint16_t i = 0;
    QPtr->queuePtr = QdataPtr;
    QPtr->enqueueNext = 0;
    QPtr->dequeueNext = 0;
    QPtr->size = 0;
    QPtr->capacity = queueCapacity;
    
    for (i = 0; i < QPtr->capacity; ++i)
        QPtr->queuePtr[i] = NULL;
}

inline uint16_t Queue_size(QueuePtr QPtr)
{
    return QPtr->size;
}

inline void* Queue_front(QueuePtr QPtr)
{   
    if (Queue_size(QPtr) > 0)
        return QPtr->queuePtr[QPtr->dequeueNext];
    else {
        printfUART("Queue - front(): FATAL ERROR! queue is empty\n", "");
        //EXIT_PROGRAM = 1; // temporary, usefull for debugging
        return NULL;
    }
}

/** Add the newMsgPtr to the queue
 *  @param newMsgPtr a pointer to the new message to enqueue
 *  @return SUCCESS if was added to queue, else FAIL
 */    
inline result_t Queue_enqueue(QueuePtr QPtr, void* objPtr)
{  
    if (Queue_size(QPtr) < QPtr->capacity) {
        NOprintfUART("Queue - enqueue(): enq= %i, deq= %i, cap= %i, objPtr= 0x%x\n", QPtr->enqueueNext, QPtr->dequeueNext, QPtr->capacity, objPtr);
        // update the queue
        QPtr->queuePtr[QPtr->enqueueNext] = objPtr;
        QPtr->enqueueNext++; 
        QPtr->enqueueNext %= QPtr->capacity;
        QPtr->size = QPtr->size + 1;
        return SUCCESS;        
    }
    else {  // Fail if queue is full
        printfUART("Queue - enqueue(): FATAL ERROR! queue is full\n", "");
        //EXIT_PROGRAM = 1;  // temporary, usefull for debugging
        return FAIL;   
    } 
}

inline void* Queue_dequeue(QueuePtr QPtr)
{  
    void* dequeuedPtr = QPtr->queuePtr[QPtr->dequeueNext];

    if (Queue_size(QPtr) > 0) {        
        //NOprintfUART("Queue - dequeue(): enq= %i, deq= %i, objPtr= 0x%x\n", QPtr->enqueueNext, dequeueNext, dequeuedMsgPtr);
        QPtr->queuePtr[QPtr->dequeueNext] = NULL;
        QPtr->dequeueNext++; 
        QPtr->dequeueNext %= QPtr->capacity;
        QPtr->size = QPtr->size - 1;
        return dequeuedPtr;
    }
    else {
        printfUART( "Queue - dequeue(): FATAL ERROR! queue is empty\n", "");
        //EXIT_PROGRAM = 1;  // temporary, usefull for debugging
        return NULL;
    }
}

inline void Queue_iterInit(QueuePtr QPtr, Iterator *itPtr)
{
    if (Queue_size(QPtr) > 0) {
        itPtr->nextObjPtr = Queue_front(QPtr); 
        itPtr->indexStartObjPtr = QPtr->dequeueNext;
        itPtr->indexNextObjPtr = itPtr->indexStartObjPtr;
    }
    else {
        itPtr->nextObjPtr = NULL;
        itPtr->indexStartObjPtr = 0;
        itPtr->indexNextObjPtr = 0;
    }
}

inline void Queue_iterNext(QueuePtr QPtr, Iterator *itPtr)
{
    NOprintfUART("Queue - Queue_iterNext(): called\n", "");
    itPtr->indexNextObjPtr = (itPtr->indexNextObjPtr + 1) % QPtr->capacity;
                                     
    if (itPtr->indexNextObjPtr == QPtr->enqueueNext)
        itPtr->nextObjPtr = NULL;
    else
        itPtr->nextObjPtr = QPtr->queuePtr[itPtr->indexNextObjPtr];

    NOprintfUART("Queue - Queue_iterNext(): leaving\n", "");
}


/**
 * Removes the objectPtr where the Iterator points, and advances the iterator forward by one
 */
inline void* Queue_iterRemove(QueuePtr QPtr, Iterator *itPtr)
{
    uint16_t currI = 0;
    uint16_t nextI = 0;    
    void* removedObjPtr = itPtr->nextObjPtr;

    // (1) Adjust the Queue 
    // shift all entries from the removed value to the end of the queue (i.e. enqueueNext)
    currI = itPtr->indexNextObjPtr;
    nextI = (currI+1) % QPtr->capacity;

    while (nextI != QPtr->enqueueNext) {
        QPtr->queuePtr[currI] = QPtr->queuePtr[nextI];  // do the shift

        currI = nextI;
        nextI = (nextI+1) % QPtr->capacity;
    }
                       
    QPtr->enqueueNext = (QPtr->enqueueNext + QPtr->capacity - 1) % QPtr->capacity;
    QPtr->queuePtr[QPtr->enqueueNext] = NULL;
    QPtr->size--;


    // (2) Adjust the Iterator to point to the next obj
    if (itPtr->indexNextObjPtr == QPtr->enqueueNext)
        itPtr->nextObjPtr = NULL;
    else
        itPtr->nextObjPtr = QPtr->queuePtr[ itPtr->indexNextObjPtr ];
        

    return removedObjPtr;        
}

inline void Queue_remove(QueuePtr QPtr, void* objPtr)
{
    Iterator it;

    for (Queue_iterInit(QPtr, &it); it.nextObjPtr != NULL;  ) {
        if (it.nextObjPtr == objPtr) {
            Queue_iterRemove(QPtr, &it);
            return;
        }
        else
            Queue_iterNext(QPtr, &it);
    }
}

#endif
