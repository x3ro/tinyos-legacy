/**
 * Interface to an abstract ouput mechanism for strings. Example
 * of provider of this interface is StrToRfm.
 *
 * @author Brian Avery
 */

interface StrOutput {

  /**
   * Output the given string.
   *
   * @return SUCCESS if the value will be output, FAIL otherwise.
   */
  
  command result_t output(char *str);

  /**
   * Output the given string with the integer postpended .
   *
   * @return SUCCESS if the value will be output, FAIL otherwise.
   */
  
  command result_t output_int(char *str,uint16_t i);

  /**
   * Output the given string with the integer postpended in hex .
   *
   * @return SUCCESS if the value will be output, FAIL otherwise.
   */
  
  command result_t output_hex(char *str,uint16_t i);


  /**
   * Output the given string with the integer postpended in base
   * base can be [2-36] inclusive.
   *
   * @return SUCCESS if the value will be output, FAIL otherwise.
   */
  
  command result_t output_int_base(char *str,uint16_t i,uint8_t base);


  /**
   * Signal that the ouput operation has completed; success states
   * whether the operation was successful or not.
   *
   * @return SUCCESS always.
   *
   */
  event result_t outputComplete(result_t success);
}
