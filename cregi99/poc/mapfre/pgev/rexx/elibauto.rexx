/*------------------------------ REXX -------------------------------*\
 * ELIBAUTO - Analyse the ELIB details and build a job to allocate   *
 * new elibs with new space/page size/directory pages etc as req'd,  *
 * copy the old one across and rename them both.                     *
 *                                                                   *
 * See page 31 onwards in the Utilities Guide manual for all details *
 * about elibs.                                                      *
\*-------------------------------------------------------------------*/
trace n

Arg prefix auto /* run jobs now & work file hlq                      */

sysuid  = sysvar(sysuid) /* userid of job submitter                  */

/* set userid the job will run under                                 */
if prefix = 'PGEV' then do
  user  = 'HKPGEND'
  class = 'N'
  jpfx  = 'EVGE'
  mcls  = 'Y'
end /* if prefix = 'PGEV' then do                                    */
else do
  user  = sysuid
  class = '3'
  jpfx  = 'TTEV'
  mcls  = '0'
end /* else do                                                       */

/* initialise variables                                              */
maxpage = 0 /* largest member size                                   */
reserve = 0 /* reserve limit                                         */

/* Set the dataset suffix for the rename after a successful copy     */
dsnsuff = 'SMGEV'right(date(j),3)

/* Set the return code in the ISPF return code variable to 12 in     */
/* case any of the maths fail.                                       */
zispfrc = 12
address ispexec "VPUT (ZISPFRC) SHARED"

call stage_dsn /* Get details of the dataset we are re-organising    */

parse var dsn hlq '.' mlq '.' llq /* Break the dsn into qualifiers   */

desc = substr(dsn,1,20) /* used on the jobcard of the skeleton       */
hlq  = strip(hlq)
mlq  = strip(mlq)
llq  = strip(llq)

if llq = 'LISTINGS' then call maxpages /* Largest page in any dsn    */

say 'ELIBAUTO: The largest member uses' maxpage 'pages of size' pagesz
say 'ELIBAUTO: '

if llq = 'LISTINGS' then call members /* Total no. of unique members */

say 'ELIBAUTO: Average pages per member is' avgpge

if avgpge = '1' then do
  say 'ELIBAUTO: The page size will be reduced to improve DASD usage'
  say 'ELIBAUTO: The current page size is' pagesz
end /* if avgpge = '1' then do                                       */

say 'ELIBAUTO:'

