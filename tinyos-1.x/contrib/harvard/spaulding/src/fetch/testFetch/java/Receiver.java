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

import net.tinyos.util.*;
import net.tinyos.message.*;
import java.util.*;
import java.text.*;

/**
 * This is the Serial port (UART) receiver for the centralized MoteTrack.
 * <code>MTReceiver</code> forwards the received beacon messages over the
 * serial port which should be received by this class.  Set MOTECOM to
 * the location where meassages are comming from, e.g. MOTECOM=serial@COM1:mica2!
 *
 * @author Konrad Lorincz
 * @version 1.1, October 12, 2004
 */
public class Receiver implements MessageListener
{
    private static DecimalFormat dbFormat = new DecimalFormat("#.###");
    private MoteIF moteIF = null;

    public static void main(String args[])
    {
        Receiver myapp = new Receiver();

        if (args.length == 1) {
            long blockID = Long.parseLong(args[0]);
            myapp.fetch(blockID);
        }
    }

    Receiver()
    {
        moteIF = new MoteIF(PrintStreamMessenger.err); // uses MOTECOM!
        moteIF.registerListener(new FetchReplyMsg(), this);
    }

    public void fetch(long blockID)
    {
        FetchRequestMsg frMsg = new FetchRequestMsg();
        frMsg.set_srcAddr(0);
        frMsg.set_blockID(blockID);
        frMsg.set_bitmask(15);

        try {
            System.out.println("Sending msg: fetch blockID= " + blockID + " ...");
            moteIF.send(MoteIF.TOS_BCAST_ADDR, frMsg);
        } catch (Exception e) {
            System.err.println("FAILED to send msg " + e);
        }


    }

    public void messageReceived(int dstaddr, Message msg)
    {
        if (msg instanceof FetchReplyMsg) {

            FetchReplyMsg frMsg = (FetchReplyMsg) msg;

            String str = "srcAddr= " + frMsg.get_originaddr() +
                         ", blockID= " + frMsg.get_block_id() +
                         ", offset= " + frMsg.get_offset() +
                         ", data= ";

            short[] data = frMsg.get_data();
            // print raw bytes
            for (int i = 0; i < data.length; i++) {
                str += " 0x" + data[i];
            }
            // print samples
            /*for (int i = 0; i < data.length-1; i += 2) {
                int sample = data[i];
                sample |= (data[i+1] << 8);
                str += " " + sample;
            }*/
            System.out.println(str);
        }
    }
}
