/* REXX                                                             */
/*------------------------------------------------------------------*/
/*                                                                  */
/*  COPYRIGHT (C) 2022 BROADCOM. ALL RIGHTS RESERVED.               */
/*                                                                  */
/*  NAME: ENDELETE                                                  */
/*                                                                  */
/*  PURPOSE: ENDELETE IS AN ISPF/PDF EDIT MACRO THAT CAN BE USED    */
/*  TO CREATE SKELETON SCL STATEMENTS FOR THE BATCH ENVIRONMENT     */
/*  ADMINISTRATION FACILITY DELETE ACTION.                          */
/*                                                                  */
/*  SYNTAX:   ENDELETE OBJECT_TYPE <OBJECT_NAME>                    */
/*   WHERE:   OBJECT_TYPE: THE TYPE OF ENVIRONMENT OBJECT FOR       */
/*                         WHICH SCL WILL BE GENERATED.  VALID      */
/*                         VALUES ARE:                              */
/*                             SYSTEM                               */
/*                             SUBSYSTEM                            */
/*                             TYPE                                 */
/*                             GROUP                                */
/*                             SYMBOL                               */
/*                             APPROVER                             */
/*                             RELATION                             */
/*                             DESTINATION                          */
/*                             MAPRULE                              */
/*                             USSMAPRULE                           */
/*                             CHGORDCORR (COC)                     */
/*                             CHGORDJUNC (COJ)                     */
/*                         THE OBJECT_TYPE IS REQUIRED              */
/*            OBJECT_NAME: AN OPTIONAL NAME OF THE ENVIRONMENT      */
/*                         OBJECT.  FOR EXAMPLE, ON EHT ENDELETE    */
/*                         SYSTEM COMMAND, THE OBJECT_NAME WOULD    */
/*                         BE THE NAME OF THE SYSTEM TO BE DELETED. */
/*                                                                  */
/*            THE COMMAND ENDELETE HELP OR ENDELETE ? CAN BE USED   */
/*            TO GENERATE A SUMMARY OF THE ENDELETE COMMAND SYNTAX, */
/*                                                                  */
/*  THE DELETE ACTION SCL IS CREATED BY POPULATING STEM VARIABLE SCL*/
/* AND CALLING ROUTINE WRITESCL.  THE WRITESCL ROUTINE WILL USE THE */
/* APPROPRIATE ISPF/PDF EDIT MACRO COMMANDS TO INSERT THE SCL STATE-*/
/* MENTS INTO THE CURRENT POSITION IN THE DATA FILE.  THERE IS ONE  */
/* ROUTINE FOR EACH ENVIRONMENT OBJECT.  EACH ROUTINE BUILDS THE    */
/* SCL. VARIABLE AND SUBSEQUENTLY CALLS WRITESCL.                   */
/*                                                                  */
/*  THE ENDELETE ROUTINE WILL ATTEMPT TO WRITE THE SCL AT THE CUR-  */
/* RENT CURSOR POSITION IN THE DATA FILE.  DUE TO LIMITATIONS OF    */
/* THE ISPF/PDF CURSOR COMMAND, THE SCL MAY NOT BE POSITIONED       */
/* EXACTLY WHERE EXPECTED.  IF THE CURSOR IS LOCATED ON THE         */
/* COMMAND LINE OR ON ANY NON-INPUT LINE, THE SCL WILL BE WRITTEN   */
/* AFTER THE FIRST DATA LINE THAT IS DISPLAYED.  OTHERWISE, THE     */
/* SCL WILL BE WRITTEN ON THE DATA LINE AFTER THE LINE WHERE THE    */
/* CURSOR IS POSITIONED.                                            */
/*                                                                  */
/*  THE DELETE SCL THAT IS CREATED WILL INCLUDE ALL THE DELETE      */
/* ACTION CLAUSES.  IN MOST CASES, THE ACTION CLAUSES WILL SPECIFY  */
/* THE DEFAULT VALUE.  IF THE CLAUSE REQUIRES USER PROVIDED DATA,   */
/* THE CLAUSE WILL INCLUDE EITHER A '?' OR A '????????' STRING AT   */
/* THE POSITION OF THE USER DATA.                                   */
/*                                                                  */
/*------------------------------------------------------------------*/
ADDRESS ISPEXEC 'ISREDIT MACRO (ENVOBJ, ENVOBJNM, ENVFILLR) NOPROCESS'

