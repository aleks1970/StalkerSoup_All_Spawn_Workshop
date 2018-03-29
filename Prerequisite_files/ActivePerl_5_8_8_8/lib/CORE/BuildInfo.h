/* BuildInfo.h
 *
 * Copyright (C) 1998-2006 ActiveState Corp.  All rights reserved.
 *
 */

#ifndef ___BuildInfo__h___
#define ___BuildInfo__h___

#define ACTIVEPERL_PRODUCT      "ActivePerl"
#define ACTIVEPERL_VERSION      819
#define ACTIVEPERL_SUBVERSION   0
#define ACTIVEPERL_CHANGELIST   " [267479]"

#define PERL_VENDORLIB_NAME	"ActiveState"

#ifndef STRINGIFY
#  include "config.h"
#endif

/* Derived values and legacy */
#if ACTIVEPERL_SUBVERSION > 0
#  define PRODUCT_BUILD_NUMBER	STRINGIFY(ACTIVEPERL_VERSION) "." STRINGIFY(ACTIVEPERL_SUBVERSION)
#else
#  define PRODUCT_BUILD_NUMBER	STRINGIFY(ACTIVEPERL_VERSION)
#endif
#define PERLFILEVERSION		"5,8,8," STRINGIFY(ACTIVEPERL_VERSION) "\0"
#define PERLRC_VERSION		5,8,8,ACTIVEPERL_VERSION
#define PERLPRODUCTVERSION	"Build " PRODUCT_BUILD_NUMBER ACTIVEPERL_CHANGELIST "\0"
#define PERLPRODUCTNAME		ACTIVEPERL_PRODUCT "\0"
#define ACTIVEPERL_LOCAL_PATCHES_ENTRY	ACTIVEPERL_PRODUCT " Build " PRODUCT_BUILD_NUMBER ACTIVEPERL_CHANGELIST
#ifdef BUILT_BY_ACTIVESTATE
#define BINARY_BUILD_NOTICE	PerlIO_printf(PerlIO_stdout(), "\n\
Binary build " PRODUCT_BUILD_NUMBER ACTIVEPERL_CHANGELIST " provided by ActiveState http://www.ActiveState.com\n\
Built " __DATE__ " " __TIME__ "\n");
#endif

#endif  /* ___BuildInfo__h___ */
