import net.tinyos.util.*;
import net.tinyos.message.*;
import java.io.*;
import java.util.*;

public class PingPong implements MessageListener,Runnable {

    public static byte group_id = 0x7D;
    MoteIF mote;

    public PingPong() {
	try {
	    mote = new MoteIF(PrintStreamMessenger.err, PingPong.group_id);
	    mote.registerListener(new PongMsg(), this);
	}
	catch (Exception e) {
	    System.err.println("Unable to connect to sf@localhost:9001");
	    System.exit(-1);
	}
    }

    public void messageReceived(int dest_addr, Message msg) {
        if (msg instanceof PongMsg) {
            pongReceived( dest_addr, (PongMsg)msg);
        } else {
            throw new RuntimeException("messageReceived: Got bad message type: "+msg);
        }
    }

    public void pongReceived(int dest_addr, PongMsg pmsg) {
        int src_rssi = pmsg.get_src_rssi();
        int dest_rssi = pmsg.get_dest_rssi();
        if (src_rssi > 127) src_rssi = src_rssi - 256;
        if (dest_rssi > 127) dest_rssi = dest_rssi - 256;
        System.out.println("================================================");
	System.out.println("Source: " + pmsg.get_src());
	System.out.println("RSSI:   " + src_rssi + "\t" + (src_rssi-45) + " dBm");
	System.out.print("LQI:    " + pmsg.get_src_lqi() + "\t");
        if (pmsg.get_src_lqi() >= 104) 
	    System.out.println("High");
        else if (pmsg.get_src_lqi() >= 80) 
	    System.out.println("Medium");
	else
	    System.out.println("Low");
        System.out.println("------------------------------------------------");
	System.out.println("Dest:   " + pmsg.get_dest());
	System.out.println("RSSI:   " + dest_rssi + "\t" + (dest_rssi-45) + " dBm");
	System.out.print("LQI:    " + pmsg.get_dest_lqi() + "\t");
        if (pmsg.get_dest_lqi() >= 104) 
	    System.out.println("High");
        else if (pmsg.get_dest_lqi() >= 80) 
	    System.out.println("Medium");
	else
	    System.out.println("Low");
	System.exit(0);
    }

    public static void main(String[] args) throws IOException {
        if (args.length == 1) {
          group_id = (byte) Integer.parseInt(args[0]);
	}
	PingPong runclass = new PingPong();
	Thread th = new Thread(runclass);
        th.start();
    }

    public void run() {
        PingMsg ping = new PingMsg();
        ping.set_src(0x007E);
        try {
	    // inject packet
	    mote.send(MoteIF.TOS_BCAST_ADDR, ping);
	}
	catch (IOException ioe) {
	    System.err.println("Unable to sent message to mote: "+ ioe);
	    ioe.printStackTrace();
	    System.exit(-1);
	}
	// wait for response
	while(true) {
	}
    }

}
