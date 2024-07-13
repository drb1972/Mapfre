/*-----------------------------REXX----------------------------------*\
 * Validate the custmap element name                                 *
\*-------------------------------------------------------------------*/

/* ------------------------------------------------------------------*\
 * Parse the 6 character element name into the following...          *
 *                                                                   *
 * Position 1 Environment e.g 'N - Nplex'                            *
 * Position 2 DB2 Datasharing group                                  *
 * Position 3 Application ID e.g. A1                                 *
 * Position 5 Policy Type - Motor, Home or Client                    *
 * Position 6 Instance e.g. Z for DLI or Y for Churchill             *
 * Position 7 Not used                                               *
 * Position 8 Not used                                               *
\*-------------------------------------------------------------------*/
trace n

arg c1element brandnum
parse value c1element with 1 envir  2 ssid 3 appid 5 epol ,
                           6 inst 7 pos7_8

say 'DB2PROC:'
say 'DB2PROC:  C1ELEMENT.' c1element
say 'DB2PROC:  ENVIR.....' envir
say 'DB2PROC:  SSID......' ssid
say 'DB2PROC:  APPID.....' appid
say 'DB2PROC:  EPOL......' epol
say 'DB2PROC:  INST......' inst

exit_rc = 0

/*  Call DB2PARMS to check characters 2,6&7 - DB2 ssid & instance    */
c1prgrp = 'X'ssid'XXX'inst'XX'
x = db2parms(c1prgrp 'PROD' 'LN1' 'BIND')     /* Call db2parms       */

/* Dont need results from DB2PARMS so clear stack                    */
delstack

if x ^= 0 then do /* DB2PARMS call failed                            */
  queue 'PXMEMCHK: An invalid SSID or INSTANCE has been coded for'
  queue 'PXMEMCHK: element' c1element 'in position 2 or 6.'
  queue 'PXMEMCHK: You should only be coding valid ssid & Instances'
  queue ' '
  exit_rc = 8
end /* x ^= 0 */

/* Position 1 envir check                                            */
if pos(envir,'N') = 0 then do
  queue 'PXMEMCHK: Invalid Environment for element' c1element 'in'
  queue 'PXMEMCHK: position 1 of the element name, you should be coding'
  queue 'PXMEMCHK: an N'
  queue ' '
  exit_rc = 8
end /* pos(envir,'N') = 0 */

/* Position 3 appid check                                            */
if pos(appid,'A1') = 0 then do
  queue 'PXMEMCHK: Invalid Application ID for element' c1element 'in'
  queue 'PXMEMCHK: position 3 of the element name, you should be coding'
  queue 'PXMEMCHK: an A1'
  queue ' '
  exit_rc = 8
end /* pos(appid,'A1') = 0 */

/* Position 5 epol check                                             */
if pos(epol,'ACDEHKMOV') = 0 then do
  queue 'PXMEMCHK: Invalid Policy Type coded for element' c1element 'in'
  queue 'PXMEMCHK: position 5 of the element name you should be coding'
  queue 'PXMEMCHK: one of the following letters ACDEHKMOV'
  queue ' '
  exit_rc = 8
end /* pos(epol,'ACDEHKMOV') = 0 */

/* Position 7 and 8 unused check                                     */
if pos7_8 ^= '' then do
  queue 'PXMEMCHK: Characters 7 and 8 of the element should be blank'
  queue 'PXMEMCHK: Element' c1element
  queue ' '
  exit_rc = 8
end /* pos78 ^= '  ' */

/* Brandnum check - Brandnum is set in the processor GCUSTMAP and    */
/* depends on the DB2 instance.                                      */
if left(brandnum,1) = '&' then do
  queue 'PXMEMCHK: The Brand Number for instance' inst
  queue 'PXMEMCHK: has not been set up in Endevor. Please contact'
  queue 'PXMEMCHK: Endevor support to update GCUSTMAP'
  queue ' '
  exit_rc = 8
end /* pos(brandnum,'12') = 0 */

if exit_rc = 8 then do
  "execio" queued() "diskw README (finis"
  if rc ^= 0 then call exception 20 'DISKW to README failed RC='rc
end /* exit_rc = 8 */
else
  say 'PXMEMCHK: Completed Successfully RC = 0'

exit exit_rc

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
