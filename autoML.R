# Sys.setlocale("LC_MESSAGES", 'en_GB.UTF-8')
# Sys.setenv(LANG = "en_US.UTF-8")
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

# AutoML
aml <- h2o.automl(x = 2:19,
                  y = "Class",
                  training_frame = card,
                  max_runtime_secs = 30)

aml@leaderboard
aml@leader
h2o.predict(aml@leader, test)
