/*********************************************************************/
/*                                                                   */
/*  COPYRIGHT (C) 2022 BROADCOM. ALL RIGHTS RESERVED.               */
/*                                                                   */
/* NAME: WIPUNDEL                                                    */
/*                                                                   */
/* FUNCTION: THIS ISPF/PDF EDIT MACRO IS USED TO SUPPORT THE WIPUNDEL*/
/* COMMAND.  THE WIPUNDEL COMMAND WILL ALLOW THE USER TO UNDELETE ALL*/
/* THE LINES THAT HAD BEEN LOGICALLY DELETED BY THE WIPLDEL COMMAND. */
/*                                                                   */
/* SYNTAX: THE SYNTAX OF THE WIPUNDEL COMMAND IS                     */
/*    WIPUNDEL FILE_ID FILE_ID ...                                   */
/*                                                                   */
/*  AT LEAST ONE FILE_ID MUST BE SPECIFIED ON THE COMMAND. VALID     */
/* FILE_ID VALUES ARE:                                               */
/*    R - IDENTIFIES THE ROOT FILE                                   */
/*    1 - IDENTIFIES THE DERIVATIVE 1 FILE                           */
/*    2 - IDENTIFIES THE DERIVATIVE 2 FILE                           */
/*  IF A FILE_ID IS INVALID OR A FILE_ID IS NOT SPECIFIED, AN ERROR  */
/* MESSAGE WILL BE DISPLAYED AND THE WIPUNDEL COMMAND WILL TERMINATE.*/
/* AT MOST, THREE FILE_ID VALUES CAN BE SPECIFIED.  ANY EXTRA PARAM- */
/* ETERS WILL BE IGNORED.                                            */
/*                                                                   */
/*********************************************************************/
ISREDIT MACRO (FILEID1,FILEID2,FILEID3,FILEID4) NOPROCESS

/*********************************************************************/
/* SAVE THE CURRENT USER STATE AND SET THE DEFAULT RETURN CODE TO 0. */
/*********************************************************************/
ISREDIT (STATUS) = USER_STATE
SET &RETCODE = 0

/*********************************************************************/
/* VERIFY THAT AT LEAST ONE FILE_ID WAS SPECIFIED.  IF NOT, WRITE AN */
/* ERROR MESSAGE AND EXIT WITH A RETURN CODE OF 8.                   */
/*********************************************************************/
IF (&FILEID1 = &STR()) THEN  +
  DO
    SET &ZEDSMSG = &STR(FILE ID IS REQUIRED)
    SET &ZEDLMSG = &STR(SPECIFY AT LEAST ONE FILE ID ON THE COMMAND)
    ISPEXEC SETMSG MSG(ISRZ001)
    SET &RETCODE = 12
    GOTO EXIT
  END

/*********************************************************************/
/* VERIFY THAT THE FILE_ID VALUES SPECIFIED ARE VALID.  VALID VALUES */
/* ARE 'R', '1', AND '2'.                                            */
/*********************************************************************/
IF (&FILEID1 ^= &STR()) THEN +
  DO
    IF ((&STR(&FILEID1) ^= &STR(R)) && +
        (&STR(&FILEID1) ^= &STR(1)) && +
        (&STR(&FILEID1) ^= &STR(2))) THEN  +
      DO
        SET &ZEDSMSG = &STR(INVALID FILE ID)
        SET &ZEDLMSG = &STR(THE FILE ID SPECIFIED, &FILEID1, IS INVALID)
        ISPEXEC SETMSG MSG(ISRZ001)
        SET &RETCODE = 12
        GOTO EXIT
      END
    ELSE  +
      SET &FILECNT = 1
  END

IF (&FILEID2 ^= &STR()) THEN  +
  DO
    IF ((&STR(&FILEID2) ^= &STR(R)) && +
        (&STR(&FILEID2) ^= &STR(1)) && +
        (&STR(&FILEID2) ^= &STR(2))) THEN  +
      DO
        SET &ZEDSMSG = &STR(INVALID FILE ID)
        SET &ZEDLMSG = &STR(THE FILE ID SPECIFIED, &FILEID2, IS INVALID)
        ISPEXEC SETMSG MSG(ISRZ001)
        SET &RETCODE = 12
        GOTO EXIT
      END
    ELSE  +
      SET &FILECNT = 2
  END

IF (&FILEID3 ^= &STR()) THEN  +
  DO
    IF ((&STR(&FILEID3) ^= &STR(R)) && +
        (&STR(&FILEID3) ^= &STR(1)) && +
        (&STR(&FILEID3) ^= &STR(2))) THEN  +
      DO
        SET &ZEDSMSG = &STR(INVALID FILE ID)
        SET &ZEDLMSG = &STR(THE FILE ID SPECIFIED, &FILEID3, IS INVALID)
        ISPEXEC SETMSG MSG(ISRZ001)
        SET &RETCODE = 12
        GOTO EXIT
      END
    ELSE  +
      SET &FILECNT = 3
  END

