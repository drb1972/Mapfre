/* Rexx------------------------------------------------------------+ */
/* |                                                               | */
/* | This Rexx is used by the GLINK processor to check the         | */
/* | processor group will not cause listing failures.              | */
/* |                                                               | */
/* | The LNKBSUB & LNKCSUB type are not processed in GLINK so they | */
/* | are not catered for in this routine.                          | */
/* |                                                               | */
/* | Date     : March 2009                                         | */
/* |                                                               | */
/* | Sample JCL is in processor GLINK.                             | */
/* |                                                               | */
/* +---------------------------------------------------------------+ */
trace n

parse arg cur_elt_c1ty cur_elt_c1prgrp

cur_elt_pglast = right(cur_elt_c1prgrp,1)

/* set the exit cc if there are no errors found */
cc = 0

/* Set up the recommend processor group positon 8 character          */
lnkb.lstlet = 'K'
lnkc.lstlet = 'X'
lnkp.lstlet = 'B'

say 'LNKCHECK:'
say 'LNKCHECK: Processing request for Type' cur_elt_c1ty
say 'LNKCHECK:             Processor Group' cur_elt_c1prgrp
say 'LNKCHECK:'

/* Read in the API output                                            */
/* LIST element &c1element from c1si build using map                 */
"execio * diskr INFILE (stem infile. finis"
if rc ^= 0 then call exception 12 'DISKR from INFILE failed RC='rc

do i = 1 to infile.0

  /* Get the environment */
  c1en = substr(infile.i,15,8)
  c1en = strip(c1en)

  /* Get the system */
  c1sy = substr(infile.i,23,8)
  c1sy = strip(c1sy)

  /* Get the subsystem */
  c1su = substr(infile.i,31,8)
  c1su = strip(c1su)

  /* Get the element name */
  c1el = substr(infile.i,39,10)
  c1el = strip(c1el)

  /* Get the type */
  c1ty = substr(infile.i,49,8)
  c1ty = strip(c1ty)

  /* Get the stage id */
  c1si = substr(infile.i,65,1)
  c1si = strip(c1si)

  /* Get the processor group */
  c1pg = substr(infile.i,71,8)
  c1pg = strip(c1pg)

  /* Get the last character of the processor group */
  pglast = right(c1pg,1)

  say 'LNKCHECK: Found element' c1el 'at' c1en'/'c1sy'/'c1su'/'c1si
  say 'LNKCHECK: of type' c1ty 'with processor group' c1pg
  say 'LNKCHECK:'

  /* Just establish if it is an unknown type */
  select

    when c1ty = 'LNKB' then nop
    when c1ty = 'LNKC' then nop
    when c1ty = 'LNKP' then nop
    when c1ty = 'LNKK' then nop
    when c1ty = 'LNKA' then nop
    when c1ty = 'LNKBSUB' then nop
    when c1ty = 'LNKCSUB' then nop

    otherwise do
      queue 'LNKCHECK: !!!!!! Warning !!!!!!'
      queue 'LNKCHECK:'
      queue 'LNKCHECK: Unknown type' c1ty
      queue 'LNKCHECK:'
      queue 'LNKCHECK: !!!!!! Warning !!!!!!'
      "execio "queued()" diskw readme (finis)"
      if rc ^= 0 then call exception 12 'DISKW to README failed RC='rc
      exit 12
    end /* otherwise do */

  end /* end select */

  if c1ty = 'LNKBSUB' then iterate /* GLINKCJ handles the LNKBSUB type */

  if c1ty = 'LNKCSUB' then iterate /* GLINKCJ handles the LNKCSUB type */

  if c1pg = 'DEFAULT' then iterate /* no check when procgrp = DEFAULT */

  if c1ty = cur_elt_c1ty then iterate /* no check when the types are */
                                      /* the same                    */
  else do

    if c1ty = 'LNKB' & pglast ^= 'K' then do
      lstlet = value(c1ty'.lstlet')
      newgrp = left(c1pg,7)||lstlet

      call readme 'LNKB' cur_elt_c1ty /* Build the README statements*/

      cc = 8
    end /* if c1ty = 'LNKB' & pglast ^= 'K' then do */

    if c1ty = 'LNKC' & pos(pglast,'XM') = 0 then do
      lstlet = value(c1ty'.lstlet')
      newgrp = left(c1pg,7)||lstlet

      call readme 'LNKC' cur_elt_c1ty /* Build the README statements*/

      cc = 8
    end /* if c1ty = 'LNKC' & pos(pglast,'XM') = 0 */

    if (c1ty = 'LNKC' & pglast = 'X') & ,
       (cur_elt_pglast = 'X')         then do
      lstlet = value(cur_elt_c1ty'.lstlet')
      newgrp = left(cur_elt_c1prgrp,7)||lstlet

      call readme cur_elt_c1ty 'LNKC' /* Build the README statements*/

      cc = 8
    end /* if c1ty = 'LNKC' & pos(pglast,'XM') = 0 */

    if c1ty = 'LNKP' & pglast ^= 'B' then do
      lstlet = value(c1ty'.lstlet')
      newgrp = left(c1pg,7)||lstlet

      call readme 'LNKP' cur_elt_c1ty /* Build the README statements*/

      cc = 8
    end /* if c1ty = 'LNKP' & pglast ^= 'B' then do */
  end /* else do */

