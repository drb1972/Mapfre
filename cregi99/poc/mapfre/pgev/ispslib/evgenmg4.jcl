/*
//INVUPD   EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=TTYY.GENEROL.MIGRATE.DATA(&MEMNAM),DISP=SHR
//SYSUT2   DD DSN=TTYY.GENEROL.SYST.DATA,DISP=MOD
//SYSIN    DD DUMMY
/*
//INVSORT   EXEC PGM=SORT                                               00050000
//SORTIN   DD DSN=TTYY.GENEROL.SYST.DATA,DISP=SHR                       00060008
//SORTOUT  DD DSN=TTYY.GENEROL.SYST.DATA,DISP=SHR                       00070002
//SYSPRINT DD SYSOUT=*                                                  00080000
//SYSOUT   DD SYSOUT=*                                                  00090000
//SYSIN    DD *                                                         00100000
  SORT FIELDS=(1,80,CH,A)                                               00110006
  SUM FIELDS=NONE                                                       00120000
/*                                                                      00130000
