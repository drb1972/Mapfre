//&TRKID   JOB 0,'NDVR &TRKID',CLASS=3,MSGCLASS=&CLASS,
//             USER=PMFBCH,REGION=&REGION&SCHENV
//             NOTIFY=&SYSUID&RESTART
//*
//**********************************************************************
//*                                                                    *
//* SKELETON PPCMPKG                                                   *
//*                                                                    *
//* ENDEVOR PRE PRODUCTION RELEASE: ENDEVOR FJOB                       *
//*                                                                    *
//* PACKAGE ID: &PKGID   TRACKER: &TRKID
//*                                                                    *
//* REPORT ANY FAILURES TO ENDEVOR SUPPORT ON +44 (0)123 963 8560
//*                                                                    *
//**********************************************************************
//** GET JOB NUMBER AND SEND TO USER                                  **
//**********************************************************************
//NDVRNTFY EXEC PGM=IKJEFT1B
//SYSPROC  DD DSN=&EVLIB..REXX,DISP=SHR
//         DD DSN=PGEV.BASE.REXX,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=C
//SYSTSIN  DD *
  %PPCMPKGN &TRKID &PKGID &SYSUID
/*
//**********************************************************************
//** NDVRC1 - ENDEVOR INSPECT STEP                                    **
//**********************************************************************
//NDVRINSP EXEC PGM=NDVRC1,PARM=ENBP1000,DYNAMNBR=1500
//APIPRINT DD SYSOUT=Z
//HLAPILOG DD SYSOUT=*
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//SYSABEND DD SYSOUT=C
//ENPSCLIN DD *
 INSPECT PACKAGE '&PKGID'
.
/*
//CHECKIT  IF NDVRINSP.RC GT 8 THEN
//*
//SPWARN   EXEC @SPWARN
//CHECKIT  ENDIF
//*
)SEL &APPR = Y
//**********************************************************************
//** NDVRC1 - APPROVE PACKAGE                                         **
//**********************************************************************
//NDVRAPPR EXEC PGM=NDVRC1,PARM=ENBP1000,DYNAMNBR=1500
//APIPRINT DD SYSOUT=Z
//HLAPILOG DD SYSOUT=*
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//SYSABEND DD SYSOUT=C
//ENPSCLIN DD *
 APPROVE PACKAGE '&PKGID'
.
/*
//CHECKIT  IF NDVRAPPR.RC NE 0 THEN
//*
//SPWARN   EXEC @SPWARN
//CHECKIT  ENDIF
//*
)ENDSEL
//**********************************************************************
//** NDVRC1 - ENDEVOR PRODUCTION PACKAGE EXECUTION                    **
//**********************************************************************
//NDVRPACK EXEC PGM=NDVRC1,DYNAMNBR=1500,
//             PARM='C1BM3000,,&PKGID'
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=C
//C1TPDD01 DD SPACE=(CYL,(5,1)),RECFM=VB,LRECL=260
//C1TPDD02 DD SPACE=(CYL,(5,1)),RECFM=VB,LRECL=260
//C1TPLSIN DD SPACE=(CYL,(5,1)),RECFM=FB,LRECL=80
//C1TPLSOU DD SPACE=(CYL,(5,1))
//APIPRINT DD SYSOUT=Z
//HLAPILOG DD SYSOUT=*
//C1PLMSGS DD SYSOUT=*
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//C1PRINT  DD SYSOUT=*,RECFM=FBA,LRECL=121
//SYSABEND DD SYSOUT=C
//SYSOUT   DD SYSOUT=*
//BSTIPT01 DD SPACE=(CYL,(2,1)),RECFM=FB,LRECL=80
//*
//CHECKIT  IF NDVRPACK.RC GT 0 THEN
)IM C1MSGS3
//CHECKIT  ENDIF
//*
//@0100    IF (NDVRPACK.RC LE 8 OR NDVRPACK.RUN=FALSE) THEN
//**********************************************************************
//** NDVRC1 - SHIP PACKAGE TO DESTINATION PLEXE1                       *
//**********************************************************************
//NDVRSHIP EXEC PGM=NDVRC1,DYNAMNBR=1500,
//             PARM='C1BMX000,&CURRDT,&CURRTM,SHIP,PGEV '
//SYSABEND DD SYSOUT=C
//APIPRINT DD SYSOUT=Z
//HLAPILOG DD SYSOUT=*
//C1BMXLOG DD SYSOUT=*
//C1BMXDET DD SYSOUT=*
//C1BMXSUM DD SYSOUT=*
//C1BMXSYN DD SYSOUT=*
//C1BMXLCC DD DSN=&&XLCC,DISP=(,DELETE),
//             RECFM=FB,LRECL=80,SPACE=(TRK,(2,10),RLSE)
//C1BMXLCM DD DSN=PGEV.BASE.SOURCE,DISP=SHR
//         DD DSN=SYSNDVR.CAI.SOURCE,DISP=SHR
//C1BMXMDL DD DSN=PGEV.BASE.SOURCE,DISP=SHR
//         DD DSN=SYSNDVR.CAI.SOURCE,DISP=SHR
//C1BMXNWC DD DSN=PGEV.NENDEVOR.&TRKID..XNWC,DISP=(,DELETE,DELETE),
//             RECFM=FB,LRECL=80,SPACE=(TRK,(2,10),RLSE)
//C1BMXNWM DD DSN=PGEV.BASE.SOURCE,DISP=SHR
//         DD DSN=SYSNDVR.CAI.SOURCE,DISP=SHR
//C1BMXRJC DD DSN=PGEV.BASE.ISPSLIB,DISP=SHR
//         DD DSN=SYSNDVR.CAI.ISPSLIB,DISP=SHR
//C1BMXDTM DD DSN=&&XDTM,DISP=(,DELETE),
//             RECFM=F,LRECL=80,SPACE=(TRK,(1,1))
//C1BMXDEL DD DSN=&&HDEL,DISP=(,DELETE),
//             RECFM=F,LRECL=80,SPACE=(TRK,(10,10),RLSE)
//C1BMXHJC DD DATA,DLM=##
//*
##
//C1BMXHCN DD DATA,DLM=##
//*
##
//C1BMXRCN DD DATA,DLM=##
//*
##
//C1BMXLIB DD DATA,DLM=##
//*
##
//C1BMXIN  DD *
SHIP PACKAGE &PKGID TO DESTINATION PLEXE1 .
/*
//@0200    IF (NDVRSHIP.RC LE 4 OR NDVRSHIP.RUN=FALSE) THEN
//**********************************************************************
//** RUN PACKAGE REPORT TO GET SUBSYSTEM NAME                         **
//**********************************************************************
//NDVRREPT EXEC PGM=NDVRC1,PARM='C1BR1000'
//BSTRPTS  DD DISP=(NEW,PASS),DSN=&&PKGREP,
//             RECFM=FB,LRECL=133,SPACE=(CYL,(25,25),RLSE)
//BSTINP   DD *
     REPORT  72 .
     ENVIRONMENT * .
     PACKAGE  '&PKGID'  .
     STATUS  IN-ED IN-AP DE APPROVED EXE AB CO BA .
/*
//BSTPDS   DD DUMMY
//SMFDATA  DD DUMMY
//UNLINPT  DD DUMMY
//BSTPCH   DD DSN=&&TEMP,DISP=(,DELETE),
//             SPACE=(CYL,(25,25)),RECFM=FB,LRECL=838
//BSTLST   DD SYSOUT=*
//SORTIN   DD SPACE=(CYL,(25,25))
//SORTOUT  DD SPACE=(CYL,(25,25))
//C1MSGS1  DD SYSOUT=*
//APIPRINT DD SYSOUT=Z
//HLAPILOG DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//*
//@0300    IF (NDVRREPT.RC LE 4 OR NDVRREPT.RUN=FALSE) THEN
//**********************************************************************
//** BUILD ENDEVOR SIGNIN SCL FROM THE PACKAGE REPORT                 **
//**********************************************************************
//NDVRBLD  EXEC PGM=IRXJCL,PARM='EVSPECI &PKGID PPCM'
//SYSEXEC  DD DSN=&EVLIB..REXX,DISP=SHR
//         DD DSN=PGEV.BASE.REXX,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD DUMMY
//PKGREP   DD DSN=&&PKGREP,DISP=(OLD,PASS)
//SCL      DD DSN=&&SCL,DISP=(,PASS,DELETE),
//             SPACE=(CYL,(1,2)),
//             RECFM=FB,LRECL=80
//*
//@0400    IF (NDVRBLD.RC LE 4 OR NDVRBLD.RUN=FALSE) THEN
//**********************************************************************
//** SIGN IN ELEMENTS FROM PMFBCH                                     **
//**********************************************************************
//NDVRSIGN EXEC PGM=NDVRC1,DYNAMNBR=1500,PARM='C1BM3000'
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=C
//C1SORTIO DD SPACE=(CYL,(50,50)),RECFM=VB,LRECL=8296,BLKSIZE=8300
//C1TPDD01 DD SPACE=(CYL,5),RECFM=VB,LRECL=260
//C1TPDD02 DD SPACE=(CYL,5),RECFM=VB,LRECL=260
//C1TPLSIN DD SPACE=(CYL,5),RECFM=FB,LRECL=80
//C1TPLSOU DD SPACE=(CYL,5)
//C1PLMSGS DD SYSOUT=*
//APIPRINT DD SYSOUT=Z
//HLAPILOG DD SYSOUT=*
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//C1PRINT  DD SYSOUT=*,RECFM=FBA,LRECL=121
//SYSABEND DD SYSOUT=C
//SYSOUT   DD SYSOUT=*
//BSTIPT01 DD DSN=&&SCL,DISP=(OLD,DELETE)
//*
//**********************************************************************
//** READ CJOB AND BUILD NDM CARDS, DELETE JCL,  CHANGE INFO          **
//**********************************************************************
//NDVRCJOB EXEC PGM=IKJEFT1B,DYNAMNBR=99
//SYSPROC  DD DSN=&EVLIB..REXX,DISP=SHR
//         DD DSN=PGEV.BASE.REXX,DISP=SHR
//JCL      DD DSN=PGEV.SHIP.D&SHORTD..T&SHORTM..PLEXE1.AHJOB,DISP=OLD
//*JCL      DD DSN=PGEV.SHIP.D&SHORTD..T&SHORTM..PLEXM1D.AHJOB,DISP=OLD
//INFO     DD DSN=PGEV.SHIP.D&SHORTD..T&SHORTM..CHANGE.INFO,
//             DISP=(,CATLG),RECFM=FB,LRECL=80,BLKSIZE=15440,
//             SPACE=(TRK,(5,5),RLSE)
//DELJCL   DD DSN=PGEV.SHIP.D&SHORTD..T&SHORTM..DELETE.INFO,
//             DISP=(,CATLG),RECFM=FB,LRECL=80,BLKSIZE=15440,
//             SPACE=(TRK,(5,5),RLSE)
//PKGREP   DD DISP=(OLD,DELETE),DSN=&&PKGREP
//NDMDATA  DD DSN=PGEV.AUTO.MNDMDATA(&TRKID),DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=C
//SYSTSIN  DD *
  %PPCMPKG &TRKID &PKGID &SHORTD &SHORTM
/*
//@0500    IF (NDVRCJOB.RC = 0 OR NDVRCJOB.RUN=FALSE) THEN
//**********************************************************************
//** DMBATCH - INVOKE NDM TO COPY ALL DATASETS TO REMOTE SYSTEM       **
//**********************************************************************
//NDVRNDM  EXEC PGM=DMBATCH
//DMNETMAP DD DSN=PGTN.CD.CD02.E1.NETMAP,DISP=SHR
//DMMSGFIL DD DSN=PGTN.CD.MSG,DISP=SHR
//DMPUBLIB DD DSN=PGEV.AUTO.MNDMDATA,DISP=SHR
//SYSPRINT DD SYSOUT=*
//NDMCMNDS DD SYSOUT=*
//DMPRINT  DD SYSOUT=*
//SYSUDUMP DD SYSOUT=C
//SYSIN    DD *
 SIGNON
  SUBMIT PROC=&TRKID PRTY=12 CLASS=1 MAXDELAY=01:00:00
 SIGNOFF
/*
//@0500    ENDIF
//@0400    ENDIF
//@0300    ENDIF
//@0200    ENDIF
//@0100    ENDIF
