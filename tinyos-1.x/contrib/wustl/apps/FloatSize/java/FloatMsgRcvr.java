// $Id: FloatMsgRcvr.java,v 1.1 2007/04/05 07:58:05 chien-liang Exp $

/* Authors:	Phil Levis <pal@cs.berkeley.edu>,
 Chien-Liang Fok <liang@cse.wustl.edu>
 * Date:        April 5, 2007
 * Desc:        Main class for receiving float messages.
 *
 */
import java.util.*;
import java.io.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class FloatMsgRcvr implements MessageListener
{
	private MoteIF moteIF;
	private String source;
	private PhoenixSource psource;
	private boolean debug;

	/**
	 * Creates an AgentInjector.
	 *
	 * @param source The MoteIF source, e.g., COM4:mica2 or sf@localhost:9001
	 * @param connect Whether the AgentInjector should immediately connect to the
	 * base station, or wait for the connect() method to be called.
	 * @param col The number of columns in the network topology
	 * @param createGUI Whether to create a GUI
	 * @param debug Whether to be in debug mode
	 * @param aID The initial agent ID
	 * @throws Exception
	 */
	public FloatMsgRcvr(String source, boolean debug) throws Exception
	{
		this.source = source;
		this.debug = debug;
		connect();
		moteIF.registerListener(new FloatMsg(), this);
	}

	/**
	 * Connect to the MoteIF.
	 */
	public void connect() throws Exception {
		if (moteIF == null) {
			if (source.startsWith("sf")) {
				//moteIF = new MoteIF(PrintStreamMessenger.err);
				//moteIF = new MoteIF(BuildSource.makePhoenix("sf@localhost:9001", PrintStreamMessenger.err));
				psource = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
				moteIF = new MoteIF(psource);
			} else {
				psource = BuildSource.makePhoenix(
					BuildSource.makeArgsSerial(source),
					net.tinyos.util.PrintStreamMessenger.err);
				moteIF = new MoteIF(psource);
			}
			log("Created MoteIF: " + source);
		}
	}

	/**
	 * Disconnects the AgentInjector from the MoteIF.
	 */
	public void disconnect() {
		if (moteIF != null && psource != null) {
			psource.shutdown();
			moteIF = null;
		}
	}

	/**
	 * Impelements the MessageListener interface.
	 */
	public void messageReceived(int dest, Message msg) {
	    if (msg.amType() == FloatMsg.AM_TYPE) {
			FloatMsg fm = (FloatMsg)msg;
			log("Current float value: " + fm.get_f());
	    } else {
			System.out.println("Unknown type of message.");
			System.out.println(""+msg);
		}
	}

	public static void main(String[] args) {

		//System.out.println("" + Float.intBitsToFloat(0x3E800000));
		//System.out.println("" + Float.floatToRawIntBits((float)0.25));

		try {
			String source = "COM27:telosb"; //"sf@localhost:9001";
			boolean debug = false;
			int index = 0;
			while (index < args.length) {
				String arg = args[index];
				if (arg.equals("-h") || arg.equals("--help")) {
					usage();
					System.exit(0);
				} else if (arg.equals("-comm")) {
					index++;
					source = args[index];
				}
				else if (arg.equals("-d"))
					debug = true;
				else {
					usage();
					System.exit(1);
				}
				index++;
			}
			new FloatMsgRcvr(source, debug);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	private static void usage() {
		System.err.println("usage: FloatMsgRcvr [options] -comm [source]");
		System.err.println("\t[options]:");
		System.err.println("\t\t-h Display help message.");
		System.err.println("\t\t-d Enable debug mode.");
		System.err.println("\t-[source]:");
		System.err.println("\t\tCOMx:[platform] or tossim-serial, default COM4:mica2");

	}

	private void log(String msg) {
		System.out.println("FloatMsgRcvr: " + msg);
	}

}

