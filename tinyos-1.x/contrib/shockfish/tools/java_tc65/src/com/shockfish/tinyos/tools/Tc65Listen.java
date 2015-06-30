package com.shockfish.tinyos.tools;

import javax.microedition.midlet.*;
import java.io.*;
import javax.microedition.io.*;
import com.siemens.icm.io.*;
import net.tinyos.message.Dump;
import net.tinyos.util.PrintStreamMessenger;
import com.shockfish.tinyos.packet.Tc65SerialByteSource;
import com.shockfish.tinyos.packet.CldcPacketizer;

public class Tc65Listen extends MIDlet {

  CommConnection  commConn;
  InputStream     inStream;
  OutputStream    outStream;

 
  public Tc65Listen() {
    System.out.println("Shockfish GPRS module");
    System.out.println("Available COM Ports: " + System.getProperty("microedition.commports"));

  }


  public void startApp() throws MIDletStateChangeException {
     
    try {

	Tc65SerialByteSource tsb = new Tc65SerialByteSource("TinyNodeLight", 0);
	CldcPacketizer reader = new CldcPacketizer("TinyNodeLight",tsb, 0);
	reader.open(PrintStreamMessenger.err);
		  
	
	int packetCnt = 0;	    
	for (;;) {
	    byte[] packet = reader.readPacket();
	    System.out.println("Received packets :"+packetCnt++);
	    Dump.printPacket(System.out, packet);
	}

    } catch(IOException e) {
      System.out.println(e);
    }
    System.out.println();
    destroyApp(true);
  }

  /**
   * pauseApp()
   */
  public void pauseApp() {
    System.out.println("pauseApp()");
  }

  /**
   * destroyApp()
   *
   * This is important.  It closes the app's RecordStore
   * @param cond true if this is an unconditional destroy
   *             false if it is not
   *             currently ignored and treated as true
   */
  public void destroyApp(boolean cond) {
    System.out.println("-- destroyApp(" + cond + ")");
    try {
      inStream.close();
      outStream.close();
      commConn.close();
      System.out.println("Streams and connection closed");
    } catch(IOException e) {
      System.out.println(e);
    }

    notifyDestroyed();
  }
}
