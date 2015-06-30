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
import java.lang.Math;

/**
 * @author Konrad Lorincz
 * @version 1.1, October 12, 2004
 */
public class JavaReceiver implements MessageListener 
{
    /**
     * The main function.
     */
    public static void main(String args[])
    {
    	// Call Constructor
        JavaReceiver myapp = new JavaReceiver();
    }

    /**
     * Instatntiates an object capable of receiving <code>MTSignatureMsg</code>
     */
    JavaReceiver()
    {
	// Create object to capture messages
        MoteIF mote = new MoteIF(PrintStreamMessenger.err); // uses MOTECOM!

        // Register to listen
        mote.registerListener(new TestPerformanceMsg(), this);
    }

    long toMilliSec(long timeClockIicks)
    {
        final double clockTicksPerMilliSec = 32.768;  // 32 KHz clock
        return Math.round( (double)timeClockIicks/(double)clockTicksPerMilliSec );
    }

    /**
     * Called when a message was received.
     * @param dsaddr  destiantion address
     * @param msg  the received message
     */
    public void messageReceived(int dstaddr, Message msg) 
    {
        System.out.println("msg received");
        if (msg instanceof TestPerformanceMsg) {
            
            TestPerformanceMsg tpMsg = (TestPerformanceMsg) msg;

            System.out.println("srcAddr= "   + tpMsg.get_srcAddr() +
                               "  sqnNbr= "  + tpMsg.get_sqnNbr() +
                               "  nbrReq= "  + tpMsg.get_nbrRequests() +
                               "  timeAdd_ms= " + toMilliSec( tpMsg.get_elapsedTimeAdd() ) +
                               "  timeGet_ms= " + toMilliSec( tpMsg.get_elapsedTimeGet() ) +

                               "  sizeofBlock= "              + tpMsg.get_const_sizeofBlock() +
                               "  BLOCK_DATA_SIZE= "          + tpMsg.get_const_BLOCK_DATA_SIZE() +
                               "  DS_NBR_BLOCKS_PER_VOLUME= " + tpMsg.get_const_DS_NBR_BLOCKS_PER_VOLUME() +
                               "  DS_NBR_VOLUMES= "           + tpMsg.get_const_DS_NBR_VOLUMES() );
        }
    }
}
