% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/preDA.R
\name{preDA}
\alias{preDA}
\title{Pre-processing for DAtest}
\usage{
preDA(data, min.samples = 0, min.reads = 0, min.abundance = 0)
}
\arguments{
\item{data}{Either a matrix with counts/abundances, OR a \code{phyloseq} object. If a matrix/data.frame is provided rows should be taxa/genes/proteins and columns samples}

\item{min.samples}{Minimum number of samples the features should be present in. Default 0}

\item{min.reads}{Minimum number of total reads the features should have. Default 0}

\item{min.abundance}{Minimum mean relative abundance features should have. Default 0}
}
\value{
Similar to input, but with features not reaching the criteria given grouped as "Others"
}
\description{
Pre-process the count table before running \code{DAtest} functions
}
\examples{
# Creating random count_table with many low abundant
set.seed(4)
mat <- matrix(rnbinom(1000, size = 0.05, mu = 500), nrow = 100, ncol = 10)
# Keep only those present in at least 3 samples
res <- preDA(mat, min.samples = 3)

# Last feature is now called 'Others' and is a sum of all features present in less than 3 samples
rownames(res)[nrow(res)]
}
