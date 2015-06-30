package net.tinyos.moteview.Packet;

import Surge.Packet.*;
import java.util.*;
import Surge.util.*;

/**
 * AbstractPacket contains all of the necessary abstractions to create and read data from a
 * packet.  With this class, the location of certain bytes of the packet need not be known,
 * rather they can be reference by name.
 *
 * @author Joe Polastre <a href="mailto:polastre@cs.berkeley.edu">polastre@cs.berkeley.edu</a>
 */
public class AbstractPacket extends Surge.Packet.SuperPacket
{
        private byte[] packet;

        //the following static variables define which byte contains the following data
        /** Location of the hi byte of the destination address
         */
	protected static int AM_DEST_HI = 1;
        /** Location of the lo byte of the destination address
         */
        protected static int AM_DEST_LO = 0;
        /** Location of the AM Handler id in the packet
         */
	protected static int AM_HANDLER = 2;
        /** Location of the mote group id in the packet
         */
	protected static int GROUP_ID = 3;
        /** Location of the hi byte of the crc in the packet
         */
        protected static int CRC_HI = 35;
        /** Location of the lo byte of the crc in the packet
         */
        protected static int CRC_LO = 34;

	          //*****---CONSTRUCTOR---******//

        /**
         * Default constructor.  Creates a new packet that can be modified.
         */
        public AbstractPacket()
        {
                packet = new byte[SuperPacket.NUMBER_OF_BYTES];
                for (int i = 0; i < SuperPacket.NUMBER_OF_BYTES; i++)
                    packet[i] = 0;
        }

        /**
         * Takes an existing data packet and turns it into an AbstractPacket
         * @param pData packet to create an AbstractPacket for
         */
	public AbstractPacket(byte pData[])
	{
		packet = pData;
	}
	          //*****---CONSTRUCTOR---******//

        /**
         * Returns the destination of the packet
         * @return a short representing the destination address
         */
        public short getDest()
        {
            Integer temp = new Integer(packet[AM_DEST_HI] << 8 + packet[AM_DEST_LO]);
            short value = temp.shortValue();
            return value;
        }

        /**
         * Sets the destination of the packet
         * @param dest the destination of this packet
         */
        public synchronized void setDest(short dest)
        {
            packet[AM_DEST_HI] = (byte)(dest >> 8);
            packet[AM_DEST_LO] = (byte)(dest & 0xFF);
        }

        /**
         * Gets the data portion of the packet as a byte array
         * @return the data of the packet
         */
        public byte[] getData()
        {
            byte[] temp = new byte[SuperPacket.NUMBER_OF_BYTES - 6];
            for (int i = 4; i < SuperPacket.NUMBER_OF_BYTES - 6; i++)
                temp[i] = packet[i];
            return temp;
        }

        /**
         * Sets the data portion of the packet
         * @param newdata data to be inserted into the packet
         */
        public synchronized void setData(byte[] newdata)
        {
            for (int i = 0; i < SuperPacket.NUMBER_OF_BYTES - 6; i++)
                packet[i+4] = newdata[i];
        }

        /** Gets the handler ID of the current packet
         * @return char value of the handler ID
         */
        public char getHandler()
        {
            //char x = (new Byte(packet[AM_HANDLER])).byteValue();
            return (char)packet[AM_HANDLER];
        }

        /** Sets the handler ID of the current packet
         * @param handler new handler id
         */
        public void setHandler(char handler)
        {
            packet[AM_HANDLER] = (byte)handler;
        }

        /** Gets the group id of the current packet
         * @return the char value of the mote group id
         */
        public char getGroup()
        {
            return (char)packet[GROUP_ID];
        }

        /** Sets the group id of the current packet
         * @param group the new group id of the packet
         */
        public void setGroup(char group)
        {
            packet[GROUP_ID] = (byte)group;
        }

        /**
         * Gets the entire bytestring of the current packet.
         * Useful for creating a packet and then sending it out through the UART
         * @return a byte array in the correct packet format
         */
        public byte[] getPacket()
        {
            int crc = (short)SuperPacket.calcrc(packet, SuperPacket.NUMBER_OF_BYTES-2);
            packet[SuperPacket.NUMBER_OF_BYTES-2] = (byte) (crc & 0xff);
            packet[SuperPacket.NUMBER_OF_BYTES-1] = (byte) ((crc >> 8) & 0xff);
            return packet;
        }


}
