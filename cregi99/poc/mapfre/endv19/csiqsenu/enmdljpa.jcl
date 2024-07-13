// INCLUDE MEMBER=SCMM@SYM     <=== INCLUDE ENDEVOR SYMBOLS
//*-------------------------------------------------------------------*
//*    BATCH JCL STATEMENTS                                           *
//*-------------------------------------------------------------------*
//ENDEVOR  EXEC PGM=NDVRC1,
//             DYNAMNBR=1500,
//             REGION=4096K,
//             PARM='ENBP1000'
// INCLUDE MEMBER=SCMM@LIB     <=== INCLUDE ENDEVOR LIBS
//*-------------------------------------------------------------------*
//*  OUTPUT DATA SETS                                                 *
//*-------------------------------------------------------------------*
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYMDUMP  DD DUMMY
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//*-------------------------------------------------------------------*
//* JCLOUT IS THE DESTINATION OF THE JCL CREATED BY THE SUBMIT PACKAGE*
//* ACTION.                                                           *
//*-------------------------------------------------------------------*
//JCLOUT   DD SYSOUT=(A,INTRDR),DCB=(LRECL=80,RECFM=F,BLKSIZE=80)
//*-------------------------------------------------------------------*
//* THE ENPSCLIN DD STATEMENT CONTAINS THE BATCH PACKAGE FACILITY     *
//* CONTROL STATEMENTS.                                               *
//*-------------------------------------------------------------------*
//ENPSCLIN DD *
