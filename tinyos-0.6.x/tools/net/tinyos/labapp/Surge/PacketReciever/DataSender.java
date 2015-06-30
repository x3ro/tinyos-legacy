

package Surge.PacketReciever;

import java.util.*;
import java.io.*;
import javax.comm.*;
import Surge.Packet.*;


public class DataSender implements Runnable{

OutputStream out;

public void run(){
       	 try{
                while(1 == 1){
                        Thread.sleep(300);
			sendPacket();
                }
       	 }catch(Exception e){
		e.printStackTrace();	
	}
	}

	void sendPacket(){
       	 try{
                        byte[] packet = new byte[Packet.NUMBER_OF_BYTES];
                        packet[0] = (byte)0xff;
                        packet[1] = 0x17;
                        packet[2] = 0x19;
                        packet[3] = 0x1;
                        packet[4] = 0x1;
                        packet[5] = 0x79;
			System.out.println("start ........................");
                        out.write(packet);
			System.out.println("done ........................");
       	 }catch(Exception e){
		e.printStackTrace();	

	 }
	}

	DataSender(OutputStream pOut){
	 out = pOut;
	}


}