/* Set the pages per cylinder. Values are hard coded                 */
select

  when pagesz = 1016  then do
    ppc = 15 * 33 /* new pages per cylinder                          */
  end /* when pagesz = 1016  then do */

  when pagesz = 2040  then do
    ppc = 15 * 21 /* new pages per cylinder                          */

    if avgpge = '1' then do
      pagesz = 1016
      ppc = 15 * 33 /* new pages per cylinder                        */
    end /* if avgpge = '1' then do */

  end /* when pagesz = 2040  then do */

  when pagesz = 3064  then do
    ppc = 15 * 15 /* new pages per cylinder                          */

    if avgpge = '1' then do
      pagesz = 2040
      ppc = 15 * 21 /* new pages per cylinder                        */
    end /* if avgpge = '1' then do */

  end /* when pagesz = 3064  then do */

  when pagesz = 4088  then do
    ppc = 15 * 12 /* new pages per cylinder                          */

    if avgpge = '1' then do
      pagesz = 3064
      ppc = 15 * 15 /* new pages per cylinder                        */
    end /* if avgpge = '1' then do */

  end /* when pagesz = 4088  then do */

  when pagesz = 5112  then do
    ppc = 15 * 9 /* new pages per cylinder                           */

    if avgpge = '1' then do
      pagesz = 4088
      ppc = 15 * 12 /* new pages per cylinder                        */
    end /* if avgpge = '1' then do */

  end /* when pagesz = 5112  then do */

  when pagesz = 6136  then do
    ppc = 15 * 8 /* new pages per cylinder                           */

    if avgpge = '1' then do
      pagesz = 5112
      ppc = 15 * 9 /* new pages per cylinder                         */
    end /* if avgpge = '1' then do */

  end /* when pagesz = 6136  then do */

  when pagesz = 7160  then do
    ppc = 15 * 7 /* new pages per cylinder                           */

    if avgpge = '1' then do
      pagesz = 6136
      ppc = 15 * 8 /* new pages per cylinder                         */
    end /* if avgpge = '1' then do */

  end /* when pagesz = 7160  then do */

  when pagesz = 8184  then do
    ppc = 15 * 6 /* new pages per cylinder                           */

    if avgpge = '1' then do
      pagesz = 7160
      ppc = 15 * 7 /* new pages per cylinder                         */
    end /* if avgpge = '1' then do */

  end /* when pagesz = 8184  then do */

  when pagesz = 9208  then do
    ppc = 15 * 5 /* new pages per cylinder                           */

    if avgpge = '1' then do
      pagesz = 8184
      ppc = 15 * 6 /* new pages per cylinder                         */
    end /* if avgpge = '1' then do */

  end /* when pagesz = 9208  then do */

  when pagesz = 10232 then do
    ppc = 15 * 5 /* new pages per cylinder                           */

    if avgpge = '1' then do
      pagesz = 9208
      ppc = 15 * 5 /* new pages per cylinder                         */
    end /* if avgpge = '1' then do */

  end /* when pagesz = 10232 then do */

  when pagesz = 11256 then do
    ppc = 15 * 4 /* new pages per cylinder                           */

    if avgpge = '1' then do
      pagesz = 10232
      ppc = 15 * 5 /* new pages per cylinder                         */
    end /* if avgpge = '1' then do */

  end /* when pagesz = 11256 then do */

  when pagesz = 12280 then do
    ppc = 15 * 4 /* new pages per cylinder                           */

    if avgpge = '1' then do
      pagesz = 11256
      ppc = 15 * 4 /* new pages per cylinder                         */
    end /* if avgpge = '1' then do */

  end /* when pagesz = 12280 then do */

  when pagesz = 16376 then do
    ppc = 15 * 3 /* new pages per cylinder                           */

    if avgpge = '1' then do
      pagesz = 12280
      ppc = 15 * 4 /* new pages per cylinder                         */
    end /* if avgpge = '1' then do */

  end /* when pagesz = 16376 then do */

  when pagesz = 18424 then do
    ppc = 15 * 3 /* new pages per cylinder                           */

    if avgpge = '1' then do
      pagesz = 16376
      ppc = 15 * 3 /* new pages per cylinder                         */
    end /* if avgpge = '1' then do */

  end /* when pagesz = 18424 then do */

  when pagesz = 24568 then do
    ppc = 15 * 2 /* new pages per cylinder                           */

    if avgpge = '1' then do
      pagesz = 18424
      ppc = 15 * 3 /* new pages per cylinder                         */
    end /* if avgpge = '1' then do */

  end /* when pagesz = 24568 then do */

  when pagesz = 26616 then do
    ppc = 15 * 2 /* new pages per cylinder                           */

    if avgpge = '1' then do
      pagesz = 24568
      ppc = 15 * 2 /* new pages per cylinder                         */
    end /* if avgpge = '1' then do */

  end /* when pagesz = 26616 then do */

  otherwise ppc = 15 * 1

end /* end select */

if avgpge = '1' then do
  say 'ELIBAUTO: As the average members per page is 1 the new page'
  say 'ELIBAUTO: size will be set to:' pagesz
  say 'ELIBAUTO: '
end /* if avgpge = '1' then do                                       */

