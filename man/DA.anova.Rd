% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/posthocs.R
\name{DA.anova}
\alias{DA.anova}
\title{Run \code{anova} on all features from \code{DAtest} results with \code{allResults = TRUE}}
\usage{
DA.anova(results, p.adj = "fdr", ...)
}
\arguments{
\item{results}{Output from a \code{DA."test"} function with \code{allResults = TRUE}}

\item{p.adj}{P-value adjustment method. See \code{p.adjust for details}. Default "fdr"}

\item{...}{Additional arguments for \code{anova} function}
}
\value{
A data.frame with output from anova and adjusted p.values for each predictor and feature
}
\description{
Works on "lrm", "llm", "llm2", "lma", "lmc". Non-paired "neb"
}
\examples{
# Creating random count_table, predictor, and covariate
set.seed(5)
mat <- matrix(rnbinom(1500, size = 0.5, mu = 500), nrow = 100, ncol = 15)
rownames(mat) <- 1:100
pred <- c(rep("A", 5), rep("B", 5), rep("C", 5))
covar <- rnorm(15)

# Running linear model and then anova on each feature
res <- DA.lmc(mat, pred, covars = list(Something = covar), allResults = TRUE)
res.ano <- DA.anova(res)
}
