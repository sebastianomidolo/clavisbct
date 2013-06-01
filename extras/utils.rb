
def regexp_collocazione(tipologia)
  case tipologia
  when 'libroparlato'
    /(NA|NB|NT|MP) +((\d+)[ -]|(\d+$))/
  when 'cdmusicale'
    # /((\w+)\.[A-Z]\.(\w+))/
    /((\w+)\.(\w+)\.(\w+))/
  else
    raise "tipologia #{tipologia} sconosciuta"
  end
end

def collocazione?(tipologia,fname)
  x = regexp_collocazione(tipologia) =~ fname
  x.nil? ? false : true
end

def get_collocation(tipologia,fname)
  # puts "tipologia: #{tipologia} =>'#{fname}'"
  regexp_collocazione(tipologia) =~ fname
  case tipologia
  when 'libroparlato'
    if $1=='MP'
      p="CD MP"
    else
      p=$1
    end
    num=$2.to_i
    "#{p} #{num}"
  when 'cdmusicale'
    return nil if $1.blank?
    "BCT.#{$1}"
  else
    nil
  end
end


