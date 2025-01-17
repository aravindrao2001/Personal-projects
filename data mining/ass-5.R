
#question 1
shipping_data <- read.csv("shippingdata.csv")

#question 2
dim(shipping_data)

#question 3
set.seed(200) # set a seed value for reproducibility
my_shipping_sample <- shipping_data[sample(nrow(shipping_data), 20, replace = FALSE), ]



#question 4 
#no NA values


#question 5
head(my_shipping_sample)



#question 6
# Scale the numeric columns
scaled_data<-scale(my_shipping_sample[,2:6])



# Build the hierarchical clustering model using single linkage
#Hierarchical clustering 

d<-dist(scaled_data,method="euclidean")


hiermodel <- hclust(d,method = "single")


# Plot the dendrogram with row names
#a Dendogram
hiermodel$name<-my_shipping_sample$name

plot(hiermodel,hang=-7,ann=FALSE,labels=hiermodel$name)


#b
#I see 17 clusters 


#c
# Cut the hierarchical clustering tree into 5 clusters
clusters <- cutree(hiermodel, k = 5)

# Show the resulting cluster assignments for each item
clusters


#d
# Assign clusters to the original dataset
library(dplyr)
original_data<-my_shipping_sample[,2:6]
original_data$clusters<-clusters

grouped<-original_data %>% 
  group_by(clusters)%>%
  summarize_all(list(mean=mean,sd=sd,median=median))



#e
library(ggplot2)
# create a data frame with the clustered data
clustered_data <- data.frame(my_shipping_sample[,2:7], cluster = clusters)

# create a scatterplot matrix with color-coded clusters
ggplot(clustered_data, aes(x = price...., y = weight..kg., color = factor(cluster))) + 
  geom_point() + 
  labs(title = "Scatterplot Matrix", x = "Price", y = "Weight (kg.)") + 
  theme_bw() + 
  facet_grid(. ~ cluster)


# Plot histogram with facet wrap based on clusters
ggplot(clustered_data, aes(x = height..m.)) +
  geom_histogram(binwidth = 0.1, color = "black", fill = "lightblue") +
  facet_wrap(~ cluster, nrow = 2) +
  ggtitle("Cluster Distribution Based on Height") +
  xlab("Height (m)") +
  ylab("Count")

# Create a violin plot with facet wrap based on clusters
ggplot(clustered_data, aes(x = factor(cluster), y = height..m., fill = factor(cluster))) +
  geom_violin() +
  ggtitle("Distribution of Height by Cluster") +
  xlab("Cluster") +
  ylab("Height (m)") +
  scale_fill_discrete(name = "Cluster")





#Question 8
# Create a weight vector
weights <- c(0.2, 0.1, 0.3, 0.3,0.2)

# Create a new dataframe with the weighted variables
weighted_shipping <- as.data.frame(lapply(original_data[, -6], "*", weights))

# View the first few rows of the weighted dataframe
head(weighted_shipping)


#8
#As the shipping cost may depend more on the size of the package than the weight, I will assign a higher weight to the size-related variables (length, width, and height) and a lower weight to the weight variable. Additionally, I will assign equal weights to the remaining two variables (price and clusters).








#9

# Create a weight vector
weights <- c(0.2, 0.1, 0.3, 0.3,0.2)

# Create a new dataframe with the weighted variables
weighted_shipping <- as.data.frame(lapply(original_data[, -6], "*", weights))

# View the first few rows of the weighted dataframe
head(weighted_shipping)



# Scale the numeric columns
scaled_data2<-scale(weighted_shipping)


d2<-dist(scaled_data2,method="euclidean")


hiermodel2 <- hclust(d2,method = "single")


# Plot the dendrogram with row names
#a Dendogram
hiermodel2$name<-my_shipping_sample$name

plot(hiermodel2,hang=-10000,ann=FALSE,labels=hiermodel2$name)


# Cut the hierarchical clustering tree into 5 clusters
clusters_updated <- cutree(hiermodel2, k = 5)

# Show the resulting cluster assignments for each item
clusters_updated

# Show the resulting cluster assignments for each item with their name
cbind(name = my_shipping_sample$name, clusters_updated)




library(dplyr)
original_data_updated<-my_shipping_sample[,2:6]
original_data_updated$clusters<-clusters_updated

