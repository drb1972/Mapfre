//TTMTPRO4 JOB 0,'PRO IV / ENDEVOR',NOTIFY=&UID,MSGCLASS=0,CLASS=3
//*
//* THIS ELEMENT IS PROIVS01 IN THE EV SYSTEM TYPE SKELS
//*
//JSTEP010 EXEC PGM=IEBUPDTE,PARM=NEW
//SYSPRINT DD SYSOUT=*
//SYSUT2   DD DSN=&TEMPDSN2,DISP=(NEW,CATLG),
//             SPACE=(TRK,(15,15,45)),
//             RECFM=FB,LRECL=80
//SYSIN    DD *
