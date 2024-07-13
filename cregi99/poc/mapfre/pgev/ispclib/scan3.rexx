/*-----------------------------REXX----------------------------------*\
 *  Scan through listings produced by the scanlist utility           *
 *   FUNCTION = LIST scan through C1PRINT output                     *
 *              to produce scan results, summary and SCL             *
 *   FUNCTION = FAID scan through FILEAID output                     *
 *              to produce summary and SCL                           *
\*-------------------------------------------------------------------*/
trace n

arg dsn type selected build_scl function slccid slretdsn slove slrep

say 'SCAN3:' Date() Time()
say 'SCAN3:'
say 'SCAN3: DSN.............:' dsn
say 'SCAN3: TYPE............:' type
say 'SCAN3: SELECTED........:' selected
say 'SCAN3: BUILD SCL.......:' build_scl
say 'SCAN3: FUNCTION........:' function
if slccid   ^= 'SLCCID' then
  say 'SCAN3: SLCCID..........:' slccid
if slretdsn ^= 'SLRETDSN' then
  say 'SCAN3: SLRETDSN........:' slretdsn
if slove    ^= 'SLOVE' then
  say 'SCAN3: SLOVE...........:' slove
if slrep    ^= 'SLREP' then
  say 'SCAN3: SLREP...........:' slrep

"execio * diskr STRING (stem strings. finis"
if rc ^= 0 then call exception rc 'DISKR of STRING failed.'
do i = 1 to strings.0
  say 'SCAN3: String 'i'........:' strip(strings.i)
end /* i = 1 to strings.0 */

say 'SCAN3:'

x = listdsi(C1PRINT file)
say 'SCAN3: --- Extract File Size:' sysused sysunits
say

/* Set up variables                                                 */
stack_size = 500
eof        = 0
started    = 0
header     = 0
ocount     = 0
tot_list   = 0
tot_mhit   = 0
hits       = 0
tot_hits   = 0

/* Print header info                                                 */
ocount     = ocount + 1
out.ocount = 'SCAN3: --- Listing DSN......:' dsn
ocount     = ocount + 1
out.ocount = 'SCAN3: --- Type.............:' type
ocount     = ocount + 1
if function = 'LIST' then do
  do i = 1 to strings.0
    out.ocount = 'SCAN3: --- Scan String 'i'....: "'strip(strings.i)'"'
    ocount     = ocount + 1
  end /* i = 1 to strings.0 */
end /* function = 'LIST' */
out.ocount = ' '

if function = 'LIST' then
  call scanlist /* Loop through listings and search for strings      */
else
  call scanfaid /* Loop through fileaid output to build summary & SCL*/

call summary /* Print summary totals and hit list                    */

if build_scl = 'R' then
  call create_scl /* Create retrieve SCL for listings with hits      */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Scanlist - Loop through the listings and search for strings       */
