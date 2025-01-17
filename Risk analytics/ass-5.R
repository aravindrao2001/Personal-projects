# Define the mean and standard deviation of each outcome
rezone_bw_mean <- 3
rezone_bw_sd <- 0.6
rezone_sd_mean <- 1.8
rezone_sd_sd <- 0.36
rezone_swout_mean <- 0.7
rezone_swout_sd <- 0.14
fail_resell_mean <- 0.3
fail_resell_sd <- 0.06
fail_unsellable_mean <- 0.1
fail_unsellable_sd <- 0.2
bribery_mean <- 1.5
bribery_sd <- 0.3

# Define the costs
purchase_cost <- 0.40
bribery_cost <- 0.075
consultant_cost <- 0.05

# Define the EMV
emv <- 1.405
loss_threshold <- 0.2
n<-10000
results<-vector()

# Calculate the probability of losing at least $200k
for(i in 1:n){
  loss_bw <- plnorm(q = log(loss_threshold / (emv - purchase_cost - bribery_cost - consultant_cost)) + (rezone_bw_mean - 0.5 * rezone_bw_sd^2), mean = rezone_bw_mean, sd = rezone_bw_sd, lower.tail = TRUE)
  loss_sd <- plnorm(q = log(loss_threshold / (emv - purchase_cost - bribery_cost - consultant_cost)) + (rezone_sd_mean - 0.5 * rezone_sd_sd^2), mean = rezone_sd_mean, sd = rezone_sd_sd, lower.tail = TRUE)
  loss_swout <- plnorm(q = log(loss_threshold / (emv - purchase_cost - bribery_cost - consultant_cost)) + (rezone_swout_mean - 0.5 * rezone_swout_sd^2), mean = rezone_swout_mean, sd = rezone_swout_sd, lower.tail = TRUE)
  loss_resell <- plnorm(q = log(loss_threshold / (emv - purchase_cost - consultant_cost)) + (fail_resell_mean - 0.5 * fail_resell_sd^2), mean = fail_resell_mean, sd = fail_resell_sd, lower.tail = TRUE)
  loss_unsellable <- plnorm(q = log(loss_threshold / (emv - purchase_cost - consultant_cost)) + (fail_unsellable_mean - 0.5 * fail_unsellable_sd^2), mean = fail_unsellable_mean, sd = fail_unsellable_sd, lower.tail = TRUE)
  loss_bribery <- plnorm(q = log(loss_threshold / (bribery_mean - bribery_cost - consultant_cost)), mean = bribery_mean, sd = bribery_sd, lower.tail = TRUE)
  loss_probs <- c(loss_bw, loss_sd, loss_swout, loss_resell, loss_unsellable, loss_bribery)
  results[i] <- sum(loss_probs)
}


total_prob<-sum(results)


myvect <- c(-2,-1,0)
as.logical(myvect)

x <- c(12L,6L)
statement <- median(x)


vect1 <- c(1:4)

vect2 <- c(1:2)
vect1*vect2






























