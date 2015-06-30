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
import net.tinyos.message.*;
import net.tinyos.util.*;

import java.io.*;
import java.text.*;
import java.util.*;

public class SendCmd implements MessageListener
{
    private MoteIF moteIF;
    static public LinkedList recvMsgs = new LinkedList();
    static public String recvMsgLock = "Lock";
    final static int CAMERA_SLAVEADDR = 85;   // 0b1010101


    public SendCmd()
    {
        resetMoteIF();
    }

    private void resetMoteIF()
    {
        try {
            moteIF = new MoteIF(PrintStreamMessenger.err);
            moteIF.registerListener(new HWTestMsg(), this);
        } catch (Exception e) {
            System.err.println("Error: Could not connect to SF: "+e);
            e.printStackTrace();
            System.exit(1);
        }
    }

    public HWTestMsg sendAndWaitForReply(int cmdID) {
        return sendAndWaitForReply(cmdID, 0, 0, 0, 0);
    }
    public HWTestMsg sendAndWaitForReply(int cmdID, int param1) {
        return sendAndWaitForReply(cmdID, param1, 0, 0, 0);
    }
    public HWTestMsg sendAndWaitForReply(int cmdID, int param1, int param2) {
        return sendAndWaitForReply(cmdID, param1, param2, 0, 0);
    }
    public HWTestMsg sendAndWaitForReply(int cmdID, int param1, int param2, int param3) {
        return sendAndWaitForReply(cmdID, param1, param2, param3, 0);
    }

    public HWTestMsg sendAndWaitForReply(int cmdID, int param1, int param2, int param3, int param4)
    {
        System.err.println("--- readReg() - beforeLock --- ");
        synchronized(recvMsgLock) {
            send(cmdID, param1, param2, param3, param4);
            try {
                recvMsgLock.wait();
            } catch (Exception e) {System.err.println(e);}
        }
        System.err.println("--- readReg() - afterLock --- ");
        return (HWTestMsg) SendCmd.recvMsgs.getLast();
    }


    public void send(int cmdID)               { send(cmdID, 0, 0, 0, 0); }
    public void send(int cmdID, int param1)   { send(cmdID, param1, 0, 0, 0); }
    public void send(int cmdID, int param1, int param2)               { send(cmdID, param1, param2, 0, 0); }
    public void send(int cmdID, int param1, int param2, int param3)   { send(cmdID, param1, param2, param3, 0); }

    public void send(int cmdID, int param1, int param2, int param3, int param4)
    {
        // Create the command */
        HWTestMsg msg = new HWTestMsg();
        msg.set_cmdID(cmdID);
        msg.set_param1((short)param1);
        msg.set_param2((short)param2);
        msg.set_param3((short)param3);
        msg.set_param4((short)param4);

        try {
            sleep(100);
            //sleep(500);
            System.err.println("Sending cmdID= " + cmdID + ", param1= " + param1);
            moteIF.send(MoteIF.TOS_BCAST_ADDR, msg);
        } catch (Exception e) {
            System.err.println("ERROR: Can't send message: "+e);
            e.printStackTrace();
        }
    }


    public void messageReceived(int to, Message m)
    {
        if (m.amType() == HWTestMsg.AM_TYPE) {

            HWTestMsg hwtMsg = (HWTestMsg) m;
            recvMsgs.add(hwtMsg);
            synchronized (recvMsgLock) {
                System.err.println("--- messageReceived() - releasingLock --- ");
                recvMsgLock.notifyAll();
            }
        }
    }


    private static void usage()
    {
        System.err.println("Usage:");
        System.err.println("  java SendCmd <cmdID> [<cmdParams>]");
        System.exit(1);
    }

    static void sleep(long ms)
    {
        String lock = new String(" ");
        synchronized(lock) {
            try {
                lock.wait(ms);
            }
            catch(Exception e) {}
        }
    }

    static int getDataFromAddr(int targetSlaveAddr7Bit, boolean isRnWTypeRead)
    {
        int data = (targetSlaveAddr7Bit << 1); // upper 7-bits
        if (isRnWTypeRead)
            data |= (1 << 0); // for Read, RnW=1
        else
            data &= ~(1 << 0); // for Write, RnW=0

        return data;
    }


    public short readRegInSteps(int regAddr)
    {
        send(cmd.cmd_I2C_sendStart);
        send(cmd.cmd_I2C_write, getDataFromAddr(CAMERA_SLAVEADDR, false));

        send(cmd.cmd_I2C_write, regAddr);

        send(cmd.cmd_I2C_sendStart);
        send(cmd.cmd_I2C_write, getDataFromAddr(CAMERA_SLAVEADDR, true));

        send(cmd.cmd_I2C_sendEnd);
        send(cmd.cmd_I2C_read, 0);

        HWTestMsg hwtMsg = sendAndWaitForReply(cmd.print_IDBR);
        return hwtMsg.get_param1();
    }

