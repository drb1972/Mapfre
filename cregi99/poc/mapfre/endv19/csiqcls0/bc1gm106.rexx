/*********************************************************************/
/*                                                                   */
/*  COPYRIGHT (C) 2022 BROADCOM. ALL RIGHTS RESERVED.               */
/*                                                                   */
/* NAME: WIPPARA                                                     */
/*                                                                   */
/* FUNCTION: THIS ISPF/PDF EDIT MACRO IS USED TO SUPPORT THE WIPPARA */
/* COMMAND.  THE WIPPARA COMMAND WILL IDENTIFY AND MARK PARAGRAPHS   */
/* THOSE LINES THAT ARE BEING INCLUDED FROM THE FILES SPECIFIED ON   */
/* IN A WIP FILE.  A PARAGRAPH IS DEFINED AS ONE OR MORE LINES OF    */
/* TEXT THAT ARE EITHER INSERTED OR DELETED FROM THE SAME DERIVATION */
/* FILE.                                                             */
/*                                                                   */
/* SYNTAX: THE SYNTAX OF THE WIPPARA COMMAND IS                      */
/*    WIPPARA                                                        */
/*                                                                   */
/*  THE COMMAND DOES NOT HAVE ANY PARAMETERS.                        */
/*                                                                   */
/*********************************************************************/
ISREDIT MACRO (FILEID1) NOPROCESS

/*********************************************************************/
/* SAVE THE CURRENT EDIT STATE AND SET THE DEFAULT RETURN CODE TO 0. */
/*********************************************************************/
ISREDIT (STATUS) = USER_STATE
SET &RETCODE = 0

/*********************************************************************/
/* INITIALIZE LOCAL VARIABLES                                        */
/*********************************************************************/
SET &LINEPTR = 1                            /* CURRENT LINE NUMBER   */
SET &PARACNT = 0                            /* NUMBER OF PARAGRAPHS  */
SET &ENDFILE = 0                            /* END-OF-FILE INDICATOR */
SET &LASTPRFX = &STR()                      /* LAST WIP PREFIX       */

/*********************************************************************/
/* RESET ANY EXISTING SPECIAL LINES.                                 */
/*********************************************************************/
ISREDIT RESET SPECIAL

/*********************************************************************/
/* READ THE FIRST LINE IN THE WIP FILE TO PRIME THE DO...UNTIL LOOP. */
/*********************************************************************/
ISPEXEC CONTROL ERRORS RETURN
ISREDIT (WIPDATA) = LINE &LINEPTR
SET &EDITRC = &LASTCC
IF (&EDITRC = 12) THEN +
  SET &ENDFILE = 1
ELSE +
  IF (&EDITRC > 12) THEN +
    DO
      SET &ZEDSMSG = &STR(COMMAND PROCESSING ERROR)
      SET &ZEDLMSG = &STR(ISPF/PDF RETURNED A RETURN CODE &EDITRC)
      ISPEXEC SETMSG MSG(ISRZ001)
      SET &RETCODE = 12
      GOTO EXIT
    END

