package net.tinyos.tinydb;
import net.tinyos.tinydb.parser.*;
import java.util.*;

public class CmdLineOutput implements ResultListener {
    public CmdLineOutput(TinyDBNetwork nw, String queryString) {
	Catalog.curCatalog = new Catalog("catalog");
	try {
	    TinyDBQuery q = SensorQueryer.translateQuery(queryString, (byte)1);
	    Vector headings = q.getColumnHeadings();
	    
	    this.q = q;

	    TinyDBMain.notifyAddedQuery(q);
	    nw.addResultListener(this, true, 1);

	    System.out.print("|");
	    for (int i = 0; i < headings.size(); i++) {
		System.out.print("\t" + headings.elementAt(i) + "\t|");
	    }
	    System.out.println("\n-----------------------------------------------------");

	    nw.sendQuery(q);

	    
	} catch (ParseException e) {
	    System.err.println("Invalid query : " + queryString + "(" + e + ")");
	}
	
    }

    public void addResult(QueryResult qr) {
	Vector v = qr.resultVector();
	for (int i = 0; i < v.size(); i++) {
	    System.out.print("\t" + v.elementAt(i) + "\t|");
	}
	System.out.println();

    }

    TinyDBQuery q;

}
