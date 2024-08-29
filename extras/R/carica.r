args = commandArgs(trailingOnly=TRUE)

fname = args

# fname <- "/home/seb/uploaded/ragazzi.xlsx"

print(fname);


library(dplyr);
library(readxl);
library(stringr);
library(tidyr);


df <- read_excel(fname)
names(df) <- tolower(names(df))

names(df) <- str_replace_all(names(df), c(" " = "_" , "," = "_" ))

if("fascia_età" %in% colnames(df))
{
  colnames(df)[colnames(df) == 'fasciaetà'] <- 'target_lettura'
}

if("codiceean" %in% colnames(df))
{
  colnames(df)[colnames(df) == 'codiceean'] <- 'ean'
}

if("isbn" %in% colnames(df))
{
  colnames(df)[colnames(df) == 'isbn'] <- 'ean'
}


sigle <- c('a','b','d','e','f','h','i','l','m','n','q','s','v','z','mar','ci','y','gin','bel','mus')  # maiuscolo

colnames(df)[colnames(df) %in% sigle] <- toupper(sigle) #cambia nomi in maiuscolo

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
      siglebib = paste(dsplt[[i]]$key, collapse = ', ')
    )
  } 
  
  mrg <- dati %>% left_join(bind_rows(res), by = "id.for.merge") %>% dplyr::select(-id.for.merge)
  
  if (remove.sigle==T) {
    mrg <- mrg[colnames(mrg) %in% nomi.colonne == F]
  }
  
  return(mrg)
}

df <- unisci_sigle(dati = df, nomi.colonne = toupper(sigle) )

if("siglebib" %in% colnames(df)) {
  
} else {
  df$siglebib <- ''
}

if("target_lettura" %in% colnames(df)) {
  
} else {
  df$target_lettura <- ''
}


if("id_ordine" %in% colnames(df)) {
  
} else {
  df$id_ordine <- ''
}

if("fornitore" %in% colnames(df)) {
  
} else {
  df$fornitore <- ''
}


if("reparto" %in% colnames(df)) {
  colnames(df)[colnames(df) == 'reparto'] <- 'reparto'
} else {
  df$reparto <- 'nessuno'
}

if("sottoreparto" %in% colnames(df)) {
  colnames(df)[colnames(df) == 'sottoreparto'] <- 'sottoreparto'
} else {
  df$sottoreparto <- 'nessuno'
}

if("datapubblicazione" %in% colnames(df)) {
} else {
  df$datapubblicazione <- 'NULL'
}

df$note = paste(df$annotazioni_1,';',df$annotazioni_2)



f <- subset(df, select=c(ean, autore, titolo, editore, collana, prezzo, siglebib, target_lettura, reparto, sottoreparto, datapubblicazione, fornitore, id_ordine, note))

print(names(df))
print(names(f))

outfile <- paste(tools::file_path_sans_ext(fname),'.csv',sep = '')

#write.table(f, file = outfile, append = FALSE, quote = TRUE, sep = ",",
#            eol = "\n", na = "NULL", dec = ".", row.names = FALSE,
#             col.names = TRUE, qmethod = c("escape", "double"),
#            fileEncoding = "UTF-8")

write.table(f, file = outfile, append = FALSE, quote = TRUE, sep = ",",
            eol = "\n", na = "NULL", dec = ".", row.names = FALSE,
            col.names = TRUE, qmethod = c("double"),
            fileEncoding = "UTF-8")

