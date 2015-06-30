
package ncs.compiler.visitor;

import ncs.compiler.*;
import ncs.compiler.syntaxtree.*;
import java.util.*;
import java.io.*;

// Rewrite mirrored variable accesses

public class MirroredVarVisitor extends DepthFirstVisitor {
  private static final boolean DEBUG = true;

  private NCSCompiler compiler;
  private boolean is_mv_deref = false;
  private boolean in_pfe = false;
  private boolean in_pfe_index = false;

  private Environment cur_env;
  private String mv_name = null;
  private Expression index_expr = null;
  private Node replace_expr = null;

  public MirroredVarVisitor(NCSCompiler compiler) {
    this.compiler = compiler;
    this.cur_env = compiler.getTopLevelEnvironment();
  }

  private MirroredVarVisitor(MirroredVarVisitor parent) {
    this.compiler = parent.compiler;
    this.cur_env = parent.cur_env;
  }

  // Track current function definition
  public void visit(FunctionDefinition fd) {
    FunctionDef fdef = compiler.getTopLevelEnvironment().findFunction(fd);
    if (fdef == null)
      throw new CompileError("Cannot find definition of containing function "+TokenVisitor.getTokenString(fd.f1));
    cur_env = fdef.getEnvironment();
    fd.f3.accept(this); /* Body */
  }

  // Track current function definition
  public void visit(Periodic p) {
    FunctionDef fd = compiler.getTopLevelEnvironment().findFunction(p);
    if (fd == null)
      throw new CompileError("Cannot find definition of periodic block");
    cur_env = fd.getEnvironment();
    p.f4.accept(this); /* Body */
  }

  // Find mirrored array derefs
  public void visit(UnaryExpression ue) {
    if (DEBUG) System.err.println("MVV: UNARY EXPRESSION: "+TokenVisitor.getTokenString(ue));

    // Recursion necessary since we may have multiple nested calls
    MirroredVarVisitor mvv = new MirroredVarVisitor(this);
    ue.f0.accept(mvv);
    if (mvv.replace_expr != null) ue.f0 = new NodeChoice(mvv.replace_expr, 0);
  }

  public void visit(PostfixExpression pfe) {
    if (DEBUG) System.err.println("MVV: POSTFIX EXPRESSION: "+TokenVisitor.getTokenString(pfe.f0)+" "+TokenVisitor.getTokenString(pfe.f1));

    mv_name = null;
    index_expr = null;
    is_mv_deref = false;

    /* PrimaryExpression */
    in_pfe = true; pfe.f1.accept(this); in_pfe = false;
    /* Possible index expr */
    in_pfe_index = true; pfe.f2.accept(this); in_pfe_index = false;

    if (is_mv_deref) {
      VariableDecl vd = cur_env.findVariable(mv_name);
      if (vd == null) {
	throw new CompileError("Cannot find declaration of variable: "+mv_name); }
      if (vd instanceof MirroredVariableDecl) {
	MirroredVariableDecl mvd = (MirroredVariableDecl)vd;
	if (index_expr == null) {
	  throw new CompileError("Dereference of mirrored array with no index expression: "+mv_name);
	}
	replace_expr = mvd.replaceArrayDeref(index_expr, true);
      }
    }

    mv_name = null;
    index_expr = null;
    is_mv_deref = false;
  }

  public void visit(NodeToken id) {
    //if (DEBUG) System.err.println("MVV: TOKEN: "+id.tokenImage+" in_pfe "+in_pfe);

    if (in_pfe) mv_name = id.tokenImage;
    else if (in_pfe_index) {
      // First token must be "[" for MV dereference
      in_pfe_index = false;
      if (id.tokenImage.equals("[")) is_mv_deref = true;
    }
  }

  public void visit(Expression expr) {
    if (DEBUG) System.err.println("MVV: EXPRESSION: "+TokenVisitor.getTokenString(expr));
    if (mv_name != null) {
      if (DEBUG) System.err.println("Setting index_expr");
      index_expr = expr;
    }
    expr.f0.accept(this);
    expr.f1.accept(this);
  }

}
