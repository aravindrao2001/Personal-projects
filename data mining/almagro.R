#Semester end project 

#Part 1: Data Preparation and Exploration 

#Loading the required libraries 
install.packages("tidyverse")
install.packages("lubridate")
install.packages("naniar")
install.packages('ggplot2')
install.packages('leaflet')

library(tidyverse)
library(lubridate)
library(naniar)
library(ggplot2)
library(leaflet)

#Reading the data set into the environment 
Buenos <- read.csv("buenos.csv")
View(Buenos)

#Creating a subset to contain record of "Almagro"
Almagro <- Buenos[Buenos$neighbourhood_cleansed== "Almagro",]
View(Almagro)

#Missing Values 
#Checking for NA values in the data set 
anyNA(Almagro)

# count the number of missing values in each column
missing_alma <- colSums(is.na(Almagro))

# print the missing value counts
print(missing_alma)

# print the total count of missing values
cat("Total missing values: ", sum(missing_alma))

#Treatment: Dropping the irrelevant columns 
alma_subset <- subset(Almagro, select = -c(id, listing_url,calendar_updated, bathrooms, 
                                           neighbourhood_group_cleansed, license, scrape_id, source, 
                                           last_scraped, name, description, picture_url, host_url, host_name, 
                                           host_since, host_location, host_about, host_thumbnail_url,
                                           host_picture_url, host_neighbourhood, host_listings_count, 
                                           neighbourhood, amenities, minimum_minimum_nights, maximum_minimum_nights, 
                                           minimum_maximum_nights, maximum_maximum_nights, calendar_last_scraped, 
                                           number_of_reviews_ltm, number_of_reviews_l30d, first_review, 
                                           last_review, review_scores_accuracy, review_scores_cleanliness,
                                           review_scores_checkin, review_scores_cleanliness, review_scores_checkin,
                                           review_scores_communication, review_scores_location, review_scores_value, 
                                           reviews_per_month))

View(alma_subset)

#re-checking for missing values 
# count the number of missing values in each column
missing_alma1 <- colSums(is.na(alma_subset))

# print the missing value counts
print(missing_alma1)

#removing missing value from the columns: bedrooms, beds and review score rating
alma2 <- alma_subset[!is.na(alma_subset$review_scores_rating), ]
alma3 <- alma2[!is.na(alma2$bedrooms), ]
alma4 <- alma3[!is.na(alma3$beds), ]

#re-checking for missing values 
# count the number of missing values in each column
missing_alma2 <- colSums(is.na(alma4))

# print the missing value counts
print(missing_alma2)

#checking the structure of the data set 
str(alma4)

#converting price to numeric data type 
alma4$price <- gsub("[\\$,]", "",alma4$price)
alma4$price <- as.numeric(alma4$price)

#Summary Statistics 
summary(alma4)

#For variable Price 
mean(alma4$price)
sd(alma4$price)
min(alma4$price)
max(alma4$price)
median(alma4$price)
length(alma4$price)

#For variable Review Score Rating
mean(alma4$review_scores_rating)
sd(alma4$review_scores_rating)
min(alma4$review_scores_rating)
max(alma4$review_scores_rating)
median(alma4$review_scores_rating)
length(alma4$review_scores_rating)

#Data Visualization 
library(ggplot2)
# Scatterplot of price vs. bedrooms
ggplot(alma4, aes(x = bedrooms, y = price, color = 'coral')) +
  geom_point() +
  labs(x = "No. of Bedrooms", y = "Price", title = "Price of the property v/s No. of Bedrooms")

# Barplot of the count of each room type
ggplot(alma4, aes(x = room_type)) +
  geom_bar(color = "white", fill = c("#FF7D75", "#EE6587", "#FFD505"))
  labs(title = "Count of room types") 
  
# Boxplot of review scores by room type
ggplot(alma4, aes(x = room_type, y = review_scores_rating)) +
  geom_boxplot()

# Histogram of the distribution of availability_365
ggplot(alma4, aes(x = availability_365)) +
  geom_histogram()

# Stacked area plot of availability over time
#ggplot(alma4, aes(x = date, y = has_availability, fill = property_type)) +
  #geom_area()

#Mapping
#Neighbourhood in map format
library(dplyr)
map_alma <- leaflet() %>% addTiles() %>% 
  addCircles(lng= alma4$longitude , lat= alma4$latitude)

# Adding markers
map_alma <- map_alma %>%
  addMarkers(lng = -58.41414, lat = -34.60593, popup = "Costliest") %>%
  addMarkers(lng = -58.41491, lat = -34.60498, popup = "Cheapest")

# Print the map
map_alma

#mapping the costliest and cheapest property in the neigbourhood
#the costliest property
#Property type: Entire Rental Unit
costly_alma <- leaflet() %>% addTiles() %>% setView(-58.41414, -34.60593, zoom = 18) %>%
  addMarkers(lng = -58.41414, lat = -34.60593, popup = "Costliest") 
costly_alma

#The cheapest property 
#Property type: Entire Rental Unit
cheap_alma <- leaflet() %>% addTiles() %>% setView( -58.41491, -34.60498, zoom = 18) %>%
  addMarkers(lng = -58.41491, lat = -34.60498, popup = "Cheapest")
cheap_alma

#Wordcloud

#loading the required libraries 
install.packages("tidytext")
library(tidytext)
install.packages("wordcloud")
library(wordcloud)
install.packages("textdata")
library(textdata)
install.packages("tidyr")
library(tidyr)

#extracting the overview column from the data set 
overview_alma <- select(alma4, neighborhood_overview)
View(overview_alma)

#tidy version of your episode text
tidy_version_alma <- overview_alma %>%
  unnest_tokens(word, neighborhood_overview)
View(tidy_version_alma)

