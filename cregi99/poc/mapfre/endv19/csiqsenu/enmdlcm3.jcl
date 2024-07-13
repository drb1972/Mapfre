//*-------------------------------------------------------------------*
//*    SAVE A COPY OF MESSAGES IN CASE OF ERROR                       *
//*-------------------------------------------------------------------*
//EN$DPMSG DD DISP=(NEW,PASS,KEEP),DSN=&EN$DPMSG,
//         LRECL=133,RECFM=FBA,BLKSIZE=0,UNIT=SYSDA,
//         SPACE=(CYL,(10,5),RLSE)
//*-------------------------------------------------------------------*
//*    PROCESS C1MSGS3 IF THERE WAS AN ERROR                          *
//*-------------------------------------------------------------------*
//IFNDVERR IF (ABEND | RC > 0) THEN
//C1SMGS3  EXEC PGM=IRXJCL,PARM='ENDVHIC3'
//EN$DPMSG DD DISP=(OLD,DELETE,DELETE),DSN=&EN$DPMSG
//SYSEXEC  DD DISP=SHR,DSN=&I@PRFX..&I@QUAL..CSIQCLS0
//C1MSGS3  DD SYSOUT=*,RECFM=VBA
//SYSTSPRT DD DUMMY
//IFNDVER$ ENDIF
