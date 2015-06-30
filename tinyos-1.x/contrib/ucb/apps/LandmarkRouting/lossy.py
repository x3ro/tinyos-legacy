from simcore import *

if not sim.__driver.pluginManager.getPlugin("RadioModelGuiPlugin").isRegistered():
  print "Please create radio model first using the Radio Model Plugin."

else:  
    
    pf = open('packet','w')
    space = ' '
    end = ' 0.0 0.0\n'
    
    for i in motes:
        for j in motes:
            s = str(i.getID()) + space + str(j.getID()) + space
            if i.getID() == j.getID():
                continue
            elif i.getID() == 1 or i.getID() == 0:
                continue
            elif j.getID() == 1 or j.getID() == 0:
                continue
            elif radio.getLossRate(i.getID(), j.getID()) < 1.0:
                s += str(radio.getLossRate(i.getID(),j.getID())) + end
                pf.write(s)
    pf.flush()
    pf.close()
