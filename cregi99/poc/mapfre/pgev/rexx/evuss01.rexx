/* Rexx------------------------------------------------------------+ */
/* |                                                               | */
/* | This Rexx is used by the USS Endevor processors , Its does    | */
/* | the following:                                                | */
/* |                                                               | */
/* |    - Build the NDM Data to process NDMPROC USSSHIP            | */
/* |                                 or NDMPROC USSCMD             | */
/* |                                                               | */
/* |    - Build the copy/delete statements used by the CJOB to     | */
/* |      copy/del files from staging USS directory to production. | */
/* |                                                               | */
/* | Name     : PGEV.BASE.REXX(EVUSS01)                            | */
/* |                                                               | */
/* | SYSIN PARMs (positional)                                      | */
/* |                                                               | */
/* |       c1ccid           : CMR number              (&C1CCID)    | */
/* |       c1sstgid         : Source Stage ID         (C1SSTGID)   | */
/* |       c1si             : Stage ID                (&C1SI)      | */
/* |       c1ssubsys        : Source Subsystem        (&C1SSUBSYS) | */
/* |       c1su             : Subsystem               (&C1SU)      | */
/* |       c1senvmnt        : Source Environment      (&C1SENVMNT) | */
/* |       c1en             : Environment             (&C1EN)      | */
/* |       c1element        : Short Element name      (&C1ELEMENT) | */
/* |       action           : COPY or DELETE                       | */
/* |                                                               | */
/* | INPUT FILEs                                                   | */
/* |    DDNAME DESTSYS: Contains the shipment destinations         | */
/* |    C1SYSTEMUSS.DEFAULT="PLEXP1 PLEXN1 PLEXM1"                 | */
/* |                                                               | */
/* |    DDNAME FILENAME: Long name of the element being processed  | */
/* |                                                               | */
/* |    DDNAME SHIPMENT: contains a line for each element output   | */
/* |    LLDIRs      FILENAME   EXTENSION TARGET                    | */
/* |                                                               | */
/* | An usage example for this REXX is in                          | */
/* | PREV.PEV1.PROCINC(USSSHIP2)                                   | */
/* |                                                               | */
/* +---------------------------------------------------------------+ */
trace n

parse arg c1ccid c1sstgid c1si c1ssubsys c1su c1senvmnt c1en c1element action

c1ccid     = strip(c1ccid)
c1sstgid   = strip(c1sstgid)
c1si       = strip(c1si)
c1ssubsys  = strip(c1ssubsys)
c1su       = strip(c1su)
c1senvmnt  = strip(c1senvmnt)
c1en       = strip(c1en)
c1element  = strip(c1element)
action     = strip(action)

/* +---------------------------------------------------------------+ */
/* | Set initial variables                                         | */
/* +---------------------------------------------------------------+ */
run_log.0      = 0  /* Counter for the run_log stack                 */
bpxcmd.1       = 'sh set -x;'
bpxcount       = 1  /* Counter for the USS commands stack            */
trigg_count    = 0  /* Counter for the trigger file stack            */

new_name       = 'TTEVUSS'c1si
owner_grp      = 'ENDEVOR:RBMFBIEG'

call get_long_filename /* get the element long name(s)               */

call print_hdr      /* Set up the output report header               */

if c1si = 'P' then do

  call setup_dirs   /* Set up the backout & implementation names     */

  if c1ccid ^= 'NDVR#SUP' then do
    new_name = 'R'||substr(c1ccid,2,7)
    owner_grp      = 'PMFBCH:RBMFBIEG'
  end /* if c1ccid ^= 'NDVR#SUP' then do */

  call destsys

end /* if c1si = 'P' then do */

if c1si = 'P' then do

  if listdsi('TRIGGER FILE') > 4 then do
    call run_log( 'EVUSS01:   Trigger DDNAME not allocated.')
    call exit(12)
  end /* if listdsi('TRIGGER FILE') > 4 then do */

end /* if c1si = 'P' then do */

do i = 1 to filename.0

  if left(shipment.i,1) = '*' then iterate /* Its a comment line */
  filename = word(filename.i,1)

end /* do i = 1 to filename.0 */

