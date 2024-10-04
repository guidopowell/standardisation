#' Méthode Plot pour un objet de classe "standardisation_list" 
#' 
#' @param x un objet de la classe "standardisation_list"
#' @param Annuel un argument, FALSE par défaut,  pour définir si les unités standardisés sont des années  
#' 
#' @export plot.standardisation_list
#' @export


plot.standardisation_list<-function(x,Annuel=F){
  
  methode<-x$methode
  multiplicateur<-x$multiplicateur
  unite<-x$unite
  
  
  if(methode=="directe"){
    
    stand<-x$Resultat %>% 
      gather(key="var",value = "Taux",c(valeur_brute,valeur_ajustee)) %>% 
      mutate(IC_bas=case_when(var=="valeur_brute"~NA,
                              T~ IC_bas),
             IC_haut=case_when(var=="valeur_brute"~NA,
                               T ~ IC_haut)) 
    
    add_star<-stand[[unite]]
    add_star<-ifelse(stand[[unite]] %in% stand[[unite]][is.na(stand$Taux)], 
                     paste0(add_star, " *"),add_star)
    
    stand[[unite]]<-add_star
    
    levels_fct<-stand %>% 
      filter(var=="valeur_ajustee")
    
    levels_fct<-if(Annuel){
      levels_fct %>% 
        arrange(unite ) %>% 
        pull({{unite}})
    }else{
      levels_fct %>% 
        arrange(Taux %>% desc) %>% 
        pull({{unite}}) %>% rev
    }
    
    
    stand[[unite]]<-factor(stand[[unite]],
                           order=T,levels=levels_fct)
    
    
    stand<-stand %>% 
      mutate(var=case_when(var=="valeur_ajustee"~ "Taux ajusté",
                           var=="valeur_brute"~"Taux brut"))
    
    viz<- ggplot(stand,aes_string(x={{unite}},y="Taux",fill="var"))+
      geom_bar(stat="identity",position = "dodge")+
      geom_errorbar(aes(ymin=IC_bas ,ymax=IC_haut),position=position_dodge())+
      scale_fill_manual(name="",
                        values=c("#87c785","#15134b"),
                        guide = guide_legend(reverse = TRUE))+
      scale_y_continuous(name=paste("Taux", 
                                    ifelse(multiplicateur!=1,
                                           paste("X",format(multiplicateur,big.mark=",", trim=TRUE)),"")))+
      theme_minimal()
    
    if(!Annuel){
      viz<-viz+
        coord_flip()
    }
    
    if(any(is.na(stand$Taux))){
      viz<-viz+labs(caption=paste0("* ",{{unite}}," ayant < 10 observations"))+
        theme(plot.caption = element_text(hjust=0))
    }
    
  }
  
  if(methode=="indirecte"){
    
   
    stand<-x$Resultat %>% 
      gather(key="var",value = "Ratio",c(ratio_brut,ratio)) %>% 
      mutate(IC_bas=case_when(var=="ratio_brute"~NA,
                              T~ IC_bas),
             IC_haut=case_when(var=="ratio_brute"~NA,
                               T ~ IC_haut)) 
    
    levels_fct<-stand %>% 
      filter(var=="ratio")
    
    
    levels_fct<-
      if(Annuel){levels_fct %>% 
          arrange(unite %>% desc) %>% 
          pull({{unite}}) %>% 
          as.vector()
      }else{
        levels_fct %>% 
          arrange(Ratio %>% desc) %>% 
          pull({{unite}}) %>% 
          as.vector() %>% rev
      }
    
    
    stand[[unite]]<-factor(stand[[unite]],
                           order=T,levels=levels_fct)
    stand<-stand %>% mutate(sig=case_when(IC_haut < 1 ~ "low",
                                          IC_bas > 1 ~ "high",
                                          T ~ "null"))
    
    stand<-stand %>% 
      mutate(var=case_when(var=="ratio"~ "Ratio ajusté",
                           var=="ratio_brut"~"Ratio brut"))
    
    viz<- ggplot(stand,aes_string(x={{unite}},y="Ratio"))+
      geom_point(size=4,aes(color=sig,pch=var))+
      geom_errorbar(aes(ymin=IC_bas ,ymax=IC_haut,col=sig))+
      geom_hline(yintercept = 1,linetype=2,alpha=.5)+
      scale_shape_manual(values=c(16,21),name="")+
      scale_y_continuous(name="Ratio (obs/exp)")+
      scale_color_manual(values=c("#8942bd","#0f8d7b", "grey30"),
                         guide="none")+
      theme_minimal()
    
    
    if(!Annuel){
      viz<-viz+
        coord_flip()
    }
  }
  viz
}






