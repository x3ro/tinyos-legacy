
package ncs.compiler.visitor;

import ncs.compiler.*;
import ncs.compiler.syntaxtree.*;
import java.util.*;
import java.io.*;

// Find function definitions and declarations

public class FunctionVisitor extends DepthFirstVisitor {
  private static final boolean DEBUG = true;

  private NCSCompiler compiler;
  private boolean in_fd_spec = false;
  private boolean in_fd_decl = false;
  private boolean in_fd_decl_direct_name = false;
  private boolean in_fd_decl_direct_args = false;

  private String fdef_name = null;
  private Node fdef_astroot = null;
  private DeclarationSpecifiers fdef_specs = null;
  private ParameterTypeList fdef_arglist = null;
  private CompoundStatement fdef_body = null;

  private Environment cur_env;

  public FunctionVisitor(NCSCompiler compiler) {
    this.compiler = compiler;
    this.cur_env = compiler.getTopLevelEnvironment();
  }

  // Find function definitions
  public void visit(FunctionDefinition fd) {

    fdef_name = null;
    fdef_astroot = fd; /* This node */
    fdef_specs = null;
    fdef_arglist = null;
    fdef_body = fd.f3; /* Body */

    /* DeclarationSpecifiers */
    in_fd_spec = true; fd.f0.accept(this); in_fd_spec = false;
    /* Declarator (name plus args) */
    in_fd_decl = true; fd.f1.accept(this); in_fd_decl = false;

    if (fdef_name == null) {
      throw new CompileError("Function definition has no associated identifier for function name!");
    }
    if (DEBUG) System.err.println("-- FUNCTION DEF: "+fdef_name);
    new FunctionDef(fdef_name, fdef_astroot, fdef_specs, 
	fdef_arglist, fdef_body, cur_env);
  }

  // Build function definition for periodic blocks
  public void visit(Periodic p) {
    new PeriodicDef(p, p.f2 /* Rate */, p.f4 /* Body */, cur_env);
  }

  public void visit(DeclarationSpecifiers specs) {
    if (in_fd_spec) fdef_specs = specs;
  }

  public void visit(DirectDeclarator dd) {
    if (in_fd_decl) {
      in_fd_decl_direct_name = true; 
      dd.f0.accept(this); /* Name */
      in_fd_decl_direct_name = false;
      in_fd_decl_direct_args = true; 
      dd.f1.accept(this); /* Args */
      in_fd_decl_direct_args = false;
    }
  }

  public void visit(ParameterTypeList ptlist) {
    if (in_fd_decl_direct_args) fdef_arglist = ptlist;
  }

  public void visit(NodeToken id) {
    //if (DEBUG) System.err.println("TOKEN: "+id.tokenImage+" in_pfe "+in_pfe);
    if (in_fd_decl_direct_name) fdef_name = id.tokenImage;
  }

}
