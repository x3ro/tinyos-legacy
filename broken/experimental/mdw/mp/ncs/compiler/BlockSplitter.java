package ncs.compiler;

import java.io.*;
import java.util.*;
import ncs.compiler.syntaxtree.*;
import ncs.compiler.visitor.*;

class BlockSplitter {
  private static final boolean DEBUG = false;

  private NCSCompiler compiler;

  BlockSplitter(NCSCompiler compiler) {
    this.compiler = compiler;
  }

  void splitBlockingFunctions() {
    Iterator it = compiler.getTopLevelEnvironment().functions().iterator();
    while (it.hasNext()) {
      FunctionDef fd = (FunctionDef)it.next();
      fd.acceptVisitor(new findBlockingCGVisitor());
    }
  }

  class findBlockingCGVisitor implements CGVisitor {
    boolean is_blocking = false;

    public void visit(FunctionDef fdef) {
      if (DEBUG) System.err.println(fdef+" blocking "+fdef.isBlocking()+" is_blocking "+is_blocking);
      Iterator it = fdef.calls.iterator();
      while (it.hasNext()) {
	is_blocking = false;
	FunctionCall fcall = (FunctionCall)it.next();
	fcall.acceptVisitor(this);
	if (is_blocking) {
          if (DEBUG) System.err.println("  SETTING BLOCKING: "+fdef);
	  fdef.setBlocking(true);
	}
      }
      if (fdef.isBlocking()) is_blocking = true;
      if (DEBUG) System.err.println("Done with "+fdef);
    }

    public void visit(FunctionCall fcall) {
      fcall.getCalledDef().acceptVisitor(this);
    }
  }


}
