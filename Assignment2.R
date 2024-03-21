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
  filter(TYPE=="RESIDENTIAL",NEIGHBORHOOD_ID==235)%>%
  group_by(YEAR=year(SALE_DATE))

Sunset_park<-summarize(df1,total_sales_price=sum(SALE_PRICE),total_gross_square_feet=sum(GROSS_SQUARE_FEET))%>%
  mutate(AverageSalesPricePerSqft=total_sales_price/total_gross_square_feet)
  
df2<- NYC_TRANSACTION_DATA %>%
  left_join(NEIGHBORHOOD,by=c("NEIGHBORHOOD_ID"="NEIGHBORHOOD_ID"))%>%
  left_join(BUILDING_CLASS,by=c("BUILDING_CLASS_FINAL_ROLL"="X.BUILDING_CODE_ID"))%>%
  filter(TYPE=="RESIDENTIAL",NEIGHBORHOOD_ID==235,SALE_PRICE>0,GROSS_SQUARE_FEET>0)%>%
  group_by(YEAR=year(SALE_DATE))

Sunset_park2<-summarize(df1,total_sales_price=sum(SALE_PRICE),total_gross_square_feet=sum(GROSS_SQUARE_FEET))%>%
  mutate(AverageSalesPricePerSqft=total_sales_price/total_gross_square_feet)


df3<- NYC_TRANSACTION_DATA %>%
  left_join(NEIGHBORHOOD,by=c("NEIGHBORHOOD_ID"="NEIGHBORHOOD_ID"))%>%
  left_join(BUILDING_CLASS,by=c("BUILDING_CLASS_FINAL_ROLL"="X.BUILDING_CODE_ID"))%>%
  filter(TYPE=="RESIDENTIAL",NEIGHBORHOOD_ID==235|NEIGHBORHOOD_ID==234|NEIGHBORHOOD_ID==233,SALE_PRICE>0,GROSS_SQUARE_FEET>0)%>%
  group_by(YEAR=year(SALE_DATE))%>%
  group_by(NEIGHBORHOOD_ID)

Sunset_park3<-summarize(df3,total_sales_price=sum(SALE_PRICE),total_gross_square_feet=sum(GROSS_SQUARE_FEET))%>%
  mutate(AverageSalesPricePerSqft=total_sales_price/total_gross_square_feet)

ggplot(Sunset_park3,aes(x=NEIGHBORHOOD_ID,y=AverageSalesPricePerSqft))+geom_bar(stat = "identity")+
  geom_text(Sunset_park3,mapping=aes(label=AverageSalesPricePerSqft))
 
