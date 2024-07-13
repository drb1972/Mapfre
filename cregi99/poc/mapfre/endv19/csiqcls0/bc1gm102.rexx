/*********************************************************************/
/*                                                                   */
/*  COPYRIGHT (C) 2022 BROADCOM. ALL RIGHTS RESERVED.               */
/*                                                                   */
/* NAME: WIPSHOW                                                     */
/*                                                                   */
/* FUNCTION: THIS ISPF/PDF EDIT MACRO IS USED TO SUPPORT THE WIPSHOW */
/* COMMAND.  THE WIPSHOW COMMAND WILL ALLOW THE USER TO DISPLAY ONLY */
/* THOSE LINES THAT ARE BEING INCLUDED FROM THE FILES SPECIFIED ON   */
/* THE WIPSHOW COMMAND.  ALL OTHER LINES ARE EXCLUDED FROM THE       */
/* DISPLAY.                                                          */
/*                                                                   */
/* SYNTAX: THE SYNTAX OF THE WIPSHOW COMMAND IS                      */
/*    WIPSHOW FILE_ID FILE_ID ...                                    */
/*                                                                   */
/*  AT LEAST ONE FILE_ID MUST BE SPECIFIED ON THE COMMAND. VALID     */
/* FILE_ID VALUES ARE:                                               */
/*    R - IDENTIFIES THE ROOT FILE                                   */
/*    1 - IDENTIFIES THE DERIVATIVE 1 FILE                           */
/*    2 - IDENTIFIES THE DERIVATIVE 2 FILE                           */
/*  IF A FILE_ID IS INVALID OR A FILE_ID IS NOT SPECIFIED, AN ERROR  */
/* MESSAGE WILL BE DISPLAYED AND THE WIPSHOW COMMAND WILL TERMINATE. */
/* AT MOST, THREE FILE_ID VALUES CAN BE SPECIFIED.  ANY EXTRA PARAM- */
/* ETERS WILL BE IGNORED.                                            */
/*                                                                   */
/*********************************************************************/

ISREDIT MACRO (FILEID1,FILEID2,FILEID3,FILEID4) NOPROCESS

/*********************************************************************/
/* SAVE THE CURRENT EDIT STATE AND SET THE DEFAULT RETURN CODE TO 0. */
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
/* USE THE ISPF/PDF EXCLUDE AND FIND COMMANDS TO SHOW ALL THE RECORDS*/
/* THAT MATCH THE FILE_IDS SPECIFIED BY THE USER.  ACCUMULATE THE    */
/* NUMBER OF RECORDS FOUND AND WRITE TOTAL AS A SHORT MESSAGE.       */
/*                                                                   */
/*********************************************************************/
ISREDIT RESET
ISREDIT UP MAX
ISREDIT EXCLUDE ALL

SET &FINDCNT = 0

IF (&FILEROOT = 1) THEN +
  DO
    ISREDIT FIND '     ' ALL CHARS 3
    ISREDIT (COUNT) = FIND_COUNTS
    SET &FINDCNT = &FINDCNT + &COUNT
  END

IF (&FILEDV1 = 1) THEN +
  DO
    ISREDIT FIND 'I-1' ALL CHARS 3
    ISREDIT (COUNT) = FIND_COUNTS
    SET &FINDCNT = &FINDCNT + &COUNT
  END

IF (&FILEDV2 = 1) THEN +
  DO
    ISREDIT FIND 'I-2' ALL CHARS 3
    ISREDIT (COUNT) = FIND_COUNTS
    SET &FINDCNT = &FINDCNT + &COUNT
    ISREDIT FIND 'I-1,2' ALL CHARS 3
    ISREDIT (COUNT) = FIND_COUNTS
    SET &FINDCNT = &FINDCNT + &COUNT
  END

ISREDIT EXCLUDE '*' ALL 1
ISREDIT (COUNT) = EXCLUDE_COUNTS
SET &FINDCNT = &FINDCNT - &COUNT

IF (&FINDCNT = 0) THEN +
  DO
   ISREDIT RESET EXCLUDED
   ISREDIT UP MAX
  END

SET &ZEDSMSG = &STR(&FINDCNT LINES FOUND)
SET &ZEDLMSG = &STR(&FINDCNT LINES MATCHED THE WIPSHOW CRITERIA)
ISPEXEC SETMSG MSG(ISRZ001)

SET &RETCODE = 1

/*********************************************************************/
/* SAVE THE CURRENT EDIT STATE AND SET THE DEFAULT RETURN CODE TO 0. */
/*********************************************************************/
EXIT:  +
ISREDIT USER_STATE = (STATUS)
EXIT CODE(&RETCODE)