"execio * diskr SHIPMENT (stem shipment. finis"
if rc > 1 then do
  say 'EVUSS01:'
  say 'EVUSS01: Error reading DD name SHIPMENT. RC =' rc
  call exception 12
end /* if rc > 1 then do */

do i = 1 to shipment.0

  if left(shipment.i,1) = '*' then iterate /* Its a comment line */

  ll_dirs   = word(shipment.i,1)
  extension = word(shipment.i,2)
  target    = word(shipment.i,3)

  posn   = pos('/',ll_dirs) + 1 /* ll_dirs is read from the FILES DD */
  ll_dir = substr(ll_dirs,posn) /* remove the first directory        */

  src_path  = '/RBSG/endevor/'c1en'/'ll_dirs

  if extension ^= 'N/A' then do
    extn_pos = pos('.',filename)
    filename = left(filename,extn_pos) || extension
  end /* if extension ^= 'N/A' then do */

  call run_log( "EVUSS01:    Building parameters for file: "ll_dirs"/"filename)
  call run_log( "EVUSS01: "                                                   )

  /* +---------------------------------------------------------------+ */
  /* | If at Stage P build trigger statements to copy the files      | */
  /* | from the shipment directories to the production directories,  | */
  /* | these are in 'PREV.P%%1.&C1TY(&C1ELEMENT).                    | */
  /* | And create unix copy commands to do all the file manipulation | */
  /* | for implementation and backout.                               | */
  /* +---------------------------------------------------------------+ */

  if action = 'COPY' & c1si = 'P' then do

  call dir_names

  /* Does the file exist? */
  command = 'ls' prod_path"/"filename
  call bpxwunix command,,Out.,Err.

  if err.0 = 0 then call backup_dir      /* File found */

  else do

    call run_log( "EVUSS01:    No file: "filename            )
    call run_log( "EVUSS01:    found in directory: "prod_path)
    call run_log( "EVUSS01: "                                )
    call run_log( "EVUSS01:    No backout will be taken."    )
    call run_log( "EVUSS01: "                                )

  end /* end do */

  call from_copy

  call impl_copy

  end /* if action = 'COPY' & c1si = 'P' then do */

  if c1si = 'P' then do

    if action = 'DELETE' then do

      call dir_names /* just in case the variable has not been set */

      /* Does the file exist? */
      command = 'ls' prod_path"/"filename
      call bpxwunix command,,Out.,Err.

      if err.0 = 0 then                      /* File found */
        call backup_dir
      else do
        call run_log( "EVUSS01:    No file: "filename            )
        call run_log( "EVUSS01:    found in directory: "prod_path)
        call run_log( "EVUSS01: "                                )
        call run_log( "EVUSS01:    No backout will be taken."    )
        call run_log( "EVUSS01: "                                )
      end /* else */

      /* Build the delete statements for stage P */
      bpxcount = bpxcount + 1
      bpxcmd.bpxcount = 'rm -f 'prod_path'/'filename';'

      call run_log( "EVUSS01: "                                       )
      call run_log( "EVUSS01:    RM command built for prod directory.")
      call run_log( "EVUSS01:    rm -f "prod_path'/'filename )
      call run_log( "EVUSS01: "                                       )

    end /* if action = 'DELETE' then do */

    /* Work out the target path and write to the tigger PDS */
    target = strip(target)        /* target  is read from the FILES DD */

    tgt_path = "/RBSG/endevor/"target"/"ll_dir

    trigg_count = trigg_count + 1
    trigger_path = target'/'ll_dir'/'filename
    trigger.trigg_count = left(action,6) trigger_path c1element

    call run_log( "EVUSS01:    Trigger built for '"trigger_path"'"   )
    call run_log( "EVUSS01: "                                        )
    call run_log( "EVUSS01:") copies('=',90)
    call run_log( "EVUSS01: "                                        )

  end /* if c1si = 'P' then do */

  /* +-------------------------------------------------------------+ */
  /* | If at stage D or F then build NDMDATA to C:D to Mplex       | */
  /* | directories.                                                | */
  /* +-------------------------------------------------------------+ */
  if (c1si = 'D' | c1si = 'F') & ,    /* Stages D or F               */
     left(target,4) ^= 'PROD' then do /* but dont ship source        */

    if action = 'COPY' then do
      stg_path = src_path
      call ndm_cards
    end /* action = 'COPY' */

    if action = 'DELETE' then
      call build_ndmdata_delete

    ndm = 'Y'

  end /* (c1si = 'D' | c1si = 'F') & left(target,4) ^= 'PROD' */

