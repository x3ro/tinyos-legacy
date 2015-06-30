
package ncs.compiler.visitor;

import ncs.compiler.*;
import ncs.compiler.syntaxtree.*;
import java.util.*;
import java.io.*;

// Find all variable references spanning a blocking call and add to the GSR

public class GSRVisitor extends DepthFirstVisitor {
  private static final boolean DEBUG = true;

  private NCSCompiler compiler;
  private FunctionDef cur_function = null;
  private Environment toplevel_env = null;
  private Environment cur_env = null;
  private LinkedHashMap vrefs = new LinkedHashMap();

  public GSRVisitor(NCSCompiler compiler) {
    this.compiler = compiler;
    this.toplevel_env = this.cur_env = compiler.getTopLevelEnvironment();
  }

  // Set current function
  public void visit(FunctionDefinition fdef) {
    cur_function = compiler.getTopLevelEnvironment().findFunction(fdef);
    if (this.cur_function == null) {
      throw new CompileError("Cannot find FunctionDef for FunctionDefinition "+fdef);
    } 
    cur_env = cur_function.getEnvironment();
  }

  // Set current environment
  public void visit(CompoundStatement cs) {
    Environment orig_env = cur_env;
    cur_env = orig_env.getNestedEnvironment(cs);
    if (cur_env == null) {
      throw new CompileError("Cannot find environment for nested compound statement "+cs);
    }
    cs.f0.accept(this);
    cs.f1.accept(this);
    cs.f2.accept(this);
    cs.f3.accept(this);
    cur_env = orig_env;
  }

  // Look for a blocking function call
  public void visit(PostfixExpression pfe) {
    FunctionCall fcall = FunctionCall.getFunctionCall(pfe);
    if (fcall != null) {
      if (fcall.getCalledDef().isBlocking()) {
	// Mark all VariableRefs as potentially crossing
	Iterator it = vrefs.values().iterator();
	while (it.hasNext()) {
	  VariableRef vr = (VariableRef)it.next();
	  vr.maycross = true;
	}
      }
    }
    pfe.f1.accept(this);
    pfe.f2.accept(this);
  }

  // Look for a variable access - node must contain identifier
  public void visit(PrimaryExpression pe) {
    if (pe.f0.choice instanceof NodeToken) {
      NodeToken nt = (NodeToken)pe.f0.choice;

      // Lookup in toplevel env first
      VariableDecl vd = toplevel_env.findVariable(nt.tokenImage);
      if (vd == null) {
	// Not a global variable
	vd = cur_env.findVariable(nt.tokenImage);
	if (vd != null) {
	  // Not a function call
	  if (DEBUG) System.err.println("Found local variable ref: "+nt);
	  VariableRef vr = (VariableRef)vrefs.get(pe);
	  if (vr == null) {
	    vrefs.put(pe, new VariableRef(vd, pe));
	  } else {
	    // If we have already crossed a blocking call, mark as in GSR
	    if (DEBUG) System.err.println("Variable ref "+nt.tokenImage+" crosses blocking call");
	    if (vr.maycross) vd.setGlobal(true);
	  }
	}
      }
    }

    pe.f0.accept(this);
  }

}
