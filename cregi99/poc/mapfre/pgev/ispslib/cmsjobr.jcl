//*--SKELETON CMSJOBR  - JOBCARD FOR CJOB/BJOB                       --
//*********************************************************************
//** ICEGENER - GENER START JCL TO TOP OF C JOB FOR &DESTID          **
//*********************************************************************
//C&STPNME EXEC PGM=ICEGENER
//SYSUT1   DD DATA,DLM=##
)SEL &C1SY = SQ
//&CMR JOB 1,'NDVR &PKG',CLASS=A,MSGCLASS=Y,
//             USER=RACFADM
)ENDSEL
)SEL &C1SY = WT
//&CMR JOB 1,'NDVR &PKG',CLASS=A,MSGCLASS=Y,
//             USER=PRODOPS
)ENDSEL
)SEL &C1SY ^= SQ && &C1SY ^= WT
//&CMR JOB 1,'NDVR &PKG',CLASS=A,MSGCLASS=Y,
//             USER=ENDVPUR
)ENDSEL
//*
##
//         DD DSN=&CJOBDSET,DISP=OLD
//SYSUT2   DD DSN=&CJOBDSET,DISP=OLD
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//*
//*********************************************************************
//** SPWARN - ABEND IF C&STPNME RETURN CODE IS NOT EQUAL TO ZERO     **
//*********************************************************************
//CHECKIT  IF C&STPNME..RC NE 0 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//*********************************************************************
//** ICEGENER - GENER START JCL TO TOP OF B JOB FOR &DESTID          **
//*********************************************************************
//B&STPNME EXEC PGM=ICEGENER
//SYSUT1   DD DATA,DLM=##
)SEL &C1SY = SQ
//&BKID JOB 1,'BACKOUT &PKG',CLASS=A,MSGCLASS=Y,REGION=6M,
//             USER=RACFADM
)ENDSEL
)SEL &C1SY = WT
//&BKID JOB 1,'BACKOUT &PKG',CLASS=A,MSGCLASS=Y,REGION=6M,
//             USER=PRODOPS
)ENDSEL
)SEL &C1SY ^= SQ && &C1SY ^= WT
//&BKID JOB 1,'BACKOUT &PKG',CLASS=A,MSGCLASS=Y,REGION=6M,
//             USER=ENDVPUR
)ENDSEL
//*
##
//         DD DSN=&BJOBDSET,DISP=OLD
//SYSUT2   DD DSN=&BJOBDSET,DISP=OLD
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//*
//*********************************************************************
//** SPWARN - ABEND IF B&STPNME RETURN CODE IS NOT EQUAL TO ZERO     **
//*********************************************************************
//CHECKIT  IF B&STPNME..RC NE 0 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
