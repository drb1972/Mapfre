/*-- REXX -----------------------------------------------------------*/
/*-                                                                 -*/
/*-  This REXX is used to determine which plex the Cjob is running  -*/
/*-  on.                                                            -*/
/*-  It can be used for cloned shipment destinations to run or not  -*/
/*-  subsequent job steps.                                          -*/
/*-                                                                 -*/
/*-------------------------------------------------------------------*/
/*-  Created: If this is the Pplex then issue return code two       -*/
/*-           If this is the Nplex then issue return code three     -*/
/*-           If this is the Eplex then issue return code four      -*/
/*-           If this is the Mplex then issue return code five      -*/
/*-           If this is the Cplex then issue return code seven     -*/
/*-           If this is the Dplex then issue return code eight     -*/
/*-           If this is the Fplex then issue return code nine      -*/
/*-------------------------------------------------------------------*/
trace n

/*-------------------------------------------------------------------*/
/* Get the sysplex name, then find out what return is issued based   */
/* on char 5 of the variable SYSPLEX                                 */
/*-------------------------------------------------------------------*/
sysplex = MVSVAR(SYSPLEX)                   /* GSI plexes are PLEX** */

select
  when substr(sysplex,5,1) = 'P' then exit 2   /* This is the Pplex  */
  when substr(sysplex,5,1) = 'N' then exit 3   /* This is the Nplex  */
  when substr(sysplex,5,1) = 'E' then exit 4   /* This is the Qplex  */
  when substr(sysplex,5,1) = 'M' then exit 5   /* This is the Mplex  */
  when substr(sysplex,5,1) = 'C' then exit 7   /* This is the Cplex  */
  when substr(sysplex,5,1) = 'D' then exit 8   /* This is the Dplex  */
  when substr(sysplex,5,1) = 'F' then exit 9   /* This is the Fplex  */

  otherwise do
    say 'EVPLEXRC: Unknown plex'
    exit 99
  end /* otherwise do */

end /* end select */
