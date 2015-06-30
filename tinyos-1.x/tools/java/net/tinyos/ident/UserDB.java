// $Id: UserDB.java,v 1.2 2003/10/07 21:45:54 idgay Exp $

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

package net.tinyos.ident;

import java.util.*;

class UserDB extends Thread implements IdentityReceiver 
{
    /* Times in ms */
    final static int checkPeriod = 1000;
    final static int idLife = 20000;

    Vector db;
    DBReceiver dbListener;
    
    UserDB()
    {
	db = new Vector();
    }

    void setDBListener(DBReceiver dbl)
    {
	dbListener = dbl;
    }

    public void identityReceived(String id)
    {
	updateDB(id, new Date().getTime());
    }

    synchronized void updateDB(String id, long arrivalTime)
    {
	Enumeration elems = db.elements();

	while (elems.hasMoreElements()) {
	    DBId elem = (DBId)elems.nextElement();

	    if (elem.id.equals(id)) {
		elem.arrivalTime = arrivalTime;
		dbListener.dbChange(db);
		return;
	    }
	}
	DBId visitor = new DBId();
	visitor.id = id;
	visitor.arrivalTime = arrivalTime;
	db.addElement(visitor);
	dbListener.dbChange(db);
    }

    synchronized void timeoutDB() {
	int dbLength = db.size();
	long currentTime = new Date().getTime();

	for (int i = 0; i < dbLength; i++) {
	    DBId visitor = (DBId)db.elementAt(i);

	    if (visitor.arrivalTime + idLife < currentTime) {
		/* Goodbye! */
		db.removeElementAt(i);
		dbLength--;
	    }
	    else
		i++;
	}
	dbListener.dbChange(db);
    }

    public void run() {
	while (true) {
	    try { sleep(checkPeriod, 0); }
	    catch (InterruptedException e) { }
	    timeoutDB();
	}
    }
    
}
