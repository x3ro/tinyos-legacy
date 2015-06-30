// $Id: AgillaProperties.java,v 1.11 2006/11/15 00:22:34 chien-liang Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2004, Washington University in Saint Louis
 * By Chien-Liang Fok.
 *
 * Washington University states that Agilla is free software;
 * you can redistribute it and/or modify it under the terms of
 * the current version of the GNU Lesser General Public License
 * as published by the Free Software Foundation.
 *
 * Agilla is distributed in the hope that it will be useful, but
 * THERE ARE NO WARRANTIES, WHETHER ORAL OR WRITTEN, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
 * MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
 *
 * YOU UNDERSTAND THAT AGILLA IS PROVIDED "AS IS" FOR WHICH NO
 * WARRANTIES AS TO CAPABILITIES OR ACCURACY ARE MADE. THERE ARE NO
 * WARRANTIES AND NO REPRESENTATION THAT AGILLA IS FREE OF
 * INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHER
 * PROPRIETARY RIGHTS.  THERE ARE NO WARRANTIES THAT SOFTWARE IS
 * FREE FROM "BUGS", "VIRUSES", "TROJAN HORSES", "TRAP DOORS", "WORMS",
 * OR OTHER HARMFUL CODE.
 *
 * YOU ASSUME THE ENTIRE RISK AS TO THE PERFORMANCE OF SOFTWARE AND/OR
 * ASSOCIATED MATERIALS, AND TO THE PERFORMANCE AND VALIDITY OF
 * INFORMATION GENERATED USING SOFTWARE. By using Agilla you agree to
 * indemnify, defend, and hold harmless WU, its employees, officers and
 * agents from any and all claims, costs, or liabilities, including
 * attorneys fees and court costs at both the trial and appellate levels
 * for any loss, damage, or injury caused by your actions or actions of
 * your officers, servants, agents or third parties acting on behalf or
 * under authorization from you, as a result of using Agilla.
 *
 * See the GNU Lesser General Public License for more details, which can
 * be found here: http://www.gnu.org/copyleft/lesser.html
 */

package edu.wustl.mobilab.agilla;

import java.io.*;
import java.util.*;
import edu.wustl.mobilab.agilla.variables.*;

public class AgillaProperties extends Properties {
	static final long serialVersionUID = -4478107165233435498L;
	private static final AgillaProperties singleton = new AgillaProperties();
	
	private static final String DEFAULT_INIT_DIR = "C:\\tinyos\\cygwin\\opt\\tinyos-1.x\\contrib\\wustl\\apps\\AgillaAgents";
	private static final String DEFAULT_AGENT = "";
	private static final String DEFAULT_INIT_AGENT_ID = "0";
	private static final String DEFAULT_INIT_NODE_ID = "0";
	private static final String DEFAULT_RUN_TEST = "false";
	private static final String DEFAULT_NUM_COL = "20";
	private static final String DEFAULT_ENABLE_CLUSTERING = "false";
	private static final String DEFAULT_ENABLE_LOCATION_UPDATE_MSGS = "false";
	private static final String DEFAULT_NETWORK_NAME = "unk";	
	private static final String DEFAULT_NUM_NODES = "24"; // Used by the GUI FigurePanel 
	private static final String DEFAULT_BASESTATION_OFFSET_X = "0"; // used to enable global co-ordinates across sensor networks
	private static final String DEFAULT_BASESTATION_OFFSET_Y = "0"; // used to enable global co-ordinates across sensor networks
	
	private static String initDir, defaultAgent, nwName;
	private static int numCol, numNodes, basestationOffsetX, basestationOffsetY, initAgentID, initNodeID;
	private static boolean runTest, enableClustering, enableLocationUpdateMsgs;
	
