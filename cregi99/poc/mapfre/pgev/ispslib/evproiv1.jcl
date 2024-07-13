//&ZPREFIX.PRO4 JOB 1,'&ZUSER - PRO-IV',
//             NOTIFY=&ZUSER,CLASS=3
//*
//************************************
//* DELETE MOVE AND ADD SCL DATASETS *
//************************************
//STEP005  EXEC PGM=IEFBR14
//ADDSCL   DD DSN=&ZPREFIX..&ZUSER..PROIV.ADDSCL,
//             DISP=(MOD,DELETE,DELETE),
//             SPACE=(TRK,(5,5)),
//             RECFM=FB,LRECL=80
//MOVESCL  DD DSN=&ZPREFIX..&ZUSER..PROIV.MOVESCL,
//             DISP=(MOD,DELETE,DELETE),
//             SPACE=(TRK,(5,5)),
//             RECFM=FB,LRECL=80
//PRODSCL  DD DSN=&ZPREFIX..&ZUSER..PROIV.PRODSCL,
//             DISP=(MOD,DELETE,DELETE),
//             SPACE=(TRK,(5,5)),
//             RECFM=FB,LRECL=80
//*
//*******************************
//* BUILD THE ADD AND MOVE SCL  *
//*******************************
//STEP010  EXEC PGM=EVPROIV1
//STEPLIB  DD DSN=PGEV.BASE.LOAD,DISP=SHR
//PARMS    DD DISP=SHR,DSN=&C5PARMS
//CTRL     DD *
DSN-STUB:  &C4DSN.
COMMENT:   &C4COMM.
CCID:      &C4CCID.
SUBSYSTEM: &C4SUBSYS.
BOOTS:     &C4BOOTS.
CICS:      &C4CICS.
CMR-TYPE:  &C4CMRTYP.
/*
//ADDSCL   DD DSN=&ZPREFIX..&ZUSER..PROIV.ADDSCL,
//             DISP=(NEW,CATLG,),SPACE=(TRK,(5,5)),
//             RECFM=FB,LRECL=80
//MOVESCL  DD DSN=&ZPREFIX..&ZUSER..PROIV.MOVESCL,
//             DISP=(NEW,CATLG,),SPACE=(TRK,(5,5)),
//             RECFM=FB,LRECL=80
//PRODSCL  DD DSN=&ZPREFIX..&ZUSER..PROIV.PRODSCL,
//             DISP=(NEW,CATLG,),SPACE=(TRK,(5,5)),
//             RECFM=FB,LRECL=80
//SYSOUT   DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//*
//*        IF ADD AND MOVE SCL CREATED OKAY:
//@050     IF STEP010.RC LE 4 THEN
//*
//***********************
//** RUN THE ADD SCL    *
//***********************
//ADDSCL   EXEC PGM=NDVRC1,DYNAMNBR=1500,PARM='C1BM3000'
//SORTWK01 DD SPACE=(CYL,(20,10))
//SORTWK02 DD SPACE=(CYL,(20,10))
//SORTWK03 DD SPACE=(CYL,(20,10))
//SORTWK04 DD SPACE=(CYL,(20,10))
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//C1PRINT  DD SYSOUT=*,RECFM=FBA,LRECL=121
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//PRODSCL  DD DSN=&ZPREFIX..&ZUSER..PROIV.PRODSCL,DISP=SHR
//BOOTS    DD *
 DUMMY ELEMENT - LOOK IN PREV.XXXX.BOOTS
/*
//BSTIPT01 DD DSN=&ZPREFIX..&ZUSER..PROIV.ADDSCL,
//             DISP=(OLD,DELETE,)
//*
)CM
)CM <<<<<<< ONLY RUN THE MOVE SCL IF IT IS A STANDARD CMR >>>>>>
)CM
)SEL &C4CMRTYP = STANDARD
//*
//*        IF ADD ACTIONS WORKED OKAY:
//@150     IF ADDSCL.RC LE 8 THEN
//*
//**********************
//** RUN THE MOVESCL   *
//**********************
//MOVESCL  EXEC PGM=NDVRC1,DYNAMNBR=1500,PARM='C1BM3000'
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//C1PRINT  DD SYSOUT=*,RECFM=FBA,LRECL=121
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//BSTIPT01 DD DSN=&ZPREFIX..&ZUSER..PROIV.MOVESCL,
//             DISP=(OLD,DELETE,)
//*
//@150     ENDIF
//*
)ENDSEL
//*
//*        IF PROD SCL CREATED OKAY:
//********************************
//** CREATE PRODUCTION PACKAGE   *
//********************************
//CREPKG   EXEC PGM=NDVRC1,PARM=ENBP1000
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//SYSABEND DD SYSOUT=*
//PRODSCL  DD DSN=&ZPREFIX..&ZUSER..PROIV.PRODSCL,
//             DISP=(OLD,DELETE,)
//ENPSCLIN DD *
DEFINE PACKAGE &C5CCID.P
IMPORT SCL FROM DDNAME PRODSCL
DESCRIPTION '&C4COMM.'
OPT SHARABLE PACKAGE       .
/*
//*
//*
//*        IF ALL STEPS OKAY:
//@250     IF ADDSCL.RC  LE 8 AND
)CM
)CM <<<<<< ONLY CHEK MOVESCL.RC IF A STANDARD CMR >>>>>>>>>
)CM
)SEL &C4CMRTYP = STANDARD
//            MOVESCL.RC LE 8 AND
)ENDSEL
//            CREPKG.RC LE 4 THEN
//*
//******************************
//** CAST PRODUCTION PACKAGE   *
//******************************
//CASTPKG  EXEC PGM=NDVRC1,PARM=ENBP1000
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//SYSABEND DD SYSOUT=*
//ENPSCLIN DD *
CAST PACKAGE &C5CCID.P .
/*
//@250     ENDIF
//@050     ENDIF
