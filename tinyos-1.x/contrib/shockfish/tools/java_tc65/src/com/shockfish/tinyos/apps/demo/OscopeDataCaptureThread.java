package com.shockfish.tinyos.apps.demo;

import java.io.IOException;

import com.shockfish.tinyos.tools.MamaBoardManager;
import com.shockfish.tinyos.gateway.TOSBuffer;
import com.shockfish.tinyos.tools.CldcLogger;
import com.shockfish.tinyos.message.tinynode.TOSMsg;
import com.shockfish.tinyos.packet.CldcPacketizer;
import net.tinyos.util.PrintStreamMessenger;

public class OscopeDataCaptureThread extends Thread {

    public final static int SENSOR_SAMPLING = 10;
    
    private CldcPacketizer serialPacketizer;
    public TOSBuffer buffer;
    boolean running;
    
    public OscopeDataCaptureThread(MamaBoardManager mamaBoardManager) {
        this.serialPacketizer = mamaBoardManager.serialAsc0Packetizer;
        this.buffer = new TOSBuffer();
    }

    public void run() {
        
        int samples = 0;
        
        try {
            serialPacketizer.open(PrintStreamMessenger.err);
        } catch (IOException e) {
            CldcLogger.severe("Error on opening the packetizer:"+e.getMessage());
            return;
        }
        
        running = true;
        
        // capture loop
        while (running) {
            byte[] packet = null;
            try {
                packet = serialPacketizer.readPacket();
            } catch (IOException ioe) {
                CldcLogger.severe("Error on reading packet :"+ioe.getMessage());
                continue;
            }
            
            TOSMsg tosMsg = new TOSMsg(packet);
            
            // Cldc does support reflection, so we have to DIY
            if (tosMsg.get_type() == OscopeMsg.AM_TYPE) {
                OscopeMsg oscopeMsg = new OscopeMsg();
                oscopeMsg.dataSet(tosMsg.dataGet(), tosMsg.offset_data(0), 0,tosMsg.get_length());
                
                // dump the packet in pretty format
                System.out.println(oscopeMsg);
                
                // we are only interested in the light sensor.
                if (oscopeMsg.get_channel() == 2) {
                    samples++;
                    if (samples >= SENSOR_SAMPLING) {
                        samples = 0;
                        buffer.addElement(oscopeMsg.dataGet());
                    }
                }
            }
        }
        
        // try to close (even though we may have been closed already in stopRequest
        closePacketizer();
        return;
    }
    
    public void stopRequest() {
        running = false;
        closePacketizer();
    }
    
    private void closePacketizer() {
        try {
            serialPacketizer.close();
        } catch (Exception e) {
            //CldcLogger.severe("Error on closing the packetizer:"+.e.getMessage());
        }
    }
    
}
