/* REXX                                                             */
/*------------------------------------------------------------------*/
/*                                                                  */
/*  COPYRIGHT (C) 1986-2013 CA. ALL RIGHTS RESERVED.                */
/*                                                                  */
/*  NAME: ENDEFINE                                                  */
/*                                                                  */
/*  PURPOSE: ENDEFINE IS AN ISPF/PDF EDIT MACRO THAT CAN BE USED    */
/*  TO CREATE SKELETON SCL STATEMENTS FOR THE BATCH ENVIRONMENT     */
/*  ADMINISTRATION FACILITY DEFINE ACTION.                          */
/*                                                                  */
/*  SYNTAX:   ENDEFINE OBJECT_TYPE <OBJECT_NAME>                    */
/*   WHERE:   OBJECT_TYPE: THE TYPE OF ENVIRONMENT OBJECT FOR       */
/*                         WHICH SCL WILL BE GENERATED.  VALID      */
/*                         VALUES ARE:                              */
/*                             SYSTEM                               */
/*                             SUBSYSTEM                            */
/*                             TYPE                                 */
/*                             SEQUENCE                             */
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
/*                         OBJECT.  FOR EXAMPLE, ON EHT ENDEFINE    */
/*                         SYSTEM COMMAND, THE OBJECT_NAME WOULD    */
/*                         BE THE NAME OF THE SYSTEM TO BE DEFINED. */
/*                                                                  */
/*            THE COMMAND ENDEFINE HELP OR ENDEFINE ? CAN BE USED   */
/*            TO GENERATE A SUMMARY OF THE ENDEFINE COMMAND SYNTAX, */
/*                                                                  */
/*  THE DEFINE ACTION SCL IS CREATED BY POPULATING STEM VARIABLE SCL*/
/* AND CALLING ROUTINE WRITESCL.  THE WRITESCL ROUTINE WILL USE THE */
/* APPROPRIATE ISPF/PDF EDIT MACRO COMMANDS TO INSERT THE SCL STATE-*/
/* MENTS INTO THE CURRENT POSITION IN THE DATA FILE.  THERE IS ONE  */
/* ROUTINE FOR EACH ENVIRONMENT OBJECT.  EACH ROUTINE BUILDS THE    */
/* SCL. VARIABLE AND SUBSEQUENTLY CALLS WRITESCL.                   */
/*                                                                  */
/*  THE ENDEFINE ROUTINE WILL ATTEMPT TO WRITE THE SCL AT THE CUR-  */
/* RENT CURSOR POSITION IN THE DATA FILE.  DUE TO LIMITATIONS OF    */
/* THE ISPF/PDF CURSOR COMMAND, THE SCL MAY NOT BE POSITIONED       */
/* EXACTLY WHERE EXPECTED.  IF THE CURSOR IS LOCATED ON THE         */
/* COMMAND LINE OR ON ANY NON-INPUT LINE, THE SCL WILL BE WRITTEN   */
/* AFTER THE FIRST DATA LINE THAT IS DISPLAYED.  OTHERWISE, THE     */
/* SCL WILL BE WRITTEN ON THE DATA LINE AFTER THE LINE WHERE THE    */
/* CURSOR IS POSITIONED.                                            */
/*                                                                  */
/*  THE DEFINE SCL THAT IS CREATED WILL INCLUDE ALL THE DEFINE      */
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
     ZEDLMSG = 'ENIP900E ENDEFINE REQUIRES AN OBJECT TYPE.',
               ' ENTER ENDEFINE HELP FOR HELP'
     ADDRESS ISPEXEC 'SETMSG MSG(ISRZ001)'
     RETURNCODE = 12
     SIGNAL ENDEFINE_EXIT
   END

  WHEN ((ENVOBJ = 'SYSTEM')  | ,
        (ENVOBJ = 'SYS')) THEN
   DO
      RETURNCODE = DEFINESYSTEM(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'SUBSYSTEM') | ,
        (ENVOBJ = 'SUB')) THEN
   DO
      RETURNCODE = DEFINESUBSYSTEM(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'TYPE') | ,
        (ENVOBJ = 'TYP')) THEN
   DO
      RETURNCODE = DEFINETYPE(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'SEQUENCE') | ,
        (ENVOBJ = 'SEQ')) THEN
   DO
      RETURNCODE = DEFINETYPESEQUENCE(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'GROUP') | ,
        (ENVOBJ = 'GRO')) THEN
   DO
      RETURNCODE = DEFINEPROCESSORGROUP(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'SYMBOL') | ,
        (ENVOBJ = 'SYM')) THEN
   DO
      RETURNCODE = DEFINEPROCESSORSYMBOL(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'APPROVER') | ,
        (ENVOBJ = 'APP')) THEN
   DO
      RETURNCODE = DEFINEAPPROVERGROUP(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'RELATION') | ,
        (ENVOBJ = 'REL')) THEN
   DO
      RETURNCODE = DEFINEAPPROVERRELATION(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'DESTINATION') | ,
        (ENVOBJ = 'DES')) THEN
   DO
      RETURNCODE = DEFINEDESTINATION(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'MAPRULE') | ,
        (ENVOBJ = 'MAP')) THEN
   DO
      RETURNCODE = DEFINEMAPPINGRULE(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'USSMAPRULE') | ,
        (ENVOBJ = 'USSMAP')) THEN
   DO
      RETURNCODE = DEFINEUSSMAPRULE(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'CHGORDCORR') | ,
        (ENVOBJ = 'COC')) THEN
   DO
      RETURNCODE = DEFINECHGORDCORR(CURLINE ENVOBJNM)
   END

  WHEN ((ENVOBJ = 'CHGORDJUNC') | ,
        (ENVOBJ = 'COJ')) THEN
   DO
      RETURNCODE = DEFINECHGORDJUNC(CURLINE ENVOBJNM)
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
     SIGNAL ENDEFINE_EXIT

