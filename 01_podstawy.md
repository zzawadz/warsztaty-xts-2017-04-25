Podstawy - przekazywanie funkcji jako argumentu do innej funkcji:
-----------------------------------------------------------------

Argumentem przekazywanym do funkcji w R może być dowolny obiekt. A że
sama funkcja też jest obiektem oznacza to, że również ona może być użyta
w wywołaniu innej funkcji. Przykład:

    # set.seed(123) zapewnia powtarzalność wyników:
    set.seed(123)
    x <- rnorm(10)

    # Prosta funkcja biorąca jako argument wektor x i
    # funkcję `fnc`:
    testFnc <- function(x, fnc) {
      fnc(x) * 10
    }

    # Przykłady wywołania:
    testFnc(x, mean) == mean(x) * 10

    ## [1] TRUE

    testFnc(x, sd) == sd(x) * 10

    ## [1] TRUE

apply i inne
------------

Mechanizm przekazywania funkcji jako argumenty jest bardzo często
wykorzystywany w R. Jednym z głównych przykładów jest rodzina funkcji
`apply`:

    # apply:
    x <- iris[, 1:4]
    apply(x, MARGIN = 2, mean)

    ## Sepal.Length  Sepal.Width Petal.Length  Petal.Width 
    ##     5.843333     3.057333     3.758000     1.199333

    # tapply:
    tapply(X = x[, 1],
      INDEX = list(iris$Species),
      FUN = mean)

    ##     setosa versicolor  virginica 
    ##      5.006      5.936      6.588

Funkcja jako wynik działania funckji:
-------------------------------------

Kodując w R zdarza się, że przydatne są małe funkcje służące jako
wrappery pozwalające wywołać inną funkcję z określonymi parametrami.
Jednym ze sposobów stworzenia takiej funkcji jest wykorzystanie
mechanizmu funkcji jako argumentu:

    x <- c(1,2,3, NA)
    mean(x) # Jest NA dlatego też wynikiem jest NA

    ## [1] NA

    mean(x, na.rm = TRUE)

    ## [1] 2

    # Funckja wywołująca przekazaną funckję `fnc`
    # z argumentem na.rm = TRUE
    withNaRm <- function(x, fnc) {
      fnc(x, na.rm = TRUE)
    }

    # Przykładowe wywołania
    withNaRm(x, mean)

    ## [1] 2

    withNaRm(x, sd)

    ## [1] 1

Wywołanie `withNaRm(x, mean)` jest jednak mało oczywiste i w zasadzie
bardziej zaciemnia kod. Jednak istnieje lepszy mechanizm który może
zostać wykorzystany do stworzenia wrapperów - funkcja jako wynik innej
funkcji.

Jeżeli funkcja w R jako wynik zwraca inną funkcję, wtedy ta wynikowa
funkcja 'pamięta' wszystkie zmienne przekazane i stworzone w funkcji
matce:

    makePower <- function(pow) {
      function(x) {
        message("pow is equal: ", pow)
        x ^ pow
      }
    }

    square <- makePower(2)
    cube   <- makePower(3)

    square(2)

    ## pow is equal: 2

    ## [1] 4

    cube(2)

    ## pow is equal: 3

    ## [1] 8

W efekcie mechanizm ten można wykorzystać do tworzenia wrapperów w
następujący sposób:

    makeNaRm <- function(fnc) {
      function(...) {
        # ... oznacza dowlny argument
        fnc(..., na.rm = TRUE)
      }
    }

    rmMean <- makeNaRm(mean)
    rmSD <- makeNaRm(sd)

    x <- c(1,2,3,NA)
    rmMean(x)

    ## [1] 2

    rmSD(x)

    ## [1] 1

Podsumowanie:
-------------

-   Funkcja może być argumentem dla innej funkcji.
-   Jeżeli funkcja zwraca funkcję, to wynikowa 'pamięta' wszystkie
    argumenty i zmienne funkcji 'matki'.
