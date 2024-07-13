//*********************************************************************
//** SKELETON CMSSIGN                                                **
//** NDVRC1 - ENDEVOR PACKAGE DETAIL REPORT (FOR SPECIFIC CHANGES)   **
//*********************************************************************
//PACKREP  EXEC PGM=NDVRC1,PARM='C1BR1000'
//BSTRPTS  DD DSN=&&PKGREP,DISP=(,PASS),
//             SPACE=(TRK,(30,30),RLSE),
//             RECFM=FBA,LRECL=133
//BSTPDS   DD DUMMY
//SMFDATA  DD DUMMY
//UNLINPT  DD DUMMY
//BSTPCH   DD DSN=&&TEMP,DISP=(,DELETE),
//             SPACE=(TRK,(15,30),RLSE),
//             RECFM=FB,LRECL=838
//BSTLST   DD SYSOUT=*
//SORTIN   DD SPACE=(TRK,(75,75),RLSE)
//SORTOUT  DD SPACE=(TRK,(75,75),RLSE)
//C1MSGS1  DD SYSOUT=*
//APIPRINT DD SYSOUT=*
//HLAPILOG DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//BSTINP   DD *
     REPORT  72 .
     ENVIRONMENT * .
     PACKAGE  &PKG .
     STATUS  IN-ED IN-AP DE APPROVED EXE AB CO BA .
/*
//*********************************************************************
//** SPWARN - ABEND IF PACKREP RETURN CODE IS GREATER THAN FOUR      **
//*********************************************************************
//CHECKIT  IF PACKREP.RC GT 4 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//*********************************************************************
//** IRXJCL - BUILD ENDEVOR SIGNIN SCL                               **
//*********************************************************************
//SIGNSCL  EXEC PGM=IRXJCL,PARM='EVSPECI &PKG EMERFIX'
//SYSTSPRT DD SYSOUT=*
//SYSEXEC  DD DSN=PGEV.BASE.REXX,DISP=SHR
//SYSTSIN  DD DUMMY
//PKGREP   DD DSN=&&PKGREP,DISP=(OLD,DELETE)
//SCL      DD DSN=&&SCL,DISP=(,PASS),
//             SPACE=(TRK,(15,30),RLSE),
//             RECFM=FB,LRECL=80
//*
//*********************************************************************
//** SPWARN - ABEND IF SIGNSCL RETURN CODE IS GREATER THAN FOUR      **
//*********************************************************************
//CHECKIT  IF SIGNSCL.RC GT 4 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//*********************************************************************
//** NDVRC1 - SIGN OUT ELEMENTS TO #EMERFIX                          **
//*********************************************************************
//SIGNOUT  EXEC PGM=NDVRC1,DYNAMNBR=1500,PARM='C1BM3000'
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=C
//C1SORTIO DD SPACE=(TRK,(750,750),RLSE),
//             RECFM=VB,LRECL=8296,BLKSIZE=8300
//C1TPDD01 DD SPACE=(TRK,(75,75),RLSE),RECFM=VB,LRECL=260
//C1TPDD02 DD SPACE=(TRK,(75,75),RLSE),RECFM=VB,LRECL=260
//C1TPLSIN DD SPACE=(TRK,(75,75),RLSE),RECFM=FB,LRECL=80
//C1TPLSOU DD SPACE=(TRK,(75,75),RLSE)
//C1PLMSGS DD SYSOUT=*
//APIPRINT DD SYSOUT=*
//HLAPILOG DD SYSOUT=*
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//C1PRINT  DD SYSOUT=*,RECFM=FBA,LRECL=121
//SYSABEND DD SYSOUT=C
//SYSOUT   DD SYSOUT=*
//BSTIPT01 DD DSN=&&SCL,DISP=(OLD,DELETE)
//*
//*********************************************************************
//** SPWARN - ABEND IF SIGNOUT RETURN CODE IS GREATER THAN EIGHT     **
//*********************************************************************
//CHECKIT  IF SIGNOUT.RC GT 8 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
