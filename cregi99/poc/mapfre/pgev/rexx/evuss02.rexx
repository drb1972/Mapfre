/* Rexx------------------------------------------------------------+ */
/* |                                                               | */
/* | This Rexx is used by the Endevor Rjob to see if there are     | */
/* | USS directories that need packaging up using the pax command, | */
/* | then sending the pax files to each plex, using pax to         | */
/* | explode the files, and finally deleting the pax files         | */
/* | following successful processing.                              | */
/* | It does the following:-                                       | */
/* |                                                               | */
/* |    - Build the pax commands at source and target and the      | */
/* |      rm command to tidy up afterwards.                        | */
/* |                                                               | */
/* |    - Build the NDM data to process NDMPROC USSPAX             | */
/* |                                                               | */
/* | Name     : PGEV.BASE.REXX(EVUSS02)                            | */
/* |                                                               | */
/* | SYSIN PARMs (positional)                                      | */
/* |                                                               | */
/* |       c1ccid           : CMR number              (&C1CCID)    | */
/* |                                                               | */
/* | INPUT FILEs                                                   | */
/* |    DDNAME DESTSYS: Contains the shipment destinations         | */
/* |    C1SYSTEMUSS.DEFAULT="PLEXP1 PLEXN1 PLEXM1"                 | */
/* |                                                               | */
/* | An usage example for this REXX is in                          | */
/* | PREV.PIB1.SKELS(CMSPAX)                                       | */
/* |                                                               | */
/* +---------------------------------------------------------------+ */
trace n

parse arg c1ccid

c1ccid = strip(c1ccid)

/* +---------------------------------------------------------------+ */
/* | Set initial variables                                         | */
/* +---------------------------------------------------------------+ */
run_log.0      = 0  /* Counter for the run_log stack                 */
bpxcount       = 0  /* Counter for the USS commands stack            */

imp_pax  = c1ccid||'.pax.Z'                  /* Impl archive         */
out_pax  = 'B'||substr(c1ccid,2,7)||'.pax.Z' /* Backout archive      */
new_name = 'R'||substr(c1ccid,2,7)           /* Used in the C:D proc */

call print_hdr      /* Set up the output report header               */

call setup_dirs     /* Set up the backout & implementation variables */

call destsys        /* Read PGEV.BASE.DATA(DESTSYS) for shipments    */

/* +---------------------------------------------------------------+ */
/* | Check to see if the staging tree contains anything for this   | */
/* | ccid.                                                         | */
/* +---------------------------------------------------------------+ */
command = 'ls' staging_dir
call bpxwunix command,,Out.,Err.

if err.0 > 0 then do /* No directory found                           */

  call run_log( "EVUSS02: "                                                  )
  call run_log( "EVUSS02:    /RBSG/endevor/STAGING/"c1ccid "not found"       )
  call run_log( "EVUSS02: "                                                  )
  call run_log( "EVUSS02:    There will be no further processing. RC = 0"    )
  call run_log( "EVUSS02: "                                                  )

  call exit 0  /* Return code to allow future steps to be bypassed   */

end /* if err.0 > 0 then call do */

else do

  call run_log( "EVUSS02: "                                                  )
  call run_log( "EVUSS02: /RBSG/endevor/STAGING/"c1ccid "found"              )
  call run_log( "EVUSS02: "                                                  )
  call run_log( "EVUSS02: PAX processing will be invoked, with the          ")
  call run_log( "EVUSS02: files sent over to the plexes identified in the   ")
  call run_log( "EVUSS02: PGEV.BASE.DATA(DESTSYS) data member.              ")
  call run_log( "EVUSS02: ")

  call build_pax   /* commands for the PAX creation */

/* +---------------------------------------------------------------+ */
/* | Read through the DESTSYS data member to get valid C:D         | */
/* | destinations.                                                 | */
/* +---------------------------------------------------------------+ */
  queue " SIGNON CASE=Y"
  say   " EVUSS02: SIGNON CASE=Y"
  do j = 1 to words(c1systemuss.default)
    plex = substr(word(c1systemuss.default,j),5,1)
    call pax_cards plex
  end  /* do j = 1 to words(c1systemuss.default) */
  queue " SIGNOFF"
  say   " EVUSS02: SIGNOFF"

/* +---------------------------------------------------------------+ */
/* | Write out the ndmdata commands                                | */
/* +---------------------------------------------------------------+ */
  "EXECIO" queued() "DISKW NDMDATA (FINI"
  if rc > 1 then do
    say 'EVUSS02:'
    say 'EVUSS02: Error writing DD name NDMDATA. RC =' rc
    call exception 12
  end /* if rc > 1 then do */

  call exit 1

end /* else do */

/*------------------ S U B R O U T I N E S ------------------*/

/* +---------------------------------------------------------------+ */
/* | Print_hdr - Write the header to the log                       | */
/* +---------------------------------------------------------------+ */
print_hdr:

 call run_log( "EVUSS02:") copies('-',70)
 call run_log( "EVUSS02: "                                        )
 call run_log( "EVUSS02:        CMR Number              :" c1ccid )
 call run_log( "EVUSS02: "                                        )
 call run_log( "EVUSS02:        Implementation pax file :" imp_pax)
 call run_log( "EVUSS02:        Backout pax file        :" out_pax)
 call run_log( "EVUSS02: "                                        )
 call run_log( "EVUSS02:") copies('-',70)

return

/* +---------------------------------------------------------------+ */
/* | setup_dirs - Set the variables for the staging directory      | */
/* |              names                                            | */
/* +---------------------------------------------------------------+ */
setup_dirs:

