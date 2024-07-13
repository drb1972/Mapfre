//*--SKELETON CMSCD                                                  --
//*********************************************************************
//** DMBATCH - INVOKE NDM TO COPY ALL DATASETS TO &DESTID             **
//*********************************************************************
//&STEPNAME  EXEC PGM=DMBATCH
//DMNETMAP DD DSN=&CDNETMAP,DISP=SHR
//DMMSGFIL DD DSN=&CDMSGF,DISP=SHR
//DMPUBLIB DD DSN=&SHIPHLQC..PROCESS.FILE,DISP=SHR
//SYSPRINT DD SYSOUT=*
//NDMCMNDS DD SYSOUT=*
//DMPRINT  DD SYSOUT=*
//SYSUDUMP DD SYSOUT=C
//SYSIN    DD *
 SIGNON
 SUBMIT PROC=&CDMEMBR NEWNAME=&RMEM
 SIGNOFF
/*
