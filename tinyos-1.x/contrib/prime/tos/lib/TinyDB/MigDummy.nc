//dummy file to make MIG run faster for TinyDB 
// compilation -- just include needed message
// files in a worthless config.

includes AM;
includes TinyDB;
includes Event;
includes Command;

configuration MigDummy {
	      
}

implementation {
	       components IntToLeds, Main;	       
	       
	       Main.StdControl -> IntToLeds;
	       
}
