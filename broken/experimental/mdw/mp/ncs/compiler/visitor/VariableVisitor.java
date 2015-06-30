
package ncs.compiler.visitor;

import ncs.compiler.*;
import ncs.compiler.syntaxtree.*;
import java.util.*;
import java.io.*;

// Add declared variables to environments
// Also picks up function declarations with no body

public class VariableVisitor extends DepthFirstVisitor {
  private static final boolean DEBUG = true;

  private NCSCompiler compiler;
  private boolean in_decl = false;
  private boolean in_declarator = false;
  private boolean is_function_decl = false;

  private FunctionDef cur_function = null;
  private Environment cur_env = null;
  private String vdecl_name = null;
  private Declaration vdecl_decl = null;
  private DeclarationSpecifiers vdecl_spec = null;
  private Declarator vdecl_declarator = null;
  private Initializer vdecl_init = null;
  private ParameterTypeList fdecl_arglist = null;
  private LinkedList type_spec_list = null;

  public VariableVisitor(NCSCompiler compiler) {
    this.compiler = compiler;
    this.cur_env = compiler.getTopLevelEnvironment();
  }

  public VariableVisitor(VariableVisitor parent) {
    this.compiler = parent.compiler;
    this.cur_function = parent.cur_function;
    this.cur_env = parent.cur_env;
  }

  // Set current function
  public void visit(FunctionDefinition fdef) {
    cur_function = compiler.getTopLevelEnvironment().findFunction(fdef);
    if (this.cur_function == null) {
      compiler.warn("Cannot find FunctionDef for FunctionDefinition "+fdef);
      return;
    } 
    cur_env = cur_function.getEnvironment();
  }

  // Set current environment
  // (Note that this creates a doubly nested environment for functions.
  // That's fine since we recurse up the parent, but it means that the
  // function's direct environment is always empty.)
  public void visit(CompoundStatement cs) {
    cur_env = new Environment(this.cur_env, cs);
  }

  // Find variable and function declarations 
  public void visit(Declaration decl) {
    if (DEBUG) System.err.println("Entering declaration");
    in_decl = true;

    vdecl_decl = decl;
    vdecl_spec = decl.f0;

    decl.f0.accept(this); // DeclarationSpecifiers
    decl.f1.accept(this); // InitDeclaratorList

    in_decl = false;
    if (DEBUG) System.err.println("Leaving declaration");
  }

  // Multiple variables may be declared in one Declaration but share
  // the same specs (different name and initializer)
  public void visit(InitDeclarator idecl) {
    if (!in_decl) return; // Get out if we got here from somewhere else
    vdecl_name = null;
    fdecl_arglist = null;
    is_function_decl = false;

    idecl.f0.accept(this); // Declarator

    if (is_function_decl) {
      if (DEBUG) System.err.println("-- FUNCTION DECL: "+vdecl_name);
      FunctionDef fdef = new FunctionDef(vdecl_name,
	  vdecl_decl, vdecl_spec, fdecl_arglist, null, cur_env);
      type_spec_list = null;

    } else if (type_spec_list != null && type_spec_list.contains("mirrored")) {
      if (DEBUG) System.err.println("-- MIRRORED DECL: "+vdecl_name);
      if (DEBUG) System.err.println("-- type_spec_list "+type_spec_list);
      MirroredVariableDecl mvdecl = new MirroredVariableDecl(compiler,
	  vdecl_name, vdecl_decl, vdecl_spec, type_spec_list, 
	  vdecl_declarator, vdecl_init, cur_env);
      type_spec_list = null;

    } else {
      if (DEBUG) System.err.println("-- VARIABLE DECL: "+vdecl_name);
      if (DEBUG) System.err.println("-- type_spec_list "+type_spec_list);
      VariableDecl vdecl = new VariableDecl(compiler, vdecl_name, vdecl_decl,
	  vdecl_spec, type_spec_list, vdecl_declarator, vdecl_init, cur_env);
      type_spec_list = null;
    }
  }

  public void visit(Declarator declarator) {
    if (DEBUG) System.err.println("DECLARATOR: "+TokenVisitor.getTokenString(declarator));
    if (DEBUG) System.err.println("  Entering declarator, in_decl "+in_decl);

    if (!in_decl) return; // Ignore if we got here from somewhere else
    if (in_declarator) return; // Don't recurse on declarators below us

    in_declarator = true;
    vdecl_declarator = declarator;

    // Look for id followed by "(" or "["
    try {
      Iterator it = TokenVisitor.getTokens(declarator.f1).iterator();
      NodeToken t1 = (NodeToken)it.next();
      NodeToken t2 = (NodeToken)it.next();
      vdecl_name = t1.tokenImage;
      if (!vdecl_name.equals("(") && t2 != null && t2.tokenImage.equals("(")) {
	// Found a function decl
	is_function_decl = true;
      } 
    } catch (NoSuchElementException e) {
      // Ignore
    }

    /* DirectDeclarator */
    declarator.f1.accept(this);

    in_declarator = false;
    if (DEBUG) System.err.println("  Leaving declarator");
  }

  public void visit(ParameterTypeList ptlist) {
    if (in_declarator) fdecl_arglist = ptlist;
  }

  public void visit(TypeSpecifier ts) {
    if (type_spec_list == null) type_spec_list = new LinkedList();
    type_spec_list.addAll(TokenVisitor.getTokenStrings(ts.f0));
  }

  public void visit(TypeQualifier tq) {
    if (type_spec_list == null) type_spec_list = new LinkedList();
    type_spec_list.addAll(TokenVisitor.getTokenStrings(tq.f0));
  }

  public void visit(StorageClassSpecifier scs) {
    if (type_spec_list == null) type_spec_list = new LinkedList();
    type_spec_list.addAll(TokenVisitor.getTokenStrings(scs.f0));
  }

  public void visit(Initializer init) {
    if (in_decl) vdecl_init = init;
  }

  public void visit(NodeToken id) {
    if (DEBUG) System.err.println("    VARIABLE TOKEN: "+id+" in_decl "+in_decl+" in_declarator "+in_declarator);
    if (in_declarator && vdecl_name == null) vdecl_name = id.tokenImage;
  }

}
