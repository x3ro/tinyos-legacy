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
//===   UdpListener.java   ==============================================

import java.util.*;
import java.io.*;
import java.net.*;

/**
 * 
 * Listens on a UDP port and prints the packet content in hex.
 *
 * @author  <A HREF="http://www.cs.berkeley.edu/~mikechen/">Mike Chen</A> 
 *		(<A HREF="mailto:mikechen@cs.berkeley.edu">mikechen@cs.berkeley.edu</A>)
 * @since   1.1.6
 */


public class UdpListener {

  //===========================================================================
  //===   CONSTANTS   =========================================================
  
private static final String  CLASS_NAME                  = "UdpListener";
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

public UdpListener(int port) {
  this.port = port;
}


  //===========================================================================

public void start() throws IOException {
  s = new DatagramSocket(port);
  byte[] buf = new byte[128];

  while (true) {
    DatagramPacket packet = new DatagramPacket(buf, buf.length);
    s.receive(packet);
    System.out.println("packet length: " + packet.getLength());
    System.out.println("buf: " + Hex.toHex(buf, packet.getLength()));
  }
  
}

  //===========================================================================  

private static void printUsageAndExit() {
  System.err.println("usage: java UdpListener [port]"); 
  System.exit(-1);
}

  //===========================================================================
  //===   MAIN    =============================================================

public static void main(String args[]) {
  if (args.length != 1) {
    printUsageAndExit();
  }

  System.out.println("\nUdpListener started");
  try {
    UdpListener listener = new UdpListener(Integer.parseInt(args[0]));
    listener.start();
  }
  catch (Exception e) {
    e.printStackTrace();
  }
}

}
//===   MAIN    =============================================================
//===========================================================================



// of Class UdpListener

//===   UdpListener.java   =============================================
//=============================================================================



//////////////////////////////////////////////////
// Fix the emacs editing mode
// Local Variables: ***
// c-basic-offset:2 ***
// End: ***
//////////////////////////////////////////////////
