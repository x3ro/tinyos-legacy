// $Id: TASKClient.java,v 1.2 2003/10/07 21:46:05 idgay Exp $

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
package net.tinyos.task.taskapi;

import java.sql.Timestamp;
import java.util.*;
import java.io.*;
import java.net.*;
import net.tinyos.task.tasksvr.*;

/**
 * The TASKClient class is the main class to provide APIs 
 * for clients to access the TASKServer.
 * @author whong@intel-research.net
 */
public class TASKClient
{
	/**
	 * The TASKServer constructor establishes a connection to the
	 * TASKServer, pre-fetches all the attribute and command information
	 * (since they don't change), and create a new thread waiting for
	 * results from the TASKServer and calling client callbacks.
	 *
	 * @param	serverIP	IP address of TASKServer.
	 * @param	serverPort	port number of TASKServer.
	 * @throws	IOException
	 */
	public TASKClient(String serverIP, int serverPort) throws IOException
	{
		this.serverIP = serverIP;
		this.serverPort = serverPort;
		sensorListenerHandler = new ListenerHandler();
		healthListenerHandler = new ListenerHandler();
		if (prefetchMetaData() != TASKError.SUCCESS)
		{
			throw new IOException("connection to TASKServer failed.");
		}
	};

	private int prefetchMetaData()
	{
		Socket conn = null;
		ObjectOutputStream outStream = null;
		ObjectInputStream inStream = null;
		int error = TASKError.SOCKET_IO_EXCEPTION;

		try
		{
			conn = getConnection();
			System.out.println("got connection");
			outStream = new ObjectOutputStream(conn.getOutputStream());
			System.out.println("got output stream");
			inStream = new ObjectInputStream(conn.getInputStream());
			System.out.println("got input stream");

			System.out.println("sending PREFETCH_METADATA command");
			outStream.writeShort(TASKServer.PREFETCH_METADATA);
			outStream.flush();
			System.out.println("PREFETCH_METADATA command sent");
			attributeInfos = (Vector)inStream.readObject();
			System.out.println("attributeinfos read done.");
			commandInfos = (Vector)inStream.readObject();
			System.out.println("commandinfos read done.");
			aggregateInfos = (Vector)inStream.readObject();
			System.out.println("aggregateinfos read done.");
			error = inStream.readInt();
			outStream.close();
			inStream.close();
			conn.close();
			System.out.println("prefetching of metadata was successful.");
		}
		catch (Exception e)
		{
			try
			{
				if (conn != null)
					conn.close();
				if (outStream != null)
					outStream.close();
				if (inStream != null)
					inStream.close();
			}
			catch (Exception ex)
			{
			}
		}
		return error;
	}

	/**
	 * The TASKServer constructor with default port number
	 *
	 * @param	serverIP	IP address of TASKServer.
	 * @throws	IOException
	 */
	public TASKClient(String serverIP) throws IOException
	{
		this(serverIP, TASKServer.DEFAULT_SERVER_PORT);
	};

	private TASKQuery getQuery(short whichQuery)
	{
		TASKQuery query = null;
		Socket conn = null;
		ObjectOutputStream outStream = null;
		ObjectInputStream inStream = null;
		try
		{
			conn = getConnection();
			outStream = new ObjectOutputStream(conn.getOutputStream());
			inStream = new ObjectInputStream(conn.getInputStream());

			outStream.writeShort(TASKServer.GET_QUERY);
			outStream.writeShort(whichQuery);
			outStream.flush();
			query = (TASKQuery)inStream.readObject();
			outStream.close();
			inStream.close();
			conn.close();
		}
		catch (Exception e)
		{
			try
			{
				if (conn != null)
					conn.close();
				if (outStream != null)
					outStream.close();
				if (inStream != null)
					inStream.close();
			}
			catch (Exception ex)
			{
			}
			e.printStackTrace();
		}
		return query;
	}

