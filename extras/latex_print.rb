# lastmod 20 febbraio 2013

module LatexPrint
  class PDF
    attr_accessor :latexcmd, :compile
    def initialize(name)
      @template=File.join(Rails.root.to_s,'extras','latex_templates',"#{name}.tex.erb")
    end
    
    def read_template
      File.read(@template)
    end

    def latexcmd
      "/usr/bin/pdflatex"
    end

    def make_pdf(texdata)
      tempdir = File.join(Rails.root.to_s, 'tmp', 'latex')
      tf = Tempfile.new("latex",tempdir)
      tex_file=tf.path + ".tex"
      pdf_file=tf.path + ".pdf"
      aux_file=tf.path + ".aux"
      log_file=tf.path + ".log"
      fd = File.open(tex_file, "w")
      fd.write texdata
      fd.close
      # print "pdf_file: #{pdf_file}\n"
      # print "tex_file: #{tex_file}\n"
      Kernel.system(self.latexcmd, '-interaction=batchmode', "-output-directory=#{tempdir}", tex_file)
      x=eval("`/usr/bin/file #{pdf_file}`")
      errors=[]
      if (/PDF document/ =~ x).nil?
        # puts "non pdf"
        x=x.split(':').last
        data = "errore TeX: #{x}"
      else
        # puts "OK pdf"
        fd = File.open(pdf_file)
        data = fd.read
        fd.close
        fd = File.open(log_file)
        logdata=fd.read
        fd.close
        logdata.each_line do |l|
          errors << l if (/^! / =~ l)==0
        end
      end
      # cancello i files creati da tex
      path = tf.path
      tf.close(true)
      Dir::glob("#{path}*").each do |f|
        # puts "cancello " << f
        File.delete f
      end
      if errors.size>0
        fd = File.open(log_file, "w")
        fd.write(errors.join)
        fd.close
      end
      return data
    end


  end
end
