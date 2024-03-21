library(odbc)
library(DBI)
library(tidyverse)
library(lubridate)
library(ggplot2)
library(forecast)

con <- dbConnect(odbc(),Driver="sql server", Server ="met-sql19.bu.edu",Database ="NYC Real Estate",Port=1433)
NEIGHBORHOOD <- dbReadTable(con,"NEIGHBORHOOD")
NYC_TRANSACTION_DATA <-dbReadTable(con,"NYC_TRANSACTION_DATA")
BUILDING_CLASS <-dbReadTable(con,"BUILDING_CLASS")
BOROUGH <-dbReadTable(con,"BOROUGH")

df1<- NYC_TRANSACTION_DATA %>%
  left_join(NEIGHBORHOOD,by=c("NEIGHBORHOOD_ID"="NEIGHBORHOOD_ID"))%>%
  left_join(BUILDING_CLASS,by=c("BUILDING_CLASS_FINAL_ROLL"="X.BUILDING_CODE_ID"))%>%
  filter(NEIGHBORHOOD_ID==235,TYPE=='RESIDENTIAL',SALE_PRICE>0)%>%
  mutate(YEAR=year(SALE_DATE))%>%
  filter(YEAR>2008)%>%
  mutate(q=quarter(SALE_DATE))%>%
  group_by(YEAR,q)


df2<-df1%>%
  summarise(total_sales=sum(SALE_PRICE))%>%
  mutate(qtr=c('Q1','Q2','Q3','Q4'))
df2$pd<-1:52
  m<-lm(formula=total_sales~pd,
      data=df2)
summary(m)

regmodel<-lm(df2,formula=total_sales~YEAR+qtr)
summary(regmodel)


plot(df2$pd,df2$total_sales)
ggplot(df2,aes(x=df2$pd,y=df2$total_sales))+geom_line()
ggplot(df2, aes(x = df2$pd, y =df2$total_sales) ) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE)

time_line<-ts(data=df2$total_sales,start=2009,frequency=4)

r<-ets(y=time_line,model="MAN")
plot(r)

forecast(r,8)%>%
  plot()



df4<-NYC_TRANSACTION_DATA %>%
  left_join(NEIGHBORHOOD,by=c("NEIGHBORHOOD_ID"="NEIGHBORHOOD_ID")) %>%
  left_join(BUILDING_CLASS,by=c("BUILDING_CLASS_FINAL_ROLL"="X.BUILDING_CODE_ID")) %>%
  filter(NEIGHBORHOOD_ID==235,SALE_PRICE>0,GROSS_SQUARE_FEET>0) %>%
  mutate(YEAR=year(SALE_DATE))%>%
  filter(YEAR>2008)%>%
  group_by(YEAR)

df.xy<-df4 %>%
  ungroup()%>%
  select(SALE_DATE,YEAR_BUILT,TYPE,GROSS_SQUARE_FEET,BUILDING_CLASS_FINAL_ROLL,RESIDENTIAL_UNITS,COMMERCIAL_UNITS,SALE_PRICE)

multireg<-lm(data=df.xy,formula=SALE_PRICE~.)
summary(multireg)

df.xy["residuals"]<-multireg$residuals

df.address<-df4%>%
  ungroup()%>%
  select(ADDRESS)
df.xy["address"]<-df.address$ADDRESS

