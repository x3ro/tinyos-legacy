/*
	HPLKBI configuration
	
	Author:			Jacob Munk-Stander <jacobms@diku.dk>
	Last modified:	May 24, 2005
*/

configuration HPLKBIC
{
	provides interface HPLKBI as KBI;
}

implementation
{
	components HPLKBIM;

	KBI = HPLKBIM;
}