end /* do i = 1 to shipment.0 */

if c1si = 'P' then do

  trigger.0 = trigg_count

  /* Both the BACKOUT & TRIGGER DSNs are the same.    */
  /* The first write is done with BACKOUT=N so that   */
  /* there is an existing member to back out to, thus */
  /* leaving an EVUSS01 trigger in the Bjob.          */
  "EXECIO * DISKW BACKOUT (stem trigger. FINI"
  if rc ^= 0 then call exception rc 'DISKW of DDname BACKOUT failed'

  "EXECIO * DISKW TRIGGER (stem trigger. FINI"
  if rc ^= 0 then call exception rc 'DISKW of DDname TRIGGER failed'

  call run_log( "EVUSS01:    Trigger file written to: '"||,
            SYSDSNAME'('c1element")'."   )
  call run_log( "EVUSS01: "              )
  call run_log( "EVUSS01:") copies('=',90)
  call run_log( "EVUSS01: "              )

  bpxcount.0 = bpxcount

  "EXECIO * DISKW BPXCMDS (stem bpxcmd. FINI"
  if rc ^= 0 then call exception rc 'DISKW of DDname BPXCMDS failed'

end /* if c1si = 'P' then do */

if ndm = 'Y' then do
  "EXECIO 0 DISKW NDMDATA (FINI"
  if rc ^= 0 then call exception rc 'DISKW of DDname NDMDATA failed'
end /* if ndm = 'Y' then do                                          */
else
  call exit(1)

call exit(0)

/*--------------------- S U B R O U T I N E S -----------------------*/

/* +---------------------------------------------------------------+ */
/* | destsys - Interpret the DESTSYS data member                   | */
/* +---------------------------------------------------------------+ */
destsys:
"execio * diskr DESTSYS (stem destsys. finis"
if rc > 1 then do
  say 'EVUSS01:'
  say 'EVUSS01: Error reading DD name DESTSYS. RC =' rc
  call exception 12
end /* if rc > 1 then do */

do i = 1 to destsys.0
  interpret destsys.i
end

return

/* +---------------------------------------------------------------+ */
/* | get_long_filename - read the element long name from DDname    | */
/* +---------------------------------------------------------------+ */
get_long_filename:

/* Read in and process the files to be shipped/deleted               */
"execio * diskr FILENAME (stem filename. finis"
if rc > 1 then do
  say 'EVUSS01:'
  say 'EVUSS01: Error reading DD name FILENAME. RC =' rc
  call exception 12
end /* if rc > 1 then do */

return
/* +---------------------------------------------------------------+ */
/* | Print_hdr - Write the header to the log                       | */
/* +---------------------------------------------------------------+ */
print_hdr:

 call run_log( "EVUSS01:") copies('-',90)
 call run_log( "EVUSS01: "                                 )
 call run_log( "EVUSS01:    CMR Number         :" c1ccid   )
 call run_log( "EVUSS01:    Source stage Id    :" c1sstgid )
 call run_log( "EVUSS01:    Target stage Id    :" c1si     )
 call run_log( "EVUSS01:    Source subsystem   :" c1ssubsys)
 call run_log( "EVUSS01:    Target subsystem   :" c1su     )
 call run_log( "EVUSS01:    Source environment :" c1senvmnt)
 call run_log( "EVUSS01:    Target environment :" c1en     )
 call run_log( "EVUSS01:    Short element name :" c1element)
 call run_log( "EVUSS01:    Action             :" action   )
 call run_log( "EVUSS01: "                                 )
 call run_log( "EVUSS01:") copies('-',90)
 call run_log( "EVUSS01: "                                 )

return

/* +---------------------------------------------------------------+ */
/* | setup_dirs - Set up the directory name for the implementation | */
/* |              directory                                        | */
/* +---------------------------------------------------------------+ */
setup_dirs:

