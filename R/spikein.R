spikein <- function(count_table, predictor, effectSize = 2, k, num.pred = FALSE, relative = TRUE){
  
  if(effectSize < 0) stop("Effect size should be positive")
  if(effectSize == 1) spikeMethod <- "none" else spikeMethod <- "mult"

  if(is.null(rownames(count_table))) rownames(count_table) <- seq_len(nrow(count_table))
  
  count_table <- as.data.frame(count_table)
  if(!num.pred) predictor <- as.numeric(as.factor(predictor))-1
  
  # Choose Features to spike
  propcount <- apply(count_table,2,function(x) x/sum(x))
  count_abundances <- sort(rowSums(propcount)/ncol(propcount))
    
  ## Only spike Features present in cases (except if predictor is numeric)
  if(num.pred){
    approved_count_abundances <- count_abundances
  } else {
    approved_count_abundances <- count_abundances[ 
      names(count_abundances) %in% row.names( count_table[ rowSums(count_table[,predictor == 1]) > 0, predictor == 1] ) ]
  }
  
  # Which to spike in each tertile  
  lower_tert <- names(approved_count_abundances[approved_count_abundances < quantile(approved_count_abundances,1/3)])
  mid_tert <- names(approved_count_abundances[approved_count_abundances >= quantile(approved_count_abundances,1/3) & approved_count_abundances < quantile(approved_count_abundances,2/3)])
  upper_tert <- names(approved_count_abundances[approved_count_abundances >= quantile(approved_count_abundances,2/3)])
    
  spike_features <- c(sample(lower_tert, k[1]), sample(mid_tert, k[2]), sample(upper_tert,k[3]))
  spike_feature_index <- which(row.names(count_table) %in% spike_features)
  
  # Spike Features by multiplication
  oldSums <- colSums(count_table)
  
  if(spikeMethod == "mult"){
    
    if(num.pred){
      # For numeric predictor
      predictor <- as.numeric(predictor)
      
      oldmat <- as.matrix(as.data.frame(count_table))
      
      # Multiply according to predictor and effectSize
      count_table[spike_feature_index,] <- t(log(t(count_table[spike_feature_index, ]) * (as.numeric((effectSize) ^ scale(predictor)))+1))
      
      # Rescale to original level
      for(i in spike_feature_index){
        count_table[i,] <- (count_table[i,] - min(count_table[i,]))/(max(count_table[i,])-min(count_table[i,])) * (max(oldmat[i,]) - min(oldmat[i,])) + min(oldmat[i,])
      }
      
    } else {
      # For categorical data
      count_table[spike_feature_index,predictor==1] <- count_table[spike_feature_index, predictor==1] * effectSize
    }
  }

  # Rescale to original sample sums
  newSums <- colSums(count_table)
  if(relative) count_table <- round(t(t(count_table) * oldSums/newSums))

  list(count_table,spike_features)
}