	/**
	 * Returns the current sensor query, null if no query has been submitted.
	 * Note that other TASK clients can modify this query.  Therefore,
	 * this query may not reflect the latest in the sensor network.
	 */
	public TASKQuery getSensorQuery() 
	{
		return getQuery(TASKServer.SENSOR_QUERY);
	};
	/**
	 * Returns the current network health monitoring query,
	 * null if no query has been submitted.
	 * Note that other TASK clients can modify this query.  Therefore,
	 * this query may not reflect the latest in the sensor network.
	 */
	public TASKQuery getHealthQuery() 
	{
		return getQuery(TASKServer.HEALTH_QUERY);
	};

    static final int SENSOR_COST_UJ = 90;

	/**
	 * Estimate a network life time (in seconds) 
	 * given a sensor query and a health monitoring query
	 * (using tehir associated sample periods (in milliseconds)
	 *
	 * @param	sensorQuery	a sensor query.
	 * @param	healthQuery	a health monitoring query.
	 * @return	estimated network life time in seconds.
	 */
	public long estimateLifeTime(TASKQuery sensorQuery, TASKQuery healthQuery)
	{
	    return EstimateLifetime.samplePeriodToLifetime((long)sensorQuery.getSamplePeriod(),
			  (long)EstimateLifetime.maxVReading, // XXX assumes fully charged batteries
			  SENSOR_COST_UJ,
			  sensorQuery.getSelectEntries().size(),
			  1 /* XXX Assume just one message per epoch ! */ );
	}
	/**
	 * Given an expected network life time (in seconds), set the
	 * appropriate sample period (in milliseconds) in the sensor
	 * query and the health monitoring query.
	 *
	 * @param	lifeTime	expected network life time in seconds.
	 * @param	sensorQuery	sensor query.  Its samplePeriod will be set.
	 * @param healthQuery health monitoring query. Its samplePeriod will be set.  */
	public void estimateSamplePeriods(long lifeTime, TASKQuery sensorQuery, TASKQuery healthQuery)
	{
	    long samplePeriod = EstimateLifetime.lifetimeToSamplePeriod(lifeTime,
					(long)EstimateLifetime.maxVReading, // XXX assumes fully charged batteries
					SENSOR_COST_UJ,
					sensorQuery.getSelectEntries().size(),
					1 /* XXX Assume just one message per epoch ! */ );
	    sensorQuery.setSamplePeriod((int)samplePeriod);
	    healthQuery.setSamplePeriod((int)samplePeriod);
	}

