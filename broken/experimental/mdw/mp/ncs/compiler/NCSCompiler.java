package ncs.compiler;

import java.io.*;
import java.util.*;
import ncs.compiler.syntaxtree.*;
import ncs.compiler.visitor.*;

public class NCSCompiler {

  private static final boolean DEBUG = true;

  private Node ast;
  private String moduleName;
  private Environment topLevelEnvironment = new Environment();
  private Set requires = new HashSet();
  private Hashtable neighborhoods = new Hashtable();

  NCSCompiler(Node astRoot, String moduleName) {
    this.ast = astRoot;
    this.moduleName = moduleName;
    compile();
  }

  public String getModuleName() {
    return moduleName;
  }

  public void addRequires(RequiredIF req) {
    requires.add(req);
  }

  public Environment getTopLevelEnvironment() {
    return topLevelEnvironment;
  }

  public void warn(String msg) {
    System.err.println("NCS: warning: "+msg);
  }

  /* Static functions ***********************************************/
  static public void printExpression(PrintWriter ps, Expression expr) {
    CodePrinter cp = new CodePrinter(ps, 0);
    expr.accept(new TreeFormatter());
    cp.startAtNextToken();
    expr.accept(cp);
  }

  static public String exprString(Expression expr) {
    StringWriter sw = new StringWriter();
    CodePrinter cp = new CodePrinter(sw, 0);
    expr.accept(new TreeFormatter());
    cp.startAtNextToken();
    expr.accept(cp);
    return sw.toString();
  }

  static Node generateTree(String s) throws ParseException {
    StringReader sr = new StringReader(s);
    NCSParser.ReInit(sr);
    return NCSParser.Expression();
  }

  /* Internal functions ***********************************************/

  private void compile() {
    if (DEBUG) System.err.println("\n*** FunctionVisitor");
    ast.accept(new FunctionVisitor(this));
    if (DEBUG) System.err.println("\n*** VariableVisitor");
    ast.accept(new VariableVisitor(this));
    if (DEBUG) System.err.println("\n*** FunctionCallVisitor");
    ast.accept(new FunctionCallVisitor(this));
    if (DEBUG) System.err.println("\n*** MirroredVarVisitor");
    ast.accept(new MirroredVarVisitor(this));

    if (DEBUG) System.err.println("\n*** makeRequires");
    makeRequires();
    makeCallGraph();
    dumpCallGraph(new PrintWriter(System.err));
    System.err.println("\n\n");

    //if (DEBUG) System.err.println("\n*** splitBlockingFunctions");
    //splitBlockingFunctions();



  }

  void dumpModule(Writer w) {
    // Preamble
    PrintWriter ps = new PrintWriter(w);
    ps.println("module "+moduleName+" {");
    ps.println("  provides {");
    ps.println("    interface StdControl;");
    ps.println("  }");
    if (requires.size() != 0) {
      ps.println("  requires {");
      Iterator it = requires.iterator();
      while (it.hasNext()) {
	RequiredIF req = (RequiredIF)it.next();
	ps.println("    interface "+req.ifname+" as "+req.asifname+";");
      }
      ps.println("  }");
    }
    ps.println("} implementation {");

    // Initializers
    dumpInit(ps);

    CodePrinter cp = new CodePrinter(ps);

    // Declarations
    Iterator it = topLevelEnvironment.variables().iterator();
    while (it.hasNext()) {
      VariableDecl vd = (VariableDecl)it.next();
      vd.output(ps);
      ps.print("\n");
    }

    // Functions
    it = topLevelEnvironment.functions().iterator();
    while (it.hasNext()) {
      FunctionDef fdef = (FunctionDef)it.next();
      fdef.output(ps);
    }

    ps.println("\n}");
    ps.flush();
  }

  void dumpConfiguration(OutputStream o) {
  }

  private void dumpInit(PrintWriter ps) {
    ps.println("  command result_t StdControl.init() {");
    ps.println("    return SUCCESS;");
    ps.println("  }");

    ps.println("  command result_t StdControl.start() {");

    // Neighborhood init
    Iterator it = neighborhoods.values().iterator();
    while (it.hasNext()) {
      Neighborhood nh = (Neighborhood)it.next();
      nh.outputInit(ps);
    }

    // Periodic init
    it = topLevelEnvironment.functions().iterator();
    while (it.hasNext()) {
      Object n = it.next();
      if (n instanceof PeriodicDef) {
	PeriodicDef pdef = (PeriodicDef)n;
	pdef.outputInit(ps);
      }
    }
    ps.println("    return SUCCESS;");
    ps.println("  }");

    ps.println("  command result_t StdControl.stop() {");
    ps.println("    return SUCCESS;");
    ps.println("  }");
  }

  private void makeRequires() {
    Iterator it = topLevelEnvironment.functions().iterator();
    while (it.hasNext()) {
      Object n = it.next();
      if (n instanceof PeriodicDef) {
	PeriodicDef pdef = (PeriodicDef)n;
	addRequires(pdef.getRequires());
      }
    }
  }

  private void makeCallGraph() {
    Iterator it = topLevelEnvironment.functions().iterator();
    while (it.hasNext()) {
      FunctionDef fd = (FunctionDef)it.next();
      fd.resolveCalls(topLevelEnvironment);
    }
  }

  /**
   * Visit each function in the toplevel environment
   */
  public void visitCallGraph(CGVisitor visitor) {
    Iterator it = topLevelEnvironment.functions().iterator();
    while (it.hasNext()) {
      FunctionDef fd = (FunctionDef)it.next();
      fd.acceptVisitor(visitor);
    }
  }

  public void dumpCallGraph(PrintWriter ps) {
    System.err.println("\nDumping call graph...");
    visitCallGraph(new DumpCallGraphVisitor(new PrintWriter(System.err)));
    System.err.println("\nDone with call graph.\n");
  }

  public Neighborhood getNeighborhood(String name) {
    if (neighborhoods.get(name) == null) {
      neighborhoods.put(name, new Neighborhood(name, topLevelEnvironment));
    }
    return (Neighborhood)neighborhoods.get(name);
  }

  private void splitBlockingFunctions() {
    // First rewrite variables
    if (DEBUG) System.err.println("\n*** GSRVisitor");
    ast.accept(new GSRVisitor(this));
    BlockSplitter bs = new BlockSplitter(this);
    bs.splitBlockingFunctions();
  }



}
