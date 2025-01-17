install.packages("arules")
library(arules)

 data("Groceries")
summary(Groceries)

#question1
class(Groceries)
dim(Groceries)


#question2
# Get the item frequency
item_freq <- itemFrequency(Groceries)

# Sort the item frequency in decreasing order and select the top 12
top_items <- names(sort(item_freq, decreasing = TRUE)[1:12])

barplot(item_freq[top_items], col = "darkcyan", main = "Top 12 Grocery Items", 
        xlab = "Grocery Item", ylab = "Frequency", 
        cex.axis = 0.8,cex.lab = 0.8,cex.names = 0.8)




#question3


rules1 <- apriori (data=Groceries, parameter=list (supp=0.001,conf = 0.08), appearance = list (default="lhs",rhs="tropical fruit"), control = list (verbose=F)) 
rules_conf1 <- sort (rules1, by="confidence", decreasing=TRUE) # 'high-confidence' rules.
inspect(head(rules_conf1,n=1))


rules2 <- apriori (data=Groceries, parameter=list (supp=0.001,conf = 0.08), appearance = list (default="rhs",lhs="tropical fruit"), control = list (verbose=F)) 
rules_conf2 <- sort (rules2, by="confidence", decreasing=TRUE) # 'high-confidence' rules.
inspect(head(rules_conf2,n=1))



#question5
install.packages("arulesViz")
library(arulesViz)

rules3 <- apriori (data=Groceries, parameter=list (supp=0.001,conf = 0.08), appearance = list (default="lhs",rhs="tropical fruit"), control = list (verbose=F)) 
rules_conf3 <- sort (rules3, by="confidence", decreasing=TRUE) # 'high-confidence' rules.
inspect(head(rules_conf3,n=3))
rules_subset <- rules_conf3[1:3] # Select the first 3 rules
plot(rules_subset, method = "scatterplot")



rules4 <- apriori (data=Groceries, parameter=list (supp=0.001,conf = 0.08), appearance = list (default="rhs",lhs="tropical fruit"), control = list (verbose=F)) 
rules_conf4 <- sort (rules4, by="confidence", decreasing=TRUE) # 'high-confidence' rules.
inspect(head(rules_conf4,n=3))
rules_subset2 <- rules_conf4[1:3] # Select the first 3 rules
plot(rules_subset2, method = "scatterplot")



#question 6
rules5 <- apriori (data=Groceries, parameter=list (supp=0.001,conf = 0.08), appearance = list (default="lhs",rhs="tropical fruit"), control = list (verbose=F)) 
rules_conf5 <- sort (rules5, by="confidence", decreasing=TRUE) # 'high-confidence' rules.
inspect(head(rules_conf5,n=3))
rules_subset3 <- rules_conf5[1:3] # Select the first 3 rules
plot(rules_subset3, method = "graph",engine="htmlwidget")


rules6 <- apriori (data=Groceries, parameter=list (supp=0.001,conf = 0.08), appearance = list (default="rhs",lhs="tropical fruit"), control = list (verbose=F)) 
rules_conf6 <- sort (rules6, by="confidence", decreasing=TRUE) # 'high-confidence' rules.
inspect(head(rules_conf6,n=3))
rules_subset4 <- rules_conf6[1:3] # Select the first 3 rules
plot(rules_subset4, method = "graph",engine="htmlwidget")



#classification tree


#question 1
library(Ecdat)
part_df <- as.data.frame(Participation)

?Participation




#question 2
set.seed(100)

train.idx<-sample(c(1:nrow(part_df)),nrow(part_df)*0.6)

part_train<-part_df[train.idx,]

part_test<-part_df[-train.idx,]


#3

library(tree)
set.seed(100)  # set a random seed for reproducibility
tree_model <- tree(lfp ~ ., data = part_train)
summary(tree_model)

library(rpart)

tree<-rpart(lfp~lnnlinc+age+educ+nyc+noc+foreign,data=part_train,method="class")

#4
library(rpart.plot)
rpart.plot(tree,fallen.leaves = FALSE,type=3,extra=4)

rpart.plot(tree, type = 2, extra = 104, main = "Classification Tree",
           box.col = c("#FFB6C1", "#00FFFF"), shadow.col = "gray")

rpart.plot(tree,fallen.leaves = FALSE,type=4,extra=2,varlen=0,cex=0.6,box.palette = c("green","yellow","red"))



#question 9

tree2<-rpart(lfp~lnnlinc+age+educ+nyc+noc+foreign,data=part_train,method="class",cp=0, minsplit=1)
rpart.plot(tree2, type = 1,split.font = 1, varlen = -10,branch=0.2, extra = 1,  main = "Classification Tree",
           box.col = c("#FFB6C1", "#00FFFF"), shadow.col = "gray")


#question 10
set.seed(100)
cv.ct<-rpart(lfp~lnnlinc+age+educ+nyc+noc+foreign,data=part_train,method="class",minsplit=2,cp=0,xval=5)
printcp(cv.ct)

opt_cp <- cv.ct$cptable[which.min(cv.ct$cptable[,"xerror"]),"CP"]

#question 11
new_pruned<-rpart(lfp~lnnlinc+age+educ+nyc+noc+foreign,data=part_train,method="class",cp=opt_cp)

#question 12
rpart.plot(new_pruned, type = 1,split.font = 1, varlen = -10,branch=0.2, extra = 1,  main = "Pruned Tree",
           box.col = c("#FFB6C1", "#00FFFF"), shadow.col = "gray")

#question 12a

# Create confusion matrices using the caret package

library(caret)

# make predictions on train data
tree_pred <- predict(tree, newdata = part_train, type = "class")

# create confusion matrix for train data
cm <- confusionMatrix(data = tree_pred, reference = part_train$lfp)
print(cm)

# extract accuracy from confusion matrix
accuracy <- cm$overall[1]
print(paste("Accuracy:", round(accuracy, 4)))



# make predictions on test data
tree_pred1 <- predict(tree, newdata = part_test, type = "class")

# create confusion matrix for test data
cm1 <- confusionMatrix(data = tree_pred1, reference = part_test$lfp)
print(cm1)

# extract accuracy from confusion matrix
accuracy1 <- cm1$overall[1]
print(paste("Accuracy:", round(accuracy1, 4)))



#question 12b

# make predictions on train data pruned
tree_pred_prune <- predict(new_pruned, newdata = part_train, type = "class")

# create confusion matrix for train data
cm_prune <- confusionMatrix(data = tree_pred_prune, reference = part_train$lfp)
print(cm_prune)

# extract accuracy from confusion matrix
accuracy2 <- cm_prune$overall[1]
print(paste("Accuracy:", round(accuracy2, 4)))



# make predictions on test data pruned
tree_pred_prune2 <- predict(new_pruned, newdata = part_test, type = "class")

# create confusion matrix for test data pruned
cm_prune2 <- confusionMatrix(data = tree_pred_prune2, reference = part_test$lfp)
print(cm_prune2)

# extract accuracy from confusion matrix
accuracy3 <- cm_prune2$overall[1]
print(paste("Accuracy:", round(accuracy3, 4)))










