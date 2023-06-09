plot_contour<-function(x,y,data,var_name,cbar_limit,ii){
    s = expand.grid(x,y) 
    data[data<=cbar_limit[1]] = cbar_limit[1]  #make sure min values are also plotted!
    data[data>=cbar_limit[2]] = cbar_limit[2]
    df = data.frame(s,as.vector(data))
    fs = 18
    colnames(df) = c("vmax","jmax","z")
    v<-ggplot(df,aes(x=vmax,y=jmax,z=z,fill=z))+geom_contour_filled()+ 
       geom_tile()+
       #geom_contour(color = "black",bins = 15)+ 
       #geom_text_contour(stroke = 0.2,min.size = 2)+
       xlab("vmax")+
       scale_fill_distiller(name=var_name,palette = "Spectral",limits = cbar_limit)+
       theme(axis.text   =element_text(size=fs),
             axis.title  =element_text(size=fs,face="bold"),
             legend.text =element_text(size=fs),
             legend.title=element_text(size=fs))
#remove axis labels 
     v <- v + theme(axis.text =element_blank(),
                    axis.ticks=element_blank(),
                    axis.title=element_blank()) 
#only plot legend at one column
#     if(ii!=4){
     v <- v + guides(fill=FALSE, color=FALSE)
#     }
#add a triangle in the center
     v <- v + geom_point(aes(x=1,y=1),shape=24, fill="grey",color="black", size=7)
#       scale_fill_distiller(name=var_name,palette = "RdBu",limits = cbar_limit)
     return(v)
}

layers_contour<-function(x,y,var2plot,cbar_limit,pdf_name,no_layers,years){
	var2plot_layers = paste(rep("layer",no_layers),1:no_layers,sep="") 
	plot_list = list()
	for (j in 1:length(var2plot_layers)){
	        varname = var2plot_layers[j]
	        var_diff = var2plot[,,,j] 
		for (i in 1:length(years)){
		    year_i = years[i]
		    fig_i = plot_contour(x,y,var_diff[,,i],varname,cbar_limit)
	            fig_order = i+ (j-1) * length(years)
		    plot_list[[fig_order]] = fig_i 
		}
	}
	pdf(pdf_name,height = 48, width=24)
	grid.arrange(grobs = plot_list,nrow=length(var2plot_layers),ncol=length(years))
	dev.off()
}

barplot<-function(df,pdfname){
   df <- within(df, CO2 <- factor(CO2,levels=names(sort(table(CO2),decreasing=FALSE))))
   CO2_label = paste(unique(df$CO2),"ppm")
   plot_list = list()
   ynames = colnames(df)[-c(1,2)]#remove year and CO2 
   ylimit = c(0,10)
   text_size = 24
   for (i in 1:length(ynames)){
   df_tmp = df[,c(1,2,i+2)]
   df_with_sd = cbind(df_tmp[1,],sd=NaN) #init the target df 
   for(CO2 in unique(df$CO2)){
      df_tmp2 = df_tmp[df_tmp$CO2==CO2,]
      df_mean = mean(df_tmp2[,3])
      df_sd   = sd(df_tmp2[,3])
      tmp = cbind(df_tmp2[1,c(1,2)],df_mean,df_sd)
      colnames(tmp) = colnames(df_with_sd)
      df_with_sd = rbind(df_with_sd,tmp)
   }
   df_with_sd = df_with_sd[-1,]
   p <- ggplot(data=df_with_sd, aes_string(x="year", y=ynames[i], fill="CO2")) +
         geom_bar(stat="identity", position=position_dodge())+
         geom_errorbar(aes_string(ymin=ynames[i], ymax=paste0(ynames[i],"+sd")), width=.2,position=position_dodge(.9))+
          coord_cartesian(ylim = ylimit)+
          theme(axis.text=element_text(size=text_size),
           axis.title=element_text(size=text_size,face="bold"),
           axis.title.x=element_blank(),
           axis.text.x =element_blank(),
           axis.ticks.x=element_blank(),
           legend.position = c(.85, .85),
           legend.text     = element_text(size=text_size),
           legend.title    = element_text(size=text_size))
   # Use custom colors
   p <- p + scale_fill_manual(values=c('blue','green','orange','grey'),labels = CO2_label)

   if(i>1) p <- p + guides(fill=FALSE, color=FALSE) #remove legends

   plot_list[[i]] = p
   }
   pdf(pdfname,height = 16, width=24)
   grid.arrange(grobs = plot_list,nrow=2,ncol=3)
   dev.off()
}