/* +---------------------------------------------------------------+ */
/* | Set up the name for the implementation directory              | */
/* +---------------------------------------------------------------+ */
 staging_dir    = '/RBSG/endevor/STAGING/'c1ccid

 /* Does the directory exist? */
 command = 'ls' staging_dir
 call bpxwunix command,,Out.,Err.

 if err.0 > 0 then do                   /* Directory does not exist */

   /* Make the implementation directory in the staging structure */
   bpxcount = bpxcount + 1
   bpxcmd.bpxcount = 'mkdir -p -m 775 'staging_dir';'

   call run_log( "EVUSS01:    Staging directory "staging_dir               )
   call run_log( "EVUSS01:    does not exist."                             )
   call run_log( "EVUSS01: "                                               )
   call run_log( "EVUSS01:    MKDIR cmd built for staging directory"       )
   call run_log( "EVUSS01:    mkdir -p -m 775 "staging_dir                 )
   call run_log( "EVUSS01: "                                               )
 call run_log( "EVUSS01:") copies('-',90)
   call run_log( "EVUSS01: "                                               )

 end /* if err.0 > 0 then do */

 else do

   call run_log( "EVUSS01:    Staging directory: "staging_dir              )
   call run_log( "EVUSS01:    already exists."                             )
   call run_log( "EVUSS01: "                                               )
   call run_log( "EVUSS01:    MKDIR command is bypassed"                   )
   call run_log( "EVUSS01: "                                               )
   call run_log( "EVUSS01:") copies('-',90)
   call run_log( "EVUSS01: "                                               )

 end /* else do */

/* +---------------------------------------------------------------+ */
/* | Set up the name for the backout directory                     | */
/* +---------------------------------------------------------------+ */
backout_dir    = '/RBSG/endevor/STAGING/B'||substr(c1ccid,2,7)

 /* Does the directory exist? */
 command = 'ls' backout_dir
 call bpxwunix command,,Out.,Err.

 if err.0 > 0 then do                   /* Directory does not exist */

   /* Make the implementation directory in the staging structure */
   bpxcount = bpxcount + 1
   bpxcmd.bpxcount = 'mkdir -p -m 775 'backout_dir';'

   call run_log( "EVUSS01:    Staging directory "backout_dir               )
   call run_log( "EVUSS01:    does not exist."                             )
   call run_log( "EVUSS01: "                                               )
   call run_log( "EVUSS01:    MKDIR cmd built for staging directory"       )
   call run_log( "EVUSS01:    mkdir -p -m 775 "backout_dir                 )
   call run_log( "EVUSS01: "                                               )
   call run_log( "EVUSS01:") copies('-',90)
   call run_log( "EVUSS01: "                                               )

 end /* if err.0 > 0 then do */

 else do

   call run_log( "EVUSS01:    Staging directory: "backout_dir              )
   call run_log( "EVUSS01:    already exists."                             )
   call run_log( "EVUSS01: "                                               )
   call run_log( "EVUSS01:    MKDIR command is bypassed"                   )
   call run_log( "EVUSS01: "                                               )
   call run_log( "EVUSS01:") copies('-',90)
   call run_log( "EVUSS01: "                                               )

 end /* else do */

return

/* +---------------------------------------------------------------+ */
/* | dir_name - Set up the directory names for future actions      | */
/* +---------------------------------------------------------------+ */
dir_names:

from      = c1senvmnt||'/'||c1sstgid||c1ssubsys

bout_path = backout_dir||'/'||target'/'ll_dir   /* B0 directory path */

impl_path = staging_dir||'/'||target'/'ll_dir   /* C0 directory path */

from_path = '/RBSG/endevor/'from'/'ll_dir       /* from directory    */

prod_path = '/RBSG/endevor/PROD/P'c1su'/'ll_dir /* prod directory    */

return

