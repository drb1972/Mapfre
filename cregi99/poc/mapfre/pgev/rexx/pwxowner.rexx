/*-----------------------------REXX----------------------------------*\
 * Get the production DB2 owner fro CUSTMAP and MSTRMAP to pass to   *
 * NDVEDIT                                                           *
 *-------------------------------------------------------------------*
 *  Executed by GCUSTMAP & GMSTRMAP                                  *
\*-------------------------------------------------------------------*/
trace n

arg instance

say 'PWXOWNER:'
say 'PWXOWNER: INSTANCE..' instance

c1prgrp = 'XDXXX'instance'XX'
x = db2parms(c1prgrp 'PROD' 'LN1' 'BIND')     /* Call db2parms       */
if x ^= 0 then call exception x 'Call to DB2PARMS failed.'

pull db2_parms
parse value db2_parms with dbsub dbqual dbown dbcoll dbwlm dbracf ,
                         db2inst desc dbiso dbcur dbdeg dbrel dbreo ,
                         dbval dbkdyn dbdynr dblkn prodown dbenc

/* Write out the DB2 owner for NDVEDIT to pick up                    */
queue prodown
"execio * diskw OWNER (finis"
if rc ^= 0 then call exception 20 'DISKW to OWNER failed RC='rc

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg exit_rc comment

 delstack /* Clear down the stack                                    */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit exit_rc
