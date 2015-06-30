/*
 * Copyright (c) 2003, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 * Date last modified: 12/11/03
 */

package net.tinyos.tools;

import java.util.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import Jama.*;

class TestTimeStamping
{
	public static void main(String[] args) throws Exception
	{
		TestTimeStamping engine = new TestTimeStamping();
		int entryLimit = 100; 

		String sourceName = "serial@COM1:57600";
		
		try
		{
			for(int i = 0; i < args.length; ++i)
			{
				if( args[i].equals("-source") )
					sourceName = args[++i];
				else if( args[i].equals("-entries") )
					entryLimit = Integer.parseInt(args[++i]);
				else if( args[i].equals("-calibrate") )
					engine.calibrate = true;
				else if( args[i].equals("-hist") )
					engine.binWidth = Double.parseDouble(args[++i]);
				else if( args[i].equals("-help") )
				{
					System.out.print(
						"Arguments:\n" +
						"  [-source <conn>]    The packet source, defaults to (MOTECOM)\n" +
						"                          sf@localhost=9001\n" + 
						"                          serial@COM1:57600\n" +
						"  [-entries <num>]    Collect this many entries (100)\n" +
						"  [-calibrate]        Perform calibration (false)\n" +
						"  [-hist <microsec>]  Print histogram with the specified bin width\n" +  
						"  [-help]             Prints out this message\n"
					);
					return;
				}
				else
				{
					System.err.println("Invalid argument: " + args[i]);
					return;
				}
			}
		}
		catch(Exception e)
		{
			System.err.println("Missing or invalid parameter");
			return;
		}

		try
		{
			PacketSource source = BuildSource.makePacketSource(sourceName);
			source.open(PrintStreamMessenger.err);
		
			while( engine.entries.size() < entryLimit )
				engine.decode(source.readPacket());

			System.out.println();
		
			engine.solve();
			engine.report();
			System.exit(0);
		}
		catch(Exception e)
		{
			System.err.println(e.getMessage());
			System.exit(-1);
		}
	}
	
	public static final int PACKET_TYPE_FIELD = 2;
	public static final int PACKET_LENGTH_FIELD = 4;
	public static final int PACKET_DATA_FIELD = 5;
	public static final byte DIAGMSG_ACTIVE_MESSAGE = (byte)0xB1;

	static final int TS_LENGTH = 19;
	static final int TS_STRING = PACKET_DATA_FIELD + 2;
	static final int TS_SENDER = PACKET_DATA_FIELD + 4;
	static final int TS_SENDINGTIME = PACKET_DATA_FIELD + 7;
	static final int TS_RECEIVER = PACKET_DATA_FIELD + 11;
	static final int TS_RECEIVINGTIME = PACKET_DATA_FIELD + 14;
	static final int TS_OFFSET = PACKET_DATA_FIELD + 18;
	
	/**
	 * Holds statistical values for each data points.
	 */
	static class Entry
	{
		/**
		 * The node ID of the sender of the message
		 */
		public int sender;
		
		/**
		 * The local time of the sender at the time of transmission
		 */
		public long sendingTime;
		
		/**
		 * The node ID of the receiver
		 */
		public int receiver;
		
		/**
		 * The local time of the receiver at the time of reception
		 */
		public long receivingTime;
		
		/**
		 * The bit offset of the received data stream. This is zero
		 * if we are not calibrating.
		 */
		public int offset;
		
		/**
		 * The error between the receivedTime and the predicted receive
		 * time. This prediction is based on the clock skews and offsets
		 * of the participating motes and the local time of the sender.
		 * For calibration prediction is also compensated with a bitoffset
		 * dependend value.
		 */
		public double error;

		public String toString()
		{
			return "entry: sender=" + sender + " sendingTime=" + sendingTime 
				+ " receiver=" + receiver +  " receivingTime=" + receivingTime 
				+ " offset=" + offset + " error=" + error;
		}
		
		// we disregard the time stamp
		public int hashCode()
		{
			return sender + (int)sendingTime + receiver + (int)receivingTime + offset;
		}
		
		public boolean equals(Object o)
		{
			if( !(o instanceof Entry) )
				return false;

			Entry e = (Entry)o;
			return sender == e.sender && sendingTime == e.sendingTime
				&& receiver == e.receiver && receivingTime == e.receivingTime
				&& offset == e.offset;
		}
	}

	/**
	 * Holds statistical values for all participating nodes.
	 */
	static class Node
	{
		/**
		 * The node ID of the mote
		 */
		public int id;
		
		/**
		 * The clock skew (normalized, that is, 1 is subtracted) of this node
		 * with respect to the first node.
		 */
		public double skew;
		
