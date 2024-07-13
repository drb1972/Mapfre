/*
//*********************************************************************
//** SKELETON CMSSHP2R                                               **
//*********************************************************************
//** IEBGENER - PRINT THE SHIPMENT DESTINATION REPORT.               **
//*********************************************************************
//PRTSHDET EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SHIPHLQC..XDET,DISP=SHR
//SYSUT2   DD SYSOUT=*
//SYSIN    DD DUMMY
//*
//*********************************************************************
//** SPWARN - ABEND IF SHIPMENT RETURN CODE IS GREATER THAN ZERO     **
//*********************************************************************
//CHECKIT  IF SHIPMENT.RC GT 4 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//*********************************************************************
//** IDCAMS - LISTCAT THE SHIPMENT DESTINATION REPORT.               **
//*********************************************************************
//ARCCHECK EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
 LISTC ENT(&SHIPHLQC..ARCHIVE.COPYJCL) NAME
 IF MAXCC >> 0 THEN SET MAXCC = 1
/*
//DOSHPDET IF ARCCHECK.RC EQ 0 THEN
//*********************************************************************
//** IKJEFT1B - SHIPSCAN SCANS SHIPMENT DETAIL REPORT TO FIND        **
//**          DELETED LOAD, OBJECT OR CICS MEMBERS FROM PROD TO      **
//**          ARCHIVE. IT THEN BUILDS JCL TO COPY THE MEMBERS TO     **
//**          THE ARCH DATASETS AND SUBMITS THE JOB (EVARCOUT).      **
//*********************************************************************
//SHIPSCAN EXEC PGM=IKJEFT1B,
//             PARM='SHIPSCAN &SHIPHLQC &CMR'
)SEL &C1SY = EK
//SYSEXEC  DD DSN=PREV.FEV1.REXX,DISP=SHR
//         DD DSN=&EVBASE..BASE.REXX,DISP=SHR
)ENDSEL
)SEL &C1SY ^= EK
//SYSEXEC  DD DSN=&EVBASE..BASE.REXX,DISP=SHR
)ENDSEL
//REPIN    DD DSN=&SHIPHLQC..XDET,DISP=SHR
//JCLOUT   DD DSN=&SHIPHLQC..ARCHIVE.COPYJCL,DISP=MOD
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD DUMMY
//*
//*********************************************************************
//** IEBGENER - IF ARCHIVED ELEMENTS THEN SUB THE JCL CREATED IN     **
//**            THE TEMPORARY DATASET COPYJCL BY THE PACKSCAN STEP   **
//*********************************************************************
//CHCKSCAN IF SHIPSCAN.RC LE 4 THEN
//*
//SUBMIT   EXEC PGM=IEBGENER
//SYSUT1   DD DSN=&SHIPHLQC..ARCHIVE.COPYJCL,DISP=SHR
//         DD DATA,DLM=##
//*
//*********************************************************************
//** DELETE INTERMEDIATE ARCHIVE JCL FOR THIS JOB                    **
//*********************************************************************
//DELETE   EXEC PGM=IEFBR14
//DD1      DD DSN=&SHIPHLQC..ARCHIVE.COPYJCL,
//             DISP=(OLD,DELETE)
##
//SYSUT2   DD SYSOUT=(A,INTRDR)
//SYSIN    DD DUMMY
//SYSPRINT DD SYSOUT=*
//*
//CHCKSCAN ENDIF
//*
//DOSHPDET ENDIF
//*
//*********************************************************************
//** IEFBR14 - DELEDET DELETE THE SHIPMENT DETAIL REPORT AFTER USE   **
//*********************************************************************
//DELEDET  EXEC PGM=IEFBR14
//REPIN    DD DSN=&SHIPHLQC..XDET,
//             DISP=(OLD,DELETE)
//*
//*********************************************************************
//** SPWARN - ABEND IF SHIPSCAN RETURN CODE IS GREATER THAN 4        **
//*********************************************************************
//CHECKIT  IF SHIPSCAN.RC GT 4  THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
