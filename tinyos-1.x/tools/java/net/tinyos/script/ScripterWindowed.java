/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        Jun 13 2004
 * Desc:        Main window for script injector.
 *               
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.script;

import java.awt.*;
import java.awt.event.*;
import java.awt.font.*;
import java.io.*;
import java.net.*;
import java.util.*;
import java.util.regex.*;
import javax.swing.*;
import javax.swing.border.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import net.tinyos.script.tree.*;
import vm_specific.*;

public class ScripterWindowed extends JFrame implements net.tinyos.message.MessageListener {

  private JMenuBar    menuBar;
    
  private JPanel      leftPanel;

  private JLabel      titleLabel;
    
  private JPanel      moteIDPanel;
  private JLabel      moteIDLabel;
  private JTextField   moteIDText;
    
  private JPanel      versionPanel;
  private JLabel      versionLabel;
  private JTextField  versionText;

  private JLabel      spacerLabel;
    
  private JPanel      selectionPanel;
  private JLabel      selectorLabel;
  private JLabel      optionLabel;
  private CapsuleSelector capsuleSelector;
  private OptionSelector optionsSelector;
  private VariablePanel variablePanel;
  
  private JPanel      buttonPanel;
  private JButton     injectButton;
  private JButton compileButton;
  private JButton     quitButton;
    
  private ProgramAreaPanel programPanel;

  private JPanel      fnListPanel;
  
  private MoteIF moteIF;

  private ErrorDialog dialog = null;
  private String context = "";
  private String cause = "";
  private String capsule = "";
  private String instruction = "";
    
  private ScriptAssembler assembler;
  private ScriptInjector injector;
  
  private Vector functions;
  private String configFileName;
  private String constantClassName;

  private ConstantMapper capsuleMap;
  private ConstantMapper optionMap;
  private ConstantMapper errorMap;
  private ConstantMapper opcodeMap;
  private ConstantMapper virusMap;
  
  private Configuration config;

  private ProgramState programState;
  
  public ScripterWindowed(MoteIF moteIF,
			  String configFileName,
			  String programFileName) throws Exception {
    super("TinyOS VM Scripter");

    this.moteIF = moteIF;
    
    this.configFileName = configFileName;
    this.config = loadConfiguration();
    System.out.println("Loaded configuration.");

    programState = new ProgramState(programFileName);
    System.out.println("Loaded saved scripter state.");
    
    assembler = new ScriptAssembler(config);

    Font font = TinyLook.defaultFont();
    TinyLook.setLookAndFeel(this);
    menuBar = new ScripterMenuBar(this);
    this.setJMenuBar(menuBar);
	
    variablePanel = new VariablePanel();
    
    leftPanel = new JPanel();
    leftPanel.setBorder(new EmptyBorder(10, 10, 10, 10));
    leftPanel.setAlignmentX(CENTER_ALIGNMENT);
    leftPanel.setFont(font);

    titleLabel = new JLabel("Tiny Script for " + config.vmName());
    titleLabel.setBorder(new EmptyBorder(10, 0, 10, 0));
    titleLabel.setFont(TinyLook.boldFont().deriveFont((float)14.0));
    titleLabel.setAlignmentX(CENTER_ALIGNMENT);
	
    createMotePanel();
    createVersionPanel();
    createSelectionPanel();
    createButtonPanel(TinyLook.boldFont());

    leftPanel.add(titleLabel);
    leftPanel.add(moteIDPanel);
    leftPanel.add(selectionPanel);
    leftPanel.add(variablePanel);
    leftPanel.add(buttonPanel);

    GridBagLayout layout = new GridBagLayout();
    GridBagConstraints gridConsts = new GridBagConstraints();
    gridConsts.fill = GridBagConstraints.BOTH;
    gridConsts.gridwidth = GridBagConstraints.REMAINDER;
    gridConsts.anchor = GridBagConstraints.CENTER;
	
    layout.setConstraints(titleLabel, gridConsts);
    layout.setConstraints(moteIDPanel, gridConsts);
    layout.setConstraints(selectionPanel, gridConsts);
    layout.setConstraints(buttonPanel, gridConsts);
    layout.setConstraints(variablePanel, gridConsts);
    leftPanel.setLayout(layout);

	
    programPanel = new ProgramAreaPanel();
    programPanel.setBorder(new EtchedBorder());

    fnListPanel = new FunctionListPanel();
    fnListPanel.setBorder(new EtchedBorder());
	
    getContentPane().setLayout(new GridLayout(0, 3));
	
    getContentPane().add(leftPanel);
    getContentPane().add(programPanel);
    getContentPane().add(fnListPanel);
    

    startListener();
    injector = new ScriptInjector(moteIF, virusMap);

    setVisible(true);
    pack();
    changeToCapsule(capsuleSelector.getSelected());	
    variablePanel.setVariables(SymbolTable.getSharedAndBuffers());
  }