/* +---------------------------------------------------------------+ */
/* | backup_dir - Create the backout member                        | */
/* +---------------------------------------------------------------+ */
backup_dir:

 /* Does the directory exist? */
 command = 'ls' bout_path
 call bpxwunix command,,Out.,Err.

 if err.0 > 0 then do                   /* Directory does not exist */

   /* Make the actual backout directory in the staging structure */
   bpxcount = bpxcount + 1
   bpxcmd.bpxcount = 'mkdir -p -m 775 'bout_path';'

   call run_log( "EVUSS01:    MKDIR command built for backout directory"   )
   call run_log( "EVUSS01:    mkdir -p -m 775 "bout_path                   )
   call run_log( "EVUSS01: "                                               )

 end /* if err.0 > 0 then do */

 else do

   call run_log( "EVUSS01:    Backout directory "bout_path                 )
   call run_log( "EVUSS01:    already exists"                              )
   call run_log( "EVUSS01: "                                               )
   call run_log( "EVUSS01:    MKDIR command is bypassed"                   )
   call run_log( "EVUSS01: "                                               )

 end /* else do */

 /* Does the file exist? */
 command = 'ls' bout_path"/"filename
 call bpxwunix command,,Out.,Err.

 if err.0 > 0 then do                   /* File does not exist */

   call run_log( "EVUSS01:    Backout file "filename                       )
   call run_log( "EVUSS01:    does not exist in directory" bout_path       )
   call run_log( "EVUSS01: "                                               )

   /* Does the source exist? */
   command = 'ls' prod_path"/"filename
   call bpxwunix command,,Out.,Err.

   if err.0 > 0 then do                  /* File does not exist */

     call run_log( "EVUSS01:    No prod file to backup"                      )
     call run_log( "EVUSS01: "                                               )

   end /* if err.0 > 0 then do */

   else do

     bpxcount = bpxcount + 1
     bpxcmd.bpxcount = "cp -m" prod_path"/"filename ,
                       bout_path"/"filename';'

     call run_log( "EVUSS01:    CP command built for backout"                )
     call run_log( "EVUSS01:      From: '"prod_path"/"filename"'"            )
     call run_log( "EVUSS01:        To: '"bout_path"/"filename"'"            )
     call run_log( "EVUSS01: "                                               )

     bpxcount = bpxcount + 1
     bpxcmd.bpxcount = "chmod -f 755 "bout_path"/"filename';'

     call run_log( "EVUSS01:    chmod -f 755 built for "                     )
     call run_log( "EVUSS01:    "bout_path"/"filename                        )
     call run_log( "EVUSS01: "                                               )

     bpxcount = bpxcount + 1
     bpxcmd.bpxcount = "chown -f PMFBCH "bout_path"/"filename';'

     call run_log( "EVUSS01:    chown -f PMFBCH built for"                   )
     call run_log( "EVUSS01:    "bout_path"/"filename                        )
     call run_log( "EVUSS01: "                                               )

   end /* else do */

 end /* if err.0 > 0 then do */

 else do

   call run_log( "EVUSS01:    Backout file: "filename                      )
   call run_log( "EVUSS01:    exists in the directory: "bout_path          )
   call run_log( "EVUSS01: "                                               )
   call run_log( "EVUSS01:    Copy bypassed"                               )
   call run_log( "EVUSS01:"                                                )
   call run_log( "EVUSS01:") copies('-',90)
   call run_log( "EVUSS01:"                                                )

 end /* else do */

return

/* +---------------------------------------------------------------+ */
/* | from_copy - Copy the files from the source directory path     | */
/* +---------------------------------------------------------------+ */
from_copy:

/* temp code until EVUSS00 is implemented */
if right(prod_path,10) = 'WBRESOLVED' then return

/* Remove the target prod file to ensure that the copy works         */
 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "rm -f" prod_path"/"filename';'

/* Copy the target file to the production directory                  */
 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "cp -m" from_path"/"filename ,
                   prod_path"/"filename';'

/* Put out messages to summarise the action                          */
 call run_log( "EVUSS01:    CP command to copy from source to prod"    )
 call run_log( "EVUSS01:      From: '"from_path"/"filename"'"          )
 call run_log( "EVUSS01:        To: '"prod_path"/"filename"'"          )
 call run_log( "EVUSS01: "                                             )

 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "chmod -f 755 "prod_path"/"filename';'

 call run_log( "EVUSS01:    chmod -f 755 built for "                   )
 call run_log( "EVUSS01:    "prod_path"/"filename                      )
 call run_log( "EVUSS01: "                                             )

 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "chown -f ENDEVOR "prod_path"/"filename';'

 call run_log( "EVUSS01:    chown -f ENDEVOR built for"                )
 call run_log( "EVUSS01:    "prod_path"/"filename                      )
 call run_log( "EVUSS01: "                                             )

