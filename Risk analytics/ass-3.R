#Question-1

#Installing and loading the packages
install.packages("triangle")
library(triangle)
library(tidyverse)


#Initialising the seed and number of trails
set.seed(100)
n <- 1000
x = runif(n)
#Generate the demand for different ranges according to their respective probabilities
#demand1 <- runif(0.35 * n, 2000, 3500)
#demand2 <- runif(0.40 * n, 3501, 7500)
#demand3 <- runif(0.20 * n, 7501, 11000)
#demand4 <- runif(0.05 * n, 11001, 15000)

demand<-sapply(X=x,function(t)
{
  if(t<0.35) rdunif(n=1,a=2000,b=5000)
  else if(t<0.75) rdunif(n=1,a=5001,b=10000)
  else if(t<0.95) rdunif(n=1,a=10001,b=14000)
  else rdunif(n=1,a=14001,b=15000)
})

hist(demand)

#Combined demand across all ranges
demand <- c(demand1, demand2, demand3, demand4)

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
      total_cost <- fixed_cost + variable_cost
      profit <- revenue - total_cost
      profits <- c(profits, profit)
    } else {
      revenue <- numboat * retail_price
      total_cost <- fixed_cost + variable_cost
      profit <- revenue - total_cost
      profits <- c(profits, profit)
    }
  }
  return(profits)
}


#Profit for each simulation after 
profit_4000 <- calculate_profits(4000)
profit_8000 <- calculate_profits(8000)
profit_12000 <- calculate_profits(12000)
profit_15000 <- calculate_profits(15000)

#Mean and standard deviation calculation
mean_4000<-mean(profit_4000)
sd_4000<-sd(profit_4000)

mean_8000<-mean(profit_8000)
sd_8000<-sd(profit_8000)

mean_12000<-mean(profit_12000)
sd_12000<-sd(profit_12000)

mean_15000<-mean(profit_15000)
sd_15000<-sd(profit_15000)

#Histogram for each simulation
par(mfrow = c(2, 2))
hist(profit_4000, main = "Profit Histogram (4000 boats)", xlab = "Profit")
hist(profit_8000, main = "Profit Histogram (8000 boats)", xlab = "Profit")
hist(profit_12000, main = "Profit Histogram (12000 boats)", xlab = "Profit")
hist(profit_15000, main = "Profit Histogram (15000 boats)", xlab = "Profit")




library(readr)
library(utils)
library(ggplot2)

#a
 part_sizes <- read.csv("problem.csv")                                   
 
 ggplot(data=part_sizes, aes(x = party_size)) + 
   geom_histogram(binwidth = 1, color = "black", fill = "lightblue") +
   labs(x = "Party Size", y = "Frequency", title = "Histogram of Party Sizes") 
 
 #b
 
 library(DescTools)
 mode_val <- Mode(part_sizes$party_size)
 shifted_data <- data.frame(party_size = (part_sizes$party_size - mode_val))
 
 library(MASS)
 
 # Shift the party sizes by subtracting 21
 party_sizes_shifted <- part_sizes
 
 
 party_sizes_shifted$party_size <- party_sizes_shifted$party_size
 
library(MASS)
 library(fitdistrplus)
 



#b
# Fit normal distribution
fit_norm_party <- fitdist(party_sizes_shifted$party_size, "norm")
summary(fit_norm_party)


# Subset the data to only include positive values
part_sizes_pos <- subset(part_sizes, party_size > 0)

# Fit gamma distribution
fit_gamma_party <- fitdist(part_sizes_pos$party_size, "gamma")
summary(fit_gamma_party)
 


# Fit lognormal distribution
fit_lnorm_party <- fitdist(part_sizes_pos$party_size, "lnorm")
summary(fit_lnorm_party)


#c
# Fit normal distribution
fit_norm_rev <- fitdist(party_sizes_shifted$rev_per_person, "norm")
summary(fit_norm_rev)
gofstat(fit_norm_rev)

# Subset the data to only include positive values
part_sizes_pos <- subset(part_sizes, party_size > 0)

# Fit gamma distribution
fit_gamma_rev <- fitdist(part_sizes_pos$rev_per_person, "gamma")
summary(fit_gamma_rev)
gofstat(fit_gamma_rev)

# Fit lognormal distribution
fit_lnorm_rev <- fitdist(part_sizes_pos$rev_per_person, "lnorm")
summary(fit_lnorm_rev)
gofstat(fit_lnorm_rev)

# Fit cauchy distribution
fit_cauchy_rev <- fitdist(party_sizes_shifted$rev_per_person, "cauchy")
summary(fit_cauchy_rev)
gofstat(fit_cauchy_rev)


fit_logistics_rev <- fitdist(party_sizes_shifted$rev_per_person, "logis")
summary(fit_logistics_rev)
gofstat(fit_logistics_rev)

fit_weibull_rev <- fitdist(part_sizes_pos$rev_per_person, "weibull")
summary(fit_weibull_rev)
gofstat(fit_weibull_rev)

#d
qqcomp(fit_gamma)
denscomp(fit_gamma)
#e
# Create a scatter plot
plot(party_sizes_shifted$party_size,part_sizes$rev_per_person,
     xlab = "Party Size", ylab = "Per Person Spending")

# Calculate the correlation coefficient
corr <- cor(party_sizes_shifted$party_size,part_sizes$rev_per_person)



#Monte-Carlo
# Set seed for reproducibility
set.seed(123)


mean_party_sizes <-mean(part_sizes$party_size)
mean_rev_per_person <-mean(part_sizes$rev_per_person)

# Number of trials
n <- 100000

# Correlation matrix
corr_mat <- matrix(c(1, corr, corr, 1), ncol = 2)

# Simulate correlated gamma distributions for party size and revenue per person
sim_data <- MASS::mvrnorm(n, mu = c(mean_party_sizes, mean_rev_per_person), Sigma = corr_mat)
partysize <- rgamma(n, shape = fit_gamma_party$estimate[1], rate = fit_gamma_party$estimate[2]) + 21
rev_person <- rgamma(n, shape = fit_gamma_rev$estimate[1], rate = fit_gamma_rev$estimate[2]) 

# Calculate total revenue for each trial
total_revenue <- partysize * rev_person

# Calculate mean and standard deviation of total revenue
mean_total_revenue <- mean(total_revenue)
sd_total_revenue <- sd(total_revenue)

# Create histogram of total revenue
ggplot(data.frame(total_revenue), aes(x = total_revenue)) +
  geom_histogram(binwidth = 100, fill = "steelblue", color = "white") +
  labs(x = "Total Revenue", y = "Frequency", title = "Histogram of Total Revenue")


#g
# Proportion of trials where total revenue is at least $5000
prop_revenue_5000 <- mean(total_revenue >= 5000)

# Print proportion
prop_revenue_5000




#h
#Creating a monte carlo simulation for 100,000 trails using the previous parameters

n<-100000
df<-data.frame(party_size=rgamma(n,fit_gamma_party$estimate[1],fit_gamma_party$estimate[2]) %>% round()+21,
               rev_per_person=rgamma(n,fit_gamma_rev$estimate[1],fit_gamma_rev$estimate[2]))



df$total_revenue<-df$party_size*df$rev_per_person

hist(df$total_revenue,main="Frequency")

mean(df$total_revenue)
sd(df$total_revenue)



