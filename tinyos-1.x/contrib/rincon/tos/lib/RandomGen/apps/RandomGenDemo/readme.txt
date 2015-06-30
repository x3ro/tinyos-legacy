Make sure you select the right flash type in the Makefile!

/**
 * This demo shows that the RandomGen component
 * will update the seed stored on non-volatile
 * memory every RANDOMGEN_STORAGE_PERIOD calls
 * to RandomGen.randXX().  RandomGen uses the 
 * Configuration component to keep the seed
 * updated.
 *
 * For some applications, this is better than
 * always starting the mote with the same seed
 * on every reboot.
 *
 * In this case, a Timer generates and displays
 * a new random number on the Leds every 512 bms.
 * 
 * @author David Moss
 */