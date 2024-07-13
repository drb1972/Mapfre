//*
//**********************************************************************
//** BACKOUT ENDEVOR PACKAGE                                          **
//**********************************************************************
//PACKBOUT EXEC PGM=NDVRC1,PARM='ENBP1000',COND=(4,LT)
//APIPRINT DD SYSOUT=*
//HLAPILOG DD SYSOUT=*
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//SYSTERM  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSABEND DD SYSOUT=C
//ENPSCLIN DD *
  BACKOUT PACKAGE &PKG  .
/*
//**********************************************************************
//** SPWARN - EXECUTE IF ENDEVOR BACKOUT FAILS                        **
//**********************************************************************
//CHECKIT  IF (PACKBOUT.RC GT 4) THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
