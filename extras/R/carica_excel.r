args = commandArgs(trailingOnly=TRUE)

fname = args

# fname <- "/home/seb/uploaded/ragazzi.xlsx"
print(fname);


# source(paste0(getwd(),'/',"extras/R/trova_header.r"))
source("/home/ror/clavisbct/extras/R/trova_header.r")

library(dplyr);
library(readxl);
library(stringr);
library(tidyr);

df <- read_excel(fname)
if("autore" %in% tolower(names(df))) {
    print("Esiste autore, presumo che le intestazioni di colonna siano in riga uno")
} else {
    print("Cerco la riga dell'header")
    df <- read_excel(fname, col_names = F)
    row.iniziale <- trova.header(data = df, deve.contenere=c('autore','titolo'))
    df <- df[row.iniziale:nrow(df) , ] 
    colnames(df) <- df[1,] %>% as.vector() %>% unlist() %>% unname()
    df <- df[-1,]
}
names(df) <- tolower(names(df))
df <- df[!is.na(names(df))]

names(df) <- str_replace_all(names(df), c(" " = "_" , "," = "_" ))

if("prezzo_cop" %in% colnames(df))
{
  colnames(df)[colnames(df) == 'prezzo_cop'] <- 'prezzo'
}

if("codiceean" %in% colnames(df))
{
  colnames(df)[colnames(df) == 'codiceean'] <- 'ean'
}

if("isbn" %in% colnames(df))
{
  colnames(df)[colnames(df) == 'isbn'] <- 'ean'
}

if("biblioteca" %in% colnames(df))
{
  colnames(df)[colnames(df) == 'biblioteca'] <- 'siglebib'
}


# sigle <- c('a','b','d','e','f','h','i','l','m','n','q','s','v','z','mar','ci','y','gin','bel','mus')  # versione prima della modifica di palumbo da gin a g
sigle <- c('a','b','d','e','f','h','i','l','m','n','q','s','v','z','mar','ci','y','g','bel','mus')

if("anno" %in% colnames(df)) {
  
} else {
    df$anno <- NA
}

if("a" %in% colnames(df)) {
    colnames(df)[colnames(df) %in% sigle] <- toupper(sigle) # cambia nomi in maiuscolo
    df <- unisci_sigle(dati = df, nomi.colonne = toupper(sigle) )	   
}

if("siglebib" %in% colnames(df)) {
  
} else {
  df$siglebib <- NA
}

if("target_lettura" %in% colnames(df)) {
} else {
  df$target_lettura <- NA
}

if("id_ordine" %in% colnames(df)) {
  
} else {
  df$id_ordine <- NA
}

if("fornitore" %in% colnames(df)) {
  
} else {
  df$fornitore <- NA
}

if("reparto" %in% colnames(df)) {
  colnames(df)[colnames(df) == 'reparto'] <- 'reparto'
} else {
  df$reparto <- NA
}

if("sottoreparto" %in% colnames(df)) {
  colnames(df)[colnames(df) == 'sottoreparto'] <- 'sottoreparto'
} else {
  df$sottoreparto <- NA
}

if("datapubblicazione" %in% colnames(df)) {
} else {
  df$datapubblicazione <- NA
}

df$note = paste(df$annotazioni_1,';',df$annotazioni_2)

f <- subset(df, select=c(ean, autore, titolo, editore, anno, collana, prezzo, siglebib, target_lettura, reparto, sottoreparto, datapubblicazione, fornitore, id_ordine, note))

print(names(f))
f$anno <- as.numeric(as.character(f$anno))
f$ean  <- as.character(as.character(f$ean))


outfile <- paste(tools::file_path_sans_ext(fname),'.csv',sep = '')

#write.table(f, file = outfile, append = FALSE, quote = TRUE, sep = ",",
#            eol = "\n", na = "NULL", dec = ".", row.names = FALSE,
#             col.names = TRUE, qmethod = c("escape", "double"),
#            fileEncoding = "UTF-8")

write.table(f, file = outfile, append = FALSE, quote = TRUE, sep = ",",
            eol = "\n", na = "NULL", dec = ".", row.names = FALSE,
            col.names = TRUE, qmethod = c("double"),
            fileEncoding = "UTF-8")

