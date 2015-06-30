package net.tinyos.tinydb.parser;

public class ParseException extends Exception {
    private String parseError;

    public ParseException(Exception e, String errMessage) {
	super(e.getMessage());
	parseError = errMessage;
    }
    
    public String getParseError() {
	return parseError;
    }
}
