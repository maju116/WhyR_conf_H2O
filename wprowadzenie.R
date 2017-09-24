# install.packages("h2o")
library(h2o)

# Tworzymy połączenie z H2O
localH2O <- h2o.init(ip = "localhost", # domyślnie
                     port = 54321, # domyślnie
                     nthreads = -1, # użyj wszystkich dostepnych rdzeni
                     min_mem_size = "20g")

# Przejdź do http://localhost:54321

h2o.clusterInfo() # Informacje o clustrze

h2o.shutdown() # Zamknięcie clustra

# WYSYŁANIE DANYCH DO H2O I Z H2O
h2o.ls() # Lista obiektów w H2O wraz z kluczami 

# 1. Z R
iris1_h2o <- as.h2o(iris)
iris2_h2o <- as.h2o(iris,
                    destination_frame = "iris2")
as.h2o(data.frame(x=1:3,y=4:6)) # Bardzo źle (za każdym razem inny klucz!)
as.h2o(data.frame(x=1:3,y=4:6),
       destination_frame = "nowe_dane") # Dobrze

# 2. Spoza R
card <- h2o.importFile(path = "data/creditcard.csv",
                       destination_frame = "creditcard")
# Analogiczne funkcje h2o.importHDFS, h2o.importURL, h2o.import_sql_table

# 3. Z H2O
h2o.exportFile(data = card,
               path = "data/card.csv",
               parts = 1) # Można podzielić plik na kilka części
card_in_R <- as.data.frame(card) # Wczytanie danych z H2O do R
# Analogiczne funkcje h2o.exportHDFS

h2o.getId(iris2_h2o) # Wyciąganie klucza
h2o.getFrame("nowe_dane") -> nowe_dane_h2o # Połączenie z istniejącymi danymi
# Analogiczne funkcje h2o.getModel, h2o.getGrid
h2o.rm(iris2_h2o) # Usuwanie z H2O obiektu 'iris2' oraz referencji z R
h2o.removeAll() # Usuwanie wszystkich obiektów z H2O

# MANIPULACJA DANYMI
x <- as.h2o(data.frame(id = 1:4,a = rnorm(4)),
            destination_frame = "x")
y <- as.h2o(data.frame(id = 1:4, b = letters[1:4]),
            destination_frame = "y")  

x$a # Powstanie tabela tymczasowa, która zniknie
y[,2] # Powstanie tabela tymczasowa, która zniknie 
x[1:2,"id"] # Powstanie tabela tymczasowa, która zniknie
x2 <- 3*x[1:2,] # Przypisanie (można ładniej)
x3 <- h2o.assign(3*x[1:2,], key = "x3") # Przypisanie
h2o.cbind(x,y)
h2o.rbind(x,x)
h2o.merge(x,y, by = "id")
# h2o:::.h2o.garbageCollect()

# 1. Ostatnia komenda nie działa, jak można to naprawić ?
h2o.removeAll()
h2o.ls()
x <- as.h2o(data.frame(id = 1:4,a = rnorm(4)),
            destination_frame = "x")
x$a <- sin(x$a)
x$a <- sin(44:47)
# 2. Zmien typ kolumny 'id' na factor
# 3. W folderze 'data' znajdują się pliki a.csv i b.csv,
# wczytaj je bezpośrednio do H2O, następnie stwórz w H2O
# nowy obiekt zawierający wspólną informację o tych zbiorach. Dodaj
# do niego nową kolumnę będącą sumą wierszy.