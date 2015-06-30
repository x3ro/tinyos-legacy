/*								
 *
 *
 * Authors:		Mike Grimmer
 * Date last modified:  3/6/03
 *
 */

configuration OneWireC
{
  provides interface OneWire;
}
implementation
{
  components OneWireM;

  OneWire = OneWireM;
}
