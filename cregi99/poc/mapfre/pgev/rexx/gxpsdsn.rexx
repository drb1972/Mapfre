/*-----------------------------REXX----------------------------------*\
 *                                                                   *
 * This routine is run by the GXPS processor if the UUJMA instance   *
 * is new. It populates a temporary collection files which will go   *
 * in to EVDEFINE to create the PGOS.BASE version.                   *
 *                                                                   *
\*-------------------------------------------------------------------*/

parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

arg c1element c1ty c1ccid

say rexxname':' Date() Time()
say rexxname':'
say rexxname': c1element.......:' c1element
say rexxname': c1ty............:' c1ty
say rexxname': c1ccid..........:' c1ccid
say rexxname':'

/* initialise variables                                              */
rqdsn = 'TTEV.TMP.'c1ccid'.NSCDEFIN' /* temp request file            */
part2 = 'PO  F,B       80      0    10     3    44 '
part3 = 'ENDEVOR  ENDEVOR  238361 '
part1 = 'PGOS.BASE.'c1ty'.'c1element
ca7   = left(c1ty,3)||right(c1ty,3)
plex  = '' /* initialise to an invalid value                         */
p     = 1 /* counter for the number of destinations                  */

/*  Read and interpret destsys table from PGEV.BASE.DATA             */
call readint 'DESTSYS'

/*  Read and interpret destinfo table from PGEV.BASE.DATA            */
call readint 'DESTINFO'

/* Cater for additional CA7's on a Plex                              */
if wordpos(right(c1ty,3),'P01 P0A P0B') > 0 then plex.p = 'PLEXP1'
                                            else plex.p = plex

/* Bail out if unable to determine the Sysplex                       */
if plex.p = '' then
  call exception 12 'Unable to determine resident Sysplex for' c1ty

/* If DESTSYS has destinations on the C1SYSTEMC card then they must  */
/* be processed                                                      */
clones = words(list_destsc) /* How many clone destinations           */

do c = 1 to clones /*  Process each clone                            */
  target = word(list_destsc,c)
  src    = parent.target /* Establish what the parent plex is called */

  if plex.p = src then do
    p = p + 1 /* increment counter                                   */
    plex.p = target /* set additional destination for clone          */
  end /* plex.p = src */

end /* c = 1 to clones */

/* build up the ndm cards                                            */
queue ' SIGNON'
do d = 1 to p
 call ndm_cards plex.d
end /* d = 1 to p */
queue ' SIGNOFF'

call request_dsn /* write out the temp collection file               */

/* write out the built up C:D cards                                  */
"execio" queued() "diskw NDM (FINIS"
if rc ^= 0 then call exception rc 'DISKW to NDM failed'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Read & interpret input data                                       */
/*-------------------------------------------------------------------*/
readint:

 arg ddname

 "execio * diskr" ddname "(stem record. finis"
 if rc > 0 then call exception rc 'Read of DDname' ddname 'failed'

 do i = 1 to record.0

   if ddname = 'DESTINFO' then do
     if pos(ca7,record.i) > 0 then
       plex = substr(record.i,5,6)
   end /* ddname = 'destinfo' */

   interpret record.i /* make the text in to variables               */
 end /* i = 1 record.0 */

 /* Check to see if there are any overrides in DESTSYS               */
 if ddname = 'DESTSYS' then do
   if C1SYSTEMC.endevor_id = "C1SYSTEMC."endevor_id then
     list_destsc = C1SYSTEMC.DEFAULT
   else
     list_destsc = C1SYSTEMC.endevor_id
 end /* ddname = 'DESTSYS' */

return

/*-------------------------------------------------------------------*/
/* build the evdefine variable and populate the request file         */
/* created and allocated in the processor.                           */
/*-------------------------------------------------------------------*/
request_dsn:
 request.1 = left(part1,45)||part2||part3

 "execio * diskw REQUEST (stem request. finis"
 if rc ^= 0 then call exception rc 'DISKW to REQUEST failed.'

return /* request_dsn: */

/*-------------------------------------------------------------------*/
/* build the ndm cards based on the type definition.                 */
/*-------------------------------------------------------------------*/
ndm_cards:
 arg plex
 dest = cd.plex

 if dest = 'LOCAL' then
    dest = 'CD.OS390.Q102'

 queue " SUBMIT PROC=NDMCOPY SNODE="dest" -"
 queue " MAXDELAY=00:10:00  - "
 queue "           &F1='"rqdsn"' -"
 queue "           &F2='PREV.NSCDEFIN.NVSAM' -"
 queue "           &DISPO='MOD'"

return /* ndm_cards: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 z = msg('off')
 address tso 'delstack'           /* Clear down the stack            */
 z = msg('on')

 if return_code < 12 | return_code > 4095 then return_code = 12

exit return_code
