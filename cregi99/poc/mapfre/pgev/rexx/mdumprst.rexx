/*-----------------------------REXX----------------------------------*\
 *  Used by MDUMPRST when moving to stage P to build the restore &   *
 *  backout lists in PREV.PEV1.DUMPDATA                              *
\*-------------------------------------------------------------------*/
trace n

arg c1ccid

actions. = '' /* set array to null                                   */

/* Get the the contents of the promoted member                       */
'execio * diskr SOURCE (stem source. finis'
if rc ^= 0 then call exception rc 'DISKR of DDname SOURCE failed.'

/* Get the the contents of the DESTINFO member                       */
'execio * diskr DESTINFO (stem destinfo. finis'
if rc ^= 0 then call exception rc 'DISKR of DDname DESTINFO failed.'

do a = 1 to destinfo.0
  interpret destinfo.a /* make the text in to variables              */
end /* a = 1 destinfo.0 */

/* Get the the contents of the DESTSYS member                        */
'execio * diskr DESTSYS (stem destsys. finis'
if rc ^= 0 then call exception rc 'DISKR of DDname DESTSYS failed.'

do b = 1 to destsys.0
  interpret destsys.b /* make the text in to variables               */
end /* b = 1 destsys.0 */

/* be prepared for any system specific overrides                     */
if C1SYSTEMB.EV = "C1SYSTEMB.EV" then
  list_destsb = C1SYSTEMB.DEFAULT
else
  list_destsb = C1SYSTEMB.EV

/* start queueing the C:D commands                                   */
queue ' SIGNON'

/* loop through the element source                                   */
do c = 1 to source.0
  dsn.c = strip(word(source.c,1)) /* dataset for processing          */

  /* this loop processes the destination(s) for the dataset          */
  do d = 2 to words(source.c)
    plex = word(source.c,d) /* get the target plex                   */
    actions.plex = actions.plex dsn.c /* build up an array           */
  end /* b = 2 to words(source.c) */
end /* do c = 1 to source.0 */

/* loop through the valid destinations to see if there are targets   */
do e = 1 to words(list_destsb)
  tdst = word(list_destsb,e) /* get the individual destination       */
  if length(actions.tdst) > 0 then call auto_data tdst
end /* e = 1 to words(list_destsb) */

/* start queueing the C:D commands                                   */
queue ' SIGNOFF'

"execio" queued() "diskw DMBATCH (finis"
if rc ^= 0 then call exception rc 'DISKW to DDname DMBATCH failed.'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Write to PREV.PEV1.DUMPDATA                                       */
/*-------------------------------------------------------------------*/
auto_data:
 arg tdst

 dfdss.   = '' /* initialise the dfdss array                          */
 senddsn  = 'PREV.PEV1.DUMPDATA'
 autodsn  = 'PGEV.AUTO.DATA'
 node     = cd.tdst
 auto     = 0 /* initialise counter for dump datasets                 */
 automem  = right(tdst,2)||right(c1ccid,6)
 senddata = senddsn'('automem')'

 /* Allocate the PGEV.AUTO.DATA dsn for writing later                */
 "alloc f(AUTODATA) dsname('"senddata"') shr"
 if rc ^= 0 then call exception rc 'ALLOC of' senddata 'failed.'

 /* build the dataset statements                                     */
 do d = 1 to words(actions.tdst)
   auto = auto + 1 /* increment array counter                        */
   dfdss.auto = '    ' word(actions.tdst,d) '-'
 end /* d = 1 to words(actions.dest) */

 dfdss.0 = auto /* set the array max value                           */

 /* write out the result set                                         */
 'execio' dfdss.0 'diskw autodata (stem dfdss. finis'
 if rc ^= 0 then call exception rc 'DISKW to AUTODATA failed'

 "free f(autodata)" /* release the allocation                        */

 /* don't do a file transfer if this is for Qplex                    */
 if node = local then return

 queue ' SUBMIT PROC=NDMCOPY SNODE='node' -'
 queue ' MAXDELAY=00:10:00  - '
 queue '           &F1="'senddata'" -'
 queue '           &F2="'autodsn'" -'
 queue '           &DISPI="SHR" - '
 queue '           &DISPO="SHR"    '

return /* auto_data: */

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
