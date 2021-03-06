smart_library
=============

Sophie's Fork:
--------------
My contribution to this library are the routines in the ``near-real-time`` folder, and ``ar_evol.pro``, which allow SMART to be run automatically for operational space weather forecasting use. 

Also added are routines to grab and process active regions with SMART to be run with the HEXA NLFF code developed at University of St Andrews. This was part of a Met Office summer student project, and it is worth noting that HEXA is currently not open access.


Original SMART code:
--------------------

An SSW IDL routine library to be used by SMART itself and users wishing to analyse SMART detections.

Requirements:

Add the following to your IDL start-up file (or run manually before using SMART_LIBRARY routines):

;Set up system variables for SMART_Library codes

;------------------------------------------------------------------------------>

;Set the environment variables

DEFSYSV, '!AR_PATH', '~/science/repositories/smart_library/'

DEFSYSV, '!AR_PARAM', 'ar_param.txt'

;------------------------------------------------------------------------------>

Notes:

1. This repository requires an SSWIDL installation

2. This repository has dependencies as listed below

Dependencies:

	GEN_LIBRARY: git@github.com:pohuigin/gen_library.git
