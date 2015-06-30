package ncs.compiler;
import ncs.compiler.syntaxtree.*;
import ncs.compiler.visitor.*;

public class Main {

  private static void usage() {
    System.err.println("Usage: ncs <filename>");
    System.exit(-1);
  }

  public static void main(String args[]) {
    NCSParser parser;

    try {
      if (args.length == 0) {
	parser = new NCSParser(System.in);
      } else if (args.length == 1) {
	parser = new NCSParser(new java.io.FileReader(args[0]));
      } else {
	usage();
	return;
      }
    } catch (Exception e) {
      System.err.println("Got exception: "+e.getMessage());
      usage();
      return;
    }

    try {
      Node root = parser.TranslationUnit();
      NCSCompiler compiler = new NCSCompiler(root, "NCSProgram");
      compiler.dumpModule(new java.io.PrintWriter(System.out));
    }
    catch (ParseException e) {
      System.err.println("Encountered errors during parse: "+e.getMessage());
    }
  }
}
