package ncs.compiler;

import ncs.compiler.syntaxtree.*;
import java.util.*;

public class Environment {

  private Environment parent;
  private LinkedHashMap functions = new LinkedHashMap();
  private LinkedHashMap variables = new LinkedHashMap();
  private LinkedHashMap nestedEnv = new LinkedHashMap();

  /**
   * Create a new top-level environment.
   */
  public Environment() {
    this.parent = null;
  }

  /**
   * Create a new environment for the given Node, with
   * the given environment as its parent.
   */
  public Environment(Environment parent, Node pnode) {
    this.parent = parent;
    parent.addNestedEnvironment(this, pnode);
  }

  // Add a nested environment corresponding to the given Node
  private void addNestedEnvironment(Environment child, Node cnode) {
    nestedEnv.put(cnode, child);
  }

  /**
   * Return the nested environment corresponding to the given 
   * Node.
   */
  public Environment getNestedEnvironment(Node cnode) {
    return (Environment)nestedEnv.get(cnode);
  }

  public void addFunction(FunctionDef fdef) {
    // XXX Check for conflicting definition in parent?
    if (functions.get(fdef.getName()) != null) {
      throw new CompileError("Function `"+fdef.getName()+"' already defined");
    }
    functions.put(fdef.getName(), fdef);
  }

  public void addVariable(VariableDecl vdecl) {
    // XXX Check for conflicting definition in parent?
    if (variables.get(vdecl.getName()) != null) {
      throw new CompileError("Variable `"+vdecl.getName()+"' already declared");
    }
    variables.put(vdecl.getName(), vdecl);
  }

  public FunctionDef findFunction(String name) {
    FunctionDef fdef = (FunctionDef)functions.get(name);
    if (fdef == null && parent != null) {
      return parent.findFunction(name);
    }
    return fdef;
  }

  // Map from FunctionDefinition to the corresponding FunctionDef
  // MDW - Should have a hashtable map here
  public FunctionDef findFunction(FunctionDefinition fdef) {
    Iterator it = functions.values().iterator();
    while (it.hasNext()) {
      FunctionDef fd = (FunctionDef)it.next();
      if (fd.getASTDefinition().equals(fdef)) {
	return fd;
      }
    }
    if (parent != null) return parent.findFunction(fdef);
    return null;
  }

  // Map from Periodic to the corresponding FunctionDef
  // MDW - Should have a hashtable map here
  public FunctionDef findFunction(Periodic p) {
    Iterator it = functions.values().iterator();
    while (it.hasNext()) {
      FunctionDef fd = (FunctionDef)it.next();
      if (fd.getASTDefinition().equals(p)) {
	return fd;
      }
    }
    if (parent != null) return parent.findFunction(p);
    return null;
  }

  public Collection functions() {
    return functions.values();
  }

  public VariableDecl findVariable(String name) {
    VariableDecl vdecl = (VariableDecl)variables.get(name);
    if (vdecl == null && parent != null) {
      return parent.findVariable(name);
    }
    return vdecl;
  }

  public Collection variables() {
    return variables.values();
  }

}
