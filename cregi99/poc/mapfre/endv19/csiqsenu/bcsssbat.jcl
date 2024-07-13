)CM *----------------------------------------------------------------*
)CM *                                                                *
)CM *  COPYRIGHT (C) 2022 BROADCOM. ALL RIGHTS RESERVED.             *
)CM *                                                                *
)CM * NAME: BCSSSBAT                                                 *
)CM *                                                                *
)CM * PURPOSE: THIS SKELETON IS USED BY THE ACM QUERY ENGINE TO      *
)CM *  GENERATE JCL FOR QUERY-RELATED SCL PRODUCTION.                *
)CM *                                                                *
)CM * ISPSLIB(SCMM@SYM) - IMBEDDED MBR TO SET STANDARD VARIABLES,    *
)CM *                     TAILORED BY THE HOST SITE.                 *
)CM * ISPSLIB(SCMM@LIB) - IMBEDDED STEPLIB/CONLIB CONCATENATIONS,    *
)CM *                     TAILORED BY THE HOST SITE.                 *
)CM *----------------------------------------------------------------*
)SEL &C1PJC1 NE &Z
&C1PJC1
)ENDSEL
)SEL &C1PJC2 NE &Z
&C1PJC2
)ENDSEL
)SEL &C1PJC3 NE &Z
&C1PJC3
)ENDSEL
)SEL &C1PJC4 NE &Z
&C1PJC4
)ENDSEL
)IM SCMM@SYM
//*-------------------------------------------------------------------*
//*     ACMQ JCL STATEMENTS                                           *
//*-------------------------------------------------------------------*
//BCSSSBAT EXEC PGM=NDVRC1,PARM='BC1PACMQ',REGION=4096K
)IM SCMM@LIB
//ACMMSGS1 DD SYSOUT=*
//ACMMSGS2 DD SYSOUT=*
//SYMDUMP  DD DUMMY
//SYSUDUMP DD SYSOUT=*
)DOT &EEVTABL
&EEVLIG
)ENDDOT
/*
