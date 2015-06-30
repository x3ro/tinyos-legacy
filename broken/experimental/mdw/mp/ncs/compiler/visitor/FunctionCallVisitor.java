
package ncs.compiler.visitor;

import ncs.compiler.*;
import ncs.compiler.syntaxtree.*;
import java.util.*;
import java.io.*;

// Find function calls

public class FunctionCallVisitor extends DepthFirstVisitor {
  private static final boolean DEBUG = true;

  private NCSCompiler compiler;
  private boolean is_function_call = false;
  private boolean in_pfe = false;
  private boolean in_pfe_arglist = false;

  private FunctionDef cur_fdef = null;
  private String fcall_name = null;
  private ArgumentExpressionList fcall_arglist = null;

  public FunctionCallVisitor(NCSCompiler compiler) {
    this.compiler = compiler;
  }

  private FunctionCallVisitor(FunctionCallVisitor parent) {
    this.compiler = parent.compiler;
    this.cur_fdef = parent.cur_fdef;
  }

  // Track current function definition
  public void visit(FunctionDefinition fd) {
    cur_fdef = compiler.getTopLevelEnvironment().findFunction(fd);
    if (cur_fdef == null) 
      throw new CompileError("Cannot find definition of containing function "+TokenVisitor.getTokenString(fd.f1));
    fd.f3.accept(this); /* Body */
  }

  // Track current function definition
  public void visit(Periodic p) {
    cur_fdef = compiler.getTopLevelEnvironment().findFunction(p);
    if (cur_fdef == null) 
      throw new CompileError("Cannot find definition of periodic block");
    p.f4.accept(this); /* Body */
  }

  // Find function calls
  public void visit(UnaryExpression ue) {
    System.err.println("UNARY EXPRESSION: "+TokenVisitor.getTokenString(ue));
    // Recursion necessary since we may have multiple nested calls
    ue.f0.accept(new FunctionCallVisitor(this));
  }

  public void visit(PostfixExpression pfe) {
    System.err.println("POSTFIX EXPRESSION: "+TokenVisitor.getTokenString(pfe.f0)+" "+TokenVisitor.getTokenString(pfe.f1));

    fcall_name = null;
    fcall_arglist = null;
    is_function_call = false;
    /* PrimaryExpression */
    in_pfe = true; pfe.f1.accept(this); in_pfe = false;
    /* Possible arglist */
    in_pfe_arglist = true; pfe.f2.accept(this); in_pfe_arglist = false;

    if (is_function_call) {
      if (cur_fdef == null) 
	throw new CompileError("Function call "+fcall_name+" outside of function context");
      FunctionCall fcall = new FunctionCall(pfe, fcall_name, fcall_arglist, cur_fdef);
      cur_fdef.addCall(fcall);
    }
    fcall_name = null;
    fcall_arglist = null;
    is_function_call = false;
  }

  public void visit(NodeToken id) {
    //if (DEBUG) System.err.println("TOKEN: "+id.tokenImage+" in_pfe "+in_pfe);

    if (in_pfe) fcall_name = id.tokenImage;
    else if (in_pfe_arglist) {
      // First token must be "(" for function call
      in_pfe_arglist = false;
      if (id.tokenImage.equals("(")) is_function_call = true;
    }
  }

  public void visit(ArgumentExpressionList ael) {
    System.err.println("ARGUMENT EXPRESSION LIST: "+TokenVisitor.getTokenString(ael));
    if (fcall_name != null) {
      System.err.println("Setting fcall_arglist");
      fcall_arglist = ael;
    }
    ael.f0.accept(this);
  }

}
