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


    public static void main(String args[])
    {
        Receiver myapp = new Receiver();
    }

    Receiver()
    {
        MoteIF mote = new MoteIF(PrintStreamMessenger.err); // uses MOTECOM!
        mote.registerListener(new SamplingMsg(), this);
    }

    public void messageReceived(int dstaddr, Message msg)
    {
        if (msg instanceof SamplingMsg) {

            SamplingMsg sMsg = (SamplingMsg) msg;

            int srcAddr = sMsg.get_srcAddr();
            long timeStamp = sMsg.get_timeStamp();
            int nbrSamples = sMsg.get_nbrSamples();
            int[] samples = sMsg.get_samples();

            System.out.print("srcAddr= " + srcAddr +
                               "  timeRaw= " + timeStamp +
                               "  timeMsec= " + dbFormat.format(((double)timeStamp/32000.0)) +
                               "  nbrSamples= " + nbrSamples +
                               "  chanMap= [");
            for (int i = 0; i < 4; ++i) {
                if (i != 0)
                    System.out.print(" ");
                System.out.print((samples[i]>>12));
            }
            System.out.println("]");
            System.out.print("  samples={");
            for (int i = 0; i < nbrSamples; ++i) {
                if (i != 0 && i % 4 == 0) // newline
                    System.out.print("\n          ");
                if (i != 0)
                    System.out.print(" ");
                System.out.print((samples[i]&0x0fff));
            }
            System.out.println("}");
        }
    }
}
