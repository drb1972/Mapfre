/*-----------------------------REXX----------------------------------*\
 *  This REXX is used by processors that delete processor outputs    *
 *  based on member footprint element names                          *
 *  E.g. GEAR, MEAR, DEAR to delete/copy DBRMs                       *
 *       WSDL for copybooks                                          *
 *       EARL for other outputs                                      *
 *       DCOMMON for common outputs                                  *
 *  It accepts output from a footprint report.                       *
\*-------------------------------------------------------------------*/
signal on syntax  name exception /* Required for ISPF batch only     */
signal on failure name exception /* Required for ISPF batch only     */
trace n

arg c1element c1su c1ty c1si c1action

c1sy = left(c1su,2)

/* Read in the report output                                         */
"execio * diskr BSTRPTS (stem line. finis)"
if rc ^= 0 then call exception 12 'DISKR from BSTRPTS failed RC='rc

/* Write out the report output for debugging                         */
"execio" line.0 "diskw FOOTRPT (stem line. finis)"
if rc ^= 0 then call exception 12 'DISKW to FOOTRPT failed RC='rc

do a = 1 to line.0
  /* Get the dataset name                                            */
  if word(line.a,1) = 'LIBRARY:' then do
    dsn = word(line.a,2)
    leave
  end /* word(line.a,1) = 'LIBRARY:' */
end /* a = 1 to line.0 */

say 'POPDEL:  Deleting members from dataset' dsn
say 'POPDEL:'

call Get_members

if fail = 'Y' then do /* Member found with different subsystem       */
  "execio * diskw README (finis)"
  if rc ^= 0 then call exception 12 'DISKW to README failed RC='rc
  zispfrc = 12
  address ispexec "VPUT (ZISPFRC) SHARED"
  exit 12
end /* fail = 'Y' */

if mem_count > 0 then
  call Delete_members
else do
  say 'POPDEL: No members found to delete for element' c1element
  zispfrc = 4
  address ispexec "VPUT (ZISPFRC) SHARED"
end /* else */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Get_ members - Get members from the footprint report              */
/*-------------------------------------------------------------------*/
Get_members:

 mem_count = 0

 do a = 1 to line.0

   member  = strip(substr(line.a,2,8))
   footsy  =       substr(line.a,33,2)
   footsu  =       substr(line.a,43,3)
   footele = strip(substr(line.a,53,8))
   footty  = strip(substr(line.a,65,8))

   /* Build a list of members to be deleted                          */

   /* 1st check for unfootprinted members                            */
   if member  = c1element  & ,
      footele = '        ' then do
     mem_count     = mem_count + 1
     mem.mem_count = member
   end /* member  = c1element & ... */
   else
     /* Or if the element MCF info matches the member footprint      */
     if footele = c1element & ,
        footty  = c1ty      & ,
        member  ^= '        ' then /* member ^= ' ' for load libs    */
       if (c1si    = 'P' & ,
           footsy  = c1sy) | ,
          (c1si   ^= 'P' & ,
           footsu  = c1su) then do
         mem_count     = mem_count + 1
         mem.mem_count = member
       end /* footele = c1element & ... */
       else
         if c1action       ^= 'DELETE' & ,
            c1si           ^= 'P'      & ,
            substr(dsn,7,2) = 'RG'     then do
           say 'POPDEL: Member with non matching footprint found.' ,
               'See README.'
           say line.a
           /* Work out the element name from the footprint           */
           if footele ^= member then
             call elt_info footele footsu footty substr(dsn,6,1)
           else
             elt_name = footele
           /* Write out the readme message                           */
           queue 'POPDEL: A common member called' member ,
                 'already exists in' dsn
           queue 'POPDEL: and has come from subsystem' footsu ,
                 'element' elt_name
           queue 'POPDEL: Your' c1action 'has been failed so that the' ,
                 'member is not overwritten.'
           queue 'POPDEL: You must either move or delete the element' ,
                 'from' footsu
           queue 'POPDEL: then' c1action 'this element in subsystem' ,
                 c1su 'again.'
           queue ' '
           fail = 'Y'
         end /* c1action ^= 'DELETE' & ... */

 end /* a = 1 to line.0 */

return /* Get_members: */