		/**
		 * The clock offset of this node with respect to the first node.
		 */
		public double offset;

		public long lastTime = Long.MIN_VALUE;
		public long firstTime;
		public long firstPCTime;
		public long lastPCTime;
		
		public double receiveBias;
		public double sendBias;

		public Node(int id)
		{
			this.id = id;
		}
	
		/**
		 * This method transforms a 32-bit time to 64-bit to avoid probems
		 * when the 32-bit time overlaps. This also updates time information
		 * that is used to compute the clock frequency of the node.
		 */
		public long getTime(int time)
		{
			if( lastTime == Long.MIN_VALUE )
			{
				firstTime = lastTime = time;
				lastPCTime = firstPCTime = System.currentTimeMillis();
				return lastTime;
			}
			
			int offset = time - (int)lastTime;
			if( offset > 0 )
			{
				lastTime += offset;
				lastPCTime = System.currentTimeMillis();
				return lastTime;
			}
			
			return lastTime + (long)offset;
		}

		/**
		 * Returns the approximate clock frequency of this node.
		 */
		public double getFreq()
		{
			return (1000.0*(lastTime-firstTime))/(lastPCTime-firstPCTime);
		}
		
		public String toString()
		{
			return "node " + id
				+ ":\n\tskew=" + skew 
				+ "\n\toffset=" + offset
				+ "\n\tapproxFreq=" + getFreq()
				+ "\n\tsendBias=" + sendBias
				+ "\n\treceiveBias=" + receiveBias;
		}
	}
	
	/**
	 * Holds statistical values for different receive side bit offsets.
	 */
	static class BitOffset
	{
		/** 
		 * The ID of the bitOffset between 0 and 7
		 * */
		int offset;

		/**
		 * The difference in clock ticks between the send time
		 * and the receive time with this bit offset. This number
		 * if usually negative because the hardware and software
		 * buffering makes the same byte arrive later than it was sent.
		 */		
		double delta;
		
		/**
		 * The delta is calculated as a liner function of the offset.
		 * There is however some error between this linear approximation
		 * and the best fit, and the difference is stored here. The radio
		 * chip can delay the transmission of specific bits by a little
		 * bit and that could result in some bias.
		 */
		double bias;
		
		/**
		 * The number of times this bit offset occured.
		 */
		int occurences;		// the number of times this offset is received
		
		/**
		 * The bit delta that should be used in the compensation of
		 * racaive and send time delay. This could be simply delta,
		 * or the sum of the delta and the bias. It might be a multiple
		 * of the delta if the time stamping algorithm works with the sum
		 * of multiple time stamps, make the correction with this and
		 * only after it divides of the number of time stamps.
		 */
		double finalDelta;

		public BitOffset(int offset)
		{
			this.offset = offset;
			occurences = 1;
		}
		
		public String toString()
		{
			return "bitOffset " + offset
				+ ":\n\tdelta=" + delta
				+ "\n\tbias=" + bias
				+ "\n\toccurences=" + occurences
				+ "\n\tBIT_CORRECTION=" + finalDelta;
		}
	}
	
	/**
	 * True if we calibrate the TimeStamping component.
	 */
	boolean calibrate = false;
	
	/**
	 * The bin width when displaying the histogram of errors.
	 */
	double binWidth = 0.0;
	
	TreeMap nodes = new TreeMap();
	TreeMap bitOffsets = new TreeMap(); 	
	HashSet entries = new HashSet(); 

	Node getNode(int id)
	{
		Node node = (Node)nodes.get(new Integer(id));
		if( node == null )
		{
			node = new Node(id);
			nodes.put(new Integer(id), node);
			System.out.println("new node: " + id);
		}
		return node;
	}

	void addBitOffset(int offset)
	{
		BitOffset bitOffset = (BitOffset)bitOffsets.get(new Integer(offset)); 
		if( bitOffset == null )
		{
			bitOffsets.put(new Integer(offset), new BitOffset(offset));
			if( calibrate )
				System.out.println("new bitoffset: " + offset);
		}
		else
			++bitOffset.occurences;
	}

	void addEntry(Entry entry)
	{
		int s = entries.size() + 1;
		entries.add(entry);

		if( s == entries.size() )
		{
			entryList.add(entry);
			if( (s % 100) == 0 )
				System.out.println("entry count: " + s);
		}
	}

