//*--SKELETON CMSBBBR  - POST IMPLEMENTATION TASKS                   --
//*********************************************************************
//** ICEGENER - SET BACKOUT FLAG IN CMR                              **
//**            ADD WHICHPLEX STEPS                                  **
//*********************************************************************
//&STEPNAME  EXEC PGM=ICEGENER
//SYSUT1   DD DATA,DLM=##
//***************************************************
//** EXECUTE IF ANY STEP HAS ABENDED OR RC GT 4    **
//***************************************************
//CHECKIT  IF (ABEND OR RC GT 4) THEN
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//*-- NDVEDIT STEPS AFTER IEBCOPY --
//*
//***************************************************
//** SET THE BACKOUT FLAG IN THE CMR               **
//***************************************************
//CMSCMSG  EXEC PGM=IKJEFT1B
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
 SEND 'EV000202 ENDEVOR CJOB: &CMR COMPLETED - STATUS: BACKOUT'
/*
//*
//***************************************************
//** CHECK RETURN CODE OF CMR UPDATE               **
//***************************************************
//CHECKIT  IF (CMSCMSG.RUN AND CMSCMSG.RC GT 0) THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
)SEL &C1SY ^= SQ
//***************************************************
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
//** THE PPLEX AND WE SHOULD RUN THE CJOB ON FROW  **
//***************************************************
//IFP1     IF WHICHPLX.RC = 2 THEN
//***************************************************
//** ADD JOB TO CA7 AND DEMAND THAT JOB            **
//***************************************************
//PROC010  EXEC @SASBSTR,HLQ=PROS,LOCN=FROW
//SYSIN    DD *
JOB
ADD,&BKID,SYSTEM=ENDEVOR,EXEC=N,JCLID=000,RELOAD=X
DBM
DEMAND,JOB=&BKID,CLASS=6
/*
//SYSPRINT DD DSN=&&CA7OUT,DISP=(,PASS),
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
)ENDSEL
//*
##
//SYSUT2   DD DSN=&BJOBDSET,DISP=MOD
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//*
//*********************************************************************
//** SPWARN - ABEND IF &STEPNAME NOT EQUAL TO ZERO                   **
//*********************************************************************
//CHECKIT  IF &STEPNAME..RC NE 0 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
