% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/GD.functions.R
\name{genome.doub.sig}
\alias{genome.doub.sig}
\title{genome.doub.sig}
\usage{
genome.doub.sig(sample, seg.mat.minor, seg.mat.copy, number.of.sim = 10000)
}
\arguments{
\item{sample}{TCGA sample identifier}

\item{seg.mat.minor}{segmented minor allele copy number matrix. segmented matrix with minor allele (e.g. seg.mat.LOH). columns should be as follows: c("Sample","Chrom","Start","End","Num.probes","val")}

\item{seg.mat.copy}{segmented total copy number matrix. segmented total copy number matrix (columns as above)}

\item{number.of.sim}{The number of simulations to assess genome doubling likelihood, defaults to 10,000}
}
\value{
the function returns a p.val for every sample
}
\description{
The following function estimates the probability that a genome doubling has
occured at some point during the evolutionary history of a tumour. This function is to assess significance as to whether sample appears to have undergone genome doubling.
}
\details{
According to the code of clonality.estimation(), "val" means "cn". the function uses the limma weighted.median function
}
\examples{
genome.doub.sig(sample, seg.mat.minor, seg.mat.copy, number.of.sim = 10000)

}
