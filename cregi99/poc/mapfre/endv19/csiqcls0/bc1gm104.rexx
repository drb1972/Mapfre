/*********************************************************************/
/*                                                                   */
/*  COPYRIGHT (C) 2022 BROADCOM. ALL RIGHTS RESERVED.               */
/*                                                                   */
/* NAME: WIPCOUNT                                                    */
/*                                                                   */
/* FUNCTION: THIS ISPF/PDF EDIT MACRO IS USED TO SUPPORT THE WIPCOUNT */
/* COMMAND.  THE WIPCOUNT COMMAND WILL ALLOW THE USER TO DISPLAY ONLY */
/* THOSE LINES THAT ARE BEING INCLUDED FROM THE FILES SPECIFIED ON   */
/* THE WIPCOUNT COMMAND. ALL OTHER LINES ARE EXCLUDED FROM THE       */
/* DISPLAY.                                                          */
/*                                                                   */
/* SYNTAX: THE SYNTAX OF THE WIPCOUNT COMMAND IS                     */
/*    WIPCOUNT FILE_ID FILE_ID ...                                   */
/*                                                                   */
/*  AT LEAST ONE FILE_ID MUST BE SPECIFIED ON THE COMMAND. VALID     */
/* FILE_ID VALUES ARE:                                               */
/*    R - IDENTIFIES THE ROOT FILE                                   */
/*    1 - IDENTIFIES THE DERIVATIVE 1 FILE                           */
/*    2 - IDENTIFIES THE DERIVATIVE 2 FILE                           */
/*  IF A FILE_ID IS INVALID OR A FILE_ID IS NOT SPECIFIED, AN ERROR  */
/* MESSAGE WILL BE DISPLAYED AND THE WIPCOUNT COMMAND WILL TERMINATE. */
/* AT MOST, THREE FILE_ID VALUES CAN BE SPECIFIED.  ANY EXTRA PARAM- */
/* ETERS WILL BE IGNORED.                                            */
/*                                                                   */
/*********************************************************************/

ISREDIT MACRO (FILEID1) NOPROCESS
/*********************************************************************/
/* SAVE THE CURRENT EDIT STATE AND SET THE DEFAULT RETURN CODE TO 0. */
/*********************************************************************/
ISREDIT (STATUS) = USER_STATE
SET &RETCODE = 0

/*********************************************************************/
/* IF THE USER SPECIFIED ANY PARAMETERS ON THE WIPCOUNT MACRO THEN   */
/* WRITE A MESSAGE INDICATING THAT THE PARAMETERS WERE IGNORED.      */
/*********************************************************************/
IF (&FILEID1 ^= &STR()) THEN  +
  DO
    SET &ZEDSMSG = &STR(PARAMETER IGNORED)
    SET &ZEDLMSG = &STR(THE WIPCOUNT MACRO DOES NOT USE ANY PARAMETERS)
    ISPEXEC SETMSG MSG(ISRZ001)
  END

/*********************************************************************/
/*                                                                   */
/* USE THE ISPF/PDF SEEK COMMAND TO COUNT ALL THE RECORDS IN THE     */
/* ROOT, DV1, DV2 AND COMMON BETWEEN DV1 AND DV2 IN THE WIP FILE.    */
/* WRITE ==MSG> LINES TO INDICATE THE NUMBER OF RECORDS FOUND.       */
/*                                                                   */
/*********************************************************************/
ISREDIT RESET SPECIAL
ISREDIT UP MAX

SET &ROOTCNT = 0
SET &DV1CNT = 0
SET &DV2CNT = 0
SET &DV12CNT = 0
SET &TOT2CNT = 0
ISREDIT LINE_BEFORE 1 =            +
   MSGLINE &STR(' WIPCOUNT RESULTS:')

/*********************************************************************/
/* COUNT THE NUMBER OF ROOT/COMMON RECORDS IN THE WIP FILE           */
/*********************************************************************/
ISREDIT SEEK '       ' ALL CHARS 1
ISREDIT (COUNT) = SEEK_COUNTS
SET &ROOTCNT = &ROOTCNT + &COUNT
SET &TOTCNT = &TOTCNT + &ROOTCNT
ISREDIT LINE_BEFORE 1 =            +
   MSGLINE &STR('   NUMBER OF ROOT/COMMON LINES:            &ROOTCNT')

/*********************************************************************/
/* COUNT THE NUMBER OF DERTIVATION 1 ONLY RECORDS IN THE WIP FILE    */
/*********************************************************************/
ISREDIT SEEK '% I-1 ' ALL CHARS 1
ISREDIT (COUNT) = SEEK_COUNTS
SET &DV1CNT = &DV1CNT + &COUNT
ISREDIT SEEK '%?I-1 ' ALL CHARS 1
ISREDIT (COUNT) = SEEK_COUNTS
SET &DV1CNT = &DV1CNT + &COUNT
SET &TOTCNT = &TOTCNT + &DV1CNT
ISREDIT LINE_BEFORE 1 =            +
   MSGLINE &STR('   LINES INSERTED BY DERIVATION 1:         &DV1CNT')

/*********************************************************************/
/* COUNT THE NUMBER OF DERTIVATION 2 ONLY RECORDS IN THE WIP FILE    */
/*********************************************************************/
ISREDIT SEEK '% I-2' ALL CHARS 1
ISREDIT (COUNT) = SEEK_COUNTS
SET &DV2CNT = &DV2CNT + &COUNT
ISREDIT SEEK '%?I-2' ALL CHARS 1
ISREDIT (COUNT) = SEEK_COUNTS
SET &DV2CNT = &DV2CNT + &COUNT
SET &TOTCNT = &TOTCNT + &DV2CNT
ISREDIT LINE_BEFORE 1 =            +
   MSGLINE &STR('   LINES INSERTED BY DERIVATION 2:         &DV2CNT')

/*********************************************************************/
/* COUNT THE NUMBER OF DERTIVATION 1 AND DERIVATION 2 (COMMON) REC-  */
/* ORDS IN THE WIP FILE.                                             */
/*********************************************************************/
ISREDIT SEEK '% I-1,2' ALL CHARS 1
ISREDIT (COUNT) = SEEK_COUNTS
SET &DV12CNT = &DV12CNT + &COUNT
SET &TOTCNT = &TOTCNT + &DV12CNT
ISREDIT LINE_BEFORE 1 =            +
   MSGLINE &STR('   LINES INSERTED BY BOTH DERIVATION 1/2:  &DV12CNT')

ISREDIT LINE_BEFORE 1 =            +
   MSGLINE &STR('   TOTAL COMMON AND INSERTED LINES:        &TOTCNT')

SET &RETCODE = 1

/*********************************************************************/
/* SAVE THE CURRENT EDIT STATE AND SET THE DEFAULT RETURN CODE TO 0. */
/*********************************************************************/
EXIT:  +
ISREDIT USER_STATE = (STATUS)

IF (&RETCODE = 1) THEN +
  ISREDIT UP MAX

EXIT CODE(&RETCODE)