/*-------------------------------------------------------------------*/
scanlist:

 do forever
   call read_line

   select
     when left(line,24) = ' ----- Start of listing:' then do
       if started then
         call end_member
       tot_list   = tot_list + 1
       mem        = left(word(line,5),10)
       elt        = left(word(line,6),8)
       type       = left(word(line,7),8)
       header     = 1
       ocount     = ocount + 1
       out.ocount = 'SCAN3: --- START SCAN LISTING' mem '---'
       say 'SCAN3: SCANING MEMBER' mem elt type tot_list ,
           'out of' right(selected,3)
     end /* left(line,24) = ' ----- Start .... */
     when header & ^started                                 & ,
          (pos('PL/I FOR MVS & VM',lineu)        > 0          | ,
           pos('IBM VS COBOL II RELEASE',lineu)  > 0          | ,
           pos('IBM COBOL FOR OS/390',lineu)     > 0          | ,
           pos('IBM COBOL FOR MVS',lineu)        > 0          | ,
           pos('IBM OS/VS COBOL',lineu)          > 0          | ,
           pos('COBOL PROCESSOR ',lineu)         > 0          | ,
           pos('IBM ENTERPRISE COBOL',lineu)     > 0          | ,
           pos('CA-EASYTRIEVE',lineu)            > 0          | ,
           pos('CA EASYTRIEVE',lineu)            > 0          | ,
           substr(lineu,2,24)  = 'PL/I OPTIMIZING COMPILER'   | ,
           substr(lineu,48,26) = 'EXTERNAL SYMBOL DICTIONARY' | ,
           substr(lineu,43,20) = 'HIGH LEVEL ASSEMBLER')    then
       started = 1
     when started                                             & ,
          (pos('RELOCATION DICTIONARY',lineu)         > 0 | ,
           pos('GENERAL PURPOSE REGISTER',lineu)      > 0 | ,
           pos('CROSS-REFERENCE OF DATA NAMES',lineu) > 0 | ,
           substr(lineu,2,14) = 'DFSMS/MVS V1 R'          | ,
           substr(lineu,3,14) = 'DFSMS/MVS V1 R'          | ,
           substr(lineu,2,8)  = 'IEW2278I'                | ,
           substr(lineu,2,27) = 'DATA SET UTILITY - GENERATE') then do
       started = 0
       header  = 0
       call end_member
     end /* started & (pos ...... */
     when started then
       do i = 1 to strings.0
         if pos(strip(strings.i),lineu) > 0 then do
           hits       = hits     + 1
           tot_hits   = tot_hits + 1
           ocount     = ocount   + 1
           out.ocount = line
           leave /* Only need to print the line once                 */
         end /* pos(strip(strings.i),lineu) > 0 */
       end /* i = 1 to strings.0 */
     otherwise nop
   end /* select */

   if eof then leave

 end /* do forever */

 if started then
   call end_member /* Print end of listing line and reset totals     */

 "execio" ocount "diskw RESULTS (stem out. finis"
 if rc ^= 0 then call exception rc 'DISKW to RESULTS failed.'

return /* scanlist */

/*-------------------------------------------------------------------*/
/* Scanfaid - Loop through fileaid output to build summary & SCL     */
/*-------------------------------------------------------------------*/
scanfaid:

 do forever
   call read_line

   select
     when left(line,24) = ' ----- Start of listing:' then do
       tot_list   = tot_list + 1
       mem        = left(word(line,5),10)
       elt        = left(word(line,6),8)
       type       = left(word(line,7),8)
       call read_line
       if left(line,6) ^= ' -----' then do
         hits       = hits     + 1
         tot_hits   = tot_hits + 1
         tot_mhit = tot_mhit + 1
         list_hit.tot_mhit = mem elt type
       end /* left(line,6) ^= ' -----' */
     end /* left(line,24) = ' ----- Start .... */
     when left(line,6) ^= ' -----' then do
       hits       = hits     + 1
       tot_hits   = tot_hits + 1
     end /* left(line,6) ^= ' -----' */
     otherwise nop
   end /* select */

   if eof then leave

 end /* do forever */

return /* scanfaid */

/*-------------------------------------------------------------------*/
/* Read_line                                                         */
/*-------------------------------------------------------------------*/
read_line:

 if queued() = 0 then do
   /* N.B. Stack size is used to make the code more efficient        */
   "execio" stack_size "diskr C1PRINT"
   readrc = rc
   if readrc   = 2 & ,        /* EOF */
      queued() = 0 then do
     "execio 0 diskr C1PRINT (finis"    /* close the file            */
     eof = 1
     return
   end /* readrc   = 2 & queued() = 0 */
   if readrc > 2 then call exception readrc 'DISKR of C1PRINT failed'
 end /* queued() = 0 */

 parse pull line
 lineu = line
 upper lineu

 if line = '' then /* If the line is blank                           */
   call read_line

return /* read_line */

