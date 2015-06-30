MIG = mig java

EventListen.class: ReportMsg.java EventListen.java
	javac EventListen.java

ReportMsg.java: ../eventreport.h
	$(MIG) -java-classname=ReportMsg ../eventreport.h eventreport -o ReportMsg.java

clean:
	rm ReportMsg.java *.class