/* +---------------------------------------------------------------+ */
/* | Set up the variable for the implementaion directory           | */
/* +---------------------------------------------------------------+ */
 staging_dir    = '/RBSG/endevor/STAGING/'c1ccid

/* +---------------------------------------------------------------+ */
/* | Set up the variable for the backout directory                 | */
/* +---------------------------------------------------------------+ */
 backout_dir    = '/RBSG/endevor/STAGING/B'||substr(c1ccid,2,7)

/* +---------------------------------------------------------------+ */
/* | Set up the variable for the implementation pax file           | */
/* +---------------------------------------------------------------+ */
 impl_pax       = '/RBSG/endevor/STAGING/'c1ccid'.pax.Z'

/* +---------------------------------------------------------------+ */
/* | Set up the variable for the backout pax file                  | */
/* +---------------------------------------------------------------+ */
 bout_pax       = '/RBSG/endevor/STAGING/B'||substr(c1ccid,2,7)'.pax.Z'

return

/* +---------------------------------------------------------------+ */
/* | destsys - Interpret the DESTSYS data member                   | */
/* +---------------------------------------------------------------+ */
destsys:

 "execio * diskr DESTSYS (stem destsys. finis"
 if rc > 1 then do
   say 'EVUSS02:'
   say 'EVUSS02: Error reading DD name DESTSYS. RC =' rc
   call exception 12
 end /* if rc > 1 then do */

 do i = 1 to destsys.0
   interpret destsys.i
 end

return

/* +---------------------------------------------------------------+ */
/* | build_pax - Queue the commands for building the pax file      | */
/* +---------------------------------------------------------------+ */
build_pax:

 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "bpxbatch sh +"
 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "pax -p e -o saveext -wzvf /RBSG/endevor/STAGING/"imp_pax "+"
 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = staging_dir

 call run_log( "EVUSS02: "                                                )
 call run_log( "EVUSS02:      PAX command built for implementation"       )
 call run_log( "EVUSS02: sh pax -p e -o saveext -wzvf /STAGING/"imp_pax"'")
 call run_log( "EVUSS02:  "staging_dir                                    )
 call run_log( "EVUSS02: "                                                )

 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "bpxbatch sh +"
 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "pax -p e -o saveext -wzvf /RBSG/endevor/STAGING/"out_pax "+"
 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = backout_dir

 call run_log( "EVUSS02: "                                                )
 call run_log( "EVUSS02:      PAX command built for implementation"       )
 call run_log( "EVUSS02: sh pax -p e -o saveext -wzvf /STAGING/"out_pax"'")
 call run_log( "EVUSS02:  "backout_dir                                    )
 call run_log( "EVUSS02: "                                                )

 "EXECIO * DISKW BPXCMDS (stem bpxcmd. FINI"
 if rc > 1 then do
   say 'EVUSS02:'
   say 'EVUSS02: Error writing DD name BPXCMDS. RC =' rc
   call exception 12
 end /* if rc > 1 then do */

return

/* +---------------------------------------------------------------+ */
/* | pax_cards - Build the C:D cards to transmit the pax file      | */
/* +---------------------------------------------------------------+ */
pax_cards:
arg plex

 queue " SUBMIT PROC=USSPAX SNODE=CD.OS390."plex"102 -"
   say " EVUSS02:  SUBMIT PROC=USSPAX SNODE=CD.OS390."plex"102 -"

 queue "  MAXDELAY=01:00:00 -"
   say " EVUSS02:  MAXDELAY=01:00:00 -"

 queue "  PRTY=12 CLASS=1 -"
   say " EVUSS02:  PRTY=12 CLASS=1 -"

 queue "  NEWNAME="new_name" -"
   say " EVUSS02:  NEWNAME="new_name" -"

 queue "  &CA7JOBI="new_name" -"
   say " EVUSS02:  &CA7JOBI="new_name" -"

 queue "  &DIRIN1='/RBSG/endevor/STAGING' -"
   say " EVUSS02:  &DIRIN1='/RBSG/endevor/STAGING' -"

 queue "  &DIROUT1='/RBSG/endevor/STAGING' -"
   say " EVUSS02:  &DIROUT1='/RBSG/endevor/STAGING' -"

 queue "  &FILEIN1='"imp_pax"' -"
   say " EVUSS02:  &FILEIN1='"imp_pax"' -"

 queue "  &FILEOUT1='"imp_pax"' -"
   say " EVUSS02:  &FILEOUT1='"imp_pax"' -"

 queue "  &DIRIN2='/RBSG/endevor/STAGING' -"
   say " EVUSS02:  &DIRIN2='/RBSG/endevor/STAGING' -"

 queue "  &DIROUT2='/RBSG/endevor/STAGING' -"
   say " EVUSS02:  &DIROUT2='/RBSG/endevor/STAGING' -"

 queue "  &FILEIN2='"out_pax"' -"
   say " EVUSS02:  &FILEIN2='"out_pax"' -"

 queue "  &FILEOUT2='"out_pax"'"
   say " EVUSS02:  &FILEOUT2='"out_pax"'"

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
 if rc > 0 then do
   say 'EVUSS02:'
   say 'EVUSS02: Error writing DD name USS01LOG. RC =' rc
   call exception 12
 end /* if rc > 1 then do */

 exit exit_rc

/* +---------------------------------------------------------------+ */
/* | Error with line number displayed                              | */
/* +---------------------------------------------------------------+ */
exception:
 arg return_code

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname': Exception called from line' sigl

exit return_code
