/**
 * Eavesdropper Module
 * Provides the same functionality as TOSBase but with 
 * the Transceiver.
 * 
 * The TOSBase program uses 12 TOS_Msg's for buffering
 * radio, and 12 TOS_Msg's for buffering UART.
 * 
 * By making the Transceiver buffer 24 total messages,
 * we are better able to compare the size differences
 * between Eavesdropper/Transceiver and TOSBase:
 *
 * TelosB TOSBase ROM = 11054
 * TelosB TOSBase RAM = 1902
 * TelosB Eavesdropper ROM = 11720 (6% increase)
 * TelosB Eavesdropper RAM = 1455 (23% decrease)
 *
 * MicaZ TOSBase ROM = 10194
 * MicaZ TOSBase RAM = 1929
 * MicaZ Eavesdropper ROM = 10696 (4.6% increase)
 * MicaZ Eavesdropper RAM = 1482 (23% decrease)
 *
 * @author David Moss - dmm@rincon.com
 */