gradient_desc<-function(x,y,z,optionx){
	#start point
	x0 = 1
	y0 = 1
	# Step size multiplier
	alpha=0.001
	num_iter = 100
        x1 = x0
        y1 = y0
        h = 0.01
        xygrid = expand.grid(x,y)
        xy_trace = c()
	for (i in 1:100) {
            xp = c(x1,x1-h,x1+h)
            yp = c(y1,y1-h,y1+h)
            fxy= interp(xygrid$Var1,xygrid$Var2,z,xp,yp,linear=FALSE)
            dzdx = (fxy$z[3,1]-fxy$z[2,1])/(2*h)
            dzdy = (fxy$z[1,3]-fxy$z[1,2])/(2*h)
            if(optionx==1){  #descent
              x1 = x1 - alpha * dzdx 
              y1 = y1 - alpha * dzdy
            }else if(optionx==2){ #ascent
              x1 = x1 + alpha * dzdx 
              y1 = y1 + alpha * dzdy
            }else{stop("no such option!")}
            if(is.na(x1)| is.na(y1)| x1<min(x) | x1>max(x) | y1<min(y) | y1>max(y)) break
            xy_trace = rbind(xy_trace,c(x1,y1))
	}	
     return(xy_trace)
}

corr_plot <- function(df,pdfname,varnames,weather_varname){
   text_size = 18
   plist = list()
   for (i in 1:length(varnames)){
   yname = varnames[i] 
   p <- ggplot(data=df, aes_string(x=weather_varname, y=yname,label="year")) +
        geom_point()+
        geom_text(vjust = 0, nudge_y = 0.5)+
        geom_smooth(method="lm")+
        theme(axis.text=element_text(size=text_size),
              axis.title=element_text(size=text_size,face="bold"))
   plist[[i]] = p
   }
   pdf(pdfname,height = 8, width=12)
   grid.arrange(grobs = plist,nrow=2,ncol=3)
   dev.off()
}

plot_diurnal<-function(y,years,months_gs,pdfname,v_use,j_use,v_scaler,j_scaler){
#array(NaN,c(length(v_scaler),length(j_scaler),length(years),length(months_gs),24,2))
 v_index = which(abs(v_scaler-v_use)<1e-10)
 j_index = which(abs(j_scaler-j_use)<1e-10)
 y1 = y[v_index,j_index,,,,]

 plot_list = list()
 fig_order = 1
 x_hours = seq(0,23,by=1)
 for (j in 1:length(months_gs)){
 for (i in 1:length(years)){
     y_mean = y1[i,j,,1]
     y_std  = y1[i,j,,2]
     df = data.frame(x_hours,y_mean,y_std)
     p <- ggplot(df,aes(x=x_hours,y=y_mean))+
          geom_line(size=1) +
          geom_point(size=1.5)+
#          geom_errorbar(aes(ymin=y_mean-y_std, ymax=y_mean+y_std), width=.2)+
	  xlab("hours")+ylab("A_net")+
          coord_cartesian(ylim = c(-10,20))+
          theme(axis.text.x = element_text(face="bold", color="#993333", 
                           size=16),
               axis.text.y = element_text(face="bold", color="#993333", 
                           size=16),
               axis.title=element_text(size=14))
     plot_list[[fig_order]] = p
     fig_order = fig_order+1
 } 
 } 

     no_rows = length(months_gs)
     pdf(pdfname,height = 36, width=24)
     grid.arrange(grobs = plot_list,nrow=no_rows,ncol=length(years))
     dev.off()
}

profile_plot1<-function(y1,y2,no_layers,years,pdfname,v_use,j_use,v_scaler,j_scaler){
	plot_list = list()
        fig_order = 1
         layers = 1:no_layers
 for (i in 1:length(v_use)){
 for (j in 1:length(j_use)){
                xlabel = paste("Ci(vmax*",v_use[i],",jmax*",j_use[j],")",sep="")
		for (k in 1:length(years)){
                    v_index = which(abs(v_scaler-v_use[i])<1e-10)
                    j_index = which(abs(j_scaler-j_use[j])<1e-10)
                    if(length(v_index)!=1 | length(j_index)!=1) stop("indexing error")
                    y11 = y1[v_index,j_index,k,]
                    y22 = y2[v_index,j_index,k,]
 			df = data.frame(shaded=y11,sunlit=y22,layers)
                        df_molten=melt(df,id.vars="layers")
                     plot_list[[fig_order]] =   ggplot(df_molten,aes(x=value,y=layers,color=variable)) + 
                      geom_line()+
                      geom_point()+
		      xlab(xlabel)
 		     fig_order= fig_order+1
                }
 }
 }
        no_rows = length(v_use)*length(j_use)
	pdf(pdfname,height = 48, width=24)
	grid.arrange(grobs = plot_list,nrow=no_rows,ncol=length(years))
	dev.off()
}

