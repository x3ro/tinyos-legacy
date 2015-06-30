package net.tinyos.tools;

import net.tinyos.util.*;
import java.io.*;

public class Send {
    public static void main(String[] argv) throws IOException
    {
	SerialForwarderStub sfw = new SerialForwarderStub("localhost", 9000);
	try { sfw.Open(); }
	catch (IOException e) {
	    e.printStackTrace();
	    System.exit(2);
	}
	byte[] packet = new byte[argv.length];
	for (int i = 0; i < argv.length; i++)
	    packet[i] = (byte) Integer.parseInt(argv[i], 16);

	try { sfw.Write(packet); }
	catch (IOException e) {
	    e.printStackTrace();
	    System.exit(2);
	}
	for (int i = 0; i < SerialForwarderStub.PACKET_SIZE; i++) {
	    System.out.print(Integer.toHexString(packet[i] & 0xff)+ " ");
	}
	System.out.println();
    }
}    
