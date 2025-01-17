install.packages("Ecdat")
install.packages("dplyr")
install.packages("caret")
install.packages("forecast")
library(Ecdat)
library(dplyr)

#Simple linear regression

#Question 1
data <- Caschool

#Question 2

str(data)


#Question 3
county_counts <- data %>% group_by(county) %>% summarize(num_districts = n())

top_counties <- county_counts %>% arrange(desc(num_districts)) %>% slice(1:16) %>% pull(county)

filtered_data <- data %>% filter(county %in% top_counties)


#Question 4
set.seed(100) # Set the seed provided for me 

train_index <- sample(nrow(data), floor(0.6*nrow(data)), replace = FALSE) # Index for training set

train <- data[train_index, ] # Subset the data into the training set using the index 

validation <- data[-train_index, ] # Subset remaining data into the validation set

#question 5
# Load the ggplot2 package
library(ggplot2)

# Create a scatterplot with a best-fit line using ggplot
ggplot(train, aes(x = mealpct, y = readscr)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  labs(x = "Percentage of students qualifying for free and reduced price lunches",
       y = "Average reading score in district") +
  theme_classic()


#Question 6
# Find the correlation between readscr and mealpct using the training set data
correlation <- cor(train$readscr, train$mealpct)

# Check for significance using cor.test()
cor.test(train$readscr, train$mealpct)

#question 7
# Fit a simple linear regression model with readscr as outcome and mealpct as input
lm_model <- lm(readscr ~ mealpct, data = train)

# Display the results of the model
summary(lm_model)

#question 8

# Get the residuals from the linear regression model
residuals <- resid(lm_model)
View(residuals)

# Find the minimum and maximum residual values
min_residual <- min(residuals)
max_residual <- max(residuals)

# Print the minimum and maximum residual values
cat("Minimum residual value:", min_residual, "\n")
cat("Maximum residual value:", max_residual, "\n")

#8 (a)

# Find the index of the observation with the highest residual value
max_residual_index <- which.max(residuals)


# Extract the data for the observation
train[max_residual_index, ]


# Get the actual and predicted readscr values for the observation
actual_readscr <- train[max_residual_index, "readscr"]
predicted_readscr <- predict(lm_model, newdata = train[min_residual_index,])

# Calculate the residual for the observation
residual <- actual_readscr - predicted_readscr

# Print the results
cat("District with highest residual:\n")
cat("Actual readscr:", actual_readscr, "\n")
cat("Predicted readscr:", predicted_readscr, "\n")
cat("Residual:", residual, "\n")



# 8 (b)

# Find the index of the observation with the lowest residual value
min_residual_index <- which.min(residuals)


# Extract the data for the observation
train[min_residual_index, ]


# Get the actual and predicted readscr values for the observation
actual_readscr1 <- train[min_residual_index, "readscr"]
predicted_readscr1 <- predict(lm_model, newdata = train[min_residual_index,])

# Calculate the residual for the observation
residual1 <- actual_readscr - predicted_readscr

# Print the results
cat("District with lowest residual:\n")
cat("Actual readscr:", actual_readscr1, "\n")
cat("Predicted readscr:", predicted_readscr1, "\n")
cat("Residual:", residual1, "\n")


#9

#to predict the reading score for a given value of a meal impact , seen from the summary statistics from the lm_model
summary(lm_model)

# Create a data frame with the input value of mealpct
new_data <- data.frame(mealpct = 50)

# Use predict() to generate the predicted value of readscr
predicted_score <- predict(lm_model, newdata = new_data)

# Print the predicted value of readscr
predicted_score



#10

# Load the forecast package
library(forecast)

# Make predictions on the training set
train_preds <- predict(lm_model, data = train)

# Make predictions on the validation set
val_preds <- predict(lm_model, data = validation)

# Calculate accuracy measures for the training set
train_accuracy <- accuracy(train_preds, train$readscr)

# Calculate accuracy measures for the validation set
val_accuracy <- accuracy(val_preds, validation$readscr)

# Print the RMSE and MAE for both the training set and validation set
cat("Training set RMSE:", train_accuracy[2], "\n")
cat("Validation set RMSE:", val_accuracy[2], "\n")
cat("Training set MAE:", train_accuracy[3], "\n")
cat("Validation set MAE:", val_accuracy[3], "\n")

#11
summary(lm_model)

# Extract the residual standard error
rse <- summary(lm_model)$sigma

# Get the degrees of freedom
df <- df.residual(lm_model)

# Calculate the standard deviation of the residuals
sd_resid <- sqrt(rse^2 * df/(df-2))





#Multiple Linear Regression

summary(data[, sapply(data, is.factor)])

n_distinct(data$district)


df_train <- train %>%
  select(-mathscr, -testscr,-district)

df2_validation <- validation %>%
  select(-mathscr, -testscr,-district)




#question 2

# Select the numerical variables of interest
numerical_vars <- df_train[, c("distcod","enrltot", "teachers", "calwpct","computer","compstu","expnstu","str","avginc","elpct","readscr")]

# Create a correlation matrix for the numerical variables
correlation_matrix <- cor(numerical_vars)

# Visualize the correlation matrix
install.packages("corrplot")
library(corrplot)
corrplot(correlation_matrix, method = "circle")

# after realizing multicollinearity from computer
numerical_vars1 <- df_train[, c("distcod","enrltot", "teachers", "calwpct","compstu","expnstu","str","avginc","elpct","readscr")]
correlation_matrix1 <- cor(numerical_vars1)
library(corrplot)
corrplot(correlation_matrix1, method = "circle")


#4
#4a
# I have picked Siskiyou County


#4b
# Subset the data for San Diego County
sd_data <- subset(df_train, county == "Siskiyou")

# Calculate the average reading score
mean(sd_data$readscr)


#4c
# Build a simple linear regression model
model_county <- lm(readscr ~ county, data = df_train)

# Summarize the model
summary(model_county)

#4d
# Predict the test score for Siskiyou County
predict(model_county, newdata = data.frame(county = "Siskiyou"))



#5
install.packages("car")
library(car)
# Set the predictors and response variable
predictors_backwards <- df_train[c("enrltot","computer", "teachers", "calwpct","compstu","expnstu","str","avginc","elpct")]
response <- df_train$readscr

# Fit the multiple regression model using backward elimination
model <- lm(response ~ ., data = predictors_backwards)
model_backward <- step(model, direction = "backward")

# Show summary of the final multiple regression model
summary(model_backward)



#6
# Calculate SSR and SST
SST <- sum((response - mean(response))^2)
SSR <- sum((predict(model_backward) - mean(response))^2)

# Calculate R-squared
R2 <- SSR / SST

# Print the R-squared value
cat("R-squared:", R2, "\n")

#find this in summary statistics
summary(model_backward)$r.squared # R-squared
summary(model_backward)$adj.r.squared # adjusted R-squared

#7
# Fit a linear regression model with the "computer" predictor
model_computer <- lm(readscr ~ computer, data = df_train)


summary(model_computer)


# Extract the t-value and degrees of freedom for the "computer" predictor
t_value <- summary(model_computer)$coefficients["computer", "t value"]

# Load the visualize package
library(visualize)

# Get the degrees of freedom for the model
df <- df.residual(model_computer)

# Create the t-distribution plot
visualize.t(t_value, df)


# Calculate the p-value
p_value <- pt(t_value, df)

# Calculate the percent of the curve that is shaded
percent_shaded <- (1 - p_value) * 100


#8
# Obtain the ANOVA table
anova_table <- anova(model_backward)

# Extract the F-statistic from the table
f_statistic <- anova_table$F[1]

#9
# Assign predictor values for a fictional school district
student_teacher_ratio <- 20
percent_free_lunch <- 50
avg_household_income <- 60000
percent_english_second_language <- 10
avg_class_size <- 25

# Define regression coefficients for each predictor
b0 <- 70
b1 <- -1
b2 <- -5
b3 <- 0.01
b4 <- -2
b5 <- -0.5

# Calculate predicted average test score using regression equation
predicted_score <- b0 + b1*student_teacher_ratio + b2*percent_free_lunch + b3*avg_household_income + b4*percent_english_second_language + b5*avg_class_size

predicted_score


#10
library(forecast)
# Make predictions on training and validation sets
train_preds_mlr <- predict(model_backward, newdata = df_train)
val_preds_mlr <- predict(model_backward, newdata = df2_validation)

# Calculate accuracy measures for training and validation sets
train_acc_mlr <- accuracy(train_preds_mlr, df_train$readscr)
val_acc_mlr <- accuracy(val_preds_mlr, df2_validation$readscr)

# Print accuracy measures
# Print the RMSE and MAE for both the training set and validation set
cat("Training set RMSE:", train_acc_mlr[2], "\n")
cat("Validation set RMSE:", val_acc_mlr[2], "\n")
cat("Training set MAE:", train_acc_mlr[3], "\n")
cat("Validation set MAE:", val_acc_mlr[3], "\n")


