package ncs.compiler;

import java.io.*;
import java.util.*;
import ncs.compiler.syntaxtree.*;
import ncs.compiler.visitor.*;

public class MirroredVariableDecl extends VariableDecl {

  private static final boolean DEBUG = true;

  protected static int mvd_count = 0;
  protected String sv_name;
  protected Neighborhood neighborhood;

  public MirroredVariableDecl(NCSCompiler compiler, String name, 
      Declaration decl, DeclarationSpecifiers spec, Collection type_spec_list,
      Declarator declarator, Initializer init, Environment env) {
    super(compiler, name, decl, spec, type_spec_list, declarator, init, env);

    this.sv_name = "_sv_"+mvd_count+"_"+name;
    mvd_count++;
    this.neighborhood = null;
    Iterator it = type_spec_list.iterator();
    while (it.hasNext()) {
      String ts = (String)it.next();
      if (ts == Neighborhood.NEIGHBORHOOD_ONEHOP ||
	  ts == Neighborhood.NEIGHBORHOOD_YAO) {
	this.neighborhood = compiler.getNeighborhood(ts);
      } 
    }
    if (this.neighborhood == null) 
      this.neighborhood = compiler.getNeighborhood(Neighborhood.NEIGHBORHOOD_ONEHOP);

    if (DEBUG) System.err.println("Creating MirroredVariableDecl: "+name);
  }

  public String toString() {
    return "MirroredVariableDecl '"+name+"'";
  }

  /**
   * Emit an AST subtree for dereferencing this mirrored var with the 
   * given index expression
   */
  public Node replaceArrayDeref(Expression index_expr, boolean block) {
    String s = "call "+sv_name+".get("+neighborhood.indexString(index_expr);
    s += ", &("+name+"["+NCSCompiler.exprString(index_expr)+"])";
    s += ", sizeof("+name+"["+NCSCompiler.exprString(index_expr)+"])";
    if (block) 
      s += ", "+neighborhood.getTimeout()+");";
    else 
      s += ", 0);";

    try {
      return NCSCompiler.generateTree(s);
    } catch (ParseException pe) {
      throw new CompileError("Cannot parse replaced expression: "+s);
    }
  }

}