RETURNCODE = 0

/*------------------------------------------------------------------*/
/* SAVE THE CURRENT EDIT SESSION STATE INFORMATION.                 */
/*------------------------------------------------------------------*/
ADDRESS ISPEXEC 'ISREDIT (USERST) = USER_STATE'

/*------------------------------------------------------------------*/
/* CONVERT THE ENVIRONMENT OBJECT TYPE AND OBJECT NAMES TO UPPER    */
/* CASE.                                                            */
/*------------------------------------------------------------------*/
UPPER ENVOBJ
UPPER ENVOBJNM

/*------------------------------------------------------------------*/
/* USE THE ISREDIT CURSOR COMMAND TO DETERMINE THE CURRENT CURSOR   */
/* POSITION.                                                        */
/*------------------------------------------------------------------*/
ADDRESS ISPEXEC 'ISREDIT (CURLINE, CURCOL) = CURSOR'

/*------------------------------------------------------------------*/
/* USE THE FOLLOWING SELECT STATEMENT TO BOTH VALIDATE THAT THE ENV-*/
/* IRONMENT OBJECT TYPE IS VALID AND TO BRANCH TO THE APPROPRIATE   */
/* ROUTINE TO PROCESS THE OBJECT.                                   */
/*------------------------------------------------------------------*/
SELECT
  WHEN (ENVOBJ = "") THEN
   DO
     ZEDSMSG = 'OBJECT TYPE REQUIRED'
     ZEDLMSG = 'ENIP900E ENDELETE REQUIRES AN OBJECT TYPE.',
               ' ENTER ENDELETE HELP FOR HELP'
     ADDRESS ISPEXEC 'SETMSG MSG(ISRZ001)'
     RETURNCODE = 12
     SIGNAL ENDELETE_EXIT
   END

  WHEN ((ENVOBJ = 'SYSTEM')  | ,
        (ENVOBJ = 'SYS')) THEN
   DO
      RETURNCODE = DELETESYSTEM(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'SUBSYSTEM') | ,
        (ENVOBJ = 'SUB')) THEN
   DO
      RETURNCODE = DELETESUBSYSTEM(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'TYPE') | ,
        (ENVOBJ = 'TYP')) THEN
   DO
      RETURNCODE = DELETETYPE(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'GROUP') | ,
        (ENVOBJ = 'GRO')) THEN
   DO
      RETURNCODE = DELETEPROCESSORGROUP(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'SYMBOL') | ,
        (ENVOBJ = 'SYM')) THEN
   DO
      RETURNCODE = DELETEPROCESSORSYMBOL(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'APPROVER') | ,
        (ENVOBJ = 'APP')) THEN
   DO
      RETURNCODE = DELETEAPPROVERGROUP(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'RELATION') | ,
        (ENVOBJ = 'REL')) THEN
   DO
      RETURNCODE = DELETEAPPROVERRELATION(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'DESTINATION') | ,
        (ENVOBJ = 'DES')) THEN
   DO
      RETURNCODE = DELETEDESTINATION(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'MAPRULE') | ,
        (ENVOBJ = 'MAP')) THEN
   DO
      RETURNCODE = DELETEMAPPINGRULE(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'USSMAPRULE') | ,
        (ENVOBJ = 'USSMAP')) THEN
   DO
      RETURNCODE = DELETEUSSMAPRULE(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'CHGORDCORR') | ,
        (ENVOBJ = 'COC')) THEN
   DO
      RETURNCODE = DELETECHGORDCORR(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'CHGORDJUNC') | ,
        (ENVOBJ = 'COJ')) THEN
   DO
      RETURNCODE = DELETECHGORDJUNC(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'HELP') | ,
        (ENVOBJ = '?')) THEN
   DO
      CALL PRINTHELP CURLINE
   END

  OTHERWISE
     ZEDSMSG = 'UNDEFINED OBJECT TYPE'
     ZEDLMSG = 'ENIP901E THE OBJECT TYPE '''||ENVOBJ||''' IS NOT',
               'DEFINED'
     ADDRESS ISPEXEC 'SETMSG MSG(ISRZ001)'
     RETURNCODE = 12
     SIGNAL ENDELETE_EXIT

END

/*------------------------------------------------------------------*/
/* MACRO EXIT POINT.  THE VARIABLE RETURNCODE CONTAINS THE MACRO    */
/* RETURN CODE.                                                     */
/*------------------------------------------------------------------*/
ENDELETE_EXIT: NOP
  ADDRESS ISPEXEC 'ISREDIT USER_STATE = (USERST)'
  EXIT RETURNCODE

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DELETESYSTEM                                               */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DELETE       */
/*  SYSTEM ACTION.                                                  */
/*                                                                  */
/*------------------------------------------------------------------*/
DELETESYSTEM:
  ARG LINENUMBER OBJECTNAME  .

  LOCALRC = CHECKOBJECTLENGTH(8 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
       IF (OBJECTNAME = '') THEN
          OBJECTNAME = '????????'

       SCL.1  = ' DELETE SYSTEM '''||OBJECTNAME||''''
       SCL.2  = '   FROM ENVIRONMENT ''????????''           '
       SCL.3  = ' .                                         '
       SCL.0 = 3

       CALL WRITESCL LINENUMBER
    END

  RETURN LOCALRC

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DELETESUBSYSTEM                                            */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DELETE       */
/*  SUBSYSTEM ACTION.                                               */
/*                                                                  */
/*------------------------------------------------------------------*/
DELETESUBSYSTEM:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(8 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
       IF (OBJECTNAME = '') THEN
          OBJECTNAME = '????????'

       SCL.1  = ' DELETE SUBSYSTEM '''||OBJECTNAME||''''
       SCL.2  = '   FROM ENVIRONMENT ''????????''        '
       SCL.3  = '        SYSTEM ''????????''             '
       SCL.4  = ' .                                      '
       SCL.0 = 4

       CALL WRITESCL LINENUMBER
    END

  RETURN LOCALRC

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DELETETYPE                                                 */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DELETE TYPE  */
/*  ACTION.                                                         */
/*                                                                  */
/*------------------------------------------------------------------*/
DELETETYPE:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(8 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
      IF (OBJECTNAME = '') THEN
         OBJECTNAME = '????????'

      SCL.1  = ' DELETE TYPE '''||OBJECTNAME||''''
      SCL.2  = '   FROM ENVIRONMENT ''????????''        '
      SCL.3  = '        SYSTEM ''????????''             '
      SCL.4  = '        STAGE NUMBER ?                  '
      SCL.5  = ' .                                      '
      SCL.0 = 5

      CALL WRITESCL LINENUMBER
  END

  RETURN LOCALRC

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DELETEPROCESSORGROUP                                       */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DELETE       */
/*  PROCESSOR GROUP ACTION.                                         */
/*                                                                  */
/*------------------------------------------------------------------*/
DELETEPROCESSORGROUP:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(8 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
      IF (OBJECTNAME = '') THEN
         OBJECTNAME = '????????'

      SCL.1  = ' DELETE PROCESSOR GROUP '''||OBJECTNAME||''''
      SCL.2  = '   FROM ENVIRONMENT ''????????''         '
      SCL.3  = '      SYSTEM ''????????''                '
      SCL.4  = '      TYPE ''????????''                  '
      SCL.5  = '      STAGE NUMBER ?                     '
      SCL.6  = ' .                                       '
      SCL.0 = 6

      CALL WRITESCL LINENUMBER
  END

  RETURN LOCALRC

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DELETEAPPROVERGROUP                                        */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DELETE       */
/*  APPROVER GROUP ACTION.                                          */
/*                                                                  */
/*------------------------------------------------------------------*/
DELETEAPPROVERGROUP:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(8 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
      IF (OBJECTNAME = '') THEN
         OBJECTNAME = '????????'

      SCL.1  = ' DELETE APPROVER GROUP '''||OBJECTNAME||''''
      SCL.2  = '   FROM ENVIRONMENT ''????????''          '
      SCL.3  = '   APPROVER = (????????)                  '
      SCL.4  = ' .                                        '
      SCL.0 = 4

      CALL WRITESCL LINENUMBER
  END

  RETURN LOCALRC

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DELETEAPPROVERRELATION                                     */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DELETE       */
/*  APPROVER RELATION ACTION.                                       */
/*                                                                  */
/*------------------------------------------------------------------*/
DELETEAPPROVERRELATION:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKNULLOBJECT(ENVOBJNM)

  SCL.1  = ' DELETE APPROVER RELATION               '
  SCL.2  = '   FOR APPROVER GROUP ''????????''      '
  SCL.3  = '   FROM ENVIRONMENT ''????????''        '
  SCL.4  = '        SYSTEM ''????????''             '
  SCL.5  = '        SUBSYSTEM ''????????''          '
  SCL.6  = '        TYPE ''????????''               '
  SCL.7  = '        STAGE NUMBER ?                  '
  SCL.8  = '   TYPE IS STANDARD                     '
  SCL.9  = ' .                                      '
  SCL.0  = 9

  CALL WRITESCL LINENUMBER

  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DELETEPROCESSORSYMBOL                                      */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DELETE       */
/*  PROCESSOR SYMBOL ACTION                                         */
/*                                                                  */
/*------------------------------------------------------------------*/
DELETEPROCESSORSYMBOL:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKNULLOBJECT(ENVOBJNM)

  SCL.1  = ' DELETE PROCESSOR SYMBOL                '
  SCL.2  = '   FROM ENVIRONMENT ''????????''        '
  SCL.3  = '        SYSTEM ''????????''             '
  SCL.4  = '        TYPE ''????????''               '
  SCL.5  = '        STAGE NUMBER ?                  '
  SCL.6  = '        PROCESSOR GROUP ????????        '
  SCL.7  = '        PROCESSOR TYPE EQ ????????      '
  SCL.8  = '   SYMBOL = (????????,?)                '
  SCL.9  = ' .                                      '
  SCL.0  = 9

  CALL WRITESCL LINENUMBER

  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DELETEDESTINATION                                          */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DELETE       */
/*  SHIPMENT DESTINATION ACTION                                     */
/*                                                                  */
/*------------------------------------------------------------------*/
DELETEDESTINATION:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(7 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
      IF (OBJECTNAME = '') THEN
         OBJECTNAME = '???????'

      SCL.1  = ' DELETE SHIPMENT DESTINATION '''||OBJECTNAME||''''
      SCL.2  = ' .                                      '
      SCL.0 = 2

      CALL WRITESCL LINENUMBER
  END
  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DELETEMAPPINGRULE                                          */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DELETE       */
/*  SHIPMENT MAPPING RULE ACTION.                                   */
/*                                                                  */
/*------------------------------------------------------------------*/
DELETEMAPPINGRULE:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKNULLOBJECT(ENVOBJNM)

  SCL.1  = ' DELETE SHIPMENT MAPPING RULE           '
  SCL.2  = '   FROM DESTINATION ''???????''         '
  SCL.3  = '   HOST DATASET ''????????''            '
  SCL.4  = ' .                                      '
  SCL.0  = 4

  CALL WRITESCL LINENUMBER

  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DELETEUSSMAPRULE                                           */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DELETE       */
/*  SHIPMENT USS MAPPING RULE ACTION.                               */
/*                                                                  */
/*------------------------------------------------------------------*/
DELETEUSSMAPRULE:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKNULLOBJECT(ENVOBJNM)

  SCL.1  = ' DELETE SHIPMENT USS MAPPING RULE           '
  SCL.2  = '   FROM DESTINATION ''???????''         '
  SCL.3  = '   USS HOST PATH NAME ''???????????????????????????????????????'', '
  SCL.4  = '        ''???????????????????????????????????????''                '
  SCL.5  = ' .                                      '
  SCL.0  = 5

  CALL WRITESCL LINENUMBER

  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DELETECHGORDCORR                                           */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DELETE       */
/*  CHANGE ORDER CORRELATION ACTION.                                */
/*                                                                  */
/*------------------------------------------------------------------*/
DELETECHGORDCORR:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(32 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
      IF (OBJECTNAME = '') THEN
         OBJECTNAME = '?????????????????????????????????'

      SCL.1  = ' DELETE CHANGE ORDER CORRELATION '''||OBJECTNAME||''''
      SCL.2  = ' .                                      '
      SCL.0 = 2

      CALL WRITESCL LINENUMBER
  END
  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DELETECHGORDJUNC                                           */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DELETE       */
/*  CHANGE ORDER JUNCTION ACTION.                                   */
/*                                                                  */
/*------------------------------------------------------------------*/
DELETECHGORDJUNC:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKNULLOBJECT(ENVOBJNM)

  SCL.1  = ' DELETE CHANGE ORDER JUNCTION           '
  SCL.2  = '   FROM ENVIRONMENT ''????????''        '
  SCL.3  = '        SYSTEM ''????????''             '
  SCL.4  = '        SUBSYSTEM ''????????''          '
  SCL.5  = '        TYPE ''????????''               '
  SCL.6  = '        STAGE NUMBER ?                  '
  SCL.7  = '***     STAGE ID ?                      '
  SCL.8  = ' .                                      '
  SCL.0  = 8

      CALL WRITESCL LINENUMBER

  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: PRINTHELP                                                  */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL PRINT THE HELP INFORMATION ASSOCIATED */
/*  WITH THE ENDELETE COMMAND.  THE HELP INFORMATION IS DISPLAYED   */
/*  AS ==MSG> LINES IN THE CURRENT FILE.                            */
/*                                                                  */
/*  NOTE: THE HELP INFORMATION IS PLACED IN STEM VARIABLE HELP.     */
/*  BECAUSE OF IDIOSYNCRACIES IN HOW THE LINE_AFTER COMMAND WORKS   */
/*  WITH ==MSG> LINES, THE TEXT IS ACTUALLY OUTPUT IN REVERSE       */
/*  ORDER.                                                          */
/*                                                                  */
/*------------------------------------------------------------------*/
PRINTHELP: PROCEDURE
  ARG LINENUMBER

  ADDRESS ISPEXEC "ISREDIT CAPS OFF"

  HELP.1 =  ,
"'*----------------------------------------------------------------*'"
  HELP.2 = ,
"'*  ENDELETE COMMAND EXTENDED HELP                                *'"
  HELP.3 = ,
"'*                                                                *'"
  HELP.4 = ,
"'*  THE ENDELETE COMMAND IS USED TO GENERATE MODEL SCL STATEMENTS *'"
  HELP.5 = ,
"'* FOR THE BATCH ENVIRONMENT ADMINISTRATION FACILITY              *'"
  HELP.6 = ,
"'* DELETE ACTION.                                                 *'"
  HELP.7 = ,
"'*                                                                *'"
  HELP.8 = ,
"'*  COMMAND SYNTAX:                                               *'"
  HELP.9 = ,
"'*                                                                *'"
  HELP.10 = ,
"'*    ENDELETE OBJECT_TYPE OBJECT_NAME                            *'"
  HELP.11 = ,
"'*                                                                *'"
  HELP.12 = ,
"'*    WHERE: OBJECT_TYPE IDENTIFIES TYPE OF ENVIRONMENT OBJECT    *'"
  HELP.13 = ,
"'*            FOR WHICH SCL WILL BE GENERATED.  THE FOLLOWING     *'"
  HELP.14 = ,
"'*            VALUES ARE VALID.  NOTE: THE OBJECT_TYPE VALUE CAN  *'"
  HELP.15 = ,
"'*            BE ABBREVIATED TO THE CAPITALIZED LETTERS.          *'"
  HELP.16 = ,
"'*              SYStem - SYSTEM DEFINITION                        *'"
  HELP.17 = ,
"'*              SUBsystem - SUBSYSTEM DEFINITION                  *'"
  HELP.18 = ,
"'*              TYPe - ELEMENT TYPE DEFINITION                    *'"
  HELP.19 = ,
"'*              GROup - PROCESSOR GROUP DEFINITION                *'"
  HELP.20 = ,
"'*              SYMbol - PROCESSOR GROUP SYMBOL DEFINITION        *'"
  HELP.21 = ,
"'*              APProver - APPROVER GROUP DEFINITION              *'"
  HELP.22 = ,
"'*              RELation - APPROVER GROUP RELATIONSHIP DEFINITION *'"
  HELP.23 = ,
"'*              DEStination - PACKAGE SHIPMENT DESTINATION        *'"
  HELP.24 = ,
"'*              MAPrule - PACKAGE SHIPMENT MAPPING RULE DEFINITION*'"
  HELP.25 = ,
"'*              USSMAPrule - PACKAGE SHIPMENT USS MAPPING RULE    *'"
  HELP.26 = ,
"'*                           DEFINITION                           *'"
  HELP.27 = ,
"'*                                                                *'"
  HELP.28 = ,
"'*           OBJECT_NAME IS THE OPTIONAL NAME OF THE ENVIRONMENT  *'"
  HELP.29 = ,
"'*             OBJECT.  IF THE OBJECT_NAME IS NOT PROVIDED, THE   *'"
  HELP.30 = ,
"'*             DELETE SCL WILL USE THE VALUE ???????? AS THE      *'"
  HELP.31 = ,
"'*             ENVIRONMENT OBJECT.  THE OBJECT_NAME IS IGNORED FOR*'"
  HELP.32 = ,
"'*             THE RELATION, SYMBOL, MAPRULE AND USSMAPRULE       *'"
  HELP.33 = ,
"'*             ENVIRONMENT OBJECTS.  THE OBJECT_NAME CAN HAVE A   *'"
  HELP.34 = ,
"'*             MAXIMUM LENGTH OF 8 CHARACTERS FOR THE SYSTEM,     *'"
  HELP.35 = ,
"'*             SUBSYSTEM, TYPE AND PROCESSOR OBJECTS.  THE        *'"
  HELP.36 = ,
"'*             MAXIMUM LENGTH OF THE APPROVER OBJECT_NAME IS 16.  *'"
  HELP.37 = ,
"'*             THE MAXIMUM LENGTH OF THE DESTINATION OBJECT_NAME  *'"
  HELP.38 = ,
"'*             IS 7.                                              *'"
  HELP.39 = ,
"'*                                                                *'"
  HELP.40 = ,
"'*  NOTE: YOU CAN REMOVE THESE LINES WITH THE D LINE COMMAND OR   *'"
  HELP.41 = ,
"'* BY ENTERING THE RESET SPECIAL COMMAND LINE COMMAND.            *'"
  HELP.42 = ,
"'*----------------------------------------------------------------*'"

  HELP.0 = 42                      /* SET THE NUMBER OF HELP LINES */

  DO LOOPIX = HELP.0 TO 1 BY -1
    ADDRESS ISPEXEC 'ISREDIT LINE_AFTER' LINENUMBER' = ' ,
                   ' MSGLINE  'HELP.LOOPIX
  END

  ADDRESS ISPEXEC "ISREDIT CAPS ON "

  RETURN

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: WRITESCL                                                   */
/*                                                                  */
/* PURPOSE: THE WRITESCL ROUTINE WILL WRITE THE SCL FOR THE CURRENT */
/*  OBJECT TO THE DATA SET.                                         */
/*                                                                  */
/* INPUT: THE WRITESCL PROCEDURE EXPECTS THE FOLLOWING PARAMETER:   */
/*     LINENUMBER: THE POSITION IN THE CURRENT FILE WHERE THE       */
/*               SCL STATEMENTS ARE TO BE WRITTEN                   */
/*                                                                  */
/*------------------------------------------------------------------*/
WRITESCL: PROCEDURE EXPOSE SCL.
  ARG LINENUMBER .

  CURRENTLINE = LINENUMBER
  LOOPLIMIT = SCL.0

  DO LOOPIX = 1 TO LOOPLIMIT
    ADDRESS ISPEXEC 'ISREDIT LINE_AFTER' CURRENTLINE' = "'SCL.LOOPIX'"'
    CURRENTLINE = CURRENTLINE + 1
  END

  ADDRESS ISPEXEC "ISREDIT CAPS OFF"
  ADDRESS ISPEXEC "ISREDIT LINE_AFTER "LINENUMBER" = MSGLINE " ,
    "'ENDELETE: LINES WITH ???????? OR ? MUST BE CUSTOMIZED'"
  ADDRESS ISPEXEC "ISREDIT CAPS ON "

  RETURN

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: CHECKOBJECTLENGTH                                          */
/*                                                                  */
/* PURPOSE: THE CHECKOBJECTLENGTH FUNCTION WILL VERIFY THAT THE     */
/*  OBJECT NAME, IF SPECIFIED BY THE USER, IS NO LONGER THAN THE    */
/*  MAXIMUM ALLOWABLE LENGTH.  THE CALLER PROVIDES BOTH THE         */
/*  ENVIRONMENT OBJECT NAME AND THE MAXIMUM ALLOWABLE LENGTH. IF    */
/*  THE OBJECT NAME IS TOO LONG, THE FUNCTION WILL GENERATE AN      */
/*  ERROR MESSAGE.                                                  */
/*                                                                  */
/* INPUT: THE CHECKOBJECTLENGTH PROCEDURE EXPECTS THE FOLLOWING     */
/*  PARAMETERS:                                                     */
/*     MAXLENGTH: THE MAXIMUM LENGTH ALLOWED FOR THE ENVIRONMENT    */
/*                OBJECT                                            */
/*     OBJECTNAME: THE ENVIRONMENT OBJECT NAME VALUE THAT THE       */
/*                USER SPECIFIED.                                   */
/*                                                                  */
/* RETURN CODES:                                                    */
/*     0: THE ENVORINMENT OBJECT NAME LENGTH IS VALID               */
/*     12: THE ENVIRONMENT OBJECT NAME LENGTH IS TOO LONG           */
/*                                                                  */
/*------------------------------------------------------------------*/
CHECKOBJECTLENGTH:
  ARG MAXLENGTH OBJECTNAME .

  LOCALRC = 0

  IF (OBJECTNAME ^= '') THEN
    DO
       IF (LENGTH(OBJECTNAME) > MAXLENGTH) THEN
         DO
            ZEDSMSG = 'INVALID OBJECT NAME'
            ZEDLMSG = 'ENIP902E THE OBJECT NAME SPECIFIED IS INVALID'
            ADDRESS ISPEXEC 'SETMSG MSG(ISRZ001)'
            LOCALRC = 12
         END
    END

  RETURN LOCALRC

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: CHECKNULLOBJECT                                            */
/*                                                                  */
/* PURPOSE: THE CHECKOBJECTLENGTH FUNCTION WILL WRITE A WARNING     */
/*  MESSAGE IF THE OBJECT NAME THAT THE USER SPECIFIED IS NON-NULL. */
/*  THIS FUNCTION IS CALLED FOR THE ENVIRONMENT OBJECTS THAT DO NOT */
/*  HAVE SPECIFIED OBJECT NAMES (EG. TYPE SEQUENCE).                */
/*                                                                  */
/* INPUT: THE CHECKNULLOBJECT FUNCTION EXPECTS THE FOLLOWING        */
/*  PARAMETER:                                                      */
/*     OBJECTNAME: THE ENVIRONMENT OBJECT NAME VALUE THAT THE       */
/*                USER SPECIFIED.                                   */
/*                                                                  */
/* RETURN CODES:                                                    */
/*     0: THE ENVIRONMENT OBJECT NAME IS NULL                       */
/*     12: THE ENVIRONMENT OBJECT NAME IS NOT NULL                  */
/*                                                                  */
/*------------------------------------------------------------------*/
CHECKNULLOBJECT:
  ARG OBJECTNAME

  LOCALRC = 0

  IF (OBJECTNAME ^= '') THEN
    DO
      IF (LENGTH(OBJECTNAME) > MAXLENGTH) THEN
        DO
           ZEDSMSG = 'OBJECT NAME IGNORED'
           ZEDLMSG = 'ENIP903W THE OBJECT NAME PARAMETER IS NOT USED',
                     'WITH THIS OBJECT TYPE'
           ADDRESS ISPEXEC 'SETMSG MSG(ISRZ001)'
           LOCALRC = 12
        END
    END

  RETURN LOCALRC

