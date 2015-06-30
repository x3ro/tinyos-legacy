from gui import *
from Comm import *
from motelist import *
from commands import *
from config import config

root.title("Field Tool")
gui = Gui(root)
if config.use_ip:
  comm = IPComm(config.sf_host, config.sf_port)
else:
  comm = SerComm(config.sf_host, config.sf_port)
receiver = Receiver(root, comm)
motes = Motelist(root, comm, receiver, gui)
command = Command(root, comm, receiver, motes)

gui.addCommand(Green(command))
gui.addCommand(Beep(command))
gui.addCommand(Reset(command))
gui.addCommand(Ping(command))

root.mainloop()

