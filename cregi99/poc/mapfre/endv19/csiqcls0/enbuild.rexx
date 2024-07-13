/* REXX                                                             */
/*------------------------------------------------------------------*/
/*                                                                  */
/*  COPYRIGHT (C) 2022 BROADCOM. ALL RIGHTS RESERVED.               */
/*                                                                  */
/*  NAME: ENBUILD                                                   */
/*                                                                  */
/*  PURPOSE: ENBUILD IS AN ISPF/PDF EDIT MACRO THAT CAN BE USED     */
/*  TO CREATE SKELETON SCL STATEMENTS FOR THE BATCH ENVIRONMENT     */
/*  ADMINISTRATION FACILITY BUILD ACTION.                           */
/*                                                                  */
/*  SYNTAX:   ENBUILD OBJECT_TYPE <OBJECT_NAME>                     */
/*   WHERE:   OBJECT_TYPE: THE TYPE OF ENVIRONMENT OBJECT FOR       */
/*                         WHICH SCL WILL BE GENERATED.  VALID      */
/*                         VALUES ARE:                              */
/*                             ENVIRONMENT                          */
/*                             SYSTEM                               */
/*                             SUBSYSTEM                            */
/*                             TYPE                                 */
/*                             SEQUENCE                             */
/*                             GROUP                                */
/*                             SYMBOL                               */
/*                             APPROVER                             */
/*                             RELATION                             */
/*                             DESTINATION                          */
/*                             CHGORDCORR (COC)                     */
/*                             CHGORDJUNC (COJ)                     */
/*                         THE OBJECT_TYPE IS REQUIRED              */
/*            OBJECT_NAME: AN OPTIONAL NAME OF THE ENVIRONMENT      */
/*                         OBJECT.  FOR EXAMPLE, ON EHT ENBUILD     */
/*                         SYSTEM COMMAND, THE OBJECT_NAME WOULD    */
/*                         BE THE NAME OF THE SYSTEM FOR WHICH THE  */
/*                         DEFINE ACTION SCL WOULD BE BUILT.        */
/*                                                                  */
/*            THE COMMAND ENBUILD HELP OR ENBUILD ? CAN BE USED     */
/*            TO GENERATE A SUMMARY OF THE ENBUILD COMMAND SYNTAX, */
/*                                                                  */
/*  THE BUILD ACTION SCL IS CREATED BY POPULATING STEM VARIABLE SCL */
/* AND CALLING ROUTINE WRITESCL.  THE WRITESCL ROUTINE WILL USE THE */
/* APPROPRIATE ISPF/PDF EDIT MACRO COMMANDS TO INSERT THE SCL STATE-*/
/* MENTS INTO THE CURRENT POSITION IN THE DATA FILE.  THERE IS ONE  */
/* ROUTINE FOR EACH ENVIRONMENT OBJECT.  EACH ROUTINE BUILDS THE    */
/* SCL. VARIABLE AND SUBSEQUENTLY CALLS WRITESCL.                   */
/*                                                                  */
/*  THE ENBUILD ROUTINE WILL ATTEMPT TO WRITE THE SCL AT THE CUR-   */
/* RENT CURSOR POSITION IN THE DATA FILE.  DUE TO LIMITATIONS OF    */
/* THE ISPF/PDF CURSOR COMMAND, THE SCL MAY NOT BE POSITIONED       */
/* EXACTLY WHERE EXPECTED.  IF THE CURSOR IS LOCATED ON THE         */
/* COMMAND LINE OR ON ANY NON-INPUT LINE, THE SCL WILL BE WRITTEN   */
/* AFTER THE FIRST DATA LINE THAT IS DISPLAYED.  OTHERWISE, THE     */
/* SCL WILL BE WRITTEN ON THE DATA LINE AFTER THE LINE WHERE THE    */
/* CURSOR IS POSITIONED.                                            */
/*                                                                  */
/*  THE BUILD SCL THAT IS CREATED WILL INCLUDE ALL THE BUILD        */
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
     ZEDLMSG = 'ENIP900E ENBUILD REQUIRES AN OBJECT TYPE.',
               ' ENTER ENBUILD HELP FOR HELP'
     ADDRESS ISPEXEC 'SETMSG MSG(ISRZ001)'
     RETURNCODE = 12
     SIGNAL ENBUILD_EXIT
   END

  WHEN ((ENVOBJ = 'ENVIRONMENT')  | ,
        (ENVOBJ = 'ENV')) THEN
   DO
      RETURNCODE = BUILDENVIRONMENT(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'SYSTEM')  | ,
        (ENVOBJ = 'SYS')) THEN
   DO
      RETURNCODE = BUILDSYSTEM(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'SUBSYSTEM') | ,
        (ENVOBJ = 'SUB')) THEN
   DO
      RETURNCODE = BUILDSUBSYSTEM(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'TYPE') | ,
        (ENVOBJ = 'TYP')) THEN
   DO
      RETURNCODE = BUILDTYPE(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'SEQUENCE') | ,
        (ENVOBJ = 'SEQ')) THEN
   DO
      RETURNCODE = BUILDTYPESEQUENCE(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'GROUP') | ,
        (ENVOBJ = 'GRO')) THEN
   DO
      RETURNCODE = BUILDPROCESSORGROUP(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'SYMBOL') | ,
        (ENVOBJ = 'SYM')) THEN
   DO
      RETURNCODE = BUILDPROCESSORSYMBOL(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'APPROVER') | ,
        (ENVOBJ = 'APP')) THEN
   DO
      RETURNCODE = BUILDAPPROVERGROUP(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'RELATION') | ,
        (ENVOBJ = 'REL')) THEN
   DO
      RETURNCODE = BUILDAPPROVERRELATION(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'DESTINATION') | ,
        (ENVOBJ = 'DES')) THEN
   DO
      RETURNCODE = BUILDDESTINATION(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'CHGORDCORR') | ,
        (ENVOBJ = 'COC')) THEN
   DO
      RETURNCODE = BUILDCHGORDCORR(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'CHGORDJUNC') | ,
        (ENVOBJ = 'COJ')) THEN
   DO
      RETURNCODE = BUILDCHGORDJUNC(CURLINE ENVOBJNM)
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
     SIGNAL ENBUILD_EXIT

