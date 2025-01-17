set.seed(97)
n<- 10000

#normally distributing the travel sites
sa <-  rnorm(n,mean = 200,sd = 20)
sb <-  rnorm(n,mean = 50,sd = 10)
sc <-  rnorm(n,mean = 100,sd = 15)
sd <-  rnorm(n,mean = 150,sd = 30)
se <-  rnorm(n,mean = 100,sd = 30)
sf <-  rnorm(n,mean = 100,sd = 10)

total_call_centre <- (sa+sb+sc+sd+se+sf)
mean(total_call_centre)
sd(total_call_centre)


#question 1 part 2

hist(total_call_centre, col = "red",border = "khaki2" ,
     main = ("Total Call Center Demand"), 
     xlab = ("Total Hours of Calls/Per Week"), 
     ylab = ("No.of Calls/Frequency"))


#Question2
set.seed(97)
n <-100000
batterylife <- rnorm(100000,mean=84,sd=24)

batterymin <- pmin(batterylife,60)
View(batterymin)


Phones_less_than_5_years <- sum(batterymin<60)
View(Phones_less_than_5_years)

Total_battery_fall <- sum(60-batterymin)
View(Total_battery_fall)

replacment_cost<- ((10*Phones_less_than_5_years)+(Total_battery_fall*1.5))

replacment_cost/n

(Phones_less_than_5_years/n)*100

replacment_cost/Phones_less_than_5_years


#Question3

set.seed(97)
n<-100000 
cup_demand <- round(rnorm(100000, mean=125 , sd= 35))
View(cup_demand)

#expected_demand <- c(75, 100, 120, 140, 160,180 )

expected_demand<- sum(cup_demand=100)
View(expected_demand)

total_profit_75<-(expected_demand*2.75-expected_demand*0.65-100)
View(total_profit_75)



#Question3

set.seed(97)
n <- 100000


cups <- as.integer(abs
                      (rnorm(n,mean = 125, sd = 35)))



cost_cup <- (0.5+0.15)
cup_profit <- (2.75 - cost_cup)
rent <- (100)


sell_75 <- pmin(cups,75)

T_75 <- ((sell_75*cup_profit)-(rent))

L_75 <- ((75-sell_75)*0.5)

NP_75 <- sum((T_75-L_75)/n)



SL100 <- pmin(cups,100)
TR100 <- ((SL100*cup_profit)-(rent))
LS100 <- ((100-SL100)*0.5)
NP100 <- sum((TR100-LS100)/n)

SL120 <- pmin(cups,120)
TR120<- ((SL120*cup_profit)-(rent))
LS120<- ((120-SL120)*0.5)
NP120 <- sum((TR120-LS120)/n)


SL140 <- pmin(cups,140)
TR140<- ((SL140*cup_profit)-(rent))
LS140 <- ((140-SL140)*0.5)
NP140 <- sum((TR140-LS140)/n)

SL160<- pmin(cups,160)
TR160<- ((SL160*cup_profit)-(rent))
LS160 <- ((160-SL160)*0.5)
NP160 <- sum((TR160-LS160)/n)


SM180 <- pmin(cups,180)
TR180 <- ((SM180*cup_profit)-(rent))
LS180 <- ((180-SM180)*0.5)
NP180 <- sum((TR180-LS180)/n)


profit_calc <- data.frame(Cups_Per_Day= c('75','100','120','140','160','180'),
                           Profit_Per_Day = c(NP_75, NP100,
                                              NP120,NP140,
                                              NP160,NP180))
View(profit_calc)


Net_profit <- (TR160-LS160)
his <- hist(Net_profit,
                  freq = TRUE, 
                  col = "Khaki2",border = "blue" ,
                  main = ("Profit -histogram 160"), 
                  xlab = ("Profit"), 
                  ylab = ("Frequency"),
                  axes = TRUE)



