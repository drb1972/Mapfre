/*rexx                                                               */
/* This common REXX routine checks the jobcard being                 */
/* used by an Endevor submission panel.                              */
/*                                                                   */
endjc.1 = translate(c1bjc1,' ',',') /* Remove commas from line 1     */
endjc.2 = translate(c1bjc2,' ',',') /* Remove commas from line 2     */
endjc.3 = translate(c1bjc3,' ',',') /* Remove commas from line 3     */
endjc.4 = translate(c1bjc4,' ',',') /* Remove commas from line 4     */

do a = 1 to 4

  if left(endjc.a,3) = '//*' then iterate /* ignore comment          */

  if pos('SYSAFF=',endjc.a) > 0 | ,
     pos(' S=',endjc.a) > 0 then do /* don't use sysaff              */
    zrxmsg = 'EVSU003E'
    zrxrc = 8
  end

  do b = 1 to words(endjc.a) /* loop each word on the line           */

    if left(word(endjc.a,b),5) = 'TIME=' then do
      zrxmsg = 'EVSU001E'
      zrxrc = 8
    end

    if left(word(endjc.a,b),8) = 'REGION=0' then do
      zrxmsg = 'EVSU002E'
      zrxrc = 8
    end

    if left(word(endjc.a,b),5) = 'PRTY=' then do
      zrxmsg = 'EVSU006E'
      zrxrc = 8
    end

    if left(word(endjc.a,b),6) = 'CLASS=' & ,
       right(word(endjc.a,b),1) ^= '3' then do

      zrxmsg = 'EVSU004E'
      zrxrc = 8
    end

  end /* do b = 1 to words(endjc1)                                   */

end /* do a = 1 to 4                                                 */

if word(endjc.1,3) ^= '0' then do /* check accounting info           */
  zrxmsg = 'EVSU005E'
  zrxrc = 8
end

if left(endjc.1,4) ^= '//TT' then do /* jobname begin with TT?       */
  zrxmsg = 'EVSU007E'
  zrxrc = 8
end

return
