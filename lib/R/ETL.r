library(rjson)
library(GEOquery)
library(httr)

config <- fromJSON(file="../../config.json")
url <- paste(config$couch_url, ":", config$couch_port, "/query/service", sep="")

statement <- "CREATE PRIMARY INDEX ON LINCS1"

# will fail silently if already exists...
res <- POST(url, query=list(statement=statement))

data <- getGEO(GEO = id, destdir = "/tmp")
fh <- paste("/tmp", id, ".soft", sep="")
unlink(fh)

treatment <- gsub(".*:", "", data@header$treatment_protocol_ch1)

metadata <- list(
  cell_line = gsub(".*:", "", data@header$source_name_ch1),
  type = treatment[1],
  lincs_id = treatment[2],
  name = treatment[3],
  dose = treatment[4],
  dose_unit = treatment[5],
  time = treatment[6],
  time_unit = treatment[7]  
)

gene_id <- as.character(data@dataTable@table[1:978,1])
zscore <- as.numeric(data@dataTable@table[1:978,4])
statement <- paste("INSERT INTO LINCS1 (KEY, VALUE) VALUES('", id, "', ", toJSON(list(metadata=metadata, data=list(gene_id=gene_id, zscore=zscore))), ")", sep="");
res <- POST(url, query=list(statement=statement))

# worked example
# statement <- ("SELECT * FROM LINCS1 WHERE metadata.cell_line = 'A375'")
# res <- POST(url, query=list(statement=statement))
# data <- content(res, as = 'parsed')
# zscore <- unlist(data$results[[1]]$LINCS1$data$zscore)


ids <- read.delim("GSE70564.txt", as.is=TRUE, header=FALSE)
count <- 1
for(id in ids[,1]) {
  print(paste(count, "of", nrow(ids), ":", id))
  data <- getGEO(GEO = id, destdir = "/tmp")
  fh <- paste("/tmp", id, ".soft", sep="")
  unlink(fh)
  
  treatment <- gsub(".*:", "", data@header$treatment_protocol_ch1)
  
  metadata <- list(
    cell_line = gsub(".*:", "", data@header$source_name_ch1),
    type = treatment[1],
    lincs_id = treatment[2],
    name = treatment[3],
    dose = treatment[4],
    dose_unit = treatment[5],
    time = treatment[6],
    time_unit = treatment[7]  
  )
  
  gene_id <- as.character(data@dataTable@table[1:978,1])
  zscore <- as.numeric(data@dataTable@table[1:978,4])
  statement <- paste("INSERT INTO LINCS1 (KEY, VALUE) VALUES('", id, "', ", toJSON(list(metadata=metadata, data=list(gene_id=gene_id, zscore=zscore))), ")", sep="");
  res <- POST(url, query=list(statement=statement))
  count <- count + 1
}


