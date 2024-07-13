//TTEVRSZE JOB ,CLASS=C,MSGCLASS=0,NOTIFY=&SYSUID
//*
//* +----------------------------------------------------------+
//* +  &IEBFUNC &IDSN
//* +----------------------------------------------------------+
//COPY     EXEC PGM=IEBCOPY
//FCOPYON  DD DUMMY
//SYSPRINT DD SYSOUT=*
//PDSIN    DD DSN=&IDSN,
)IF &ENQTYPE = O THEN
//            DISP=OLD
)ELSE
//            DISP=SHR
//SYSIN    DD *
  &IEBCMD
//SYSUT3   DD SPACE=(CYL,(30,30),RLSE),UNIT=SYSDA
//SYSUT4   DD SPACE=(CYL,(30,30),RLSE),UNIT=SYSDA
//* +----------------------------------------------------------+
//* + SEND MESSAGE ON FAILURE                                  +
//* +----------------------------------------------------------+
//IF08000   IF RC GT 0 THEN
//MESSAGE  EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=Z
//SYSPRINT DD SYSOUT=Z
//SYSTSIN  DD *
SE '&IEBFUNC FAILED FOR   &IDSN'                                       -
U(&SYSUID) LOGON
SE '&IEBFUNC FAILED FOR   &IDSN'                                       -
U(&SYSUID) LOGON
SE '&IEBFUNC FAILED FOR   &IDSN'                                       -
U(&SYSUID) LOGON
SE '&IEBFUNC FAILED FOR   &IDSN'                                       -
U(&SYSUID) LOGON
SE '&IEBFUNC FAILED FOR   &IDSN'                                       -
U(&SYSUID) LOGON
//IF08000   ENDIF
