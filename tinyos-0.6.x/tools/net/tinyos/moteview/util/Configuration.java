/* "Copyright (c) 2001 and The Regents of the University
* of California.  All rights reserved.
*
* Permission to use, copy, modify, and distribute this software and its
* documentation for any purpose, without fee, and without written agreement is
* hereby granted, provided that the above copyright notice and the following
* two paragraphs appear in all copies of this software.
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
* Authors:   Kamin Whitehouse <kamin@cs.berkeley.edu>
* History:   created 7/22/2001
*/

package net.tinyos.moteview.util;

import java.util.*;

public class Configuration {

    private Vector PacketReaders = null;
    private Vector PacketSenders = null;
    private Vector PacketAnalyzers = null;

    private boolean bDebug = false;
    private boolean bVerbose = false;

    private String serverName = "localhost";
    private int serverPort = 9000;

    public Configuration()
    {
    }

    public Vector getPacketReaders()
    {
	return PacketReaders;
    }

    public Vector getPacketSenders()
    {
	return PacketSenders;
    }

    public Vector getPacketAnalyzers()
    {
	return PacketAnalyzers;
    }

    public void setPacketReaders(Vector pr)
    {
	PacketReaders = pr;
    }

    public void setPacketSenders(Vector ps)
    {
	PacketSenders = ps;
    }

    public void setPacketAnalyzers(Vector pa)
    {
	PacketAnalyzers = pa;
    }

    public boolean getDebug()
    {
	return bDebug;
    }

    public void setDebug(boolean d)
    {
	bDebug = d;
    }

    public boolean getVerbose()
    {
	return bVerbose;
    }

    public void setVerbose(boolean v)
    {
	bVerbose = v;
    }

    public String getServerName()
    {
	return serverName;
    }

    public void setServerName (String sn)
    {
	serverName = sn;
    }

    public int getServerPort()
    {
	return serverPort;
    }

    public void setServerPort(int port)
    {
	serverPort = port;
    }

}
