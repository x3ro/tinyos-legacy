/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
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
