package Surge;

import java.io.*;
import java.util.*;
import java.awt.*;
import java.applet.Applet;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.sql.Time;
import Surge.PacketReciever.*;

public class Inject implements Runnable {
    static PacketReciever pr;
    static byte[] packet;
    static boolean go;
    
    public Inject(PacketReciever r) {
	pr = r;
    }
    public void run() {
	
	try{
	    
	    int seq_num = 1;
            while(true){
		int i = 0;
		packet = new byte[36];
		packet[i] = (byte)0xff; i ++;
		packet[i] = (byte)0xff; i ++;
		packet[i] = 0x17; i ++;
		packet[i] = 0x77; i ++;
		//level
		packet[i] = 1; i ++;
		packet[i] = 1; i ++;
		packet[i] = 1; i ++;
		//end of hops
		//end of neighbor_list
		
		//update num
		i = 17;
		packet[i] = 0; i ++;
		//cost
		packet[i] = 0; i ++;
		packet[i] = 0; i ++;
	
		//seq_num
		i = 24;	
		packet[i] = (byte)(seq_num & 0xff); i ++;
		packet[i] = (byte)(seq_num >> 8); i ++;
		seq_num += 1;
		pr.write(packet);
		for(int j = 0; j < packet.length; j++) System.out.print(packet[j] + " ");
		System.out.println(".");
		Thread.sleep(10000);
	     }
	}catch(Exception e){
		e.printStackTrace();
	}
    }

}
