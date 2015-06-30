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
includes pxa27x_registers;
includes HWTest;
includes KAC9648;
includes RegUtils;
includes Image;
includes PrintfUART;

module HWTestM 
{
    provides interface StdControl;
    
    uses interface Timer;
    uses interface Leds;
    uses interface SendMsg;
    uses interface ReceiveMsg;
    uses interface I2CTransaction;    // for debugging
    uses interface KAC9648;
    uses interface PXA27XInterrupt as I2CIrq;
    uses interface Image;
}
implementation 
{
    // =========================== Data ============================= 
    uint16_t cntTimerFired = 0;
    uint32_t tempReg = 0;
    TOS_Msg sendMsg;
    HWTestMsg *hwtSendMsgPtr;

    uint32_t nbrTimesLooped = 0;
    uint32_t temp1 = 0;
    uint32_t temp2 = 0;
    uint32_t temp3 = 0;

    // =========================== Methods ==========================
    void runCmd(uint16_t cmdID, uint8_t param1, uint8_t param2, uint8_t param3, uint8_t param4);




    command result_t StdControl.init() 
    {
        hwtSendMsgPtr = (HWTestMsg*) sendMsg.data;
        printfUART_init();
        call Leds.init();
        return SUCCESS;
    }



    command result_t StdControl.start() 
    {
        printfUART("HWTestM:StdControl.start() - called\n", "");
          
        call I2CIrq.allocate(); // generate an IRQ interrupt
        call I2CIrq.enable();   // enable the I2C interrupt mask

        return call Timer.start(TIMER_REPEAT, 5000);
    }

    command result_t StdControl.stop() 
    {
        return call Timer.stop();
    }

    void sendHWTMsg(uint8_t data)
    {
        hwtSendMsgPtr->param1 = data;
        
        if ( (call SendMsg.send(TOS_BCAST_ADDR, sizeof(HWTestMsg), &sendMsg)) == FAIL ) {
            printfUART("sendHWTMsg() - FAILED to send msg()\n", "");        
        }
    }
    
    event result_t SendMsg.sendDone(TOS_MsgPtr msgPtr, result_t sendResult)
    {
        return SUCCESS;
    }

    event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msgPtr)
    {
        HWTestMsg *hwtMsgPtr = (HWTestMsg*) msgPtr->data;
        call Leds.greenToggle();
        atomic { printfUART(">>>>> ReceiveMsg.receive() - called, param1= %i\n", hwtMsgPtr->cmdID); }
        runCmd(hwtMsgPtr->cmdID, hwtMsgPtr->param1, hwtMsgPtr->param2, 
                                 hwtMsgPtr->param3, hwtMsgPtr->param4);
        return msgPtr;
    }




    void runCmd(uint16_t cmdID, uint8_t param1, uint8_t param2, uint8_t param3, uint8_t param4)
    {
        /*printfUART("\n\nbeforeRunCmd() - cmdID= %i, param1= %i, param2= %i\n", cmdID, param1, param2);
        RegUtils_printISR();
        RegUtils_printICR();
        RegUtils_printIDBR();*/                  

        switch (cmdID) {

            case cmd_I2CTR_readReg:                    
                call I2CTransaction.read(CAMERA_SLAVEADDR, param1);
                break;
            case cmd_I2CTR_writeReg:                    
                call I2CTransaction.write(CAMERA_SLAVEADDR, param1, param2);
                break;
            case cmd_I2CTR_writeRegBits:                    
                call I2CTransaction.writeBits(CAMERA_SLAVEADDR, param1, param2, param3, param4);
                break;
            case cmd_I2CTR_setBit:                    
                call I2CTransaction.setBit(CAMERA_SLAVEADDR, param1, param2);
                break;
            case cmd_I2CTR_clearBit:                    
                call I2CTransaction.clearBit(CAMERA_SLAVEADDR, param1, param2);
                break;

            case cmd_cameraReset:
                call KAC9648.reset();
                break;
            case cmd_cameraTakePicture:
                call KAC9648.takePicture();
                break;
            case cmd_cameraSetImageSize:
                {
                result_t result = FAIL;                
                if (param1 == 1)
                    result = call KAC9648.setImageSize(16, 8);
                else if (param1 == 2)
                    result = call KAC9648.setImageSize(64, 8);
                else if (param1 == 3)
                    result = call KAC9648.setImageSize(640, 480);
                else
                    result = call KAC9648.setImageSize(1280, 1024);

                if (result == FAIL)
                    sendHWTMsg(0);
                }
                break;

            case cmd_pinSet:
                TOSH_SET_SNAPSHOT_PIN();
                break;
            case cmd_pinClear:
                TOSH_CLR_SNAPSHOT_PIN();
                break;

            case cmd_RegUtils_setBit:
                RegUtils_setBit(param1, param2);
                sendHWTMsg(1);
                break;
            case cmd_RegUtils_clearBit:
                RegUtils_clearBit(param1, param2);
                sendHWTMsg(1);
                break;
            case cmd_RegUtils_print:
                RegUtils_print(param1);
                sendHWTMsg(1);
                break;

            case cmd_Image_print:
                Image_print(&image, param1);
                break;
            case cmd_Image_init:
                Image_init(&image);
                break;
            case cmd_Image_send:
                call Image.send();
                break;

            case print_DMA:
                switch(param1) {
                    case 51: {printfUART("DDADR%i= ", param2); RegUtils_printData(DDADR(param2), 32);}  break;
                    case 52: {printfUART("DSADR%i= ", param2); RegUtils_printData(DSADR(param2), 32);}  break;
                    case 53: {printfUART("DTADR%i= ", param2); RegUtils_printData(DTADR(param2), 32);}  break;
                    case 54: {printfUART("DCMD%i= ", param2);  RegUtils_printData(DCMD(param2), 32);}   break;
                    case 55: {printfUART("DCSR%i= ", param2);  RegUtils_printData(DCSR(param2), 32);}   break;
                    case 56: {printfUART("DINT= ", "");        RegUtils_printData(DINT, 32);}           break;
                    case 57: {printfUART("DALGN= ", "");       RegUtils_printData(DALGN, 32);}          break;
                }                                                                                                       
                break;  
            case print_ICR:
                RegUtils_printICR();
                break;
            case print_ISR:
                RegUtils_printISR();
                break;
            case print_ISAR:
                RegUtils_printISAR();
                break;
            case print_IDBR:
                RegUtils_printIDBR();
                sendHWTMsg((uint8_t) IDBR);
                break;
            case print_IBMR:
                RegUtils_printIBMR();
                break;

            case temp_CIF_enableIRQ:
                //CIF_enableInterrupts();
                break;

            default:
                printfUART("runCmd() - WARINING!, UNKNOWN cmdID= %i, param1= %i, param2= %i\n", cmdID, param1, param2);
                break;
        }   
        
        /*printfUART("\n\nafterRunCmd() - cmdID= %i, param1= %i, param2= %i\n", cmdID, param1, param2);
        RegUtils_printISR();
        RegUtils_printICR();
        RegUtils_printIDBR();*/                  
    }      

    event result_t Timer.fired()
    {
        call Leds.redToggle();
        cntTimerFired++;
        if (cntTimerFired % 4 == 0) {
            {printfUART("Timer.fired() - cntTimerFired= %i, nbrTimesLooped= %i\n", cntTimerFired, nbrTimesLooped);}
            //call KAC9648.takePicture();
            sendHWTMsg(3);
        }
        
        return SUCCESS;
    }


    // ---------------------- KAC9648 interface -------------------------
    event void KAC9648.resetDone(result_t result)
    {
        printfUART("HWTestM: KAC9648.resetDone() - called, result= %i\n", result);
        sendHWTMsg(result);
    }

    event void KAC9648.setImageSizeDone(result_t result)
    {
        printfUART("HWTestM: KAC9648.setImageSizeDone() - called, result= %i\n", result);
        sendHWTMsg(result);
    }
    

    // ---------------------- I2CTransaction interface --------------
    event void I2CTransaction.readDone(result_t result, uint8_t data)
    {
        printfUART("HWTestM:I2CTransaction.readDone() - called, result= %i, data= %i\n", result, data);
        sendHWTMsg(data);
    }

    event void I2CTransaction.writeDone(result_t result)
    {
        printfUART("HWTestM:I2CTransaction.writeDone() - called, result= %i\n", result);
        sendHWTMsg(result);
    }

    event void I2CTransaction.writeBitsDone(result_t result)
    {
        printfUART("HWTestM:I2CTransaction.writeBitsDone() - called, result= %i\n", result);
        sendHWTMsg(result);
    }

    event void I2CTransaction.setBitDone(result_t result)
    {
        printfUART("HWTestM:I2CTransaction.setBitDone() - called, result= %i\n", result);
        sendHWTMsg(result);
    }

    event void I2CTransaction.clearBitDone(result_t result)
    {
        printfUART("HWTestM:I2CTransaction.clearBitDone() - called, result= %i\n", result);
        sendHWTMsg(result);
    }


    // ---------------------- PXA27XInterrupt interface -------------------------
    async event void I2CIrq.fired() 
    {
        atomic { printfUART("\n>>>>>>>>>> IRQ fired <<<<<<<<<<<<<<\n", ""); }
    }

    // ---------------------- Image interface -------------------------
    event void Image.sendDone(result_t result)
    {
        printfUART("\n******** Image.sendDone() - result= %i ***********\n", result); 
    }

}


