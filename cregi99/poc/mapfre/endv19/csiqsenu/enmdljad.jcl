// INCLUDE MEMBER=SCMM@SYM     <=== INCLUDE ENDEVOR SYMBOLS
//*-------------------------------------------------------------------*
//*    BATCH JCL STATEMENTS                                           *
//*-------------------------------------------------------------------*
//ENDEVOR  EXEC PGM=NDVRC1,
//             DYNAMNBR=1500,
//             REGION=4096K,
//             PARM='ENBE1000'
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
//* THE ENESCLIN DD STATEMENT CONTAINS THE BATCH ADMINISTRATION       *
//* FACILITY CONTROL STATEMENTS.                                      *
//*-------------------------------------------------------------------*
//ENESCLIN DD *