	/**
	 * Returns the name of all the clientinfo's registered with the
	 * TASKServer.  Clientinfo's are opaque client states (e.g., layout of 
	 * sensor space) stored at the server.
	 */
	public String[] getClientInfos() 
	{
		Socket conn = null;
		ObjectOutputStream outStream = null;
		ObjectInputStream inStream = null;
		Vector clientInfos = null;
		String[] clientInfoNames;
		try
		{
			conn = getConnection();
			outStream = new ObjectOutputStream(conn.getOutputStream());
			inStream = new ObjectInputStream(conn.getInputStream());

			outStream.writeShort(TASKServer.GET_CLIENTINFOS);
			outStream.flush();
			clientInfos = (Vector)inStream.readObject();
			outStream.close();
			inStream.close();
			conn.close();
			System.out.println("Vector of ClientInfo names received");
		}
		catch (Exception e)
		{
			try
			{
				if (conn != null)
					conn.close();
				if (outStream != null)
					outStream.close();
				if (inStream != null)
					inStream.close();
			}
			catch (Exception ex)
			{
			}
			e.printStackTrace();
		}
		clientInfoNames = new String[clientInfos.size()];
		for (int i = 0; i < clientInfos.size(); i++)
			clientInfoNames[i] = (String)clientInfos.elementAt(i);
		return clientInfoNames;
	};
	/**
	 * Look up the cleintinfo by name.
	 *
	 * @param	name	name of clientinfo to look up.
	 * @return	clientinfo corresponding to name.
	 */
	public TASKClientInfo getClientInfo(String name) 
	{
		Socket conn = null;
		ObjectOutputStream outStream = null;
		ObjectInputStream inStream = null;
		TASKClientInfo clientInfo = null;
		try
		{
			conn = getConnection();
			outStream = new ObjectOutputStream(conn.getOutputStream());
			inStream = new ObjectInputStream(conn.getInputStream());

			outStream.writeShort(TASKServer.GET_CLIENTINFO);
			outStream.writeObject(name);
			outStream.flush();
			clientInfo = (TASKClientInfo)inStream.readObject();
			outStream.close();
			inStream.close();
			conn.close();
		}
		catch (Exception e)
		{
			try
			{
				if (conn != null)
					conn.close();
				if (outStream != null)
					outStream.close();
				if (inStream != null)
					inStream.close();
			}
			catch (Exception ex)
			{
			}
			e.printStackTrace();
		}
		return clientInfo;
	};
	/**
	 * Create a new clientinfo with the TASKServer.
	 *
	 * @param	clientinfo	new clientinfo to be created by TASKServer.
	 * @return	true if successful, false otherwise
	 */
	public int addClientInfo(TASKClientInfo clientInfo) 
	{
		Socket conn = null;
		ObjectOutputStream outStream = null;
		ObjectInputStream inStream = null;
		int error = TASKError.SOCKET_IO_EXCEPTION;
		try
		{
			conn = getConnection();
			outStream = new ObjectOutputStream(conn.getOutputStream());
			inStream = new ObjectInputStream(conn.getInputStream());

			outStream.writeShort(TASKServer.ADD_CLIENTINFO);
			outStream.writeObject(clientInfo);
			outStream.flush();
			error = inStream.readInt();
			outStream.close();
			inStream.close();
			conn.close();
		}
		catch (Exception e)
		{
			try
			{
				if (conn != null)
					conn.close();
				if (outStream != null)
					outStream.close();
				if (inStream != null)
					inStream.close();
			}
			catch (Exception ex)
			{
			}
			e.printStackTrace();
		}
		return error;
	};
	/**
	 * Delete a clientinfo and all its related moteinfo.
	 *
	 * @param	name 	name of clientinfo to be deleted.
	 * @return	true if successful, false otherwise
	 */
	public int deleteClientInfo(String name) 
	{
		Socket conn = null;
		ObjectOutputStream outStream = null;
		ObjectInputStream inStream = null;
		int error = TASKError.SOCKET_IO_EXCEPTION;
		try
		{
			conn = getConnection();
			outStream = new ObjectOutputStream(conn.getOutputStream());
			inStream = new ObjectInputStream(conn.getInputStream());

			outStream.writeShort(TASKServer.DELETE_CLIENTINFO);
			outStream.writeObject(name);
			outStream.flush();
			error = inStream.readInt();
			outStream.close();
			inStream.close();
			conn.close();
		}
		catch (Exception e)
		{
			try
			{
				if (conn != null)
					conn.close();
				if (outStream != null)
					outStream.close();
				if (inStream != null)
					inStream.close();
			}
			catch (Exception ex)
			{
			}
			e.printStackTrace();
		}
		return error;
	};
	/**
	 * Get client information about a certain mote
	 *
	 * @param	moteId	id of the mote
	 * @return	client information about the particular mote
	 */
	public TASKMoteClientInfo getMoteClientInfo(int moteId) 
	{
		Socket conn = null;
		ObjectOutputStream outStream = null;
		ObjectInputStream inStream = null;
		TASKMoteClientInfo moteClientInfo = null;
		try
		{
			conn = getConnection();
			outStream = new ObjectOutputStream(conn.getOutputStream());
			inStream = new ObjectInputStream(conn.getInputStream());

			outStream.writeShort(TASKServer.GET_MOTECLIENTINFO);
			outStream.writeInt(moteId);
			outStream.flush();
			moteClientInfo = (TASKMoteClientInfo)inStream.readObject();
			outStream.close();
			inStream.close();
			conn.close();
		}
		catch (Exception e)
		{
			try
			{
				if (conn != null)
					conn.close();
				if (outStream != null)
					outStream.close();
				if (inStream != null)
					inStream.close();
			}
			catch (Exception ex)
			{
			}
			e.printStackTrace();
		}
		return moteClientInfo;
	};
	/**
	 * Add client information about a new mote or overwrite information
	 * about an existing mote.
	 *
	 * @param	moteClientInfo	mote client information
	 * @return	true if successful, false otherwise
	 */
	public int addMote(TASKMoteClientInfo moteClientInfo) 
	{
		Socket conn = null;
		ObjectOutputStream outStream = null;
		ObjectInputStream inStream = null;
		int error = TASKError.SOCKET_IO_EXCEPTION;
		try
		{
			conn = getConnection();
			outStream = new ObjectOutputStream(conn.getOutputStream());
			inStream = new ObjectInputStream(conn.getInputStream());

			outStream.writeShort(TASKServer.ADD_MOTE);
			outStream.writeObject(moteClientInfo);
			outStream.flush();
			error = inStream.readInt();
			outStream.close();
			inStream.close();
			conn.close();
		}
		catch (Exception e)
		{
			try
			{
				if (conn != null)
					conn.close();
				if (outStream != null)
					outStream.close();
				if (inStream != null)
					inStream.close();
			}
			catch (Exception ex)
			{
			}
			e.printStackTrace();
		}
		return error;
	};
	/**
	 * Delete a mote, which deletes its clientinfo.
	 *
	 * @param	moteId	mote id.
	 * @return	true if successful, false otherwise
	 */
	public int deleteMote(int moteId) 
	{
		Socket conn = null;
		ObjectOutputStream outStream = null;
		ObjectInputStream inStream = null;
		int error = TASKError.SOCKET_IO_EXCEPTION;
		try
		{
			conn = getConnection();
			outStream = new ObjectOutputStream(conn.getOutputStream());
			inStream = new ObjectInputStream(conn.getInputStream());

			outStream.writeShort(TASKServer.DELETE_MOTE);
			outStream.writeInt(moteId);
			outStream.flush();
			error = inStream.readInt();
			outStream.close();
			inStream.close();
			conn.close();
		}
		catch (Exception e)
		{
			try
			{
				if (conn != null)
					conn.close();
				if (outStream != null)
					outStream.close();
				if (inStream != null)
					inStream.close();
			}
			catch (Exception ex)
			{
			}
			e.printStackTrace();
		}
		return error;
	};

