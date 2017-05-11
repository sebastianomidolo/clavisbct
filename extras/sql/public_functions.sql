
CREATE OR REPLACE FUNCTION public.get_dirname(text) returns text AS
  'return [join [lreplace [split $1 /] end end] /]'
language pltcl IMMUTABLE RETURNS NULL ON NULL INPUT;


CREATE OR REPLACE FUNCTION public.get_basename(text) returns text AS
  'return [lindex [split $1 /] end]'
language pltcl IMMUTABLE RETURNS NULL ON NULL INPUT;
