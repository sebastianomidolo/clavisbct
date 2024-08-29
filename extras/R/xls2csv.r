args = commandArgs(trailingOnly=TRUE)

fname = args

print(fname);

library(dplyr);
library(readxl);
library(stringr);
library(tidyr);

df <- read_excel(fname)
df <- df %>% mutate(Date = as.character(Date))



outfile <- paste(tools::file_path_sans_ext(fname),'.csv',sep = '')
 
write.table(df, file = outfile, append = FALSE, quote = TRUE, sep = ",",
            eol = "\n", na = "NULL", dec = ".", row.names = TRUE,
             col.names = FALSE, qmethod = c("escape", "double"),
            fileEncoding = "UTF-8")


