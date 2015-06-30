package net.tinyos.moteview.Packet;

import net.tinyos.moteview.Packet.*;
import java.util.*;
import net.tinyos.moteview.util.*;

/**
 * This class will hold all information about the packets.
 * As the packets change between versions, the static variables in this class
 * can be changed to reflect changes, thereby keeping the packet specifics
 * contained in this class and increasing modularity.
 *  This class is the default class used for all packet events in Surge
 *
 * @author Kamin Whitehouse
 */
public class Packet extends net.tinyos.moteview.Packet.SuperPacket
{
		          //the following static variables define which byte contains the following data
	protected static int AM_DEVICE_ADDRESS = 0;
	protected static int AM_HANDLER = 2;
	protected static int GROUP_ID = 3;
	public static int PACKET_TYPE = 4;
        protected static int SOURCE_NODE_HIGH = 6;
	protected static int SOURCE_NODE_LOW = 5;
        protected static int DEST_NODE_HIGH = 8;
	protected static int DEST_NODE_LOW = 7;
	protected static int CHIRP_TTL = 9;
	protected static int CHIRP1_NODE_HIGH = 11;
	protected static int CHIRP1_NODE_LOW = 10;
	protected static int CHIRP1_SS_HIGH = 13;
	protected static int CHIRP1_SS_LOW = 12;
	protected static int CHIRP2_NODE_HIGH = 15;
	protected static int CHIRP2_NODE_LOW = 14;
	protected static int CHIRP2_SS_HIGH = 17;
	protected static int CHIRP2_SS_LOW = 16;
	protected static int CHIRP3_NODE_HIGH = 19;
	protected static int CHIRP3_NODE_LOW = 18;
	protected static int CHIRP3_SS_HIGH = 21;
	protected static int CHIRP3_SS_LOW = 20;
	protected static int CHIRP4_NODE_HIGH = 23;
	protected static int CHIRP4_NODE_LOW = 22;
	protected static int CHIRP4_SS_HIGH = 25;
	protected static int CHIRP4_SS_LOW = 24;
	protected static int CHIRP5_NODE_HIGH = 27;
	protected static int CHIRP5_NODE_LOW = 26;
	protected static int CHIRP5_SS_HIGH = 29;
	protected static int CHIRP5_SS_LOW = 28;
        protected static int CRC_HIGH = 35;
        protected static int CRC_LOW = 34;


	// REPROGRAMMING

	protected static int NETPROG_NODE_LOW = 8;
	protected static int NETPROG_NODE_HIGH = 9;
	protected static int NETPROG_PROGID_LOW = 10;
	protected static int NETPROG_PROGID_HIGH = 11;
	protected static int NETPROG_PROGLEN_LOW = 12;
	protected static int NETPROG_PROGLEN_HIGH = 13;

	public int GetNodeID ( )
	{
	    return GetField ( NETPROG_NODE_HIGH, NETPROG_NODE_LOW );
	}

	public int GetProgID ( )
	{
	    return GetField ( NETPROG_PROGID_HIGH, NETPROG_PROGID_LOW );
	}

	public int GetProgLength ( )
	{
	    return GetField ( NETPROG_PROGLEN_HIGH, NETPROG_PROGLEN_LOW );
	}

        /** tinyos broadcast address
         */
        public static short TOS_ADDR_BROADCAST = (short)0xFFFF;
        /** tinyos uart address
         */
        public static short TOS_ADDR_UART      = (short)0x007E;

        /**
         * Default Constructor
         * @param pData byte array representing the packet
         */
	public Packet(byte pData[])
	{
		super(pData);
	}

	          //*****---Create Hop Array---******//
   /**
    * Make an array that consists solely of the moteID's
    * @return Vector of the form [Source] [Intermediate Hops...] [Dest]
    */
   public Vector CreateRoutePathArray()
   {
	Vector routePath = new Vector();
   	routePath.add(new Integer(GetSourceNode()));
	return routePath;
   }

