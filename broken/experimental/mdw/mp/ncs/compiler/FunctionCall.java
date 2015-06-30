package ncs.compiler;

import java.util.*;
import ncs.compiler.syntaxtree.*;

public class FunctionCall {

  private static final boolean DEBUG = true;

  private PostfixExpression expr;
  private String name; 
  private ArgumentExpressionList arglist;
  private FunctionDef parent_fdef;
  private FunctionDef called_fdef;

  private static final LinkedHashMap all_fcalls = new LinkedHashMap();

  public FunctionCall(PostfixExpression expr, String name, ArgumentExpressionList arglist, FunctionDef parent_fdef) {
    this.expr = expr;
    this.name = name;
    this.arglist = arglist;
    this.parent_fdef = parent_fdef;
    all_fcalls.put(expr, this);
    if (DEBUG) System.err.println("Creating FunctionCall: "+name+"() from "+parent_fdef.getName()+"()");
  }

  public void setCalledDef(FunctionDef called_fdef) {
    this.called_fdef = called_fdef;
  }

  public FunctionDef getCalledDef() {
    return called_fdef;
  }

  public void acceptVisitor(CGVisitor visitor) {
    visitor.visit(this);
  }

  public String getName() {
    return name;
  }

  public String toString() {
    return "FunctionCall '"+name+"()'";
  }

  /**
   * Returns the function call (if any) corresponding to this 
   * PostfixExpression.
   */
  public static FunctionCall getFunctionCall(PostfixExpression pfe) {
    return (FunctionCall)all_fcalls.get(pfe);
  }

}
