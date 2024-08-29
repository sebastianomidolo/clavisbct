# -*- coding: utf-8 -*-
module LatexPrint
  class PDF
    attr_accessor :latexcmd, :texinput
    def initialize(name, inputdata=[], replace_amp=true)
      @template=File.join(Rails.root.to_s,'extras','latex_templates',"#{name}.tex.erb")
      erb = ERB.new(File.read(@template))
      begin
        @texinput = erb.result(binding)
      rescue
        raise "Errore in PDF::initialize con name='#{name}': #{$!}"
      end
      @texinput.gsub!("&", '\\\&') if replace_amp
      @texinput.gsub!("_", ' ')
      @texinput.gsub!("«", '``')
      @texinput.gsub!("»", "''")
      @texinput.gsub!('<', '$<$')
      @texinput.gsub!('>', '$>$')
    end

    def latexcmd
      "/usr/bin/pdflatex"
    end

    def makepdf(times=1)
      tempdir = File.join(Rails.root.to_s, 'tmp', 'latex')
      tf = Tempfile.new("latex",tempdir)
      tex_file=tf.path + ".tex"
      pdf_file=tf.path + ".pdf"
      aux_file=tf.path + ".aux"
      log_file=tf.path + ".log"
      fd = File.open(tex_file, "w")
      fd.write @texinput
      fd.close
      # print "pdf_file: #{pdf_file}\n"
      # print "tex_file: #{tex_file}\n"

      fd=File.open(File.join(tempdir,'current_texfile.tex'),'w')
      fd.write(@texinput)
      fd.close

      x=''
      while(times>0) do
        times-=1
        Kernel.system(self.latexcmd, '-interaction=batchmode', "-output-directory=#{tempdir}", tex_file)
        x=eval("`/usr/bin/file #{pdf_file}`")
      end
      errors=[]
      if (/PDF document/ =~ x).nil?
        # puts "non pdf"
        # x=x.split(':').last
        # puts "errore TeX: #{x.inspect}"
        data="Errore in makepdf: #{x.inspect}"
      else
        # puts "OK pdf"
        fd = File.open(pdf_file)
        data = fd.read
        fd.close
      end
      fd=File.open(File.join(tempdir,'current_logfile.log'),'w')
      fd.write(File.read(log_file))
      fd.close

      # cancello i files creati da tex
      path = tf.path
      tf.close(true)
      Dir::glob("#{path}*").each do |f|
        # puts "cancello " << f
        File.delete f
      end

      #if errors.size>0
      #  fd = File.open(log_file, "w")
      #  fd.write(errors.join)
      #  fd.close
      #end
      return data
    end


  end
end
