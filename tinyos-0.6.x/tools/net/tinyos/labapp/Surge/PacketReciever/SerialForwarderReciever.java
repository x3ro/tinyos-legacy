package Surge.PacketReciever;

import Surge.*;
import Surge.event.*;
import Surge.util.*;
import java.util.*;
import java.io.*;
import javax.comm.*;
import Surge.Packet.*;
import SerialForwarderReader;
import PacketListenerIF;

public class SerialForwarderReciever extends PacketReciever implements PacketListenerIF
{
	SerialForwarderReader r;
	public SerialForwarderReciever(String hostname, int port) throws IOException
	{
		 r = new SerialForwarderReader(hostname, port);
		 //r = new SerialForwarderReader("10.212.2.59",9000);
		 r.Open();
		 r.registerPacketListener(this);
		 recievePacketsThread = new Thread(this);
		 recievePacketsThread.setPriority(Thread.MIN_PRIORITY);
		 recievePacketsThread.start(); 
	}

    public SerialForwarderReciever() throws IOException {
	this("localhost", 9000);
    }

	public void run() //throws IOException
	{
		try{
        	 r.Read();
		} catch(Exception e){e.printStackTrace();}
	}

	public void packetReceived(byte[] packet){
		Packet p  = new Packet(packet);
		if(p.isValid()){
			for(int i = 0; i < packet.length; i ++){
				System.out.print(Hex.toHex(((int)packet[i] & 0xff)) + " ");
			}
			System.out.println();
      			TriggerPacketEvent(new PacketEvent(this, p, Calendar.getInstance().getTime()));
		}else{
			System.out.println(".");
		}
	}
    public synchronized void write(byte [] packet) throws IOException{
	r.Write(packet);
    }
}
