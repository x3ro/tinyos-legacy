interface PibAttributeService
{
	command result_t set(Ieee_PibAttribute attribute, void (*func)(Ieee_Status status) );
}
