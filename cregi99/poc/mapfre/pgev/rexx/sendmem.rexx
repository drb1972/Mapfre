/* rexx - To read saslist                                    */
/*                                                           */
  /*                                                           */
  /*  Address for transmit                                     */
  /*                                                           */
      xmitaddr = 'RCJESX.ENDEVOR'

  /*  Read MXGREP                                              */
  /*                                                           */
      "execio * diskr MXGREP (stem saslist. finis"
      if rc > 0 then exit(13) ;
      say saslist.0 'Records read from MXGREP'

  /*  If more than 0 records write the output                  */
  /*                                                           */
      if saslist.0 > 0 then do
        "execio * diskw saslist (stem saslist. finis"
        if rc > 0 then exit(41) ;
        say saslist.0 'Records written to saslist'
      end /*  saslist */


  /*  Loop through saslist and find messages                   */
  /*                                                           */
      do m = 1 to saslist.0

         smftime    = word(saslist.m,1)
         lglib      = word(saslist.m,2)
         lgmem      = word(saslist.m,3)
         lgtyp      = word(saslist.m,4)
         lguser     = word(saslist.m,5)
         lgvol      = word(saslist.m,6)

         dsnquals = translate(lglib,' ','.')

         hlq     = word(dsnquals,1)
         mlq     = word(dsnquals,2)
         stage   = substr(mlq,1,1)
         sys     = substr(mlq,2,2)
         subsys  = substr(mlq,2,3)

         select

         when lgtyp = 'Z:BND' then do

            trigger = ,
               smftime ,
               'EBINDIT'   ,
               lguser     ,
               lglib

               say   trigger
               queue trigger

         end /* Z:BND    */

         when lgtyp = 'D:DEL' then do

            trigger = ,
               smftime ,
               'EDELMEM'   ,
               lguser      ,
               lglib       ,
               lgmem

               say   trigger
               queue trigger

         end /* D:DEL    */

         otherwise do

            trigger = ,
               smftime ,
               'ECPYMEM' ,
               lguser     ,
               lglib      ,
               lgmem

               say   trigger
               queue trigger
          end /* otherwise */
         end /* select  */

      end /*  loop throug saslist */

      if queued() > 0 then do
        'alloc fi(EEEE)' ,
        'unit(vio) space(1 1) track recfm(f b) lrecl(80) new'
        'execio * diskw EEEE (finis'
        "transmit" xmitaddr ,
        "msgddname(EEEE) nolog" /* logdsname('"sysdsname"')" */
        'free fi(EEEE)'
      end /* queued() > 0 */

  exit(0)