profile_plot2<-function(y,no_layers,years,pdfname,v_use,j_use,v_scaler,j_scaler){

	plot_list = list()
        fig_order = 1
        layers = 1:no_layers
	for (k in 1:length(years)){
        y_sub = (1:no_layers)*NaN  #create a empty column for cbind
        col_names = c()
 	for (i in 1:length(v_use)){
 	for (j in 1:length(j_use)){
             v_index = which(abs(v_scaler-v_use[i])<1e-10)
             j_index = which(abs(j_scaler-j_use[j])<1e-10)
            if(length(v_index)!=1 | length(j_index)!=1) stop("indexing error")
             y_sub = cbind(y_sub,y[v_index,j_index,k,])
             col_names = c(col_names,paste("vmax",v_use[i],"jmax",j_use[j],sep=""))
	}      
	}      
        #after cbind, remove the first column
        y_sub = y_sub[,-1]
        colnames(y_sub) = col_names
 	     df = data.frame(y_sub,layers)
             df_molten=melt(df,id.vars="layers")
            plot_list[[fig_order]] =   ggplot(df_molten,aes(x=value,y=layers,color=variable,shape=variable)) + 
            geom_line()+
            geom_point(alpha=0.5)+
	    xlab("Ci(ppm)")+
           scale_y_continuous(breaks=c(1:no_layers))+
            theme(axis.text.x = element_text(face="bold", color="#993333", 
                           size=14),
                  axis.text.y = element_text(face="bold", color="#993333", 
                           size=14),
                  axis.title=element_text(size=14),
                  legend.position = c(0.8, 0.2),
                  legend.text=element_text(size=14))
 	    fig_order= fig_order+1
	}
	pdf(pdfname,height = 12, width=24)
	grid.arrange(grobs = plot_list,nrow=1,ncol=length(years))
	dev.off()
}
# Define functions to create plots
plot_all_tissues <- function(res, year, biomass, biomass.std) {
  
  r <- reshape2::melt(res[, c("time","Root","Leaf","Stem","Grain")], id.vars="time")
  r.exp <- reshape2::melt(biomass[, c("DOY", "Leaf", "Stem", "Pod")], id.vars = "DOY")
  r.exp.std <- reshape2::melt(biomass.std[, c("DOY", "Leaf", "Stem", "Pod")], id.vars = "DOY")
  r.exp.std$ymin<-r.exp$value-r.exp.std$value
  r.exp.std$ymax<-r.exp$value+r.exp.std$value
  
  # Colorblind friendly color palette (https://personal.sron.nl/~pault/)
  col.palette.muted <- c("#332288", "#117733", "#999933", "#882255")
  
  size.title <- 12
  size.axislabel <-10
  size.axis <- 10
  size.legend <- 12
  
  f <- ggplot() + theme_classic()
  f <- f + geom_point(data=r, aes(x=time,y=value, colour=variable), show.legend = TRUE, size=0.25)
  f <- f + geom_errorbar(data=r.exp.std, aes(x=DOY, ymin=ymin, ymax=ymax), width=3.5, size=.25, show.legend = FALSE)
  f <- f + geom_point(data=r.exp, aes(x=DOY, y=value, fill=variable), shape=22, size=2, show.legend = FALSE, stroke=.5)
  f <- f + labs(title=element_blank(), x=paste0('Day of Year (',year,')'),y='Biomass (Mg / ha)')
  f <- f + coord_cartesian(ylim = c(0,10)) + scale_y_continuous(breaks = seq(0,10,2)) + scale_x_continuous(breaks = seq(150,275,30))
  f <- f + theme(plot.title=element_text(size=size.title, hjust=0.5),
                 axis.text=element_text(size=size.axis),
                 axis.title=element_text(size=size.axislabel),
                 legend.position = c(.15,.85), legend.title = element_blank(),
                 legend.text=element_text(size=size.legend),
                 legend.background = element_rect(fill = "transparent",colour = NA),
                 panel.grid.major = element_blank(),
                 panel.grid.minor = element_blank(), panel.background = element_rect(fill = "transparent",colour = NA),
                 plot.background = element_rect(fill = "transparent", colour = NA))
  f <- f + guides(colour = guide_legend(override.aes = list(size=2)))
  f <- f + scale_fill_manual(values = col.palette.muted[2:4], guide = FALSE)
  f <- f + scale_colour_manual(values = col.palette.muted, labels=c('Root','Leaf','Stem','Pod'))
  
  return(f)
}



