/*
	HPLKBI interface
	
	Author:			Jacob Munk-Stander <jacobms@diku.dk>
	Last modified:	May 24, 2005
*/
interface HPLKBI
{
	async command result_t init();
	
	async event result_t switchDown(uint8_t sw);
}