    public short i2ctrReadReg(int regAddr)
    {
        HWTestMsg hwtMsg = sendAndWaitForReply(cmd.cmd_I2CTR_readReg, regAddr);
        return hwtMsg.get_param1();
    }


    public void writeRegInSteps(int regAddr, int data)
    {
        send(cmd.cmd_I2C_sendStart);
        send(cmd.cmd_I2C_write, getDataFromAddr(CAMERA_SLAVEADDR, false));

        send(cmd.cmd_I2C_write, regAddr);

        send(cmd.cmd_I2C_sendEnd);
        send(cmd.cmd_I2C_write, data);

        send(cmd.print_IDBR);  // Not necessary, for debug
    }

    public short i2ctrWriteReg(int regAddr, int data)
    {
        HWTestMsg hwtMsg = sendAndWaitForReply(cmd.cmd_I2CTR_writeReg, regAddr, data);
        return hwtMsg.get_param1();
    }

    public short i2ctrWriteRegBits(int regAddr, int startBitIndexLSB, int nbrBits, int bitValues)
    {
        HWTestMsg hwtMsg = sendAndWaitForReply(cmd.cmd_I2CTR_writeRegBits, regAddr, startBitIndexLSB, nbrBits, bitValues);
        return hwtMsg.get_param1();
    }

    public short i2ctrSetBit(int regAddr, int bitIndex)
    {
        HWTestMsg hwtMsg = sendAndWaitForReply(cmd.cmd_I2CTR_setBit, regAddr, bitIndex);
        return hwtMsg.get_param1();
    }

    public short i2ctrClearBit(int regAddr, int bitIndex)
    {
        HWTestMsg hwtMsg = sendAndWaitForReply(cmd.cmd_I2CTR_clearBit, regAddr, bitIndex);
        return hwtMsg.get_param1();
    }

    public short cameraReset()
    {
        HWTestMsg hwtMsg = sendAndWaitForReply(cmd.cmd_cameraReset);
        return hwtMsg.get_param1();
    }

    public void cameraTakePicture()
    {
        send(cmd.cmd_cameraTakePicture);
    }

    public short jInit()
    {
        short result = i2ctrWriteReg(0x85, 0x86);
        if (result == 1)
            result = i2ctrWriteReg(0x09, 0x07);
        if (result == 1)
            result = i2ctrWriteReg(0x88, 0x00);
        return result;
    }

    public short jTakePicture()
    {
        short result = i2ctrSetBit(0x30, 5);
        if (result == 1)
            result = i2ctrSetBit(0x30, 4);
        if (result == 1)
            result = i2ctrClearBit(0x30, 3);
        return result;

        //       return i2ctrWriteReg(0x30, 55);
    }
    public short jTakeVideo()
    {
        return i2ctrClearBit(0x30, 5);
    }

    public short jPulseMode()
    {
        short result = i2ctrSetBit(0x53, 6);  // set PCLK in data-ready mode
        if (result == 1)
            result = i2ctrSetBit(0x53, 5);    // set VSYNC to pulse mode
        if (result == 1)
            result = i2ctrSetBit(0x53, 4);    // set HSYNC to pulse mode
        return result;
    }


    static int parseNumber(String str)
    {
        Integer intVal = Integer.decode(str);
        System.out.println("str= " + str + "  =>  " + intVal);
        return intVal.intValue();
    }

    static String printMultiRadix(short nbr)
    {
        return nbr + ", 0x" + Integer.toString(nbr, 16) + ", 0b" + Integer.toString(nbr, 2);
    }


    public short runCurrFunc()
    {
        short result = 0;

        result = ((HWTestMsg) sendAndWaitForReply(cmd.cmd_RegUtils_clearBit, cmd.REGID_CICR0, 28)).get_param1(); // disable CIF
        if (result == 1)
            result = ((HWTestMsg) sendAndWaitForReply(cmd.cmd_RegUtils_setBit, cmd.REGID_CICR1, 25)).get_param1(); // 1024 pixels per line
        if (result == 1)
            result = ((HWTestMsg) sendAndWaitForReply(cmd.cmd_RegUtils_setBit, cmd.REGID_CICR1, 6)).get_param1(); // 10 bits per pixel
        if (result == 1)
            result = ((HWTestMsg) sendAndWaitForReply(cmd.cmd_RegUtils_setBit, cmd.REGID_CICR2, 28)).get_param1(); // BLW=16 (begin-of-line pixel clock wait count
        if (result == 1)
            result = ((HWTestMsg) sendAndWaitForReply(cmd.cmd_RegUtils_setBit, cmd.REGID_CICR2, 20)).get_param1(); // ENL=16 (end-of-line pixel clock wait count
        if (result == 1)
            result = ((HWTestMsg) sendAndWaitForReply(cmd.cmd_RegUtils_setBit, cmd.REGID_CICR3, 10)).get_param1(); // 1024 lines-per-frame
        if (result == 1)
            result = ((HWTestMsg) sendAndWaitForReply(cmd.cmd_RegUtils_setBit, cmd.REGID_CICR0, 28)).get_param1(); // enable CIF

        return result;
    }

