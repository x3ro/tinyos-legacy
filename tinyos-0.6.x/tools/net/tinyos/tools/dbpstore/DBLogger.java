package net.tinyos.tools.dbpstore;
import net.tinyos.util.*;
import java.io.*;

public class DBLogger {
    public static void main(String args[]) {
	Class c = DBLogger.class;
	if (args.length < 2) {
	    System.err.println("usage: java "+c+" [forwarder address] [port] ");
	}
	System.out.println("\n"+c+" started");
 	try {
	    DBSensorListener dbwriter = new DBSensorListener();
	    dbwriter.Connect();
	    SerialForwarderStub stub = new SerialForwarderStub(args[0],Integer.parseInt(args[1]));
	    stub.Open();
	    stub.registerPacketListener(dbwriter);
	    try {
		BeaconInjector bi = new BeaconInjector(stub,(byte) 0x42);
		Thread t = new Thread(bi);
		t.start();
	    } catch (IOException e) {
		System.err.println("Will not be able to inject beacons. Sorry");
		e.printStackTrace();
	    }
	    stub.Read();
	}
	catch (Exception e) {
	    e.printStackTrace();
	}
    }

}
