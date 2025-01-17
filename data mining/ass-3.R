library(tidyverse)
library(caret)
library(dplyr)
library(FNN)
library(ggplot2)
# Question 1

# Reading the CSV files into the environment

topcharts<-read.csv('spot100.csv')
spotify <- read.csv('spotify.csv')


# Question 2 

mysong<-topcharts[topcharts$name == 'Shape of You',]
class(mysong)

# Question 3 

str(spotify) # looking at the dataset description 

spotify$target<-as.factor(spotify$target) # it was numerical so we converted it to factor. 

table(spotify$target)  # looking at the unique values here


# Question 4

anyNA(spotify) # used to look at if there are any NA values here.


# Question 5

spotify <- subset(spotify, select = -c(X, key, time_signature, mode))

colnames(spotify)

str(spotify)
# Question 6

set.seed(100)

train.index<-sample(c(1:nrow(spotify)),nrow(spotify)*0.6)
valid.index <- setdiff(row.names(spotify), train.index)  

train.df<-spotify[train.index,]

test.df<-spotify[valid.index,]


# Question 7 


# Part A

liked_songs <- train.df %>% filter(target == 1)
disliked_songs <- train.df %>% filter(target == 0)

# Create vector of variable names
numeric_vars <- c("acousticness", "danceability", "energy", "instrumentalness", 
                  "liveness", "loudness", "speechiness", "tempo", "valence")

#Part A&B
# Loop through variables and perform t-tests
for (var in numeric_vars) {
  t_test <- t.test(liked_songs[[var]], disliked_songs[[var]])
  cat("Variable:", var, "\n")
  cat("Mean of liked songs:", mean(liked_songs[[var]]), "\n")
  cat("Mean of disliked songs:", mean(disliked_songs[[var]]), "\n")
  cat("p-value:", t_test$p.value, "\n")
  cat("\n")
}

#Part-C
#Removing the insignificant variables

train.data<-subset(train.df, select = -c(energy,tempo,liveness))
test.data<-subset(test.df, select = -c(energy,tempo,liveness))

mysong.df<-subset(mysong,select=-c(id,name,key,mode,tempo,liveness,energy))
colnames(mysong.df)[1]="duration_ms"


# Question 8 

# Preprocess training data using only the first 7 columns
norm<- preProcess(train.data[, 1:7], method = c("center", "scale"))
train_norm<-train.data
train_norm[,1:7] <- predict(norm, train.data[, 1:7])


new.norm<-predict(norm,mysong.df)
new.norm<-new.norm[names(train_norm[,1:7])]

# Question 9
#K-nearest neighbor

nn<-kmodel<-knn(train=train_norm[,1:7],test=new.norm,cl=train_norm[,8,drop = TRUE],k=7)
row.names(train.data)[attr(nn,"nn.index")]

neighbors <- train_norm[c(34, 842, 1155, 249, 1088, 438,1004),]
neighbors %>% select (song_title,artist,target)



#question 10

accuracy.df <- data.frame(k = seq(1, 14, 1), accuracy = rep(0, 14))

# compute knn for different k on validation.
for(i in 1:14) {
  knn.pred <- knn(train_norm[, 1:7], valid_norm[, 1:7], 
                  cl = train_norm[, 8,drop=TRUE], k = i)
  accuracy.df[i, 2] <- confusionMatrix(knn.pred,valid_norm[, 8,drop=TRUE])$overall[1]
}

accuracy.df


#Question 11
library(ggplot2)

# Plot scatterplot of accuracy vs. k values
ggplot(accuracy.df, aes(x = k, y = accuracy)) +
  geom_point() +
  labs(x = "K value", y = "Accuracy")

#question 12
#K-nearest neighbor

nn1<-kmodel<-knn(train=train_norm[,1:7],test=new.norm,cl=train_norm[,8,drop = TRUE],k=10)
row.names(train.data)[attr(nn1,"nn.index")]

neighbors <- train_norm[c(34, 842, 1155, 249, 1088, 438,1004,789,52,742),]
neighbors %>% select (song_title,artist,target)


#Naive Bayes

install.packages("carData")
library(carData)

data(Chile)

#2 

# Create a table showing missingness by column
missing_table <- data.frame(
  Column_Name = names(Chile),
  Missing_Count = colSums(is.na(Chile)),
  Percent_Missing = round(colSums(is.na(Chile)) / nrow(Chile) * 100, 2)
)

# Print the table
print(missing_table)

#2 i

Chile_complete <- Chile[complete.cases(Chile$vote), ]

#2ii

# Filter variables with less than 1% missingness
library(tidyverse)
missing_table_filtered <- missing_table %>% filter(Percent_Missing < 1)

# Remove rows with NAs for these variables
Chile_complete1 <- Chile_complete %>% drop_na(missing_table_filtered$Column_Name)

# Verify that the new dataset doesn't have any missing values for the filtered variables
sapply(Chile_complete1, function(x) sum(is.na(x)))


#2iii
# Filter variables with more than 1% missingness
missing_table_filtered2 <- missing_table %>% 
  filter(Percent_Missing > 1) %>% 
  pull(Column_Name)

Chile_complete2 <- Chile_complete1 %>%
  mutate(across(all_of(missing_table_filtered2), ~ifelse(is.na(.), "No_data", as.character(.))))

#3
Chile_complete2$income <- factor(Chile_complete2$income)
sapply(Chile_complete2, class)


library(dplyr)

