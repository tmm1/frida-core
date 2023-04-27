#ifndef __FRIDA_TVOS_H__
#define __FRIDA_TVOS_H__

#ifdef HAVE_TVOS
#include <Availability.h>
#undef __TVOS_PROHIBITED
#define __TVOS_PROHIBITED
#undef __API_UNAVAILABLE
#define __API_UNAVAILABLE(...)
#endif

#endif
