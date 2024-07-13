/*-REXX to de-allocate the alternate ID ------------------------*/
 'execio * diskr LGNT$$$O (finis'
 'free f(LGNT$$$I)'
 'free f(LGNT$$$O)'
 ascb      = c2x(storage(224,4))
 asxb      = c2x(storage(d2x(x2d(ascb)+108),4))
 acee      = c2x(storage(d2x(x2d(asxb)+200),4))
 asxbuser  =     storage(d2x(x2d(asxb)+192),8)
return asxbuser
