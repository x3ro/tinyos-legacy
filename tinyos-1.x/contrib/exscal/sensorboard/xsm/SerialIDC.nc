/*								
 *
 *
 * Authors:		Mike Grimmer
 * Date last modified:  3/6/03
 *
 */

configuration SerialIDC
{
  provides interface SerialID;
}
implementation
{
  components SerialIDM, OneWireC;

  SerialID = SerialIDM;
  SerialIDM.OneWire -> OneWireC;
}
