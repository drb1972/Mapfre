 SIGNIN   ELEMENT "        "
)N        THROUGH "<THRUNAME>"
     FROM ENV     "        " STAGE NUM "1"
          SYS     "        " SUBSYSTEM "        " TYPE "        "
)N
)N USE "MD" LINE COMMANDS TO CONVERT REQUIRED OPTIONS TO VALID SCL
)N NOTE: WHERE KEYWORDS ARE GROUPED, PICK ONE LINE ONLY E.G. SPAN
)N
)N  OPTION
)N    OVERRIDE SIGNOUT
)N
)N    SIGNOUT TO <USERID>
)N
)N      SEARCH
)N      NOSEARCH
)N
)N  WHERE
)N    CCID
)N      OF CURRENT  EQUAL <CCID>
)N      OF ALL      EQ   (<CCID1>, <CCID2>, <CCID3>)
)N      OF RETRIEVE =     <CCID>
)N    PROCESSOR GROUP EQUAL <PG>
    .
