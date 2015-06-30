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
 * Description - I2C Byte Level Transaction
 *
 * @author Konrad Lorincz
 * @version 1.0, July 11, 2005
 */
includes pxa27x_registers;
includes HWTest;
includes RegUtils;
includes PrintfUART;

module I2CTransactionM 
{
    provides interface I2CTransaction as I2CTransaction[uint8_t id];
    
    uses interface I2C;
}
implementation 
{
    // =========================== Data =============================     
    enum {
        REQUEST_NONE = 1,
        REQUEST_READ, 
        REQUEST_WRITE,
        REQUEST_WRITEBITS,
        REQUEST_SETBIT,
        REQUEST_CLEARBIT
    };
    uint8_t request = REQUEST_NONE;    
    uint8_t requestNextStep = 0;
    uint8_t requestInterfaceID;
         
    uint8_t requestDeviceAddr7Bit;
    uint8_t requestRegAddr;
    uint8_t requestStartBitIndexLSB;
    uint8_t requestNbrBits;
    uint8_t requestBitValues;
    uint8_t requestData;

    uint8_t readData;


    // =========================== Methods ==========================

    // -------------------------- Internal private helper functions -----
    uint8_t getDataFromAddr(uint8_t targetSlaveAddr7Bit, bool isRnWTypeRead)
    {
        uint8_t data = (targetSlaveAddr7Bit << 1); // upper 7-bits
        if (isRnWTypeRead)
            data |= (1 << 0); // for Read, RnW=1
        else
            data &= ~(1 << 0); // for Write, RnW=0

        return data;
    }

    void resetRequestState()
    {
        atomic {
            request = REQUEST_NONE;
            requestNextStep = 0;
        }
    }

    void signalI2CTransactionEvent(result_t result)
    {  
        switch (request) {
            case REQUEST_NONE:
                return;

            case REQUEST_READ:
                  printfUART(" ===============> runReadStep done <===============\n", "");
                  RegUtils_printIDBR();
                  printfUART(" =================================================\n", "");                
                resetRequestState();
                signal I2CTransaction.readDone[requestInterfaceID](result, readData);    
                break;

            case REQUEST_WRITE:
                resetRequestState();
                signal I2CTransaction.writeDone[requestInterfaceID](result);    
                break;

            case REQUEST_WRITEBITS:
                resetRequestState();
                signal I2CTransaction.writeBitsDone[requestInterfaceID](result);    
                break;

            case REQUEST_SETBIT:
                resetRequestState();
                signal I2CTransaction.setBitDone[requestInterfaceID](result);    
                break;

            case REQUEST_CLEARBIT:
                resetRequestState();
                signal I2CTransaction.clearBitDone[requestInterfaceID](result);    
                break;

            default:
                printfUART("I2CTransactionM:signalI2CTransactionEvent() - ERROR, bad request= %i\n", request);
                break;
        } 
    }

    void runReadStep(uint8_t step)
    {
        result_t result = FAIL;

        switch (step) {
            case 0:
                result = call I2C.sendStart();
                break;
            case 1:                                         
                result = call I2C.write( getDataFromAddr(requestDeviceAddr7Bit, FALSE) );
                break;
            case 2:
                result = call I2C.write(requestRegAddr);
                break;
            case 3:
                result = call I2C.sendStart();
                break;
            case 4:
                result = call I2C.write( getDataFromAddr(requestDeviceAddr7Bit, TRUE) );
                break;
            case 5:
                result = call I2C.sendEnd();
                break;
            case 6:
                result = call I2C.read(FALSE);
                break;
            case 7: // we are done
                signalI2CTransactionEvent(SUCCESS);
                return;
            default:                  
                printfUART("I2CTransactionM:runWriteStep() - ERROR, bad step= %i\n", step);
                break;
        }

        if (result == FAIL) {
            printfUART("I2CTransactionM:runReadStep() - ERROR, result==FAIL, step= %i\n", step);
            signalI2CTransactionEvent(FAIL);
        }
    }

    void runWriteStep(uint8_t step)
    {
        result_t result = FAIL;

        switch (step) {
            case 0:
                result = call I2C.sendStart();
                break;
            case 1:                                         
                result = call I2C.write( getDataFromAddr(requestDeviceAddr7Bit, FALSE) );
                break;
            case 2:
                result = call I2C.write(requestRegAddr);
                break;
            case 3:
                result = call I2C.sendEnd();
                break;
            case 4:
                result = call I2C.write(requestData);
                break;
            case 5: // we are done
                signalI2CTransactionEvent(SUCCESS);
                return;
            default:                  
                printfUART("I2CTransactionM:runWriteStep() - ERROR, bad step= %i\n", step);
                break;
        }

        if (result == FAIL) {
            printfUART("I2CTransactionM:runWriteStep() - ERROR, result==FAIL\n", "");
            signalI2CTransactionEvent(FAIL);
        }
    }


    void handleI2CEventDone(result_t result)
    {
        requestNextStep++;

        switch (request) {
            case REQUEST_NONE:
                return;

            case REQUEST_READ:
                if (result == FAIL)
                    signalI2CTransactionEvent(FAIL);    
                else
                    runReadStep(requestNextStep);
                break;

            case REQUEST_WRITE:
                if (result == FAIL)
                    signalI2CTransactionEvent(FAIL);    
                else
                    runWriteStep(requestNextStep);
                break;

            case REQUEST_WRITEBITS:
            case REQUEST_SETBIT:
            case REQUEST_CLEARBIT:
                if (result == FAIL)
                    signalI2CTransactionEvent(FAIL);    
                else {
                    if (requestNextStep < 7)
                        runReadStep(requestNextStep);
                    else {
                        if (requestNextStep == 7) {
                            uint8_t i = 0;
                            uint8_t movedBitValues = 0;
                            movedBitValues = (requestBitValues << requestStartBitIndexLSB);

                            // clear the positions to be set
                            for (i = 0; i < requestNbrBits; ++i)
                                requestData &= ~( (1 << (i+requestStartBitIndexLSB)) );
                            
                            requestData |= movedBitValues;    
                        }
                    
                        if (requestNextStep < 12)
                            runWriteStep(requestNextStep - 7);
                        else // we are done
                            signalI2CTransactionEvent(SUCCESS);
                    }
                }
                break;

            default:
                printfUART("I2CTransactionM:handleI2CEventDone() - ERROR, bad result= %i\n", result);
                break;
        }

    }
         

    // -------------------------- I2CTransaction interface ------------------------------
    command result_t I2CTransaction.read[uint8_t id](uint8_t targetSlaveAddr7Bit, uint8_t regAddr)
    {
        atomic {
            if (request != REQUEST_NONE) {
                printfUART("I2CTransaction.read[id=%i] - ERROR request= %i, regAddr= %i\n", id, request, regAddr);
                return FAIL;
            }
        }        

        atomic {
            request = REQUEST_READ;
            requestNextStep = 0;

            requestInterfaceID = id;
            requestDeviceAddr7Bit = targetSlaveAddr7Bit;
            requestRegAddr = regAddr;
        }

        runReadStep(requestNextStep);

        return SUCCESS;
    }

    command result_t I2CTransaction.write[uint8_t id](uint8_t targetSlaveAddr7Bit, uint8_t regAddr, uint8_t data)
    {
        atomic {
            if (request != REQUEST_NONE) {
                printfUART("I2CTransaction.write[id=%i] - ERROR request= %i, regAddr= %i\n", id, request, regAddr);
                return FAIL;
            }
        }        

        atomic {
            request = REQUEST_WRITE;
            requestNextStep = 0;

            requestInterfaceID = id;
            requestDeviceAddr7Bit = targetSlaveAddr7Bit;
            requestRegAddr = regAddr;
            requestData = data;
        }

        runWriteStep(requestNextStep);
        return SUCCESS;
    }

    command result_t I2CTransaction.writeBits[uint8_t id](uint8_t targetSlaveAddr7Bit, uint8_t regAddr, 
                                              uint8_t startBitIndexLSB, uint8_t nbrBits, uint8_t bitValues)
    {
        atomic {
            if (request != REQUEST_NONE) {
                printfUART("I2CTransaction.writeBits[id=%i] - ERROR request= %i, regAddr= %i\n", id, request, regAddr);
                return FAIL;
            }
        }

        atomic {
            request = REQUEST_WRITEBITS;
            requestNextStep = 0;

            requestInterfaceID = id;
            requestDeviceAddr7Bit = targetSlaveAddr7Bit;
            requestRegAddr = regAddr;
            requestStartBitIndexLSB = startBitIndexLSB;
            requestNbrBits = nbrBits;
            requestBitValues = bitValues;
        }

        runReadStep(requestNextStep);
        return SUCCESS;     
    }

    command result_t I2CTransaction.setBit[uint8_t id](uint8_t targetSlaveAddr7Bit, uint8_t regAddr, uint8_t bitIndex)
    {
        atomic {
            if (request != REQUEST_NONE) {
                printfUART("I2CTransaction.setBits[id=%i] - ERROR request= %i, regAddr= %i\n", id, request, regAddr);
                return FAIL;
            }
        }        

        atomic {
            request = REQUEST_SETBIT;
            requestNextStep = 0;

            requestInterfaceID = id;
            requestDeviceAddr7Bit = targetSlaveAddr7Bit;
            requestRegAddr = regAddr;
            requestStartBitIndexLSB = bitIndex;
            requestNbrBits = 1;
            requestBitValues = 1;
        }

        runReadStep(requestNextStep);
        return SUCCESS;     
    }

    command result_t I2CTransaction.clearBit[uint8_t id](uint8_t targetSlaveAddr7Bit, uint8_t regAddr, uint8_t bitIndex)
    {
        atomic {
            if (request != REQUEST_NONE) {
                printfUART("I2CTransaction.clearBits[id=%i] - ERROR request= %i, regAddr= %i\n", id, request, regAddr);
                return FAIL;
            }
        }        

        atomic {
            request = REQUEST_SETBIT;
            requestNextStep = 0;

            requestInterfaceID = id;
            requestDeviceAddr7Bit = targetSlaveAddr7Bit;
            requestRegAddr = regAddr;
            requestStartBitIndexLSB = bitIndex;
            requestNbrBits = 1;
            requestBitValues = 0;
        }

        runReadStep(requestNextStep);
        return SUCCESS;     
    }
    

    default event void I2CTransaction.readDone[uint8_t id](result_t result, uint8_t data) {return;}
    default event void I2CTransaction.writeDone[uint8_t id](result_t result)              {return;}
    default event void I2CTransaction.writeBitsDone[uint8_t id](result_t result)          {return;}
    default event void I2CTransaction.setBitDone[uint8_t id](result_t result)             {return;}
    default event void I2CTransaction.clearBitDone[uint8_t id](result_t result)           {return;}
    

    // -------------------------- I2C interface ------------------------------
    event result_t I2C.sendStartDone() 
    {
        //printfUART("I2CTransactionM:I2C.sendStartDone() - called\n", "");
        handleI2CEventDone(SUCCESS);
        return SUCCESS;
    }

    event result_t I2C.sendEndDone()  
    {
        //printfUART("I2CTransactionM:I2C.sendEndDone() - called\n", "");
        handleI2CEventDone(SUCCESS);
        return SUCCESS;
    }

    event result_t I2C.readDone(char data) 
    {
        atomic readData = data;
        handleI2CEventDone(SUCCESS);
        return SUCCESS;
    }

    event result_t I2C.writeDone(bool success) 
    {
        handleI2CEventDone(success);
        return SUCCESS;
    }

}


