interface ModuleControl
{
	async command void prepareStart();
	/** Stop the module. The module should return
		the specified state when stopped **/
	async command void stop();
	async event void done();
}
