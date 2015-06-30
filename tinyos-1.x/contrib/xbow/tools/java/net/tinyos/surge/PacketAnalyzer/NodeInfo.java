// $Id: NodeInfo.java,v 1.14 2004/03/17 03:48:19 gtolle Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


/**
 * @author Wei Hong
 */

package net.tinyos.surge.PacketAnalyzer;

import net.tinyos.surge.*;
import net.tinyos.surge.event.*;
import net.tinyos.message.*;
import net.tinyos.surge.util.*;
import java.util.*;
import java.lang.*;
import java.text.*;
import javax.swing.*;
import net.tinyos.surge.Dialog.*;
import java.awt.*;
import net.tinyos.surge.messages.*;


    public class NodeInfo
    {
	// dchi
	protected ProprietaryNodeInfoPanel panel = null;
	public ProprietaryLinkInfoPanel link_panel = null;
	protected Integer nodeNumber;
	public int value;
	protected int centerY;
	protected int centerX;
	public String infoString;
	public long msgCount = 0;
	protected long lastTime;
	protected double msgYield = 0;
	protected double msgRate = 0;
	public double link_quality;
	protected long AVERAGE_INTERVAL = 180000;
	protected boolean isDirectChild = false;
	protected boolean active = false;
	protected long[] packetSkips;
	protected long[] packetTimes;
	public  double supplied_yield;
	protected double[] yieldHistory;
	protected byte[] depthHistory;
	protected int packetTimesPointer;
	protected int packetSkipsPointer;
	protected int hopcount;



	public DataSeries time_series = new DataSeries();
	public DataSeries yield_series = new DataSeries();
	public DataSeries batt_series = new DataSeries();
	public DataSeries temp_series = new DataSeries();
	public DataSeries light_series = new DataSeries();
	public DataSeries accelx_series = new DataSeries();
	public DataSeries accely_series = new DataSeries();
	public DataSeries magx_series = new DataSeries();
	public DataSeries magy_series = new DataSeries();


	public int stats_start_sequence_number;
	public int batt;
	public int seq_no;
	public int[] parent_count = new int[255];

        public int primary_parent;
        public int secondary_parent;

        public class NeighborInfo{
		public int id;
		public double link_quality;
		public int hopcount;
        }



	public NeighborInfo[] neighbors;

	public NodeInfo(Integer pNodeNumber) {
	    packetTimesPointer = 0;
	    packetSkipsPointer = 0;
	    neighbors = new NeighborInfo[5];
	    for(int i = 0; i < 5; i ++)neighbors[i] = new NeighborInfo();
	    packetTimes = new long[SensorAnalyzer.HISTORY_LENGTH];
	    packetSkips = new long[SensorAnalyzer.HISTORY_LENGTH];
	    yieldHistory = new double[SensorAnalyzer.YIELD_HISTORY_LENGTH];
	    depthHistory = new byte[SensorAnalyzer.YIELD_HISTORY_LENGTH];
	    lastTime = System.currentTimeMillis() - 500;
	    nodeNumber = pNodeNumber;
	    value = -1;//if it doesn't change from this value nothing will be written
	    infoString = "[none]";
	}

	public Integer GetNodeNumber() {
	    return nodeNumber;
	}

	public void SetPanel (ProprietaryNodeInfoPanel p) {
	    panel = p;
	}

	public void SetNodeNumber(Integer pNodeNumber) {
	    nodeNumber = pNodeNumber;
	}

	public int GetSensorValue() { return value; }
	public String GetInfoString() { return infoString; }

	// Decay current estimates if no msgs heard in last cycle

        int yieldHistoryPointer;
        int yieldHistoryCounter;
        int total_yield = 0;

	public void decay() {

	    long curtime = System.currentTimeMillis();
	    msgRate = calcMsgRate(curtime - lastTime);
	    msgYield = calcMsgYield(curtime - lastTime);
	    //also cycle the yield history.
		if(yieldHistoryCounter ++ > SensorAnalyzer.YIELD_INTERVAL ){
			yieldHistoryCounter = 0;
			depthHistory[yieldHistoryPointer] = (byte)hopcount;
			yieldHistory[yieldHistoryPointer++] = yield();
			
			yieldHistoryPointer %= yieldHistory.length;
			if(panel != null) panel.repaint();
			if(link_panel != null) link_panel.get_new_data();
		}
	    if (active) { active = false; return; }

	    if (curtime - lastTime >= AVERAGE_INTERVAL) {
		if(self_calc != false) infoString = msgCount+" msgs ";
		else infoString = "";
		if(panel != null) panel.YieldLabel.setText(String.valueOf(percent_yield()) + " %");
	    }
	    int best = 0;
	    int best_parent = 0;
	    for(int i = 0; i < parent_count.length; i ++){
		if(parent_count[i] > best) {
			best_parent = i;
			best = parent_count[i];
		}
	    }
	    primary_parent = best_parent;
	    best = 0;
	    for(int i = 0; i < parent_count.length; i ++){
		if(parent_count[i] > best && i != primary_parent) {
			best_parent = i;
			best = parent_count[i];
		}
	    }
	    secondary_parent = best_parent;


	}

	public boolean self_calc = true;	

        public double expected_yield(int count){
		if(count > 10) return 0.0;
		if(nodeNumber.intValue() == 0) return 1.0;
		Integer parent = MainClass.objectMaintainer.getParent(nodeNumber);
		if(parent == null) return 0.0;
		NodeInfo parentni = (NodeInfo)MainClass.sensorAnalyzer.proprietaryNodeInfo.get(parent);
		if(parentni == null) return 0.0;
		return link_quality * parentni.expected_yield(count + 1);	
	}
        public double percent_yield(){
		return yield() * 100.00;
        }
        public double yield(){
		if(self_calc == false) {
			return supplied_yield;
		}
		double yield = msgYield;
		if(yield > 1.0) yield = 1.0;
		return yield;
		
	}

        public double calcMsgYield(long lastInterval){
		int count = 0;
		long sum = lastInterval/AVERAGE_INTERVAL; 
		if(sum != 0) count = 1;
		for(int i = 0; i < SensorAnalyzer.HISTORY_LENGTH; i ++){	
			if(packetSkips[i] != 0){
				sum += packetSkips[i];
				count ++;
			}
		}
		double avg = ((double)sum)/((double)count);
		return ((double)1.0)/avg;

        }
        public double calcMsgRate(long lastTime){
		int count = 0;
		long sum = lastTime; 
		if(sum != 0) count = 1;
		for(int i = 0; i < SensorAnalyzer.HISTORY_LENGTH; i ++){	
			if(packetTimes[i] != 0){
				sum += packetTimes[i];
				count ++;
			}
		}
		double avg = ((double)sum)/((double)count);
		return ((double)1000.0)/avg;

        }

	public void updateDebug(MultihopMsg msg) {
	    	DebugPacket DMsg = new DebugPacket(msg.dataGet(),msg.offset_data(0));
		hopcount = (byte)DMsg.getElement_estList_hopcount(0)+1;
		int i = 0;
		for(i = 0; i < (int)DMsg.get_estEntries(); i ++){
			neighbors[i].id = 0;
			neighbors[i].id = (int)DMsg.getElement_estList_id(i);
			neighbors[i].link_quality = (int)DMsg.getElement_estList_sendEst(i);
			neighbors[i].hopcount = (int)DMsg.getElement_estList_hopcount(i);
		}
		for(; i < 5; i ++){
			neighbors[i].id = 0;
			neighbors[i].link_quality = 0;
			neighbors[i].hopcount = 0;
		}
		if(link_panel != null) link_panel.get_new_data();
	}


	int level_sum;
        public double averageLevel(){

		return ((double)level_sum)/(double)msgCount;

	}

	public void update(MultihopMsg msg) {
	    String info;
	    SurgeMsg SMsg = new SurgeMsg(msg.dataGet(),msg.offset_data(0));
	    if (SMsg.get_type() == 0) {

		if (SMsg.get_parentaddr() == MainFrame.BEACON_BASE_ADDRESS) {
		    isDirectChild = true;
		} else {
		    isDirectChild = false;
		}

		// Update message count and rate
		// Only update if this message is coming to the root from
		// a direct child
		int saddr = msg.get_sourceaddr();
		NodeInfo ni = (NodeInfo)SensorAnalyzer.proprietaryNodeInfo.get(new Integer(saddr));
		if (ni != null) {
		    if (ni.isDirectChild) {
			msgCount++; 
			int new_seq_no = (int)SMsg.get_seq_no() & 0x7fffff;
			if(stats_start_sequence_number == 0) stats_start_sequence_number = new_seq_no;
			if(seq_no == 0) seq_no = new_seq_no - 1;
			int diff = new_seq_no - seq_no;
			if(diff > 1000) diff = 1;
			active = true;
			long curtime = System.currentTimeMillis();
			packetTimes[packetTimesPointer ++] = curtime - lastTime;
			packetTimesPointer %= SensorAnalyzer.HISTORY_LENGTH;
			packetSkips[packetSkipsPointer ++] = diff;
			packetSkipsPointer %= SensorAnalyzer.HISTORY_LENGTH;
			msgRate = calcMsgRate(0);
			msgYield = calcMsgYield(0);
		
			SimpleDateFormat formatter = new SimpleDateFormat ("MM/dd/yyyy hh:mm:ss a");

			
			String log = "";
			log += nodeNumber + "#";
			log += msgCount + "#";
			log += formatter.format(new Date()) + "#";
			log += curtime + "#";
			log += (curtime - lastTime) + "#";
			log += SMsg.get_parentaddr() + "#";

			parent_count[SMsg.get_parentaddr()] ++;
			log += msgRate + "#";
			seq_no = new_seq_no;
			batt = (int)SMsg.get_seq_no() >> 23 & 0x1ff;
			
			log += seq_no + "#";
			log += hopcount + "#";

			level_sum += hopcount;
			log += SMsg.get_reading() + "#";
			log += batt + "#";
			for(int i = 0; i < 5;i ++){
				log += neighbors[i].id + "#";
				log += neighbors[i].hopcount + "#";
				log += neighbors[i].link_quality/255.0 + "#";
			}
			log += SMsg.get_temp() + "#";
			log += SMsg.get_light() + "#";
			log += SMsg.get_accelx() + "#";
			log += SMsg.get_accely() + "#";
			log += SMsg.get_magx() + "#";
			log += SMsg.get_magy() + "#";
			System.out.println(log);

			double batt_val = (double) batt;
			batt_val = 1.25 * 1023.0/batt_val;
			batt_val *= 256.0/4.0;
			//System.out.println(batt_val);
			//Store the sensor readings.
			yield_series.insertNewReading(total_yield++, new Integer((int)(yield() * 256.0)));  
			time_series.insertNewReading(seq_no, new Long(curtime));  
			batt_series.insertNewReading(seq_no, new Integer((int)batt_val));  
 			temp_series.insertNewReading(seq_no, new Integer(SMsg.get_temp()));
 			light_series.insertNewReading(seq_no, new Integer(SMsg.get_light()));
 			accelx_series.insertNewReading(seq_no, new Integer(SMsg.get_accelx()));
 			accely_series.insertNewReading(seq_no, new Integer(SMsg.get_accely()));
 			magx_series.insertNewReading(seq_no, new Integer(SMsg.get_magx()));
 			magy_series.insertNewReading(seq_no, new Integer(SMsg.get_magy()));


			link_quality = neighbors[0].link_quality / 255;

			//update the edge quality as well...
			MainClass.locationAnalyzer.setQualityForEdge(nodeNumber.intValue(), SMsg.get_parentaddr(), (int)(link_quality * 255.0));



		        lastTime = curtime;
		    }
		}

		if(self_calc != false) info = msgCount+" msgs ";
		else info = "";

		this.value = SMsg.get_reading();
		if (panel != null) {
		    panel.YieldLabel.setText(String.valueOf(percent_yield())  + " %");
		    panel.SensorLabel.setText(String.valueOf(value));
		    panel.ParentLabel.setText(String.valueOf(SMsg.get_parentaddr()));
		    panel.SequenceLabel.setText(String.valueOf(seq_no));
		    panel.CountLabel.setText(String.valueOf(msgCount));
		    panel.DepthLabel.setText(String.valueOf(hopcount));
		    panel.repaint();
		}

		this.infoString = info;


	    }

	}
      
    }                                         
