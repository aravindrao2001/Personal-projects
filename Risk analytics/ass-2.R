install.packages("ggplot")
library(ggplot2)

set.seed(97)

n_uni<- 100 #uniform random variables
n_trial <- 10000 #number of trials 

uni_samples <- matrix(runif(n_uni*n_trial ,min=0 ,max = 1), ncol = n_uni)


s_samples <- rowSums(uni_samples)
View(s_samples)


#	A histogram of the results of the MC simulation

ggplot(data.frame(s_samples),aes(x=s_samples))+geom_histogram(bins=50,fill="blue", col ="yellow",aes(y=..density..)) + 
  ggtitle("Histogram of uniform samples") + 
  xlab("Sum of 100 Uniform Samples") + 
  ylab("Density")


# density plot of the normal distribution
mean <- n_uni * 0.5 # mean of uniform distribution with min=0 and max=1 is 0.5
var <- n_uni * (1/12) # variance of uniform distribution with min=0 and max=1 is 1/12
std_dev <- sqrt(var)
x <- seq(mean - 4 * std_dev, mean + 4 * std_dev, length.out = 100)
View(x)

ggplot(data.frame(x), aes(x = x)) + 
  stat_function(fun = dnorm, args = list(mean = mean, sd = std_dev), geom = "line", color = "red") + 
  ggtitle("Density Plot of Normal Distribution") + 
  xlab("Sum of 100 Uniform Samples") + 
  ylab("Density")

# The mean and standard deviation of the MC simulation.
mean(s_samples)
sd(s_samples)


#Question 1b)
set.seed(97)
trials <-10000
n<-10
k<-3


uni_samples2 <- matrix(runif(trials*n,min=0,max=1), ncol = n)
View(uni_samples2)

k_lowest<-apply(uni_samples2,1,sort)[k,]
View(k_lowest)




hist(k_lowest, main = " 3rd Lowest histogram", xlab = "3rd Lowest Value", col = "red")

S1 <- k
S2 <- n+1-k
beta_dist <- dbeta(k_lowest, S1, S2)
View(beta_dist)
plot(density(beta_dist),col="blue",lwd=2,main="density")

density(beta_dist)

#Mean and standard deviation
mean(k_lowest)
sd(k_lowest)



#Question 2
set.seed(97)

# Define the rate of the exponential distribution
Rate <- 10

# Define the number of trials
n_trials1 <- 10000

# Simulate the time until the next purchase for each trial
time_purchase1 <- matrix(rexp(n_trials1*100, Rate),ncol=100)
View(time_purchase1)

a<-apply(time_purchase1,1,cumsum)

p<-t(a)

results<-matrix(0,nrow=nrow(p),ncol=ncol(p))

for(i in 1:nrow(p)){
  for(j in 1:ncol(p)){
    if(p[i,j]<=1){
      results[i,j]<-TRUE
    }
    else{
      results[i,j]<-FALSE
    }
  }
}

final_results<-rowSums(results)

hist(final_results)


# Calculate the number of purchases per day for each trial

purchases_per_day1 <- rpois(n_trials1, lambda = 10)

# Plot a histogram of the number of purchases per day
hist(purchases_per_day, 
     main = "Number of Purchases per Day",
     xlab = "Purchases",
     ylab = ?"Frequency")



#question 3

S1 <- 4.5
SL <- 39
tm <- 20
pm <- 115
bene <- 1000000
lap <- 0.003
Rate <- 0.065

# Define the number of trials
n_trials1 <- 10000

# Define the function to simulate the cash flows for one policyholder
simulate_cash_flows <- function() {
  # Simulate the time until the policyholder dies
  death_time <- rweibull(1, S1, SL)
  
  # If the policyholder dies during the term of the policy, pay the death benefit
  if (death_time <= term) {
    cash_flows <- c(rep(pm * 12, tm * 12), -bene)
  } else {
    cash_flows <- rep(pm * 12, tm * 12)
  }
  
  # Simulate the probability of the policyholder lapsing
  if (runif(1) < lap) {
    cash_flows <- 0
  }
  
  # Calculate the net present value of the cash flows
  npv <- sum(cash_flows / ((1 + Rate/12)^(1:length(cash_flows))))
  
  return(npv)
}

# Simulate the cash flows for each trial
set.seed(123)
npv <- replicate(n_trials1, simulate_cash_flows())

View(npv)
# Create a histogram of the NPV
hist(npv, breaks = 100, col = "skyblue", main = "Histogram of NPV")


# Calculate the mean and standard deviation of the NPV
mean_npv <- mean(npv)
sd_npv <- sd(npv)

# Calculate the profitability of the insurance company
profi <- mean_npv > 0
if (profi) {
  message("making a profit.")
} else {
  message("Not making a profit.")
}

# 95% confidence interval for the mean of the NPV
cp <- t.test(npv)$conf.int

# Interpret the result
message("	 95% confidence interval for the mean of the NPV (", cp[1], ", ", cp[2], ").")

#	How many iterations would be necessary to provide a 99% confidence interval with a half width of $200
n_ite <- ceiling((qnorm(0.995) * sd_npv / 200)^2)


message("The number of iterations needed for a 99% confidence interval with a half width of $200 is ", n_ite)

# The company can be 90% sure their npv will be at least x
x <- quantile(npv, 0.1, type = 1)


message("The company can be 90% sure their NPV will be at least $", round(x, 2), ".")

# The company can be 99% sure their npv will be at least y
y <- quantile(npv, 0.01, type = 1)


message("The company can be 99% sure their NPV will be at least $", round(y, 2), ".")







