package Surge.Packet;



import java.util.*;
import Surge.util.*;

	          //This class will hold all information about the packets
	          //as the packets change between versions, the static variables in this class
	          //can be changed to reflect changes, thereby keeping the packet specifics
	          //contained in this class and increasing modularity
public class Packet implements java.io.Serializable
{
	public static int NUMBER_OF_BYTES = 15;
	public static int NUMBER_OF_PACKETS_SO_FAR = 0;
	protected final byte[] data;
	protected final int    packetNumber;//e.g. this packet was the ith packet
	
	          //naming convention:  packet route goes:  Source (first hop)-->second hop-->third hop-->...-->last hop (currently fourth hop)-->destination (currently fifth hop)
		          //the following static variables define which byte contains the following data
	protected static int AM_DEVICE_ADDRESS = 0;
	protected static int AM_HANDLER = 0;
	protected static int GROUP_ID = 2;
	protected static int SOURCE_NODE = 3;
	protected static int SECOND_HOP = 4;
	protected static int THIRD_HOP = 5;
	protected static int FOURTH_HOP = 6;
	protected static int FIFTH_HOP = 7;
	protected static int SOURCE_SIGNAL_STRENGTH_HIGH = -1;
	protected static int SOURCE_SIGNAL_STRENGTH_LOW = -1;
	protected static int SECOND_HOP_SIGNAL_STRENGTH_HIGH = -1;
	protected static int SECOND_HOP_SIGNAL_STRENGTH_LOW = -1;
	protected static int THIRD_HOP_SIGNAL_STRENGTH_HIGH = -1;
	protected static int THIRD_HOP_SIGNAL_STRENGTH_LOW = -1;
	protected static int FOURTH_HOP_SIGNAL_STRENGTH_HIGH = -1;
	protected static int FOURTH_HOP_SIGNAL_STRENGTH_LOW = -1;
	protected static int FIFTH_HOP_SIGNAL_STRENGTH_HIGH = -1;
	protected static int FIFTH_HOP_SIGNAL_STRENGTH_LOW = -1;
	protected static int CHIRP_NODE_NUMBER = 11;
	protected static int CHIRP_SIGNAL_STRENGTH_HIGH = 9;
	protected static int CHIRP_SIGNAL_STRENGTH_LOW = 10;
	protected static int LAST_HOP_SIGNAL_STRENGTH_HIGH = 14;
	protected static int LAST_HOP_SIGNAL_STRENGTH_LOW = 13;
	protected static int LIGHT_HIGH = -1;
	protected static int LIGHT_LOW = 12;
	protected static int TEMP_HIGH = -1;
	protected static int TEMP_LOW = -1;
	
	protected static final byte    HANDLER_ID    = 0x7e;//the "value" of the handler ID (usually 6)
	protected static boolean HAVE_WARNED = false;//see hack in constructor
	protected static final int     ERROR         = -1;//standard error return value
	
	
//  static final int     NOT_CONNECTED = -1;
//  static final int     CORRUPTED     = -2;
//	private static final int     MAX_READINGS  =  8; // the highest numbered ss/mote id pair
//	private static final int     HANDLER_LOC   = 0;

	
	          //*****---CONSTRUCTOR---******//
	public Packet(byte[] pData)
	{
		data = pData;
		NUMBER_OF_PACKETS_SO_FAR++;
		packetNumber = NUMBER_OF_PACKETS_SO_FAR;
    
	    // this is a hack to make sure the packet is properly aligned
    	int locationOfAMHandler= GetIndexFromValue(HANDLER_ID);
    	if (locationOfAMHandler == -1) 
    	{
        	System.out.println("HANDLER "+HANDLER_ID+" not found");
    	} 
    	else if (locationOfAMHandler!=AM_HANDLER) 
    	{
        	int offset = locationOfAMHandler- AM_HANDLER;
        	byte[] newData = new byte[data.length];
        	for (int i=0; i < data.length-offset; i++) 
        	{
        		newData[i] = data[i + offset];
        	}
        	if (!HAVE_WARNED) System.out.println("****WARNING: PACKET BEING SHIFTED***");
        	HAVE_WARNED = true; 
    	}
	}
	          //*****---CONSTRUCTOR---******//
	
	          //*****---beginCUSTOM FUNCTIONS---******//
	          //this "custom functions" section is where all functions are held that must be 
	          //rewritten every time the packet structure changes.  The get/set functions
	          //in the next section build upon these and do not need to be changed
	          //The rest of this file should NEVER use a hard-coded byte-index (use the static variables)
	          
