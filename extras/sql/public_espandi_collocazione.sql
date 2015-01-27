CREATE OR REPLACE FUNCTION public.espandi_collocazione(text) returns text AS
  'set r $1
   set tmp [set res ""]
   foreach v [split $r ".-/"] {
    lappend tmp [string trim $v]
   }
   foreach v [split $tmp] {
      if [string is alpha $v] {
        lappend res [format "% 5s" $v]
      } else {
        lappend res [format "%06s" $v]
      }  
   } 
   return [join $res]
' language pltcl IMMUTABLE RETURNS NULL ON NULL INPUT;


CREATE OR REPLACE FUNCTION public.espandi_dewey(text) returns text AS
  'set r [split $1 "."]
   if {[lindex $r 2]==""} {
     return [join [linsert $r 1 "00000000"] "."]
   } else {
     set res ""
     set cnt 0
     foreach v [split $r] {
      set v [string trim $v]
       incr cnt
       if $cnt==1 {
         lappend res $v
         continue
       }
       if [string is alpha $v] {
         lappend res $v
       } else {
         lappend res [format "%08s" $v]
       }
     }
     return [join $res "."]
   }
' language pltcl IMMUTABLE RETURNS NULL ON NULL INPUT;