/* If LISTING and using small pagesize then re-allocate with         */
/* big halftrack page size/record len.                               */
if ((llq = 'LISTINGS') |,
    (llq = 'LISTINGS.NIG') |,
    (llq = 'DELTA' & pos('USS.',dsn) > 0)) &,
    pagesz < 26616 then do
      pagesz = 26616 /* Ci is half track so 2 ci/trk.                */
      pf  = ppc / 30 /* Adj factor old ppc / new ppc                 */
      Ppc = 30 /* New pages per cyl is 30.                           */
      maxpage = trunc(maxpage / pf + 0.99) /*Adjust max page size    */
    end /* end select */

cisz = pagesz + 8 /* CISIZE is 8 more than the page size             */

if llq = 'LISTINGS.NIG' |,
   llq = 'LISTINGS' then
  mlq = substr(mlq,1,1)'ZZ'
else
  mlq = substr(mlq,1,4)'ZZ'

if left(mlq,1) = '#' then mlq = 'ZZ'

/* To work out the reserve limit, the largest member size is         */
/* multiplied by 1.1, then divided by pages per cylinder. Add 1 to   */
/* the result then multiply by pages per cylinder again to get the   */
/* perfectly worked out number!                                      */
maxgrwth = (maxpage * 1.1)
reserve  = trunc(maxgrwth / ppc)
reserve  = (reserve + 1)
reserve  = trunc(reserve * ppc)

if reserve < 90 then reserve = 90 /* Set minimum reserve threshold   */

say 'ELIBAUTO: The reserve limit should be 1.1 times the largest'
say 'ELIBAUTO: member, but the figure has been rounded to be an'
say 'ELIBAUTO: integer of the pages per cylinder figure or to a'
say 'ELIBAUTO: minimum value of 90 (whichever is greater.'
say 'ELIBAUTO: '
say 'ELIBAUTO: The reserve threshold is set to' reserve 'pages.'
say 'ELIBAUTO: '

/* Workout how many directory pages are required.                    */
/* The calculation is page size - 32 divided by 84                   */
max_dir = trunc(((pagesz - 32) / 84) + .5)
say 'ELIBAUTO: Maximum number of directory entries for pagesize' pagesz
say 'ELIBAUTO: is' max_dir 'per page'
say 'ELIBAUTO: '
drreqd = (mems / max_dir)
say 'ELIBAUTO: Directory pages required with no free space based'
say 'ELIBAUTO: on' mems 'members divided by' max_dir 'is' drreqd
say 'ELIBAUTO: '

drreqd = (drreqd * 2.5)
drreqd = trunc((drreqd * 1) + .5)
say 'ELIBAUTO: Multiply by 2.5 to allow for growth and free space means'
say 'ELIBAUTO: the actual directory pages required is' drreqd
say 'ELIBAUTO: '

if drreqd < 30 then do /* minimum recommended at RBS                 */

  if llq = 'LISTINGS' then do
    drreqd = 30
    say 'ELIBAUTO: The minimum number of directory pages that RBS'
    say 'ELIBAUTO: recommend for listings is' drreqd
    say 'ELIBAUTO: '
  end /* if llq = 'LISTINGS' then do */

  else do
    drreqd = 50
    say 'ELIBAUTO: The minimum number of directory pages that RBS'
    say 'ELIBAUTO: recommend is for base/deltas is' drreqd
    say 'ELIBAUTO: '
  end /* else do */

end /* if drreqd < 30 then do                                        */

else do
 say 'ELIBAUTO: The new dataset will have' drreqd 'directory pages,'
 say 'ELIBAUTO: to allow for growth.'
 say 'ELIBAUTO: '
end /* else do                                                       */

/* Calc new Primary Cyls by adding 20% to pages used and dividing by */
/* the number of pages per cylinder and round.                       */
say 'ELIBAUTO: The new primary allocation is calculated by adding:-'
say 'ELIBAUTO: '
say 'ELIBAUTO: The pages used....................==>' right(pgrqd,8) '+'
say 'ELIBAUTO: The directory pages required plus.==>' right(drreqd,8) '+'
say 'ELIBAUTO: The largest member in pages.......==>' right(maxpage,8)
say 'ELIBAUTO:                                       ========'

