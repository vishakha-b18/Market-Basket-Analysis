########MARKET BASKET ANALYSIS, EATON RWDD
#######AUTHOR: Vishakha Bhattacharjee
#######Ver: 1.1
library('arulesViz')
library(arules)
library(readxl)
library(tidyverse)
library(plyr)
library(dplyr)
library(tidyselect)
library(rlang)
library(sqldf)  
library(ggplot2)
library(RColorBrewer)

#Reading Data
mba.1 = read_excel('Jan-May 2018.xlsx')
mba.2 = read_excel('June-Oct 2018.xlsx')
mba.3 = read_excel('Nov-Dec 2018.xlsx')
mba.4 = read_excel('Jan-May 2019.xlsx')
mba.5 = read_excel('June-July 2019.xlsx')


#descriptive analysis
nrow(mba.1)
nrow(mba.2)
nrow(mba.3)
nrow(mba.4)
nrow(mba.5)


#combining into a single data frame
mba_data = rbind(mba.1,mba.2,mba.3,mba.4,mba.5)
nrow(mba_data) #3535686
str(mba_data)

#Checking for NA records
sapply(mba_data, function(x) sum(is.na(x)))


#Selecting only those rows where the Customer Category (CUST_CATG) is 'Trade'
mba_data_trade = subset(mba_data, CUST_CATG == "00" | 
                          CUST_CATG == "01" | 
                          CUST_CATG == "02" | 
                          CUST_CATG == "03" | 
                          CUST_CATG == "04" | 
                          CUST_CATG == "05" | 
                          CUST_CATG == "06" | 
                          CUST_CATG == "07" | 
                          CUST_CATG == "09" | 
                          CUST_CATG == "10" | 
                          CUST_CATG == "11" | 
                          CUST_CATG == "12" | 
                          CUST_CATG == "13" | 
                          CUST_CATG == "14" | 
                          CUST_CATG == "15" | 
                          CUST_CATG == "16" | 
                          CUST_CATG == "17" | 
                          CUST_CATG == "18" | 
                          CUST_CATG == "19" | 
                          CUST_CATG == "30" | 
                          CUST_CATG == "31" | 
                          CUST_CATG == "32" | 
                          CUST_CATG == "33" | 
                          CUST_CATG == "34" | 
                          CUST_CATG == "35" | 
                          CUST_CATG == "36" | 
                          CUST_CATG == "37" | 
                          CUST_CATG == "39" | 
                          CUST_CATG == "50" | 
                          CUST_CATG == "52" | 
                          CUST_CATG == "53" | 
                          CUST_CATG == "54" | 
                          CUST_CATG == "56" | 
                          CUST_CATG == "57" | 
                          CUST_CATG == "58" | 
                          CUST_CATG == "59" | 
                          CUST_CATG == "70" | 
                          CUST_CATG == "80")

#Adding new calculated field for Order Value
mba_data_trade$order_val = mba_data_trade$ITEM_QTY_ORD * mba_data_trade$UNIT_AUTH_PRICE


######################################################  DATA PROCESSING
#CALCULATING TOTAL DISTINCT ORDERS IN THE DATASET
nrow(sqldf("select distinct(GO_NUM) from mba_data_trade"))


#REMOVING DUPLICATE ENTRIES OF SAME PRODUCTS IN THE ORDERS
df1 = sqldf("select * from (select *, row_number() over (partition by GO_NUM, CATALOG_NUM, 
                            PROD_CODE,PROD_LINE, PRODUCT_FAMILY_CODE order by order_val desc) RN
                            from mba_data_trade) where RN ==1")

#TEST CASE
df2 = sqldf("select GO_NUM, CATALOG_NUM, count(*) from df1 group by
                    GO_NUM, CATALOG_NUM 
                     having count(*) > 1") 


#KEEPING TRANSACTIONS WITH HIGHER ORDER VALUE FOR CASES WHERE SAME CATALOG_NUM
#IS PRESENT UNDER MORE THAN PROD_CODE
df3 = sqldf("select * from (select *, rank() over (partition by GO_NUM, 
              CATALOG_NUM ORDER BY ORDER_VAL DESC) RN1 from df1) where RN1 == 1")
)                             