	private AgillaProperties() {
		super();
		initDir = DEFAULT_INIT_DIR;
		defaultAgent = DEFAULT_AGENT;
		runTest = Boolean.valueOf(DEFAULT_RUN_TEST).booleanValue();
		numCol = Integer.valueOf(DEFAULT_NUM_COL).intValue();
		initAgentID = Integer.valueOf(DEFAULT_INIT_AGENT_ID).intValue();
		initNodeID = Integer.valueOf(DEFAULT_INIT_NODE_ID).intValue();
		numNodes = Integer.valueOf(DEFAULT_NUM_NODES).intValue();
		enableClustering = Boolean.valueOf(DEFAULT_ENABLE_CLUSTERING).booleanValue();
		enableLocationUpdateMsgs = Boolean.valueOf(DEFAULT_ENABLE_LOCATION_UPDATE_MSGS).booleanValue();
		setNetworkName(DEFAULT_NETWORK_NAME);
		basestationOffsetX = Integer.valueOf(DEFAULT_BASESTATION_OFFSET_X).intValue();
		basestationOffsetY = Integer.valueOf(DEFAULT_BASESTATION_OFFSET_Y).intValue();
		try {
			load(new FileInputStream("agilla.properties"));
		}
		catch(IOException e) { 
			System.err.println("No agilla.properties file found.  "
					+ "Consider creating an agilla.properties file. "
					+ "See http://mobilab.wustl.edu/projects/agilla/docs/tutorials/2_inject.html#aiproperties for "
					+ "details");
			return;
		}
		try {
			initDir = getProperty("initDir", DEFAULT_INIT_DIR);
			defaultAgent = getProperty("defaultAgent", DEFAULT_AGENT);
			runTest = Boolean.valueOf(getProperty("runTest", DEFAULT_RUN_TEST)).booleanValue();
			numCol = Integer.valueOf(getProperty("numCol", DEFAULT_NUM_COL)).intValue();
			initAgentID = Integer.valueOf(getProperty("initAgentID", DEFAULT_INIT_AGENT_ID)).intValue();
			initNodeID = Integer.valueOf(getProperty("initNodeID", DEFAULT_INIT_AGENT_ID)).intValue();
			numNodes = Integer.valueOf(getProperty("numNodes", DEFAULT_NUM_NODES)).intValue();
			enableClustering = Boolean.valueOf(getProperty("enableClustering", DEFAULT_ENABLE_CLUSTERING)).booleanValue();
			enableLocationUpdateMsgs = Boolean.valueOf(getProperty("enableLocationUpdateMsgs", DEFAULT_ENABLE_LOCATION_UPDATE_MSGS)).booleanValue();
			nwName = getProperty("nwName", DEFAULT_NETWORK_NAME);
			basestationOffsetX = Integer.valueOf(getProperty("basestationOffsetX", DEFAULT_BASESTATION_OFFSET_X)).intValue();
			basestationOffsetY = Integer.valueOf(getProperty("basestationOffsetY", DEFAULT_BASESTATION_OFFSET_Y)).intValue();
		} catch(Exception e) {
			e.printStackTrace();
		}
	}
	
	public static int numCol() {
		return numCol;
	}
	
	public static int numNodes() {
		return numNodes;
	}
	
	public static int basestationOffsetX(){
		return basestationOffsetX;
	}
	
	public static int basestationOffsetY(){
		return basestationOffsetY;
	}
	
	public boolean runTest() {
		return runTest;
	}
	
	public static boolean enableClustering() {
		return enableClustering;
	}
	
	public static boolean enableLocationUpdateMsgs() {
		return enableLocationUpdateMsgs;
	}
	
	/**
	 * Sets the network name.
	 * 
	 * @param name The name of the network.
	 */
	public static void setNetworkName(String name) {
		//System.out.println("Setting network name to be " + name);
		nwName = name;
	}
	
	/**
	 * Returns the name of the network as a java String.
	 * 
	 * @return The name of the network.
	 */
	public static String networkName(){
		return nwName;
	}
	
	/**
	 * Returns the name of the network as an AgillaString.
	 * 
	 * @return The name of the network.
	 */
	public static AgillaString getNetworkName() {
		return new AgillaString(nwName);
	}
	
	public String getInitDir() {
		return initDir;
	}
	
	public static int getInitAgentID() {
		return initAgentID;
	}
	
	public static int getInitNodeID() {
		return initNodeID;
	}
	
	public String getDefaultAgent() {
		return defaultAgent;
	}
	
	static AgillaProperties getProperties() {
		return singleton;
	}	
	
	public static final int getRadioChannel() {
		if (nwName.equals("aaa"))
			return 18;
		else if (nwName.equals("bbb"))
			return 20;
		else if (nwName.equals("ccc"))
			return 22;
		else
			return 0xffff;
	}
}
