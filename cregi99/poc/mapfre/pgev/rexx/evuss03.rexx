/* Rexx------------------------------------------------------------+ */
/* |                                                               | */
/* | This Rexx is used by the EVL0101D job to see if there is a    | */
/* | pax file in the staging directory that needs expanding.       | */
/* |                                                               | */
/* | If the pax files exists, then commands are built to expand    | */
/* | the pax file and delete the pax file on successful completion | */
/* | of the pax command.                                           | */
/* |                                                               | */
/* | It does the following:-                                       | */
/* |                                                               | */
/* |    - Build the pax commands at source and target and the      | */
/* |      rm command to tidy up afterwards.                        | */
/* |                                                               | */
/* | Name        : PGEV.BASE.REXX(EVUSS03)                         | */
/* |                                                               | */
/* | SYSIN PARMs :                                                 | */
/* |                                                               | */
/* |      c1ccid : CMR number                                      | */
/* |                                                               | */
/* | An usage example for this REXX is in                          | */
/* | PGOS.BASE.PROCLIB(EVL0101D)                                   | */
/* |                                                               | */
/* +---------------------------------------------------------------+ */
trace n

parse arg c1ccid

c1ccid = strip(c1ccid)

/* +---------------------------------------------------------------+ */
/* | Set initial variables                                         | */
/* +---------------------------------------------------------------+ */
run_log.0 = 0 /* Counter for the run_log stack                       */
bpxcount  = 0 /* Counter for the USS commands stack                  */

call setup_dirs /* Set up the backout & implementation variables     */

call print_hdr /* Set up the output report header                    */

/* +---------------------------------------------------------------+ */
/* | Check to see if the staging tree contains a pax file for this | */
/* | change record.                                                | */
/* +---------------------------------------------------------------+ */
command = 'ls' impl_pax
call bpxwunix command,,Out.,Err.

if err.0 > 0 then do /* No directory found                           */

  call run_log( "EVUSS03: "                                                 )
  call run_log( "EVUSS03: No PAX file was found in the /RBSG/endevor/STAGING")
  call run_log( "EVUSS03: tree that matches "impl_pax                        )
  call run_log( "EVUSS03: "                                                  )
  call run_log( "EVUSS03: There will be no further processing. RC = 0"       )
  call run_log( "EVUSS03: "                                                  )

  call exit 0  /* Return code to allow future steps to be bypassed   */

end /* if err.0 > 0 then call do                                     */

else do

  call run_log( "EVUSS03: "                                                  )
  call run_log( "EVUSS03: A directory that matches "c1ccid" has been found" )
  call run_log( "EVUSS03: in the /RBSG/endevor/STAGING tree.                ")
  call run_log( "EVUSS03: "                                                  )
  call run_log( "EVUSS03: PAX processing will be invoked. RC = 1            ")
  call run_log( "EVUSS03: ")

  call build_pax /* commands for the PAX creation                    */

  call remove_pax /* commands for the rm of the PAX file             */

  call exit 1

end /* else do                                                       */

/*---------------------- S U B R O U T I N E S ----------------------*/

/* +---------------------------------------------------------------+ */
/* | Print_hdr - Write the header to the log                       | */
/* +---------------------------------------------------------------+ */
print_hdr:

 call run_log( "EVUSS03:") copies('-',70)
 call run_log( "EVUSS03: "                                         )
 call run_log( "EVUSS03:     CMR Number              : "c1ccid     )
 call run_log( "EVUSS03: "                                         )
 call run_log( "EVUSS03:     Implementation pax file : "impl_pax   )
 call run_log( "EVUSS03:     Backout pax file        : "bout_pax   )
 call run_log( "EVUSS03: "                                         )
 call run_log( "EVUSS03:") copies('-',70)

return

/* +---------------------------------------------------------------+ */
/* | setup_dirs - Set the variables for the staging directory      | */
/* |              names                                            | */
/* +---------------------------------------------------------------+ */
setup_dirs:

 /* +--------------------------------------------------------------+ */
 /* | Set up the variable for the implementation pax file          | */
 /* +--------------------------------------------------------------+ */
 impl_pax    = '/RBSG/endevor/STAGING/'c1ccid'.pax.Z'

 /* +--------------------------------------------------------------+ */
 /* | Set up the variable for the backout pax file                 | */
 /* +--------------------------------------------------------------+ */
 bout_pax    = '/RBSG/endevor/STAGING/B'||substr(c1ccid,2,7)'.pax.Z'

 /* +--------------------------------------------------------------+ */
 /* | Set up the variable for the implementaion directory          | */
 /* +--------------------------------------------------------------+ */
 staging_dir = '/RBSG/endevor/STAGING/'c1ccid

 /* +--------------------------------------------------------------+ */
 /* | Set up the variable for the backout directory                | */
 /* +--------------------------------------------------------------+ */
 backout_dir = '/RBSG/endevor/STAGING/B'||substr(c1ccid,2,7)

return

/* +---------------------------------------------------------------+ */
/* | build_pax - Queue the commands for building the pax file      | */
/* +---------------------------------------------------------------+ */
build_pax:

 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "bpxbatch sh +"
 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "pax -rvf "impl_pax staging_dir

 call run_log( "EVUSS03: "                                            )
 call run_log( "EVUSS03:      PAX command built for implementation"   )
 call run_log( "EVUSS03: sh pax -rvf "impl_pax staging_dir            )
 call run_log( "EVUSS03: "                                            )

 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "bpxbatch sh +"
 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "pax -rvf "bout_pax backout_dir

 call run_log( "EVUSS03: "                                            )
 call run_log( "EVUSS03:      PAX command built for backout"          )
 call run_log( "EVUSS03: sh pax -rvf "bout_pax backout_dir            )
 call run_log( "EVUSS03: "                                            )

return

/* +---------------------------------------------------------------+ */
/* | remove_pax - Queue the commands for building the pax file     | */
/* +---------------------------------------------------------------+ */
remove_pax:

 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "bpxbatch sh +"
 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "rm -f "impl_pax

 call run_log( "EVUSS03: "                                            )
 call run_log( "EVUSS03:      Delete the implmentation PAX file."     )
 call run_log( "EVUSS03: sh rm -f "impl_pax                           )
 call run_log( "EVUSS03: "                                            )

 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "bpxbatch sh +"
 bpxcount = bpxcount + 1
 bpxcmd.bpxcount = "rm -f "bout_pax

 call run_log( "EVUSS03: "                                            )
 call run_log( "EVUSS03:      Delete the backout PAX file."           )
 call run_log( "EVUSS03: sh rm -f "bout_pax                           )
 call run_log( "EVUSS03: "                                            )

 "EXECIO * DISKW BPXCMDS (stem bpxcmd. FINI"
 if rc > 1 then do
   say 'EVUSS03:'
   say 'EVUSS03: Error writing DD name BPXCMDS. RC = 'rc
   call exception 12
 end /* if rc > 1 then do                                            */

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
   say 'EVUSS03:'
   say 'EVUSS03: Error writing DD name USS01LOG. RC =' rc
   call exception 12
 end /* if rc > 1 then do                                            */

 exit exit_rc

/* +---------------------------------------------------------------+ */
/* | Error with line number displayed                              | */
/* +---------------------------------------------------------------+ */
exception:
 arg return_code

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname': Exception called from line' sigl

exit return_code
