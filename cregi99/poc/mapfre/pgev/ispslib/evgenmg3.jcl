//*
//GENMIG&SGTLIB  EXEC PGM=SG#BMIG
//STEPLIB  DD  DSN=PGLN.GENEROL.LOADLIB,DISP=SHR
//TABLES   DD  DSN=PGLN.GENEROL.LOADLIB,DISP=SHR
//SGTLIB1  DD  DSN=&INLIB1,DISP=SHR
//SGTLIB2  DD  DSN=&INLIB2,DISP=SHR
//SGTLIBC  DD  DSN=PGEV.VGENEROL.SGTLIBC,DISP=SHR
//FROMLIB1 DD  DSN=&INLIB1,DISP=SHR
//FROMLIB2 DD  DSN=&INLIB2,DISP=SHR
//TOLIB1U  DD  DSN=TTLN.MIGRATE.VGENEROL.SGTLIBU,DISP=SHR
//TOLIB2U  DD  DSN=TTLN.MIGRATE.VGENEROL.SGTLIBU,DISP=SHR
//TOLIB1   DD  DSN=&OUTLIB1,DISP=SHR
//TOLIB2   DD  DSN=&OUTLIB2,DISP=SHR
//SYSUDUMP DD  SYSOUT=*
//SYSPRINT DD  SYSOUT=*
//PRINTER  DD  SYSOUT=*
//CARDIN   DD  *
