/* Rexx to download all MAPFRE Files */
'zowe zos-files download data-sets-matching "CREGI99.POC.MAPFRE.**" --exclude-patterns "**.XMIT*" --extension-map ISPCLIB=rexx,REXX=rexx,ISRCLIB=rexx,CLIST=rexx,ISPSLIB=jcl,CSIQCLS0=rexx,CSIQSENU=jcl'
