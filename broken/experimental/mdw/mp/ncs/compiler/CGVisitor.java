package ncs.compiler;

/** 
 * Visitor interface for traversing the call graph.
 */
public interface CGVisitor {

  public void visit(FunctionDef fdef);
  public void visit(FunctionCall fcall);

}
