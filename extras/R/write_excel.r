library("xlsx")

args = commandArgs(trailingOnly=TRUE)

csv_file = args

# print(csv_file)

df <- read.csv(csv_file)
df$CodiceEan = as.character(df$CodiceEan)
write.xlsx(df, "/home/seb/prova.xls", sheetName = "FoglioUno",col.names = TRUE, row.names = FALSE, append = FALSE)

print(names(df))
# print(df$Note)
