//package edu.berkeley.guir.location;

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
//===   UdpPacketForwarder.java   ==============================================

import java.util.*;
import java.io.*;
import java.net.*;
import javax.comm.*;

/**
 * 
 * Creates a serial port reader and forward the packets received to another host.
 * Handles encryption and MAC.
 *
 * To be used with UdpPacketReciever built into Surge2.0
 *
 * @author  <A HREF="http://www.cs.berkeley.edu/~mikechen/">Mike Chen</A> 
 *		(<A HREF="mailto:mikechen@cs.berkeley.edu">mikechen@cs.berkeley.edu</A>)
 * @since   1.1.6
 */


public class UdpPacketForwarder //implements PacketListenerIF {

  //===========================================================================
  //===   CONSTANTS   =========================================================
  
private static final String  CLASS_NAME                  = "UdpPacketForwarder";
private static final String  VERSION     	         = "v0.1";

private static final int payloadOffset =  1;
private static final int payloadLength = 29;
private static final int macOffset = 22;
private static final  int macLength =  8;

  //===========================================================================
  //===   PRIVATE VARIABLES   =================================================

SerialPortReader reader;
String serialPortName;
InetAddress host;
int port;
DatagramSocket s;
byte[] payload = new byte[payloadLength];
byte[] mac = new byte[8];

  //===   CONSTRUCTORS   ======================================================
  //===========================================================================

  //===========================================================================
  

  /**
   *  .
   */

public UdpPacketForwarder(String serialPortName, InetAddress host, int port) {
  this.serialPortName = serialPortName;
  this.host = host;
  this.port = port;
}


  //===========================================================================

public void start() throws NoSuchPortException, PortInUseException, IOException, UnsupportedCommOperationException {
  reader = new SerialPortReader(serialPortName);

  //// init the reader
  //reader.printAllPorts();
  reader.open();
  System.out.println("UdpPacketForwarder.start");
  reader.registerPacketListener(this);

  //// init the UDP socket
  s = new DatagramSocket();

  //// start the reader
  reader.read();
}

  //===========================================================================

  /*
   *  Receives a packet and forwards it content to a UDP port.
   */
  
public void packetReceived(byte[] packet) {
  //System.out.println("packetR: " + Hex.toHex(packet));
  
  //// verifies that the packet is ok

  //// forwards that to a UDP port
  
  /*
  DatagramPacket p = new DatagramPacket(packet, offset, length, host, port);
  */
  System.arraycopy(packet, payloadOffset, payload, 0, payloadLength);
  System.out.println("data: " + Hex.toHex(payload));

  System.arraycopy(packet, macOffset, mac, 0, macLength);
  //System.out.println("mac:   " + Hex.toHex(mac));

  DatagramPacket p;
  try {
    System.out.println("sending UDP packet...");
    p = new DatagramPacket(payload, payload.length, host, port);
    s.send(p);

    /*
    p = new DatagramPacket(packet, packet.length, host, port);
    s.send(p);
    */
  }
  catch (Exception e) {
    e.printStackTrace();
  }
}

  //===========================================================================  

private static void printUsageAndExit() {
  System.err.println("usage: java UdpPacketForwarder <serial_port> <host> <port>"); 
  System.exit(-1);
}

  //===========================================================================
  //===   MAIN    =============================================================

public static void main(String args[]) {
  if (args.length != 3) {
    printUsageAndExit();
  }

  System.out.println("\nUdpPacketForwarder started");
  try {
    UdpPacketForwarder bs = new UdpPacketForwarder(args[0], InetAddress.getByName(args[1]), Integer.parseInt(args[2]));
    bs.start();
  }
  catch (Exception e) {
    e.printStackTrace();
  }
}

}
//===   MAIN    =============================================================
//===========================================================================



// of Class UdpPacketForwarder

//===   UdpPacketForwarder.java   =============================================
//=============================================================================



//////////////////////////////////////////////////
// Fix the emacs editing mode
// Local Variables: ***
// c-basic-offset:2 ***
// End: ***
//////////////////////////////////////////////////
