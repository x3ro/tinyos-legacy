/* "Copyright (c) 2001 and The Regents of the University  
* of California.  All rights reserved. 
* 
* Permission to use, copy, modify, and distribute this software and its 
* documentation for any purpose, without fee, and without written agreement is 
* hereby granted, provided that the above copyright notice and the following 
* two paragraphs appear in all copies of this software. 
*  
* IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR 
* DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT 
* OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF 
* CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*  
* THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, 
* INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
* AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS 
* ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO 
* PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS." 
* 
* Authors:   Mike Chen
*			 Scott Klemmer
*			 Kamin Whitehouse <kamin@cs.berkeley.edu>
* History:   created as listen October 22, 2000
*			 Modified by Scott to read from a UDP socket 11/1/2000
*			 Modified by Kamin to work with Surge 2.0 7/22/2001 
*/

//*********************************************************
//*********************************************************
//this class reads the data packets from a UDP socket
//and generates packet events for each packet recieved.
//it runs in the background on its own thread.
//It is designed to run with UDPPacketForwarder.java
//*********************************************************
//*********************************************************

package Surge.PacketRecievers;
import java.util.*;
import java.io.*;
import java.net.*;
import Surge.util.*;
import java.awt.event.*;
import javax.swing.*;


/**
 * 
 * Listens on a UDP port and prints the packet content in hex.
 * 
 * To be used with the UdpPacketForwarder, which uses the SerialPortPacketReciever.
 *
 * @author  <A HREF="http://www.cs.berkeley.edu/~mikechen/">Mike Chen</A> 
 *		(<A HREF="mailto:mikechen@cs.berkeley.edu">mikechen@cs.berkeley.edu</A>)
 * @since   1.1.6
 */


public class UdpPacketReciever {

  //===========================================================================
  //===   CONSTANTS   =========================================================
  
private static final String  CLASS_NAME                  = "UdpPacketReciever";
private static final String  VERSION     	         = "v0.1";

  //===   CONSTANTS   =========================================================
  //===========================================================================
  
  //===========================================================================
  //===   PRIVATE VARIABLES   =================================================

int port;
DatagramSocket s;

  //===   PRIVATE VARIABLES   =================================================
  //===========================================================================
  
  
  //===========================================================================
  //===   NONLOCAL INSTANCE VARIABLES   =======================================

  //===   NONLOCAL INSTANCE VARIABLES   =======================================
  //===========================================================================
  
  //===========================================================================
  //===   CONSTRUCTORS   ======================================================
  
  /**
   * Default constructor.
   */

  //===   CONSTRUCTORS   ======================================================
  //===========================================================================

  //===========================================================================
  

  /**
   *  .
   */

public UdpPacketReciever(int port) {
  this.port = port;
}


  //===========================================================================

public void start() throws IOException {
  s = new DatagramSocket(port);
  byte[] buf = new byte[128];

  System.out.println("UdpPacketReciever.start");

  while (true) {
    DatagramPacket packet = new DatagramPacket(buf, buf.length);
    s.receive(packet);
    System.out.println("packet length: " + packet.getLength());
    System.out.println("buf: " + Hex.toHex(buf, packet.getLength()));
  }
  
}

  //===========================================================================  

private static void printUsageAndExit() {
  System.err.println("usage: java UdpPacketReciever [port]"); 
  System.exit(-1);
}

  //===========================================================================
  //===   MAIN    =============================================================

public static void main(String args[]) {
  if (args.length != 1) {
    printUsageAndExit();
  }

  System.out.println("\nUdpPacketReciever started");
  try {
    UdpPacketReciever listener = new UdpPacketReciever(Integer.parseInt(args[0]));
    listener.start();
  }
  catch (Exception e) {
    e.printStackTrace();
  }
}



}
//===   MAIN    =============================================================
//===========================================================================



// of Class UdpPacketReciever

//===   UdpPacketReciever.java   =============================================
//=============================================================================



//////////////////////////////////////////////////
// Fix the emacs editing mode
// Local Variables: ***
// c-basic-offset:2 ***
// End: ***
//////////////////////////////////////////////////
