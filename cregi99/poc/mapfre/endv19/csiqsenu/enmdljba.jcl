// INCLUDE MEMBER=SCMM@SYM     <=== INCLUDE ENDEVOR SYMBOLS
//*-------------------------------------------------------------------*
//*    BATCH JCL STATEMENTS                                           *
//*-------------------------------------------------------------------*
//ENDEVOR  EXEC PGM=NDVRC1,
//             DYNAMNBR=1500,
//             REGION=4096K,
//             PARM='C1BM3000'
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
)N
)N  TO ENABLE THE FOLLOWING JCL, USE "MD" COMMANDS TO MARK AS DATA AND
)N  THEN USE "((" COMMANDS TO SHIFT THEM LEFT TO MAKE THEM VALID JCL.
)N
)N//*******************************************************************
)N//*  CONCURRENT ACTION PROCESSING REQUESTED
)N//*******************************************************************
)N//EN$CAPNN  DD SYSOUT=*
)N
)N//*------------------------------------------------------------------
)N//*  PANVALET AND LIBRARIAN SUPPORT.
)N//*------------------------------------------------------------------
)N//C1TPDD01 DD  UNIT=&T@DISK,
)N//             SPACE=(CYL,(1,1)),
)N//             DCB=(RECFM=VB,LRECL=260)
)N//C1TPDD02 DD  UNIT=&T@DISK,
)N//             SPACE=(CYL,(1,1)),
)N//             DCB=(RECFM=VB,LRECL=260)
)N//C1TPLSIN DD  UNIT=&T@DISK,
)N//             SPACE=(CYL,(1,1)),
)N//             DCB=(RECFM=FB,LRECL=80)
)N//C1TPLSOU DD  UNIT=&T@DISK,
)N//             SPACE=(CYL,(1,1))
)N//C1PLMSGS DD  SYSOUT=*
)N
//*-------------------------------------------------------------------*
//*  CONTROL STATEMENTS                                               *
//*-------------------------------------------------------------------*
//BSTIPT01 DD *