end /* do i = 1 to infile.0 */

"execio "queued()" diskw readme (finis)"
if rc ^= 0 then call exception 12 'DISKW to README failed RC='rc

exit cc

/*---------------------- S U B R O U T I N E S ----------------------*/

/*---------------------------------------------------------------*/
/* queue messages for the output                                 */
/*---------------------------------------------------------------*/
readme:
arg regen_c1ty alt_c1ty

if substr(newgrp,4,1) = 'X' then
  newgrp = overlay('M',newgrp,4)

queue 'LNKCHECK: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
queue 'LNKCHECK:'
queue 'LNKCHECK: It is not possible to process element' c1el
queue 'LNKCHECK: of type' cur_elt_c1ty 'as there is an element of type'
queue 'LNKCHECK:' c1ty 'with the same name. This' c1ty 'element is'
queue 'LNKCHECK: located in' c1en'/'c1sy'/'c1su'/'c1si
queue 'LNKCHECK:'
queue 'LNKCHECK: Having two LNK* elements of the same name means that'
queue 'LNKCHECK: their Endevor listing names will conflict.'
queue 'LNKCHECK:'
queue 'LNKCHECK: The processor group' c1pg 'for type' regen_c1ty 'should'
queue 'LNKCHECK: have a' lstlet 'in position 8 so that the listing is not'
queue 'LNKCHECK: overwritten. The processor group should actually'
queue 'LNKCHECK: be.....'newgrp
queue 'LNKCHECK:'
queue 'LNKCHECK: The correct source code is now in Endevor, please do NOT'
queue 'LNKCHECK: delete/add/update the source code any further.'
queue 'LNKCHECK:'
queue 'LNKCHECK: Please GENERATE element' c1el 'of type' regen_c1ty
queue 'LNKCHECK: but specify processor group' newgrp
if regen_c1ty ^= cur_elt_c1ty then
  queue 'LNKCHECK: in the same stage as the' alt_c1ty 'element'
queue 'LNKCHECK:'
queue 'LNKCHECK: The GENERATE action is the only way to resolve this'
queue 'LNKCHECK: issue.'
queue 'LNKCHECK:'
if regen_c1ty ^= cur_elt_c1ty then do
  queue 'LNKCHECK: It is essential that you also promote' c1el 'of type'
  queue 'LNKCHECK:' alt_c1ty
  queue 'LNKCHECK:'
end  /* regen_c1ty ^= cur_elt_c1ty */
queue 'LNKCHECK: If' newgrp 'does not exist, please send an e-mail'
queue 'LNKCHECK: to VERTIZOS@kyndryl.com'
queue 'LNKCHECK: requesting the setup of the'
queue 'LNKCHECK: processor group' newgrp 'for type' regen_c1ty 'in system' c1sy
queue 'LNKCHECK:'
queue 'LNKCHECK: For further details on processor groups please'
queue 'LNKCHECK: refer to our website at'
queue 'LNKCHECK: http://www.manufacturing.rbs.co.uk/gtendevor/'
queue 'LNKCHECK: and look at the Processor Groups page in the'
queue 'LNKCHECK: reference information.'
queue 'LNKCHECK:'
queue 'LNKCHECK: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'

return

/*---------------------------------------------------------------*/
/* Error with line number displayed                              */
/*---------------------------------------------------------------*/
exception:
 parse arg return_code comment

 delstack                    /* Clear down the stack                 */

 parse source . . rexxname . /* Get the rexxname (generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
