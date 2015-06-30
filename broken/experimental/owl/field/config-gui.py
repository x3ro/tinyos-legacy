from Tkinter import *
from config import *
from pickle import *

class Gui:
  font = "6x13"

  def labeledEntry(self, title):
    title = title + ":"
    l = Label(self.frame, text=title, font=self.font)
    l.grid(row=self.row, sticky=E)
    e = Entry(self.frame, font=self.font)
    e.grid(row=self.row, column=1)
    self.row = self.row + 1
    return (e, l)

  def configLabel(self, title, field, isint=1):
    (entry, label) = self.labeledEntry(title)
    entry.insert(END, config.__dict__[field])
    self.fields[field] = (entry, isint, title, label)

  def blankRow(self):
    msg = Label(self.frame, text="", font=self.font)
    msg.grid(row=self.row, columnspan=2)
    self.row = self.row + 1
    return msg

  def choices(self, list, current):
    v = IntVar()
    cframe = Frame(self.frame)
    cframe.grid(row=self.row, columnspan=2)
    self.row = self.row + 1
    idx = 1
    for choice in list:
      rb = Radiobutton(cframe, text=choice[0], command=choice[1], value=idx)
      rb.grid(row=0, column=idx)
      if idx == current:
        rb.select()
      idx = idx + 1

  def defs(self):
    config = Config()
    for field in self.fields.keys():
      entry = self.fields[field][0]
      entry.delete(0, END)
      entry.insert(END, config.__dict__[field])
      
  def save(self):
    for field in self.fields.keys():
      (entry, isint, title, label) = self.fields[field]
      val = entry.get()
      if isint:
        try:
          val = int(val)
        except:
          self.msg.config(text=title + " must be an integer")
          return
      config.__dict__[field] = val
      
    cf = open("field.config", "w+")
    dump(config, cf)
    cf.close()
    self.root.quit()
    return

  def configField(self, name, newState):
    self.fields[name][0].config(state=newState)
    # Not all versions support state on labels
    if newState == DISABLED:
      colour = "darkgrey"
    else:
      colour = "black"
    self.fields[name][3].config(fg=colour)

  def choose_ser(self):
    config.use_ip = 0
    #self.configField("sf_port", DISABLED)

  def choose_ip(self):
    config.use_ip = 1
    #self.configField("sf_port", NORMAL)

  def __init__(self, root):
    self.row = 0
    self.fields = {}
    self.root = root
    self.frame = Frame(root)
    self.frame.pack()
        
    root.title("Field Configuration")
    self.choices((("Serial", self.choose_ser), ("IP", self.choose_ip)), config.use_ip + 1)
    self.configLabel("Host/Serial", "sf_host", 0)
    self.configLabel("Port/Baud", "sf_port")
    self.configLabel("Group", "group")
    self.configLabel("Local Id", "local_id")
    self.configLabel("Msg Size", "msg_size")
    self.blankRow()
    self.configLabel("Command Period", "send_period")
    self.configLabel("Command Count", "send_count")
    self.configLabel("Wakeup Period", "wakeup_period")
    self.configLabel("Mote Timeout", "mote_timeout")
    self.msg = self.blankRow()
    bframe = Frame(self.frame)
    bframe.grid(row=self.row, columnspan=2)
    Button(bframe, text="Save", command=self.save).grid(row=0, column=0)
    Button(bframe, text="Defaults", command=self.defs).grid(row=0, column=1)
    Button(bframe, text="Cancel", command=root.quit).grid(row=0, column=2)

    if config.use_ip:
      self.choose_ip()
    else:
      self.choose_ser()
    
root = Tk()
Gui(root)
root.mainloop()
