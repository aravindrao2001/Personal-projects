#Installing and loading the packages
install.packages("triangle")
library(triangle)
library(tidyverse)


#Initialising the seed and number of trails
set.seed(91)
n <- 1000
x<-runif(n)

#Generate the demand for different ranges according to their respective probabilities
demand<-sapply(X=x,function(t)
{ if(t<0.35) rdunif(n=1,a=2000,b=5000)
  else if(t<0.75) rdunif(n=1,a=5001,b=10000)
  else if(t<0.95) rdunif(n=1,a=10001,b=14000)
  else rdunif(n=1,a=14001,b=15000)
})


hist(demand)

#Defining the cost parameters
fixed_cost_mean <- 300000000
fixed_cost_sd <- 60000000
variable_cost_min <- 77000
variable_cost_max <- 100000
variable_cost_mode <- 90000

#Defining the revenue parameters
retail_price <- 150000
discount_price <- 70000

#Function to calculate profit according to the demand along with corresponding fixed cost and variable cost
calculate_profits <- function(numboat) {
  profits <- c()
  for (i in demand) {
    fixed_cost <- rnorm(1, fixed_cost_mean, fixed_cost_sd)
    variable_cost <- rtriangle(1,variable_cost_min,variable_cost_max,variable_cost_mode)
    if (i < numboat) {
      revenue <- (i) * retail_price + (numboat - i) * discount_price
    }
    else {
      revenue <- numboat * retail_price
    }
    total_cost <- fixed_cost + variable_cost
    profit <- revenue - total_cost
    profits <- c(profits, profit)
  }
  return(profits)
}


#Profit for each simulation after 
numboat <- seq(2000, 15000, by=1000)
profits <- sapply(numboat,calculate_profits)

#Mean calculation
means <- apply(profits, 2, mean)
lower80 <- apply(profits, 2, function(numboat) quantile(numboat, 0.1))
upper80 <- apply(profits, 2, function(numboat) quantile(numboat, 0.9))
lower95 <- apply(profits, 2, function(numboat) quantile(numboat, 0.025))
upper95 <- apply(profits, 2, function(numboat) quantile(numboat, 0.975))


df <- data.frame(numboat, means, lower80, upper80, lower95, upper95)


ggplot(df, aes(x=numboat)) +
  geom_line(aes(y=means), color="blue") +
  geom_ribbon(aes(ymin=lower80, ymax=upper80), fill="blue", alpha=0.5) +
  geom_ribbon(aes(ymin=lower95, ymax=upper95), fill="blue", alpha=0.2) +
  xlab("Boat Production") +
  ylab("Profit") +
  ggtitle("GWS Profit with 80% and 95% Confidence Intervals")


production <- c(2000, 4000, 6000, 8000, 10000, 12000,14000)

profits1 <- lapply(production,calculate_profits)

# Combine profits into a single data frame
df <- data.frame(
  Production = rep(production, each=1000),
  Profit = unlist(profits1)
)

# Create density plots
ggplot(df, aes(x=Profit,fill=factor(Production))) +
  geom_density()+
  xlab("Profit") +
  ylab("Density") +
  ggtitle("GWS Profit Density by Boat Production Level")



numboat<-c(2000, 4000, 6000, 8000, 10000, 12000,14000)

#Function to calculate expected profit
calculate_expected_profit <- function(numboat) {
  profits <- calculate_profits(numboat)
  expected_profit <- mean(profits)
  return(-expected_profit)
}

#Function to calculate the 10th percentile of profit
calculate_10th_percentile_profit <- function(numboat) {
  profits <- calculate_profits(numboat)
  percentile_profit <- quantile(profits, 0.1)
  return(-percentile_profit)
}

#Function to calculate the probability of earning $50 million profit
calculate_profit_probability <- function(numboat, target_profit = 50000000) {
  profits <- calculate_profits(numboat)
  profit_probability <- mean(profits >= target_profit)
  return(-(profit_probability - 1))
}

