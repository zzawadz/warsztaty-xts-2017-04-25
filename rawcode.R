### Warsztaty

# Podstawy - przekazywanie funkcji jako argumentu do innej funkcji:

```{r}
testFnc <- function(x, fnc) {
  fnc(x) * 10
}

x = rnorm(10)
testFnc(x, mean) == mean(x) * 10
testFnc(x, sd) == sd(x) * 10

```

```{r}

x <- iris[,1:4]
apply(x, MARGIN = 2, mean)
```

# Zapamiętywanie środowiska

```{r}
withNaRm <- function(x, fnc) {
  fnc(x, na.rm = TRUE)
}

x <- c(1,2,3, NA)
mean(x)
mean(x, na.rm = TRUE)
withNaRm(x, mean)
```

```{r}
makeNaRm <- function(fnc) {
  function(...) {
    fnc(..., na.rm = TRUE)  
  }
}

rmMean <- makeNaRm(mean)
rmSD <- makeNaRm(sd)

x <- c(1,2,3,NA)
rmMean(x)
rmSD(x)
```

## xts

```{r}
library(xts)

ukgas <- as.xts(UKgas)
ukgas["1985"]
ukgas["1984/1985"]
ukgas["1984/"]
ukgas["/1961"]

gas <- ukgas["1984/1985"]

rollapply(gas, width = 3, align = "center", sum)
rollapply(gas, width = 3, align = "left", sum)
rollapply(gas, width = 3, align = "right", sum)
```

### xta apply

```{r}
ukgas <- as.xts(UKgas)
apply.yearly(ukgas, sum)
apply.yearly(ukgas, mean)
```

```{r}
library(quantmod)
index((EuStockMarkets[,1]))

data <- getSymbols("^GSPC", auto.assign = FALSE)
data <- data[,c(1,2,3,4)]
colnames(data) <- c("Open", "High", "Low", "Close")
class(data)

data.monthly <- apply.monthly(data, function(x) {
  x <- as.matrix(x)
  c(Open = x[1,1], High = max(x), Low = min(x), Close = x[nrow(x), ncol(x)])
})

plot(data[, "Close"], main = "SP500 daily vs monthly")
lines(data.monthly[, "Close"], col = "red", lwd = 2)
```

```{r}
close <- data.monthly[, "Close"]
close <- na.omit(diff(log(close)))

fit <- arima(close, c(1,0,0))
fit

fitModel <- function(x) {
  arima(x, c(1,0,0))
}

# Nie dziala!!!
# rollapply(close, align = "right", width = 24, fitModel)
```

```{r}
dt.env <- new.env()

dt.env$x <- 10

tmpFnc <- function() {
  x <- 20
}

envFnc <- function() {
  dt.env$x <- 20
}

dt.env$x <- 10
x        <- 10

tmpFnc()
x

dt.env$x
envFnc()
dt.env$x
```

# Powrót do xts

```{r}
result.env <- new.env()
result.env$result.list <- list()

fitModelEnv <- function(x) {
  
  end.date <- as.character(tail(index(x), 1))
  fit <- arima(x, c(1,0,0))
  result.env$result.list[[end.date]] <- fit

  return(1)
}

tmp <- rollapply(close, align = "right", width = 24, fitModelEnv)

result.list <- result.env$result.list

x <- result.list[[1]]

summary(x)

coef.list <- lapply(result.list, function(x) {
  c(x$coef[[1]], sqrt(x$var.coef[[1]]))
})

idx <- lubridate::ymd(names(coef.list))
coef.mat <- Reduce(rbind, coef.list)
coef.xts <- xts(coef.mat, order.by = idx)

plot(coef.xts[,1], ylim = c(-1,1))
lines(coef.xts[,1] - 2 * coef.xts[,2], lwd = 2, col = "red")
lines(coef.xts[,1] + 2 * coef.xts[,2], lwd = 2, col = "red")
abline(h = 0, col = "blue", lwd = 2)
```


```{r}
result.env <- new.env()
result.env$result.list <- list()
result.env$forecast.list <- list()

predictModelEnv <- function(x) {
  
  end.date <- as.character(tail(index(x), 1))
  
  xx <- head(x, -1)
  fit <- arima(xx, c(1,0,0))
  result.env$result.list[[end.date]] <- fit

  forecast <- predict(fit, 1)
    
  result.env$forecast.list[[end.date]] <- c(
    Forecast = forecast$pred[[1]],
    SE  = forecast$se[[1]],
    Raw = as.numeric(tail(x,1)))
  
  return(1)
}

tmp <- rollapply(close, align = "right", width = 24, predictModelEnv)

forecast.result <- Reduce(rbind, result.env$forecast.list)
forecast.result <- xts(forecast.result, order.by = lubridate::ymd(names(result.env$forecast.list)))

plot(forecast.result[,3], type = "p", pch = 19)
points(forecast.result[,1], pch = 19, col = "red")

plot(forecast.result[,3] - forecast.result[,1], pch = 19, type = "p")
abline(h = 0, col = "red", lty = 2)
lines(forecast.result[,2] * 2, col = "blue")
lines(-forecast.result[,2] * 2, col = "blue")
```
