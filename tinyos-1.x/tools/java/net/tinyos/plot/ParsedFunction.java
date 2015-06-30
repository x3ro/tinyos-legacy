// $Id: ParsedFunction.java,v 1.2 2003/10/07 21:46:02 idgay Exp $

package net.tinyos.plot;

public class ParsedFunction implements Function {
	ExpressionParser e;
	public ParsedFunction(String s) {
		e = new ExpressionParser(s);
	}
	
	public double f(double x) {
		e.addVar("x", new Double(x));
		return e.eval();
	}
}