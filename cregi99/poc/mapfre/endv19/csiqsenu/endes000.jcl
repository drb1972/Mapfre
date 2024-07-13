)CM *----------------------------------------------------------------*
)CM *                                                                *
)CM *  COPYRIGHT (C) 2022 BROADCOM. ALL RIGHTS RESERVED.             *
)CM *                                                                *
)CM * NAME: ENDES000                                                 *
)CM *                                                                *
)CM * PURPOSE: THIS SKELETON IS USED BY THE QUICK-EDIT DIALOG TO     *
)CM *  GENERATE JCL TO GENERATE AN EDITED ELEMENT IN BATCH MODE.     *
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
//*    BATCH JCL STATEMENTS                                           *
//*-------------------------------------------------------------------*
//ENDES000 EXEC PGM=NDVRC1,
//             DYNAMNBR=1500,
//             REGION=4096K,
//             PARM='C1BM3000'
)IM SCMM@LIB
)SEL &VARSILEV = Y
//*-------------------------------------------------------------------*
//*  PANVALET AND LIBRARIAN SUPPORT.                                  *
//*-------------------------------------------------------------------*
//C1TPDD01 DD  UNIT=&T@DISK,
//             SPACE=(CYL,(1,1)),
//             DCB=(RECFM=VB,LRECL=260)
//C1TPDD02 DD  UNIT=&T@DISK,
//             SPACE=(CYL,(1,1)),
//             DCB=(RECFM=VB,LRECL=260)
//C1TPLSIN DD  UNIT=&T@DISK,
//             SPACE=(CYL,(1,1)),
//             DCB=(RECFM=FB,LRECL=80)
//C1TPLSOU DD  UNIT=&T@DISK,
//             SPACE=(CYL,(1,1))
//C1PLMSGS DD  SYSOUT=*
)ENDSEL
//*-------------------------------------------------------------------*
//*  OUTPUT DATA SETS                                                 *
//*-------------------------------------------------------------------*
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYMDUMP  DD DUMMY
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
)SEL &VCAPYN = Y
//*********************************************************************
//*  CONCURRENT ACTION PROCESSING REQUESTED                           *
//*********************************************************************
//EN$CAP&VCAPRN DD SYSOUT=*
)ENDSEL
//*-------------------------------------------------------------------*
//*  CONTROL STATEMENTS                                               *
//*-------------------------------------------------------------------*
//BSTIPT01 DD *
)CM
)CM  IF CD18101 QE QUEUE BATCH ACTION OPTION IS ENABLED THEN
)CM  QUICK EDIT CAN SUBMIT BATCH JOBS WITH MULTIPLE REQUESTS
)CM  FROM A TABLE (ENZIESCL, WHERE Z IS THE SCREEN NUMBER)
)CM  IF MULTIPLE REQUESTS ARE PRESENT THEY ARE FORMATED AS USUAL
)CM  BUT WITH THE REQUEST SEQUENCE NUMBER IN COLS 73-80
)CM  THE ACTUAL TABLE DEFINITIONS ARE IN A SEPARATE IMBED MEMBER TO
)CM  ALLOW EXPANSION OF THE SCL ONLY (TO EDIT OR VALIDATE THE SCL).
)CM
)IF &VNTQUENA EQ E && &EEVQUREQ GT 00000000 THEN )DO
)SEL &VARSTPRC NE &Z
 SET STOPRC &VARSTPRC..
)ENDSEL
)IM ENDES010
)ENDDO
)ELSE )DO
)SEL &EEVGENS1 NE &Z
&EEVGENS1
)ENDSEL
)SEL &EEVGENS2 NE &Z
&EEVGENS2
)ENDSEL
)SEL &EEVGENS3 NE &Z
&EEVGENS3
)ENDSEL
)SEL &EEVGENS4 NE &Z
&EEVGENS4
)ENDSEL
)SEL &EEVGENS5 NE &Z
&EEVGENS5
)ENDSEL
)SEL &EEVGENS6 NE &Z
&EEVGENS6
)ENDSEL
)SEL &EEVGENS7 NE &Z
&EEVGENS7
)ENDSEL
)SEL &EEVGENS8 NE &Z
&EEVGENS8
)ENDSEL
)SEL &EEVGENS9 NE &Z
&EEVGENS9
)ENDSEL
)SEL &EEVGENSA NE &Z
&EEVGENSA
)ENDSEL
)SEL &EEVGENSB NE &Z
&EEVGENSB
)ENDSEL
)SEL &EEVGENSC NE &Z
&EEVGENSC
)ENDSEL
)SEL &EEVGENSD NE &Z
&EEVGENSD
)ENDSEL
)ENDDO
)SEL &EEVINJCL = Y
//*-------------------------------------------------------------------*
//*  INCLUDED JCL                                                     *
//*-------------------------------------------------------------------*
)SEL &VNBDD01 NE &Z
&VNBDD01
)ENDSEL
)SEL &VNBDD02 NE &Z
&VNBDD02
)ENDSEL
)SEL &VNBDD03 NE &Z
&VNBDD03
)ENDSEL
)SEL &VNBDD04 NE &Z
&VNBDD04
)ENDSEL
)SEL &VNBDD05 NE &Z
&VNBDD05
)ENDSEL
)SEL &VNBDD06 NE &Z
&VNBDD06
)ENDSEL
)SEL &VNBDD07 NE &Z
&VNBDD07
)ENDSEL
)SEL &VNBDD08 NE &Z
&VNBDD08
)ENDSEL
)SEL &VNBDD09 NE &Z
&VNBDD09
)ENDSEL
)SEL &VNBDD10 NE &Z
&VNBDD10
)ENDSEL
)SEL &VNBDD11 NE &Z
&VNBDD11
)ENDSEL
)SEL &VNBDD12 NE &Z
&VNBDD12
)ENDSEL
)SEL &VNBDD13 NE &Z
&VNBDD13
)ENDSEL
)SEL &VNBDD14 NE &Z
&VNBDD14
)ENDSEL
)SEL &VNBDD15 NE &Z
&VNBDD15
)ENDSEL
)SEL &VNBDD16 NE &Z
&VNBDD16
)ENDSEL
)SEL &VNBDD17 NE &Z
&VNBDD17
)ENDSEL
)SEL &VNBDD18 NE &Z
&VNBDD18
)ENDSEL
)SEL &VNBDD19 NE &Z
&VNBDD19
)ENDSEL
)SEL &VNBDD20 NE &Z
&VNBDD20
)ENDSEL
)ENDSEL
//* ENDES000 GENERATED BY &ZUSER ON &ZDATE AT &ZTIME
