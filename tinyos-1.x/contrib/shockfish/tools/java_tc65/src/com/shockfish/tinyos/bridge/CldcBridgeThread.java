package com.shockfish.tinyos.bridge;

import net.tinyos.message.Dump;
import net.tinyos.util.PrintStreamMessenger;
import com.shockfish.tinyos.tools.Tc65Manager;
import com.shockfish.tinyos.packet.*;
import java.io.*;

public class CldcBridgeThread extends Thread implements CldcPacketListener {

	CldcPacketizer serialPacketizer;
	CldcNetworkByteSource nsb;
	CldcPacketizer airPacketizer;
	Tc65Manager manager;
    
    boolean stopRequested;
	String inetHost;
	int inetPort;
    
	byte inetMessageFilter;

	public CldcBridgeThread(CldcPacketizer serialPacketizer,
			Tc65Manager manager, String inetHost, int inetPort) {
		this.serialPacketizer = serialPacketizer;
		this.inetHost = inetHost;
		this.inetPort = inetPort;
		//this.inetMessageFilter = inetMessageFilter;
		this.manager = manager;

	}

	public void run() {

        stopRequested = false;
        
        this.nsb = new CldcNetworkByteSource(this.inetHost, this.inetPort, manager.getGprsConf());
        this.airPacketizer = new CldcPacketizer("GPRS", nsb, 0); // WARNING 1 is TINYOS
        
		serialPacketizer.setPacketListener(this);

		try {
			airPacketizer.open(PrintStreamMessenger.err);
		} catch (IOException ioe) {
			ioe.printStackTrace();
		}

		int packetCnt = 0;
		for (;;) {
			try {
				byte[] packet = airPacketizer.readPacket();
				// write back to serial interface
				long t1 = System.currentTimeMillis();
				serialPacketizer.writePacket(packet);
				long t2 = System.currentTimeMillis();
				System.out.println("*** FWD GPRS > SERIAL done in "+(t2-t1));
                if (stopRequested) {
                    serialPacketizer.removePacketListener(); 
                    return;
                }
                
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
	}

	// any packet received by the serial are sent back to the air iface
	public void packetReceived(byte[] packet) {
		try {
			// (byte)0x0A
			// packet filtering, oscope specific
			//if (packet.length > 7)
			//if (packet[4] == this.inetMessageFilter)
			long t1 = System.currentTimeMillis();
			 airPacketizer.writePacket(packet);
			long t2 = System.currentTimeMillis();
			System.out.println("*** FWD GPRS < SERIAL done in "+(t2-t1));

		} catch (IOException ioe) {
			ioe.printStackTrace();
		}
	}
    
    public void requestStop() {
        try {
            airPacketizer.close();
        } catch (Exception e) {}    
        
        stopRequested = true;
    }

}