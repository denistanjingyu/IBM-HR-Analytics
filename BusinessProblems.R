# To show High Turnover Volatility in the Sales Department
# This shows that RnD Department has the highest proportion of employees who voluntarily resigned
sum((ibm1$Attrition == 'Voluntary Resignation') & (ibm1$Department == 'Human Resources')) / sum(ibm1$Department == 'Human Resources')
sum((ibm1$Attrition == 'Voluntary Resignation') & (ibm1$Department == 'Research & Development')) / sum(ibm1$Department == 'Research & Development')
sum((ibm1$Attrition == 'Voluntary Resignation') & (ibm1$Department == 'Sales')) / sum(ibm1$Department == 'Sales')

# Aside: IBM2- Find Out Why these People Get Terminated
# Run logistic regression for those terminated against the info we will have during selection stage
ibm.m8 <- glm(Attrition ~ Age + Department + DistanceFromHome + Education + EducationField + `Employee Source`+ Gender + JobRole + MaritalStatus +AverageTenure + TotalWorkingYears, 
              family = binomial, 
              data = ibm2)
summary(ibm.m8)
vif(ibm.m8)
ibm.m9 <- glm(Attrition ~ Age + DistanceFromHome + `Employee Source`, 
              family = binomial, 
              data = ibm2)
summary(ibm.m9)
vif(ibm.m9)

# Shortlist candidates with info we have at the selection stage:
# Run logistic regression for those not terminated against the info we will have during selection stage
ibm.m5 <- glm(Attrition ~ Age + Department +DistanceFromHome + Education +EducationField + `Employee Source`+ Gender + JobRole + MaritalStatus +AverageTenure + TotalWorkingYears, 
              family = binomial, 
              data = ibm1)
summary(ibm.m5)
vif(ibm.m5)
ibm.m6 <- glm(Attrition ~ Age + Department + DistanceFromHome + Education+ `Employee Source` + Gender + JobRole + MaritalStatus, 
              family = binomial, 
              data = ibm1)
summary(ibm.m6)
vif(ibm.m6)
ibm.m7 <- glm(Attrition ~ Age + Department + DistanceFromHome + `Employee Source` + JobRole + MaritalStatus, 
              family = binomial, 
              data = ibm1)
summary(ibm.m7)
vif(ibm.m7)

# Match shortlisted candidates with relevant job openings
ibm3 <- ibm[ibm$Attrition == 'Current employee']
dim(ibm3)

# Run the CART model to profile current employees to Departments
cart3.ibm3 <- rpart(Department ~ Age + Department + DistanceFromHome + Education + EducationField + `Employee Source`+ Gender + JobRole + MaritalStatus +AverageTenure + TotalWorkingYears, 
                    data = ibm3, 
                    method = "class", 
                    control = rpart.control(minsplit = 500, cp = 0))
rpart.plot(cart3.ibm3)
plotcp(cart3.ibm3)
cart3.opt.ibm3 <- prune(cart3.ibm3, cp = 0.0022)
rpart.plot(cart3.opt.ibm3)
cart3.opt.ibm3$variable.importance

# Keep the current employees
# Run logistic regression for those not terminated 
ibm.m2 <- glm(Attrition ~ MonthlyIncome+ PercentSalaryHike + TrainingTimesLastYear + BusinessTravel + OverTime + StockOptionLevel + EnvironmentSatisfaction + JobSatisfaction + JobInvolvement + RelationshipSatisfaction + WorkLifeBalance, 
              family = binomial, 
              data = ibm1)
summary(ibm.m2)
vif(ibm.m2)
