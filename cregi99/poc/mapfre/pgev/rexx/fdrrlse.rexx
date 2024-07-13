/*-----------------------------REXX----------------------------------*\
 * This Rexx is used to build FDR release data cards to              *
 * release tracks in shipment datasets.                              *
 *                                                                   *
 * Executed in job EVGFDRRD proc EV#FDRRD                            *
\*-------------------------------------------------------------------*/
trace n

arg days

plex = substr(MVSVAR(sysplex),5,1)
select
  when plex = 'M' then
    storgrp = '(ONLINE)'
  when plex = 'N' then
    storgrp = '(PRIMARY,ONLINE,ONLINE1)'
  when plex = 'P' then
    storgrp = '(PRIMARY,ONLCICS)'
  when plex = 'E' then
    storgrp = 'PRIMARY1'
  otherwise /*  This is the default for new plexes                   */
    storgrp = '(PRIMARY,ONLINE)'
end /* select */

say 'FDRRLSE: Building FDR data cards to compact yesterdays shipment' ,
    'datasets'
say 'FDRRLSE: Days.....:' days
say 'FDRRLSE: Today....:' right(date('S'),6)

yesterday = right(date('S',date('B')-days,'B'),6)
say 'FDRRLSE: Yesterday:' yesterday
say 'FDRRLSE:'

line.0 = 4
line.1 = ' CPK TYPE=RLSE,STORGRP='storgrp','
line.2 = '   DSNENQ=USE,UNABLE=IGNORE'
line.3 = ' SELECT DSN=PGEV.SHIP.D'yesterday'.**,'
line.4 = '   DSORG=(PS,PO,EF),RLSE=TRK'

do i = 1 to line.0
  say 'FDRRLSE:' line.i
end /* do i = 1 to line.0 */

"execio" line.0 "diskw FDRCARDS (stem line. finis"
if rc ^= 0 then call exception 12 'DISKW to FDRCARDS failed. RC='rc

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 address tso 'delstack' /* Clear down the stack                      */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
