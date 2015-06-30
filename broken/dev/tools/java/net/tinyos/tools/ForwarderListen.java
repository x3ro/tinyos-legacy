/*
 * Author: Mike Chen <mikechen@cs.berkeley.edu>
 * Inception Date: October 22th, 2000
 *
 * This software is copyrighted by Mike Chen and the Regents of
 * the University of California.  The following terms apply to all
 * files associated with the software unless explicitly disclaimed in
 * individual files.
 *
 * The authors hereby grant permission to use this software without
 * fee or royalty for any non-commercial purpose.  The authors also
 * grant permission to redistribute this software, provided this
 * copyright and a copy of this license (for reference) are retained
 * in all distributed copies.
 *
 * For commercial use of this software, contact the authors.
 *
 * IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY
 * DERIVATIVES THEREOF, EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE
 * IS PROVIDED ON AN "AS IS" BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE
 * NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 */

//==============================================================================
//===   listen.java   ==============================================

package net.tinyos.tools;

import java.util.*;
import java.io.*;
import java.net.*;

/**
 *
 * Init the serial port and reads data from it.
 *
 * @author  <A HREF="http://www.cs.berkeley.edu/~mikechen/">Mike Chen</A>
 *		(<A HREF="mailto:mikechen@cs.berkeley.edu">mikechen@cs.berkeley.edu</A>)
 * @since   1.1.6
 *
 * modified by bwhull to work with the serialforwarder
 */


public class ForwarderListen {

    //=========================================================================
    //===   CONSTANTS   =======================================================

    private static final String  CLASS_NAME                  = "listen";
    private static final String  VERSION     	         = "v0.1";
    private static int MSG_SIZE = 36;  // 4 header bytes, 30 msg bytes, 2 crc
				       // bytes;  2 strength bytes are not
				       // transmitted 
    //=========================================================================
    //===   PRIVATE VARIABLES  ================================================

    String strAddr;
    int nPort;
    Socket socket;
    InputStream in;
    OutputStream out;

    public ForwarderListen(String host, String port) {
	this.nPort = Integer.parseInt( port );
	this.strAddr = host;
    }


    //=========================================================================

    public boolean open()
    {
	try {
	    System.out.println ("Connecting to host " + strAddr + ":" + nPort + "\n");
	    socket = new Socket (strAddr, nPort);
	    in = socket.getInputStream();
	    out = socket.getOutputStream();
	} catch ( IOException e ) {
	    System.out.println ("Unable to connect to host\n");
	    return false;
	}

	return true;
    }


    //=========================================================================

    //=========================================================================

    public void read() throws IOException {
	int i;
	int count = 0;
	byte[] packet = new byte[MSG_SIZE];

	while ((i = in.read()) != -1) {
	    if(i == 0x7e || count != 0){
		packet[count] = (byte)i;
		String datum = (Integer.toHexString(i).toUpperCase());
		if (datum.length() == 1) {datum = "0" + datum;}
		System.out.print(datum + " ");
		count++;
		if (count == MSG_SIZE) {
		    System.out.println();
		    count = 0;
		}
	    }else{
		    String datum = (Integer.toHexString(i).toUpperCase());
		    if (datum.length() == 1) {datum = "0" + datum;}
		    System.out.print(datum + " ");
	    }
	}
    }



    //=========================================================================
    //===   MAIN    ===========================================================

    public static void main(String args[]) {
	if (args.length < 2) {
	    System.err.println("usage: java listen [forwarder address] [port] [msg size (optional - default=" + MSG_SIZE +"]");
	    System.exit(-1);
	}
	if ( args.length == 3 ) {
	    MSG_SIZE = Integer.parseInt( args[2] );
	}
	boolean bSuccess = false;
	System.out.println("\nlisten started");
	ForwarderListen reader = new ForwarderListen(args[0],args[1]);

	bSuccess = reader.open();

	try {
	    if ( bSuccess ) reader.read();
	}
	catch (Exception e) {
	    e.printStackTrace();
	}
    }

}