	/**
	 * Delete all motes associated with a clientinfo
	 *
	 * @param	clientInfoName	a clientinfo name
	 * @return	an error code as defined in TASKError
	 */
	public int deleteMote(String clientInfoName)
	{
		Socket conn = null;
		ObjectOutputStream outStream = null;
		ObjectInputStream inStream = null;
		int error = TASKError.SOCKET_IO_EXCEPTION;
		try
		{
			conn = getConnection();
			outStream = new ObjectOutputStream(conn.getOutputStream());
			inStream = new ObjectInputStream(conn.getInputStream());

			outStream.writeShort(TASKServer.DELETE_MOTES);
			outStream.writeObject(clientInfoName);
			outStream.flush();
			error = inStream.readInt();
			outStream.close();
			inStream.close();
			conn.close();
		}
		catch (Exception e)
		{
			try
			{
				if (conn != null)
					conn.close();
				if (outStream != null)
					outStream.close();
				if (inStream != null)
					inStream.close();
			}
			catch (Exception ex)
			{
			}
			e.printStackTrace();
		}
		return error;
	};
	/**
	 * Get information about all motes in one shot.
	 *
	 * @param	clientinfoName	name of clientinfo.
	 * @return	a Vector of TASKMoteClientInfo for all known motes.
	 */
	public Vector getAllMoteClientInfo(String clientinfoName) 
	{
		Socket conn = null;
		ObjectOutputStream outStream = null;
		ObjectInputStream inStream = null;
		Vector moteClientInfos = null;
		try
		{
			conn = getConnection();
			outStream = new ObjectOutputStream(conn.getOutputStream());
			inStream = new ObjectInputStream(conn.getInputStream());

			outStream.writeShort(TASKServer.GET_ALLMOTECLIENTINFO);
			outStream.writeObject(clientinfoName);
			outStream.flush();
			moteClientInfos = (Vector)inStream.readObject();
			outStream.close();
			inStream.close();
			conn.close();
		}
		catch (Exception e)
		{
			try
			{
				if (conn != null)
					conn.close();
				if (outStream != null)
					outStream.close();
				if (inStream != null)
					inStream.close();
			}
			catch (Exception ex)
			{
			}
			e.printStackTrace();
		}
		return moteClientInfos;
	};
	/**
	 * Get health related information about a mote.
	 *
	 * @param	moteId	mote id.
	 */
	public TASKMoteInfo getMoteInfo(int moteId) 
	{
		// XXX to be completed later
		return null;
	};
	/**
	 * Get health reated information about all motes.
	 * Call this method to figure out which motes have disappeared
	 * from the network, or have low batteries, etc.
	 */
	public TASKMoteInfo[] getAllMoteInfo() 
	{
		// XXX to be completed later
		return null;
	};
	/**
	 * Get all attribute information.  At TASKClient start time,
	 * it pre-fetches all the attribute information from the TASKServer
	 * and saves them in attributeInfos.
	 *
	 * @return an array of attribute information.
	 */
	public Vector getAttributes() 
	{
		return attributeInfos;
	};
	/**
	 * Returns information about the named attribute.
	 *
	 * @param	name	attribute name.
	 * @return	information about the attribute.
	 */
	public TASKAttributeInfo getAttribute(String name) 
	{
		for (int i = 0; i < attributeInfos.size(); i++)
		{
			TASKAttributeInfo attrInfo = (TASKAttributeInfo)attributeInfos.elementAt(i);
			if (attrInfo.name.equalsIgnoreCase(name))
				return attrInfo;
		}
		return null;
	};
	/**
	 * Get all command information.  At TASKClient start time,
	 * it pre-fetches all the command information from the TASKServer
	 * and saves them in commandInfos.
	 *
	 * @return an array of command information.
	 */
	public Vector getCommands() 
	{
		return commandInfos;
	};
	/**
	 * Returns information about the named command.
	 *
	 * @param	name 	command name
	 * @return	command information
	 */
	public TASKCommandInfo getCommand(String name) 
	{
		for (int i = 0; i < commandInfos.size(); i++)
		{
			TASKCommandInfo cmdInfo = (TASKCommandInfo)commandInfos.elementAt(i);
			if (cmdInfo.getCommandName().equalsIgnoreCase(name))
				return cmdInfo;
		}
		return null;
	};
	/**
	 * Get information about all supported aggregates.  At TASKClient start time
	 * it pre-fetches all the aggregate information from the TASKServer
	 * and saves them in aggregateInfos.
	 *
	 * @return an array of aggregate information.
	 */
	public Vector getAggregates() 
	{
		return aggregateInfos;
	};
	/**
	 * Returns information about the named aggregate.
	 *
	 * @param	name	aggregate name.
	 * @return	aggregate information.
	 */
	public TASKAggInfo getAggregate(String name) 
	{
		for (int i = 0; i < aggregateInfos.size(); i++)
		{
			TASKAggInfo aggInfo = (TASKAggInfo)aggregateInfos.elementAt(i);
			if (aggInfo.getName().equalsIgnoreCase(name))
				return aggInfo;
		}
		return null;
	};
	/**
	 * Get basic configuration information about TASKServer.
	 *
	 * @return configuration information about TASKServer.
	 */
	public TASKServerConfigInfo getServerConfigInfo() 
	{
		Socket conn = null;
		ObjectOutputStream outStream = null;
		ObjectInputStream inStream = null;
		TASKServerConfigInfo serverConfigInfo = null;
		try
		{
			conn = getConnection();
			outStream = new ObjectOutputStream(conn.getOutputStream());
			inStream = new ObjectInputStream(conn.getInputStream());
			outStream.writeShort(TASKServer.GET_SERVERCONFIGINFO);
			outStream.flush();
			serverConfigInfo  = (TASKServerConfigInfo)inStream.readObject();
			outStream.close();
			inStream.close();
			conn.close();
		}
		catch (Exception e)
		{
			try
			{
				if (conn != null)
					conn.close();
				if (outStream != null)
					outStream.close();
				if (inStream != null)
					inStream.close();
			}
			catch (Exception ex)
			{
			}
			e.printStackTrace();
		}
		return serverConfigInfo;
	};
	/**
	 * Submit sensor query to the sensor network via the TASKServer.
	 *
	 * @param query	the query to be submitted
	 * @return an error code defined in TASKError
	 */
	public int submitSensorQuery(TASKQuery query) 
	{
		return sendQuery(query, TASKServer.SENSOR_QUERY);
	};
	/**
	 * Stop the current sensor query.
	 * @return true if successful, false otherwise
	 */
	public int stopSensorQuery() 
	{
		return stopQuery(TASKServer.SENSOR_QUERY);
	};
	/**
	 * Submit health monitoring query to the sensor network via the TASKServer.
	 * For now, we will restrict that the health query's sample period must
	 * be multiples of the sensor query's sample period.
	 *
	 * @param query	The query to be submitted
	 * @return an error code defined in TASKError
	 */
	public int submitHealthQuery(TASKQuery query)
	{
		return sendQuery(query, TASKServer.HEALTH_QUERY);
	};
	/**
	 * Stop the current heath query.
	 * @return true if successful, false otherwise
	 */
	public int stopHealthQuery() 
	{
		return stopQuery(TASKServer.HEALTH_QUERY);
	};
	/**
	 * Add a listener which will be called upon arrival
	 * of any result from the sensor query.
	 * Note that all listeners will be called in the same thread.
	 * Therefore they should not perform heavy computation.
	 *
	 * @param listener	a result listener.
	 */
	public int addSensorResultListener(TASKResultListener listener) 
	{
		return addListener(TASKServer.SENSOR_QUERY, listener);
	};
	/**
	 * Add a listener which will be called upon arrival
	 * of any result from the network health monitoring query.
	 * Note that all listeners will be called in the same thread.
	 * Therefore they should not perform heavy computation.
	 *
	 * @param listern	a result listener
	 */
	public int addHealthResultListener(TASKResultListener listener) 
	{
		return addListener(TASKServer.HEALTH_QUERY, listener);
	};
	/**
	 * Submit a command to the sensor network via the TASKServer.
	 * For now, we are not handling return results of commands.
	 *
	 * @param	command	a TASK command
	 * @return	an error code defined in TASKError
	 */
	public int submitCommand(TASKCommand command)
	{
		Socket conn = null;
		ObjectOutputStream outStream = null;
		ObjectInputStream inStream = null;
		TASKServerConfigInfo serverConfigInfo = null;
		int error = TASKError.SOCKET_IO_EXCEPTION;
		try
		{
			conn = getConnection();
			outStream = new ObjectOutputStream(conn.getOutputStream());
			inStream = new ObjectInputStream(conn.getInputStream());
			outStream.writeShort(TASKServer.RUN_COMMAND);
			outStream.writeObject(command);
			outStream.flush();
			error  = inStream.readInt();
			outStream.close();
			inStream.close();
			conn.close();
		}
		catch (Exception e)
		{
			try
			{
				if (conn != null)
					conn.close();
				if (outStream != null)
					outStream.close();
				if (inStream != null)
					inStream.close();
			}
			catch (Exception ex)
			{
			}
			e.printStackTrace();
		}
		return error;
	}

