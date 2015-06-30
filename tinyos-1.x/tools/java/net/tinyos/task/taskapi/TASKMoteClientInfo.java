// $Id: TASKMoteClientInfo.java,v 1.2 2003/10/07 21:46:06 idgay Exp $

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
 * TASKMoteClientInfo contains opaque client information about each mote.
 * Typically this includes location information about each mote.
 */
public class TASKMoteClientInfo implements Serializable
{
	/**
	 * Constructor for TASKMoteClientInfo.
	 *
	 * @param	moteId	unique mote id.
	 * @param	data	opaque client data for the mote, e.g.,(x, y) coordinates
	 * @param	clientInfoName name of clientinfo the moteinfo is based on
	 */
	public TASKMoteClientInfo(int moteId, double x, double y, double z, byte[] data, String clientInfoName) 
	{
		this.moteId = moteId;
		this.xCoord = x;
		this.yCoord = y;
		this.zCoord = z;
		this.data = data;
		this.clientInfoName = clientInfoName;
	};

	public int		moteId;			// mote id
	public double	xCoord;			// x coordinate
	public double	yCoord;			// y coordinate
	public double	zCoord;			// z coordinate
	public byte[]	data;			// opaque client data for the mote
	public String	clientInfoName;	// name of clientinfo
};