  private Configuration loadConfiguration() throws Exception {
    Configuration configuration = null;
    functions = new Vector();
    try {
      configuration = new Configuration(configFileName);
      Enumeration funcs = configuration.functions();
      while (funcs.hasMoreElements()) {
	String fnName = (String)funcs.nextElement();
	functions.add(FunctionSet.getFunction(fnName));
      }
      constantClassName = configuration.constantClassName();
    }
    catch (Exception exception) {
      System.err.println("Could not load configuration in " + configFileName);
      exception.printStackTrace();
      throw exception;
    }
    capsuleMap = configuration.getCapsuleMap();
    optionMap = configuration.getOptionMap();
    errorMap = configuration.getErrorMap();
    opcodeMap = configuration.getOpcodeMap();
    virusMap = configuration.getVirusMap();
    
    return configuration;
  }

  /*
    catch (FileNotFoundException exception) {
      System.out.println("No program state found, instantiating.");
    }
    catch (IOException exception) {
      showError("Error reading program file: " + exception);
      exception.printStackTrace();
    }
    catch (StatementFormatException exception) {
      showError("Error reading program file: " + exception);
      exception.printStackTrace();
    }
    } */
  
  private String getType(int type) {
    return capsuleMap.codeToName((byte)type);
  }
    
  private String getCause(int cause) {
    return errorMap.codeToName((byte)cause);
  }

  protected void loadProgramFile(File file) {
    try {
      String val = "";
      String text = "";
      BufferedReader reader = new BufferedReader(new FileReader(file));
      while (val != null) {
        text += val;
        val = reader.readLine();
        if (val != null) {
          val += "\n";
        }
      }
      text += "\n";
      programPanel.setProgram(text);
    }
    catch (IOException exception) {
      showError("Error reading file: " + exception.getMessage());
    }
  }

  
  public void messageReceived(int to, Message m) {
    try {
      BombillaErrorMsg msg = (BombillaErrorMsg)m;
      String context = getType(msg.get_context());
      String cause = getCause((int)msg.get_reason());
      String capsule = getType(msg.get_capsule());
      String instruction = "" + msg.get_instruction();
      if ((!this.context.equals(context)) ||
	  (!this.cause.equals(cause)) ||
	  (!this.capsule.equals(capsule)) ||
	  (!this.instruction.equals(instruction))) {
	this.context = context;
	this.cause = cause;
	this.capsule = capsule;
	this.instruction = instruction;
	System.out.println("Error received:");
	System.out.println("  Context:     " + context);
	System.out.println("  Cause:       " + cause);
	System.out.println("  Capsule:     " + capsule);
	System.out.println("  Instruction: " + instruction);
	System.out.println();
	updateDialog(context, cause, capsule, instruction);
      }
    }
    catch (ClassCastException e) {
      System.err.println("Erroneously received a non-error message.");
      System.err.println(m);
    }
    catch (Exception e) {
      System.err.println("Exception thrown when receiving packets.");
      e.printStackTrace();
    }
  }

  private void updateDialog(String context, String cause, String capsule, String instruction) {
    Point p = null;
    if (dialog != null) {
      p = dialog.getLocation();
      dialog.dispose();
    }

    dialog = new ErrorDialog(context, cause, capsule, instruction);
    if (p != null) {
      dialog.setLocation(p);
    }
	
    dialog.show();
  }

  private String getProgramText() {return programPanel.getProgram();}
  private String getVersion() {return versionText.getText();}
  private String getSelectedContext() {return capsuleSelector.getSelected();}
  private byte   getOptions() {return (byte)optionsSelector.getOptions();}

  private void inject() {
    String program =  getProgramText();
    String handler = capsuleSelector.getSelected();
    byte options= (byte)optionsSelector.getOptions();
    int version = Integer.parseInt(getVersion());
    compileAndInject(program, handler, options, version);
  }