	/**
	 * run the calibration query until sensor calibration coefficients
	 * are collected from every mote in the network.
	 *
	 * @return	an error code defined in TASKError
	 */
	public int collectCalibration()
	{
		Socket conn = null;
		ObjectOutputStream outStream = null;
		ObjectInputStream inStream = null;
		TASKServerConfigInfo serverConfigInfo = null;
		int error = TASKError.SOCKET_IO_EXCEPTION;
		try
		{
			conn = getConnection();
			outStream = new ObjectOutputStream(conn.getOutputStream());
			inStream = new ObjectInputStream(conn.getInputStream());
			outStream.writeShort(TASKServer.RUN_CALIBRATION);
			outStream.flush();
			error  = inStream.readInt();
			outStream.close();
			inStream.close();
			conn.close();
		}
		catch (Exception e)
		{
			try
			{
				if (conn != null)
					conn.close();
				if (outStream != null)
					outStream.close();
				if (inStream != null)
					inStream.close();
			}
			catch (Exception ex)
			{
			}
			e.printStackTrace();
		}
		return error;
	}

    /** 
	 * Return a socket allowing communication with the server
	 *
	 * @throws IOException If the server is unavailable
     */
    Socket getConnection() throws IOException 
	{
		try 
		{
			return new Socket(InetAddress.getByName(serverIP), serverPort);
		} 
		catch(UnknownHostException e) 
		{
	    	throw new IOException("Invalid TASK Server at " + serverIP + ":" + serverPort);
		}
    }

