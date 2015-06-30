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
