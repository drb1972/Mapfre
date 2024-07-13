//TTYYCSEG JOB 0,'CASEGEN RETRIEVE',CLASS=3,NOTIFY=&UID,REGION=6M
/*JOBPARM SYSAFF=QFOS
//*
//*-------------------------------------------------------------------*
//*  RETRIEVE DIF ELEMENT                                             *
//*-------------------------------------------------------------------*
//NDVRBAT  EXEC PGM=NDVRC1,DYNAMNBR=1500,PARM='C1BM3000'
//APIPRINT DD SYSOUT=Z
//HLAPILOG DD SYSOUT=*
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//BSTIPT01 DD *
 RETRIEVE ELEMENT "&ELE"
    FROM ENVIRONMENT "&ENV"
         SYSTEM "LJ" SUBSYSTEM "LJ1"
         TYPE "DIF" STAGE "&STG"
 TO DSNAME 'TTYY.CASEGEN.SOURCE'
    OPTIONS COMMENT "RETRIEVE TO CASEGEN SERVER"
            CCID "&TCCI" REPLACE
    .
/*
//*
//CHECKIT  IF NDVRBAT.RC NE 0 THEN
//*-------------------------------------------------------------------*
//*  ABEND IF NDVRBAT STEP GIVES HIGHER THAN ZERO RETURN CODE         *
//*-------------------------------------------------------------------*
//@SPWARN  EXEC @SPWARN
//CHECKIT  ENDIF
//*
//*-------------------------------------------------------------------*
//*  SCAN THE DIF SOURCE FOR ELEMENTS CONTROLLED BY THE DIF           *
//*-------------------------------------------------------------------*
//SCANCODE EXEC PGM=IRXJCL,PARM='EVCSERET &ELE &TCCI'                   00400000
//SYSEXEC  DD DSN=PGEV.BASE.REXX,DISP=SHR                               00181003
//ELEMENT  DD DSN=TTYY.CASEGEN.SOURCE(&ELE),DISP=SHR /*INPUT*/
//SCL      DD DSN=&&SCL,DISP=(NEW,PASS),SPACE=(TRK,(1,1)), /*OUTPUT*/
//             LRECL=80,RECFM=FB
//DOWNLOAD DD DSN=&&APPC,DISP=(NEW,PASS),SPACE=(TRK,(1,1)), /*OUTPUT*/
//             LRECL=80,RECFM=FB
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD DUMMY
//*
//CHECKIT  IF SCANCODE.RC NE 0 THEN
//*-------------------------------------------------------------------*
//*  ABEND IF SCANCODE STEP GIVES HIGHER THAN ZERO RETURN CODE        *
//*-------------------------------------------------------------------*
//@SPWARN  EXEC @SPWARN
//CHECKIT  ENDIF
//*
//*-------------------------------------------------------------------*
//*  RETRIEVE THE ELEMENTS THAT THE DIF USES, READY FOR THE ADD       *
//*-------------------------------------------------------------------*
//NDVRRET  EXEC PGM=NDVRC1,DYNAMNBR=1500,PARM='C1BM3000'
//APIPRINT DD SYSOUT=Z
//HLAPILOG DD SYSOUT=*
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//BSTIPT01 DD DSN=&&SCL,DISP=(OLD,DELETE)
//*
//CHECKIT  IF NDVRRET.RC NE 0 THEN
//*-------------------------------------------------------------------*
//*  ABEND IF NDVRRET STEP GIVES HIGHER THAN ZERO RETURN CODE         *
//*-------------------------------------------------------------------*
//@SPWARN  EXEC @SPWARN
//CHECKIT  ENDIF
//*
//*-------------------------------------------------------------------*
//*  TRANSFER THE DIF CODE TOP THE CASEGEN SERVER                     *
//*-------------------------------------------------------------------*
//TRANSFER EXEC PGM=CPBD0101
//STEPLIB  DD DSN=PGLJ.BASE.LOAD,DISP=SHR
//SYSOUT   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=C
//SYSIN    DD DSN=&&APPC,DISP=(OLD,DELETE)
//*
//CHECKIT  IF TRANSFER.RC NE 0 THEN
//*-------------------------------------------------------------------*
//*  ABEND IF TRANSFER STEP GIVES HIGHER THAN ZERO RETURN CODE        *
//*-------------------------------------------------------------------*
//@SPWARN  EXEC @SPWARN
//CHECKIT  ENDIF
