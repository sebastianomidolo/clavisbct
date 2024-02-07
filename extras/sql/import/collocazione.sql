SET SEARCH_PATH TO import;

CREATE OR REPLACE FUNCTION collocazione(text,text,text,text,text) returns text AS
  'if {$1!=""} {lappend r $1} else {lappend r "BCT"}
   if {$2!=""} {lappend r $2}
   if {$3!=""} {lappend r $3}
   if {$4!=""} {lappend r $4}
   set res [string trimright [join $r "."] "."]
   if {$5!=""} {set res "$res $5"}
   return $res
' language pltcl IMMUTABLE;
