/*
 * DataCollect.java
 *
 * Created on July 10, 2003, 1:43 AM
 */

package net.tinyos.tinydb.experiment;
import java.io.*;
import java.util.*;
import net.tinyos.tinydb.parser.*;
import net.tinyos.tinydb.*;
import net.tinyos.message.*;

/**
 *
 * @author  yliu10
 */
public class DataCollect implements ResultListener {
    
    public DataCollect() {
	TinyDBMain.debug = false;
	TinyDBMain.simulate = false;
        try {
            TinyDBMain.initMain();
            query = SensorQueryer.translateQuery("select nodeid, energy from sensors sample period 4096", (byte)queryid);
        } catch (IOException e) {
            System.out.println("Network error.");
        } catch (ParseException e) {
            System.out.println("Invalid query.");
        }
    }
    
    public static void main(String args[]) {
        new DataCollect();
    }

    public void addResult(QueryResult qr) {
        try {

        Vector datamsg = qr.resultVector();
        Vector element;
        boolean found = false;

        if (collectEnergyDone && collectMergeDone) return;
	
        if (datamsg.size() == 1) return;

        for (int i=0; i<datamsg.size(); i++) {
            if (datamsg.elementAt(i) == null)
                return;
        }

        if (!collectEnergyDone) {

            for (int i=0; i<resultCollect.size(); i++) {
                element = (Vector)resultCollect.elementAt(i);
                if (((String)element.elementAt(1)).equalsIgnoreCase
                                       ((String)datamsg.elementAt(1))) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                resultCollect.add(datamsg);
                System.out.print(resultCollect.size() + ".");
            }
            if (resultCollect.size() == numNode) {
                printResult();
                stopQuery();
                Thread.currentThread().sleep(200);
                stopQuery();
                collectEnergyDone = true;
            }
        } else if (!collectMergeDone) {
        } else {
            System.out.println("Logical Wrong, impossible to be here - Quit!!");
            System.exit(0);
        }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }    
    
    private void resetMote() {
        stopQuery();
        try {
            TinyDBMain.mif.send( (short)-1, CommandMsgs.resetCmd((short)-1));
        } catch (Exception e) {
            System.out.println("Error sending Reset.");
        }
    }

    private void printResult() {
        Vector element;
        System.out.println();
        Collections.sort(resultCollect, new Comparator() {
            public int compare(Object a, Object b) {
                Vector va = (Vector)a;
                Vector vb = (Vector)b;
                int x = Integer.parseInt((String)va.elementAt(1));
                int y = Integer.parseInt((String)vb.elementAt(1));
                return (x - y);
            }
        });
        for (int i=0; i<resultCollect.size(); i++) {
            element = (Vector)resultCollect.elementAt(i);
            for (int j=0; j<element.size(); j++)
                System.out.print("\t" + element.elementAt(j) + "\t|");
            System.out.println();
       }
       System.out.println();
    }

    private void sendQuery() {
        try {
            /* first query has to register listenr */
            if (!queryRegistered) {
                TinyDBMain.injectQuery(query, this);
                queryRegistered = true;
            } else {
                TinyDBMain.network.sendQuery(query);
            }
            
        } catch (IOException e) {
            System.out.println("Network error.");
        }
    }
    
    private void stopQuery() {
        try {
            TinyDBMain.network.abortQuery(query);
            Thread.currentThread().sleep(200);
            TinyDBMain.network.removeQuery(query);
            Thread.currentThread().sleep(200);
            TinyDBMain.network.removeResultListener(this);
            TinyDBMain.notifyRemovedQuery(query);
            queryRegistered = false;
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    private byte queryid = 10;
    private TinyDBQuery query;
    private boolean queryRegistered = false;
    private Vector resultCollect = new Vector(0);
    private int numNode = 30;   
    private boolean collectEnergyDone = false;
    private boolean collectMergeDone = false;
}
