/*--------------------------REXX------------------------------------*\
 * Simple rexx it just builds an SCL statement with a date and time *
 * 48 hours less than the current time.                             *
 * The card we build looks like this " DATE=04/23/98 TIME=12:00 ."  *
 * Its used for clearing down elements from stage O.                *
 *------------------------------------------------------------------*
 *  Executed by : PROC EVHEMERD and JOB EVHEMERD                    *
\*------------------------------------------------------------------*/
trace n

/* Convert todays date to date(B) format              */
newd = date('B',date(s),'S')

/* xdays is the number of days to subtract from today */
/* Keep the elements longer on a Sunday & Monday      */
select
  when date(W) = 'Sunday' then xdays = 3
  when date(W) = 'Monday' then xdays = 4
  otherwise                    xdays = 2
end

newd = newd - xdays

/* Convert back to date(S) format                     */
newd = date('S',newd,'B')

/* Create date SCL statement with new date            */
newd = ' DATE='substr(newd,5,2)'/'substr(newd,7,2)'/'substr(newd,3,2)

/* Define the time parameter                          */
newt = 'TIME='substr(time(),1,5)' .'

/* Write statement for use in next step in EVHEMERD   */

queue newd newt
queue ' '
queue ' LIST ELEMENT * .'

"execio" queued() "diskw DATETO (finis)"
if rc ^= 0 then call exception 20 'DISKW to DATETO failed RC='rc

exit

/*---------------------- S U B R O U T I N E S -----------------------*/

/*---------------------------------------------------------------*/
/* Error with line number displayed                              */
/*---------------------------------------------------------------*/
exception:
 parse arg return_code comment

 /* Clear down the stack */
 do i = 1 to queued()
   pull
 end

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
