/*-----------------------------REXX----------------------------------*\
 *  This runs and build an output dataset name based on last month,  *
 *  if alloc fails then rexx deletes last years copy and then        *
 *  reallocates.                                                     *
\*-------------------------------------------------------------------*/
trace n

/* read in variable of dsn prefix and jobname.                       */
arg prefix jobname .

/* IF VARIABLE NOT PROVIDED THEN SET DEFAULTS.                       */
if prefix='' then prefix='PREV'
if jobname='' then jobname='JOBNAME'

/* build previous month name as job runs on the first.               */
month=substr(date(m),1,3)
upper month
if      month      = 'JAN' then month = 'L----DEC'
else if month = 'FEB' then month = 'A----JAN'
else if month = 'MAR' then month = 'B----FEB'
else if month = 'APR' then month = 'C----MAR'
else if month = 'MAY' then month = 'D----APR'
else if month = 'JUN' then month = 'E----MAY'
else if month = 'JUL' then month = 'F----JUN'
else if month = 'AUG' then month = 'G----JUL'
else if month = 'SEP' then month = 'H----AUG'
else if month = 'OCT' then month = 'I----SEP'
else if month = 'NOV' then month = 'J----OCT'
else if month = 'DEC' then month = 'K----NOV'

/* build the dataset name we want to create.                         */
thedsn = prefix'.NENDEVOR.'jobname'.PACKAGE.'month

/* if dataset does exist then delete                                 */
if sysdsn("'"thedsn"'") = 'OK' then do
  "delete '"thedsn"'"
  if rc ^= 0 then call exception rc 'Delete of' thedsn 'failed.'
end /* sysdsn("'"thedsn"'") = 'OK' */

/* dyanmically allocate filename.                                    */
say 'EVHPCK3M:'
say 'EVHPCK3M: Allocating file:-'
say 'EVHPCK3M:' thedsn
say 'EVHPCK3M:'

"ALLOC F(OUTDD) DA('"thedsn"') NEW CATALOG" ,
"SPACE(1500,300) TRACKS LRECL(133) RECFM(F B) RELEASE"
if rc ^= 0 then call exception rc 'Alloc of' thedsn 'failed.'

/* queue repro command to copy report to dynamically alloc file      */
queue "   REPRO INFILE(INDD) OUTFILE(OUTDD)        ";
queue "                                            ";
"EXECIO * DISKW SYSIN (FINIS"
if rc ^= 0 then call exception rc 'DISKW of DDname SYSIN failed.'
"delstack"

/* call idcams                                                       */
"CALL 'SYS1.LINKLIB(IDCAMS)'"

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment 'RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code
