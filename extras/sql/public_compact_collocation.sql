CREATE OR REPLACE FUNCTION public.compact_collocation(text,text,text,text,text) returns text AS
  '
   set res {}
   set a [string trim $1]
   set b [string trim $2]
   set c [string trim $3]
   set d [string trim $4]
   set e [string trim $5]
   if {$a!=""} {lappend res $a}
   if {$b!=""} {lappend res $b}
   if {$c!=""} {lappend res $c}
   if {$d!=""} {lappend res $d}
   if {$e!=""} {lappend res $e}
   return [join $res "."]
' language pltcl IMMUTABLE;

select public.compact_collocation("section",collocation,specification,sequence1,sequence2) as collocazione,
  "section",collocation,sequence1,sequence2,specification,item_id
 from clavis.item where specification notnull and sequence1 != '' and sequence2 != ''
  and owner_library_id=2 limit 10;