return

/* +---------------------------------------------------------------+ */
/* | impl_copy - Create the implementation statements              | */
/* +---------------------------------------------------------------+ */
impl_copy:

 /* Does the directory exist? */
 command = 'ls' impl_path
 call bpxwunix command,,Out.,Err.

 if err.0 > 0 then do                   /* Directory not found */

   /* Make the implementation directory in the staging structure */
   bpxcount = bpxcount + 1
   bpxcmd.bpxcount = 'mkdir -p -m 775 'impl_path';'

 end /* if err.0 = 0 then do */

 else do

   call run_log( "EVUSS01:    Implementation directory: "impl_path           )
   call run_log( "EVUSS01:    already exists."                               )
   call run_log( "EVUSS01: "                                                 )
   call run_log( "EVUSS01:    MKDIR bypassed"                                )
   call run_log( "EVUSS01: "                                                 )

 end /* else do */

 /* Copy the prod file to the implementation staging directory */
 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "cp -m" prod_path"/"filename ,
                   impl_path"/"filename';'

 call run_log( "EVUSS01:    CP command built for implementation"           )
 call run_log( "EVUSS01:      From: '"prod_path"/"filename"'"              )
 call run_log( "EVUSS01:        To: '"impl_path"/"filename"'"              )
 call run_log( "EVUSS01: "                                                 )
 call run_log( "EVUSS01:") copies('-',90)
 call run_log( "EVUSS01: "                                                 )

 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "chmod -f 755 "impl_path"/"filename';'

 call run_log( "EVUSS01:    chmod -f 755 built for "                   )
 call run_log( "EVUSS01:    "impl_path"/"filename                      )
 call run_log( "EVUSS01: "                                             )

 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "chown -f PMFBCH "impl_path"/"filename';'

 call run_log( "EVUSS01:    chown -f PMFBCH built for"                 )
 call run_log( "EVUSS01:    "impl_path"/"filename                      )
 call run_log( "EVUSS01: "                                             )

return

/* +---------------------------------------------------------------+ */
/* | Build NDM cards to delete files on the Mplex                  | */
/* +---------------------------------------------------------------+ */
build_ndmdata_delete:

 queue " SIGNON CASE=Y"
   say " EVUSS01: SIGNON CASE=Y"
 queue "  SUBMIT PROC=USSCMD SNODE=CD.OS390.M102 -"
   say " EVUSS01:  SUBMIT PROC=USSCMD SNODE=CD.OS390.M102 -"
 queue "  NEWNAME=TTEVUDEL -"
   say " EVUSS01:  NEWNAME=TTEVUDEL -"
 queue "  &UNCMD01=\C'sh rm -f \ || -"
   say " EVUSS01:  &UNCMD01=\C'sh rm -f \ || -"
 queue "  \"src_path"/\ || -"
   say " EVUSS01:  \"src_path"/\ || -"

 if length(filename) > 50 then do
   filename1 = left(filename,50)
   filename2 = substr(filename,51)
   queue "  \"filename1"\ || -"
     say " EVUSS01:  \"filename1"\ || -"
   queue "  \"filename2"' \"
     say " EVUSS01:  \"filename2"' \"
 end /* if length(filename) > 50 then do */

 else queue "  \"filename"' \"
        say " EVUSS01:  \"filename"' \"

 queue " SIGNOFF"
   say " EVUSS01: SIGNOFF"

 "EXECIO" queued() "DISKW NDMDATA"
 if rc > 1 then do
   say 'EVUSS01:'
   say 'EVUSS01: Error writing DD name NDMDATA. RC =' rc
   call exception 12
 end /* if rc > 1 then do */

 call run_log( "EVUSS01:    NDM data built for M-plex"                     )
 call run_log( "EVUSS01: "                                                 )
 call run_log( "EVUSS01:    Delete: '"src_path"/"filename"'"               )
 call run_log( "EVUSS01: "                                                 )

