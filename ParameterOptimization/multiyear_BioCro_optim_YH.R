## Optimization problem to solve for partitioning parameters for soybean

multiyear_BioCro_optim_YH <- function(optim_params, biocro.fun, ExpData, num_rows, weights, wts2, RootVals){
  
  cost.avg <- 0
  
  for (i in 1:length(biocro.fun)) {
    
    gro.opt <- match.fun(biocro.fun[[i]])
    
    result <- gro.opt(optim_params)
    
    if (nrow(result) < num_rows[i]) {
      # if simulation does not complete, assign a very high cost and exit
      cost.avg <- 1e10
      break
      
    } else{
      
      TrueValues <- ExpData[[i]]
      
      # Predicted values at DOY equal the DOYs in experimental data
      Pred <- data.frame("DOY"=TrueValues$DOY)
      doy_inds <- which(result$time %in% TrueValues$DOY)
      Pred$Stem <- result$Stem[doy_inds]
      Pred$Leaf <- result$Leaf[doy_inds]
      Pred$Pod  <- result$Pod[doy_inds]
      Pred$Seed <- result$Grain[doy_inds]
      
      doy_inds.Root <- which(result$time %in% RootVals[[i]]$DOY)
      Pred.Root <- result$Root[doy_inds.Root]
      
      
      # factor to scale experimental and simulated results between 0 and ~1 for all components
      scale.leaf <- max(TrueValues$Leaf)
      scale.stem <- max(TrueValues$Stem)
      scale.pod  <- max(TrueValues$Pod)
      scale.seed <- max(TrueValues$Seed)
      scale.Root <- max(RootVals[[i]]$Root)
      
      # weights
      wts <- weights[[i]]
      wts[] = 1
      
      # weighted rmses
      err.stem <- sum(wts$Stem*(((Pred$Stem-TrueValues$Stem)/scale.stem)^2))/length(Pred$Stem)
      err.leaf <- sum(wts$Leaf*(((Pred$Leaf-TrueValues$Leaf)/scale.leaf)^2))/length(Pred$Leaf)
      err.pod <- sum(wts$Pod*(((Pred$Pod-TrueValues$Pod)/scale.pod)^2))/length(Pred$Pod)
      err.seed <- sum(wts$Seed*(((Pred$Seed-TrueValues$Seed)/scale.seed)^2))/length(Pred$Seed)
      err.Root <- sum(((Pred.Root-RootVals[[i]]$Root)/scale.Root)^2)/length(Pred.Root)
      
      cost <- (wts2$Stem*err.stem + wts2$Pod*err.pod + wts2$Leaf*err.leaf + wts2$Root*err.Root + 
               wts2$Seed*err.seed)

      cost <- round(100 * cost,2) / length(biocro.fun)

#put more weight on the second year!
#      if(i ==length(biocro.fun)) cost=cost*20

      cost.avg <- cost.avg + cost
      
    }
    
  }
  
  return(cost.avg)
  
}
