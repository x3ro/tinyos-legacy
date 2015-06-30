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
 * @author Konrad Lorincz
 * @version 1.0, August 15, 2005
 */
#ifndef HWTEST_H
#define HWTEST_H

enum {
    cmd_I2C_init = 1000,
    cmd_I2C_enable,
    cmd_I2C_reset,
    cmd_I2C_loadIDBRwithAddr,
    cmd_I2C_loadIDBRwithData,
    cmd_I2C_sendSTARTandRepeatedSTART,
    cmd_I2C_sendNoSTARTorSTOP,
    cmd_I2C_sendSTOP,
    cmd_I2C_clearInterruptTxDone,
    cmd_I2C_clearInterruptArbitrLoss,
    cmd_I2C_clearStateSend,

    cmd_I2C_sendStart = 2000,
    cmd_I2C_sendEnd,
    cmd_I2C_read,
    cmd_I2C_write,

    cmd_I2CTR_readReg = 3000,
    cmd_I2CTR_writeReg,
    cmd_I2CTR_writeRegBits,
    cmd_I2CTR_setBit,
    cmd_I2CTR_clearBit,

    cmd_cameraReset = 4000,
    cmd_cameraTakePicture,
    cmd_cameraSetImageSize,

    cmd_pinSet = 5000,
    cmd_pinClear,

    cmd_RegUtils_setBit = 6000,
    cmd_RegUtils_clearBit,
    cmd_RegUtils_print,

    cmd_Image_print = 7000,
    cmd_Image_init,
    cmd_Image_send,    
    
    temp_CIF_enableIRQ,
                             
    print_DMA,
    print_ICR,
    print_ISR,
    print_ISAR,
    print_IDBR,
    print_IBMR,
};

enum {
    REGID_IDBR = 0,

    REGID_CICR0 = 10,
    REGID_CICR1,
    REGID_CICR2,
    REGID_CICR3,
    REGID_CICR4,
    REGID_CITOR,
    REGID_CISR,
    REGID_CIFR,
    REGID_CIBR0,
    REGID_CIBR1,
    REGID_CIBR2,

    REGID_DMA,

    REGID_ICHP,
};

// For Transmission
enum { AM_HWTESTMSG = 19 };
typedef struct HWTestMsg
{
    uint16_t cmdID;
    uint8_t param1;
    uint8_t param2;
    uint8_t param3;
    uint8_t param4;
} HWTestMsg;

#endif
