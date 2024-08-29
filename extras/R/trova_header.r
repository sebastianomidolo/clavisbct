trova.header <- function(data, deve.contenere=c('autore','titolo')) {
    k=1
    while (k>0) {
	if(k == (nrow(data) + 1)) {
	    stop('Ricerca fallita. Nessun match trovato.')
	}
	# print(paste("riga: ", data[k,]))
	# print(paste("Stringa da controllare: ", data[k,] %>% as.vector %>% unlist %>% unname %>% tolower))
	string2test <- data[k,] %>% as.vector %>% unlist %>% unname %>% tolower   #trasforma in stringa
	tst <- string2test %in% deve.contenere %>% table() %>% data.frame() %>% setNames(c('tstv','freq'))
    	if (nrow(tst)==1) {
	    k = k +1
	} else {
	    mtch.tst = tst %>% filter(tstv==TRUE) %>% pull(freq)
	    if(mtch.tst == length(deve.contenere)) {
		rslt <- k
		k = 0
	    } else {
		k = k +1
	    }
	}
    }
    # print(paste("In trova_header, rslt = ", rslt))
    return(rslt)
}

unisci_sigle <- function(dati, nomi.colonne, remove.sigle=T) {
  
    dati$id.for.merge <- as.character(1:nrow(dati))
  
    d <- dati %>% 
	gather("key","val",all_of(nomi.colonne)) %>%
	filter(val >= 1) 
    dsplt <- split(d, as.character(d$id.for.merge)) 
  
    res <-list()
    for (i in 1:length(dsplt)) {
	res[[i]] <- data.frame(
	    id.for.merge = names(dsplt)[i], 
	    siglebib = paste(dsplt[[i]]$key, collapse = ',')
	)
    } 
  
    mrg <- dati %>% left_join(bind_rows(res), by = "id.for.merge") %>% dplyr::select(-id.for.merge)
  
    if (remove.sigle==T) {
	mrg <- mrg[colnames(mrg) %in% nomi.colonne == F]
    }
  
    return(mrg)
}