END

/*------------------------------------------------------------------*/
/* MACRO EXIT POINT.  THE VARIABLE RETURNCODE CONTAINS THE MACRO    */
/* RETURN CODE.                                                     */
/*------------------------------------------------------------------*/
ENBUILD_EXIT: NOP
  ADDRESS ISPEXEC 'ISREDIT USER_STATE = (USERST)'
  EXIT RETURNCODE

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: BUILDENVIRONMENT                                           */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE BUILD SCL FOR*/
/*  ENVIRONMENT ACTION                                              */
/*                                                                  */
/*------------------------------------------------------------------*/
BUILDENVIRONMENT:
  ARG LINENUMBER OBJECTNAME  .

  LOCALRC = CHECKOBJECTLENGTH(8 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
      IF (OBJECTNAME = '') THEN
         OBJECTNAME = '????????'

      SCL.1  = ' BUILD SCL FOR ENVIRONMENT '''||OBJECTNAME||''''
      SCL.2  = '   TO DSNAME ''????????''                  '
      SCL.3  = ' .                                         '
      SCL.0 = 3

      CALL WRITESCL LINENUMBER
    END

  RETURN LOCALRC

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: BUILDSYSTEM                                                */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE BUILD SCL FOR*/
/*  SYSTEM ACTION.                                                  */
/*                                                                  */
/*------------------------------------------------------------------*/
BUILDSYSTEM:
  ARG LINENUMBER OBJECTNAME  .

  LOCALRC = CHECKOBJECTLENGTH(8 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
      IF (OBJECTNAME = '') THEN
         OBJECTNAME = '????????'

      SCL.1  = ' BUILD SCL FOR SYSTEM '''||OBJECTNAME||''''
      SCL.2  = '   FROM ENVIRONMENT ''????????''           '
      SCL.3  = '        INCLUDE SUBORDINATES               '
      SCL.4  = '   TO DSNAME ''????????''                  '
      SCL.5  = ' .                                         '
      SCL.0 = 5

      CALL WRITESCL LINENUMBER
    END

  RETURN LOCALRC

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: BUILDSUBSYSTEM                                             */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE BUILD SCL FOR*/
/*  SUBSYSTEM ACTION.                                               */
/*                                                                  */
/*------------------------------------------------------------------*/
BUILDSUBSYSTEM:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(8 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
       IF (OBJECTNAME = '') THEN
          OBJECTNAME = '????????'

      SCL.1  = ' BUILD SCL FOR SUBSYSTEM '''||OBJECTNAME||''''
      SCL.2  = '   FROM ENVIRONMENT ''????????''        '
      SCL.3  = '        SYSTEM ''????????''             '
      SCL.4  = '   TO DSNAME ''????????''                  '
      SCL.5  = ' .                                      '
      SCL.0 = 5

      CALL WRITESCL LINENUMBER
    END

  RETURN LOCALRC

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: BUILDTYPE                                                  */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE BUILD SCL FOR*/
/*  TYPE ACTION.                                                    */
/*                                                                  */
/*------------------------------------------------------------------*/
BUILDTYPE:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(8 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
      IF (OBJECTNAME = '') THEN
         OBJECTNAME = '????????'

      SCL.1  = ' BUILD SCL FOR TYPE '''||OBJECTNAME||''''
      SCL.2  = '   FROM ENVIRONMENT ''????????''        '
      SCL.3  = '        SYSTEM ''????????''             '
      SCL.4  = '        STAGE NUMBER ?                  '
      SCL.5  = '        INCLUDE SUBORDINATES            '
      SCL.6  = '   TO DSNAME ''????????''               '
      SCL.7  = ' .                                      '
      SCL.0 = 7

      CALL WRITESCL LINENUMBER
  END

  RETURN LOCALRC

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: BUILDTYPESEQUENCE                                          */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE BUILD SCL FOR*/
/*  TYPE SEQUENCE ACTION.                                           */
/*                                                                  */
/*------------------------------------------------------------------*/
BUILDTYPESEQUENCE:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKNULLOBJECT(ENVOBJNM)

  SCL.1  = ' BUILD SCL FOR TYPE SEQUENCE '
  SCL.2  = '   FROM ENVIRONMENT ''????????''        '
  SCL.3  = '        SYSTEM ''????????''             '
  SCL.4  = '        STAGE NUMBER ?                  '
  SCL.5  = '   TO DSNAME ''????????''                  '
  SCL.6  = ' .                                      '
  SCL.0 = 6

  CALL WRITESCL LINENUMBER

  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: BUILDPROCESSORGROUP                                        */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE BUILD SCL FOR*/
/*  PROCESSOR GROUP ACTION.                                         */
/*                                                                  */
/*------------------------------------------------------------------*/
BUILDPROCESSORGROUP:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(8 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
      IF (OBJECTNAME = '') THEN
         OBJECTNAME = '????????'

      SCL.1  = ' BUILD SCL FOR PROCESSOR GROUP '''||OBJECTNAME||''''
      SCL.2  = '   FROM ENVIRONMENT ''????????''          '
      SCL.3  = '      SYSTEM ''????????''               '
      SCL.4  = '      TYPE ''????????''                 '
      SCL.5  = '      STAGE NUMBER ?                    '
      SCL.6  = '   TO DSNAME ''????????''               '
      SCL.7  = ' .                                      '
      SCL.0 = 7

      CALL WRITESCL LINENUMBER
  END

  RETURN LOCALRC

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: BUILDAPPROVERGROUP                                         */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE BUILD SCL FOR*/
/*  APPROVER GROUP ACTION.                                          */
/*                                                                  */
/*------------------------------------------------------------------*/
BUILDAPPROVERGROUP:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(8 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
      IF (OBJECTNAME = '') THEN
         OBJECTNAME = '????????'

      SCL.1  = ' BUILD SCL FOR APPROVER GROUP '''||OBJECTNAME||''''
      SCL.2  = '   FROM ENVIRONMENT ''????????''          '
      SCL.3  = '   TO DSNAME ''????????''                 '
      SCL.4  = ' .                                        '
      SCL.0 = 4

      CALL WRITESCL LINENUMBER
  END

  RETURN LOCALRC

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: BUILDAPPROVERRELATION                                      */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE BUILD SCL FOR*/
/*  APPROVER RELATION ACTION.                                       */
/*                                                                  */
/*------------------------------------------------------------------*/
BUILDAPPROVERRELATION:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKNULLOBJECT(ENVOBJNM)

  SCL.1  = ' BUILD SCL FOR APPROVER RELATION        '
  SCL.2  = '   FROM ENVIRONMENT ''????????''        '
  SCL.3  = '        APPROVER GROUP ''????????''     '
  SCL.4  = '   TO DSNAME ''????????''               '
  SCL.5  = ' .                                      '
  SCL.0  = 5

  CALL WRITESCL LINENUMBER

  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: BUILDPROCESSORSYMBOL                                       */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE BUILD SCL FOR*/
/*  PROCESSOR SYMBOL ACTION                                         */
/*                                                                  */
/*------------------------------------------------------------------*/
BUILDPROCESSORSYMBOL:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKNULLOBJECT(ENVOBJNM)

  SCL.1  = ' BUILD SCL FOR PROCESSOR SYMBOL                '
  SCL.2  = '   FROM ENVIRONMENT ''????????''        '
  SCL.3  = '        SYSTEM ''????????''             '
  SCL.4  = '        TYPE ''????????''               '
  SCL.5  = '        STAGE NUMBER ?                  '
  SCL.6  = '        PROCESSOR GROUP ????????        '
  SCL.7  = '   TO DSNAME ''????????''                  '
  SCL.8  = ' .                                      '
  SCL.0  = 8

  CALL WRITESCL LINENUMBER

  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: BUILDDESTINATION                                           */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE BUILD SCL FOR*/
/*  SHIPMENT DESTINATION ACTION                                     */
/*                                                                  */
/*------------------------------------------------------------------*/
BUILDDESTINATION:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(7 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
      IF (OBJECTNAME = '') THEN
         OBJECTNAME = '???????'

      SCL.1  = ' BUILD SCL FOR SHIPMENT DESTINATION '''||OBJECTNAME||''''
      SCL.2  = '   TO DSNAME ''????????''                  '
      SCL.3  = '*     MEMBER ''????????''                  '
      SCL.4  = '*     REPLACE                              '
      SCL.5  = '*  TO DDNAME ''????????''                  '
      SCL.6  = ' .                                      '
      SCL.0 = 6

      CALL WRITESCL LINENUMBER
  END
  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: BUILDCHGORDCORR                                            */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE BUILD SCL FOR*/
/*  CHANGE ORDER CORRELATION ACTION                                 */
/*                                                                  */
/*------------------------------------------------------------------*/
BUILDCHGORDCORR:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(32 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
      IF (OBJECTNAME = '') THEN
         OBJECTNAME = '????????????????????????????????'

      SCL.1  = ' BUILD SCL FOR CHANGE ORDER CORRELATION '''||OBJECTNAME||''''
      SCL.2  = '   TO DSNAME ''????????''                  '
      SCL.3  = ' .                                      '
      SCL.0 = 3

      CALL WRITESCL LINENUMBER
  END
  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: BUILDCHGORDJUNC                                            */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE BUILD SCL FOR*/
/*  CHANGE ORDER JUNCTION ACTION                                    */
/*                                                                  */
/*------------------------------------------------------------------*/
BUILDCHGORDJUNC:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKNULLOBJECT(ENVOBJNM)

  SCL.1  = ' BUILD SCL FOR CHANGE ORDER JUNCTION    '
  SCL.2  = '   FROM ENVIRONMENT ''????????''        '
  SCL.3  = '        SYSTEM ''????????''             '
  SCL.4  = '        SUBSYSTEM ''????????''          '
  SCL.5  = '        TYPE ''????????''               '
  SCL.6  = '        STAGE NUMBER ?                  '
  SCL.7  = '   TO DSNAME ''????????''               '
  SCL.8  = ' .                                      '
  SCL.0  = 8

  CALL WRITESCL LINENUMBER

  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: PRINTHELP                                                  */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL PRINT THE HELP INFORMATION ASSOCIATED */
/*  WITH THE ENBUILD COMMAND.   THE HELP INFORMATION IS DISPLAYED   */
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
"'*  ENBUILD COMMAND EXTENDED HELP                                 *'"
  HELP.3 = ,
"'*                                                                *'"
  HELP.4 = ,
"'*  THE ENBUILD COMMAND IS USED TO GENERATE MODEL SCL STATEMENTS  *'"
  HELP.5 = ,
"'* FOR THE BATCH ENVIRONMENT ADMINISTRATION FACILITY              *'"
  HELP.6 = ,
"'* BUILD SCL FOR ACTION.                                          *'"
  HELP.7 = ,
"'*                                                                *'"
  HELP.8 = ,
"'*  COMMAND SYNTAX:                                               *'"
  HELP.9 = ,
"'*                                                                *'"
  HELP.10 = ,
"'*    ENBUILD OBJECT_TYPE OBJECT_NAME                             *'"
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
"'*              ENVironment - ENVIRONMENT AND SUBORDINATES        *'"
  HELP.17 = ,
"'*              SYStem - SYSTEM                                   *'"
  HELP.18 = ,
"'*              SUBsystem - SUBSYSTEM                             *'"
  HELP.19 = ,
"'*              TYPe - ELEMENT TYPE                               *'"
  HELP.20 = ,
"'*              SEQuence - TYPE SEQUENCE                          *'"
  HELP.21 = ,
"'*              GROup - PROCESSOR GROUP                           *'"
  HELP.22 = ,
"'*              SYMbol - PROCESSOR GROUP SYMBOL                   *'"
  HELP.23 = ,
"'*              APProver - APPROVER GROUP                         *'"
  HELP.24 = ,
"'*              RELation - APPROVER GROUP RELATIONSHIP            *'"
  HELP.25 = ,
"'*              DEStination - PACKAGE SHIPMENT DESTINATION        *'"
  HELP.26 = ,
"'*                                                                *'"
  HELP.27 = ,
"'*           OBJECT_NAME IS THE OPTIONAL NAME OF THE ENVIRONMENT  *'"
  HELP.28 = ,
"'*             OBJECT.  IF THE OBJECT_NAME IS NOT PROVIDED, THE   *'"
  HELP.29 = ,
"'*             BUILD SCL WILL USE THE VALUE ???????? AS THE       *'"
  HELP.30 = ,
"'*             ENVIRONMENT OBJECT.  THE OBJECT_NAME IS IGNORED FOR*'"
  HELP.31 = ,
"'*             THE RELATION, SYMBOL AND SEQUENCE ENVIRONMENT      *'"
  HELP.32 = ,
"'*             MENT OBJECTS.  THE OBJECT_NAME CAN HAVE A MAXIMUM  *'"
  HELP.33 = ,
"'*             LENGTH OF 8 CHARACTERS FOR THE ENVIRONMENT, SYSTEM,*'"
  HELP.34 = ,
"'*             SUBSYSTEM, TYPE AND PROCESSOR OBJECTS.  THE MAX-   *'"
  HELP.35 = ,
"'*             IMUM LENGTH OF THE APPROVER NAME IS 16.  THE MAX-  *'"
  HELP.36 = ,
"'*             IMUM LENGTH OF THE DESTINATION OBJECT_NAME IS 7.   *'"
  HELP.37 = ,
"'*                                                                *'"
  HELP.38 = ,
"'*  NOTE: YOU CAN REMOVE THESE LINES WITH THE D LINE COMMAND OR   *'"
  HELP.39 = ,
"'* BY ENTERING THE RESET SPECIAL COMMAND LINE COMMAND.            *'"
  HELP.40 = ,
"'*----------------------------------------------------------------*'"

  HELP.0 = 40                      /* SET THE NUMBER OF HELP LINES */

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
    "'ENBUILD: LINES WITH ???????? OR ? MUST BE CUSTOMIZED'"
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

