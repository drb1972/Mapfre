/* REXX */
TRACE N
ADDRESS TSO

/*****************************************************************/
/* THIS JOB RUNS ON THE FIRST OF THE MONTH, SO THIS FIGURES OUT  */
/* LAST MONTHS MONTH AND ALSO THE YEAR, ALLOWS FOR 2000.         */
/*                                                               */
/* WRITTEN: 2/12/97                       AUTHOR: S.BATT         */
/*****************************************************************/

MONTH=SUBSTR(DATE(M),1,3)
UPPER MONTH

/*****************************************************************/
/* SET PREVIOUS MONTH VARIABLE                                   */
/*****************************************************************/

IF MONTH='JAN' THEN PMONTH='DEC'
ELSE IF MONTH='FEB' THEN PMONTH='JAN'
ELSE IF MONTH='MAR' THEN PMONTH='FEB'
ELSE IF MONTH='APR' THEN PMONTH='MAR'
ELSE IF MONTH='MAY' THEN PMONTH='APR'
ELSE IF MONTH='JUN' THEN PMONTH='MAY'
ELSE IF MONTH='JUL' THEN PMONTH='JUN'
ELSE IF MONTH='AUG' THEN PMONTH='JUL'
ELSE IF MONTH='SEP' THEN PMONTH='AUG'
ELSE IF MONTH='OCT' THEN PMONTH='SEP'
ELSE IF MONTH='NOV' THEN PMONTH='OCT'
ELSE IF MONTH='DEC' THEN PMONTH='NOV'

/*****************************************************************/
/* SET YEAR VARIABLE                                             */
/*****************************************************************/

YEAR=SUBSTR(DATE(J),1,2)
NYEAR=YEAR

/*****************************************************************/
/* AS REPORT IS RUN FOR PREV MONTH THEN SET YEAR IF PMONTH=DEC   */
/* ALLOC FOR COMPLICATIONS WITH CHANGE OF CENTURY                */
/*****************************************************************/

IF PMONTH='DEC' THEN DO
   IF YEAR^='01' & YEAR^='1' & YEAR^='00' & YEAR^='0' THEN NYEAR=YEAR-1
   IF YEAR='01' | YEAR='1' THEN NYEAR='00'
   IF YEAR='00' | YEAR='0' THEN NYEAR='99'
   END

/*****************************************************************/
/* BUILD DATE PARAMETER FOR PACKAGE REPORT WINDOW                */
/*****************************************************************/

THEDAT='01'||PMONTH||NYEAR

/*****************************************************************/
/* QUEUE THE CARDS THAT RESTRICT THE REPORT TO ONE MONTH         */
/*****************************************************************/

 QUEUE "    WINDOW    AFTER "THEDAT " ."
 QUEUE "    CREATE    AFTER "THEDAT " ."
 QUEUE "    EXECUTE   AFTER "THEDAT " ."
 QUEUE "    CAST      AFTER "THEDAT " ."
 QUEUE "    BACKEDOUT AFTER "THEDAT " ."
 QUEUE "                               "
 say 'EVHPCK1M: Cards built as follows:-'
 say 'EVHPCK1M: '
 say 'EVHPCK1M: WINDOW    AFTER 'THEDAT ' .'
 say 'EVHPCK1M: CREATE    AFTER 'THEDAT ' .'
 say 'EVHPCK1M: EXECUTE   AFTER 'THEDAT ' .'
 say 'EVHPCK1M: CAST      AFTER 'THEDAT ' .'
 say 'EVHPCK1M: BACKEDOUT AFTER 'THEDAT ' .'
 say 'EVHPCK1M: '

/*****************************************************************/
/* WRITE OUT THE CARDS TO BE INPUTED TO THE REPORT STEP          */
/*****************************************************************/

"EXECIO * DISKW DATECARD (FINIS"
  cc = rc
    if cc > 0 then do
      say 'EVHPCK1M: execio of DATECARD ddname gave a return code of 'cc
      exit cc
    end /* if cc > 0 then do */

"DELSTACK"

/*****************************************************************/
/* EXIT                                                          */
/*****************************************************************/

 EXIT
