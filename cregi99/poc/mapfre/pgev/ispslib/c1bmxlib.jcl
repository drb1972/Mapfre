)CM *-----------------------------------------------------------------*
)CM *                                                                 *
)CM *  COPYRIGHT (C) 1986-2012 CA. ALL RIGHTS RESERVED.               *
)CM *                                                                 *
)CM * NAME: C1BMXLIB                                                  *
)CM *                                                                 *
)CM *PACKAGE SHIPMENT BATCH JCL - STEPLIB/CONLIB - ISPSLIB(C1BMXLIB)  *
)CM *                                                                 *
)CM *THIS SKELETON CONTAINS THE STEPLIB AND CONLIB DEFINITIONS TO RUN *
)CM *PACKAGE SHIPMENT JOB STEPS AT THE HOST SITE.                     *
)CM *-----------------------------------------------------------------*
//* ******************************************************************
//* *  STEPLIB, CONLIB, MESSAGE LOG AND ABEND DATASETS
//* ******************************************************************
)CM  ISPSLIB(SCMM@LIB) - STEPLIB/CONLIB CONCATENATIONS,
)CM                      TAILORED BY THE HOST SITE.
//*
//SYSUDUMP DD SYSOUT=C     *** DUMP TO SYSOUT *************************
//SYMDUMP  DD DUMMY
//C1BMXLOG DD SYSOUT=*     *** MESSAGES, ERRORS, RETURN CODES *********