   /** Make an array that consists of two arrays, each containing mote numbers
    * the two arrays are the same lengths, and corresponding elements indicate
    * connectivity in the sense that the second can HEAR the first
    * @return a vector consisting of the source and destination vectors
    */
   public Vector CreateRFConnectivityArray()
   {
    if(GetField(PACKET_TYPE)==0){return null;}

    Vector RFConnectivity = new Vector();
    Vector sources = new Vector();
    Vector destinations = new Vector();

        if (GetField(CHIRP1_NODE_HIGH,CHIRP1_NODE_LOW) != 0)
        {
            sources.add(new Integer(GetField(CHIRP1_NODE_HIGH,CHIRP1_NODE_LOW)));
            destinations.add(new Integer(GetSourceNode()));
        }
	sources.add(new Integer(GetField(CHIRP2_NODE_HIGH,CHIRP2_NODE_LOW)));
	destinations.add(new Integer(GetSourceNode()));
	sources.add(new Integer(GetField(CHIRP3_NODE_HIGH,CHIRP3_NODE_LOW)));
	destinations.add(new Integer(GetSourceNode()));
	sources.add(new Integer(GetField(CHIRP4_NODE_HIGH,CHIRP4_NODE_LOW)));
	destinations.add(new Integer(GetSourceNode()));
	sources.add(new Integer(GetField(CHIRP5_NODE_HIGH,CHIRP5_NODE_LOW)));
	destinations.add(new Integer(GetSourceNode()));

	RFConnectivity.add(sources);
	RFConnectivity.add(destinations);
	return RFConnectivity;
   }

   /**
    * Make an array that consists solely of the Signal strengths of all motes in the route
    * @return Vector of the form [Source] [Intermediate Hops...] [Dest] (should be the same as CreateRoutePathArray)
    */
   public Vector CreateSignalStrengthArray()
   {
    if(GetField(PACKET_TYPE)==0){return null;}
    Vector SSArray = new Vector();
	Vector sources = new Vector();
	Vector destinations = new Vector();
	Vector signalStrength = new Vector();

        if (GetField(CHIRP1_NODE_HIGH,CHIRP1_NODE_LOW) != 0)
        {
            sources.add(new Integer(GetField(CHIRP1_NODE_HIGH,CHIRP1_NODE_LOW)));
            destinations.add(new Integer(GetSourceNode()));
            signalStrength.add(new Integer(GetField(CHIRP1_SS_HIGH,CHIRP1_SS_LOW)));
        }
        if (GetField(CHIRP2_NODE_HIGH,CHIRP2_NODE_LOW) != 0)
        {
            sources.add(new Integer(GetField(CHIRP2_NODE_HIGH,CHIRP2_NODE_LOW)));
            destinations.add(new Integer(GetSourceNode()));
            signalStrength.add(new Integer(GetField(CHIRP2_SS_HIGH,CHIRP2_SS_LOW)));
        }
        if (GetField(CHIRP3_NODE_HIGH,CHIRP3_NODE_LOW) != 0)
        {
            sources.add(new Integer(GetField(CHIRP3_NODE_HIGH,CHIRP3_NODE_LOW)));
            destinations.add(new Integer(GetSourceNode()));
            signalStrength.add(new Integer(GetField(CHIRP3_SS_HIGH,CHIRP3_SS_LOW)));
        }
	/*sources.add(new Integer(GetField(CHIRP4_NODE_HIGH,CHIRP4_NODE_LOW)));
	destinations.add(new Integer(GetSourceNode()));
	signalStrength.add(new Integer(GetField(CHIRP4_SS_HIGH,CHIRP4_SS_LOW)));
	sources.add(new Integer(GetField(CHIRP5_NODE_HIGH,CHIRP5_NODE_LOW)));
	destinations.add(new Integer(GetSourceNode()));
	signalStrength.add(new Integer(GetField(CHIRP5_SS_HIGH,CHIRP5_SS_LOW)));
	sources.add(new Integer(GetField(CHIRP6_NODE_HIGH,CHIRP6_NODE_LOW)));
	destinations.add(new Integer(GetSourceNode()));
	signalStrength.add(new Integer(GetField(CHIRP6_SS_HIGH,CHIRP6_SS_LOW)));*/

	SSArray.add(sources);
	SSArray.add(destinations);
	SSArray.add(signalStrength);
	return SSArray;
   }

   /**
    * Get the length of the route
    * @return at least 1 and at most 5
    */
   public int GetRouteLength()
   {
	return 1;
   }

   /**
    * Get the source node
    * @return int value representing the source node
    */
   public int GetSourceNode()
   {
    return GetField(SOURCE_NODE_HIGH, SOURCE_NODE_LOW);
   }
}
