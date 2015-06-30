/*
 * Copyright (c) 2007
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
 * Description - defines the DataStore Block
 *
 * @author: Konrad Lorincz
 * @version 1.0 - 4/20/05
 */
#ifndef BLOCK_H
#define BLOCK_H
  // Needed by Block_print(), when the block data part is a SampleChunk.  
  // Otherwise it shouldn't be here
  #ifdef BLOCK_PRINT_SAMPLECHUNK
    #include "SampleChunk.h"  
  #endif


typedef uint32_t  blocksqnnbr_t;


#ifndef BLOCK_DATA_SIZE
#define BLOCK_DATA_SIZE (256 - sizeof(blocksqnnbr_t)) // minus the sqnNbr size
#endif

typedef struct Block {
    blocksqnnbr_t sqnNbr;
    uint8_t       data[BLOCK_DATA_SIZE];
} Block;





// =========================== Methods ===============================
// --------------------------- Block -------------------------------
/**
 * Initializes a block to a default value.
 */
inline void Block_init(Block *blockPtr)
{      
    uint32_t i = 0;
    blockPtr->sqnNbr = 0;

    for (i = 0; i < sizeof(blockPtr->data); ++i)
        blockPtr->data[i] = 0;
}

/**
 * Prints the content of a block.
 */
inline void Block_print(Block *blockPtr)
{
  #ifdef PRINTFUART_ENABLED
    printfUART("----- Block_print() - for Block (%p) ----- \n", blockPtr);
    printfUART("    sqnNbr= %lu\n", blockPtr->sqnNbr);  // KLDEBUG - sqnNbr is probably 64-bit while %i is 16-bit!!!

  #ifdef BLOCK_PRINT_SAMPLECHUNK
    SampleChunk_print( (SampleChunk*)blockPtr->data );
  #else  
    //printfUART("    --- data part: hex dump ---\n", "");
    {uint32_t i = 0;
    uint8_t hexVal = 0x0;
    for (i = 0; i < sizeof(blockPtr->data); ++i) {
        hexVal = (uint8_t) *(((uint8_t*)&blockPtr->data) + i);
        if (hexVal <= 0x0f)
            {printfUART("0%x ", hexVal);} 
        else
            {printfUART("%x ", hexVal);}

        if ( (i+1) == sizeof(blockPtr->data) ||
             (i+1) % 16 == 0 ) 
            {printfUART("\n");}
        else if ((i+1) % 4 == 0)
            {printfUART("   ");}        
    }}
  #endif
     
    printfUART("------------------------------------------------\n");
  #endif
}



#endif
