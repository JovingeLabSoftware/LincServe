library(rjson)
library(GEOquery)
library(httr)
 
# http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM1715626&view=FULL&form=text


url <- "http://54.152.59.84:8093/query/service"
GET(url, query = list(statement="SELECT * FROM \`beer-sample\` LIMIT 4"))
   
cat(content(tt, "text"))
 