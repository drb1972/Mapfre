/*REXX */
arg element system subsys type stage
trace o

"EXECIO * DISKR BSTRPTS (STEM LINE. FINIS)"

do A=1 to line.0
   if word(line.a,1) = 'LIBRARY:' then dsn = word(line.a,2)

   Call format_record

                                 /* ------------------------------- */
   if ele.a = element then do    /* only process further if element */
     if sub.a ^= subsys then do  /* matches and subsystem does'nt   */
                                 /* ------------------------------- */

    /* If the target stage is PROD or the footprint is for a backed */
    /* out element, then terminate with return code zero            */
       if stage = 'P' | mem.a ^= element  then exit 0
                                          else Call Write_README

        end /* sub.a ^= subsys */
        else exit 0

     end /* ele.a = element */
end /* end do */

exit 0

format_record:
parse var line.a 2  mem.a ,
                 23 env.a ,
                 33 sys.a ,
                 43 sub.a ,
                 53 ele.a ,
                 65 typ.a ,
                 73 .
return

Write_README:
queue
queue "  THE COMMON COPYBOOK '"element"' ALREADY EXISTS" ,
      "IN THE LIBRARY"
queue " " dsn "AND HAS COME FROM SUBSYSTEM" sub.a
queue
queue "  YOU CANNOT OVERWRITE THAT MEMBER."
queue
queue "  ANY QUESTIONS CALL +44 (0)123 963 8560"
queue
"execio" queued() "diskw README (finis"
exit 20
return
