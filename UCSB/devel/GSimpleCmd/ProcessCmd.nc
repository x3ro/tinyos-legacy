// $Id: ProcessCmd.nc,v 1.1.1.1 2006/05/04 23:08:19 ucsbsensornet Exp $

includes AM;

/** 
 * This interface process a 
 * command and is capable of the hnadling of command 
 * led_on, led_off, radio_louder and radio_quieter 
 */
interface ProcessCmd
{
  /**
   * This command  extracts the command from the message 'pmsg' and 
   * executes the command.
   * @return Command execution result.
   */
  command result_t execute(TOS_MsgPtr pmsg);

  /**
   * Indicate that the command contained in 'pmsg' has finished executing.
   * @param status The status of the command completion.
   * @return Always returns SUCCESS.
   */
  event result_t done(TOS_MsgPtr pmsg, result_t status);
}
