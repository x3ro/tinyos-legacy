package net.tinyos.widgets;

import java.io.*;
import java.util.*;
import java.net.*;
import java.awt.*;

public class SignalStrength{
    static LinkedList packets = new LinkedList();    
    
    public static void main(String[] args){
	Proximity demo;
	Frame f = new Frame("Proximity Meter");
	int SS_LOW_BYTE, SS_HIGH_BYTE;

	if (args.length != 2){
	    System.out.println("usage: java net/tinyos/widgets/SignalStrength l h");
	    System.out.println("where l and h are the positions of the low and high byte of the signal strength value in the packet");
	    System.exit(0);
	}
	SS_LOW_BYTE = Integer.parseInt(args[0]);
	SS_HIGH_BYTE = Integer.parseInt(args[1]);
	System.out.println(SS_LOW_BYTE);

	demo = new Proximity(packets);
	f.add(demo);
	f.setSize(new Dimension(400, 300));
	f.show();
	demo.start();

	try {
	    BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
	    while (true) {
		try {
		    if (in.ready()) {
			synchronized (packets) {
			    StringTokenizer st = new StringTokenizer(new String(in.readLine()),",");
			    String s = "";
			    for (int i=0; i<SS_LOW_BYTE; i++) {
				s = st.nextToken();
			    }
			    int ss = Hex.fromHex(s,s.length()) + Hex.fromHex(st.nextToken(), st.nextToken().length())*256;
			    packets.addLast(Integer.toString(ss));
			}
		    }
		} catch (Exception e){}
		Thread.sleep(10);
	    }
	} catch (Exception e) {
	    e.printStackTrace();
	}
    }
}


//////////////////////////////////////////////////
class Hex {
 
  public static final char[] hex_upper = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};   
  public static final char[] hex_lower = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};   

  public static int fromHex(String s, int length){
      if (length == 0){
	  return 0;
      }else{
	  for (int i=0; i < 16; i++){
	      if (hex_upper[i] == s.charAt(length-1) ||
		  hex_lower[i] == s.charAt(length-1)){
		  return (i+ (16 * Hex.fromHex(s,length-1)));
	      }
	  }
      }

      return 0;
  } 
}  
