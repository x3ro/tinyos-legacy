// $Id: DBSource.java,v 1.2 2003/10/07 21:46:03 idgay Exp $

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


//Not Done yet

package net.tinyos.sf.old;

import java.util.*;

public class DBSource implements DataSource {
    private DBReader m_dbReader = null;
    private boolean  m_bShutdown = false;
    private SerialForward sf;

    public DBSource(SerialForward SF) {sf=SF;}
    public void setSerialForward(SerialForward SF) {sf=SF;}

    public boolean OpenSource() {
        m_dbReader = new DBReader (sf.strDBUser, sf.strDBPassword, sf.bPostgresql);
	m_bShutdown = !(m_dbReader.Connect ());

        return true;
    }

    public boolean CloseSource() { return true; }

    public byte[] ReadPacket() {
	if (m_dbReader == null) {
	    m_bShutdown = true;
	    return null;
	}

	java.sql.Timestamp lastTimestamp = null;
	java.sql.Timestamp crrntTimestamp = null;

	byte[] packet = m_dbReader.NextPacket();
	crrntTimestamp = m_dbReader.GetTimestamp ();
	lastTimestamp = crrntTimestamp;

	int sleep = (int)(crrntTimestamp.getTime() - lastTimestamp.getTime());
	if (sleep > 0) {
	    System.out.println ("Sleeping for: " + sleep);
	    try { Thread.currentThread().sleep (sleep); }
	    catch (Exception e) { }
	}


        return packet;
    }

    public boolean WritePacket (byte[] packet) {return true;}
}
