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
 * Description - IMote2 Hardware integration test module.
 *
 * @author Konrad Lorincz
 * @version 1.0, July 11, 2005
 */
#ifndef REGUTILS_H
#define REGUTILS_H
#include "PrintfUART.h"


uint8_t RegUtils_readBit(uint32_t data, uint8_t bitIndex)
{
    return ((data >> bitIndex) & 1);
}

void RegUtils_printByteArray(uint8_t byteArray[], uint16_t nbrBytes)
{
    uint16_t b;  // byte index
    uint16_t i;  // bit index
    for (b = nbrBytes-1; TRUE; --b) {
        for (i = 8-1; TRUE; --i) {
            printfUART("%i", ((byteArray[b] >> i) & 1));
            if (i == 0)     {break;}
            else if (i % 4 == 0) {printfUART(" ", "");}
        }
        printfUART(":[0x%x]  ", &byteArray[b]);
        if (b == 0)            {break;} 
    }
    printfUART("\n", "");
}

void RegUtils_printAddrBits(uint8_t* startAddrPtr, uint16_t nbrBits)
{
    uint16_t i;  // bit index
 
    for (i = nbrBits-1; TRUE; --i) {
        uint8_t* currBytePtr = (startAddrPtr + (i/8));
        uint8_t currBitIndex = i % 8;
        uint8_t currBitValue = ((*currBytePtr) >> currBitIndex) & 1;        
        printfUART("%i", currBitValue);

        if (i % 8 == 0)        {printfUART(":[0x%x]  ", currBytePtr);}
        else if (i % 4 == 0)   {printfUART(" ", "");}
        if (i == 0)            {break;} 
    }
    printfUART("\n", "");
}


void RegUtils_printData(uint32_t data, uint16_t nbrBits)
{
    uint16_t i;
    for (i = nbrBits-1; TRUE; --i) { 
        printfUART("%i", RegUtils_readBit(data, i) );

        if (i == 0)           {break;}
        else if (i % 16 == 0) {printfUART("  ", "");}
        else if (i % 4  == 0) {printfUART(" ", "");}
    }
    printfUART("\n", "");
}


void RegUtils_printICR()   {printfUART("ICR= ", "");  RegUtils_printData(ICR, 16);}
void RegUtils_printISR()   {printfUART("ISR= ", "");  RegUtils_printData(ISR, 11);}
void RegUtils_printISAR()  {printfUART("ISAR= ", ""); RegUtils_printData(ISAR, 7);}
void RegUtils_printIDBR()  {printfUART("IDBR= ", ""); RegUtils_printData(IDBR, 8);}       
void RegUtils_printIBMR()  {printfUART("IBMR= ", ""); RegUtils_printData(IBMR, 2);}       


// -------------------- New ------------------------
void RegUtils_print(uint8_t regID)
{  
    switch(regID) {
        case REGID_CICR0:   {printfUART("CICR0= ", ""); RegUtils_printData(CICR0, 32);}   return;
        case REGID_CICR1:   {printfUART("CICR1= ", ""); RegUtils_printData(CICR1, 32);}   return;
        case REGID_CICR2:   {printfUART("CICR2= ", ""); RegUtils_printData(CICR2, 32);}   return;
        case REGID_CICR3:   {printfUART("CICR3= ", ""); RegUtils_printData(CICR3, 32);}   return;
        case REGID_CICR4:   {printfUART("CICR4= ", ""); RegUtils_printData(CICR4, 27);}   return;
        case REGID_CITOR:   {printfUART("CITOR= ", ""); RegUtils_printData(CITOR, 32);}   return;
        case REGID_CISR:    {printfUART("CISR= ", "");  RegUtils_printData(CISR, 16);}    return;
        case REGID_CIFR:    {printfUART("CIFR= ", "");  RegUtils_printData(CIFR, 30);}    return;
        case REGID_CIBR0:   {printfUART("CIBR0= ", ""); RegUtils_printData(CIBR0, 32);}   return;
        case REGID_CIBR1:   {printfUART("CIBR1= ", ""); RegUtils_printData(CIBR1, 32);}   return;
        case REGID_CIBR2:   {printfUART("CIBR2= ", ""); RegUtils_printData(CIBR2, 32);}   return;
        // Interrupt registers
        case REGID_ICHP:    {printfUART("ICHP= ", "");  RegUtils_printData(ICHP, 32);}    return;
        default:
            printfUART("RegUtils_print() - ERROR, invalid regID= %i\n", regID);    
            break;
    } 
} 
uint32_t RegUtils_read(uint8_t regID)
{  
    switch(regID) {
        case REGID_IDBR:        return IDBR;

        case REGID_CICR0:       return CICR0;
        case REGID_CICR1:       return CICR1;
        case REGID_CICR2:       return CICR2;
        case REGID_CICR3:       return CICR3;
        case REGID_CICR4:       return CICR4;
        case REGID_CITOR:       return CITOR;
        case REGID_CISR:        return CISR;
        case REGID_CIFR:        return CIFR;
        case REGID_CIBR0:       return CIBR0;
        case REGID_CIBR1:       return CIBR1;
        case REGID_CIBR2:       return CIBR2;
        // Interrupt registers
        case REGID_ICHP:        return ICHP;
        default:
            printfUART("RegUtils_read() - ERROR, invalid regID= %i\n", regID);
            return 0;    
            break;
    } 
}
void RegUtils_write(uint8_t regID, uint32_t data)
{  
    switch(regID) {
        case REGID_IDBR:        IDBR = data;    break;

        case REGID_CICR0:       CICR0 = data;   break;
        case REGID_CICR1:       CICR1 = data;   break;
        case REGID_CICR2:       CICR2 = data;   break;
        case REGID_CICR3:       CICR3 = data;   break;
        case REGID_CICR4:       CICR4 = data;   break;
        case REGID_CITOR:       CITOR = data;   break;
        case REGID_CISR:        CISR  = data;    break;
        case REGID_CIFR:        CIFR  = data;    break;
        case REGID_CIBR0:       CIBR0 = data;    break;
        case REGID_CIBR1:       CIBR1 = data;    break;
        case REGID_CIBR2:       CIBR2 = data;    break;
        // Interrupt registers
        case REGID_ICHP:        ICHP = data;    break;
        default:
            printfUART("RegUtils_write() - ERROR, invalid regID= %i\n", regID);    
            break;
    } 
}

void RegUtils_setBit(uint8_t regID, uint8_t bitIndex)
{   
    uint32_t regData = RegUtils_read(regID);
    regData |= (1 << bitIndex);
    RegUtils_write(regID, regData);
}

void RegUtils_clearBit(uint8_t regID, uint8_t bitIndex)
{   
    uint32_t regData = RegUtils_read(regID);
    regData &= ~(1 << bitIndex);
    RegUtils_write(regID, regData);
}


#endif
