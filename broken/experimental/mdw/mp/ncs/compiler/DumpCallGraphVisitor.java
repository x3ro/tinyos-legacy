package ncs.compiler;

import java.io.*;
import java.util.*;
import ncs.compiler.syntaxtree.*;
import ncs.compiler.visitor.*;

// Visitor for dumping the call graph
public class DumpCallGraphVisitor implements CGVisitor {
  int indent = 0;
  PrintWriter pw;

  DumpCallGraphVisitor(PrintWriter pw) {
    this.pw = pw;
  }

  public void visit(FunctionDef fdef) {
    for (int i = 0; i < indent; i++) pw.print(" ");
    pw.println(fdef.getName()+"()");
    indent += 2;
    Iterator it = fdef.calls.iterator();
    while (it.hasNext()) {
      FunctionCall fcall = (FunctionCall)it.next();
      fcall.acceptVisitor(this);
    }
    indent -= 2;
  }

  public void visit(FunctionCall fcall) {
    for (int i = 0; i < indent; i++) pw.print(" ");
    //pw.println(fcall.toString());
    if (fcall.getCalledDef() == null) {
      //for (int i = 0; i < indent; i++) pw.print(" ");
      //pw.println("  <no fdef>");
    } else {
      fcall.getCalledDef().acceptVisitor(this);
    }
  }
}


