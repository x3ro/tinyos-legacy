// $Id: TASKServerConfigInfo.java,v 1.2 2003/10/07 21:46:06 idgay Exp $

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

import java.io.*;

/**
 * TASKServerConfigInfo contains the configuration information about the
 * TASKServer.
 */
public class TASKServerConfigInfo implements Serializable
{
	/**
	 * Constructor for TASKServerConfigInfo.
	 *
	 * @param	amGroupId	AM group id of the sensor network.
	 * @param	jdbcUrl		JDBC URL for the TASK database.
	 * @param	jdbcUser	TASK database user name.
	 * @param	jdbcPwd		TASK database password.
	 * @param	sfHost		IP address of host running the serial forwarder.
	 * @param	sfPort		Port number of the serial forwarder.
	 * @param	sfCommPort	COMM port name of the serial forwarder.
	 */
	public TASKServerConfigInfo(short amGroupId, String jdbcUrl, String jdbcUser, String jdbcPwd, String sfHost, short sfPort, String sfCommPort) 
	{
		amGroupId = amGroupId;
		jdbcUrl = jdbcUrl;
		jdbcUser = jdbcUser;
		jdbcPwd = jdbcPwd;
		sfHost = sfHost;
		sfPort = sfPort;
		sfCommPort = sfCommPort;
	};

	public short		amGroupId;	// AM group id for the sensor network
	public String		jdbcUrl;	// JDBC URL for the TASK database
	public String		jdbcUser;	// TASK database user name
	public String		jdbcPwd;	// TASK database password, clear text for now
	public String		sfHost;		// host IP of the serial forwarder
	public short		sfPort;		// port number of the serial forwarder
	public String		sfCommPort;	// COMM port name of the serial forwarder
};
