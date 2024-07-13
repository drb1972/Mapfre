/* REXX */

/****************/
/* READ RECORDS */
/****************/

"EXECIO * DISKRU IN1 (STEM IN1. FINIS)"

/*********************************/
/* READ RECORDS AND CHECK SYSDSN */
/*********************************/

FLAG=NO
DO I = 1 TO IN1.0
   IN1.I=SUBSTR(IN1.I,2)
   IF SUBSTR(IN1.I,41,8)="LINKEDIT" THEN QUEUE IN1.I
   IF SUBSTR(IN1.I,1,12)="** PDSM22 **" THEN DO
      IF FLAG=NO THEN QUEUE IN1.I
      FLAG=YES
      END
   IF SUBSTR(IN1.I,8,8)="TYPE=LINKEDIT" THEN QUEUE IN1.I
   END

FLAG=NO
/*******************/
/* WRITEOUT REPORT */
/*******************/

 "EXECIO "QUEUED()" DISKW IN1 (FINIS)"

/****************/
/* READ RECORDS */
/****************/

"EXECIO * DISKRU IN2 (STEM IN2. FINIS)"

/*********************************/
/* READ RECORDS AND CHECK SYSDSN */
/*********************************/

DO I = 1 TO IN2.0
   IN2.I=SUBSTR(IN2.I,2)
   IF SUBSTR(IN2.I,41,8)="LINKEDIT" THEN QUEUE IN2.I
   IF SUBSTR(IN2.I,1,12)="** PDSM22 **" THEN DO
      IF FLAG=NO THEN QUEUE IN2.I
      FLAG=YES
      END
   IF SUBSTR(IN2.I,8,8)="TYPE=LINKEDIT" THEN QUEUE IN2.I
   END

/*******************/
/* WRITEOUT REPORT */
/*******************/

 "EXECIO "QUEUED()" DISKW IN2 (FINIS)"

/********/
/* EXIT */
/********/

EXIT
