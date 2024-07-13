//*--SKELETON CMSINFR  - INFOMAN FEEDBACK FOR CJOBS                  --
//*********************************************************************
//** ICEGENER  - MODS JCL TO CJOB FOR UPDATING ASSIGNMENT DATA       **
//**             ON CHANGE RECORDS                                   **
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
//** SET THE IMPL FLAG IN THE CMR                  **
//***************************************************
//STEP025  EXEC PGM=IKJEFT1B
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
 SEND 'EV000202 ENDEVOR CJOB: &CMR COMPLETED - STATUS: IMPL'
/*
//*
//***************************************************
//** CHECK RETURN CODE OF CMR UPDATE               **
//***************************************************
//CHECKIT  IF (STEP025.RUN AND STEP025.RC GT 0) THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//***************************************************
//** SET THE IMPLFAIL FLAG IN THE CMR              **
//***************************************************
//CHECKIT  IF ABEND THEN
//*
//STEP035  EXEC PGM=IKJEFT1B,COND=EVEN
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
 SEND 'EV000202 ENDEVOR CJOB: &CMR COMPLETED - STATUS: IMPLFAIL'
/*
//CHECKIT  ENDIF
//*
//***************************************************
//** CHECK RETURN CODE OF CMR UPDATE               **
//***************************************************
//CHECKIT  IF (STEP035.RUN AND STEP035.RC GT 0) THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//***************************************************
//** EXECUTE IF ANY OF THE STEPS RAISE A CC GT 8   **
//***************************************************
//CHECKIT  IF RC GT 8 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
##
//SYSUT2   DD DSN=&CJOBDSET,DISP=MOD
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//*
//*********************************************************************
//** SPWARN - ABEND IF &STEPNAME RETURN CODE GT ZERO                 **
//*********************************************************************
//CHECKIT  IF &STEPNAME..RC GT 0 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
