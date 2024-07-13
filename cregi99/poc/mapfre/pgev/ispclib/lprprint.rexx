        /* ---------------------  rexx procedure  ---------------------- *
         * Name:      LPRPrint                                           *
         *                                                               *
         * Function:  Invoked by the user or via another ISPF dialog     *
         *            to invoke the LPRPRINT ISPF Panel and then use     *
         *            the TCP/IP LPR command to print the specified      *
         *            data set on a TCP/IP connected printer.            *
         *                                                               *
         *            Note that the specified Host must have LPD active  *
         *            to receive the data.                               *
         *                                                               *
         * Syntax:    %lprprint dsname                                   *
         *                                                               *
         *            dsname is optional                                 *
         *                                                               *
         * Author:    Lionel B. Dyck                                     *
         *            Kaiser Permanente Information Technology           *
         *            25 N. Via Monte Ave.                               *
         *            Walnut Creek, CA 94598                             *
         *            (925) 926-5332                                     *
         *            Internet: lionel.b.dyck@kp.org                     *
         *                                                               *
         * History:                                                      *
         *            03/20/97 - save inds in profile                    *
         *            01/10/95 - Remove ack as tcp/ip 3.1 doesn't        *
         *            08/29/94 - update for Postscript option            *
         *            06/23/94 - fix parse for pds dsname                *
         *            01/21/94 - fix for pds input w/member name         *
         *            01/18/94 - add support for member selection if     *
         *                       dsname is pds and no member given       *
         *            01/17/94 - fix for invalid dsn and for messages    *
         *            01/07/94 - add option for additional user specified*
         *                       parameters other than what is directly  *
         *                       supported                               *
         *            01/04/94 - add entry optional parameter of dsn     *
         *                       and support ACK option                  *
         *            01/03/94 - updated to cleanup invocation           *
         *            12/22/93 - creation of application                 *
         *                                                               *
         * ------------------------------------------------------------- */

         arg inds

         Address ISPEXEC

         do forever
           "VGET (lprdest lprhost lprbin lprcc lprntfy lprlcnt lprhead ",
                 "lprburst lprntfy lprps lpruopt lprpinds) Profile"
            if length(inds) > 0 then lprpinds = inds
            "Display Panel(LPRPRINT)"
            if rc > 3 then exit 0
           "VPUT (lprdest lprhost lprbin lprcc lprntfy lprlcnt lprhead ",
                 "lprburst lprntfy lprps lpruopt lprpinds) Profile"

         if sysdsn(lprpinds) <> "OK" then do
            lprsmsg = "Error"
            lprlmsg = "Specified data set does not exist:" lprpinds
            "Vput (lprsmsg lprlmsg)"
            "SETMSG MSG(LPR002)"
            end
         else do
              parse value "" with binary cc mail line_count header burst,
                             copies postscr
              if lprbin   = "Yes" then binary = "Binary"
              if lprcc    = "Yes" then cc     = "CC"
                                  else cc     = "NOCC"
              if lprntfy  = "Yes" then mail   = "Mail"
              if lprhead  = "No"  then header = "NoHeader"
              if lprburst = "No"  then burst  = "NoBurst"
              if lprcopy  > 1     then copies = "Copies" lprcopy
              if lprlcnt  > 0     then line_count = "Linecount" lprlcnt
              if lprps    = "Portrait"  then postscr = "Postscript"
              if lprps    = "Landscape" then postscr = "Landscape"

              x = listdsi(lprpinds)
              if pos("(",lprpinds) > 0 then sysdsorg = "PS"
              Select
                When sysdsorg = "PS" | pos("(",lprpinds) > 1
                     then call do_lpr lprpinds
                When sysdsorg = "PO"
                     then call do_pds
                Otherwise nop;
              end
              end
         end

         do_pds:
            "Lminit Dataid(dataid) Dataset("lprpinds") Enq(Shrw)"
            "Lmopen Dataid("dataid") Option(Input)"
            "Lmmdisp Dataid("dataid") Option(Display)",
              "Commands(Any) Panel(LPRPM)"
              do while rc == 0
                 Call process_selection
                "Lmmdisp Dataid("dataid") Option(Get)"
                 if rc == 8
                    then "Lmmdisp Dataid("dataid") Option(Display)",
                         "Commands(Any) Panel(LPRPM)"
              end
              "Lmmdisp Dataid("dataid") Option(Free)"
              "Lmclose Dataid("dataid")"
              "Lmfree  Dataid("dataid")"
            return

         process_selection:
            if left(lprpinds,1) = "'"
               then parse value lprpinds with "'" w_dsn "'"
               else w_dsn = sysvar("syspref")"."lprpinds
            zlmember = strip(zlmember)
            Select
            When zllcmd = "/" | zllcmd = "S"
            Then do
              "Lmmdisp Dataid("dataid") Option(Put) Member("zlmember")",
                  "Zludata(printed)"
              call do_lpr "'"w_dsn"("zlmember")'"
              end
            When zllcmd = "B"
            Then "Browse Dataid("dataid") Member("zlmember")"
            Otherwise nop;
            End
            return

         do_lpr:
            arg dsn
            Address TSO,
           "LPR" dsn "(Printer" lprdest "Host" lprhost "Type",
                 binary cc mail line_count header burst copies ,
                 postscr lpruopt
           if sysdsorg <> "PS" then return
           lprsmsg = ""
           lprlmsg = lprpinds "printed to" lprdest "at" lprhost
          "Vput (lprsmsg lprlmsg)"
          "SETMSG MSG(LPR002)"
           return
