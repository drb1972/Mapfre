//&ZPREFIX.XP3Q JOB CLASS=X,MSGCLASS=X,NOTIFY=&ZUSER                    JOB02673
//*ROUTE XEQ RBJESQ1
//*
//*
//*----------------------------------------------------------------
//* BATCH FILE UTILITY    OPTION: IMPORT      JES TYPE: 2
//*----------------------------------------------------------------
//UTILITY  EXEC  PGM=CWDDSUTL,REGION=4M,COND=(8,LT)
//STEPLIB  DD  DISP=SHR,DSN=SYSCOMPU.ECC.SLCXLOAD
//ABNLREPT DD  SYSOUT=*
//ABNLTERM DD  SYSOUT=*
//ABNLFROM DD  DISP=SHR,DSN=&EXPORTDS
//ABNLTO   DD  DISP=SHR,DSN=&DDIOFIL2
//ABNLPARM DD  *
IMPORT
/*
//CHECKIT  IF  UTILITY.RC GT 0 THEN                                     00010000
//@SPWARN  EXEC @SPWARN                                                 00020000
//CHECKIT  ENDIF                                                        00030000
//*                                                                     00040000
