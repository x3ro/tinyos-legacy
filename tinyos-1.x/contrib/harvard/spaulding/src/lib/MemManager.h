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

/** Description: MsgQueue
 *      This class/interface  implements a generic  memory manager.  A
 *      user  can request  and return  memory pointers.   You  have to
 *      provide the memory!
 *
 * // ----- How to Use (example) -----
 * // (1) Allocate memory
 *     MemManager MM;
 *     double mmData[MEM_SIZE];    // use any type, example shown with double
 *     double* mmFreeList[MEM_SIZE]; // or declare as void*
 *
 * // (2) Initialize
 *     MemManager_init(&MM, mmData, sizeof(double), (void*) mmFreeList, MEM_SIZE);
 *
 *     // Optional: initialize object
 *     uint16_t i = 0;
 *     for (i = 0; i < MEM_SIZE; ++i)
 *      mmData[i] = i + 0.1;   
 *
 * // (3) Use
 *     double *db3Ptr = MemManager_getMemory(&MM);
 *     double *db2Ptr = MemManager_getMemory(&MM);
 *     MemManager_print(&MM);
 *    
 *     printf("\nAfter returnMemory()...\n");
 *     MemManager_returnMemory(&MM, db3Ptr);
 *     MemManager_returnMemory(&MM, db2Ptr);
 *     MemManager_print(&MM);
 * // ----- end of how to use -----     
 *
 * @author Konrad Lorincz <konrad@eecs.harvard.edu>
 * @date   March 15, 2004
 */      
#ifndef MEMMANAGER_H
#define MEMMANAGER_H                 
#include "AM.h"
#include "PrintfUART.h"


typedef struct MemManager {
    void* *freeListPtr;
    uint16_t stackSize;
    uint16_t capacity;
} MemManager;
typedef MemManager* MemManagerPtr;


// ========================== Implementation ==========================

void MemManager_init(MemManager *MMPtr, void* mmData, uint16_t sizeOfType, void* mmFreeListPtr[], uint16_t mmCapacity)
{
    uint16_t i = 0;
    MMPtr->freeListPtr = mmFreeListPtr;
    MMPtr->stackSize = mmCapacity;
    MMPtr->capacity = mmCapacity;

    for (i = 0; i < mmCapacity; ++i)
        MMPtr->freeListPtr[i] = mmData+(i*sizeOfType); //&mmData[i*sizeOfType];
}

void* MemManager_getMemory(MemManager *MMPtr)
{
    NOprintfUART("MemManager - getMemory(): beforeGet_stackSize=%i, ", MMPtr->stackSize);
    
    if (MMPtr->stackSize > 0) {
        MMPtr->stackSize = MMPtr->stackSize - 1;
        NOprintfUART("objPtr=0x%x\n", MMPtr->freeListPtr[MMPtr->stackSize]);
        return MMPtr->freeListPtr[MMPtr->stackSize];
    }
    else {
        printfUART("\nMemManager - getMemory(): FATAL ERROR! out of memory!", "");
        //EXIT_PROGRAM = 1;
        return NULL;     
    }
}

result_t MemManager_returnMemory(MemManager *MMPtr, void* objPtr)
{
    NOprintfUART("MemManager - returnMemory(): beforeRet_stackSize=%i, objPtr=0x%x\n", MMPtr->stackSize, objPtr);

    if (MMPtr->stackSize < MMPtr->capacity) {
        MMPtr->freeListPtr[MMPtr->stackSize] = objPtr;
        MMPtr->stackSize =  MMPtr->stackSize + 1;
        return SUCCESS;
    }
    else {
        printfUART("MemManager - returnMemory(): FATAL ERROR! can't return memory, freeList is full!", "");
        //EXIT_PROGRAM = 1;
        return FAIL;                   
    }
}

uint16_t MemManager_sizeAvailableMemory(MemManager *MMPtr)
{
    return MMPtr->stackSize;
}

void MemManager_print(MemManager *MMPtr)
{
    int i = 0;
    printfUART(">>>-----MemManager: (0x%x)----->>>\n", MMPtr);
    printfUART("capacity= %i\n", MMPtr->capacity);
    printfUART("stackSize= %i\n", MMPtr->stackSize);

    for (i = 0; i < MMPtr->capacity; ++i) {
        if (i < MMPtr->stackSize)
            printfUART( "    [freeList[%i]: 0x%x: -> 0x%x]\n", i, &(MMPtr->freeListPtr[i]), MMPtr->freeListPtr[i]);
    }
    printfUART("<<<------------------------------<<<\n", "");

}                                   
                                    
#endif
