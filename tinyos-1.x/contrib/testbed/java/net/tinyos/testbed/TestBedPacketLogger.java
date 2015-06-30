/* ex: set tabstop=4 shiftwidth=4 expandtab:*/ 
/* $Id: TestBedPacketLogger.java,v 1.2 2006/10/24 02:18:53 phoebusc Exp $ */


package net.tinyos.testbed;

import net.tinyos.util.*;
import java.io.*;
import java.util.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

/** Connects to a set of packet sources and logs all packets read. 
  * The sources are assumed to be serial forwarders in specific ports in the local machine,
  * but this is easy to change.
  *@author Rodrigo Fonseca (rfonseca at cs.berkeley.edu)
  */
public class TestBedPacketLogger {
   protected class TestBedMote implements net.tinyos.packet.PacketListenerIF  {
     private Receiver receiver;
     private Date date;
     private long time;
     private long baseTime;
     private int id;
     private int port;
     private DataOutputStream dos;
     private MessageFactory messageFactory;
 
     /* This creates a new mote listener. It assumes that a mote with
      * programmed id <i> is connected to a serial forwarder at port
      * 9100 + i 
      */
     public TestBedMote(int id, long baseTime, OutputStream os) {
       this.dos = new DataOutputStream(os);
       this.id = id;
       this.baseTime = baseTime;
       this.port = 9100+id;
       System.err.println("Starting connection to mote "+id);
       PhoenixSource source = BuildSource.makePhoenix("sf@127.0.0.1:"+port, PrintStreamMessenger.err);
       // Start source if it isn't started yet
       try {
          source.start();
       }
       catch (IllegalThreadStateException e) { }

       source.registerPacketListener(this);
       messageFactory = new MessageFactory(source);
     
     }

     public void packetReceived(byte[] packet) {
        long time = System.currentTimeMillis() - this.baseTime;
        Date date = new Date(System.currentTimeMillis());
	final TOSMsg msg = messageFactory.createTOSMsg(packet);
        //CBRMessage cMsg = new CBRMessage();
        //if (msg.get_type() == NoGeoConstants.AM_CBR_NOGEO_MSG) {
        //    cMsg.dataSet(msg.dataGet(), msg.offset_data(0), 0, msg.get_length());
        //    Dump.printPacket(System.out, cMsg.dataGet());
        //}
        synchronized(System.out) {
            System.out.print(id + " " + time + " ");
            Dump.printPacket(System.out, msg.dataGet());
            System.out.println();
        }
        try {
            synchronized (this.dos) {
               dos.writeShort(this.id);
               dos.writeLong(time);
               dos.writeShort(packet.length);
               dos.write(packet);
            }
       } catch (Exception e) {
            e.printStackTrace(System.err);
       }
     }
   }   
   
   private Vector motes;

   public TestBedPacketLogger(TestBedConfig tbConfig, int seconds) {
      OutputStream os = null;
      try {
        os = new BufferedOutputStream(new FileOutputStream("data.out"));
      } catch (Exception e) {
        e.printStackTrace(System.err);
        System.exit(0);
      }
      long now = System.currentTimeMillis();
      motes = new Vector();

      Iterator motesIt = tbConfig.getMotesIterator();
      TestBedConfig.TestBedConfigMote configMote;
      while (motesIt.hasNext()) {
         configMote = (TestBedConfig.TestBedConfigMote) motesIt.next(); 
         motes.addElement(new TestBedMote(configMote.getId(),now,os));
      }
      if (seconds > 0) {
        System.err.println("TestBedPacketLogger starting for " + seconds + " seconds");
        try{
            Thread.sleep(seconds * 1000);
            synchronized(os) {
              os.flush();
              os.close();
            }
            System.exit(0);
        } catch (Exception e) {e.printStackTrace(System.err);}
      } else {
        System.err.println("TestBedPacketLogger starting, will run until the next blackout");
      }
   }

   private static void printUsage() {
      System.err.println("usage: TestBedPacketLogger <configuration file> <seconds>");
      System.err.println("\t if seconds is 0, the logger is run forever");
   }
   public static void main(String[] args) throws IOException {
      int seconds = 0;
      TestBedConfig tbConfig;
      if (args.length == 2) {
        try {
           tbConfig = new TestBedConfig(args[0]); 
           try { 
              seconds = Integer.parseInt(args[1]);
              if (seconds < 0) seconds = 0;
           } catch(NumberFormatException e) {
              seconds = 0;
           }
           System.out.println("Read " + tbConfig.getNumberOfMotes() + " motes from " + args[0]);
           TestBedPacketLogger pl = new TestBedPacketLogger(tbConfig,seconds);
        } catch(FileNotFoundException e) {
           System.err.println(e);
           System.exit(-1);
        }
      } else {
        printUsage();
        System.exit(-1);
      }
   }
}

