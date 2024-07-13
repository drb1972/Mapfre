/* REXX */

/*****************************************************************/
/* THIS REXX RUNS AND BUILD A OUTPUT DATASET NAME BASED ON LAST  */
/* MONTH, IF ALLOC FAILS THEN REXX DELETES LAST YEARS COPY AND   */
/* THEN REALLOCATES.                                             */
/*                                                               */
/* WRITTEN: 2/12/97                       AUTHOR: S.BATT         */
/*****************************************************************/

TRACE N
ADDRESS TSO

/*****************************************************************/
/* READ IN VARIABLE OF DSN PREFIX AND JOBNAME.                   */
/*****************************************************************/

ARG PREFIX JOBNAME .

/*****************************************************************/
/* IF VARIABLE NOT PROVIDED THEN SET DEFAULTS.                   */
/*****************************************************************/

IF PREFIX='' THEN PREFIX='PREV'
IF JOBNAME='' THEN JOBNAME='JOBNAME'

/*****************************************************************/
/* BUILD PREVIOUS MONTH NAME AS JOB RUNS ON THE FIRST.           */
/*****************************************************************/

MONTH=SUBSTR(DATE(M),1,3)
UPPER MONTH
IF MONTH='JAN' THEN MONTH='L----DEC'
ELSE IF MONTH='FEB' THEN MONTH='A----JAN'
ELSE IF MONTH='MAR' THEN MONTH='B----FEB'
ELSE IF MONTH='APR' THEN MONTH='C----MAR'
ELSE IF MONTH='MAY' THEN MONTH='D----APR'
ELSE IF MONTH='JUN' THEN MONTH='E----MAY'
ELSE IF MONTH='JUL' THEN MONTH='F----JUN'
ELSE IF MONTH='AUG' THEN MONTH='G----JUL'
ELSE IF MONTH='SEP' THEN MONTH='H----AUG'
ELSE IF MONTH='OCT' THEN MONTH='I----SEP'
ELSE IF MONTH='NOV' THEN MONTH='J----OCT'
ELSE IF MONTH='DEC' THEN MONTH='K----NOV'

/*****************************************************************/
/* BUILD THE DATASET NAME WE WANT TO CREATE.                     */
/*****************************************************************/

 THEDSN=PREFIX||'.NENDEVOR.'||JOBNAME||'.PACKAGE.'||MONTH

/*****************************************************************/
/* DYANMICALLY ALLOCATE FILENAME.                                */
/*****************************************************************/

ALOCFILE:

"ALLOC F(OUTDD) DA('"THEDSN"') NEW CATALOG" ,
"SPACE(100,20) CYL LRECL(133) BLKSIZE(27930) RECFM(F B)"

/**********************************************************************/
/* IF ALLOCATE FAILS THEN LAST YEARS REPORT SO DELETE AND RE-ALLOCATE */
/**********************************************************************/

IF RC=12 THEN DO
   "DELETE '"THEDSN"'"
   SIGNAL ALOCFILE
   END

/*****************************************************************/
/* QUEUE REPRO COMMAND TO COPY REPORT TO DYNAMICALLY ALLOC FILE  */
/*****************************************************************/

 QUEUE "   REPRO INFILE(INDD) OUTFILE(OUTDD)        ";
 QUEUE "                                            ";
"EXECIO * DISKW SYSIN (FINIS"
"DELSTACK"

/*****************************************************************/
/* CALL IDCAMS                                                   */
/*****************************************************************/

"CALL 'SYS1.LINKLIB(IDCAMS)'"

/*****************************************************************/
/* EXIT                                                          */
/*****************************************************************/

EXIT
