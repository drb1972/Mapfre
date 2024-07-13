)SEL &C1SY ^= SQ
//*********************************************************************
//** SKELETON CMSCCCR                                                **
//** ICEGENER - MODS JCL TO CJOB FOR ANY REMOTE SUBMISSION           **
//**            REQUIRED                                             **
//*********************************************************************
//&STEPNAME  EXEC PGM=ICEGENER
//SYSUT1   DD DATA,DLM=##
//***************************************************
//** CREATED FROM SKELETON CMSCCCR                 **
//**                                               **
//** IF PPLEX THEN RC=2                            **
//** IF NPLEX THEN RC=3                            **
//** IF QPLEX THEN RC=4                            **
//** IF MPLEX THEN RC=5                            **
//** IF EPLEX THEN RC=6                            **
//** IF CPLEX THEN RC=7                            **
//** IF DPLEX THEN RC=8                            **
//** IF FPLEX THEN RC=9                            **
//** ELSE IT WILL GIVE A RETURN CODE OF 0.         **
//** THIS ENABLES CLONED SHIPMENTS TO              **
//** IGNORE THE CA7FROW STEP AND THE SUBMISSION    **
//** OF A JOB TO THE QPLEX TO UPDATE INFOMAN WHERE **
//** MSF LINKS ARE NOT AVAILABLE.                  **
//***************************************************
//WHICHPLX EXEC PGM=IRXJCL,PARM='EVPLEXRC'
//SYSEXEC  DD DSN=&EVBASE..BASE.REXX,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD DUMMY
//*
//***************************************************
//** ABEND IF WHICHPLX RETURN CODE GREATER THAN 9  **
//***************************************************
//CHECKIT  IF (WHICHPLX.RC GT 9) THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//***************************************************
//** IF THE WHICHPLX RETURN CODE WAS TWO THIS IS   **
//** THE PPLEX AND WE SHOULD DEMAND THE DUMMY JOB  **
//** ON TO FROW.                                   **
//***************************************************
//IFP1     IF WHICHPLX.RC = 2 THEN
//***************************************************
//** ADD JOB TO CA7 AND DEMAND THAT JOB            **
//***************************************************
//PROC010  EXEC @SASBSTR,HLQ=PROS,LOCN=FROW
//SYSIN    DD *
JOB
ADD,&CMR,SYSTEM=ENDEVOR,EXEC=N,JCLID=000,RELOAD=X
DBM
DEMAND,JOB=&CMR,CLASS=6
/*
//SYSPRINT DD DSN=&&CA7OUT,DISP=(NEW,PASS),
//             SPACE=(TRK,(15,15),RLSE),RECFM=FB,
//             LRECL=80
//*
//***************************************************
//** CHECK THE CA7 OUTPUT FOR ERRORS               **
//***************************************************
//STEP110  EXEC PGM=IRXJCL,PARM='CA7CHECK FROW'
//SYSEXEC  DD DSN=&EVBASE..BASE.REXX,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD SYSOUT=*
//CA7IN    DD DSN=&&CA7OUT,DISP=(OLD,DELETE)
//CA7OUT   DD SYSOUT=*
//*
//***************************************************
//** SPWARN IF CA7 BATCH TERMINAL FAILS            **
//***************************************************
//CHECKIT  IF (STEP110.RUN AND STEP110.RC GT 0) THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//IFP1X    ENDIF
//*
##
//SYSUT2   DD DSN=&CJOBDSET,DISP=MOD
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//*
//*********************************************************************
//** SPWARN - ABEND IF &STEPNAME RETURN CODE IS GREATER THAN ZERO    **
//*********************************************************************
//CHECKIT  IF &STEPNAME..RC GT 0 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
)ENDSEL
