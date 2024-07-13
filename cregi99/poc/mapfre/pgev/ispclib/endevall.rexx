/*------------------------------ REXX -------------------------------*\
 * ENDEVALL  This rexx drives the panel front-end to allow a user    *
 * to specify analysis of the elements in a system at various stages *
 * identifying duplicates and elements without a current Infoman     *
 * Change Management Record.  It creates a job which runs to create  *
 * a CSV file which is sent to the user's email address              *
 *                                                                   *
 * Invoked from the Endevor User Menu option 12 (NDVRUSER)           *
 *                                                                   *
\*-------------------------------------------------------------------*/
trace n

panelrc = 1
evpref1 = 'PGEV.BASE'
evpref2 = 'PGEV.BASE'

plex = MVSVAR(sysplex) /* Which plex are we on                       */
if plex ^= 'PLEXQ1' then schenv = ''
                    else schenv = ',SCHENV=QGEN'

/* determine whether override LIBDEF libraries are in                */
/* use, and if so, set the EV prefix1 accordingly                    */
address ispexec 'qlibdef ispplib id(idv)'
if rc > 4 then call exception rc 'QLIBDEF for ISPPLIB failed'

override_pos = pos('EV1',idv)

if override_pos > 0 then do
  evpref1 = 'PREV.'substr(idv,override_pos-1,4)
  parse source . . rexxname .
  say rexxname': WARNING! LIBDEF Overrides in Effect'
  say rexxname': Evpref1 set to' evpref1
end /* override_pos > 0 */

/* main processing                                                   */
do while panelrc > 0
  address ispexec 'display panel(endevall)'
  if rc = 08 | pfk = pf03 | pfk = pf04 then exit
  panelrc = rc
  select
    when unit||syst||acpt||prod = 'NNNN' then do
      panelrc = 4
      zedsmsg = 'Error'
      zedlmsg = 'You must select at least one Environment'
      err     = 'Error - you must select at least one Environment'
      address ispexec 'setmsg msg(ende006e)'
    end /* unit||syst||acpt||prod = 'NNNN' */
    when pos('*',c1sys) >= 1 then do
      panelrc = 4
      zedsmsg = 'Error'
      zedlmsg = 'You cannot wildcard system'
      err     = 'Error - please select a valid system'
      address ispexec 'setmsg msg(ende001e)'
    end /* pos('*',c1sys) >= 1 */
    when substr(c1sub,1,2) ^= c1sys & substr(c1sub,1,2) ^= '* ' then do
      panelrc = 4
      zedsmsg = 'Error'
      zedlmsg = 'Subsystem must match the system or be *'
      err     = 'Error - please correct the subsystem'
      address ispexec 'setmsg msg(ende002e)'
    end /* substr(c1sub,1,2) ^= c1sys | substr(c1sub,1,2) ^= '* ' */
    otherwise nop /* do nothing */
  end /* select */
end /* while panelrc > 0 */

address ispexec 'vget (zuser zprefix)'
if rc > 4 then call exception rc 'VGET for ZUSER ZPREFIX failed'
c1sysuid = zuser
c1pref   = zprefix
c1jb     = substr(c1sysuid,1,4)
say 'Summary spreadsheet for system' c1sys 'will be sent to' c1email

address ispexec 'ftopen temp'
address ispexec 'ftincl' endevall
if rc > 0 then call exception rc 'FTINCL of ENDEVALL failed'

address ispexec 'ftclose'
if rc > 0 then call exception rc 'FTCLOSE failed'

address ispexec 'vget (ztempf) shared'
address tso     "submit '"ztempf"'"

exit

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
   address ispexec "FTCLOSE" /* Close any FTOPENed files             */
   address tso 'delstack'    /* Clear down the stack                 */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code
