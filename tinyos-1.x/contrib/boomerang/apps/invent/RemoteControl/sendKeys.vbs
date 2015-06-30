set stdin = WScript.StdIn
set stdout = WScript.StdOut
set WshShell = WScript.CreateObject("WScript.Shell")

Do While Not stdin.AtEndOfStream
  text = stdin.ReadLine
  WshShell.SendKeys text
Loop
  
