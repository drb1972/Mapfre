/*
//* THIS ELEMENT IS PROIVS05 IN THE EV SYSTEM TYPE SKELS
//*
//CHECKIT  IF NDVRADD.RC NE 0 THEN
//*
//NDVRADDC EXEC @SPWARN
//CHECKIT  ENDIF
//*
//JSTEP030 EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
 DELETE '&TEMPDSN1' PURGE
 DELETE '&TEMPDSN2' PURGE
/*
//CHECKIT  IF JSTEP030.RC NE 0 THEN
//*
//JSTEP040 EXEC @SPWARN
//CHECKIT  ENDIF
//*
//*********************************************************************
//*  END OF PRO IV / ENDEVOR JCL                                      *
//*********************************************************************