# Bin age into 4 equal frequency groups
Chile_complete2 <- Chile_complete2 %>% 
  mutate(age_group = cut(age, breaks = 4, labels = c("young", "middle-aged", "older", "elderly"), include.lowest = TRUE))


# Bin statusquo into 5 equal frequency groups with custom labels
Chile_complete3 <- Chile_complete2 %>%
  mutate(statusquo_group = cut(statusquo, breaks = 5, labels = c("Very negative", "Negative", "Neutral", "Positive", "Very positive"), include.lowest = TRUE))

#Bin population
Chile_complete4 <- Chile_complete3 %>%
  mutate(population_bin = cut(population, breaks = 5, labels = c("very low", "low", "medium", "high", "very high"), include.lowest = TRUE))


table(Chile_complete4$age_group)
table(Chile_complete4$statusquo_group)
table(Chile_complete4$population)



library(rsample)
set.seed(100)
chile_split <- initial_split(Chile_complete4, prop = 0.6)
chile_train <- training(chile_split)
chile_val <- testing(chile_split)



library(ggplot2)

# create a data frame with the vote and each input variable from the training set
df1 <- chile_train %>% select(vote, age_group)
df2 <- chile_train %>% select(vote, education)
df3 <- chile_train %>% select(vote, income)
df4 <- chile_train %>% select(vote, population_bin)
df5 <- chile_train %>% select(vote, statusquo_group)
df6 <- chile_train %>% select(vote, region)
df7 <- chile_train %>% select(vote, sex)

# create barplots with vote as the fill variable and each input variable as the x-axis variable
ggplot(df1, aes(x = age_group, fill = vote)) +
  geom_bar(position = "fill") +
  labs(title = "Age group vs Vote", x = "Age group", y = "Proportion")

ggplot(df2, aes(x = education, fill = vote)) +
  geom_bar(position = "fill") +
  labs(title = "Education vs Vote", x = "Education", y = "Proportion")

ggplot(df3, aes(x = income, fill = vote)) +
  geom_bar(position = "fill") +
  labs(title = "Income vs Vote", x = "Income", y = "Proportion")

ggplot(df4, aes(x = population_bin, fill = vote)) +
  geom_bar(position = "fill") +
  labs(title = "Population vs Vote", x = "Population", y = "Proportion")

ggplot(df5, aes(x = statusquo_group, fill = vote)) +
  geom_bar(position = "fill") +
  labs(title = "Statusquo vs Vote", x = "Statusquo", y = "Proportion")

ggplot(df6, aes(x = region, fill = vote)) +
  geom_bar(position = "fill") +
  labs(title = "region vs Vote", x = "region", y = "Proportion")

ggplot(df7, aes(x = sex, fill = vote)) +
  geom_bar(position = "fill") +
  labs(title = "sex vs Vote", x = "sex", y = "Proportion")

#income and sex doesn't have a higher predictive power
chile_train <- chile_train %>% select(-c("sex","income"))
chile_val <- chile_val %>% select(-c("sex","income"))


#Building a Naive Bayes model
inputs <- chile_train[, -which(names(chile_train) == "vote")]
response <- chile_train$vote

#Train the Naive Bayes model
library(e1071)
nb_model <- naiveBayes(inputs, response)
print(nb_model)


#8
# Make predictions on the training and validation sets
train_inputs <- chile_train[, -which(names(chile_train) == "vote")]
train_preds <- predict(nb_model, train_inputs)

val_inputs <- chile_val[, -which(names(chile_val) == "vote")]
val_preds <- predict(nb_model, val_inputs)

# Create confusion matrices
train_cm <- table(train_preds, chile_train$vote)
val_cm <- table(val_preds, chile_val$vote)

# Print confusion matrices
cat("Training set confusion matrix:\n")
print(train_cm)

cat("\nValidation set confusion matrix:\n")
print(val_cm)

# Calculate accuracy on training set
train_acc <- sum(diag(train_cm)) / sum(train_cm)
cat("Training set accuracy:", train_acc, "\n")

# Calculate accuracy on validation set
val_acc <- sum(diag(val_cm)) / sum(val_cm)
cat("Validation set accuracy:", val_acc, "\n")


#9
table(chile_train$vote)


#10
# Make predictions on the validation set
val_inputs <- chile_val[, -which(names(chile_val) == "vote")]
val_preds <- predict(nb_model, val_inputs, type = "raw")

# Create a data frame with the predicted probabilities and actual outcomes
val_probs <- data.frame(prob_yes = val_preds[, "Y"], actual = chile_val$vote)

# Sort the data frame by predicted probability of "YES" in descending order
val_probs_sorted <- val_probs[order(val_probs$prob_yes, decreasing = TRUE), ]

# Select the top 100 records
val_top100 <- val_probs_sorted[1:100, ]

sum(val_top100$actual == "Y")

sum(df2$actual == df2$predicted)/nrow(df2)


#question 11
view(chile_train)
person_vote <- data.frame(region= "C",
                          population=250000,
                          age=60,
                          education="S",
                          statusquo=1.30940,
                          vote="Y",
                          age_group="elderly",
                          statusquo_group="Very positive",
                          population_bin="very high")


person_vote_pred <- predict(nb_model,person_vote)
person_vote_pred

person_vote_prob <- predict(nb_model, person_vote, type = "raw")
person_vote_prob_Y <- person_vote_prob[,"Y"]
person_vote_prob_Y

