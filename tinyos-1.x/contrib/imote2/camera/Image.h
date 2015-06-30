/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2005 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/** 
 * Description - An Image data structure.
 *
 * @author Konrad Lorincz
 * @version 1.0, August 20, 2005
 */
#ifndef IMAGE_H
#define IMAGE_H   
#include "RegUtils.h"
#ifdef PRINTFUART_ENABLED
#include "PrintfUART.h"
#endif



// ========================== Datastructure ==========================
#define Image_MAX_ROWS  128          //64     // 32
#define Image_MAX_COLS  (128/2)     //(64/2) // 64
#define Image_DATA_SIZE (Image_MAX_ROWS*Image_MAX_COLS)
typedef struct Image 
{
    // the actual nbr of row and cols in the image instance
    uint16_t nbrRows;    // y-direction
    uint16_t nbrCols;    // x-direction
    uint32_t curPixel;   // nbr pixels filled

    // the image buffer
    uint32_t data[Image_DATA_SIZE];   // The data is alligned from data[baseIndex]
} Image;               
Image image;



// ========================== Implementation ==========================
void Image_init(Image *ImgPtr)
{
    uint32_t i = 0;
    ImgPtr->nbrRows = 0;
    ImgPtr->nbrCols = 0;
    ImgPtr->curPixel = 0;

    for (i = 0; i < Image_DATA_SIZE; ++i)
        ImgPtr->data[i] = 0xffffffff;  // known pattern
}

void Image_print(Image *ImgPtr, uint16_t granularity)
{
#ifdef PRINTFUART_ENABLED
    uint32_t i = 0;
    printfUART("============= Image ===============\n", "");
    printfUART("  nbrRows= %i\n", ImgPtr->nbrRows);
    printfUART("  nbrCols= %i\n", ImgPtr->nbrCols);
    printfUART("  curPixel= %i\n\n", ImgPtr->curPixel);

    for (i = 0; i < Image_DATA_SIZE; i += granularity) {
        printfUART("  data[%i]=   (%x)  (%x)  ", (uint16_t)i, 
            ((ImgPtr->data[i] >> 16) & 0xf), 
            (ImgPtr->data[i] & 0xf) ); 
        RegUtils_printData(ImgPtr->data[i], 32);
    }
    printfUART("===================================\n", "");
#endif
}



#endif
