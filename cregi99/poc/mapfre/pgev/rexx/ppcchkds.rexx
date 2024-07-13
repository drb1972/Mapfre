/********************************************************************/
/* Issue the SYSDSN() to see if the dataset exists                  */
/********************************************************************/
checkdsn:
  arg lvl dsn
  address ISPEXEC
  "VGET (ERRMSGS WARNMSGS)"
  cc = 0
  if dsn = '' then return cc
  dsn = "'"strip(dsn)"'"
  dsnok = sysdsn(dsn)
  if dsnok ^= 'OK' then do
    call ppclogw left(lvl,7) ':' left(dsnok,18) dsn
    if result = 99 then exit 99
    select
      when lvl = 'ERROR'   then do
        errmsgs = errmsgs + 1
        cc = 16
      end
      when lvl = 'WARNING' then do
        warnmsgs = warnmsgs + 1
        cc = 04
      end
      otherwise
    end
  end
  "VPUT (ERRMSGS WARNMSGS)"
return cc
