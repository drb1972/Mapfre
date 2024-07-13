/*--------------------------REXX---------------------------------*\
 *  Read a report of active INFOMAN CMRs.                        *
 *  Read a report of OS elements in ACPT.                        *
 *  Report on all redundant elements and email the perpetrators. *
 *---------------------------------------------------------------*
 *  Author:     Emlyn Williams                                   *
 *              Endevor Support                                  *
 *  Executed by : PROC EVHWIZEW and JOB EVHWIZQW                 *
\*---------------------------------------------------------------*/
trace n

/* Read the active CMR report */
"execio * diskr INFOMAN (stem inf.  finis" /* CMR list        */
if rc ^= 0 then
  call exception 20 'Execio diskr from INFOMAN failed RC =' rc
/* Read the element list (ACPT only) */
"execio * diskr ELTS    (stem elts. finis" /* OS elts in ACPT */
if rc ^= 0 then
  call exception 20 'Execio diskr from ELTS failed RC =' rc

user_count = 0   /* number of users with redundant elements */
exit_rc    = 0

/* Analyse CMR list */
do x = 1 to inf.0
  ccid = substr(inf.x,222,8)
  cmr.ccid = 'Y'
end /* x = 1 to inf.0 */

/* Analyse elements */
do i = 1 to elts.0
  elt  = substr(elts.i,39,8)
  typ  = substr(elts.i,49,8)
  stg  = substr(elts.i,57,1)
  user = substr(elts.i,148,8)
  ccid = substr(elts.i,156,8)
  if cmr.ccid ^= 'Y' then do
    if userlist.user ^= user then do
      userlist.user   = user
      user_count      = user_count + 1
      user.user_count = user
    end /* userlist.user ^= user */
    queue ' 'user elt typ left(stg,5) ccid
  end /* cmr.ccid ^= 'Y' */
end /* i = 1 to elts.0 */

if user_count > 0 then do        /* Redundant elements found */
  exit_rc = 1
  'execio * diskw EDATA (finis'  /* Write out element list     */
  if rc ^= 0 then
    call exception 20 'Execio diskw to EDATA failed RC =' rc

  queue '  FROM: mapfre.endevor@rsmpartners.com'
  queue '  TO: VERTIZOS@kyndryl.com'

  do i = 1 to user_count
    queue '  TO:  ' strip(user.i)'@mapfre.com'
  end

  queue '  SUBJECT: EPLEX - EVHWIZQW - Redundant Endevor elements'

  'execio * diskw EADDR (finis'  /* Write out address details */
  if rc ^= 0 then
    call exception 20 'Execio diskw to EADDR failed RC =' rc

end /* user_count > 0 */

exit exit_rc

/*---------------------- S U B R O U T I N E S -----------------------*/

/*---------------------------------------------------------------*/
/* Error with line number displayed                              */
/*---------------------------------------------------------------*/
exception:
 parse arg return_code comment

 /* Clear down the stack                                             */
 do i = 1 to queued()
   pull
 end /* do i = 1 to queued()                                         */

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
