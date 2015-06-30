/**
 * MessagePoolFree interface
 *
 * Parameterized interface:
 *
 *    uses interface MessagePoolFree[ unique("MessagePoolFree") ];
 */

interface MessagePoolFree {
  /**
   * Signal whenever a message buffer is available.
   */
  async event void avail();
}