	          //*****---Create Hop Array---******//
	// Make an array that consists solely of the moteID's
   // The order this returns is [Source] [Intermediate Hops...] [Dest]
   public Vector CreateRoutePathArray()
   {
	int routeLength = GetRouteLength();
	Vector routePath = new Vector(routeLength);
	if(CHIRP_NODE_NUMBER != -1)
		routePath.add(new Integer(GetChirpNode()));
	if(routeLength>-1)
		routePath.add(new Integer(GetSourceNode()));
	if(routeLength>1)
		routePath.add(new Integer(GetSecondHop()));
	if(routeLength>2)
		routePath.add(new Integer(GetThirdHop()));
	if(routeLength>3)
		routePath.add(new Integer(GetFourthHop()));
	if(routeLength>4)
		routePath.add(new Integer(GetFifthHop()));
	return routePath;
   }
          //*****---Create Hop Array---******//

  	          //*****---Create Signal StrengthArray---******//
	// Make an array that consists solely of the Signal strengths of all motes in the route
   // The order this returns is [Source] [Intermediate Hops...] [Dest] (should be the same as CreateRoutePathArray)
   public Vector CreateSignalStrengthArray()
   {
	Vector signalStrength = new Vector();
	signalStrength.add(new Double(this.GetChirpSignalStrength()));
	signalStrength.add(new Double(this.GetLastHopSignalStrength()));
	return signalStrength;
   }
          //*****---Create Signal Strength Array---******//

  	          //*****---Create Signal Strength Source Array---******//
	// Make an array that consists solely of the Signal strengths of all motes in the route
   // The order this returns is [Source] [Intermediate Hops...] [Dest] (should be the same as CreateRoutePathArray)
   public Vector CreateSignalStrengthSourceArray()
   {
	Vector signalStrength = new Vector();
	signalStrength.add(new Integer(this.GetChirpNode()));
	signalStrength.add(new Integer(this.GetLastHop()));
	return signalStrength;
   }
          //*****---Create Signal Strength SOURCE Array---******//

  	          //*****---Create Signal Strength DESTINATION Array---******//
	// Make an array that consists solely of the Signal strengths of all motes in the route
   // The order this returns is [Source] [Intermediate Hops...] [Dest] (should be the same as CreateRoutePathArray)
   public Vector CreateSignalStrengthDestinationArray()
   {
	Vector signalStrength = new Vector();
	signalStrength.add(new Integer(this.GetSourceNode()));
	signalStrength.add(new Integer(this.GetDestinationNode()));
	return signalStrength;
   }
          //*****---Create Signal Strength DESTINATION Array---******//

  
	          //*****---GetRouteLength---******//
   // this functionreturns at least 1 and at most 5
   public int GetRouteLength() 
   { 
	return 2; //this is here because of some problems iwth th packets. take out.
  /*  int routeLength=5;
    if(data[FIFTH_HOP] == 0) routeLength = 4;
    if(data[FOURTH_HOP] == 0) routeLength = 3;
    if(data[THIRD_HOP] == 0) routeLength = 2;
    if(data[SECOND_HOP] == 0) routeLength = 1;//packet was sent directly by basestation mote
    if(CHIRP_NODE_NUMBER == -1)
	    return routeLength;
	return routeLength + 1;*/
   }
	          //*****---GetRouteLength---******//
   
	          //*****---END CUSTOM FUNCTIONS---******//
   
   
   
   
   
	          //*****---GET/SET Functions---******//
	 // this method returns the first array index of a byte with a particular value
   private int GetIndexFromValue(byte value) 
   {
       for (int i=0; i<data.length; i++) {
           if (data[i]==value) return i;         
       }
       return ERROR;
   }