	/**
	 * This method collects data into the nodes, bitOffsets and entries
	 * collections. This information is then ordered and processed in
	 * the solve method.
	 */
	void decode(byte[] packet)
	{
		if( packet[PACKET_TYPE_FIELD] != DIAGMSG_ACTIVE_MESSAGE 
			|| packet[PACKET_LENGTH_FIELD] != TS_LENGTH 
			|| packet[TS_STRING] != 'T' || packet[TS_STRING+1] != 'S' )
			return;

		Entry entry = new Entry();

		entry.sender = (packet[TS_SENDER] & 0xFF) + ((packet[TS_SENDER+1] & 0xFF) << 8);
		int sendingTime = (packet[TS_SENDINGTIME] & 0xFF) + ((packet[TS_SENDINGTIME+1] & 0xFF) << 8)
			+ ((packet[TS_SENDINGTIME+2] & 0xFF) << 16) + ((packet[TS_SENDINGTIME+3] & 0xFF) << 24);
		entry.receiver = (packet[TS_RECEIVER] & 0xFF) + ((packet[TS_RECEIVER+1] & 0xFF) << 8);
		int receivingTime = (packet[TS_RECEIVINGTIME] & 0xFF) + ((packet[TS_RECEIVINGTIME+1] & 0xFF) << 8)
			+ ((packet[TS_RECEIVINGTIME+2] & 0xFF) << 16) + ((packet[TS_RECEIVINGTIME+3] & 0xFF) << 24);
		entry.offset = packet[TS_OFFSET] & 0xFF;

		Node node = getNode(entry.sender);
		entry.sendingTime = node.getTime(sendingTime);

		node = getNode(entry.receiver);
		entry.receivingTime = node.getTime(receivingTime);

		addEntry(entry);
		addBitOffset(entry.offset);
	}

	ArrayList nodeList;
	ArrayList bitOffsetList;
	ArrayList entryList = new ArrayList();
	
	/**
	 * The average error in clock ticks of all data points.
	 */
	double avgError;
	
	/**
	 * The maximum error in clock ticks of all data points.
	 */
	double maxError;

	/**
	 * The receive delay in clock ticks between the sending
	 * and receiving of the same data byte provided that 
	 * the bit offset is zero. This should be a negative number.
	 */
	double receiveOffset;
	
	/**
	 * The additional receive delay in clock ticks because of 
	 * the bit offset. This is the unit, so each bit counts 
	 * as this much delay.
	 */
	double bitOffsetUnit;
	
	/**
	 * The frequency of the first node.
	 */
	double freq;

	int indexOfNode(int id)
	{
		for(int i = 0;; ++i)
			if( ((Node)nodeList.get(i)).id == id )
				return i;
	}

	int indexOfBitOffset(int offset)
	{
		for(int i = 0;; ++i)
			if( ((BitOffset)bitOffsetList.get(i)).offset == offset )
				return i;
	}

	final static int CALIB_NONE = 0;
	final static int CALIB_SINGLE = 1;
	final static int CALIB_MULTI = 2;

