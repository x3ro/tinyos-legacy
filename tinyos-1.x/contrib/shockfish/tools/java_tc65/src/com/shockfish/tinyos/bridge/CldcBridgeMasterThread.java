package com.shockfish.tinyos.bridge;

import java.io.IOException;

import com.shockfish.tinyos.tools.MamaBoardManager;
import com.shockfish.tinyos.packet.CldcNetworkByteSource;
import com.shockfish.tinyos.packet.Tc65SerialByteSource;
import com.shockfish.tinyos.packet.CldcPacketizer;
import net.tinyos.util.PrintStreamMessenger;
import com.shockfish.tinyos.tools.CldcLogger;

public class CldcBridgeMasterThread extends Thread {

    MamaBoardManager manager;
    String inetHost;
    int inetPort;
    boolean stopRequested;
    
    Tc65SerialByteSource tsb2;
    CldcPacketizer serialPacketizer;
    CldcBridgeThread br;
    
	public CldcBridgeMasterThread(MamaBoardManager manager, String host, int port) {
		this.manager = manager;
        this.inetHost = host;
        this.inetPort = port;       
        this.serialPacketizer = manager.serialAsc0Packetizer;
        
	}
    
    public void requestStop() {
        try {
            serialPacketizer.close();
        } catch (Exception e) {}    
        try {
            br.requestStop();
        } catch (Exception e) {}  
        
        stopRequested = true;
    }

	public void run() {
        stopRequested = false;

		try {

            CldcLogger.info("Starting bridge, host="+this.inetHost
                    +", port=" + this.inetPort);

			br = new CldcBridgeThread(serialPacketizer, this.manager,
					inetHost, inetPort);
			br.start();
            serialPacketizer.open(PrintStreamMessenger.err);
		} catch (IOException e) {
			e.printStackTrace();
		}
		int packetCnt = 0;
		for (;;) {
			try {
				byte[] packet = serialPacketizer.readPacket();
			} catch (IOException e) {
				e.printStackTrace();
			}
            
            if (stopRequested) { return;}
		}

	}

}
