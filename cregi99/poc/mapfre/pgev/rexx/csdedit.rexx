/* rexx -                                                    */
/* John PD Scott (Endevor Support)                           */
/*        Reads unloaded pds created by IEBPTPCH             */
/*        Removes Print attributes and member name           */
/*        Processes a PDS containing DFHCSD members          */
/*        Build CSD DELETE statements                        */
/*        Changes REMOTE SYSTEM NAME                         */
/*        Removes Print attributes and member name           */
/* --------------------------------------------------------- */
/*      //STEP01   EXEC PGM=IKJEFT01,                        */
/*      // PARM='CSDEDIT VER5'                              */
/*      //SYSEXEC  DD DISP=SHR,DSN=pds.with.this.rexx.in     */
/*      //SYSTSPRT DD SYSOUT=*                               */
/*      //CSDIN    DD DSN=                                   */
/*      //CSDOUT   DD DSN=                                   */
/*      //SYSTSIN  DD DUMMY                                  */
/* --------------------------------------------------------- */
  parse arg tower
  say date() time() '--- C S D E D I T ---'
  say date() time() 'CSDEDIT TOWER PARM='tower

  /*  Read csdin and INMSGS2                                   */
  /*                                                           */
      "execio * diskr csdin (stem csdin. finis"
      if rc > 0 then exit(13) ;

  /*  Loop through csdin and find messages                     */
  /*                                                           */
  memcount = 0
  say 'CSDEDIT: Start of CSDIN'
      do j = 1 to csdin.0
      /* Loop through IEBPTPCH output */
        if substr(csdin.j,2,11) = 'MEMBER NAME' then do

          /* Start of new member */

          member = substr(csdin.j,15,8)
          say 'CSDEDIT: MEMBER='member


          /* CREATE CSD DELETE STATEMENT     */

          memcount = memcount + 1

          if substr(member,5,4) = "LIST" then
             queue " DELETE LIST("member")"
          else
             queue " DELETE GROUP("member")"

          /* SHOULD DEFINITION BE ALTERED  ? */
          If index(member,'LIST') > 0 then ,
             | TOWER = "VER5" then ALTER = "NO"
          else ALTER = "YES"
        end /* MEMBER NAME */
        else do
          /*                                 */
          /* CREATE ALTERED CSD UPDATES      */
          /*                                 */
          csddata = substr(csdin.j,2,80)
          if ALTER = "YES" then do

             REMPOS = index(CSDDATA,"REMOTESYSTEM(")
             if REMPOS > 0 then do

                  if substr(CSDDATA,REMPOS+13,2) = "PR" then
                    csddata = overlay(TOWER,CSDDATA,REMPOS+13,2)
             end /* REMPOS > 0 */

          end /* ALTER = YES */
          queue CSDDATA
          say CSDDATA
        end /*             */
     end /* j = 1 to csdin.0 */
  say 'CSDEDIT: End of CSDIN'
  say 'CSDEDIT:' memcount ' members processed'
  queue ''
  'execio * diskw csdout (finis'
  exit(rc)
