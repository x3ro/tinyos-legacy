package ncs.compiler;

import java.io.*;
import java.util.*;
import ncs.compiler.syntaxtree.*;
import ncs.compiler.visitor.*;

public class FunctionDef {
  private static final boolean DEBUG = true;

  protected String name;
  protected Node ast_def;
  protected DeclarationSpecifiers specs;
  protected ParameterTypeList arglist;
  protected CompoundStatement body;
  protected Collection calls = new LinkedList();
  protected Environment env;
  protected boolean is_blocking = false;

  // For subclasses only
  protected FunctionDef() {
  }

  public FunctionDef(String name, Node ast_def,
      DeclarationSpecifiers specs, ParameterTypeList arglist, 
      CompoundStatement body, Environment parentEnv) {
    this.name = name;
    this.ast_def = ast_def;
    this.specs = specs; 
    this.arglist = arglist;
    this.body = body;
    this.env = new Environment(parentEnv, ast_def);
    if (isBlocking(specs)) this.is_blocking = true;
    parentEnv.addFunction(this);
    if (DEBUG) System.err.println("Creating FunctionDef: "+name+"()");
  }

  public void addCall(FunctionCall fcall) {
    calls.add(fcall);
  }

  void resolveCalls(Environment env) {
    Iterator it = calls.iterator();
    while (it.hasNext()) {
      FunctionCall fcall = (FunctionCall)it.next();
      if (DEBUG) System.err.println("Resolving call from "+this.name+"() to "+fcall.getName()+"()");
      FunctionDef fdef = env.findFunction(fcall.getName());
      if (fdef == null) throw new CompileError("Cannot resolve call to function "+fcall.getName());
      fcall.setCalledDef(fdef);
    }
  }

  public String getName() {
    return name;
  }

  public Environment getEnvironment() {
    return env;
  }

  public Node getASTDefinition() {
    return ast_def;
  }

  public CompoundStatement getBody() {
    return body;
  }

  public void setBlocking(boolean blocking) {
    this.is_blocking = blocking;
  }

  public boolean isBlocking() {
    return is_blocking;
  }

  // Visitor to test if DeclarationSpecifiers includes a blocking ID
  class testBlockingVisitor extends DepthFirstVisitor {
    boolean in_scs = false;
    boolean is_blocking;
    public void visit(StorageClassSpecifier scs) {
      in_scs = true; scs.f0.accept(this); in_scs = false;
    }
    public void visit(NodeToken nt) {
      if (in_scs && nt.tokenImage.equals("blocking")) is_blocking = true;
    }
  }

  private boolean isBlocking(DeclarationSpecifiers specs) {
    testBlockingVisitor v = new testBlockingVisitor();
    specs.accept(v);
    return v.is_blocking;
  }
  
  public String toString() {
    return "FunctionDef '"+name+"()'";
  }

  public void output(PrintWriter ps) {
    ps.println("  /* FunctionDef: blocking: "+is_blocking+" */");
    //TreeFormatter tf = new TreeFormatter();
    //ast_def.accept(tf);
    CodePrinter cp = new CodePrinter(ps);
    cp.startAtNextToken(); 
    ast_def.accept(cp);
    ps.println("\n");
  }

  public void acceptVisitor(CGVisitor visitor) {
    visitor.visit(this);
  }

  void dumpCallGraph(PrintWriter ps) {
    acceptVisitor(new DumpCallGraphVisitor(ps));
  }
}
