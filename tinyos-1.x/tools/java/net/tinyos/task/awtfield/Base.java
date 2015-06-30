package net.tinyos.task.awtfield;

class Base {
    public static void main(String[] args) {
	Tool t = new Tool();

	// Adding a command, e.g., GreenCmd (blink green leds) would look
	// like this:
	//t.addCommand("green", new GreenCmd(t));

	t.start();
    }
}