return

/* +---------------------------------------------------------------+ */
/* | Ndm_cards - Build NDM data cards to copy files to the Mplex   | */
/* +---------------------------------------------------------------+ */
ndm_cards:

 queue " SIGNON CASE=Y"
   say " EVUSS01: SIGNON CASE=Y"
 queue "  SUBMIT PROC=USSSHIP SNODE=CD.OS390.M102 -"
   say " EVUSS01:  SUBMIT PROC=USSSHIP SNODE=CD.OS390.M102 -"
 queue "  NEWNAME="new_name" -"
   say " EVUSS01:  NEWNAME="new_name" -"
 queue "  &CA7JOBI="new_name" -"
   say " EVUSS01:  &CA7JOBI="new_name" -"
 queue "  &UNCMD01=\C'SH mkdir -p -m 775 \ || -"
   say " EVUSS01:  &UNCMD01=\C'SH mkdir -p -m 775 \ || -"
 queue "           \"stg_path "' \ -"
   say " EVUSS01:           \"stg_path "' \ -"
 queue "  &UNCMD02=\C'SH chmod 775 \ || -"
   say " EVUSS01:  &UNCMD02=\C'SH chmod 775 \ || -"
 queue "           \"stg_path "' \ -"
   say " EVUSS01:           \"stg_path "' \ -"
 queue "  &UNCMD03=\C'SH chown" owner_grp "\ || -"
   say " EVUSS01:  &UNCMD03=\C'SH chown" owner_grp "\ || -"
 queue "           \"stg_path "' \ -"
   say " EVUSS01:           \"stg_path "' \ -"
 queue "  &DIRIN1='"src_path"' -"
   say " EVUSS01:  &DIRIN1='"src_path"' -"
 queue "  &DIROUT1='"stg_path"' -"
   say " EVUSS01:  &DIROUT1='"stg_path"' -"

 if length(filename) > 50 then do
   filename1 = left(filename,50)
   filename2 = substr(filename,51)
   queue "  &FILEIN1=\'"filename1"\ || -"
     say " EVUSS01:  &FILEIN1=\'"filename1"\ || -"
   queue "           \"filename2"' \ -"
     say " EVUSS01:           \"filename2"' \ -"
   queue "  &FILEOUT1=\'"filename1"\ || -"
     say " EVUSS01:  &FILEOUT1=\'"filename1"\ || -"
   queue "            \"filename2"' \"
     say " EVUSS01:            \"filename2"' \"
 end /* if length(filename) > 50 then do */

 else do
   queue "  &FILEIN1='"filename"' -"
     say " EVUSS01:  &FILEIN1='"filename"' -"
   queue "  &FILEOUT1='"filename"'"
     say " EVUSS01:  &FILEOUT1='"filename"'"
 end /* else do */

 queue " SIGNOFF"
   say " EVUSS01: SIGNOFF"

 "EXECIO" queued() "DISKW NDMDATA"
 if rc > 1 then do
   say 'EVUSS01:'
   say 'EVUSS01: Error reading DD name FILENAME. RC =' rc
   call exception 12
 end /* if rc > 1 then do */

 call run_log( "EVUSS01:    NDM data built for Mplex"                      )
 call run_log( "EVUSS01: "                                                 )
 call run_log( "EVUSS01:      From: '"src_path"/"filename"'"               )
 call run_log( "EVUSS01:        To: '"stg_path"/"filename"'"               )
 call run_log( "EVUSS01: "                                                 )

return

/* +---------------------------------------------------------------+ */
/* | run_log - Write a line to the log                             | */
/* +---------------------------------------------------------------+ */
run_log:
 parse arg log_entry
 run_log.0 = run_log.0 + 1
 junk = value('run_log.'||run_log.0,log_entry)

return

/* +---------------------------------------------------------------+ */
/* | Exit - Closedown                                              | */
/* +---------------------------------------------------------------+ */
Exit:
 arg exit_rc
 "EXECIO * DISKW USS01LOG (FINI STEM run_log."
 exit exit_rc

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 delstack /* Clear down the stack                                    */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
