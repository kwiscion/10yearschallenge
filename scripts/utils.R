library(tidyverse)
library(patchwork)

theme_set(theme_bw())
scale_colour_discrete <- ggthemes::scale_color_tableau
scale_fill_discrete <- ggthemes::scale_fill_tableau


# For storing and loading models
storeModel <- function(model, predict_method, name, path) {
  readr::write_rds(list(model = structure(model, class = c(name, class(model))),
                        predict_method = predict_method),
                   path)
}

loadModel <- function(path) {
  tmp <- readr::read_rds(path)
  setMethod('predict', signature(object = class(tmp$model)[[1]]), tmp$predict_method)
  tmp$model
}

# From https://gist.github.com/traversc/1446ebe1dcc2d84bccdca781d4f1fa2a
fastAUC <- function(target, score) {
  x <- score
  y <- target
  x1 = x[y==1]; n1 = length(x1); 
  x2 = x[y==0]; n2 = length(x2);
  r = rank(c(x1,x2))  
  auc = (sum(r[1:n1]) - n1*(n1+1)/2) / n1 / n2
  return(auc)
}
# Model diagnostic function
plotModelDiagnostic <- function(df, target, score, model, mcs = 10, rescale_scores = FALSE){
  target <- enquo(target)
  score <- enquo(score)
  score_name <- quo_name(score)
  model <- enquo(model)
  
  if(rescale_scores) df <- df %>% group_by(model) %>% mutate(!! score_name := ((!! score) - min(!! score))/(max(!! score) - min(!! score))) %>% ungroup()
  
  color <- model
  
  p_auc <- df %>%
    mutate(foo = 1) %>%
    inner_join(data.frame(mcs = 1:mcs, foo = 1), by = 'foo') %>%
    group_by(!! model, mcs) %>%
    sample_frac(1, replace = T) %>%
    summarise(auc = fastAUC(!! target, !! score)) %>%
    ggplot(aes(!! model, auc, color = !! color)) +
    geom_boxplot() +
    ggtitle('Area under curve')
  
  
  df2plots <- df %>%
    group_by(!! model, !! score)  %>%
    summarise(positive = sum(!! target),
              negative = sum((!! target) == 0)) %>%
    arrange(desc(!! score)) %>%
    mutate(tpr = cumsum(positive)/sum(positive),
           fpr = cumsum(negative)/sum(negative),
           accuracy = (cumsum(positive) + sum(negative) - cumsum(negative))/sum(positive + negative),
           precision = cumsum(positive)/cumsum(positive + negative))
  
  p_roc <- df2plots %>%
    ggplot(aes(fpr, tpr, color = !! color)) +
    geom_line() +
    ggtitle('Receiver operating characteristic') +
    annotation_custom(grob = ggplotGrob(p_auc + 
                                          theme_bw(7) +
                                          theme(plot.background = element_rect(colour = "black"),
                                                legend.position = 'none')),
                      xmin = 0.45, xmax = 1.05,
                      ymin = -0.05, ymax = 0.55) +
    theme(legend.position = 'none')
  p_acc <- df2plots %>%
    ggplot(aes(!! score, accuracy, color = !! color)) +
    geom_line() +
    ggtitle('Accuracy') +
    theme(legend.position = 'none')
  p_pr <- df2plots %>%
    ggplot() +
    geom_line(aes(tpr, precision, color = !! color)) +
    xlab('recall') +
    ggtitle('Precision-recall curve') +
    theme(legend.justification=c(1,1),
          legend.position=c(1,1),
          legend.background = element_rect(color = 'black'))
  p_density <- df %>%
    mutate(linetype = as.factor(!! target)) %>%
    ggplot(aes(score, color = !! color, linetype = linetype)) +
    geom_density() +
    ggtitle('Score distribution per class') +
    theme(legend.position = 'none')
  
  (p_roc + p_acc + p_pr + p_density) +
    plot_layout(ncol = 2)
}

