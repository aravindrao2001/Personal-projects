install.packages("ggplot2")
install.packages("leaflet")
library(dplyr)
library(lubridate)
library(tidyverse)
library(stringr)
library(ggplot2)
library(leaflet)

#2
apartments_toronto <- read.csv("apartments_toronto.csv");

#Function used to find types of data in each column
str(apartments_toronto);

#3
#Filtering My Data (as per ward assigned)
my_data <- filter(apartments_toronto, WARDNAME == "Humber River-Black Creek");
dim(my_data);
#My Data frame contains 844 rows, and 40 columns

#4
#a)
#Finding Total NA values in Data set
sum(is.na(my_data));

#b)
#Finding percentage of NA values for all variables
summary(my_data)
Percentage_NA <- (colMeans(is.na(my_data)*100) %>% sort(decreasing = TRUE)) %>% 
  data.frame();


#c) Removing variables with more than 50% NA values
final_data <- subset(my_data,select = -c(STORAGE_AREAS_LOCKERS,OTHER_FACILITIES));

#5
#a) Data type seen as character, and not date.
str(final_data)
#no type has dates, hence changing column Evaluation_Completed_On type to date
final_data$EVALUATION_COMPLETED_ON <- as.Date(final_data$EVALUATION_COMPLETED_ON, format = "%Y-%m-%d");
str(final_data$EVALUATION_COMPLETED_ON)
#Filtering Bday Month
My_month <- final_data %>%
  filter(month(ymd(EVALUATION_COMPLETED_ON))==8);

#6
#a)
str(final_data$WARD)
#b)
#1)
storey_median <- median(final_data$CONFIRMED_STOREYS);
#2)
storey_mean <- mean(final_data$CONFIRMED_STOREYS);

#Percentage of buildings which needs evaluation needed to be conducted in 3 years
z<-final_data %>%
  group_by(RESULTS_OF_SCORE) %>%
  tally() %>%
  data.frame()

z$percentage<-(z$n/sum(z$n))*100

# Find the oldest property
y<- arrange(final_data,YEAR_BUILT)

y$SITE_ADDRESS[[10]]
y$SCORE[[10]]
y$YEAR_EVALUATED[[10]]
y$YEAR_BUILT[[10]]

#7)
final_1 <- mutate(final_data, Quarters = quarter(final_data$EVALUATION_COMPLETED_ON))
final_1$Quarters <- str_replace(final_1$Quarters,"1","Winters") %>%
  str_replace("2", "Spring") %>% 
  str_replace("3","Summer") %>% 
  str_replace("4", "Fall");

final_1$Quarters

#8)
#Making a Bargraph
h_data <- group_by(final_1,Quarters)
barplot_hdata <- ggplot(data = h_data, aes(x= Quarters))+geom_bar(color = "red",
                                                            fill = "cadetblue") +
  ggtitle("Count of Confirmed Storeys Each Season")+
  xlab("seasons")+
  ylab("Count Per Quarter")

barplot_hdata

#9
g_data <- aggregate(final_1$GRAFFITI, by = list(final_1$PROPERTY_TYPE), FUN = mean)

#Making Barplot for Graffiti Rating 
barplot_gdata <- ggplot(g_data,aes(x = Group.1, y = x))+
  geom_bar(stat = "identity", fill = "cadetblue", color = "khaki2")+
  ggtitle("Graffiti Rating Mean Score")+
  xlab("Type of Property")+
  ylab("Mean of Graffity Rating")
barplot_gdata



#10
#make a histogram that shows the distribution of the 'SCORE' variable

ggplot(final_1, aes(x = SCORE)) +
  geom_histogram(fill = "skyblue", color = "white", bins = 25) +
  labs(x = "Score", y = "Frequency", title = "Distribution of Scores")

#11
ggplot(final_1, aes(x = GRAFFITI)) +
  geom_histogram(fill = "red", color = "white", bins = 10) +
  labs(x = "Graffiti Score", y = "Frequency", title = "Distribution of Graffiti Scores")

#12

ggplot(final_1, aes(x = SCORE, fill = RESULTS_OF_SCORE)) +
  geom_histogram(color = "white", bins = 20, position = "dodge") +
  facet_wrap(~RESULTS_OF_SCORE, scales = "free_y") +
  labs(x = "Score", y = "Frequency", title = "Distribution of Scores by Results of Score") +
  theme(legend.position = "top", panel.spacing = unit(0.5, "lines"))

#13




final_1$SITE_ADDRESS<-as.character(final_1$SITE_ADDRESS)
x<-final_data
for(i in x){
  x$address <- trimws(sub("[0-9]+", " ", x$SITE_ADDRESS))
}

final_1 <- final_1 %>%
  mutate(Address=x$address) 

df_final<-final_1%>%
  group_by(Address)%>%
  summarize(n=n())%>%
  arrange(desc(n))%>%
  filter(row_number()<=5)

y<-df_final$Address

final_df<-final_1 %>%
  filter(Address %in% y)

final_df$Address

ggplot(final_df,aes(x=YEAR_BUILT,y=SCORE))+geom_point(size=2)+
  ggtitle("Year Built vs Score for five most common streets")+
  xlab("Year built")+
  ylab("Score")

#14

  m<- leaflet() %>%
  addTiles() %>%
  addCircles(lng = -79.51595, lat = 43.74740) 
print(m)
#15

q<-leaflet() %>%
  addTiles() %>%
  addCircles(lng = -79.51595, lat = 43.74740) %>%
  addProviderTiles(providers$CartoDB.Positron)
print(q)



