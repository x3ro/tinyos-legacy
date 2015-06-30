BEGIN{
  print "Recompile? ([y]/n)"
  getline
  if ($0 == "y" || $0 == "")
    system("make mica2");
    
  n = 0;	
  print "Ctrl-C to Exit";
    
  while(1){
    print"";
    print "----------------------------------------------------";
    print "Please put mote "n" on the programmer and push Enter \nor type - to reinstall \nor type an address to install \nor type r to recompile \nor type q to quit.";
    getline;    
    if ($0 == "r") {
      system("make mica2");
      continue;
    } else if ($0 == "-") 
      n--;    
    else if ($0 ~ /[0-9]+/) 
      n=$0;    
    else if ($0 == "q")
      exit 1
    system("make reinstall."n" mica2 mib510,/dev/ttyS0");
    n++;
  }
}

