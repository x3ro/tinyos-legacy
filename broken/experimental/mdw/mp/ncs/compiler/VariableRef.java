package ncs.compiler;

import java.io.*;
import java.util.*;
import ncs.compiler.syntaxtree.*;
import ncs.compiler.visitor.*;

public class VariableRef {

  private static final boolean DEBUG = true;

  private VariableDecl vdecl;
  private PrimaryExpression expr;
  public boolean maycross; // May cross blocking boundary

  public VariableRef(VariableDecl vdecl, PrimaryExpression expr) {
    this.vdecl = vdecl;
    this.expr = expr;
    vdecl.addRef(this);
  }
      
  public String toString() {
    return "VariableRef '"+vdecl.getName()+"'";
  }

  public VariableDecl getDecl() {
    return vdecl;
  }

  public PrimaryExpression getExpr() {
    return expr;
  }

}