total = (pgrqd + drreqd + maxpage)

say 'ELIBAUTO: The total number of pages required==>' right(total,8) '/'
say 'ELIBAUTO: Divided by pages per cylinder.....==>' right(ppc,8)
say 'ELIBAUTO:                                       ========'
say 'ELIBAUTO: '

pricyl = trunc((((pgrqd + drreqd + maxpage) / ppc) + .5))
say 'ELIBAUTO: Primary allocation in cyliders....==>' pricyl
say 'ELIBAUTO: '
select
  when pricyl < 51  then pricyl = pricyl + 3
  when pricyl < 101 then pricyl = pricyl + 5
  when pricyl > 100 then pricyl = pricyl + 10
  otherwise nop
end /* end select */

say 'ELIBAUTO: Primary allocation for growth is..==>' right(pricyl,8) 'cyls'
say 'ELIBAUTO: '

if pricyl < 5 then do
  pricyl = 5
  say 'ELIBAUTO: However, the smallest primary allocation that RBS'
  say 'ELIBAUTO: recommend is five cylinders.'
  say 'ELIBAUTO: '
end /* if pricyl < 5 then do                                         */

/* The secondary allocation is worked out based on the size of the   */
/* largest member multiplied by 1.2 to allow for growth and rounded  */
/* up.                                                               */
say 'ELIBAUTO: The secondary allocation is worked out based on the'
say 'ELIBAUTO: size of the largest member muliplied by 1.2 and then'
say 'ELIBAUTO: divided by the pages per cylinder.                  '
say 'ELIBAUTO: '
say 'ELIBAUTO: Largest member (in pages).........==>' right(maxpage,8) '/'
say 'ELIBAUTO: Divided by pages per cylinder.....==>' right(ppc,8)
say 'ELIBAUTO:                                       ========'
say 'ELIBAUTO: '

seccyl = trunc(((maxpage / ppc) + .5) * 1.2)

say 'ELIBAUTO: Multiplied by 1.2 equals..........==>' right(seccyl,8) 'cyls'
say 'ELIBAUTO: '

/* If the calculated secondary is less that 10 cyls then use 10 cyls */
if seccyl < 10 then do
  seccyl = 10
  say 'ELIBAUTO: However, the smallest secondary allocation that RBS'
  say 'ELIBAUTO: recommend is 10 cylinders'
  say 'ELIBAUTO: '
end /* if seccyl < 10 then do                                        */

/* Set number of primary, secondary pages. Re-calculate the          */
/* secondary pages to ensure the that it is a full cylinder amount.  */
pripage = (pricyl * ppc) -1
secpage = (seccyl * ppc)

/* Calculate the allocations in tracks                               */
pritrk = (pricyl * 15)
sectrk = (seccyl * 15)

/* Now use File Tailoring to create the two jobs to allocate         */
/* initialise, copy, and rename the Elib.                            */
say 'ELIBAUTO: The re-allocation routine will allocate file'
say 'ELIBAUTO: 'hlq'.'mlq'.'llq' before running the copy'
say 'ELIBAUTO: '
say 'ELIBAUTO: Page size is                         ==>' pagesz
say 'ELIBAUTO: CI size is                           ==>' cisz
say 'ELIBAUTO: '
say 'ELIBAUTO: Pages per cylinder are:              ==>' ppc
say 'ELIBAUTO: '
say 'ELIBAUTO: Primary allocation in cylinders is   ==>' pricyl
say 'ELIBAUTO: Secondary allocation in cylinders is ==>' seccyl
say 'ELIBAUTO: '
say 'ELIBAUTO: Primary allocation in tracks is      ==>' pritrk
say 'ELIBAUTO: Secondary allocation in tracks is    ==>' sectrk
say 'ELIBAUTO: '
say 'ELIBAUTO: Primary pages are set to             ==>' pripage
say 'ELIBAUTO: Secondary pages are set to           ==>' secpage
say 'ELIBAUTO: '
say 'ELIBAUTO: Reserve pages are set to             ==>' reserve
say 'ELIBAUTO: '
say 'ELIBAUTO: Directory pages are set to           ==>' drreqd
say 'ELIBAUTO: '

