package net.tinyos.moteview.Packet;



import java.util.*;
import net.tinyos.moteview.util.*;


/**
 * SuperPacket holds all of the metadeta about a packet and is the packet class
 * which all other packet classes inherit from
 *
 * @author Kamin Whitehouse
 */
public class SuperPacket implements java.io.Serializable
{
        /** total number of bytes in the packet
         */
	public static int NUMBER_OF_BYTES = 36;
        /** number of packets we've received so far
         */
	public static int NUMBER_OF_PACKETS_SO_FAR = 0;
        /** packet and its data payload
         */
	protected byte[] data = null;
        /** the number of the current packet (eg: this packet was the ith packet)
         */
	protected int packetNumber = 0;


        /** destination id of the UART (default 0x7e)
         */
	protected static final byte    HANDLER_ID    = 0x7e;
        /** location of the destation id in the packet
         */
	protected static final byte    AM_HANDLER = 0;
        /** used for a hack in the constructor
         */
	protected static boolean HAVE_WARNED = false;
        /** standard error return value (default -1)
         */
	protected static final int     ERROR         = -1;

        /**
         * Unused constructor for inherited methods
         */
        public SuperPacket()
        {
        }

        /** Default Constructor
         * @param pData packet as a byte array
         */
        public SuperPacket(byte[] pData)
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
   /**
    * Make an array that consists solely of the moteID's
    * @return Vector of the form [Source] [Intermediate Hops...] [Dest]
    */
      public Vector CreateRoutePathArray()
   {
	return null;
   }

   /** Make an array that consists of two arrays, each containing mote numbers
    * the two arrays are the same lengths, and corresponding elements indicate
    * routing connectivity in the sense that the first transmits to the second
    * @return the vector consisting of the two arrays
    */
   public Vector CreateRoutingConnectivityArray()
   {
	return null;
   }


   /** Make an array that consists of two arrays, each containing mote numbers
    * the two arrays are the same lengths, and corresponding elements indicate
    * connectivity in the sense that the second can HEAR the first
    * @return a vector consisting of the source and destination vectors
    */
    public Vector CreateRFConnectivityArray()
   {
	return null;
   }

   /** Gets the route length
    * @return at least 1 and at most 5
    */
   public int GetRouteLength()
   {
	return 0;
   }

   /** this method returns the first array index of a byte with a particular value
    * @return byte array of the data
    */
   public byte[] GetData(){return data;	}

   /**
    * Given a value, find its index and return that position
    * @param value byte to find
    * @return integer position that the byte was found at
    */
   private int GetIndexFromValue(byte value)
   {
       for (int i=0; i<data.length; i++) {
           if (data[i]==value) return i;
       }
       return ERROR;
   }

        /** Get the field of data at a given index
         * @param index index of the packet data
         * @return data at that index
         */
	public int GetField(int index){if(index==-1) return -1; return (0xff & (int)data[index]);}

        /** Get the field of data at a given index where the index is specified by hi byte and lo byte
         * @param index_high the hi byte of the index
         * @param index_low the lo byte of the index
         * @return the data combined into an integer of both hi and lo fields
         */
	public int GetField(int index_high, int index_low)
	{
		if( (index_high==-1) &&(index_low==-1))
			return -1;
		else if(index_high==-1)
			return (0xff & (int)data[index_low]);
		else if(index_low==-1)
			return (int)((0xff) & data[index_high]) * 256;
		else
			return (int)((0xff) & data[index_high]) * 256 + (int)(0xff & data[index_low]);
	}

    /** Gets the source node (??)
     * @return an integer representing the source node
     */
    public int GetSourceNode(){return -1;}

    public static int calcrc(byte[] packet, int count)
    {
            int crc=0, index=0;
            int i;

            while (count > 0)
            {
                crc = crc ^ (int) packet[index] << 8;
                index++;
                i = 8;
                do
                {
                    if ((crc & 0x8000) == 0x8000)
                        crc = crc << 1 ^ 0x1021;
                    else
                        crc = crc << 1;
                } while(--i != 0);
                count --;
            }

	    //System.out.println ("SUPERPACKET:calccrc: crc= " + crc );
            return (crc);
        }
}

