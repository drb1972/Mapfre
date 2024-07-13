&C1BJC1
&C1BJC2
&C1BJC3
&C1BJC4
//*
//* BUILD PACKAGE &PKGID BY &CCID
//*
//LISTELTS EXEC PGM=NDVRC1,PARM='CONCALL,DDN:CONLIB,BC1PCSV0'
//CSVMSGS1 DD SYSOUT=*
//APIPRINT DD SYSOUT=Z
//SYSABEND DD SYSOUT=C
//APIEXTR  DD DISP=(MOD,PASS),DSN=&&CSV,
//            SPACE=(TRK,(45,90),RLSE),
//            RECFM=FB,LRECL=1600
//BSTIPT01 DD *
LIST ELEMENT *
  FROM ENV &ENV1 SYS &PKGSY SUB * TYPE * STAGE &STG1
  OPTIONS NOSEARCH NOCSV
  WHERE CCID OF CURRENT = &CCID
 .
)SEL &STG2 ^= X
LIST ELEMENT *
  FROM ENV &ENV2 SYS &PKGSY SUB * TYPE * STAGE &STG2
  OPTIONS NOSEARCH NOCSV
  WHERE CCID OF CURRENT = &CCID
 .
)ENDSEL
/*
//*
//CHECK010 IF RC LE 4 THEN
//*
//* BUILD MOVE SCL
//*
//BUILDSCL EXEC PGM=IKJEFT1B,PARM='%PKMOVE &PKGSY &STG1 &STG2 &CCID'
//SYSEXEC  DD DSN=PGEV.BASE.REXX,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//CSV      DD DISP=(OLD,DELETE),DSN=&&CSV
//SCL      DD DISP=(NEW,PASS),DSN=&&SCL,
//            SPACE=(TRK,(45,90),RLSE),
//            RECFM=FB,LRECL=80
//README   DD SYSOUT=*
//SYSTSIN  DD DUMMY
//*
//CHECK020 IF BUILDSCL.RC EQ 0 THEN
//*
//* BUILD PACKAGE &PKGID BY &CCID
//*
//BUILD    EXEC PGM=NDVRC1,PARM=ENBP1000,DYNAMNBR=1500
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//APIPRINT DD SYSOUT=Z
//SYSABEND DD SYSOUT=C
//ENPSCLIN DD *
)SEL &DELPKG = Y
DELETE PACKAGE '&PKGID' .
)ENDSEL
DEFINE PACKAGE '&PKGID'
  DESCRIPTION "#"
  IMPORT SCL FROM DDNAME SCL
          DO NOT APPEND
  OPTIONS STANDARD PACKAGE
          SHARABLE PACKAGE
          BACKOUT IS ENABLED
          EXECUTION WINDOW FROM 03SEP04 00:00 TO 31DEC79 00:00
  NOTES=('                                                            ',
         '                                                            ')
 .
/*
//SCL      DD *
* PACKAGE BUILT BY PKUTIL

//         DD DISP=(OLD,DELETE),DSN=&&SCL
//*
//CHECK030 IF BUILD.RC LE 4 THEN
//*
//* CAST PACKAGE &PKGID
//*
//CAST     EXEC PGM=NDVRC1,PARM=ENBP1000,DYNAMNBR=1500
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//APIPRINT DD SYSOUT=Z
//SYSABEND DD SYSOUT=C
//ENPSCLIN DD *
 CAST    PACKAGE '&PKGID' .
/*
//*
//CHECK040 IF CAST.RC GT 4 THEN
//*
//* RUN THE CAST REPORT ANALYSER
//*
//README   EXEC PGM=IKJEFT1B,PARM='%CZ &PKGID',DYNAMNBR=1500
//SYSEXEC  DD DSN=PGEV.BASE.REXX,DISP=SHR
//SYSTSPRT DD SYSOUT=Z
//APIPRINT DD SYSOUT=Z
//BSTLST   DD SYSOUT=Z
//SYSOUT   DD SYSOUT=Z
//SORTIN   DD SPACE=(CYL,(150,15))
//SORTOUT  DD SPACE=(CYL,(150,15))
//CASTRPT  DD SYSOUT=*
//SYSTSIN  DD DUMMY
//*
//CHECK040 ENDIF
//*
//CHECK030 ENDIF
//*
//CHECK020 ENDIF
//*
//CHECK010 ENDIF