END

/*------------------------------------------------------------------*/
/* MACRO EXIT POINT.  THE VARIABLE RETURNCODE CONTAINS THE MACRO    */
/* RETURN CODE.                                                     */
/*------------------------------------------------------------------*/
ENDEFINE_EXIT: NOP
  ADDRESS ISPEXEC 'ISREDIT USER_STATE = (USERST)'
  EXIT RETURNCODE

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DEFINESYSTEM                                               */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DEFINE       */
/*  SYSTEM ACTION.                                                  */
/*                                                                  */
/*------------------------------------------------------------------*/
DEFINESYSTEM:
  ARG LINENUMBER OBJECTNAME              .

  LOCALRC = CHECKOBJECTLENGTH(8 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
       IF (OBJECTNAME = '') THEN
          OBJECTNAME = '????????'

       SCL.1  = ' DEFINE SYSTEM '''||OBJECTNAME||''''
       SCL.2  = '   TO ENVIRONMENT ''????????''             '
       SCL.3  = '   DESCRIPTION ''???????? ''               '
       SCL.4  = '   NEXT SYSTEM '''||OBJECTNAME||''''
       SCL.5  = '   COMMENTS NOT REQUIRED                   '
       SCL.6  = '   CCID NOT REQUIRED                       '
       SCL.7  = '   DUPLICATE ELEMENT CHECK IS NOT ACTIVE   '
       SCL.8  = '   DUPLICATE PROCESSOR OUTPUT CHECK IS NOT ACTIVE '
       SCL.9  = '   ELEMENT JUMP ACKNOWLEDGMENT REQUIRED    '
       SCL.10 = '   SIGNOUT IS NOT ACTIVE                   '
       SCL.11 = '   SIGNOUT DATASET VALIDATION IS NOT ACTIVE'
       SCL.12 = '   STAGE ONE LOAD LIBRARY IS               '
       SCL.13 = '      ''???????? ''                        '
       SCL.14 = '   STAGE ONE LIST LIBRARY IS               '
       SCL.15 = '      ''???????? ''                        '
       SCL.16 = '   STAGE TWO LOAD LIBRARY IS               '
       SCL.17 = '      ''???????? ''                        '
       SCL.18 = '   STAGE TWO LIST LIBRARY IS               '
       SCL.19 = '      ''???????? ''                        '
       SCL.20 = ' .                                         '
       SCL.0 = 20

       CALL WRITESCL LINENUMBER
    END

  RETURN LOCALRC

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DEFINESUBSYSTEM                                            */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DEFINE       */
/*  SUBSYSTEM ACTION.                                               */
/*                                                                  */
/*------------------------------------------------------------------*/
DEFINESUBSYSTEM: PROCEDURE
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(8 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
       IF (OBJECTNAME = '') THEN
          OBJECTNAME = '????????'

       SCL.1  = ' DEFINE SUBSYSTEM '''||OBJECTNAME||''''
       SCL.2  = '   TO ENVIRONMENT ''????????''          '
       SCL.3  = '      SYSTEM ''????????''               '
       SCL.4  = '   DESCRIPTION ''???????? ''            '
       SCL.5  = '   NEXT SUBSYSTEM '''||OBJECTNAME||''''
       SCL.6  = '   DO NOT EXCLUDE DUPLICATE PROCESSOR OUTPUT CHECK'
       SCL.7  = ' .                                      '
       SCL.0 = 7

       CALL WRITESCL LINENUMBER
    END

  RETURN LOCALRC

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DEFINETYPE                                                 */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DEFINE TYPE  */
/*  ACTION.                                                         */
/*                                                                  */
/*------------------------------------------------------------------*/
DEFINETYPE:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(8 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
      IF (OBJECTNAME = '') THEN
         OBJECTNAME = '????????'

      SCL.1  = ' DEFINE TYPE '''||OBJECTNAME||''''
      SCL.2  = '   TO ENVIRONMENT ''????????''          '
      SCL.3  = '      SYSTEM ''????????''               '
      SCL.4  = '      STAGE NUMBER ?                    '
      SCL.5  = '   DESCRIPTION ''???????? ''            '
      SCL.6  = '   NEXT TYPE '''||OBJECTNAME||''''
      SCL.7  = '   BASE LIBRARY IS                      '
      SCL.8  = '        ''???????? ''                   '
      SCL.9  = '   DELTA LIBRARY IS                     '
      SCL.10 = '        ''???????? ''                   '
      SCL.11 = '   INCLUDE LIBRARY IS                   '
      SCL.12 = '        ''???????? ''                   '
      SCL.13 = '   DO NOT EXPAND INCLUDES               '
      SCL.14 = '   SOURCE OUTPUT LIBRARY IS             '
      SCL.15 = '        ''???????? ''                   '
      SCL.16 = '   DEFAULT PROCESSOR GROUP IS *NOPROC*  '
      SCL.17 = '   SOURCE ELEMENT LENGTH IS ???????     '
      SCL.18 = '   COMPARE FROM COLUMN ???????? TO ????????'
      SCL.19 = '   LANGUAGE IS ????????                 '
      SCL.20 = '* IF PANVALET OR LIBRARIAN SUPPORT IS USED, UNCOMMENT '
      SCL.21 = '* ONE OF THE FOLLOWING TWO STATEMENTS.                '
      SCL.22 = '*  PANVALET LANGUAGE IS ????????        '
      SCL.23 = '*  LIBRARIAN LANGUAGE IS ????????       '
      SCL.24 = '   ELEMENT DELTA FORMAT IS FORWARD      '
      SCL.25 = '   COMPRESS BASE                        '
      SCL.26 = '   REGRESSION PERCENTAGE THRESHOLD IS 50'
      SCL.27 = '   REGRESSION SEVERITY IS CAUTION       '
      SCL.28 = '   CONSOLIDATE ELEMENT LEVELS           '
      SCL.29 = '   CONSOLIDATE ELEMENT AT LEVEL 99      '
      SCL.30 = '   NUMBER OF ELEMENT LEVELS TO CONSOLIDATE 50'
      SCL.31 = '* IF YOU ARE USING HFS FILES, LONGNAME ELEMENTS'
      SCL.32 = '* OR THE LFS FEATURE FROM ENTERPRISE WORKBENCH '
      SCL.33 = '* UNCOMMENT THE FOLLOWING STATEMENTS.          '
      SCL.34 = '*  DATA FORMAT IS TEXT                  '
      SCL.35 = '*  HFS RECFM NL                         '
      SCL.36 = '*  FILE EXTENSION IS                    '
      SCL.37 = '   COMPONENT DELTA FORMAT IS FORWARD    '
      SCL.38 = '   CONSOLIDATE COMPONENT LEVELS         '
      SCL.39 = '   CONSOLIDATE COMPONENT AT LEVEL 99    '
      SCL.40 = '   NUMBER OF COMPONENT LEVELS TO CONSOLIDATE 50'
      SCL.41 = '*  ELEMENT RECFM IS NOT DEFINED         '
      SCL.42 = ' .                                      '
      SCL.0 = 42

      CALL WRITESCL LINENUMBER
  END

  RETURN LOCALRC

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DEFINETYPESEQUENCE                                         */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DEFINE TYPE  */
/*  SEQUENCE ACTION.                                                */
/*                                                                  */
/*------------------------------------------------------------------*/
DEFINETYPESEQUENCE:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKNULLOBJECT(ENVOBJNM)

  SCL.1  = ' DEFINE TYPE SEQUENCE                   '
  SCL.2  = '   TO ENVIRONMENT ''????????''          '
  SCL.3  = '      SYSTEM ''????????''               '
  SCL.4  = '      STAGE NUMBER ?                    '
  SCL.5  = '   SEQUENCE = (????????,?)              '
  SCL.6  = '   SEQUENCE = (????????,?)              '
  SCL.7  = ' .                                      '
  SCL.0  = 7

  CALL WRITESCL LINENUMBER

  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DEFINEPROCESSORGROUP                                       */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DEFINE       */
/*  PROCESSOR GROUP ACTION.                                         */
/*                                                                  */
/*------------------------------------------------------------------*/
DEFINEPROCESSORGROUP:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(8 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
      IF (OBJECTNAME = '') THEN
         OBJECTNAME = '????????'

      SCL.1  = ' DEFINE PROCESSOR GROUP '''||OBJECTNAME||''''
      SCL.2  = '   TO ENVIRONMENT ''????????''          '
      SCL.3  = '      SYSTEM ''????????''               '
      SCL.4  = '      TYPE ''????????''                 '
      SCL.5  = '      STAGE NUMBER ?                    '
      SCL.6  = '   DESCRIPTION ''???????? ''            '
      SCL.7  = '   NEXT PROCESSOR GROUP '''||OBJECTNAME||''''
      SCL.8  = '   PROCESSOR OUTPUT TYPE ????????       '
      SCL.9  = '   GENERATE PROCESSOR NAME IS ????????  '
      SCL.10 = '     ALLOW FOREGROUND EXECUTION         '
      SCL.11 = '   DELETE PROCESSOR NAME IS ????????    '
      SCL.12 = '     ALLOW FOREGROUND EXECUTION         '
      SCL.13 = '   MOVE PROCESSOR NAME IS ????????      '
      SCL.14 = '     ALLOW FOREGROUND EXECUTION         '
      SCL.15 = '   MOVE ACTION USES MOVE PROCESSOR      '
      SCL.16 = '   TRANSFER ACTION USES GENERATE PROCESSOR'
      SCL.17 = ' .                                      '
      SCL.0 = 17

      CALL WRITESCL LINENUMBER
  END

  RETURN LOCALRC

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DEFINEAPPROVERGROUP                                        */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DEFINE       */
/*  APPROVER GROUP ACTION.                                          */
/*                                                                  */
/*------------------------------------------------------------------*/
DEFINEAPPROVERGROUP:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(8 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
      IF (OBJECTNAME = '') THEN
         OBJECTNAME = '????????'

      SCL.1  = ' DEFINE APPROVER GROUP '''||OBJECTNAME||''''
      SCL.2  = '   TO ENVIRONMENT ''????????''          '
      SCL.3  = '   TITLE ''???????? ''                  '
      SCL.4  = '   QUORUM SIZE IS 0                     '
      SCL.5  = '   APPROVER = (????????,REQUIRED)       '
      SCL.6  = ' .                                      '
      SCL.0 = 6

      CALL WRITESCL LINENUMBER
  END

  RETURN LOCALRC

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DEFINEAPPROVERRELATION                                     */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DEFINE       */
/*  APPROVER RELATION ACTION.                                       */
/*                                                                  */
/*------------------------------------------------------------------*/
DEFINEAPPROVERRELATION:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKNULLOBJECT(ENVOBJNM)

  SCL.1  = ' DEFINE APPROVER RELATION               '
  SCL.2  = '   FOR APPROVER GROUP ''????????''      '
  SCL.3  = '   TO ENVIRONMENT ''????????''          '
  SCL.4  = '      SYSTEM ''????????''               '
  SCL.5  = '      SUBSYSTEM ''????????''            '
  SCL.6  = '      TYPE ''????????''                 '
  SCL.7  = '      STAGE NUMBER ?                    '
  SCL.8  = '   TYPE IS STANDARD                     '
  SCL.9  = ' .                                      '
  SCL.0  = 9

  CALL WRITESCL LINENUMBER

  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DEFINEPROCESSORSYMBOL                                      */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DEFINE       */
/*  PROCESSOR SYMBOL ACTION                                         */
/*                                                                  */
/*------------------------------------------------------------------*/
DEFINEPROCESSORSYMBOL:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKNULLOBJECT(ENVOBJNM)

  SCL.1  = ' DEFINE PROCESSOR SYMBOL                '
  SCL.2  = '   TO ENVIRONMENT ''????????''          '
  SCL.3  = '      SYSTEM ''????????''               '
  SCL.4  = '      TYPE ''????????''                 '
  SCL.5  = '      STAGE NUMBER ?                    '
  SCL.6  = '      PROCESSOR GROUP ????????          '
  SCL.7  = '      PROCESSOR TYPE EQ ????????        '
  SCL.8  = '   SYMBOL ???????? = ????????           '
  SCL.9  = ' .                                      '
  SCL.0  = 9

  CALL WRITESCL LINENUMBER

  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DEFINEDESTINATION                                          */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DEFINE       */
/*  SHIPMENT DESTINATION ACTION                                     */
/*                                                                  */
/*------------------------------------------------------------------*/
DEFINEDESTINATION:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(7 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
      IF (OBJECTNAME = '') THEN
         OBJECTNAME = '???????'

      SCL.1  = ' DEFINE SHIPMENT DESTINATION '''||OBJECTNAME||''''
      SCL.2  = '   DESCRIPTION ''???????? ''            '
      SCL.3  = '* TRANSMISSION METHODS ARE:             '
      SCL.4  = '*   BDT, BDTNJE, LOCAL, NDM, NETVIEWFTP, XCOM '
      SCL.5  = '   TRANSMISSION METHOD ????????         '
      SCL.6  = '* XCOM SUPPORTS NODENAME OR IPNAME (1-63)'
      SCL.7  = '*  REMOTE IPNAME                        '
      SCL.8  = '*  ''????????''                         '
      SCL.9  = '*  IPPORT ????????                      '
      SCL.10 = '   REMOTE NODENAME ????????             '
      SCL.11 = '   DO NOT SHIP COMPLEMENTARY DATASET    '
      SCL.12 = '   HOST DATASET PREFIX ''????????''     '
      SCL.13 = '   HOST DISPOSITION DELETE              '
      SCL.14 = '   HOST UNIT SYSDA                      '
      SCL.15 = '   HOST VOLUME SERIAL ??????            '
      SCL.16 = '   REMOTE DATASET PREFIX ''????????''   '
      SCL.17 = '   REMOTE DISPOSITION DELETE            '
      SCL.18 = '   REMOTE UNIT SYSDA                    '
      SCL.19 = '   REMOTE VOLUME SERIAL ??????          '
  SCL.20 = '   USS HOST PATH NAME PREFIX ''????????????????????????????????'', '
  SCL.21 = '                   ''?????????????????????????????????''           '
  SCL.22 = '   USS HOST PATH DISPOSITION DELETE         '
  SCL.23 = '   USS REMOTE PATH NAME PREFIX ''??????????????????????????????'', '
  SCL.24 = '                   ''?????????????????????????????????''           '
  SCL.25 = '   USS REMOTE PATH DISPOSITION DELETE       '
      SCL.26 = '   REMOTE JOBCARD =                                  '
      SCL.27 = '    (''//*JOBNAMEX JOB ACCT,NAME                 '', '
      SCL.28 = '     ''//*                                       '', '
      SCL.29 = '     ''//*                                       '', '
      SCL.30 = '     ''//*                                       '') '
      SCL.31 = ' .                                      '
      SCL.0 = 31

      CALL WRITESCL LINENUMBER
  END
  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DEFINEMAPPINGRULE                                          */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DEFINE       */
/*  SHIPMENT MAPPING RULE ACTION.                                   */
/*                                                                  */
/*------------------------------------------------------------------*/
DEFINEMAPPINGRULE:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKNULLOBJECT(ENVOBJNM)

  SCL.1  = ' DEFINE SHIPMENT MAPPING RULE           '
  SCL.2  = '   TO DESTINATION ''???????''           '
  SCL.3  = '   DESCRIPTION ''????????''             '
  SCL.4  = '   HOST DATASET ''????????''            '
  SCL.5  = '      MAPS TO ''????????''              '
  SCL.6  = '   APPROXIMATE MEMBERS PER CYLINDER ''???'' '
  SCL.7  = ' .                                      '
  SCL.0  = 7

  CALL WRITESCL LINENUMBER

  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DEFINEUSSMAPRULE                                           */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DEFINE       */
/*  SHIPMENT USS MAPPING RULE ACTION.                               */
/*                                                                  */
/*------------------------------------------------------------------*/
DEFINEUSSMAPRULE:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKNULLOBJECT(ENVOBJNM)

  SCL.1  = ' DEFINE SHIPMENT USS MAPPING RULE           '
  SCL.2  = '   TO DESTINATION ''???????''           '
  SCL.3  = '   DESCRIPTION ''????????''             '
  SCL.4  = '   USS HOST PATH NAME ''???????????????????????????????????????'', '
  SCL.5  = '        ''????????????????????????????????????????''               '
  SCL.6  = '      MAPS TO  ''??????????????????????????????????????????????'', '
  SCL.7  = '        ''????????????????????????????????????????''               '
  SCL.8  = ' .                                      '
  SCL.0  = 8

  CALL WRITESCL LINENUMBER

  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DEFINECHGORDCORR                                           */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DEFINE       */
/*  CHANGE ORDER CORRELATION ACTION.                                */
/*                                                                  */
/*------------------------------------------------------------------*/
DEFINECHGORDCORR:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKOBJECTLENGTH(32 OBJECTNAME)
  IF (LOCALRC = 0) THEN
    DO
      IF (OBJECTNAME = '') THEN
         OBJECTNAME = '???????'

  SCL.1  = ' DEFINE CHANGE ORDER CORRELATION '''||OBJECTNAME||''''
  SCL.2  = '   DESCRIPTION ''????????''             '
  SCL.3  = '   STATUS      ''????????''             '
  SCL.4  = '   USERDATA    ''???????????????????????????????????????'',        '
  SCL.5  = '        ''????????????????????????????????????????''               '
  SCL.6  = '   OPTIONS                              '
  SCL.7  = '        EXECUTION WINDOW FROM ddmmmyy hh:mm TO ddmmmyy hh:mm       '
  SCL.8  = ' .                                      '
  SCL.0  = 8

  CALL WRITESCL LINENUMBER

  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: DEFINECHGORDJUNC                                           */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL GENERATE THE SCL FOR THE DEFINE       */
/*  CHANGE ORDER JUNCTION ACTION.                                   */
/*                                                                  */
/*------------------------------------------------------------------*/
DEFINECHGORDJUNC:
  ARG LINENUMBER OBJECTNAME .

  LOCALRC = CHECKNULLOBJECT(ENVOBJNM)

  SCL.1  = ' DEFINE CHANGE ORDER JUNCTION           '
  SCL.2  = '   TO ENVIRONMENT ''????????''          '
  SCL.3  = '      SYSTEM ''????????''               '
  SCL.4  = '      SUBSYSTEM ''????????''            '
  SCL.5  = '      TYPE ''????????''                 '
  SCL.6  = '      STAGE NUMBER ?                    '
  SCL.7  = '****  STAGE ID ?                        '
  SCL.8  = ' .                                      '
  SCL.0  = 8

  CALL WRITESCL LINENUMBER

  RETURN 0

/*------------------------------------------------------------------*/
/*                                                                  */
/* NAME: PRINTHELP                                                  */
/*                                                                  */
/* PURPOSE: THIS ROUTINE WILL PRINT THE HELP INFORMATION ASSOCIATED */
/*  WITH THE ENDEFINE COMMAND.  THE HELP INFORMATION IS DISPLAYED   */
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
"'*  ENDEFINE COMMAND EXTENDED HELP                                *'"
  HELP.3 = ,
"'*                                                                *'"
  HELP.4 = ,
"'*  THE ENDEFINE COMMAND IS USED TO GENERATE MODEL SCL STATEMENTS *'"
  HELP.5 = ,
"'* FOR THE BATCH ENVIRONMENT ADMINISTRATION FACILITY              *'"
  HELP.6 = ,
"'* DEFINE ACTION.                                                 *'"
  HELP.7 = ,
"'*                                                                *'"
  HELP.8 = ,
"'*  COMMAND SYNTAX:                                               *'"
  HELP.9 = ,
"'*                                                                *'"
  HELP.10 = ,
"'*    ENDEFINE OBJECT_TYPE OBJECT_NAME                            *'"
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
"'*              SEQuence - TYPE SEQUENCE DEFINITION               *'"
  HELP.20 = ,
"'*              GROup - PROCESSOR GROUP DEFINITION                *'"
  HELP.21 = ,
"'*              SYMbol - PROCESSOR GROUP SYMBOL DEFINITION        *'"
  HELP.22 = ,
"'*              APProver - APPROVER GROUP DEFINITION              *'"
  HELP.23 = ,
"'*              RELation - APPROVER GROUP RELATIONSHIP DEFINITION *'"
  HELP.24 = ,
"'*              DEStination - PACKAGE SHIPMENT DESTINATION        *'"
  HELP.25 = ,
"'*              MAPrule - PACKAGE SHIPMENT MAPPING RULE DEFINITION*'"
  HELP.26 = ,
"'*              USSMAPrule - PACKAGE SHIPMENT USS MAPPING RULE    *'"
  HELP.27 = ,
"'*              CHGORDCORR -  CHANGE ORDER CORRELATION DEFINITION *'"
  HELP.28 = ,
"'*              CHGORDJUNC -  CHANGE ORDER JUNCTION DEFINITION    *'"
  HELP.29 = ,
"'*                           DEFINITION                           *'"
  HELP.30 = ,
"'*                                                                *'"
  HELP.31 = ,
"'*           OBJECT_NAME IS THE OPTIONAL NAME OF THE ENVIRONMENT  *'"
  HELP.32 = ,
"'*             OBJECT.  IF THE OBJECT_NAME IS NOT PROVIDED, THE   *'"
  HELP.33 = ,
"'*             DEFINE SCL WILL USE THE VALUE ???????? AS THE      *'"
  HELP.34 = ,
"'*             ENVIRONMENT OBJECT.  THE OBJECT_NAME IS IGNORED FOR*'"
  HELP.35 = ,
"'*             THE SEQUENCE, RELATION, SYMBOL, MAPRULE AND        *'"
  HELP.36 = ,
"'*             USSMAPRULE ENVIRONMENT OBJECTS.  THE OBJECT_NAME   *'"
  HELP.37 = ,
"'*             CAN HAVE A MAXIMUM LENGTH OF 8 CHARACTERS FOR THE  *'"
  HELP.38 = ,
"'*             SYSTEM, SUBSYSTEM, TYPE ,PROCESSOR GROUP           *'"
  HELP.39 = ,
"'*             CHANGE ORDER CORRELATION, CHANGE ORDER JUNCTION    *'"
  HELP.40 = ,
"'*             OBJECTS. THE MAXIMUM LENGTH OF THE APPROVER        *'"
  HELP.41 = ,
"'*             OBJECT_NAME IS 16. THE MAXIMUM LENGTH OF THE       *'"
  HELP.42 = ,
"'*             DESTINATION OBJECT_NAME IS 7.                      *'"
  HELP.43 = ,
"'*                                                                *'"
  HELP.44 = ,
"'*  NOTE: YOU CAN REMOVE THESE LINES WITH THE D LINE COMMAND OR   *'"
  HELP.45 = ,
"'* BY ENTERING THE RESET SPECIAL COMMAND LINE COMMAND.            *'"
  HELP.46 = ,
"'*----------------------------------------------------------------*'"

  HELP.0 = 46                      /* SET THE NUMBER OF HELP LINES */

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
    "'ENDEFINE: LINES WITH ???????? OR ? MUST BE CUSTOMIZED'"
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
/*     0: THE ENVIRONMENT OBJECT NAME LENGTH IS VALID               */
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

