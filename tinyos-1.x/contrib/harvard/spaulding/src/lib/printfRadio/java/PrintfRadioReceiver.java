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

public class PrintfRadioReceiver implements MessageListener
{
    private static DecimalFormat dbFormat = new DecimalFormat("#.###");
    private Map<Integer, Integer> nodePrevPrintfNbr = Collections.synchronizedMap(new HashMap<Integer, Integer>());

    public static void main(String args[])
    {
        PrintfRadioReceiver myapp = new PrintfRadioReceiver();
    }

    PrintfRadioReceiver()
    {
        MoteIF mote = new MoteIF(PrintStreamMessenger.err); // uses MOTECOM!
        mote.registerListener(new PrintfRadioMsg(), this);
        System.out.println("Output Format:\n<nodeID>.<printfNbr>: <text>\n");
    }

    public void messageReceived(int dstaddr, Message msg)
    {
        if (msg instanceof PrintfRadioMsg) {

            PrintfRadioMsg sMsg = (PrintfRadioMsg) msg;

            int srcAddr = sMsg.get_srcAddr();
            int dataSize = sMsg.get_dataSize();
            int printfNbr = sMsg.get_printfNbr();
            byte[] data = sMsg.get_data();

            String dataStr = "";
            for (int i = 0; i < dataSize && i < data.length; ++i) {
                if ((char)data[i] == '\0')
                    break;
                else
                    dataStr += (char) data[i];
            }


            // (1) - See if there are any missing lines
            Integer prevPrintfNbr = nodePrevPrintfNbr.get(srcAddr);
            if (prevPrintfNbr != null && printfNbr-prevPrintfNbr != 1)
                System.out.println(" <" + srcAddr + ": .. " + (printfNbr-prevPrintfNbr-1) + " ..>");
            nodePrevPrintfNbr.put(srcAddr, printfNbr);

            // (2) - Print the message
            System.out.println(srcAddr + "." +
                               printfNbr + ": " +
                               dataStr);
        }
    }
}