    public static void main(String[] args)
    {
        SendCmd sc = new SendCmd();

        if (args[0].equals("i2ctrReadReg") && args.length == 2) {
            short regData = sc.i2ctrReadReg(parseNumber(args[1]));
            System.out.println("reg[" + args[1] + "]= " + printMultiRadix(regData));
        }
        else if (args[0].equals("i2ctrWriteReg") && args.length == 3) {
            short result = sc.i2ctrWriteReg(parseNumber(args[1]), parseNumber(args[2]));
            System.out.println("result= " + result);
        }
        else if (args[0].equals("i2ctrWriteRegBits") && args.length == 5) {
            short result = sc.i2ctrWriteRegBits(parseNumber(args[1]), parseNumber(args[2]), parseNumber(args[3]), parseNumber(args[4]));
            System.out.println("result= " + result);
        }
        else if (args[0].equals("i2ctrSetBit") && args.length == 3) {
            short result = sc.i2ctrSetBit(parseNumber(args[1]), parseNumber(args[2]));
            System.out.println("result= " + result);
        }
        else if (args[0].equals("i2ctrClearBit") && args.length == 3) {
            short result = sc.i2ctrClearBit(parseNumber(args[1]), parseNumber(args[2]));
            System.out.println("result= " + result);
        }
        else if (args[0].equals("cameraReset") && args.length == 1) {
            short result = sc.cameraReset();
            System.out.println("result= " + result);
        }
        else if (args[0].equals("cameraSetImageSize") && args.length == 2) {
            short result = ((HWTestMsg) sc.sendAndWaitForReply(cmd.cmd_cameraSetImageSize, parseNumber(args[1]))).get_param1();
            System.out.println("result= " + result);
        }
        else if (args[0].equals("cameraTakePic") && args.length == 1) {
            sc.cameraTakePicture();
        }
        else if (args[0].equals("jInit") && args.length == 1) {
            short result = sc.jInit();
            System.out.println("result= " + result);
        }
        else if (args[0].equals("jTakePic") && args.length == 1) {
            short result = sc.jTakePicture();
            System.out.println("result= " + result);
        }
        else if (args[0].equals("jTakeVideo") && args.length == 1) {
            short result = sc.jTakeVideo();
            System.out.println("result= " + result);
        }
        else if (args[0].equals("jPulseMode") && args.length == 1) {
            short result = sc.jPulseMode();
            System.out.println("result= " + result);
        }
        else if (args[0].equals("pinSet") && args.length == 1) {
            sc.send(cmd.cmd_pinSet);
        }
        else if (args[0].equals("pinClear") && args.length == 1) {
            sc.send(cmd.cmd_pinClear);
        }
        else if (args[0].equals("regUtilsSetBit") && args.length == 3) {
            sc.send(cmd.cmd_RegUtils_setBit, parseNumber(args[1]), parseNumber(args[2]));
        }
        else if (args[0].equals("regUtilsClearBit") && args.length == 3) {
            sc.send(cmd.cmd_RegUtils_clearBit, parseNumber(args[1]), parseNumber(args[2]));
        }
        else if (args[0].equals("regUtilsPrint") && args.length == 2) {
            sc.send(cmd.cmd_RegUtils_print, parseNumber(args[1]));
        }
        else if (args[0].equals("imagePrint")  && args.length == 2) {
            sc.send(cmd.cmd_Image_print, parseNumber(args[1]));
        }
        else if (args[0].equals("imageInit")) {
            sc.send(cmd.cmd_Image_init);
        }
        else if (args[0].equals("imageSend")) {
            sc.send(cmd.cmd_Image_send);
        }
        else if (args[0].equals("runCurrFunc") && args.length == 1) {
            short result = sc.runCurrFunc();
            System.out.println("result= " + result);
        }
        else if (args[0].equals("printDMA") && args.length == 3) {
            sc.send(cmd.print_DMA, parseNumber(args[1]), parseNumber(args[2]));
        }

        // ----- temporary ----
        else if (args[0].equals("printIDBR") && args.length == 1) {
            sc.send(cmd.print_IDBR);
        }
        else if (args[0].equals("tempCIFEnableIRQ") && args.length == 1) {
            sc.send(cmd.temp_CIF_enableIRQ);
        }



        else
            usage();

        System.exit(1);
    }
}