    /** Send a query to the server
	@param query The text of the query
	@param whichQuery is it a sensor query or health query?
	@return an error code defined in TASKError
    */
    private int sendQuery(TASKQuery query, short whichQuery) 
	{
		Socket conn = null;
		ObjectOutputStream outStream = null;
		ObjectInputStream inStream = null;
		TASKServerConfigInfo serverConfigInfo = null;
		int error = TASKError.SOCKET_IO_EXCEPTION;
		try
		{
			conn = getConnection();
			outStream = new ObjectOutputStream(conn.getOutputStream());
			inStream = new ObjectInputStream(conn.getInputStream());
			outStream.writeShort(TASKServer.RUN_QUERY);
			outStream.writeObject(query);
			outStream.writeShort(whichQuery);
			outStream.flush();
			error  = inStream.readInt();
			outStream.close();
			inStream.close();
			conn.close();
		}
		catch (Exception e)
		{
			try
			{
				if (conn != null)
					conn.close();
				if (outStream != null)
					outStream.close();
				if (inStream != null)
					inStream.close();
			}
			catch (Exception ex)
			{
			}
			e.printStackTrace();
		}
		return error;
    }

	private int stopQuery(short whichQuery)
	{
		Socket conn = null;
		ObjectOutputStream outStream = null;
		ObjectInputStream inStream = null;
		TASKServerConfigInfo serverConfigInfo = null;
		int error = TASKError.SOCKET_IO_EXCEPTION;
		try
		{
			conn = getConnection();
			outStream = new ObjectOutputStream(conn.getOutputStream());
			inStream = new ObjectInputStream(conn.getInputStream());
			outStream.writeShort(TASKServer.STOP_QUERY);
			outStream.writeShort(whichQuery);
			outStream.flush();
			error  = inStream.readInt();
			outStream.close();
			inStream.close();
			conn.close();
		}
		catch (Exception e)
		{
			try
			{
				if (conn != null)
					conn.close();
				if (outStream != null)
					outStream.close();
				if (inStream != null)
					inStream.close();
			}
			catch (Exception ex)
			{
			}
			e.printStackTrace();
		}
		return error;
	}