/*********************************************************************/
/* LOOK AT THE FILE_ID VALUES SPECIFIED AND DETERMINE WHICH OF THE   */
/* FILE IDENTIFIERS HAVE BEEN SPECIFIED.  SET A FLAG TO INDICATE THAT*/
/* EACH OF THE FILE_IDS (ROOT, DV1 OR DV2) HAS BEEN SPECIFIED.       */
/*********************************************************************/
SET &FILEROOT = 0
SET &FILEDV1 = 0
SET &FILEDV2 = 0

IF (&FILEID1 ^= &STR()) THEN  +
  DO
    IF (&STR(&FILEID1) = &STR(R)) THEN +
      SET &FILEROOT = 1
    ELSE IF (&STR(&FILEID1) = &STR(1)) THEN +
            SET &FILEDV1 = 1
    ELSE  SET &FILEDV2 = 1
  END

IF (&FILEID2 ^= &STR()) THEN  +
  DO
    IF (&STR(&FILEID2) = &STR(R)) THEN +
      SET &FILEROOT = 1
    ELSE IF (&STR(&FILEID2) = &STR(1)) THEN +
            SET &FILEDV1 = 1
    ELSE  SET &FILEDV2 = 1
  END

IF (&FILEID3 ^= &STR()) THEN  +
  DO
    IF (&STR(&FILEID3) = &STR(R)) THEN +
      SET &FILEROOT = 1
    ELSE IF (&STR(&FILEID3) = &STR(1)) THEN +
            SET &FILEDV1 = 1
    ELSE  SET &FILEDV2 = 1
  END

/*********************************************************************/
/*                                                                   */
/* USE THE ISPF/PDF EXCLUDE, FIND AND CHANGE COMMANDS TO CHANGE THE  */
/* FIRST CHARACTER OF ALL LINES INSERTED OR DELETED BY THE SPECIFIED */
/* FILE IDENTIFIERS TO THE PDM 'IGNORE THE LINE' CHARACTER (AN AST-  */
/* ERICK)                                                            */
/*                                                                   */
/*********************************************************************/
ISREDIT RESET
ISREDIT UP MAX
ISREDIT EXCLUDE ALL

/*********************************************************************/
/* UNCOMMENT THE FOLLOWING CODE IF THE MACRO IS TO ALWAYS SET THE    */
/* EDIT RECOVERY MODE TO ON.                                         */
/*********************************************************************/
/* ISREDIT RECOVERY = ON                                             */

SET &CHGCNT = 0
SET &RETCODE = 1

IF (&FILEROOT = 1) THEN +
  DO
    ISREDIT FIND '*      ' ALL CHARS 1
  END

ISREDIT CHANGE '*' ' ' ALL CHARS NX 1
ISREDIT (RCHGCNT) = CHANGE_COUNTS

IF (&FILEDV1 = 1) THEN +
  DO
    ISREDIT FIND '* I-1' ALL CHARS 1
    ISREDIT FIND '*?I-1' ALL CHARS 1
  END

IF (&FILEDV2 = 1) THEN +
  DO
    ISREDIT FIND '* I-2 '  ALL CHARS 1
    ISREDIT FIND '*?I-2 '  ALL CHARS 1
    ISREDIT FIND '* I-1,2' ALL CHARS 1
  END

ISREDIT CHANGE '*' '%' ALL CHARS NX 1
ISREDIT (TCHGCNT) = CHANGE_COUNTS
SET &CHGCNT = &TCHGCNT + &RCHGCNT

IF (&CHGCNT > 0) THEN +
  DO
    ISREDIT LOCATE FIRST CHANGE
    ISREDIT RESET EXCLUDED
    ISREDIT WIPCOUNT
    SET &RETCODE = 0
  END
ELSE  +
  DO
    ISREDIT RESET
    ISREDIT UP MAX
    SET &RETCODE = 1
  END

SET &ZEDSMSG = &STR(&CHGCNT LINES UNDELETED)
SET &ZEDLMSG = &STR(&CHGCNT LINES HAVE BEEN LOGICALLY UNDELETED)
ISPEXEC SETMSG MSG(ISRZ001)

/*********************************************************************/
/* RESTORE THE USERS EDIT STATE AND EXIT THE MACRO WITH THE APPROP-  */
/* RIATE RETURN CODE.                                                */
/*********************************************************************/
EXIT:  +
ISREDIT USER_STATE = (STATUS)
EXIT CODE(&RETCODE)
