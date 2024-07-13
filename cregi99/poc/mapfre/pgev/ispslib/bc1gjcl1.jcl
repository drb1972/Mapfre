)CM *-----------------------------------------------------------------*
)CM *                                                                 *
)CM *  COPYRIGHT (C) 1986-2012 CA. ALL RIGHTS RESERVED.               *
)CM *                                                                 *
)CM * NAME: BC1GJCL1                                                  *
)CM *                                                                 *
)CM * FUNCTION: THIS SKELETON IS USED BY THE PDM BATCH SUBMIT DIALOG  *
)CM *  TO BUILD THE PDM BATCH EXECUTION JCL.                          *
)CM *                                                                 *
)CM * NOTE: THIS SKELETON MUST BE CUSTOMIZED TO YOUR SITES            *
)CM *  SPECIFICATIONS.                                                *
)CM *                                                                 *
)CM * ISPSLIB(SCMM@SYM) - IMBEDDED MBR TO SET STANDARD VARIABLES,     *
)CM *                     TAILORED BY THE HOST SITE.                  *
)CM * ISPSLIB(SCMM@LIB) - IMBEDDED STEPLIB/CONLIB CONCATENATIONS,     *
)CM *                     TAILORED BY THE HOST SITE.                  *
)CM *-----------------------------------------------------------------*
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
//NDVRPDM  EXEC PGM=NDVRC1,DYNAMNBR=1500,
//             PARM='BC1G0000'
//*-------------------------------------------------------------------*
//* OUTPUT MESSAGE DATASETS                                           *
//*-------------------------------------------------------------------*
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//C1PRINT  DD SYSOUT=*
//APIPRINT DD SYSOUT=Z
//HLAPILOG DD SYSOUT=*
//SYSUDUMP DD SYSOUT=C
//SYSOUT   DD SYSOUT=*
//SYMDUMP  DD DUMMY
//*-------------------------------------------------------------------*
//* PDM BATCH REQUEST DATASET                                         *
//*-------------------------------------------------------------------*
//BATCHIN  DD DSN=&PB1VADSN,DISP=SHR
)SEL &PB1VINCF = Y
//*-------------------------------------------------------------------*
//* INCLUDED JCL                                                      *
//*-------------------------------------------------------------------*
)SEL &PB1VDD01 NE &Z
&PB1VDD01
)ENDSEL
)SEL &PB1VDD02 NE &Z
&PB1VDD02
)ENDSEL
)SEL &PB1VDD03 NE &Z
&PB1VDD03
)ENDSEL
)SEL &PB1VDD04 NE &Z
&PB1VDD04
)ENDSEL
)SEL &PB1VDD05 NE &Z
&PB1VDD05
)ENDSEL
)SEL &PB1VDD06 NE &Z
&PB1VDD06
)ENDSEL
)SEL &PB1VDD07 NE &Z
&PB1VDD07
)ENDSEL
)SEL &PB1VDD08 NE &Z
&PB1VDD08
)ENDSEL
)SEL &PB1VDD09 NE &Z
&PB1VDD09
)ENDSEL
)SEL &PB1VDD10 NE &Z
&PB1VDD10
)ENDSEL
)SEL &PB1VDD11 NE &Z
&PB1VDD11
)ENDSEL
)SEL &PB1VDD12 NE &Z
&PB1VDD12
)ENDSEL
)SEL &PB1VDD13 NE &Z
&PB1VDD13
)ENDSEL
)SEL &PB1VDD14 NE &Z
&PB1VDD14
)ENDSEL
)SEL &PB1VDD15 NE &Z
&PB1VDD15
)ENDSEL
)SEL &PB1VDD16 NE &Z
&PB1VDD16
)ENDSEL
)SEL &PB1VDD17 NE &Z
&PB1VDD17
)ENDSEL
)SEL &PB1VDD18 NE &Z
&PB1VDD18
)ENDSEL
)SEL &PB1VDD19 NE &Z
&PB1VDD19
)ENDSEL
)SEL &PB1VDD20 NE &Z
&PB1VDD20
)ENDSEL
)ENDSEL
//*
)IM C1MSGS3