	private int addListener(short whichQuery, TASKResultListener listener)
	{
		Socket conn = null;
		ObjectOutputStream outStream = null;
		ObjectInputStream inStream = null;
		ListenerHandler handler;
		int error = TASKError.SOCKET_IO_EXCEPTION;

		if (whichQuery == TASKServer.SENSOR_QUERY)
			handler = sensorListenerHandler;
		else
			handler = healthListenerHandler;
		handler.addListener(listener);
		if (handler.getSocket() != null)
		{
			return TASKError.SUCCESS;
		}

		// add listener in the server
		try
		{
			conn = getConnection();
			System.out.println("got listener socket.");
			outStream = new ObjectOutputStream(conn.getOutputStream());
			System.out.println("got listener output stream.");
			inStream = new ObjectInputStream(conn.getInputStream());
			System.out.println("got listener input stream.");
			outStream.writeShort(TASKServer.ADD_LISTENER);
			outStream.writeShort(whichQuery);
			outStream.flush();
			System.out.println("server add listener request sent.");
			error  = inStream.readInt();
			if (error == TASKError.SUCCESS)
				handler.setSocket(conn, inStream);
			else
			{
				System.out.println("server add listener request failed.");
				outStream.close();
				inStream.close();
				conn.close();
			}
		}
		catch (Exception e)
		{
			try
			{
				if (conn != null)
					conn.close();
				if (outStream != null)
					outStream.close();
				if (inStream != null)
					inStream.close();
			}
			catch (Exception ex)
			{
			}
			e.printStackTrace();
		}
		return error;
	}

