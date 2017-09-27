module TextSearchUtils
  def textsearch_sanitize(src)
    src.gsub!(/\:|&/,'')
    src.split.join(' & ')
  end
end