/*-------------------------------------------------------------------*/
/* Delete_members - Delete the member(s) with LM                     */
/*-------------------------------------------------------------------*/
Delete_members:

 address ispexec
 "LMINIT DATAID(dataid) DATASET('"dsn"') ENQ(SHRW)"
 "LMOPEN DATAID("dataid") OPTION(OUTPUT)"

 do i = 1 to mem_count
   say 'POPDEL:  Deleting' mem.i 'from' dsn
   "LMMDEL DATAID("dataid") MEMBER("mem.i")"
   say 'POPDEL:  RC =' rc
   if rc > 8 then call exception 12 'Delete of member' mem.i 'failed.'
 end /* i = 1 to mem_count */

 "LMCLOSE DATAID("dataid")"
 "LMFREE DATAID("dataid")"

return /* Delete_members: */

/*-------------------------------------------------------------------*/
/* Elt_info - Get element MCF information with the CSV utility.      */
/*-------------------------------------------------------------------*/
elt_info:
 arg csv_elt csv_sub csv_typ csv_stg

 select
   when pos(csv_stg,'TU') > 0 then csv_env = 'UTIL'
   when pos(csv_stg,'AB') > 0 then csv_env = 'UNIT'
   when pos(csv_stg,'CD') > 0 then csv_env = 'SYST'
   when pos(csv_stg,'EF') > 0 then csv_env = 'ACPT'
   when pos(csv_stg,'OP') > 0 then csv_env = 'PROD'
   otherwise nop
 end /* select */

 address tso
 /* Free incase there are hangovers. Do not code an exception call */
 test = msg(off)
 "free f(bsterr c1msgsa csvmsgs1 csvfile csvipt01)"
 test = msg(on)

 "alloc f(csvipt01) new space(1 1) tracks recfm(f b) lrecl(80)"
 if rc ^= 0 then call exception rc 'ALLOC of csvipt01 failed.'

 /* Build the input to the CSV utiltiy                               */
 inp.1 = '  LIST ELEMENT *'
 inp.2 = '    FROM ENV' csv_env 'SYS' left(csv_sub,2) 'SUB' csv_sub
 inp.3 = '         TYP' csv_typ 'STA' csv_stg
 inp.4 = '    TO DDN CSVFILE'
 inp.5 = '    OPTIONS NOSEARCH NOCSV .'
 'execio 5 diskw csvipt01 (stem inp. finis)'
 if rc ^= 0 then call exception rc 'DISKW to csvipt01 failed.'

 /* Allocate files to process SCL                                    */
 "alloc f(CSVFILE) new space(1 1) tracks recfm(f b) lrecl(1600)"
 if rc ^= 0 then call exception rc 'ALLOC of CSVFILE failed.'

 /* Allocate the necessary datasets                                  */
 test = msg(off)
 "ALLOC F(C1MSGSA) SYSOUT(*)"
 if rc ^= 0 then call exception rc 'ALLOC of C1MSGSA failed.'
 "alloc f(CSVMSGS1) new space(1 1) tracks recfm(f b a) lrecl(134)"
 if rc ^= 0 then call exception rc 'ALLOC of CSVMSGS1 failed.'
 "ALLOC F(BSTERR) SYSOUT(*)"
 if rc ^= 0 then call exception rc 'ALLOC of BSTERR failed.'
 test = msg(on)

 /* Invoke the CSV utility                                           */
 address "LINKMVS" 'BC1PCSV0'
 lnk_rc = rc

 if lnk_rc > 4 then do
   "execio * diskr csvmsgs1 (stem c1. finis"
   do i = 1 to c1.0
     say c1.i
   end /* i = 1 to c1.0 */
   call exception lnk_rc 'Call to BC1PCSV0 failed'
 end /* rc > 0 */

 "free f(bsterr c1msgsa csvmsgs1 csvipt01)"

 elt_name = 'UNKNOWN('footele')'
 g = listdsi(csvfile file) /* Check for output                     */
 if g = 0 then do
   "execio 1 diskr CSVFILE (stem elt. finis"
   "free f(csvfile)"
   do ii = 1 to elt.0
     if substr(elt.1,39,8) = footele then
       elt_name = substr(elt.1,1055,50)
   end /* ii = 1 to elt.0 */
 end /* g = 0 */

return /* elt_info: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 /* This if is for ISPF in batch only                                */
 if wordpos(condition('C'),'SYNTAX FAILURE') > 0 then do
   say 'Line' sigl':' left(sourceline(sigl),70)
   say 'Errortext:' errortext(rc)
   return_code = rc
   comment     = condition('C') 'failure at line' sigl
 end /* wordpos(condition('C'),'SYNTAX FAILURE') > 0 */

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

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code