error_code = 0
address ispexec
"ftopen"
"ftincl EVGELB2I"
if rc ^= 0 then call exception rc 'FTINCL for EVGELB2I failed'
"ftclose NAME(EVGELB2I)"
if rc ^= 0 then call exception rc 'FTCLOSE for EVGELB2I failed'

"ftopen"
"ftincl EVGELB3I"
if rc ^= 0 then call exception rc 'FTINCL for EVGELB3I failed'
"ftclose NAME(EVGELB3I)"
if rc ^= 0 then call exception rc 'FTCLOSE for EVGELB3I failed'

zispfrc = 0
address ispexec "VPUT (ZISPFRC) SHARED"

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/* +---------------------------------------------------------------+ */
/* | Read REPORT dataset into stem MLIST. and process each record  | */
/* | The MLIST. array is the dataset that is actually being        | */
/* | re-organised.                                                 | */
/* +---------------------------------------------------------------+ */
stage_dsn:
 ADDRESS TSO
 "EXECIO * DISKR REPORT (STEM MLIST. FINIS)"
 if rc ^= 0 then call exception rc 'Read of DDname REPORT failed'

 do n1 = 1 to mlist.0

   say substr(mlist.n1,2,131) /* Shorten var to stop line overflow   */

   /* Get variable values from report output                         */
   select
     when substr(mlist.n1,11,7)  = "DSNAME:"     then dsn    = word(mlist.n1,2)
     when substr(mlist.n1,11,10) = "PAGE SIZE:"  then pagesz = word(mlist.n1,3)
     when substr(mlist.n1,11,11) = "PAGES USED:" then pgrqd  = word(mlist.n1,3)
     when substr(mlist.n1,13,8)  = "MEMBERS:"    then mems   = word(mlist.n1,3)
     when substr(mlist.n1,11,11) = "AVG PAGES/M" then avgpge = word(mlist.n1,3)

     when pos('START PAGE #',mlist.n1) > 0 then do
       cmppage = substr(mlist.n1,122,6)
       cmppage = strip(cmppage)
       if cmppage > maxpage then maxpage = cmppage
     end /* when pos('START PAGE #',mlist.n1) > 0 then do */

     otherwise nop
   end /* end select */
 end /* do n1 = 1 to mlist.0 */

 say 'ELIBAUTO:'
 say 'ELIBAUTO: Processing file' dsn
 say 'ELIBAUTO:'

return /* stage_dsn: */

/* +---------------------------------------------------------------+ */
/* | Read PRODELIB ddname to get the largest maxpage in all        | */
/* | listing datasets.                                             | */
/* +---------------------------------------------------------------+ */
maxpages:
 ADDRESS TSO
 "EXECIO 1 DISKR PRODELIB (STEM PLIST. FINIS)"
 if rc ^= 0 then call exception rc 'Read of DDname PRODELIB failed'

 /* Shortened output to stop line overflow                           */
 maxpage = substr(plist.1,122,6)
 maxpage = strip(maxpage)

return /* maxpages: */

/* +---------------------------------------------------------------+ */
/* | Read MEMBERS ddname to get the total number of members in the | */
/* | listing dataset.                                              | */
/* +---------------------------------------------------------------+ */
members:
 ADDRESS TSO
 "EXECIO * DISKR MEMBERS (STEM ALIST. FINIS)"
 if rc ^= 0 then call exception rc 'Read of DDname MEMBERS failed'

 say 'ELIBAUTO: The total number of elements in listings is' alist.0
 say 'ELIBAUTO:'

 mems = alist.0

return /* members: */

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
   address ispexec "FTCLOSE"        /* Close any FTOPENed files      */
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code
