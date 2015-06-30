// $Id: ExpressionParser.java,v 1.2 2003/10/07 21:46:01 idgay Exp $

/**
 *    ExpressionParser.java
 *
 *    This is a simple yet extendable logical expression parser.
 *
 *    Copyright(C) 2002, Tom Pycke
 */
 

package net.tinyos.plot;
import java.util.*;
import java.io.*;

class ExpressionParser {
	String expr="", expr2="", expr3="";
	static String _separators[] = { ",", "+", "-", "*", "/", "%", "^", "(", ")" };
	static String _operators[] = {
		",",
		"+",
		"-",
		"*",
		"/",
		"%",
		"^",
		"log",
		"sin",
		"cos",
		"tan",
		"sqrt",
		"abs",
		"ceil",
		"floor",
		"round",
		"asin",
		"acos",
		"atan",
		"exp",
		"random",
		"toDegrees",
		"toRadians"
	};
	
	static ArrayList separators, operators;
	static HashMap varMap;

	static {
		int x;
		varMap = new HashMap();
		varMap.put ("pi", new Double(3.14159265358979323846));
		varMap.put ("Pi", new Double(3.14159265358979323846));
		varMap.put ("x", new Double(0.5));
		separators = new ArrayList();
		operators = new ArrayList();
		for (x=_separators.length - 1; x >= 0; x--)
			separators.add(_separators[x]);
		for (x=0 ; x < _operators.length; x++)
			operators.add(_operators[x]);
	}
	
	static void addVar (String name, Double value) {
		varMap.put (name, value);
	}
	
	ExpressionParser (String expr) {
		this.expr = expr;
		separateTokens();
		postfix();
	}
	
	void separateTokens () {
		boolean nextIsNumber = true;
		for (int i = 0; i < expr.length(); i++) {
			if (expr.charAt(i) == '-' && nextIsNumber) // negative number?
				expr2 += " -1 * ";
			else if (separators.contains(new String(""+expr.charAt(i)))) {
				expr2 += " ";
				expr2 += expr.charAt(i);
				expr2 += " ";
				if (expr.charAt(i) != ')')
					nextIsNumber = true;
				else
					nextIsNumber = false;
			} else {
				expr2 += expr.charAt(i);
				nextIsNumber = false;
			}
		}
		//System.out.println("s: "+expr2);
	}
	
	void postfix() {
		Stack s = new Stack();
		StringTokenizer t = new StringTokenizer(expr2);
		while (t.hasMoreTokens()) {
			String token = t.nextToken();
			if (token.equals("(")) {
				s.push(token);
			} else if (token.equals(")")) {
				while (!s.peek().equals("("))
					expr3 += " " + s.pop() + " ";
				s.pop();
			} else if (operators.contains(token)) {
				while (!s.empty() && operators.indexOf(s.peek()) >= operators.indexOf(token) && !s.peek().equals("(")) {
					expr3 += " " + s.pop() + " ";
				}
				s.push(token);
			} else
				expr3 += " " + token + " ";
		}
		while (!s.empty())
			expr3 += " " + s.pop() + " ";
		//System.out.println("p: "+expr3);
	}
	
	
	double eval() {
		try {
			double e = 0;
			StringTokenizer t = new StringTokenizer(expr3);
			Stack s = new Stack();
			double tmp;
			while (t.hasMoreTokens()) {
				String token = t.nextToken();
				if (operators.contains(token)) {
					switch(operators.indexOf(token)) {
						case 1:    // +
							e = ((Double)s.pop()).doubleValue() + ((Double)s.pop()).doubleValue();
							break;
						case 2:    // -
							if (s.size() == 1)    //   a binairy minus
								e = -((Double)s.pop()).doubleValue();
							else
								e = -((Double)s.pop()).doubleValue() + ((Double)s.pop()).doubleValue();
							break;
						case 3:    // *
							e = ((Double)s.pop()).doubleValue() * ((Double)s.pop()).doubleValue();
							break;
						case 4:    // /
							e = 1 / ((Double)s.pop()).doubleValue() * ((Double)s.pop()).doubleValue();
							break;
						case 5:    // %
							tmp = ((Double)s.pop()).doubleValue();
							e = ((Double)s.pop()).doubleValue() % tmp;
							break;
						case 6:    // ^
							tmp = ((Double)s.pop()).doubleValue();
							e = Math.pow( ((Double)s.pop()).doubleValue(), tmp);
							break;
						case 7:    // log
							e = Math.log(((Double)s.pop()).doubleValue());
							break;
						case 8:    // sin
							e = Math.sin(((Double)s.pop()).doubleValue());
							break;
						case 9:    // cos
							e = Math.cos(((Double)s.pop()).doubleValue());
							break;
						case 10:    // tan
							e = Math.tan(((Double)s.pop()).doubleValue());
							break;
						case 11:    // sqrt
							e = Math.sqrt(((Double)s.pop()).doubleValue());
							break;
						case 12:    // abs
							e = Math.abs(((Double)s.pop()).doubleValue());
							break;
						case 13:    // ceil
							e = Math.ceil(((Double)s.pop()).doubleValue());
							break;
						case 14:    // floor
							e = Math.floor(((Double)s.pop()).doubleValue());
							break;
						case 15:    // round
							e = Math.round(((Double)s.pop()).doubleValue());
							break;
						case 16:    // asin
							e = Math.asin(((Double)s.pop()).doubleValue());
							break;
						case 17:    // acos
							e = Math.acos(((Double)s.pop()).doubleValue());
							break;
						case 18:    // atan
							e = Math.atan(((Double)s.pop()).doubleValue());
							break;
						case 19:    // exp
							e = Math.exp(((Double)s.pop()).doubleValue());
							break;
						case 20:    // random
							e = Math.random();
							break;
						case 21:    // toDegrees
							e = Math.toDegrees(((Double)s.pop()).doubleValue());
							break;
						case 22:    // toRadians
							e = Math.toRadians(((Double)s.pop()).doubleValue());
							break;
	
	
						default:
							System.out.println ("?"+operators.indexOf(token)+"?");
					}
					s.push(new Double (e));
				} else {
					char a = token.charAt(0);
					if (a >= 'A' && a <= 'z')
						s.push(varMap.get(token));
					else
						s.push(new Double (token));
				}
			}
			return ((Double)s.pop()).doubleValue();
		} catch (Exception e) {
			return Double.NaN;
		}
	}
	
	
	public static void main (String [] args) throws IOException {
		BufferedReader kb = new BufferedReader (new InputStreamReader (System.in));
		String line;
		//blah a = new blah("1+2/3*(1+2)+2*log(2+1)");
		//blah a = new blah("2*log(2+1)");
		ExpressionParser a;
		
		while (true) {
			System.out.print ("Infix> ");
			line = kb.readLine ();
			if (line.length() == 0 ||line.charAt(0) == 'q')
				break;
			a = new ExpressionParser(line);
			System.out.println("= "+a.eval());

		}
	
	}
}