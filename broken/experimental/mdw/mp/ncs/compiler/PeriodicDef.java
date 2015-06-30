package ncs.compiler;

import java.io.*;
import java.util.*;
import ncs.compiler.syntaxtree.*;
import ncs.compiler.visitor.*;

public class PeriodicDef extends FunctionDef {
  private static final boolean DEBUG = true;

  protected static int pb_count = 0;
  protected UnaryExpression rate_expr;

  public PeriodicDef(Periodic p, UnaryExpression rate_expr, CompoundStatement body,
      Environment parentEnv) {
    this.name = "_periodic_block"+pb_count;
    pb_count++;
    this.ast_def = p;
    this.rate_expr = rate_expr;
    this.body = body;
    this.specs = null;
    this.arglist = null;
    this.env = new Environment(parentEnv, p);
    parentEnv.addFunction(this);
    if (DEBUG) System.err.println("Creating Periodic: "+name+"()");
  }

  public UnaryExpression getRateExpr() {
    return rate_expr;
  }

  public RequiredIF getRequires() {
    return new RequiredIF("Timer", "Timer_"+name);
  }

  public void output(PrintWriter ps) {
    ps.println("\n  /* PeriodicDef: blocking: "+is_blocking+" */");
    ps.println("  event result_t Timer_"+name+".fired() {");
    CodePrinter cp = new CodePrinter(ps, CodePrinter.INDENT*2);
    cp.startAtNextToken();
    body.accept(cp);
    ps.println("\n    return SUCCESS;");
    ps.println("  }\n\n");
  }

  public void outputInit(PrintWriter ps) {
    ps.print("    call Timer_"+name+".start(TIMER_REPEAT, (");
    CodePrinter cp = new CodePrinter(ps, 0);
    rate_expr.accept(new TreeFormatter());
    cp.startAtNextToken();
    rate_expr.accept(cp);
    ps.println("));");
  }
  
  public String toString() {
    return "Periodic '"+name+"()'";
  }

}
