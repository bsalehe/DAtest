#' Zero inflated Negative Binomial glm
#'
#' Apply zero-inflated negative binomial generalized linear model to multiple features, with one independent variable
#' With \code{log(librarySize)} as offset.
#' @param data Either a matrix with counts/abundances, OR a \code{phyloseq} object. If a matrix/data.frame is provided rows should be taxa/genes/proteins and columns samples
#' @param predictor The predictor of interest. Either a Factor or Numeric, OR if \code{data} is a \code{phyloseq} object the name of the variable in \code{sample_data(data)} in quotation
#' @param covars Either a named list with covariables, OR if \code{data} is a \code{phyloseq} object a character vector with names of the variables in \code{sample_data(data)}
#' @param relative Logical. Whether \code{log(librarySize)} should be used as offset. Default TRUE
#' @param out.all If TRUE will output results and p-values from \code{drop1}. If false will output results for 2. level of the \code{predictor}. If NULL (default) set as TRUE for multi-class \code{predictor} and FALSE otherwise
#' @param p.adj Character. P-value adjustment. Default "fdr". See \code{p.adjust} for details
#' @param coeff Integer. The p-value and log2FoldChange will be associated with this coefficient. Default 2, i.e. the 2. level of the \code{predictor}.
#' @param coeff.ref Integer. Reference level of the \code{predictor}. Will only affect the log2FC and ordering columns on the output. Default the intercept, = 1 
#' @param allResults If TRUE will return raw results from the \code{zeroinfl} function
#' @param ... Additional arguments for the \code{zeroinfl} function
#' @return A data.frame with with results.
#' @examples 
#' # Creating random count_table and predictor
#' set.seed(4)
#' mat <- matrix(rnbinom(1000, size = 0.1, mu = 500), nrow = 100, ncol = 10)
#' rownames(mat) <- 1:100
#' pred <- c(rep("Control", 5), rep("Treatment", 5))
#' 
#' # Running Zero-inflated Negative Binomial regression on each feature
#' res <- DA.znb(data = mat, predictor = pred)
#' @export

