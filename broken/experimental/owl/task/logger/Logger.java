import net.tinyos.task.awtfield.*;

class Logger {
    public static void main(String[] args) {
	Tool t = new Tool();

	//maybe, not on reflection. t.addCommand("clear log", new ClearCmd(t));
	t.addCommand("log status", new OffsetCmd(t));

	t.start();
    }
}

class ClearCmd extends SimpleCommand {
    ClearCmd(Tool parent) {
	super(parent, "LogClr");
    }
}

class OffsetCmd extends SimpleCommand {
    OffsetCmd(Tool parent) {
	super(parent, "LogOff");
    }

    public String result(FieldReplyMsg reply) {
	OffsetReplyMsg p = new OffsetReplyMsg(reply, reply.offset_result(0));

	return "" + p.get_count() + " bytes used";
    }
}