grouped_updated<-original_data_updated %>% 
  group_by(clusters)%>%
  summarize_all(list(mean=mean,sd=sd,median=median))

















#text-mining 

#question1
# Read in the Simpsons dataset
simpsons <- read.csv("simpsons.csv")

# Subset the Simpsons dataset to only include episode 10
simpson_episode <- subset(simpsons, episode_id == 10) #seed 100



#question2
# Count frequency of each raw_location_text value in chosen episode
location_counts <- table(simpson_episode$raw_location_text)

# Sort location counts in descending order
location_counts <- location_counts[order(location_counts, decreasing = TRUE)]

# Create horizontal barplot of location counts
barplot(location_counts, horiz = TRUE, main = "Most Common Locations", 
        xlab = "Count", las = 1, cex.names = 0.45)





#question3

library(dplyr)
library(tidytext)

# Create new dataframe with only the spoken_words column
simpson_episode_words <- simpson_episode %>% 
  select(spoken_words)

# Create tidy version of the spoken_words column
simpson_episode_tidy <- simpson_episode_words %>% 
  unnest_tokens(word, spoken_words)





#question 4

# Count frequency of each word and show top 10
simpson_episode_tidy %>%
  count(word, sort = TRUE) %>%
  top_n(10)


#b
# download stopwords
data(stop_words)

# create new dataframe with one row for each word in spoken_words column
words <- simpson_episode %>%
  select(spoken_words) %>%
  unnest_tokens(word, spoken_words)

# remove stopwords
words_nostop <- anti_join(words, stop_words)

# count frequency of each word and show top 10 most common words
library(ggplot2)
words_nostop %>%
  count(word, sort = TRUE) %>%
  head(10) %>%
  ggplot(aes(x = n, y = reorder(word, n))) +
  geom_col() +
  labs(title = "10 Most Common Words", x = "Frequency", y = NULL) +
  theme_minimal()




#c
# Select spoken_words column and unnest into bigrams
simpson_episode_bigrams <- simpson_episode %>%
  select(spoken_words) %>%
  unnest_tokens(bigram, spoken_words, token = "ngrams", n = 2)

# Remove stop words
data("stop_words")
simpson_episode_bigrams <- cross_join(simpson_episode_bigrams, stop_words)

# Count frequency of each bigram and show top 10
top_words_bigram <- simpson_episode_bigrams %>%
  count(bigram, sort = TRUE) %>%
  head(10)




#question 5
library(wordcloud)
data(stop_words)
# generate a frequency table for each word
word_freq <- table(words_nostop$word)

# create wordcloud with 20 most common words
set.seed(100)
wordcloud(names(word_freq), freq = word_freq, max.words = 20, random.order = FALSE, scale=c(3,0.5))


#question 6

library(tidytext)
library(dplyr)
library(tidyr)


# Load bing lexicon

simpsons_sentiment <- words_nostop %>%
  inner_join(get_sentiments("bing")) %>%
  count(word, sentiment, sort = TRUE)%>%
  ungroup()


top_10_sentiment<-simpsons_sentiment%>%
  head(10)


#question 7

# Load the tidytext library
library(tidytext)

# Get the AFINN lexicon
afinn_lexicon <- get_sentiments("afinn")

# Join the words with the AFINN lexicon to obtain sentiment scores
word_scores_afinn <- words_nostop %>%
  inner_join(afinn_lexicon, by = "word")

# Find the worst 3 words based on the AFINN scores
worst_words_afinn <- word_scores_afinn %>%
  group_by(word) %>%
  summarize(sentiment = sum(value)) %>%
  arrange(sentiment) %>%
  slice(1:3)

# Find the best 3 words based on the AFINN scores
best_words_afinn <- word_scores_afinn %>%
  group_by(word) %>%
  summarize(sentiment = sum(value)) %>%
  arrange(desc(sentiment)) %>%
  slice(1:3)

cat("The worst 3 words in the episode based on AFINN scores:", worst_words_afinn$word)
cat("The best 3 words in the episode based on AFINN scores:", best_words_afinn$word)


# Join the words with the AFINN lexicon to obtain sentiment scores

# Sum all the sentiment values
total_sentiment_afinn <- sum(word_scores_afinn$value)

cat("The total sentiment score for the episode based on AFINN lexicon is:", total_sentiment_afinn)














