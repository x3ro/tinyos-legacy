import java.io.*;
import java.util.*;
import java.net.*;
import java.awt.*;

public class SignalStrength{
    static LinkedList packets = new LinkedList();    
    
    static final int SS_LOW_BYTE = 37;
    static final int SS_HI_BYTE = 38;
    
    public static void main(String[] args){
	Proximity demo;
	Frame f = new Frame("Proximity Meter");

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
			    int ss = Integer.parseInt(s) + Integer.parseInt(st.nextToken())*256;
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