#RECHECKING NO OF ORDERS
nrow(sqldf("select distinct(GO_NUM) from df3")) #347162 orders (SAME AS ABOVE)

#TEST CASE
#View(sqldf('select * from df3 where GO_NUM = "AP11903KHS" and CATALOG_NUM = "C"'))

#write.csv(df3, "MBA_Clean.csv")

#Calculating the average order value for each catalog_num
avg_val_df = (sqldf('select avg(order_val) as AVERAGE_ORDER_VALUE, 
                            count(*) as QUANTITY,
                            sum(order_val),
                            catalog_num from df3 group by CATALOG_NUM'))

################################ DATA MINING USING APRIORI ALGORITHM
#For naming the basket file
period = "TesRun"

#Using df3 for MBA
df = df3

#Grouping data by GO_NUM and transposing CATALOG_NUM to columns  
itemList <- ddply(df,c("GO_NUM"), 
                  function(df)paste(df$CATALOG_NUM, 
                                    collapse = ","))

#Removing Index Column								 
itemList1 = itemList[-c(1)]

#Renaming Product Column as items
colnames(itemList1) = "items"

#Creating a csv file for storing the basket (transposed) data for easy access.
#Running all the code above takes a very long time in case R crashes
write.csv(itemList1,paste0(period,".csv"), quote = FALSE, row.names = TRUE)

#Reading the data from the file in the form of Transactions
tr <- read.transactions(paste0(period,".csv"), format = 'basket', sep=',')

#For reference
summary(tr)


#Creating Rules using Apriori Algorithm, threshold for support = 0.01 and Confidence = 0.80
rules <- apriori(tr, parameter = list(supp= 0.01, conf=0.80))

#Sorting the rules first by Lift then by Confidence
rules <- sort(rules, by= c('lift','confidence'), decreasing = TRUE)

summary(rules)

#rule_eclat = eclat(tr, parameter = list(supp= 0.01))

#setting RHS as particular products
#rules_catalog_rhs <-apriori(data=tr, parameter=list(supp=0.01,conf = 0.80), 
#                            appearance = list(default="lhs",rhs="BCR120"))

#rules <- sort(rules_catalog_rhs, by='support', decreasing = TRUE)

#summary(rules)


#Pruning redundant rules (Supersets of rules which are already present are called redundant)
subset_rules <- which(colSums(is.subset(rules,rules)) > 1) # get subset rules in vector
subset_association_rules = rules[-subset_rules]

summary(subset_association_rules)

#Viewing the Top 10 Rules by Lift, Confidence
inspect(subset_association_rules[1:10])

#Opens a R tool for easy viewing of rules
inspectDT(subset_association_rules)


#Visualization

#Absolute Item Frequency
arules::itemFrequencyPlot(tr,ylim = c(0, 50000),
                          topN=10,type="absolute", col=brewer.pal(8,'Pastel2'), 
                          main="Top 10 Absolute Item Frequency Plot", xlab="Item Frequency")


#Relative Item Frequency
arules::itemFrequencyPlot(tr,xlim = c(0, 0.20), 
                          topN=20,col=brewer.pal(8,'Pastel2'),
                          main='Relative Item Frequency Plot',type="relative", horiz = TRUE)

#Plotting Top rules in a Graph format
topRules <- subset_association_rules[1:10]
plot(topRules)

plot(topRules, method="graph")

#Interactive scatter plot visualization for all rules
arulesViz::plotly_arules(subset_association_rules)


############################################################ Storing the rules

#Converting the rules to a dataframe
pruned_rule_fulldata = subset_association_rules
rule_fulldata = as(pruned_rule_fulldata,"data.frame")

#Writing the rules for easier access
write.csv(rule_fulldata, "FinalRules.csv")