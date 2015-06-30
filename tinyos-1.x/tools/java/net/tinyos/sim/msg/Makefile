PACKAGE = net.tinyos.sim.msg
TOS = ../../../../../../tos

MSGS = 	DebugMsgEvent.java \
	RadioMsgSentEvent.java \
	UARTMsgSentEvent.java \
	ADCDataReadyEvent.java \
	LedEvent.java \
	TossimInitEvent.java \
	TurnOnMoteCommand.java \
	TurnOffMoteCommand.java \
	RadioMsgSendCommand.java \
	UARTMsgSendCommand.java \
	SetLinkProbCommand.java \
	SetADCPortValueCommand.java \
	VariableResolveCommand.java \
	VariableResolveResponse.java \
	VariableRequestCommand.java \
	VariableRequestResponse.java \
	InterruptCommand.java \
	InterruptEvent.java \
	SetRateCommand.java \
	SetDBGCommand.java \
	SetEventMaskCommand.java \
	BeginBatchCommand.java \
	EndBatchCommand.java \

MSGCLASSES = $(MSGS:.java=.class)

all: $(MSGS) $(MSGCLASSES)

%.java: $(TOS)/platform/pc/GuiMsg.h
	mig java -target=pc -java-classname=$(PACKAGE).$* $(TOS)/platform/pc/GuiMsg.h $* -o $@

# given that a change in GuiMsg.h will trigger a rebuild of all the
# mig files anyway, might as well build them all at once since it's
# faster
%.class: %.java
	javac *.java

clean:
	rm -f $(MSGS) $(MSGCLASSES)