#Removing stop words
#First loading the data set with stop words from tidy text package 
data(stop_words)

#Now removing the stopwords 
alma_no_stopwords <- anti_join(tidy_version_alma, stop_words, by = "word")
View(alma_no_stopwords)

#Using biagrams instead of unigrams 
# Generate tidy bigram data frame
tidy_bigrams_alma <- overview_alma %>%
  unnest_tokens(bigram, neighborhood_overview, token = "ngrams", n = 2)
tidy_bigrams_clean_alma <- tidy_bigrams_alma %>%
  separate(bigram, into = c("word1", "word2"), sep = " ") %>%
  filter(!word1 %in% stop_words$word) %>%
  filter(!word2 %in% stop_words$word) %>%
  filter(!is.na(word1)) %>% 
  filter(!is.na(word2)) %>%
  unite(bigram, word1, word2, sep = " ")
top_bigrams_clean_alma <- tidy_bigrams_clean_alma %>%
  count(bigram, sort = TRUE) %>%
  top_n(10)
top_bigrams_clean_alma

#Generating wordcloud for the neighbourhood overview
tidy_version_alma %>%
  anti_join(stop_words) %>%
  count(word) %>%
  with(wordcloud(word, n, max.words = 100))

# Load required packages
library(class)
library(dplyr)


#classification tree

# Load necessary packages
library(rpart)
library(rpart.plot)







#classification trees


# Bin the review_scores_rating variable

# Extract specified columns from alma4 and create new dataframe

# Create new dataframe with specified columns and filter for almagro neighborhood
# Filter for Almagro neighborhood and remove NA values
review_scores_almagro <- Buenos[Buenos$neighbourhood_cleansed == "Almagro", c("price","accommodates","bedrooms","beds","number_of_reviews","number_of_reviews_l30d","number_of_reviews_ltm","host_is_superhost","room_type","minimum_nights","has_availability")]
review_scores_almagro <- na.omit(review_scores_almagro)


#converting price to numeric data type 
review_scores_almagro$price <- gsub("[\\$,]", "",review_scores_almagro$price)
review_scores_almagro$price <- as.numeric(review_scores_almagro$price)






#binning review scores 
# Create the review score bins
review_scores_almagro$review_score_bin <- cut(review_scores_almagro$review_scores_rating, 
                                             breaks=10)


# Split data into training and testing sets
#question 2
set.seed(100)

train.idx<-sample(c(1:nrow(review_scores_almagro)),nrow(review_scores_almagro)*0.6)

part_train<-review_scores_almagro[train.idx,]

part_test<-review_scores_almagro[-train.idx,]


# Build pruned tree using training data
library(rpart)
tree_model <- rpart(review_score_bin~ accommodates+bedrooms+beds+price+number_of_reviews+number_of_reviews_l30d+number_of_reviews_ltm+host_is_superhost+room_type+minimum_nights , data = part_train, method = "class")

# Plot the tree
library(rpart.plot)
rpart.plot(tree_model, type = 2, extra = 2, main = "Classification Tree",
           box.col = c("#FFB6C1", "#00FFFF"), shadow.col = "gray")


#cross-validation
set.seed(100)
cv.ct <- rpart(review_score_bin~ accommodates+bedrooms+beds+price+number_of_reviews+number_of_reviews_l30d+number_of_reviews_ltm+host_is_superhost+room_type+minimum_nights , data = part_train, method = "class", minsplit = 5, cp = 0.001, xval = 5)
printcp(cv.ct)

opt_cp <- cv.ct$cptable[which.min(cv.ct$cptable[,"rel error"]),"CP"]

new_pruned<-rpart(review_score_bin ~ bedrooms + beds + room_type + accommodates + minimum_nights+price,data=part_train,method="class",cp=opt_cp)



rpart.plot(new_pruned ,type = 1, extra = 2, main = "pruned Tree",
           box.col = c("#FFB6C1", "#00FFFF"), shadow.col = "gray")





#KNN

Buenos_knn <-read.csv("Buenos.csv")

# Load necessary libraries
library(dplyr)
library(caret)
library(class)

# Filter the data for the selected amenity
amenity <- "Extra pillows and blankets"
data <- Buenos %>% 
  filter(grepl(amenity, amenities)) %>% # Filter for the selected amenity
  select(bedrooms, beds, amenities) %>% # Select relevant numerical predictors and the outcome variable
  na.omit() %>% # Remove rows with missing values
  group_by(amenities) %>% # Group by the selected amenity
  filter(n() > 1) %>% # Remove the amenities with only one record
  ungroup() # Ungroup the data

# Filter the data for the selected neighborhood
neighborhood <- "Almagro"
data_test <- Buenos %>% 
  filter(grepl(amenity, amenities)) %>% # Filter for the selected amenity
  filter(neighbourhood_cleansed == neighborhood) %>% # Filter for the selected neighborhood
  select(bedrooms, beds, amenities) %>% # Select relevant numerical predictors and the outcome variable
  na.omit() %>% # Remove rows with missing values
  group_by(amenities) %>% # Group by the selected amenity
  filter(n() > 1) %>% # Remove the amenities with only one record
  ungroup() # Ungroup the data

# Split the data into training and testing sets
set.seed(123)
trainIndex <- createDataPartition(data$amenities, p = .7, list = FALSE)
training <- data[trainIndex, ]
testing <- data_test



# Use the selected value of k to make predictions on the testing set
knnFit <- knn(train = training[, c("bedrooms", "beds")], 
              test = testing[, c("bedrooms", "beds")], 
              cl = training$amenities, 
              k = 5)

# Print the predicted amenities
print(knnFit)

# Calculate the accuracy of the predictions
accuracy <- mean(knnFit == testing$amenities)

