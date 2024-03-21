
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