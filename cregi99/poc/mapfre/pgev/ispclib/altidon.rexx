/*-REXX to allocate the alternate ID ---------------------------*/

 /* Get the userid from storage                     */
 ascb      = c2x(storage(224,4))
 asxb      = c2x(storage(d2x(x2d(ascb)+108),4))
 acee      = c2x(storage(d2x(x2d(asxb)+200),4))
 asxbuser  =     storage(d2x(x2d(asxb)+192),8)
 /* Switch to alternate userid (ENDEVOR)             */
 'alloc f(lgnt$$$i) dummy'
 'alloc f(lgnt$$$o) dummy'
 'execio * diskr LGNT$$$I (finis'
 /* Get the userid from storage again (should be ENDEVOR) */
 asxbuser  =     storage(d2x(x2d(asxb)+192),8)
return asxbuser
