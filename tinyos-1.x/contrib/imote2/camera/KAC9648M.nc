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
 * Description - Kodak KAC-9648 camera module
 * 
 * @author Konrad Lorincz
 * @version 1.0, August 10, 2005
 */
includes pxa27x_registers;
includes PXA27XQuickCaptInt;
includes KAC9648;
includes Image;
includes PrintfUART;

module KAC9648M
{
    provides interface StdControl;
    provides interface KAC9648;
    
    uses interface Timer as Timer_ResetSnapshotPin;
    uses interface PXA27XQuickCaptInt;
    uses interface I2CTransaction;
}
implementation
{
    // ======================= Data ==================================
    enum{ minX = 4, maxX = 1283+1,
          minY = 4, maxY = 1027+1,
    };

    enum {SNAPSHOT_PIN_RESET_DELAY = 4000L };
    enum {
        STATE_IDLE = 1,
        STATE_RESET,
        STATE_SETIMAGESIZE,
    };
    uint8_t state = STATE_IDLE;
    uint8_t stateNextStep = 0;

    // For setting the image size
    uint16_t startX;
    uint16_t endX;
    uint16_t startY;
    uint16_t endY;

    uint16_t cntSOF = 0;
    uint16_t cntEOF = 0;
    uint16_t cntEOL = 0;
    uint16_t cntRDA[3];
    uint16_t cntIFO[3];

   
    // ======================= Methods ===============================

    // ----------------------- Internal private helper functions -----
    void resetState()
    {
        atomic {
            state = STATE_IDLE;
            stateNextStep = 0;
        }
    }         

    void KAC9648_configurePins()
    {
        TOSH_MAKE_SNAPSHOT_OUTPUT();
    }

    void signalStateEvent(result_t result)
    {
        switch (state) {
            case STATE_IDLE:
                break;

            case STATE_RESET:
                resetState();
                call KAC9648.setImageSize(Image_MAX_COLS*2, Image_MAX_ROWS);  // KLHACK - shold not be here!!!
                signal KAC9648.resetDone(result);
                break;                            

            case STATE_SETIMAGESIZE:
                resetState();
                signal KAC9648.setImageSizeDone(result);
                break;                            
            
            default:
                printfUART("KAC9648M: signalStateEvent() - ERROR, bad state= %i\n", state);
                break;
        } 
    }

    void runStateReset(uint8_t step)
    {
        result_t result = FAIL;

        switch (step) {
            // (1) - Reset the software state and the hardware
            case 0:                                                           
                result = call I2CTransaction.write(CAMERA_SLAVEADDR, PWDRST, 2); // SenReset
                break;
            case 1:                                                           
                result = call I2CTransaction.write(CAMERA_SLAVEADDR, OPCTRL, 1); // RstzSoft
                break;

            // (2) - Turn on the bandgap circuitry
            case 2:                                                           
                result = call I2CTransaction.write(CAMERA_SLAVEADDR, POWCTRL, 0x86);
                break;
            case 3:                                                           
                result = call I2CTransaction.write(CAMERA_SLAVEADDR, OPCTRL, 0x07);
                break;
            case 4:                                                           
                result = call I2CTransaction.write(CAMERA_SLAVEADDR, INTREG2, 0x00);
                break;

            // (3) - The rest of the stuff ...
            case 5:   
                // Set the camera to "snapshot-mode", with snapshot signals in "pule-mode"
                // the shutter to "internal-mode", and 
                result = call I2CTransaction.write(CAMERA_SLAVEADDR, SNAPMODE, 55);
                break;
//             case 6:
//                 // Disable the first 8 pixels of every row
//                 result = call I2CTransaction.write(CAMERA_SLAVEADDR, DVBUSCONFIG2, 0xb0);
//                 break;
            case 6:
                // Set the pixel clock speed
                result = call I2CTransaction.write(CAMERA_SLAVEADDR, VCLKGEN, 6);
                break;                       
            case 7: // we are done
                signalStateEvent(SUCCESS);
                return;
            default:
                break;
        }

        if (result == FAIL) {
            printfUART("KAC9648M:runStateReset() - ERROR, result==FAIL, step= %i\n", step);
            signalStateEvent(FAIL);
        }
    }

    void runStateSetImageSize(uint8_t step)
    {
        result_t result = FAIL;
        uint8_t data = 0;

        switch (step) {
            // (1) - Column registers
            //  a. 8 MSB (most-significant-bits), bits [10:3]
            case 0:
                data = ((startX >> WCOLS_WStartCol) & 0xFF);
                result = call I2CTransaction.write(CAMERA_SLAVEADDR, WCOLS, data);
                break;
            case 1:     
                data = ((endX   >> WCOLE_WEndCol)   & 0xFF);
                result = call I2CTransaction.write(CAMERA_SLAVEADDR, WCOLE, data);
                break;   
            //  b. 3 LSB (lower-significant-bits), bits [2:0]
            case 2:   
                data  = ( ((startX >> 2) & 0x01) << WCOLLSB_WStartCol);
                data |= ( (endX   & 0x07) << WCOLLSB_WEndCol);
                result = call I2CTransaction.write(CAMERA_SLAVEADDR, WCOLLSB, data);
                break;

            // (2) - Row registers
            //  a. 8 MSB (most-significant-bits), bits [10:3]
            case 3:
                data = ((startY >> WROWS_WStartRow) & 0xFF);
                result = call I2CTransaction.write(CAMERA_SLAVEADDR, WROWS, data);
                break;                               
            case 4:
                data = ((endY   >> WROWE_WEndRow)   & 0xFF);
                result = call I2CTransaction.write(CAMERA_SLAVEADDR, WROWE, data);
                break;
            // 3 LSB (lower-significant-bits), bits [2:0]
            case 5:
                data  = ( (startY & 0x07) << WROWLSB_WStartRow);
                data |= ( (endY   & 0x07) << WROWLSB_WEndRow);
                result = call I2CTransaction.write(CAMERA_SLAVEADDR, WROWLSB, data);
                break;                    
                                     
            case 6: // we are done  
                // Also update the quick capture interface  
                atomic {
                    image.nbrCols = endX-startX+1;
                    image.nbrRows = endY-startY+1;                                   
                }
                printfUART("nbrCols= %i, nbrRows= %i\n", (uint16_t)image.nbrCols, (uint16_t)image.nbrRows);
                signalStateEvent( call PXA27XQuickCaptInt.setImageSize(endX-startX+1, endY-startY+1) );
                return;
            default:
                break;
        }

        if (result == FAIL) {
            printfUART("KAC9648M:runStateSetImageSize() - ERROR, result==FAIL, step= %i\n", step);
            signalStateEvent(FAIL);
        }
    }

    void handleI2CTransactionEventDone(result_t result)
    {
        atomic stateNextStep++;

        switch (state) {
            case STATE_IDLE:
                break;

            case STATE_RESET:
                if (result == FAIL)
                    signalStateEvent(FAIL);
                else
                    runStateReset(stateNextStep);
                break;

            case STATE_SETIMAGESIZE:
                if (result == FAIL)
                    signalStateEvent(FAIL);
                else
                    runStateSetImageSize(stateNextStep);
                break;

            default:
                printfUART("KAC9648M: handleI2CTransactionEventDone() - ERROR, bad state= %i\n", state);
                break;
        }
    }  
    
    // ----------------------- StdControl interface ------------------
    command result_t StdControl.init() 
    {
        printfUART_init();
        KAC9648_configurePins();
        return SUCCESS;
    }

    command result_t StdControl.start() 
    {          
        call KAC9648.reset();                
        return SUCCESS;
    }

    command result_t StdControl.stop() 
    {
        return SUCCESS;
    }

    // ----------------------- Timer interface ------------------
    event result_t Timer_ResetSnapshotPin.fired() 
    {
        TOSH_CLR_SNAPSHOT_PIN();
        return SUCCESS;
    }
 

    // ----------------------- KAC9648 (Camera) interface ------------------
    command result_t KAC9648.takePicture()
    {
        // Trigger the snapshot by setting the SNAPSHOT PIN to a logic 1.  The signal
        // applied to the SNAPSHOT PIN must be longer than 1 frame.
        atomic {
            uint8_t i = 0;
            printfUART("previous: cntSOF= %i, cntEOF= %i, cntEOL= %i, cntRDA[]={%i, %i, %i}, cntIFO[]={%i, %i, %i}\n", 
                        cntSOF, cntEOF, cntEOL, cntRDA[0], cntRDA[1], cntRDA[2], 
                                                cntIFO[0], cntIFO[1], cntIFO[2]);
            cntSOF = 0;
            cntEOF = 0;
            cntEOL = 0;
            for (i = 0; i < 3; ++i) {
                cntRDA[i] = 0;
                cntIFO[i] = 0;
            }
        }         
        Image_init(&image);
    
        {
        uint16_t i = 0;
        volatile uint32_t temp;
        RegUtils_print(REGID_CIFR);
        // Flush the FIFO            
            while ( ((CIFR >> 8) & 0xff) != 0 ) {
                atomic {
                    temp = CIBR0;
                    i++;
                }
            }         
        RegUtils_print(REGID_CIFR);
        printfUART("i= %i\n", i);
        }
       

        call PXA27XQuickCaptInt.startDMA();                        

        
        TOSH_SET_SNAPSHOT_PIN();
        
        if (call Timer_ResetSnapshotPin.start(TIMER_ONE_SHOT, SNAPSHOT_PIN_RESET_DELAY) == FAIL) {
            printfUART("***** KAC9648.takePicture() - ERROR, failed to call timer start\n", "");
            signal Timer_ResetSnapshotPin.fired();  // then, force a reset                    
        }

        return SUCCESS;
    }

    command result_t KAC9648.reset()
    {
        atomic {
            if (state != STATE_IDLE)
                return FAIL;
        }
        
        atomic {
            state = STATE_RESET;
            stateNextStep = 0;
        }
        runStateReset(stateNextStep);
        return SUCCESS;
    }

    command result_t KAC9648.setImageSize(uint16_t sizeX, uint16_t sizeY)
    {
        atomic {
            if (state != STATE_IDLE)
                return FAIL;
        }

        // (1) - Make sure we have a valid size
        if ( sizeX > (maxX - minX) || sizeY > (maxY - minY) ||
             sizeX % 4 != 0 || sizeY % 4 != 0 ) {
            printfUART("KAC9648.setImageSize() - ERROR, invalid inputs  sizeX= %i, sizeY= %i", sizeX, sizeY);
            return FAIL;
        }


        // (2) - Calculate the new coordinates
        startX = minX + ((maxX - minX - sizeX) >> 1);
        startX &= ~(0x03);   // make sure its a multiple of 4 (zero out the 2 LSBs)
        endX = startX + sizeX - 1;

        startY = minY + ((maxY - minY - sizeY) >> 1);
        startY &= ~(0x03);   // make sure its a multiple of 4 (zero out the 2 LSBs)
        endY = startY + sizeY - 1;


        // (3) - Set the registers.  Must set the MSBs before the LSBs!
        atomic {
            state = STATE_SETIMAGESIZE;
            stateNextStep = 0;
        }
        runStateSetImageSize(stateNextStep);
        return SUCCESS;
    }

   

    // ----------------------- PXA27XQuickCaptInt interface ------------------------
    async event void PXA27XQuickCaptInt.startOfFrame()
    {
        atomic cntSOF++;
        //atomic {printfUART("<<<<< KAC9648M: PXA27XQuickCaptInt.EndOfLine() - called >>>>>\n", "");}        
    }

    async event void PXA27XQuickCaptInt.endOfFrame()
    {
        atomic cntEOF++;
        //atomic {printfUART("<<<<< KAC9648M: PXA27XQuickCaptInt.EndOfFrame() - called >>>>>\n", "");}        
    }

    async event void PXA27XQuickCaptInt.endOfLine()
    {
        atomic cntEOL++;
        //atomic {printfUART("<<<<< KAC9648M: PXA27XQuickCaptInt.EndOfLine() - called >>>>>\n", "");}        
    }

    async event void PXA27XQuickCaptInt.recvDataAvailable(uint8_t channel)
    {
        uint32_t i;
        uint32_t nbr4Bytes;
        atomic {nbr4Bytes = ((CIFR >> 8) & 0xff) >> 2;}

        //atomic {printfUART("PXA27XQuickCaptInt.recvDataAvailable() - 1. nbrBytes= %i\n", (uint16_t) nbrBytes);}
        for (i = 0; i < nbr4Bytes; i++) {          
            image.data[image.curPixel + i] = CIBR0;
        }
        atomic {image.curPixel += nbr4Bytes;}
        atomic cntRDA[channel]++;
    }

    async event void PXA27XQuickCaptInt.fifoOverrun(uint8_t channel)
    {
        cntIFO[channel]++;
    }


    // ----------------------- I2CTransaction interface -------------------------
    event void I2CTransaction.readDone(result_t result, uint8_t data)
    {
        printfUART("KAC9648M: I2CTransaction.readDone() - called, result= %i, data= %i\n", result, data);
        handleI2CTransactionEventDone(result);
    }

    event void I2CTransaction.writeDone(result_t result)
    {
        printfUART("KAC9648M: I2CTransaction.writeDone() - called, result= %i\n", result);
        handleI2CTransactionEventDone(result);
    }

    event void I2CTransaction.writeBitsDone(result_t result)
    {
        printfUART("KAC9648M: I2CTransaction.writeBitsDone() - called, result= %i\n", result);
        handleI2CTransactionEventDone(result);
    }

    event void I2CTransaction.setBitDone(result_t result)
    {
        printfUART("KAC9648M: I2CTransaction.setBitDone() - called, result= %i\n", result);
        handleI2CTransactionEventDone(result);
    }

    event void I2CTransaction.clearBitDone(result_t result)
    {
        printfUART("KAC9648M: I2CTransaction.clearBitDone() - called, result= %i\n", result);
        handleI2CTransactionEventDone(result);
    }

}

