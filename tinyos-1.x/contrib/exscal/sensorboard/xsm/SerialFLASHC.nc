/*								
 *
 *
 * Authors:		Mike Grimmer
 * Date last modified:  3/6/03
 *
 */

configuration SerialFLASHC
{
  provides interface SerialFLASH;
}
implementation
{
  components SerialFLASHM;

  SerialFLASH = SerialFLASHM;
}
