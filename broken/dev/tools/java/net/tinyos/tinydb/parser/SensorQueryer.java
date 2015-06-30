package net.tinyos.tinydb.parser;

import net.tinyos.tinydb.*;
import java.io.*;
import java_cup.runtime.*;

public class SensorQueryer {
    private static boolean DEBUG = false;

    private TinyDBNetwork network;
    private byte queryId = 1;
    public static String errorMessage = "";

    public SensorQueryer(TinyDBNetwork network) {
	this.network = network;
    }

    public void query(String sql_query) {
	TinyDBQuery tdb_query;

	try {
	    tdb_query = translateQuery(sql_query, queryId++);
	} catch (ParseException pe) {
	    System.err.println(pe.getMessage());
	    //pe.printStackTrace();
	    //System.err.println(pe.getParseError());
	    return;
	}
	network.sendQuery(tdb_query);
    }

    public static TinyDBQuery translateQuery(String sql_query, byte queryId) throws ParseException {
	StringReader reader = new StringReader(sql_query);
	senseParser parser = new senseParser(new Yylex(reader));
	Symbol parse_result = null;

	if (parser == null)
	    System.out.println("PARSER IS NULL");
	//parser.setCatalog("catalog");
	//parser.setQueryId(queryId);

	try {
	    errorMessage = "";
	    if (DEBUG)
		parse_result = parser.debug_parse();
	    else
		parse_result = parser.parse();
	} catch (Exception e) {

	    String parseErrMessage;

	    if (errorMessage.equals(""))
		parseErrMessage = parser.errorMsg;
	    else
		parseErrMessage = errorMessage;



	    //	    System.err.println("Unable to parse query:  " + sql_query);
	    //System.err.println("Exception:  " + e);
	    //e.printStackTrace();
	    //System.out.println("ERROR MSG = " + parser.errorMsg);

	    throw new ParseException(e, parseErrMessage);
	    //return null;
	}
	
	if (parse_result == null) {
	    System.out.println("Parse result is null.");
	    return null;
	} else {
	    if (parse_result.value == null) {
		System.out.println("Parse result value is null.");
		return null;
	    } else {
		TinyDBQuery tdb_query = ((TinyDBQuery) parse_result.value);
		tdb_query.setId(queryId);
		tdb_query.setSQL(sql_query);
		return tdb_query;
	    }
	}
	//never gets here
    }
}

