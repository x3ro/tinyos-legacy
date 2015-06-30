/**
 *  Low-level interface to CC2420 chip
 */

interface CC2420LowLevelFIFO {
  async command void enableFIFOP();
  async command void disableFIFOP();
  async command bool getEnabledFIFOP();
  async event   void FIFOPIntr();
}