	public byte[] GetData(){return data;	}
    public int GetAMDeviceAddress(){if(AM_DEVICE_ADDRESS==-1) return -1; return (0xff & (int)data[AM_DEVICE_ADDRESS]);}
	public int GetAMHandler(){if(AM_HANDLER==-1) return -1; return (0xff & (int)data[AM_HANDLER]);}
	public int GetSourceNode(){if(SOURCE_NODE==-1) return -1; return (0xff & (int)data[SOURCE_NODE]);}
	public int GetSecondHop(){if(SECOND_HOP==-1) return -1; return (0xff & (int)data[SECOND_HOP]);}
	public int GetThirdHop(){if(THIRD_HOP==-1) return -1; return (0xff & (int)data[THIRD_HOP]);}
	public int GetFourthHop(){if(FOURTH_HOP==-1) return -1; return (0xff & (int)data[FOURTH_HOP]);}
	public int GetFifthHop(){if(FIFTH_HOP==-1) return -1; return (0xff & (int)data[FIFTH_HOP]);}
//	public int GetSignalStrengthHigh(){if(SIGNAL_STRENGTH_HIGH==-1) return -1; return (0xff & (int)data[SIGNAL_STRENGTH_HIGH]);}
//	public int GetSignalStrengthLow(){if(SIGNAL_STRENGTH_LOW==-1) return -1; return (0xff & (int)data[SIGNAL_STRENGTH_LOW]);}
	public int GetLightHigh(){if(LIGHT_HIGH==-1) return -1; return (0xff & (int)data[LIGHT_HIGH]);}
	public int GetLightLow(){if(LIGHT_LOW==-1) return -1; return (0xff & (int)data[LIGHT_LOW]);}
	public int GetTempHigh(){if(TEMP_HIGH==-1) return -1; return (0xff & (int)data[TEMP_HIGH]);}
	public int GetTempLow(){if(TEMP_LOW==-1) return -1; return (0xff & (int)data[TEMP_LOW]);}
	public int GetChirpNode(){if(CHIRP_NODE_NUMBER==-1) return -1; return (0xff & (int)data[CHIRP_NODE_NUMBER]);}
	public int GetChirpSignalStrength()
	{
		if( (CHIRP_SIGNAL_STRENGTH_HIGH==-1) &&(CHIRP_SIGNAL_STRENGTH_LOW==-1)) 
			return -1; 
		else if(CHIRP_SIGNAL_STRENGTH_HIGH==-1) 
			return (0xff & (int)data[CHIRP_SIGNAL_STRENGTH_LOW]); 
		else if(CHIRP_SIGNAL_STRENGTH_LOW==-1) 
			return ((0xff) & (int)data[CHIRP_SIGNAL_STRENGTH_HIGH]) * 256;
		else
			return ((0xff) & (int)data[CHIRP_SIGNAL_STRENGTH_HIGH]) * 256 + (0xff & (int)data[CHIRP_SIGNAL_STRENGTH_LOW]);
	}	
	public int GetLastHopSignalStrength()
	{
		if( (LAST_HOP_SIGNAL_STRENGTH_HIGH==-1) &&(LAST_HOP_SIGNAL_STRENGTH_LOW==-1)) 
			return -1; 
		else if(LAST_HOP_SIGNAL_STRENGTH_HIGH==-1) 
			return (0xff & (int)data[LAST_HOP_SIGNAL_STRENGTH_LOW]); 
		else if(LAST_HOP_SIGNAL_STRENGTH_LOW==-1) 
			return ((0xff) & (int)data[LAST_HOP_SIGNAL_STRENGTH_HIGH]) * 256; 
		else
			return ((0xff) & (int)data[LAST_HOP_SIGNAL_STRENGTH_HIGH]) * 256 + (0xff & (int)data[LAST_HOP_SIGNAL_STRENGTH_LOW]); 
	}	
	public int GetLight()
	{
		if( (LIGHT_HIGH==-1) &&(LIGHT_LOW==-1)) 
			return -1; 
		else if(LIGHT_HIGH==-1) 
			return (0xff & (int)data[LIGHT_LOW]); 
		else//(LIGHT_LOW==-1) 
			return (0xff & (int)data[LIGHT_HIGH]) * 256; 
	}
	public int GetTemp()
	{
		if( (TEMP_HIGH==-1) &&(TEMP_LOW==-1)) 
			return -1; 
		else if(TEMP_HIGH==-1) 
			return (0xff & (int)data[TEMP_LOW]); 
		else//(TEMP_LOW==-1) 
			return (0xff & (int)data[TEMP_HIGH]) * 256; 
	}
	
	public int GetDestinationNode()    
	{ 
		Vector routePath = CreateRoutePathArray();
		return ((Integer)routePath.lastElement()).intValue(); 
	} 
	
	public int GetLastHop()    
	{ 
		Vector routePath = CreateRoutePathArray();
		return ((Integer)routePath.elementAt(routePath.size()-2)).intValue();
	} 

	          //*****---GET/SET Function---******//

}
	        