/* REXX */
/**********************************************************************/
/****  AUTHOR:   VINCE FELTON                      DATE 19.10.93   ****/
/****  FUNCTION: CREATE URT SOURCE FOR SPECIFIED BUS AREA CLONE.   ****/
/****  AMENDED:  VINCE FELTON                      DATE 23.05.94   ****/
/****  FUNCTION: SET UP VARIABLES FOR CONDITIONAL ASSEMBLY.        ****/
/****  AMENDED:  VINCE FELTON                      DATE 14.05.96   ****/
/****  FUNCTION: ALTER AUTHID FOR SQL ACCESS.                      ****/
/**********************************************************************/
TRACE O
MAIN:

CALL INIT

PROC='MAIN'

DO I=1 TO NUMBER_OF_URT_CARDS BY 1

   LINE.1 = URT.I
   POS = INDEX(URT.I,"DBID=")

   /* ALTER DBID FOR CURRENT BUSINESS AREA. */

   IF POS > 0 THEN DO

      MASTER_DBID = SUBSTR(URT.I,POS+5,3)

      IF  (MASTER_DBID > "039" & ,
          (MASTER_DBID < "250" | ,
           MASTER_DBID > "299" )) THEN DO


         CALL ASBW7790

         LINE.1 = SUBSTR(LINE.1,1,POS+4) || CLONE_ID || ,
                  SUBSTR(LINE.1,POS+8,80-POS+7)

      END

   END

   /* ALTER AUTHID FOR CURRENT BUSINESS AREA. */

   POS = INDEX(URT.I,"AUTHID=SYSUSR,")

   IF (POS > 0 & BUS_AREA_ID <> "MST") THEN DO

      LINE.1 = SUBSTR(LINE.1,1,POS-1) || ,
               "AUTHID=SYSUSR_"       || ,
               BUS_AREA_ID            || ,
               ","                    || ,
               SUBSTR(LINE.1,POS+18,80-POS+17)

   END

   WRITE:
   "EXECIO 1 DISKW URTOUT (STEM LINE."

END

QUIT:
EXIT

ERROR:
EXIT 12

/**********************************************************************/
/****    INITIAL PROCESSING. ONCE ONLY.                            ****/
/****    READ IN URT SOURCE.                                       ****/
/****    READ AND VALIDATE CLONE ID PARM.                          ****/
/**********************************************************************/
INIT:

PROC='INIT'

"EXECIO * DISKR URTIN (FINIS STEM URT."           /* READ URT SOURCE */
 NUMBER_OF_URT_CARDS = URT.0
"EXECIO * DISKR PARMIN (FINIS STEM PARM."    /* READ INPUT PARAMETER */
 NUMBER_OF_PARM_CARDS = PARM.0

 IF NUMBER_OF_PARM_CARDS <> 1 THEN DO
    SAY "INVALID INPUT PARAMETER."
    SIGNAL ERROR
 END

 SELECT
 WHEN WORD(PARM.1,1) = "MST" THEN NOP
 WHEN (WORD(PARM.1,1) < "000" | WORD(PARM.1,1) > "650") THEN DO
    SAY "INVALID BUSINESS AREA ID ON INPUT PARAMETER."
    SIGNAL ERROR
 END
 OTHERWISE NOP
 END

 BUS_AREA_ID = WORD(PARM.1,1)

/**********************************************************************/
/**** SET UP SYMBOLICS FOR DBIDS HELD IN COPY MEMBERS THAT ARE     ****/
/**** SUBSEQUENTLY RESOLVED BY A CONDITIONAL ASSEMBLY.             ****/
/****                                                              ****/
/**** URT COPYBOOKS MUST HAVE THE DBID= PARM CODED AS FOLLOWS:     ****/
/****           DBID=&DBNNN,     WHERE NNN=MASTER DATABASE ID      ****/
/**********************************************************************/

 DO I=40 TO 199

    MASTER_DBID = RIGHT(I,3,'0')

    CALL ASBW7790

    IF RETURN_CODE = "03" THEN NOP
    ELSE DO

       LINE.1 = "&DB" || MASTER_DBID || " SETA " || CLONE_ID
       "EXECIO 1 DISKW URTOUT (STEM LINE."

    END

 END

RETURN
/**********************************************************************/
/**** ASBW7790 RETURNS THE BASE CLONE ID CORRESPONDING TO THE      ****/
/**** MASTER DBID SUPPLIED. THIS PROC THEN ADDS ON THE BUSINESS    ****/
/**** AREA ID TO DERIVE THE CLONE DATABASE ID.                     ****/
/**********************************************************************/
ASBW7790:

 ASBW7790_PARM = "01" || MASTER_DBID || "000WWWWWWWWRR"
 CALL USERPROG ASBW7790,ASBW7790_PARM

 BASE_CLONE_ID = SUBSTR(RESULT,6,3)
 RETURN_CODE   = SUBSTR(RESULT,17,2)

 IF RETURN_CODE <> "00" THEN DO
    SELECT
    WHEN RETURN_CODE = "01" THEN MESSAGE = "INVALID NO OF PARMS"
    WHEN RETURN_CODE = "02" THEN MESSAGE = "NON NUMERIC DBID"
    WHEN RETURN_CODE = "03" THEN MESSAGE = "UNKNOWN DBID"
    WHEN RETURN_CODE = "04" THEN MESSAGE = "UNSUPPORTED VERSION"
    OTHERWISE                    MESSAGE = "UNKNOWN ERROR"
    END
    IF (PROC = 'INIT' & RETURN_CODE = "03") THEN
       BASE_CLONE_ID = 0
    ELSE DO
       SAY "ASBW7790 ERROR RC: " || RETURN_CODE || " DBID: " || ,
          MASTER_DBID || " REASON: " || MESSAGE
       SIGNAL ERROR
    END
 END

 IF BUS_AREA_ID = "MST" THEN

    CLONE_ID = RIGHT(MASTER_DBID,3,'0')

 ELSE

    CLONE_ID = RIGHT(BASE_CLONE_ID + BUS_AREA_ID,3,'0')

RETURN