DA.znb <- function(data, predictor, covars = NULL, relative = TRUE, out.all = NULL, p.adj = "fdr", coeff = 2, coeff.ref = 1, allResults = FALSE, ...){
 
  ok <- tryCatch({
    loadNamespace("pscl")
    TRUE
  }, error=function(...) FALSE)
  
  if (ok){
    # Extract from phyloseq
    if(is(data, "phyloseq")){
      DAdata <- DA.phyloseq(data, predictor, paired = NULL, covars)
      count_table <- DAdata$count_table
      predictor <- DAdata$predictor
      covars <- DAdata$covars
    } else {
      count_table <- data
    }
    if(!is.null(covars)){
      for(i in seq_along(covars)){
        assign(names(covars)[i], covars[[i]])
      }
    }
    
    if(coeff == coeff.ref) stop("coeff and coeff.ref cannot be the same")
    if(!coeff %in% seq_along(unique(predictor)) | !coeff.ref %in% seq_along(unique(predictor))) stop(paste("coeff and coeff.ref should be integers between 1 and",length(unique(predictor))))
    
    # out.all
    if(is.null(out.all)){
      if(length(unique(predictor)) == 2) out.all <- FALSE
      if(length(unique(predictor)) > 2) out.all <- TRUE
      if(is.numeric(predictor)) out.all <- FALSE
    }
    
    # Library sizes
    if(relative) libSize <- colSums(count_table) else libSize <- rep(1,ncol(count_table))
    count_table <- as.data.frame.matrix(count_table)
    
    # Define function
    if(is.null(covars)){
      negbin <- function(x){
        fit <- NULL
        tryCatch(
          fit <- pscl::zeroinfl(x ~ predictor + offset(log(libSize)),dist="negbin",...), 
          error = function(x) fit <- NULL)
        if(!is.null(fit)) {
          if(nrow(summary(fit)$coefficients$count) > 1) {
            pval <- summary(fit)$coefficients$count[coeff,4]
            ests <- summary(fit)$coefficients$count[,1]
            c(ests,pval)
          } else NA
        } else NA 
      }
    } else {
      negbin <- function(x){
        fit <- NULL
        tryCatch(
          fit <- pscl::zeroinfl(as.formula(paste("x ~ predictor+offset(log(libSize))+",paste(names(covars), collapse="+"),sep = "")),dist="negbin",...), 
          error = function(x) fit <- NULL)
        if(!is.null(fit)) {
          if(nrow(summary(fit)$coefficients$count) > 1) {
            pval <- summary(fit)$coefficients$count[coeff,4]
            ests <- summary(fit)$coefficients$count[,1]
            c(ests,pval)
          } else NA
        } else NA 
      }
    }
    
    ## for out.all TRUE
    if(out.all){
      if(is.null(covars)){
        negbin <- function(x){
          fit <- NULL
          tryCatch(
            fit <- pscl::zeroinfl(x ~ predictor + offset(log(libSize)),dist="negbin",...), 
            error = function(x) fit <- NULL)
          if(!is.null(fit)){
            ests <- summary(fit)$coefficients$count[,1]
            ano <- tryCatch(drop1(fit, test = "Chisq")[2,],error = function(e) ano <- NULL)
            c(ano,ests)
          }
        }
      } else {
        negbin <- function(x){
          fit <- NULL
          tryCatch(
            fit <- pscl::zeroinfl(as.formula(paste("x ~ predictor+offset(log(libSize))+",paste(names(covars), collapse="+"),sep = "")),dist="negbin",...), 
            error = function(x) fit <- NULL)
          if(!is.null(fit)){
            ests <- summary(fit)$coefficients$count[,1]
            ano <- tryCatch(drop1(fit, test = "Chisq")[2,],error = function(e) ano <- NULL)
            c(ano,ests)
          }
        }
      }
    }
    
    ## for allResults TRUE
    if(allResults){
      if(is.null(covars)){
        negbin <- function(x){
          fit <- NULL
          tryCatch(
            fit <- pscl::zeroinfl(x ~ predictor + offset(log(libSize)),dist="negbin",...), 
            error = function(x) fit <- NULL)
        }
      } else {
        negbin <- function(x){
          fit <- NULL
          tryCatch(
            fit <- pscl::zeroinfl(as.formula(paste("x ~ predictor+offset(log(libSize))+",paste(names(covars), collapse="+"),sep = "")),dist="negbin",...), 
            error = function(x) fit <- NULL)
        }
      }
      return(apply(count_table,1,negbin))
    } else {
      
      # Run the tests for allResults FALSE
      if(out.all){
        res <- as.data.frame(do.call(rbind,apply(count_table,1,negbin)))
        colnames(res)[1:4] <- c("Df","AIC","LRT","pval")
        res <- as.data.frame(lapply(res, unlist))
      } else {
        res <- as.data.frame(t(as.data.frame(apply(count_table,1,negbin))))
        colnames(res)[ncol(res)] <- "pval"
        res$log2FC <- log2(exp(res[,coeff.ref]+res[,coeff]) / exp(res[,coeff.ref]))
        if(!is.numeric(predictor)){
          res$ordering <- NA
          res[!is.na(res[,coeff]) & res[,coeff] > 0,"ordering"] <- paste0(levels(as.factor(predictor))[coeff],">",levels(as.factor(predictor))[coeff.ref])
          res[!is.na(res[,coeff]) & res[,coeff] < 0,"ordering"] <- paste0(levels(as.factor(predictor))[coeff.ref],">",levels(as.factor(predictor))[coeff])
        }
      }
      
      if(nrow(res) == 1){
        res <- data.frame(pval = rep(NA,nrow(count_table)))
        rownames(res) <- rownames(count_table) 
      } 
      
      res$pval.adj <- p.adjust(res$pval, method = p.adj)
      res$Feature <- rownames(count_table)
      res$Method <- "ZI-NegBin GLM (znb)"
      
      if(nrow(res) > 1){
        if(is(data, "phyloseq")) res <- addTax(data, res)
      }
      return(res)
    }
    
  } else {
    stop("pscl package required")
  }
  
}
