library(h2o)
library(ggplot2)

# Tworzymy połączenie z H2O
localH2O <- h2o.init(ip = "localhost", # domyślnie
                     port = 54321, # domyślnie
                     nthreads = -1, # użyj wszystkich dostepnych rdzeni
                     min_mem_size = "20g")

# Wczytujemy dane
card <- h2o.importFile(path = "data/creditcard.csv",
                       destination_frame = "creditcard")
# Podsumowania
class(card)
colnames(card)
summary(card)
h2o.table(card$Class) # Max dwie zmienne

# Dzielimy na zbiór treningowy i testowy
h2o.splitFrame(card,
               ratios = 0.75,
               destination_frames = c("creditcard_train","creditcard_test"),
               seed = 1234)
h2o.ls()
# 4. Stwórz połaczenie pomiędzy R i H2O dla zbiorów "creditcard_train" i "creditcard_test"

# LASSO z over/under samplingiem
card_lasso_balanced <- h2o.glm(x = 2:29, # Nazwy lub indeksy
                               y = "Class", # Nazwa lub indeks
                               training_frame = "creditcard_train", 
                               family = "binomial", 
                               alpha = 1, 
                               lambda_search = TRUE, 
                               model_id = "creditcard_lasso_balanced", 
                               nfolds = 5,
                               balance_classes = TRUE, # Over/under sampling
                               class_sampling_factors = c(0.5,0.5), 
                               seed = 1234)

# Predykcje i miary dopasowania
# 5. Wykonaj predykcje dla zbioru card_test
perf_lasso_balanced <- h2o.performance(card_lasso_balanced, card_test)

cm_lasso_balanced <- h2o.confusionMatrix(card_lasso_balanced, 
                                         newdata = card_test,
                                         metrics = "f2")
# 6. Dla powyzszego modelu wyciągnij informacje o wartości AUC i AIC
# 7. Dla powyzszego modelu wyciągnij informacje o współczynnikach regresji
# 8. Dla powyzszego modelu wyciągnij informacje o wartości wybranej przez model lambdy

fpr <- h2o.fpr(perf_lasso_balanced)[['fpr']]
tpr <- h2o.tpr(perf_lasso_balanced)[['tpr']]
ggplot(data.frame(fpr = fpr, tpr = tpr), aes(fpr, tpr)) + 
  geom_line() + theme_bw()

# Zapisywanie i wczytywanie modeli
h2o.saveModel(card_lasso_balanced,
              path = "data/")
loaded_model <- h2o.loadModel("data/creditcard_lasso_balanced")
# Analogiczne funkcje h2o.saveMojo(), h2o.download_mojo()