class SpBibliography < ActiveRecord::Base
  self.table_name='sp.sp_bibliographies'

  has_many :sp_sections, :foreign_key=>'bibliography_id'
  has_many(:toplevel_sections, :class_name=>'SpSection',
           :foreign_key=>'bibliography_id', :conditions=>'parent=0',
           :order=>'sortkey')

  has_many :sp_items, :foreign_key=>'bibliography_id'
  
  def description_html
    return '' if self.description.nil?
    SpBibliography.latex_html(self.description)
  end

  def SpBibliography.latex_html(src)
    tf = Tempfile.new("import", File.join(Rails.root.to_s, 'tmp'))
    #tempdir=tf.path
    #tempfile=tf.path + ".tex"


    tempfile = ""
    basename = "xyz"
    workdir  = "/tmp"
    outdir   = File.join(workdir, basename)
    puts "outdir: #{outdir}"
    tempfile = File.join(workdir, "#{basename}.tex")
    puts tempfile

    # tempfile="/tmp/templatex.tex"
    fdout=File.open(tempfile,'w')

    # src.gsub!("", "\\b")
    #src.gsub!("begin", "\n\\begin")
    #src.gsub!("item", "\n\\item")
    #src.gsub!("end", "\n\\end")
    # src.gsub!("", "\n")
    src.gsub!("B_A_C_K_S_L_A_S_Hrm", "\\\\rm")
    src.gsub!("B_A_C_K_S_L_A_S_Hr", "\n")
    src.gsub!("B_A_C_K_S_L_A_S_H", '\\\\')
    fdout.write(src)
    fdout.close

    cmd = "/usr/bin/latex2html -lcase_tags #{tempfile} > /dev/null 2>/dev/null"
    puts cmd
    Kernel.system(cmd)
    data=File.read(File.join(outdir, 'index.html'))
    i=data.index("<!--End of Navigation Panel-->")+30
    x=data.index("<!--Table of Child-Links-->")-1
    data[i..x]
  end


  def SpBibliography.latex_html_old(src)
    res=[]
    level=0
    src.gsub!("\b", "\\b")
    src.gsub!("\medskip", "")

    src.split("\r").each do |l|
      # puts "l: #{l}"
      case
      when l=="m"
      when /^m (.*)/ =~ l
        res << $1

      when /^\it (.*)/ =~ l
        res << "<span style='font-style: italic'>#{$1}</span>"

      when /parindent/ =~ l
        # res << "<br/>PARINDENT"

      when /par(.?)/ =~ l
        res << "<br/>#{$1}"

      when /^ewpage/ =~ l
        res << "<br/>"

      when /enterline\{(.*)\}/ =~ l
        # res << "CENTRA LINEA (#{$1})"

      when l=="\\begin{itemize}"
        level+=1
        res << "<ul>"
      when l=="end{itemize}"
        level-=1
        res << "</ul>"
      when /^item (.*)/ =~ l
        res << "<li>#{$1}</li>"
      when l==''
        # res << "<pre>\n</pre>"
      else
        res << l

      end
    end
    res.join(' ')
  end
end
