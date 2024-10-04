#' Méthode Plot pour un objet de classe "agregation" 
#' 
#' @param x un objet de la classe "agregation"
#' 
#' @export plot.agregation
#' @export

plot.agregation<-function(x){
  
  
  agregation_data<-x$df
  unite<-x$unite
  sexe<-x$sexe
  
  #outlier
  agregation_data<-agregation_data %>% mutate(prop=num/denom)
  q <- quantile(agregation_data$prop, c(0.25, 0.75))
  iqr <- q[2] - q[1]
  lower_bound <- max(0,q[1] - 1.5 * iqr)
  upper_bound <- q[2] + 1.5 * iqr
  max_inlier<-max(agregation_data$prop[agregation_data$prop<=upper_bound])
  agregation_data$outlier_up <- agregation_data$prop > upper_bound
  
  
  tmp_total<-
    agregation_data %>% 
    group_by(AGE_CAT) %>% 
    summarize(num=sum(num),denom=sum(denom)) %>% 
    mutate(unite="Total") 
  
  if(!is.null(sexe)){
    tmp_total<-
      agregation_data %>% 
      group_by(AGE_CAT,sexe) %>% 
      summarize(num=sum(num),denom=sum(denom)) %>% 
      mutate(unite="Total") 
  }
  
  colnames(tmp_total)[colnames(tmp_total)=="unite"]<-{{unite}}
  
  tmp_total$outlier_up<-F
  tmp_total<-tmp_total %>% mutate(prop=num/denom)
  tmp_total_bind<-agregation_data %>% bind_rows(tmp_total)
  
  levels_unite<-unique(agregation_data[[unite]]) %>% sort(decreasing = T)
  
  tmp_total_bind[[unite]]<-factor(tmp_total_bind[[unite]],ordered = T, levels=c(levels_unite,"Total"))
  
  
  #Total globale pour titre
  title_sum<-agregation_data %>% ungroup %>% 
    summarize(nums =sum(num),denoms=sum(denom), prop= nums/denoms )
  
  # tmp_total_bind<- tmp_total_bind %>% 
  #   mutate(prop=case_when(outlier_up==T ~ NA,
  #                         T ~ prop)) 
  viz<- 
  tmp_total_bind %>% 
    
    ggplot(aes_string(x="AGE_CAT",y={{unite}}))+
  #  geom_tile(aes(fill=prop,colour=""))+#,color="white")+
    geom_tile(aes(fill=prop),color="white")+
    geom_tile(data=tmp_total,linewidth=1.5,color="white",alpha=0)+
    geom_tile(data=tmp_total,linewidth=1,color="black",alpha=0)+
    
    geom_label(aes(label=paste0(num,"/",denom)),size=3)+
    scale_linewidth_manual(values=c(.5,2),guide="none")+
    scale_fill_continuous(type = "viridis",
                          name="Proportion",
                          #limits=c(0,max_inlier),
                          na.value="white" )+
    scale_colour_manual(values=NA) +              
    guides(colour=guide_legend("Outlier", override.aes=list(colour="black",fill="white")))+
    
    theme_minimal()+
    theme(plot.caption = element_text(hjust=.5) )+
    labs(caption = paste0("Statistiques globales: ",title_sum$nums," / ",
                          title_sum$denoms,"\n",
                          "Proportion: ",
                          formatC(title_sum$prop)))
  
  if(!is.null(sexe)){
    viz<-viz+
      facet_wrap(~sexe)
  }
  
  viz
  
}

