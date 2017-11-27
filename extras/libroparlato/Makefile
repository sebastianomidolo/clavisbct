pdf_files = ultimi-libri-parlati.pdf \
            libri-parlati-scaricabili.pdf \
            libri-parlati-cd.pdf \
            libri-parlati-completo.pdf

all: $(pdf_files)

WGET=/usr/bin/wget
URL=https://clavisbct.comperio.it/talking_books
htmlparams=htmloutput=yes

libri-parlati-scaricabili.html: params = digitalized=yes
ultimi-libri-parlati.html: params = type=novita&mesi=12
libri-parlati-cd.html: params = cdmp3=yes
libri-parlati-completo.html: params = completo=yes

%.html: /home/seb/BCT/wca22014/linux64/LP2mog/catalogo.mdb
	$(WGET) -O $@ "$(URL)?$(htmlparams)&$(params)&filename=$@"

%.pdf: %.html
	/usr/bin/libreoffice --headless --convert-to pdf $<

clean:
	rm -fv *.pdf *.html