/*********************************************************************/
/* LOOP OVER THE WIP FILE SEARCHING FOR BLOCKS OF COMMON OPERATIONS. */
/* FOR EACH NEW BLOCK, DETERMINE THE TYPE OF BLOCK AND BUILD AND     */
/* INSERT A MSG LINE INTO THE WIP FILE THAT IDENTIFIES THE TYPE OF   */
/* PARAGRAPH FOUND.                                                  */
/*********************************************************************/
DO WHILE (&ENDFILE = 0)
  SET &WIPPRFX = &STR(&SUBSTR(1:8,&SYSNSUB(1,&WIPDATA)))
  /*******************************************************************/
  /* IF THIS IS NOT A COMMENT RECORD THEN PROCESS THE RECORD.        */
  /*******************************************************************/
  IF (&STR(&SUBSTR(1:1,&WIPPRFX)) ^= &STR(*)) THEN +
    DO
     /****************************************************************/
     /* IF THIS PREFIX DIFFERS FROM THE PREVIOUS PREFIX THEN IT IS A */
     /* NEW PARAGRAPH.                                               */
     /****************************************************************/
      IF (&STR(&WIPPRFX) ^= &STR(&LASTPRFX)) THEN +
        DO
         /***********************************************************/
         /* IF THE FIRST CHARACTER OF THE WIP PREFIX IS A '%' THEN  */
         /* WRITE A =NOTE= LINE TO INDICATE THE TYPE OF PARAGRAPH   */
         /* THAT HAS BEEN LOCATED.                                  */
         /***********************************************************/
          IF (&STR(&SUBSTR(1:1,&WIPPRFX)) = &STR(%)) THEN +
            DO
              /*******************************************************/
              /* DETERMINE THE TYPE OF PARAGRAPH BY LOOKING AT THE   */
              /* WIP PREFIX.                                         */
              /*******************************************************/
              SELECT
               WHEN (&STR(&WIPPRFX) = &STR(% I-1 )) +
                SET &NOTE = &STR(AN INSERT BLOCK FROM DERIVATION 1)
               WHEN (&STR(&WIPPRFX) = &STR(% I-2 )) +
                SET &NOTE = &STR(AN INSERT BLOCK FROM DERIVATION 2)
               WHEN (&STR(&WIPPRFX) = &STR(% D-1 )) +
                SET &NOTE = &STR(A DELETE BLOCK BY DERIVATION 1)
               WHEN (&STR(&WIPPRFX) = &STR(% D-2 )) +
                SET &NOTE = &STR(A DELETE BLOCK BY DERIVATION 2)
               WHEN (&STR(&WIPPRFX) = &STR(% I-1,2)) +
                SET &NOTE = &STR(A COMMON INSERT BLOCK)
               WHEN (&STR(&WIPPRFX) = &STR(% D-1,2)) +
                SET &NOTE = &STR(A COMMON DELETE BLOCK)
               WHEN (&STR(&WIPPRFX) = &STR(%?I-1 )) +
                SET &NOTE = &STR(A CONFLICTING INSERT FROM DERIVATION 1)
               WHEN (&STR(&WIPPRFX) = &STR(%?I-2 )) +
                SET &NOTE = &STR(A CONFLICTING INSERT FROM DERIVATION 2)
               OTHERWISE +
                SET &NOTE = &STR(AN UNKNOWN PARAGRAPH TYPE)
              END
              /*******************************************************/
              /* BUILD A MSG LINE THAT IDENTIFIES THE TYPE OF PARA-  */
              /* GRAPH IDENTIFIED.                                   */
              /*******************************************************/
              SET &NOTETEXT = &STR(* THE FOLLOWING PARAGRAPH IS &NOTE)
              ISREDIT LINE_BEFORE &LINEPTR = NOTELINE &STR('&NOTETEXT')
              SET &PARACNT = &PARACNT + 1
            END
        END
    END
  SET &LASTPRFX = &STR(&WIPPRFX)
  SET &LINEPTR = &LINEPTR + 1

/*********************************************************************/
/* READ THE NEXT RECORD IN THE WIP FILE.                             */
/*********************************************************************/
  ISREDIT (WIPDATA) = LINE &LINEPTR
  SET &EDITRC = &LASTCC
  IF (&EDITRC = 12) THEN +
    SET &ENDFILE = 1
  ELSE +
    IF (&EDITRC > 12) THEN +
      DO
        SET &ZEDSMSG = &STR(COMMAND PROCESSING ERROR)
        SET &ZEDLMSG = &STR(ISPF/PDF RETURNED A RETURN CODE &EDITRC)
        ISPEXEC SETMSG MSG(ISRZ001)
        SET &RETCODE = 12
        GOTO EXIT
      END
END

/*********************************************************************/
/* IF NO PARAGRAPHS WERE FOUND THEN CHANGE THE ZERO COUNT IN PARACNT */
/* TO THE STRING 'NO'.  OTHERWISE, POSITION THE WIP FILE TO THE FIRST*/
/* PARAGRAPH BY LOCATING THE FIRST SPECIAL LINE IN THE FILE.         */
/*********************************************************************/
IF (&PARACNT = 0) THEN +
  SET &PARACNT = &STR(NO)
ELSE +
  DO
    ISREDIT UP MAX
    ISREDIT LOCATE FIRST SPECIAL
  END

/*********************************************************************/
/* WHEN DONE, WRITE A MESSAGE INDICATING THE NUMBER OF PARAGRAPHS    */
/* FOUND AND REPOSITION THE WIP MEMBER TO THE TOP OF THE FILE.       */
/*********************************************************************/
SET &ZEDSMSG = &STR(&PARACNT PARAGRAPHS FOUND)
SET &ZEDLMSG = &STR(&PARACNT PARAGRAPHS WERE IDENTIFIED IN THIS WIP +
FILE)
ISPEXEC SETMSG MSG(ISRZ001)

SET &RETCODE = 1

/*********************************************************************/
/* WHEN DONE, EXIT WITH THE APPROPRIATE RETURN CODE.                 */
/*********************************************************************/
EXIT:  +
EXIT CODE(&RETCODE)
