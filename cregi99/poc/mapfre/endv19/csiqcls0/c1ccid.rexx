 PROC 0 DEBUG()                                                         00010003
 GLOBAL PNLCSR PNLMSG                                                   00020003
/********************************************************************/  00030003
/* CLIST TO ALLOW EDITTING OF THE CCID VALIDATAION DATASET          */  00040003
/*   CHANGES WHICH NEED TO MADE TO IMPLEMENT THIS CLIST          */     00050003
/*       1) THE ALLOCATIONS OF TEMPCCID AND NDVRCCID NEED TO BE     */  00060003
/*          MODIFIED  TO  REFLECT USER'S SITE.                      */  00061003
/*       2) THE CLIST C1CCID NEEDS TO BE ADDED TO THE               */  00062003
/*          IPRFX.IQUAL.CSIQCLS0.                                   */  00063003
/********************************************************************/  00064003
/********************************************************************/  00065003
/* SET UP DEBUGGING AND RUN PARAMETERS                              */  00066003
/********************************************************************/  00067003
  IF &DEBUG = &STR(DEBUG) +                                             00068003
     THEN CONTROL MSG NOFLUSH LIST CONLIST SYMLIST NOPROMPT ASIS        00069003
  ELSE CONTROL NOMSG NOFLUSH NOLIST NOCONLIST NOSYMLIST NOPROMPT        00070003
/********************************************************************/  00071003
/*            ISPF ACTIVE                                           */  00080003
/********************************************************************/  00081003
 IF &SYSISPF NE ACTIVE THEN DO                                          00090003
                           WRITE THIS CLIST MUST BE INVOKED UNDER ISPF  00100003
                           EXIT                                         00110003
                           END                                          00120003
/*                                                                  */  00130003
/*********************************************************************/ 00140003
/*    ALLOCATE CCID FILE & A TEMP FILE FOR EDITING                   */ 00150003
/*    THE SP ALLOCATION, THE UNIT, THE BKLSIZE AND TRACK OR CYL      */ 00151003
/*     NEED TO BE MODIFY IN ALLOCIATION OF THE TEMPCCID FILE         */ 00152003
/*    THE FILE NAME NEEDS TO MODIFY IN THE ALLOCATION OF NDVRCCID    */ 00153003
/*********************************************************************/ 00154003
 ISPEXEC VGET (ZSCREEN,ZUSER)                                           00155003
/*********************************************************************/ 00155103
/*             CCID FILE EXISTS                                      */ 00156003
/*********************************************************************/ 00156103
 SET &CCID   = 'IPRFX.IQUAL.CCID'                                       00157003
 SET &STATUS = &SYSDSN(&CCID)                                           00158003
 IF &STATUS NE OK THEN DO                                               00159003
                       WRITE CCID DATA SET NOT VALID -> &STATUS         00160003
                       WRITE &CCID                                      00170003
                       EXIT                                             00171003
                       END                                              00172003
/*                                                                  */  00173003
 SET &TMPCCID = &STR(&ZUSER..NDVR&ZSCREEN..CNTL)                        00174003
 ALLOC F(TEMPCCID) DA('&TMPCCID') SP(5 5) MOD TRACK -                   00175003
      LRECL(80) BLKSIZE(800) RECFM(F B) REUSE UNIT(SYSDA)               00176003
 ALLOC FILE(NDVRCCID) DA(&CCID) SHR                                     00177003
 ERROR DO                                                               00192003
      SET &RC = &LASTCC                                                 00193003
      IF &RC = 400 THEN SET &EOF = ON                                   00194003
      IF &RC GT 400 THEN SET &ERROR = ON                                00195003
      RETURN                                                            00196003
      END                                                               00197003
/*    COPY CCID DATASET INTO TEMP FILE FOR EDITING   */                 00198003
  OPENFILE NDVRCCID INPUT                                               00199003
  OPENFILE TEMPCCID OUTPUT                                              00200003
  SET &EOF = OFF                                                        00210003
  SET &ERROR = OFF                                                      00220003
 READCCID: +                                                            00230003
   GETFILE NDVRCCID                                                     00240003
   IF &EOF = ON THEN GOTO EOFCCID                                       00250003
         SET &TEMPCCID = &NDVRCCID                                      00260003
         PUTFILE TEMPCCID                                               00270003
   GOTO READCCID                                                        00280003
 EOFCCID: +                                                             00290003
   CLOSFILE NDVRCCID INPUT                                              00300003
   CLOSFILE TEMPCCID OUTPUT                                             00310003
/*********************************************************************/ 00320003
/*   EDIT THE TEMP FILE                                              */ 00330003
/*********************************************************************/ 00340003
 ISPFEDIT: +                                                            00350003
    ISPEXEC EDIT     DATASET ('&TMPCCID')                               00360003
    SET &RC  = 0                                                        00370003
/*      COPY TEMPFILE INTO CCID DATASET                */               00380003
  OPENFILE NDVRCCID OUTPUT                                              00390003
  OPENFILE TEMPCCID INPUT                                               00400003
   SET &EOF = OFF                                                       00410003
   SET &ERROR = OFF                                                     00420003
 COPYCCID: +                                                            00430003
   GETFILE TEMPCCID                                                     00440003
   IF &EOF = ON THEN GOTO EOFCOPY                                       00450003
       SET &NDVRCCID = &TEMPCCID                                        00460003
       PUTFILE NDVRCCID                                                 00470003
   GOTO COPYCCID                                                        00480003
 EOFCOPY: +                                                             00490003
   CLOSFILE NDVRCCID                                                    00500003
   CLOSFILE TEMPCCID                                                    00510003
  FREE FILE(NDVRCCID)                                                   00520003
  FREE FILE(TEMPCCID) DELETE                                            00530003
 EXIT                                                                   00540003
