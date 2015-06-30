Config README
Written by Cory Sharp
$Id: Config_README.txt,v 1.1 2003/10/09 01:35:22 cssharp Exp $


OVERVIEW

Config provides automatic code generation for configuration parameters
that can be set remotely.

In a NesC code module, create a configuration parameter with this
kind of special comment

  //!! Config [num] { [type] [name] = [init]; }

[num] is a unique number between 0 and 255 used in the bottom messaging
layer for decoding a config message.

[type] specifies this parameters C type.  If you want to use structs,
unions, or enums, typedef them in a separate header file and use that
typedef.

[name] is a unique name for the parameter.

[init] is an initial default value for the parameter.


INTERFACES AND MODULES

All interfaces and modules are placed in the build/ directory.

  Config.h
  ConfigC.nc
  ConfigM.nc
  Config_[name].nc

Config.h defines a global structure G_Config that has one field for each
Config specification.  This is where configuration values can and should
be accessed in general.

ConfigC.nc wires everything necessary for the Configuration module.  It
provides all Config_[name] interfaces.  Be sure to wire
ConfigC.StdControl to Main in your main application configuration.  Any
module that uses a Config_[name] interface will have the corresponding
config module automatically wired in ConfigC.nc.  DO NOT wire the
Config_[name] interface in your own configuration file.

ConfigM.nc is the module that does all the marshalling, unmarshalling,
and event notification for each parameter.  You need not directly
interact with this module.

Config_[name].nc is an interface created specifically for each
configuration parameter.  It looks like this

  interface Config_[name]
  {
    event void updated();
    command result_t set( [type] [name] );
  }

The updated event is fired when the configuration value has changed
either from a routing message or from a local set command.  Use the set
command to invoke an updated event -- this can be used to abstract
intermodule behaviors.  To set a config value without causing an updated
event, set G_Config.[name] directly.  It's your problem to make sure you
do this responsibly.

Note that you only need to use a Config_[name] interface if you need to
take immediate action such as reinitialization given an updated value.
If you code will take the correct action passively through accessing
G_Config.[name], then there's no need to use the Config_[name]
interface, simplifying your wiring.  Note that when you do use a
Config_[name] interface in your module, you MUST NOT wire it in your own
configuration, because it is automatically wired in ConfigC.nc.


EXAMPLE

In MyMagM.nc you can specify config type

//!! Config 130 { uint16_t mag_threshold = 32; }
//!! Config 131 { uint16_t mag_period = 64; }

When compiled, this creates Config.h file that defines a G_Config with
mag_threshold and mag_period fields.  G_Config.mag_threshold initializes
to 32 and G_Config.mag_period initializes to 64.

  command result_t StdControl.start()
  {
    call Timer.start( G_Config.mag_period );
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    call U16Sensor.read();
  }

  event result_t U16Sensor.readDone( uint16_t value )
  {
    if( value > G_Config.mag_threshold )
    {
      // ... do something clever and impressive ...
    }
  }

G_Config.mag_period sets the timer period for reading the magnetometer
value.  If it's changed, we're going to have to change the timer.  So,
we need to use the Config_mag_period interface so that we can reset the
timer.  Note, we won't wire Config_mag_period in MyMagC.nc because it is
automatically wired to MyMagC in ConfigC.nc.  The updated event code
could look like this:

  event void Config_mag_period.updated()
  {
    call Timer.stop();
    call Timer.start( G_Config.mag_period );
  }

G_Config.mag_threshold is only used passively in readDone.  When it's
changed, the correct behavior will take place next time readDone rolls
around.  So, we do NOT need to wire to the Config_mag_threshold behavior
there's nothing in particular we need to reinitialize on.


That's it!  Good luck!

