PACKAGE = net.tinyos.sim.msg
TOS =  ../../../../../../tos

MSGS = DebugMsgEvent.java RadioMsgSentEvent.java UARTMsgSentEvent.java ADCDataReadyEvent.java TurnOnMoteCommand.java TurnOffMoteCommand.java RadioMsgSendCommand.java UARTMsgSendCommand.java SetLinkProbCommand.java SetADCPortValueCommand.java TossimInitEvent.java VariableRequestCommand.java VariableResolveCommand.java VariableValueEvent.java VariableResolveEvent.java SimulationPauseCommand.java SimulationPausedEvent.java SetRateCommand.java LedEvent.java SetDBGCommand.java

MSGCLASSES = $(MSGS:.java=.class)

all: $(MSGS) $(MSGCLASSES)

%.java:
	mig java -target=pc -java-classname=$(PACKAGE).$* $(TOS)/platform/pc/GuiMsg.h $* -o $@

%.class: %.java
	javac $<

clean:
	rm -f $(MSGS) $(MSGCLASSES)
