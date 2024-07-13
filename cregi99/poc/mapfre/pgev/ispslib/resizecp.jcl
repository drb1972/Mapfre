&EWJCL1
&EWJCL2
&EWJCL3
&EWJCL4
//* +----------------------------------------------------------+
//* + COPY &IDSN
//* +   TO &NDSN
//* +----------------------------------------------------------+
//COPY     EXEC PGM=IEBCOPY
//FCOPYON  DD DUMMY
//SYSPRINT DD SYSOUT=*
//PDSIN    DD DSN=&IDSN,
//            DISP=SHR
//PDSOUT   DD DSN=&NDSN,
//            DISP=(NEW,CATLG),
//            RECFM=&IRFM,LRECL=&ILRL,BLKSIZE=&IBLKSZ,
//            SPACE=(&LUNITS,(&LPRI,&LSEC,&LDIR)&RLSEJ),
//            DSNTYPE=PDS
//SYSIN    DD *
  COPY OUTDD=PDSOUT,INDD=((PDSIN,R))
  EXCLUDE MEMBER=$$$SPACE
//SYSUT3   DD SPACE=(CYL,(30,30),RLSE),UNIT=SYSDA WORK FILE 1
//SYSUT4   DD SPACE=(CYL,(30,30),RLSE),UNIT=SYSDA WORK FILE 2
//* +----------------------------------------------------------+
//* + SEND MESSAGE ON FAILURE                                  +
//* +----------------------------------------------------------+
//IF08000   IF RC GT 0 THEN
//MESSAGE  EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=Z
//SYSPRINT DD SYSOUT=Z
//SYSTSIN  DD *
SE 'COPY FAILED FOR   &IDSN' -
U(&SYSUID) LOGON
SE 'COPY FAILED FOR   &IDSN' -
U(&SYSUID) LOGON
SE 'COPY FAILED FOR   &IDSN' -
U(&SYSUID) LOGON
SE 'COPY FAILED FOR   &IDSN' -
U(&SYSUID) LOGON
SE 'COPY FAILED FOR   &IDSN' -
U(&SYSUID) LOGON
//IF08000   ENDIF
