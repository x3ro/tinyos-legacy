/* Sample apriori-routes.h */
#ifndef APR_ROUTES
#define APR_ROUTES

enum {
  MSGS_INITIAL_WAIT = 600,
  MSGS_INTERVAL = 1,
  N_ROUTES = 14 + 1,
};

uint16_t routes[N_ROUTES][2] = {
{110,75},
{302,332},
{319,324},
{170,353},
{391,321},
{269,337},
{233,205},
{269,110},
{122,77},
{302,131},
{303,252},
{206,172},
{86,143},
{194,184},
};

#endif
