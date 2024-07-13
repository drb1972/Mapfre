)CM *-----------------------------------------------------------------*
)CM *                                                                 *
)CM *  COPYRIGHT (C) 1986-2013 CA. ALL RIGHTS RESERVED.               *
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
&C1PJC1
&C1PJC2
&C1PJC3
&C1PJC4
)IM SCMM@SYM
//NDVRSCL  EXEC PGM=NDVRC1,REGION=4096K,PARM='C1BM3000'
)IM SCMM@LIB
//SYMDUMP  DD DUMMY
//SYSUDUMP DD SYSOUT=*
//C1MSGS1  DD SYSOUT=&C
//C1PRINT  DD SYSOUT=&C,RECFM=FBA,LRECL=133
//SORTWK01 DD UNIT=&T@DISK,SPACE=(CYL,(5,5))
//SORTWK02 DD UNIT=&T@DISK,SPACE=(CYL,(5,5))
//SORTWK03 DD UNIT=&T@DISK,SPACE=(CYL,(5,5))
//SYSPRINT DD SYSOUT=&C
//BSTIPT01 DD  DSN=&C1PDSN,DISP=(OLD,DELETE)
