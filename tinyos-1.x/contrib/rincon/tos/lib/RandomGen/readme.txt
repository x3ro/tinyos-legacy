
/**
 * This RandomGen component has an advantage over other Random generator
 * components because it uses the Configuration component
 * to periodically store the seed to non-volatile microcontroller memory.
 * Rebooting the mote will not reset the seed back all the way back
 * to the very beginning. 
 *
 * The seed is not stored everytime it is updated because that
 * would waste time and energy.  By default, it is saved every
 * 25 times it is called. If your app will never reboot,
 * you can prevent the periodic flash write by defining
 * RANDOMGEN_STORAGE_PERIOD = 0.  You can also access the regular
 * Random components to generate random numbers that do not require
 * checkpoints.
 *
 * It's recommend you don't use the RandomGen component until it has 
 * signaled RandomGen.ready().
 *
 * @author David Moss
 */

