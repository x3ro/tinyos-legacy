package ncs.compiler;

import java.io.*;
import java.util.*;
import ncs.compiler.syntaxtree.*;
import ncs.compiler.visitor.*;

public class VariableDecl {

  private static final boolean DEBUG = true;

  protected String name;
  protected Declaration decl;
  protected DeclarationSpecifiers spec;
  protected Collection type_spec_list;
  protected Declarator declarator;
  protected Initializer init;
  protected Environment env;
  protected boolean is_global = false;
  protected LinkedHashMap refs = new LinkedHashMap();

  public VariableDecl(NCSCompiler compiler, String name, Declaration decl, 
      DeclarationSpecifiers spec, Collection type_spec_list,
      Declarator declarator, Initializer init, Environment env) {
    this.name = name;
    this.decl = decl; 
    this.spec = spec;
    this.type_spec_list = type_spec_list;
    this.declarator = declarator;
    this.init = init;
    this.env = env;
    this.env.addVariable(this);
    if (DEBUG) System.err.println("Creating VariableDecl: "+name);
  }

  public String getName() {
    return name;
  }

  public Environment getEnvironment() {
    return env;
  }

  public String toString() {
    return "VariableDecl '"+name+"'";
  }

  public void output(PrintWriter ps) {
    CodePrinter cp = new CodePrinter(ps);
    cp.startAtNextToken();
    decl.accept(cp);
  }

  public void setGlobal(boolean global) {
    this.is_global = global;
  }

  public boolean isGlobal() {
    return is_global;
  }

  void addRef(VariableRef vr) {
    refs.put(vr.getExpr(), vr);
  }

}
