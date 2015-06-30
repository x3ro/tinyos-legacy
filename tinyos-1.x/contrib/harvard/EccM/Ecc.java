/**
 * Implementation of ECC module.
 *
 * @author  David Malan <malan@eecs.harvard.edu>
 *
 * @version 2.0
 *
 * Copyright (c) 2004
 *  The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *      may be used to endorse or promote products derived from this software
 *      without specific prior written permission.
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


// imports
import net.tinyos.message.*;


/**
 * Ecc class.  Simply shows DbgMsg's.
 *
 * @author  David Malan <malan@eecs.harvard.edu>
 *
 * @version 2.0
 */
public class Ecc implements MessageListener
{
    /**
     * Main driver.
     *
     * @param argv  arguments
     */
    public static void main(String [] argv)
    {
        // try to start Ecc application, else report failure
        try
        {
            new Ecc();
        }
        catch (Exception e)
        {
            System.err.println("Exception: " + e);
            e.printStackTrace();
        }
    }


    /**
     * Implicit constructor.  Connects to the SerialForwarder,
     * registers itself as a listener for DbgMsg's,
     * and starts listening.
     */

    public Ecc() throws Exception 
    {
        // connect to the SerialForwarder running on the local mote
        MoteIF mote = new MoteIF((net.tinyos.util.Messenger) null);

        // prepare to listen for messages of type DbgMsg 
        mote.registerListener(new DbgMsg(), this);

        // start listening to the mote
        mote.start();
    }


    /**
     * Event for handling incoming DbgMsg's.
     *
     * @param dstaddr   destination address
     * @param msg       received message
     */
    public void messageReceived(int dstaddr, Message msg) 
    {
        // process any DbgMsg's received
        if (msg instanceof DbgMsg)
        {
            // cast message
            DbgMsg dmsg = (DbgMsg) msg;

            // report message
            System.out.println("privKeyTime: " 
                               + dmsg.get_privKeyTime() / 7.3828 / 1000000);
            System.out.println("pubKeyTime: " 
                               + dmsg.get_pubKeyTime() / 7.3828 / 1000000);
            System.out.println("secKeyTime: " 
                               + dmsg.get_secKeyTime() / 7.3828 / 1000000);
            System.out.println();
        }
        else
        {
            // report error
            System.out.println("Unknown message type received.");
        }
    }
}
