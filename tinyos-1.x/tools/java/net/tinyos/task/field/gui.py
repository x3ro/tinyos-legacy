from Tkinter import *
from Comm import Message
from time import *

root = Tk()

ALL = Message.BCAST

class Output:
  def __init__(self, gui, title):
    self.title = title
    self.gui = gui
    self.time = strftime('%H:%M:%S')
    self.text = {}
    self.displayed = self.first = 0
    
  def activate(self, first):
    self.displayed = 1
    self.first = first
    self.redisplay()

  def deactivate(self):
    self.displayed = 0

  def add(self, moteid, msg):
    self.text[moteid] = msg
    if self.displayed:
      self.redisplay()

  def redisplay(self):
    if self.first:
      fulltitle = self.title
      color="red"
    else:
      fulltitle = '%s @ %s' % (self.title, self.time)
      color="black"
    self.gui.o_running.config(text=fulltitle, fg=color)
    
    self.gui.o_list.config(state=NORMAL)
    self.gui.o_list.delete(1.0, END)
    motes = self.text.keys()
    motes.sort()
    for mote in motes:
      self.gui.o_list.insert(END, '%d: %s\n' % (mote, self.text[mote]))
    self.gui.o_list.config(state=DISABLED)
    

class Gui:
  maxoutput = 100
  font = "6x13"
  
  def buildDestinations(self):
    dframe = Frame(self.frame)
    dframe.grid(row=0, column=1)
    self.destinations = Listbox(dframe, width=7, height=8, font=Gui.font)
    self.destinations.pack(side=LEFT)
    self.setDestinations([])
    scrollbar = Scrollbar(dframe, command=self.destinations.yview)
    scrollbar.pack(side=RIGHT, fill=Y)
    self.destinations.config(yscrollcommand=scrollbar.set)

  def setDestinations(self, list):
    list.sort()
    oldactive = self.destinations.get(ACTIVE)
    self.destinations.delete(0, END)
    self.destinations.insert(END, 'ALL')
    for i in list:
      self.destinations.insert(END, i)
    sel=0
    if oldactive != 'ALL':
      try:
        sel = list.index(int(oldactive)) + 1
      except ValueError:
        list=list # silly python
    self.destinations.select_set(sel)
    self.destinations.activate(sel)
      
  def buildCommands(self):
    self.commands = Text(self.frame, width=26, height=10, font=Gui.font)
    self.commands.grid(row=0, column=0)

  def addCommand(self, cmd):
    def run(self=self, cmd=cmd):
      active=self.destinations.index(ACTIVE)
      if active == 0:
        dest = ALL
        title = "ALL: "
      else:
        dest = int(self.destinations.get(active))
        title = 'Mote %d: ' % dest
      cmd.run(dest, self.newoutput(title + cmd.name))
        
    button = Button(self.commands, text=cmd.name, command=run, width=21, font=Gui.font)
    self.commands.window_create(END, window=button)

  def buildOutput(self):
    oframe = Frame(self.frame, borderwidth=2, relief=RAISED)
    oframe.grid(row=1, column=0, columnspan=2)
    self.o_running = Label(oframe, width=28, font=Gui.font)
    self.o_running.grid(row=0, column=0)
    self.o_previous = Button(oframe, bitmap="@left.xbm",
                             command=self.outputprev)
    self.o_previous.grid(row=0, column=1)
    self.o_next = Button(oframe, bitmap="@right.xbm",
                         command = self.outputnext)
    self.o_next.grid(row=0, column=2)
    olframe = Frame(oframe)
    olframe.grid(row=1, column=0, columnspan=3)
    self.o_list = Text(olframe, width=33, height=8, font=Gui.font)
    self.o_list.pack(side=LEFT)
    self.o_list.config(state=DISABLED)
    scrollbar = Scrollbar(olframe, command=self.o_list.yview)
    scrollbar.pack(side=RIGHT, fill=Y)
    self.o_list.config(yscrollcommand=scrollbar.set)

  def initOutputs(self):
    self.output = []
    self.output_pos = 0
    self.outputupdate()

  def newoutput(self, title):
    o = Output(self, title)
    if len(self.output) == self.maxoutput:
      del self.output[0]
    self.output.append(o)
    self.output_pos = len(self.output) - 1
    self.outputupdate()
    return o

  def outputupdate(self):
    def buttonset(button, on):
      if on:
        button.config(state=NORMAL)
      else:
        button.config(state=DISABLED)

    buttonset(self.o_previous, self.output_pos > 0)
    if self.output == []:
      buttonset(self.o_next, 0)
      self.o_running.config(text="NO COMMAND", fg="red")
      self.o_list.config(state=NORMAL)
      self.o_list.delete(1.0, END)
      self.o_list.config(state=DISABLED)
    else:
      current = self.output_pos + 1 == len(self.output)
      buttonset(self.o_next, not current)
      self.output[self.output_pos].activate(current)

  def outputprev(self):
    if self.output_pos > 0:
      self.output_pos = self.output_pos - 1
    self.outputupdate()
  
  def outputnext(self):
    if self.output_pos < len(self.output) - 1:
      self.output_pos = self.output_pos + 1
    self.outputupdate()
  
  def __init__(self, master):
    self.root = master
    self.frame = Frame(master)
    self.frame.pack()

    self.buildDestinations()
    self.buildCommands()
    self.buildOutput()
    self.initOutputs()

