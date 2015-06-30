/*								
 *
 *
 * Authors:		Mike Grimmer
 * Date last modified:  3/6/03
 *
 */

configuration GrenadeC
{
  provides interface Grenade;
}
implementation
{
  components GrenadeM, OneWireC;

  Grenade = GrenadeM;
  GrenadeM.OneWire -> OneWireC;
}