    /** A test for server connection
	Requires two parameters:
	- query to run
	- hostname of the server 
	Runs the query, registers as a listener for it, and prints out results
    public static void main(String[] argv) {
	if (argv.length != 2)
	    System.out.println("Invalid argument list\n usage:\n TASKServerConn query host");
	else {
	    try {
		String host = argv[1];
		String query = argv[0];
		Socket results;
		TASKServerConn serv = new TASKServerConn(host, TASKServer.getServerPort());
		boolean ok;
		String result;
		
		ok = serv.sendQuery(query, 0);
		if (ok) {
		    System.out.println("Sent query successfully!");
		    results = serv.registerListener(0);
		    BufferedReader br = new BufferedReader(new InputStreamReader(results.getInputStream()));
		    while (true) {
			while ((result = br.readLine()) != null) {
			    System.out.println("Read result: " + result);
			}
		    }
		} else {
		    System.out.println("Send query failed.");
		}
	    
	    } catch (IOException e) {
		System.out.println("Error: " + e);
	    }
	}
    }    
	*/

	private Vector	attributeInfos;	// pre-fetched attribute info's
	private Vector	commandInfos;	// pre-fetched command info's 
	private Vector	aggregateInfos;	// pre-fetched aggregate info's
	private String	serverIP;	// server ip address
	private int		serverPort; // server port number
	private ListenerHandler	sensorListenerHandler;
	private ListenerHandler	healthListenerHandler;
};

/**
 * ListenerHandler: internal class responsible for listening on a socket
 * for results then call all registered listeners on the socket once
 * a result is received.
 */
class ListenerHandler implements Runnable
{
	public ListenerHandler()
	{
		this.inStream = null;
		this.socket = null;
		this.resultListeners = new Vector();
	}

	public void run()
	{
		TASKResult result;
		try
		{
			while ((result = (TASKResult)inStream.readObject()) != null)
			{
				for (Iterator it = resultListeners.iterator(); it.hasNext(); )
				{
					TASKResultListener listener = (TASKResultListener)it.next();
					listener.addResult(result);
				}
			}
			// end of stream is reached, clean up
			inStream.close();
			socket.close();
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
		socket = null;
		inStream = null;
	}

	public void addListener(TASKResultListener listener)
	{
		resultListeners.add(listener);
	}

	public void setSocket(Socket sock, ObjectInputStream inStream)
	{
		Thread t = new Thread(this);
		this.socket = sock;
		try
		{
			this.inStream = inStream;
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
		t.start();
	}

	public Socket getSocket()
	{
		return socket;
	}

	private Socket				socket;
	private ObjectInputStream	inStream;
	private Vector				resultListeners;
}
