/** rexx ********************************************************/
/*                                                              */
/*      //STEP01   EXEC PGM=IRXJCL,                             */
/*      // PARM='EVAPICHK'                                      */
/*      //SYSEXEC  DD DISP=SHR,dsn=pds.with.this.rexx.in        */
/*      //SYSTSPRT DD SYSOUT=*                                  */
/*      //SCANIN   DD ...                                       */
/*      //MESSAGE  DD ...                                       */
/*                                                              */
/* THIS REXX SCANS FOR RETURNED COUNT=      in FILE SCANIN      */
/*                                                              */
/* IF "RETURNED COUNT ="  NOT FOUND THEN EXIT RC=12             */
/* IF "RETURNED COUNT =0" THEN EXIT RC=0                        */
/* IF "RETURNED COUNT =" NE 0 THEN EXIT RC=8                    */
/*                                                              */
/****************************************************************/
  trace n
  say 'EVAPICHK: ' DATE() TIME()
  parse arg none
  say  'EVAPICHK:'

  maxrc = 12

  call scanloop

  if maxrc = 8 then
     call readme
  say 'EVAPICHK: COMPLETED rc='maxrc
  exit maxrc

readme:
  "execio * diskr message (stem data. finis"
      if rc > 0 then exit(30) ;
  "execio * diskw README (stem data. finis"
  if rc > 0 then exit(40) ;
return
scanloop:
/******************************************************************/
/* Loop through the SCANIN  looking for targets                   */
/******************************************************************/
  do until readrc = 2          /* loop til you just cant loop no more */
    "execio 1 diskr scanin  "  /* read 1 line                         */
    readrc = rc                /* return code from execio             */
    pull scanin                /* store scanin  line                  */
    if pos('RETURNED COUNT=',scanin) > 0 then do   /* FOUND A RESULT  */
       maxrc = 8                                   /* RETURN COUNT ANY*/
       say 'EVAPICHK:' scanin
       if pos('RETURNED COUNT=00000',scanin) > 0 then do
         maxrc = 0                                 /* RETURN COUNT 0  */
         leave                                     /* GET OUT         */
      end /* RETURNED COUNT=0 */
      leave                                        /* GET OUT         */
    end   /* RETURNED COUNT=  */
  end  /* End of pass through the pdsmrpt */
return
