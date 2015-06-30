package net.tinyos.tinydb;

import java.util.*;

public class EpochTimer implements Runnable {
    /** Rate is number of ms per time slot */
    public EpochTimer(int rate) {
	Thread t = new Thread(this);

	sleepMs = 1000 / rate;
	int sleepLeftover = 1000 - (sleepMs * rate);
	sleepExtraEvery = rate / sleepLeftover; 

	this.rate = rate;

	t.start();
	
    }

    public void run() {
	int curInterval = sleepExtraEvery;
	int extraSleepTime = sleepMs + (sleepExtraEvery > 0?1:0);
	while (true) {
	    try {
		if (curInterval-- == 0) {
		    curInterval = sleepExtraEvery;
		    Thread.currentThread().sleep(extraSleepTime);
		} else {
		    Thread.currentThread().sleep(sleepMs);
		}
		for (int i = 0; i < queries.size(); i++) {
		    QueryTimeInfo qif = (QueryTimeInfo)queries.elementAt(i);
		    if (qif != null && qif.slotsLeft-- == 0){
			qif.slotsLeft = qif.querySlots;
		    }
		}
	    } catch (Exception e) {
	    }
	}
    }

    public void addQuery(char qid, int epochDur) {
	QueryTimeInfo qif = new QueryTimeInfo();
	qif.qid = qid;
	qif.querySlots = epochDur / rate;
	qif.slotsLeft = qif.querySlots;
	
	if ((int)qid >= queries.size())
	    queries.setSize((int)qid + 1);
	System.out.println("added query : " + (int)qid);
	queries.setElementAt(qif, (int)qid);
    }


    public short getQueryTimeLeft(int qid) throws NoSuchElementException{
	QueryTimeInfo qif = (QueryTimeInfo)queries.elementAt(qid);
	if (qif == null) throw new NoSuchElementException();
	System.out.println(qid + " time left " + qif.slotsLeft);
	return (short)qif.slotsLeft;
    }

    Vector queries = new Vector();

    int sleepMs;
    int sleepExtraEvery;
    int curInterval;
    int rate;
}

    class QueryTimeInfo {
	char qid;
	int querySlots;
	int slotsLeft;
    }
