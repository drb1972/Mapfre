)CM *----------------------------------------------------------------*
)CM *                                                                *
)CM *  COPYRIGHT (C) 1986-2012 CA. ALL RIGHTS RESERVED.              *
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
)SEL &C1BJC1 NE &Z
&C1BJC1
)ENDSEL
)SEL &C1BJC2 NE &Z
&C1BJC2
)ENDSEL
)SEL &C1BJC3 NE &Z
&C1BJC3
)ENDSEL
)SEL &C1BJC4 NE &Z
&C1BJC4
)ENDSEL
)IM SCMM@SYM
//*-------------------------------------------------------------------*
//*     ACMQ JCL STATEMENTS                                           *
//*-------------------------------------------------------------------*
//NDVRACMQ EXEC PGM=NDVRC1,PARM='BC1PACMQ'
//ACMMSGS1 DD SYSOUT=*
//ACMMSGS2 DD SYSOUT=*
//APIPRINT DD SYSOUT=Z
//SYMDUMP  DD DUMMY
//SYSUDUMP DD SYSOUT=C
)DOT &EEVTABL
&EEVLIG
)ENDDOT
/*
