/* rexx */

/* Rexx exec to run Endevor API to list stages and build      */
/* a graphic version of the endevor lifecycle                 */

address ISPEXEC

/* Set a simple message text here */
GMSG1 = " "
GMSG2 = "Welcome to Endevor"
GMSG3 = " "

/* Then draw a pretty box around it and save it in the THUMBx
   Variables so it can be displayed...
   */

/* Decide on drawing character set to use                       */
"VGET (ZTERM QEPEVNME VAREVNME) ASIS"   /* get term & ENV Names */

/* set drawing chrs according to terminal type */
select
   when ZTERM = "3278T" then do /* If we have Text Drawing Chrs */
      TL = 'AC'x                   /* Top Left         Ð      */
      TM = 'CC'x                   /* Top middle       ö      */
      TR = 'BC'x                   /* Top Right        ¯      */
      MR = 'EB'x                   /* Mid Left         Ô      */
      MM = '8F'x                   /* Mid Mid          ±      */
      MR = 'EC'x                   /* Mid Right        Ö      */
      BL = 'AB'x                   /* Bot Left         ¿      */
      BM = 'CB'x                   /* Bot middle       ô      */
      BR = 'BB'x                   /* Bot Right        ¨      */
      HL = 'BF'x                   /* Horizontal Line  ×      */
      VL = 'FA'x                   /* Vertical Line    ³      */
      AR = '6E'x                   /* Arrow Right      >      */
      AU = 'EF'x                   /* Arrow Up         Õ      */
   end
   otherwise do
      TL = '+'                     /* Top Left         +      */
      TM = '+'                     /* Top middle       +      */
      TR = '+'                     /* Top Right        +      */
      MR = '+'                     /* Mid Left         +      */
      MM = '+'                     /* Mid Mid          +      */
      MR = '+'                     /* Mid Right        +      */
      BL = '+'                     /* Bot Left         +      */
      BM = '+'                     /* Bot middle       +      */
      BR = '+'                     /* Bot Right        +      */
      HL = '-'                     /* Horizontal Line  -      */
      VL = '|'                     /* Vertical Line    |      */
      AR = '>'                     /* Arrow Right      >      */
      AU = "'"                     /* Arrow Up         '      */
   end
end


/* Prepare for display each "line" is 45 characters wide, just concat... */
/* First draw the text useing the appropriate drawing symbols */
THUMBA = copies(' ',15)||TL||copies(HL,23)   ||TR||copies(' ',05) ,
      || copies(' ',15)||VL||center(GMSG1,23)||VL||copies(' ',05),
      || copies(' ',15)||VL||center(GMSG2,23)||VL||copies(' ',05),
      || copies(' ',15)||VL||center(GMSG3,23)||VL||copies(' ',05),
      || copies(' ',15)||BL||copies(HL,23)   ||BR||copies(' ',05)

/* Then add the SHADOW chars to change the colours */
THUMBS = copies(' ',45)  ,
      || copies(' ',16)||COPIES('P',23)||copies(' ',06),
      || copies(' ',16)||COPIES('P',23)||copies(' ',06),
      || copies(' ',16)||COPIES('P',23)||copies(' ',06),
      || copies(' ',45)

/* Finally store the updated variables for display */
address ispexec "VPUT (THUMBA,THUMBS) PROFILE"

return

/* Call Endevor API */
