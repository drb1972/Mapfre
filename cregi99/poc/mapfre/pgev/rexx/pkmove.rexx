/*-----------------------------REXX----------------------------------*\
 *  Build MOVE SCL from CSV output for automatic package build.      *
 *  Executed in skelton PKBUILD.                                     *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

arg sys stg1 stg2 ccid

say rexxname':' Date() Time()
say rexxname':'
say rexxname': Sys.............:' sys
say rexxname': Stg1............:' stg1
say rexxname': Stg2............:' stg2
say rexxname': Ccid............:' ccid
say rexxname':'

exit_rc = 0

/* Read the list of elements by CCID                                 */
"execio * diskr CSV (stem csv. finis"
if rc ^= 0 then call exception rc 'DISKR of CSV failed'

if csv.0 = 0 then
  call readme
else
  call build_scl

exit exit_rc

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Readme - Write out readme to say no elements found                */
/*-------------------------------------------------------------------*/
readme:

 queue ' '
 queue ' No elements selected from stages' stg1 'or' stg2
 queue ' for CCID' ccid 'in system' sys'.'

 "execio" queued() "diskw README (finis"
 if rc ^= 0 then call exception rc 'DISKW to README failed'

 exit_rc = 4

return /* readme: */

/*-------------------------------------------------------------------*/
/* Build_scl - Build MOVE SCL statements                             */
/*-------------------------------------------------------------------*/
build_scl:

 do i = 1 to csv.0
   if substr(csv.i,13,1) = 'M' then do /* Element master record     */
     envr = substr(csv.i,15,4)
     sys  = substr(csv.i,23,2)
     subs = substr(csv.i,31,3)
     type = substr(csv.i,49,8)
     stg  = substr(csv.i,65,1)
     elt  = strip(substr(csv.i,1055,65))
     say rexxname':' type subs stg elt
     queue "MOVE ELEMENT '"elt"'"
     queue '  FROM ENVIRONMENT' envr 'SYSTEM' sys 'SUBSYSTEM' subs
     queue '    TYPE' type 'STAGE' stg
     queue '  OPTIONS CCID' ccid ' COMMENTS "#"'
     queue ' .'
   end /* substr(csv.0,15,4) = 'M' */
 end /* i = 1 to csv.0 */

 actions = queued() / 5
 say rexxname':'
 say rexxname':' actions 'MOVE statements built'

 "execio" queued() "diskw SCL (finis"
 if rc ^= 0 then call exception rc 'DISKW to SCL failed'

return /* build_scl */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code