#Optimizing for expected profit
expected_profit_opt <-round(optimize(f = calculate_expected_profit, interval = c(2000, 15000))$minimum)
expected_profit_opt 

#Optimizing for 10th percentile profit
percentile_profit_opt <- round(optimize(f = calculate_10th_percentile_profit, interval = c(2000, 15000))$minimum)
percentile_profit_opt 

#Optimizing for probability of earning $50 million profit
profit_probability_opt <- round(optimize(f = calculate_profit_probability, interval = c(2000, 15000))$minimum)
profit_probability_opt





#Question 2
set.seed(123)

liquidity <- 100000000
correlation <- -0.6
tax_rate <- 0.15

simulate <- function(a, b) {
  cd <- liquidity - a - b
  cd_return <- cd * 1.08
  
  a_mean <- 2 * a
  a_sd <- 3 * a
  b_mean <- 1.6 * b
  b_sd <- 2 * b
  
  if (a_mean^2 / sqrt(a_sd^2 + a_mean^2) < 0 | b_mean^2 / sqrt(b_sd^2 + b_mean^2) < 0) {
    return(NA)
  }
  
  a_return <- rlnorm(1, meanlog = log(a_mean^2 / sqrt(a_sd^2 + a_mean^2)), sdlog = sqrt(log(1 + a_sd^2 / a_mean^2)))
  b_return <- rlnorm(1, meanlog = log(b_mean^2 / sqrt(b_sd^2 + b_mean^2)), sdlog = sqrt(log(1 + b_sd^2 / b_mean^2)))
  
  total_return <- a_return + b_return + cd_return
  total_tax <- pmax(total_return - tax_rate * total_return, 0)
  total_profit <- total_return - total_tax
  
  return(total_profit)
}

objective_function <- function(x) {
  a <- x[1] * liquidity
  b <- x[2] * liquidity
  return(-simulate(a, b))
}

result <- optim(c(0.5, 0.5), fn = objective_function, lower = c(0, 0), upper = c(1, 1), method = "L-BFGS-B")

optimal_a <- result$par[1] * liquidity
optimal_b <- result$par[2] * liquidity

cat("Optimal investment in alternative A: $", round(optimal_a/1e6, 2), " million\n")
cat("Optimal investment in alternative B: $", round(optimal_b/1e6, 2), " million\n")




#Part B

set.seed(123)
simulate <- function(a, b) {
  cd <- liquidity - a - b
  cd_return <- cd * 1.08
  
  if (a <= 0 || b <= 0) {
    return(NA)
  }
  
  a_mean <- 2 * a + 1e-6
  a_sd <- 3 * a + 1e-6
  b_mean <- 1.6 * b + 1e-6
  b_sd <- 2 * b + 1e-6
  
  a_return <- rlnorm(1, meanlog = log(a_mean^2 / sqrt(a_sd^2 + a_mean^2)), sdlog = sqrt(log(1 + a_sd^2 / a_mean^2)))
  b_return <- rlnorm(1, meanlog = log(b_mean^2 / sqrt(b_sd^2 + b_mean^2)), sdlog = sqrt(log(1 + b_sd^2 / b_mean^2)))
  
  total_return <- a_return + b_return + cd_return
  total_tax <- pmax(total_return - tax_rate * total_return, 0)
  total_profit <- total_return - total_tax
  
  return(total_profit)
}

objective_function <- function(x) {
  a <- x[1] * liquidity
  b <- x[2] * liquidity
  total_profit <- -simulate(a, b)
  penalty <- pmax(0, 60000000 - a - b - liquidity * 1.08)
  return(total_profit - 100 * penalty)
}


result <- optim(c(0.5, 0.5), fn = objective_function, lower = c(0.01, 0.01), method = "L-BFGS-B", upper = c(0.99, 0.99))



optimal_a <- result$par[1] * liquidity
optimal_b <- result$par[2] * liquidity

cat("Optimal investment in alternative A: $", round(optimal_a/1e6, 2), " million\n")
cat("Optimal investment in alternative B: $", round(optimal_b/1e6, 2), " million\n")