  private void compileAndInject(String program, String context, byte options, int version) {
    
    TinyScriptCompiler compiler = new TinyScriptCompiler(config);
    StringReader reader = new StringReader(program);
    version = version + 1;
    
    try {
      compiler.compile(reader);
      System.out.println("Sending program: " + compiler.getByteString());
      byte[] code = compiler.getBytecodes();
      byte handler = capsuleMap.nameToCode(context.toUpperCase());
      injector.inject(code, handler, options, version);
      programState.update(context, version, program, compiler.getProgram());
      variablePanel.setVariables(SymbolTable.getSharedAndBuffers());
      programState.writeState();
      changeToCapsule(context);
    }
    catch (NoProgramException e) {
      showError("Internal error, no program to compile: " + e.getMessage());
      e.printStackTrace();
    }
    catch (SemanticException e) {
      programPanel.highlightLine(e.lineNumber());
      showError("Semantic error in program: " + e.getMessage());
    }
    catch (CompileException e) {
      programPanel.highlightLine(e.lineNumber());
      showError("Compilation error: " + e.getMessage());
    }
    catch (InvalidInstructionException e) {
      showError("Compiler generated invalid instruction. Are the scripter and VM up to date? Error: " + e.getMessage());
      e.printStackTrace();
    }
    catch (IOException e) {
      showError("Error compiling program to assembly: " + e);
      e.printStackTrace();
    }
    catch (Exception e) {
      showError("Compilation error: " + e.getMessage());
      e.printStackTrace();
    }
  }
  
  protected void changeToCapsule(String capsule) {
    String version = "" + programState.getVersion(capsule);
    if (version == null || version.equals("")) {
      version = "1";
    }
    versionText.setText(version);
    if (programPanel != null) {
      programPanel.setProgram(programState.getProgram(capsule));
    }
  }
  
  private void createMotePanel() {
    moteIDPanel = new JPanel();
    moteIDPanel.setBorder(new EtchedBorder());
    moteIDPanel.setLayout(new BoxLayout(moteIDPanel, BoxLayout.X_AXIS));
    moteIDPanel.setAlignmentX(CENTER_ALIGNMENT);

    versionLabel = new JLabel("Handler Version");
    versionLabel.setBorder(new EmptyBorder(0, 10, 0, 10));
    versionLabel.setFont(TinyLook.boldFont());
    versionText = new JTextField("0", 4);
    moteIDPanel.add(versionLabel);
    moteIDPanel.add(versionText);
    versionText.setMaximumSize(new Dimension(50, 25));
    versionText.setMinimumSize(new Dimension(50, 25));
  }
    
  private void createVersionPanel() {
    versionPanel = new JPanel();
    //versionPanel.setLayout(new BoxLayout(versionPanel, BoxLayout.X_AXIS));
    //versionPanel.setBorder(new EmptyBorder(5, 0, 10, 0));
    //versionPanel.setAlignmentX(LEFT_ALIGNMENT);
	
  }

  private void createSelectionPanel() {
    selectionPanel = new JPanel();
    JPanel subLeftPanel = new JPanel();
    JPanel subRightPanel = new JPanel();

    subLeftPanel.setBorder(new EmptyBorder(10, 10, 10, 10));
    subLeftPanel.setLayout(new BoxLayout(subLeftPanel, BoxLayout.Y_AXIS));
    subRightPanel.setBorder(new EmptyBorder(10, 10, 10, 10));
    subRightPanel.setLayout(new BoxLayout(subRightPanel, BoxLayout.Y_AXIS));
    selectionPanel.setLayout(new BoxLayout(selectionPanel, BoxLayout.X_AXIS));
    selectionPanel.setBorder(new EtchedBorder());
	
    selectorLabel = new JLabel("Event Handler");
    selectorLabel.setFont(TinyLook.boldFont());
    selectorLabel.setBorder(new EmptyBorder(0, 0, 10, 0));
    capsuleSelector = new CapsuleSelector(capsuleMap, this);
    selectorLabel.setAlignmentY(TOP_ALIGNMENT);
    capsuleSelector.setAlignmentY(TOP_ALIGNMENT);
	
    optionLabel = new JLabel("Handler Options");
    optionLabel.setFont(TinyLook.boldFont());
    optionLabel.setBorder(new EmptyBorder(0, 0, 10, 0));
    optionsSelector = new OptionSelector(optionMap);
    optionLabel.setAlignmentY(TOP_ALIGNMENT);
    optionsSelector.setAlignmentY(TOP_ALIGNMENT);

    subLeftPanel.add(selectorLabel);
    subLeftPanel.add(capsuleSelector);

    //subRightPanel.add(optionLabel);
    //subRightPanel.add(options);
    
    subLeftPanel.setAlignmentY(TOP_ALIGNMENT);
    subRightPanel.setAlignmentY(TOP_ALIGNMENT);
    subRightPanel.setAlignmentX(RIGHT_ALIGNMENT);
	
    selectionPanel.add(subLeftPanel);
    selectionPanel.add(subRightPanel);
    selectionPanel.setAlignmentX(CENTER_ALIGNMENT);
  }

