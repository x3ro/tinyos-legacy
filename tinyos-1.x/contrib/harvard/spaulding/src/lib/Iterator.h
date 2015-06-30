/*
 * Copyright (c) 2005
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
 * Description: Iterator <br>
 *    This iterator is used to itrate over arrays of void*. 
 *    <p>
 *    IMPORTANT: The collection class/structure that wishes to support iterators
 *      must implement ClassName_iterInit() and ClassName_iterNext();
 *
 * // ----- How to Use (example with Queue) -----
 * // (1) Allocate memory
 *    Iterator it;
 *
 * // (2) Create your class
 *    Queue Q;
 *    double* Qdata[QUEUE_SIZE]; // or may be declared as void*
 *
 *    Queue_init(&Q, (void*) Qdata, QUEUE_SIZE);
 *    double a = 0.1;
 *    double b = 1.1;
 *    Queue_enqueue(&Q, &a);
 *    Queue_enqueue(&Q, &b);
 *
 * // (3) Use   
 *    for( Queue_iterInit(&Q, &it); it.nextObjPtr != NULL; Queue_iterNext(&Q, &it) )
 *		  printf("Iterator - nextObjPtr: %f\n", *(double*)(it.nextObjPtr) );
 * // ----- end of how to use -----     
 *
 * <pre>URL: http://www.eecs.harvard.edu/~konrad/projects/motetrack</pre>
 * @author Konrad Lorincz
 * @version 2.0, January 5, 2005
 */
#ifndef ITERATOR_H
#define ITERATOR_H             
#include "PrintfUART.h"


typedef struct Iterator
{
    void* nextObjPtr;
    uint16_t indexStartObjPtr;
    uint16_t indexNextObjPtr;
} Iterator;

/**
 * Prints the state of the Iterator.
 */
inline void Iterator_print(Iterator *itPtr)
{
    printfUART(">>>-----Iterator: (0x%x)----->>>\n", itPtr);
    printfUART("nextObjPtr= 0x%x\n", itPtr->nextObjPtr);
    printfUART("indexStartObjPtr= %i\n", itPtr->indexStartObjPtr);
    printfUART("indexNextObjPtr= %i\n", itPtr->indexNextObjPtr);
    printfUART("<<<--------------------------<<<\n", "");
}


#endif
