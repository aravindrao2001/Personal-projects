library(odbc)
library(DBI)
library(tidyverse)
library(lubridate)
library(ggplot2)

con <- dbConnect(odbc(),Driver="sql server", Server ="met-sql19.bu.edu",Database ="NYC Real Estate",Port=1433)
NEIGHBORHOOD <- dbReadTable(con,"NEIGHBORHOOD")
NYC_TRANSACTION_DATA <-dbReadTable(con,"NYC_TRANSACTION_DATA")
BUILDING_CLASS <-dbReadTable(con,"BUILDING_CLASS")
BOROUGH <-dbReadTable(con,"BOROUGH")


df1<- NYC_TRANSACTION_DATA %>%
  left_join(NEIGHBORHOOD,by=c("NEIGHBORHOOD_ID"="NEIGHBORHOOD_ID"))%>%
  left_join(BUILDING_CLASS,by=c("BUILDING_CLASS_FINAL_ROLL"="X.BUILDING_CODE_ID"))%>%
  filter(NEIGHBORHOOD_ID==235,COMMERCIAL_UNITS>=0 ,RESIDENTIAL_UNITS >=0)%>%
  mutate(YEAR=year(SALE_DATE))%>%
  filter(YEAR>2008)

  

Total_units_sold <-group_by(df2,YEAR)%>%
  summarize(Total_units_sold=sum(COMMERCIAL_UNITS,RESIDENTIAL_UNITS))


df2<- NYC_TRANSACTION_DATA %>%
  left_join(NEIGHBORHOOD,by=c("NEIGHBORHOOD_ID"="NEIGHBORHOOD_ID"))%>%
  left_join(BUILDING_CLASS,by=c("BUILDING_CLASS_FINAL_ROLL"="X.BUILDING_CODE_ID"))%>%
  filter(TYPE=="RESIDENTIAL",NEIGHBORHOOD_ID==235,SALE_PRICE>0,GROSS_SQUARE_FEET>0)%>%
  mutate(YEAR=year(SALE_DATE))%>%
  filter(YEAR>2008)

summary(df2$SALE_PRICE)
summary(df2$GROSS_SQUARE_FEET)

mean_sale_price <- group_by(df2,YEAR)%>%
  summarize(x=mean(SALE_PRICE),y=mean(GROSS_SQUARE_FEET))

df3<- NYC_TRANSACTION_DATA %>%
  left_join(NEIGHBORHOOD,by=c("NEIGHBORHOOD_ID"="NEIGHBORHOOD_ID"))%>%
  left_join(BUILDING_CLASS,by=c("BUILDING_CLASS_FINAL_ROLL"="X.BUILDING_CODE_ID"))%>%
  filter(NEIGHBORHOOD_ID==235,TYPE!="NA")%>%
  mutate(YEAR=year(SALE_DATE))%>%
  filter(YEAR>2008)%>%
  group_by(TYPE)%>%
  summarize(units=n())


df4<- NYC_TRANSACTION_DATA %>%
  left_join(NEIGHBORHOOD,by=c("NEIGHBORHOOD_ID"="NEIGHBORHOOD_ID"))%>%
  left_join(BUILDING_CLASS,by=c("BUILDING_CLASS_FINAL_ROLL"="X.BUILDING_CODE_ID"))%>%
  filter(TYPE=="RESIDENTIAL",SALE_PRICE>0,GROSS_SQUARE_FEET>0)%>%
  mutate(YEAR=year(SALE_DATE))%>%
  filter(YEAR>2008)

sd(df4$SALE_PRICE)

cor(df4$SALE_PRICE,df4$GROSS_SQUARE_FEET)

dfb <-group_by(df4,NEIGHBORHOOD_ID)%>%
  summarize(median_price =median(SALE_PRICE),numberofsales=n(),saleprice=sd(SALE_PRICE))%>%
  filter(saleprice>0)

zscores <-scale(dfb[c(-1)])%>%
  as.data.frame()


ggplot(zscores)+geom_point(mapping=aes(x=median_price,y=numberofsales,size=saleprice))
    
k<-kmeans(zscores,center=3)

dfc<-cbind(dfb,k$cluster)

ggplot(dfb)+geom_point(mapping=aes(x=median_price,y=numberofsales,size=saleprice,color=k$cluster))                       

                           
df5<- NYC_TRANSACTION_DATA %>%
  left_join(NEIGHBORHOOD,by=c("NEIGHBORHOOD_ID"="NEIGHBORHOOD_ID"))%>%
  left_join(BUILDING_CLASS,by=c("BUILDING_CLASS_FINAL_ROLL"="X.BUILDING_CODE_ID"))%>%
  filter(TYPE=="RESIDENTIAL",SALE_PRICE>0,GROSS_SQUARE_FEET>0,NEIGHBORHOOD_ID==236)%>%
  mutate(YEAR=year(SALE_DATE))%>%
  filter(YEAR>2008)

average_residential <-group_by(df5,YEAR)%>%
  summarize(avg=mean(SALE_PRICE))

          

t.test(mean_sale_price$x,average_residential$avg,alternative="t",conf.level=0.95)      
