library(h2o)
library(tidyverse)

# Tworzymy połączenie z H2O
localH2O <- h2o.init(ip = "localhost", # domyślnie
                     port = 54321, # domyślnie
                     nthreads = -1, # użyj wszystkich dostepnych rdzeni
                     min_mem_size = "20g")

# Wczytujemy dane
card <- h2o.importFile(path = "data/creditcard.csv",
                       destination_frame = "creditcard")

# Dzielimy na zbiór treningowy i testowy
h2o.splitFrame(card,
               ratios = 0.75,
               destination_frames = c("creditcard_train","creditcard_test"),
               seed = 1234)
card_train <- h2o.getFrame("creditcard_train")
card_test <- h2o.getFrame("creditcard_test")

card_train$Class <- as.factor(card_train$Class)
card_test$Class <- as.factor(card_test$Class)

card_nn <- h2o.deeplearning(x = 2:29, # Nazwy lub indeksy
                            y = "Class", # Nazwa lub indeks
                            training_frame = card_train, 
                            distribution = "bernoulli",
                            model_id = "card_nn",
                            activation = "Tanh", # Funkcja aktywacji
                            adaptive_rate = TRUE,
                            hidden = 100,
                            nfolds = 5,
                            fold_assignment = "Modulo",
                            keep_cross_validation_predictions = TRUE) # Ilość warstw ukrytych i neuronów per warstwa


card_gbm <- h2o.gbm(x = 2:29,
                    y = "Class",
                    training_frame = card_train,
                    distribution = "bernoulli",
                    ntrees = 10,
                    max_depth = 3,
                    min_rows = 2,
                    learn_rate = 0.2,
                    nfolds = 5,
                    fold_assignment = "Modulo",
                    keep_cross_validation_predictions = TRUE,
                    seed = 1234)

card_rf <- h2o.randomForest(x = 2:29,
                            y = "Class",
                            training_frame = card_train,
                            ntrees = 10,
                            nfolds = 5,
                            fold_assignment = "Modulo",
                            keep_cross_validation_predictions = TRUE,
                            seed = 1234)

ensemble <- h2o.stackedEnsemble(x = 2:29,
                                y = "Class",
                                training_frame = card_train,
                                model_id = "card_ensemble6",
                                base_models = list(card_gbm@model_id, card_nn@model_id, card_rf@model_id))

perf <- h2o.performance(ensemble, newdata = card_test)

perf_gbm_test <- h2o.performance(card_gbm, newdata = card_test)
perf_nn_test <- h2o.performance(card_nn, newdata = card_test)
perf_rf_test <- h2o.performance(card_rf, newdata = card_test)
baselearner_best_auc_test <- max(h2o.auc(perf_gbm_test), h2o.auc(perf_nn_test), h2o.auc(perf_rf_test))
ensemble_auc_test <- h2o.auc(perf)
print(sprintf("Best Base-learner Test AUC:  %s", baselearner_best_auc_test))
print(sprintf("Ensemble Test AUC:  %s", ensemble_auc_test))

pred <- h2o.predict(ensemble, newdata = card_test)
