package ncs.compiler.visitor;

import ncs.compiler.*;
import ncs.compiler.syntaxtree.*;
import java.util.*;
import java.io.*;

// Build up a list of tokens visited while traversing a tree in depth-first 
// order
public class TokenVisitor extends DepthFirstVisitor {
  public Collection tokenList = new LinkedList();
  public Collection tokenStringList = new LinkedList();

  public void visit(NodeToken n) {
    tokenList.add(n);
    tokenStringList.add(n.tokenImage);
  }

  public static Collection getTokens(Node n) {
    TokenVisitor tv = new TokenVisitor();
    n.accept(tv);
    return tv.tokenList;
  }

  public static Collection getTokenStrings(Node n) {
    TokenVisitor tv = new TokenVisitor();
    n.accept(tv);
    return tv.tokenStringList;
  }

  public static String getTokenString(Node n) {
    Iterator it = getTokens(n).iterator();
    String s = "";
    while (it.hasNext()) {
      s += ((NodeToken)it.next()).tokenImage + " ";
    }
    return s;
  }

}