	/**
	 * Solves a bunch of linear equations to figure out
	 * the clock skews and offsets of the participating motes.
	 * Based on this it calculates various statistics.
	 * In calibration mode this method also calculates the
	 * the receiveOffset and bitOffsetUnit.
	 */
	void solve()
	{
		nodeList = new ArrayList(nodes.values());
		bitOffsetList = new ArrayList(bitOffsets.values());
		
		int nodeVars = 2*(nodes.size()-1);
		int calibType = calibrate ? (bitOffsets.size() > 1 ?  
			CALIB_MULTI : CALIB_SINGLE) : CALIB_NONE; 
		
		Matrix A = new Matrix(entries.size(),nodeVars + calibType);
		Matrix B = new Matrix(entries.size(),1);

	/*
	 * sendingTime*(1+skew_sender) + offset_sender 
	 * 	= receivingTime*(1+skew_receiver) + offset_receiver + receiveOffset + bitOffset_offset
	 * 
	 * sendingTime*skew_sender + offset_sender 
	 *	- receivingTime*skew_receiver - offset_receiver - receiveOffset - bitOffset*bitOffsetUnit
	 *  = - sendingTime + receivingTime  
	 */
		
		Iterator iter = entryList.iterator();
		for(int i = 0; iter.hasNext(); ++i)
		{
			Entry entry = (Entry)iter.next();

			int n = indexOfNode(entry.sender);
			if( n > 0 )
			{
				A.set(i, 2*(n-1), entry.sendingTime);
				A.set(i, 2*(n-1)+1, 1.0);
			}
			B.set(i, 0, -entry.sendingTime);
			
			n = indexOfNode(entry.receiver);
			if( n > 0 )
			{
				A.set(i, 2*(n-1), -entry.receivingTime);
				A.set(i, 2*(n-1)+1, -1.0);
			}
			B.set(i, 0, B.get(i,0)+entry.receivingTime);

			if( calibType == CALIB_SINGLE )
			{
				A.set(i, nodeVars, -1.0);
			}
			else if( calibType == CALIB_MULTI )
			{
				A.set(i, nodeVars, -1.0);
				A.set(i, nodeVars+1, -indexOfBitOffset(entry.offset));
			}
		}

		Matrix X = A.solve(B);
		Matrix E = A.times(X).minus(B);

		Node n = (Node)nodeList.get(0);
		n.skew = 0.0;
		n.offset = 0.0;
		for(int i = 1; i < nodeList.size(); ++i)
		{
			n = (Node)nodeList.get(i);
			n.skew = X.get(2*(i-1),0);
			n.offset = X.get(2*(i-1)+1,0);
		}

		if( calibType == CALIB_SINGLE )
		{
			receiveOffset = X.get(nodeVars,0);
			bitOffsetUnit = 0.0;
		}
		else if( calibType == CALIB_MULTI )
		{
			receiveOffset = X.get(nodeVars,0);
			bitOffsetUnit = X.get(nodeVars+1,0);
		}

		for(int i = 0; i < bitOffsetList.size(); ++i)
		{
			BitOffset b = (BitOffset)bitOffsetList.get(i);
			b.delta = receiveOffset + i * bitOffsetUnit;
		}

		maxError = 0.0;
		avgError = 0.0;
		for(int i = 0; i < entryList.size(); ++i)
		{
			double e = E.get(i,0);
			((Entry)entryList.get(i)).error = e;
			
			if( e < 0.0 )
				e = -e;
			
			avgError += e;
			if( maxError < e )
				maxError = e;
		}
		avgError /= entries.size();
		
		for(int i = 0; i < nodeList.size(); ++i)
		{
			Node node = (Node)nodeList.get(i);
			node.receiveBias = 0.0;
			node.sendBias = 0.0;
			int receiveCount = 0, sendCount = 0;
			
			for(int j = 0; j < entryList.size(); ++j)
			{
				Entry entry = (Entry)entryList.get(j);

				if( entry.sender == node.id )
				{
					node.sendBias += entry.error;
					++sendCount;
				}
				if( entry.receiver == node.id )
				{
					node.receiveBias += entry.error;
					++receiveCount;
				}
			}
			
			if( sendCount > 0 )
				node.sendBias /= sendCount;
				
			if( receiveCount > 0 )
				node.receiveBias /= receiveCount;
		}

		for(int i = 0; i < bitOffsetList.size(); ++i)
		{
			BitOffset bitOffset = (BitOffset)bitOffsetList.get(i);
			bitOffset.bias = 0.0;
			int count = 0;
			
			for(int j = 0; j < entryList.size(); ++j)
			{
				Entry entry = (Entry)entryList.get(j);

				if( entry.offset == bitOffset.offset )
				{
					bitOffset.bias += entry.error;
					++count;
				}
			}
			
			if( count > 0 )
				bitOffset.bias /= count;
				
			bitOffset.finalDelta = -2.0 * (bitOffset.delta + bitOffset.bias);			
		}
		
		freq = ((Node)nodeList.get(0)).getFreq();
	}

	/**
	 * Prints a histogram of the errors of all data points.
	 */
	void printHistogram()
	{
		double binSize = binWidth / 1000000.0 * freq;
		int half = (int)(Math.ceil(maxError/binSize));
		int[] bins = new int[2*half+1];
		double max = binSize * (half + 0.5);
		
		for(int i = 0; i < entryList.size(); ++i)
		{
			Entry entry = (Entry)entryList.get(i);
			++bins[(int)((entry.error + max) / binSize)];
		}
		
		for(int i = 0; i < bins.length; ++i)
		{
			System.out.println("histogram bin [" + (i-half-0.5)*binWidth 
				+ "," + (i-half+0.5)*binWidth 
				+ "]\t= " + bins[i] * 100.0 / entryList.size() + "%");
		}
	}

	void report()
	{
		if( calibrate )
		{
			for(int i = 0; i < nodeList.size(); ++i)
				System.out.println(nodeList.get(i));

			for(int i = 0; i < bitOffsetList.size(); ++i)
				System.out.println(bitOffsetList.get(i));

			System.out.println("receiveOffset=" + receiveOffset 
				+ "\nbitOffsetUnit=" + bitOffsetUnit
				+ "\nBYTE_TIME=" + -8.0 * bitOffsetUnit);
			System.out.println();
		}

		System.out.println("approximate clock frequency = " + freq + " Hz");
		System.out.println("maximum error = " + maxError +" (" + maxError / freq * 1000000.0 + " microsec)");
		System.out.println("average error = " + avgError +" (" + avgError / freq * 1000000.0 + " microsec)");

		if( binWidth != 0.0 )
			printHistogram();
	}
}
