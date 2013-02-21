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

SELECT espandi_collocazione('BCT.1.A.5-7');
SELECT espandi_collocazione('BCT.DVD.9');
SELECT espandi_collocazione('BCT.DVD.245');
