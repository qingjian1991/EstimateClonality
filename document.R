library(devtools)
devtools::document()


#Example codes.


library(EstimateClonality)

data("centromere", package = "EstimateClonality")

blac.mut = system.file("extdata/Input/BLCA.mutation.table.txt", package = "EstimateClonality")
blac.seg = system.file("extdata/Input/tcga.blca.seg.hg19.rdata", package = "EstimateClonality")

clonality.estimation(mutation.table.loc= blac.mut,
                     seg.mat.loc= blac.seg,
                     data.type='TCGA_BLCA',
                     TCGA.barcode="TCGA-BT-A42C",
                     ANALYSIS.DIR="example/")