/*-------------------------------------------------------------------*/
/* End of member processing                                          */
/*-------------------------------------------------------------------*/
end_member:

 ocount     = ocount + 1
 out.ocount = 'SCAN3: --- END   SCAN LISTING' mem '---' hits 'hits'
 ocount     = ocount + 1
 out.ocount = ' '
 if hits > 0 then do
   tot_mhit = tot_mhit + 1
   list_hit.tot_mhit = mem elt type
   hits     = 0
 end /* hits > 0 */

return /* end_member */

/*-------------------------------------------------------------------*/
/* Summary - print summary stats and hit list                        */
/*-------------------------------------------------------------------*/
summary:

 queue 'SCAN3:'
 queue 'SCAN3: Listing DSN......:' dsn
 queue 'SCAN3: Type.............:' type
 do i = 1 to strings.0
  queue 'SCAN3: Search String 'i'..:' strip(strings.i)
 end /* i = 1 to strings.0 */
 queue 'SCAN3:'
 queue 'SCAN3: Total line hits' tot_hits
 queue 'SCAN3: Total listings with hits' tot_mhit
 queue 'SCAN3: Total listings searched ' tot_list
 queue 'SCAN3:'
 queue 'SCAN3: Listings with hits...'
 queue 'SCAN3:        LISTING    ELEMENT  TYPE'
 queue 'SCAN3:        -------    -------  ----'

 do i = 1 to tot_mhit
   queue 'SCAN3:  ' right(i,4) list_hit.i
 end /* i = 1 to tot_mhit */

 if tot_list ^= selected then do
   queue 'SCAN3: Total listings selected ' selected
   queue 'SCAN3: Searched ^= Selected please call' ,
                'Endevor Support'
   "execio * diskw SUMMARY (finis"
   if rc ^= 0 then call exception rc 'DISKW to SUMMARY failed.'
   exit 12
 end /* tot_list ^= selected */

 "execio * diskw SUMMARY (finis"
 if rc ^= 0 then call exception rc 'DISKW to SUMMARY failed.'

return /* summary */

/*-------------------------------------------------------------------*/
/* Create SCL                                                        */
/*-------------------------------------------------------------------*/
create_scl:

 stage = substr(dsn,6,1)
 sys   = substr(dsn,7,2)
 select
   when pos(stage,'TU') > 0 then envr = 'UTIL'
   when pos(stage,'AB') > 0 then envr = 'UNIT'
   when pos(stage,'CD') > 0 then envr = 'SYST'
   when pos(stage,'EF') > 0 then envr = 'ACPT'
   when pos(stage,'OP') > 0 then envr = 'PROD'
   when pos(stage,'YZ') > 0 then envr = 'ARCH'
   otherwise call exception 12 'STAGE invalid:' stage
 end /* select */
 queue '* IF YOU ARE IN VIEW OR EDIT MODE YOU CAN TYPE SCL ON THE     '
 queue '* COMMAND LINE TO SUBMIT THIS SCL.                            '
 queue "* USE THE SE LINE COMMAND IN SDSF TO EDIT THIS SCL DD.        "
 queue "                                                              "
 queue " SET OPTIONS CCID '"slccid"'                                  "
 queue "             COMMENT '#' .                                    "
 if slrep = 'Y' then
   queue " SET OPTIONS REPLACE MEMBER .                               "
 if slove = 'Y' then
   queue " SET OPTIONS OVERRIDE SIGNOUT .                             "
 queue ' SET FROM ENVIRONMENT' envr 'SYSTEM' sys 'STAGE' stage '.'
 queue " SET TO DSNAME '"slretdsn"' ."
 queue '*                                                             '
 do i = 1 to tot_mhit
   subsys  = sys || right(word(list_hit.i,1),1)
   element = left(word(list_hit.i,2),10)
   type    = word(list_hit.i,3)
   queue ' RETRIEVE ELEMENT' element 'FROM SUBSYSTEM' subsys ,
         'TYPE' type '.'
 end /* i = 1 to tot_mhit */

 "execio * diskw SCL (finis"
 if rc ^= 0 then call exception rc 'DISKW to SCL failed.'

return /* create_scl */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 address tso delstack /* Clear down the stack                        */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
