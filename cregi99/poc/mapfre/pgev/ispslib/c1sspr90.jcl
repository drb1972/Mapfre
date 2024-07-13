)CM *-----------------------------------------------------------------*
)CM *                                                                 *
)CM *  COPYRIGHT (C) 1986-2012 CA. ALL RIGHTS RESERVED.               *
)CM *                                                                 *
)CM * NAME: C1SSPR90                                                  *
)CM *                                                                 *
)CM * THIS SKELETON IS USED TO SUBMIT A JOB TO PRINT                  *
)CM *                                                                 *
)CM * ISPSLIB(SCMM@SYM) - IMBEDDED MBR TO SET STANDARD VARIABLES,     *
)CM *                     TAILORED BY THE HOST SITE.                  *
)CM * ISPSLIB(SCMM@LIB) - IMBEDDED STEPLIB/CONLIB CONCATENATIONS,     *
)CM *                     TAILORED BY THE HOST SITE.                  *
)CM *-----------------------------------------------------------------*
)IM SCMM@SYM
&C1BJC1
&C1BJC2
&C1BJC3
&C1BJC4
//NDVRSCL  EXEC PGM=NDVRC1,PARM='C1BM3000'
//SYMDUMP  DD DUMMY
//SYSUDUMP DD SYSOUT=C
//C1MSGS1  DD SYSOUT=&C
//C1PRINT  DD SYSOUT=&C,RECFM=FBA,LRECL=133
//SYSPRINT DD SYSOUT=&C
//BSTIPT01 DD DSN=&C1PDSN,DISP=(OLD,DELETE)
