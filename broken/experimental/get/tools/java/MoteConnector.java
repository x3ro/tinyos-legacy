import java.io.*;
import java.util.*;

import net.tinyos.packet.*;
import net.tinyos.util.*;

public class MoteConnector {
    
    private static MoteConnector _instance = new MoteConnector();

    private TreeMap motecomMap = new TreeMap();
    private HashMap connectionMap = new HashMap();

    private MoteConnector() {
	Timer t = new Timer(true);
	t.scheduleAtFixedRate(new TimerTask() {
		public void run() {
		    loadMoteList();
		}}, 0, 1000);
    }

    protected void loadMoteList() {
	
	motecomMap.clear();

	try {
	    BufferedReader in = new BufferedReader(new FileReader("motes.txt"));
	    String str;
	    while ((str = in.readLine()) != null) {
		processMoteListEntry(str);
	    }
	    in.close();
	} catch (IOException e) { }

	loadTelosMoteList();
    }

    private void processMoteListEntry(String line) {
	String[] tokens = line.split("\\s+",3);
	String name = tokens[0];
	String motecom = tokens[1];
	
	motecomMap.put(name, motecom);
    }

    private void loadTelosMoteList() {
	try {
	    BufferedReader in = new BufferedReader(new FileReader("motelist.txt"));
	    String str;
	    while ((str = in.readLine()) != null) {
		processTelosMoteListEntry(str);
	    }
	    in.close();
	} catch (IOException e) { }
    }

    private void processTelosMoteListEntry(String line) {
	String[] tokens = line.split(",",4);
	if (tokens.length >= 2) {
	    String name = tokens[0];
	    String motecom = "serial@" + tokens[1] + ":telos";
	    motecomMap.put(name, motecom);
	}
    }

    public static MoteConnector getInstance() {
	return _instance;
    }

    public Map getNameMap() {
	return motecomMap;
    }

    public void registerPacketListener(String name, 
				       net.tinyos.packet.PacketListenerIF listener)
	throws NoSuchNameException {

	if (connectionMap.containsKey(name)) {

	    ConnectionEntry ce = (ConnectionEntry) connectionMap.get(name);
	    ce.source.registerPacketListener(listener);
	    return;
	    
	} else {

	    if (motecomMap.containsKey(name)) {

		String motecom = (String) motecomMap.get(name);

		System.err.println("OPEN CONNECTION to " + name + " motecom: " + motecom);

		PhoenixSource source = 
		    BuildSource.makePhoenix(motecom, PrintStreamMessenger.err);
		source.setResurrection();
		source.start();
		source.registerPacketListener(listener);

		ConnectionEntry ce = new ConnectionEntry();
		ce.source = source;
		ce.clientCount = 1;
		
		connectionMap.put(name, ce);

	    } else {

		throw new NoSuchNameException();
	    }
	}
    }

    public void deregisterPacketListener(String name, 
					 net.tinyos.packet.PacketListenerIF listener)
	throws NoSuchNameException {
	
	if (connectionMap.containsKey(name)) {

	    ConnectionEntry ce = (ConnectionEntry) connectionMap.get(name);
	    ce.source.deregisterPacketListener(listener);
	    ce.clientCount--;

	    if (ce.clientCount == 0) {

		System.err.println("CLOSE CONNECTION to " + name);

		ce.source.shutdown();
		connectionMap.remove(name);
	    }

	} else {
	    throw new NoSuchNameException();
	}
    }

    private class ConnectionEntry {
	public PhoenixSource source;
	public int clientCount = 0;
    }
}
