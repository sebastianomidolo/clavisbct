CREATE OR REPLACE FUNCTION public.espandi_collocazione(text) returns text AS
  'set r $1
   set tmp [set res ""]
   foreach v [split $r ".-/"] {
    lappend tmp [string trim $v]
   }
   if { [string is alpha [lindex $tmp 1]] && [string is alpha [lindex $tmp 3]] } {
     set tmp [linsert $tmp 3 ""]
   }
   foreach v [split $tmp] {if {$v=="{}"} {set v ""}; append res [format "%04s" $v]}
   return $res
' language pltcl IMMUTABLE RETURNS NULL ON NULL INPUT;

SELECT espandi_collocazione('BCT.1.A.5-7');

SELECT espandi_collocazione('BCT.DVD.9');
SELECT espandi_collocazione('BCT.DVD.245');