  private void createButtonPanel(Font font) {
    injectButton = new InjectButton(this);
    injectButton.setFont(font);
    injectButton.setAlignmentX(CENTER_ALIGNMENT);

    buttonPanel = new JPanel();
    buttonPanel.setLayout(new GridLayout(1,1));
    buttonPanel.add(injectButton);
    buttonPanel.setAlignmentX(CENTER_ALIGNMENT);
    buttonPanel.setBorder(new EtchedBorder());
  }

  private void startListener() {
    moteIF.registerListener(new BombillaErrorMsg(), this);
  }
  
  private class InjectButton extends JButton {
    
    public InjectButton(ScripterWindowed inject) {
      super("Inject");
      addActionListener(new InjectListener(inject));
      setAlignmentX(CENTER_ALIGNMENT);
    }

    private class InjectListener implements ActionListener {
      private ScripterWindowed window;
      private OptionSelector optionsSelector;
      private CapsuleSelector capsuleSelector;
      
      public InjectListener(ScripterWindowed window) {
	this.window = window;
      }

      public void actionPerformed(ActionEvent e) {
	window.inject();
      }
    }
    
  }

  private class DialogDisposeListener implements ActionListener {
    private JDialog dialog;
    public DialogDisposeListener(JDialog dialog) {
      this.dialog = dialog;
    }

    public void actionPerformed(ActionEvent e) {
      dialog.dispose();
    }
  }
  
  protected void showError(String error) {
    JDialog dialog = new JDialog(this, "Scripter Error", true);
    BorderLayout border = new BorderLayout();
    border.setHgap(20);
    border.setVgap(20);
    dialog.getContentPane().setLayout(border);

    String realError = "";
    for (int i = 0; i < error.length(); i+= 80) {
      String subStr = error.substring(i);
      if (subStr.length() > 80) {
	subStr = subStr.substring(0, 80);
      }
      subStr += "\n";
      realError += subStr;
    }
    
    JLabel label = new JLabel(realError);
    JButton b = new JButton("OK");
    b.addActionListener(new DialogDisposeListener(dialog));

    dialog.setDefaultLookAndFeelDecorated(true);
    dialog.getRootPane().setWindowDecorationStyle(JRootPane.ERROR_DIALOG);
    dialog.getContentPane().add(label, BorderLayout.NORTH);
    dialog.getContentPane().add(b, BorderLayout.SOUTH);
    dialog.pack();
    dialog.show();
  }

  protected void showWarning(String warning) {
    JDialog dialog = new JDialog(this, "Scripter Error", false);
    BorderLayout border = new BorderLayout();
    JTextArea text = new JTextArea(warning);
    text.setColumns(80);
    text.setLineWrap(true);
    text.setWrapStyleWord(true);
    text.setEditable(false);

        
    border.setHgap(20);
    border.setVgap(20);
    dialog.getContentPane().setLayout(border);

    JButton b = new JButton("OK");
    b.addActionListener(new DialogDisposeListener(dialog));

    dialog.setDefaultLookAndFeelDecorated(true);
    dialog.getRootPane().setWindowDecorationStyle(JRootPane.WARNING_DIALOG);
    dialog.getContentPane().add(text, BorderLayout.NORTH);
    dialog.getContentPane().add(b, BorderLayout.SOUTH);
    dialog.pack();
    dialog.show();
  }

  public void cleanup() {
    if (programState != null) {
      try {
	programState.writeState();
      }
      catch (IOException exception) {
	System.err.println("Could not properly save Scripter state.");
	exception.printStackTrace();
      }
    }
  }
  
}
