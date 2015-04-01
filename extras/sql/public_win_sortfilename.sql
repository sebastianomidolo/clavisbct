CREATE OR REPLACE FUNCTION public.win_sortfilename(text) returns text AS
  'set i [regexp "\\\\((\\\\d*)\\\\)" "$1" x num]
   if {$i==0} {
     return $1
   } else {
     set res ""
     set l [split $1 "/"]
     set l [lreplace $l end end]
     foreach v $l {
       lappend res $v
     }
     return "[join $res "/"]/[format %04s $num]"
   }
' language pltcl IMMUTABLE RETURNS NULL ON NULL INPUT;


select win_sortfilename('libroparlato/cd mp/mp 268 - ronchi della rocca - la vera eleganza/traccia (28).mp3');

