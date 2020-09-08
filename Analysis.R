ibm <- fread('ibm.clean.csv')

# Import required libraries 
library(car)
library(caret)
library(caTools)
library(corrplot)
library(data.table)
library(ggplot2)
library(rpart)
library(rpart.plot)

# Preparing the data for analysis
# Change suitable variables to factor data type
ibm$Attrition <- as.factor(ibm$Attrition)
ibm$BusinessTravel <- as.factor(ibm$BusinessTravel)
ibm$Department <- as.factor(ibm$Department)
ibm$Education <- as.factor(ibm$Education)
ibm$EducationField <- as.factor(ibm$EducationField)
ibm$'Employee Source'  <- as.factor(ibm$'Employee Source')
ibm$EnvironmentSatisfaction <- as.factor(ibm$EnvironmentSatisfaction)
ibm$Gender <- as.factor(ibm$Gender)
ibm$JobInvolvement <- as.factor(ibm$JobInvolvement)
ibm$JobLevel <- as.factor(ibm$JobLevel)
ibm$JobRole <- as.factor(ibm$JobRole)
ibm$JobSatisfaction <- as.factor(ibm$JobSatisfaction)
ibm$MaritalStatus <- as.factor(ibm$MaritalStatus)
ibm$OverTime <- as.factor(ibm$OverTime)
ibm$PerformanceRating <- as.factor(ibm$PerformanceRating)
ibm$RelationshipSatisfaction <- as.factor(ibm$RelationshipSatisfaction)
ibm$StockOptionLevel <- as.factor(ibm$StockOptionLevel)
ibm$WorkLifeBalance <- as.factor(ibm$WorkLifeBalance)

# We as.integer these variables.
ibm$DistanceFromHome <- as.integer(ibm$DistanceFromHome)
ibm$MonthlyIncome <- as.integer(ibm$MonthlyIncome)
ibm$PercentSalaryHike <- as.integer(ibm$PercentSalaryHike)

# Drop all factor levels with 0 count
ibm <- droplevels(ibm)
summary(ibm)

# Create a prior years of experience column to better visualize the employee experience profile 
ibm$PriorYearsOfExperience <- ibm$TotalWorkingYears - ibm$YearsAtCompany

# Create a new feature average tenure to profile employees' average stay at previous companies
ibm$AverageTenure <- ibm$PriorYearsOfExperience / ibm$NumCompaniesWorked
# Average tenure produces values such as Inf due to the nature of deriving it
ibm$AverageTenure[!is.finite(ibm$AverageTenure)]<-0
summary(ibm$AverageTenure)

# Analyse and split the data according to whether the employees are terminated or not
# Current Employees and Voluntary Resignation
ibm1 <- ibm[ibm$Attrition != 'Termination']
ibm1 <- droplevels(ibm1)
dim(ibm1)
summary(ibm1)

# Current Employees and Terminated
ibm2<- ibm[ibm$Attrition != 'Voluntary Resignation']
ibm2<-droplevels(ibm2)
dim(ibm2)  
summary(ibm2)

# Data exploration - searching for insights
# plots for univariate analysis
ggplot(ibm) + geom_bar(aes(x = Attrition))
ggplot(ibm) + geom_density(aes(x=Age))
ggplot(ibm) + geom_bar(aes(x=Department))
ggplot(ibm) + geom_bar(aes(x=JobRole))
ggplot(ibm) + geom_bar(aes(x=Education)) + facet_grid(~EducationField)
ggplot(ibm) + geom_bar(aes(x=Gender))

# Multiplot of "Years" theme to discover any meaningful trend
plot.TotalWorkingYears <- ggplot(ibm) + geom_density(aes(TotalWorkingYears))
plot.YearsAtCompany <- ggplot(ibm) + geom_density(aes(YearsAtCompany))
plot.YearsSinceLastPromotion <- ggplot(ibm) + geom_density(aes(YearsSinceLastPromotion))
plot.YearsWithCurrManager <- ggplot(ibm) + geom_density(aes(YearsWithCurrManager))
plot.YearsInCurrentRole <- ggplot(ibm) + geom_density(aes(YearsInCurrentRole))
plot.PriorYearsOfExperience <- ggplot(ibm) + geom_density(aes(PriorYearsOfExperience))
grid.arrange(plot.TotalWorkingYears, plot.YearsAtCompany, plot.YearsSinceLastPromotion, 
             plot.YearsWithCurrManager, plot.YearsInCurrentRole, plot.PriorYearsOfExperience, 
             nrow = 2, ncol = 3)

# Finding out the proportion of employees below certain years of experience (Chosen 1, 3, 5, 7, 10 years)
# 58% of employees have less than 3 years of work experience before entering IBM
# Possible problems: Undeveloped skillsets, young employee base, immature "work' mindset, 'jumpship' culture
length(which(ibm$PriorYearsOfExperience < 1)) / length(ibm$PriorYearsOfExperience)   # 0.32
length(which(ibm$PriorYearsOfExperience < 3)) / length(ibm$PriorYearsOfExperience)   # 0.58
length(which(ibm$PriorYearsOfExperience < 5)) / length(ibm$PriorYearsOfExperience)   # 0.70
length(which(ibm$PriorYearsOfExperience < 7)) / length(ibm$PriorYearsOfExperience)   # 0.79
length(which(ibm$PriorYearsOfExperience < 10)) / length(ibm$PriorYearsOfExperience)  # 0.85


# Only 22% of employees are below 30 years old, employee base not exactly that young as expected
length(which(ibm$Age < 30))/length(ibm$Age)
# Check education profile
summary(ibm$Education)
# Around 39% of employees are degree holders and 27% pursued Master's Degree
# Pursue of higher education might have led to decreased work experience
length(which(ibm$Education == 3)) / length(ibm$Education)
length(which(ibm$Education == 4)) / length(ibm$Education)

# plots for multivariate analysis
# for variables attainable at the hiring stage:
ggplot(data = ibm1) + geom_bar(aes(x = EducationField , fill = Attrition), position = 'fill') + facet_grid(.~Department)
ggplot(data = ibm1) + geom_bar(aes(x = Education , fill = Attrition), position = 'fill') + facet_grid(.~Department)
ggplot(data = ibm1) + geom_bar(aes(x = Education , fill = Attrition), position = 'fill') + facet_grid(.~JobRole)
ggplot(data = ibm1) + geom_bar(aes(x = EducationField , fill = Attrition), position = 'fill') + facet_grid(.~JobRole) + theme(axis.text.x=element_text(angle = -90, hjust = 0))

ggplot(ibm1) + geom_bar(aes(x=Age, fill=Attrition), position = 'fill') #Age against attrition. 
ggplot(ibm1) + geom_bar(aes(x=Department, fill=Attrition), position = 'fill') #Department against attrition
ggplot(ibm1) + geom_bar(aes(x=DistanceFromHome, fill=Attrition), position = 'fill')
ggplot(ibm1) + geom_bar(aes(x=`Employee Source`, fill=Attrition), position = 'fill')
ggplot(ibm1) + geom_bar(aes(x=JobRole, fill = Attrition), position = 'fill')
ggplot(ibm1) + geom_bar(aes(x=MaritalStatus, fill = Attrition), position = 'fill')
ggplot(ibm1) + geom_bar(aes(AverageTenure, fill = Attrition), position = 'fill')
ggplot(ibm1) + geom_bar(aes(x=Education, fill=Attrition), position='fill')
ggplot(ibm1) + geom_bar(aes(x=EducationField, fill=Attrition),position ='fill')
ggplot(ibm1) + geom_bar(aes(x=Gender, fill=Attrition), position='fill')

# for variables attainable only after employment

# plot attrition against monthly income
ggplot(ibm1) + geom_boxplot(aes(Attrition, MonthlyIncome))

# plot attrition against percentage salary hike
ggplot(ibm1) + geom_boxplot(aes(Attrition, PercentSalaryHike))

# plot attrition against training times last year
ggplot(ibm1) + geom_bar(aes(TrainingTimesLastYear, fill = Attrition), position = 'fill')

# plot attrition against business travel
ggplot(ibm1) + geom_bar(aes(BusinessTravel, fill = Attrition), position = 'fill')

# plot attrition against overtime
ggplot(ibm1) + geom_bar(aes(OverTime, fill = Attrition), position = 'fill')

# plot attrition against stock option level
ggplot(ibm1) + geom_bar(aes(StockOptionLevel, fill = Attrition), position = 'fill')

# plot attrition against stock environmental satisfaction
ggplot(ibm1) + geom_bar(aes(EnvironmentSatisfaction, fill = Attrition), position = 'fill')

# plot attrition against job satisfaction
ggplot(ibm1) + geom_bar(aes(JobSatisfaction, fill = Attrition), position = 'fill')

# plot attrition against job involvement
ggplot(ibm1) + geom_bar(aes(JobInvolvement, fill = Attrition), position = 'fill')

# plot attrition against relationship satisfaction
ggplot(ibm1) + geom_bar(aes(RelationshipSatisfaction, fill = Attrition), position = 'fill')

# plot attrition against work life balance
ggplot(ibm1) + geom_bar(aes(WorkLifeBalance, fill = Attrition), position = 'fill')

# Boxplot showing Monthlyincome distribution for all 4 levels of Jobsatisfaction from 1-4
# No obvious signs that higher income leads to higher job satisfaction
ggplot(data = subset(ibm, !is.na(JobSatisfaction)), aes(JobSatisfaction, MonthlyIncome)) + geom_boxplot()

# Check correlation between various "Years" metrics to detect anomalies
# Correlation of 0.6266406 (Expected to have medium/strong correlation, no weird relationship detected)
cor(ibm$TotalWorkingYears, ibm$YearsAtCompany, use = "complete.obs")
# Correlation of 0.7584772 (Shows that role/rank tends to stagnate after working long enough? Examine together with below point)
cor(ibm$YearsAtCompany, ibm$YearsInCurrentRole, use = "complete.obs")
# Correlation of 0.6154823 (After several years of working, promotion might be harder due to lack of high ranking positions? Examine further later)
cor(ibm$YearsAtCompany, ibm$YearsSinceLastPromotion, use = "complete.obs")
# Correlation of 0.770201 (Veteran employees tend to work together with the same manager. Both parties role/rank stagnate?)
cor(ibm$YearsAtCompany, ibm$YearsWithCurrManager, use = "complete.obs")


# Scatterplot of monthly income vs total working years and years at company respectively
ggplot(ibm) + geom_point(aes(TotalWorkingYears, MonthlyIncome))
ggplot(ibm) + geom_point(aes(YearsAtCompany, MonthlyIncome))
# Use Correlation function as scatterplot above was not very obvious in showing relationship
# Correlation of 0.7633158 (Relatively strong relationship between totalworkingyears and monthlyincome, not unexpected)
cor(ibm$TotalWorkingYears, ibm$MonthlyIncome, use = "complete.obs")
# Correlation of 0.5017943 (Employees working at IBM do not experience a strong rise in monthly income with increase in number of years worked)
cor(ibm$YearsAtCompany, ibm$MonthlyIncome, use = "complete.obs")    


#Find out relationship between worklifebalance and monthlyincome
#Main observation: Employees who rated work life balance of 1 also have significantly lower median monthly income
#Low work life balance and low income? A problem the HR department needs to examine...
ggplot(data = subset(ibm, !is.na(WorkLifeBalance)), aes(WorkLifeBalance, MonthlyIncome)) + geom_boxplot()

# Check the salary difference among males and females for possible gender discrimination
# No signs of gender discrimination, in fact females earning marginally higher on average disregarding all other factors
ggplot(data = subset(ibm, !is.na(Gender)), aes(Gender, MonthlyIncome, fill = Gender)) +
  geom_boxplot() + theme(legend.position = "none", plot.title = element_text(hjust = 0.5, size = 10)) +
  labs(x = "Gender", y = "Monthly Income", title = "Monthly Income Distribution Across Gender") +
  coord_flip()

# Examine various metrics against job roles

# Compare the monthly income across all job roles
# Manager and research director has significantly higher income than all others
# Laboratory technician, research scientist and sales representative have severely depressed income
ggplot(data = subset(ibm, !is.na(JobRole))) + geom_boxplot(aes(JobRole, MonthlyIncome)) +
  ggtitle("Monthly Income for All Job Roles")

# Compare the age started working across all job roles
# Manager and research director roles started working at 18-20 years old while all others at 25 average (Justify their higher income)
ggplot(data = subset(ibm, !is.na(JobRole))) + geom_boxplot(aes(JobRole, AgeStartedWorking)) +
  ggtitle("Age Started Working for All Job Roles")
# Compare the age across all job roles
# Once again, manager and research director have higher median age probably because they started working earlier
ggplot(data = subset(ibm, !is.na(JobRole))) + geom_boxplot(aes(JobRole, Age)) +
  ggtitle("Age Across All Job Roles")
# Compare the years at company across all job roles
# Manager and research director spent longest time at company (median 12 and 9 years respectively) compared to other roles
# Sales representatives have significantly lower years at company, coincide with them being lowest income
ggplot(data = subset(ibm, !is.na(JobRole))) + geom_boxplot(aes(JobRole, YearsAtCompany)) +
  ggtitle("Years At Company Across All Job Roles")

# Compare the education level for all job roles
# Sales representative strikes out as the role with lower education level compared to the rest
# Might be a reason for their low salary
ggplot(data = na.omit(ibm)) + geom_bar(aes(JobRole, fill = Education), position = "fill") +
  ggtitle("Education Level for All Job Roles") + ylab("Proportion")

# Logistic Regression model===============================================================


# Model 1--------------------------------------
model1 <- glm(Attrition ~ Age+ Department+ DistanceFromHome + `Employee Source`+ JobRole + MaritalStatus + AverageTenure + PriorYearsOfExperience + Gender + Education + EducationField, family = binomial, data = ibm1)
summary(model1)
vif(model1)
probmodel1 <- predict(model1, type = 'response')
threshold1 <- sum(ibm1$Attrition == 'Voluntary Resignation')/length(ibm1$Attrition)
threshold2 <- 0.5
pass.hat1 <- ifelse(probmodel1>threshold2, 'Voluntary Resignation', 'Current employee')
table(ibm1$Attrition, pass.hat1)
mean(pass.hat1==ibm1$Attrition)
OR1 <- exp(coef(model1))
OR1
ORCI1 <- exp(confint(model1))
ORCI1

# Train-test split
# usually stratify and split on a 70:30% basis
set.seed(2004)
train <- sample.split(Y = ibm1$Attrition, SplitRatio = 0.7)
trainset <- subset(ibm1, train == T)
testset <- subset(ibm1, train == F)

# Need to check the distribution of Y in the train test sets
summary(trainset$Attrition)
summary(testset$Attrition)

trainm1 <- glm(Attrition ~ Age+ Department+ DistanceFromHome + `Employee Source`+ JobRole + MaritalStatus + AverageTenure + PriorYearsOfExperience + Gender + Education + EducationField, family = binomial, data = trainset)
summary(trainm1)
probtestm1 <- predict(trainm1, type = 'response', newdata = testset)
pass.hat.testm1 <- ifelse(probtestm1>threshold2, 'Voluntary Resignation', 'Current employee')
table(testset$Attrition, pass.hat.testm1)
mean(pass.hat.testm1==testset$Attrition)

probtrainm1 <- predict(trainm1, type = 'response')
pass.hat.trainm1 <- ifelse(probtrainm1>threshold2, 'Voluntary Resignation', 'Current employee')
table(trainset$Attrition, pass.hat.trainm1)
mean(pass.hat.trainm1==trainset$Attrition)

# remove education field----------------------------
model2 <- glm(Attrition ~ Age + Department + DistanceFromHome + `Employee Source` + JobRole + MaritalStatus + AverageTenure + PriorYearsOfExperience + Education + Gender, family = binomial, data = ibm1)
summary(model2)
vif(model2)
probmodel2 <- predict(model2, type = 'response')

pass.hat2 <- ifelse(probmodel2>threshold2, 'Voluntary Resignation', 'Current employee')
table(ibm1$Attrition, pass.hat2)
mean(pass.hat2==ibm1$Attrition)
OR2 <- exp(coef(model2))
OR2
ORCI2 <- exp(confint(model2))
ORCI2

trainm2 <- glm(Attrition ~ Age+ Department+ DistanceFromHome + `Employee Source`+ JobRole + MaritalStatus + AverageTenure + PriorYearsOfExperience + Gender + Education, family = binomial, data = trainset)
summary(trainm2)
probtestm2 <- predict(trainm2, type = 'response', newdata = testset)
pass.hat.testm2 <- ifelse(probtestm2>threshold2, 'Voluntary Resignation', 'Current employee')
table(testset$Attrition, pass.hat.testm2)
mean(pass.hat.testm2==testset$Attrition)

probtrainm2 <- predict(trainm2, type = 'response')
pass.hat.trainm2<- ifelse(probtrainm2>threshold2, 'Voluntary Resignation', 'Current employee')
table(trainset$Attrition, pass.hat.trainm2)
mean(pass.hat.trainm2==trainset$Attrition)

# remove gender--------------------------
model3 <- glm(Attrition ~ Age + Department + DistanceFromHome + `Employee Source` + JobRole + MaritalStatus + AverageTenure + PriorYearsOfExperience + Education, family = binomial, data = ibm1)
summary(model3)
vif(model3)
probmodel3 <- predict(model3, type = 'response')
pass.hat3 <- ifelse(probmodel3>threshold2, 'Voluntary Resignation', 'Current employee')
table(ibm1$Attrition, pass.hat3)
mean(pass.hat3==ibm1$Attrition)
OR3 <- exp(coef(model3))
OR3
ORCI3 <- exp(confint(model3))
ORCI3

trainm3 <- glm(Attrition ~ Age+ Department+ DistanceFromHome + `Employee Source`+ JobRole + MaritalStatus + AverageTenure + PriorYearsOfExperience + Education, family = binomial, data = trainset)
summary(trainm3)
probtestm3 <- predict(trainm3, type = 'response', newdata = testset)
pass.hat.testm3 <- ifelse(probtestm3>threshold2, 'Voluntary Resignation', 'Current employee')
table(testset$Attrition, pass.hat.testm3)
mean(pass.hat.testm3==testset$Attrition)

probtrainm3 <- predict(trainm3, type = 'response')
pass.hat.trainm3<- ifelse(probtrainm3>threshold2, 'Voluntary Resignation', 'Current employee')
table(trainset$Attrition, pass.hat.trainm3)
mean(pass.hat.trainm3==trainset$Attrition)

# remove education------------------------------
model4 <- glm(Attrition ~ Age + Department + DistanceFromHome + `Employee Source` + JobRole + MaritalStatus + AverageTenure + PriorYearsOfExperience, family = binomial, data = ibm1)
summary(model4)
vif(model4)
probmodel4 <- predict(model4, type = 'response')
pass.hat4 <- ifelse(probmodel4>threshold2, 'Voluntary Resignation', 'Current employee')
table(ibm1$Attrition, pass.hat4)
mean(pass.hat4==ibm1$Attrition)
OR4 <- exp(coef(model4))
OR4
ORCI4 <- exp(confint(model4))
ORCI4

trainm4 <- glm(Attrition ~ Age+ Department+ DistanceFromHome + `Employee Source`+ JobRole + MaritalStatus + AverageTenure + PriorYearsOfExperience, family = binomial, data = trainset)
summary(trainm4)
probtestm4 <- predict(trainm4, type = 'response', newdata = testset)
pass.hat.testm4 <- ifelse(probtestm4>threshold2, 'Voluntary Resignation', 'Current employee')
table(testset$Attrition, pass.hat.testm4)
mean(pass.hat.testm4==testset$Attrition)

probtrainm4 <- predict(trainm4, type = 'response')
pass.hat.trainm4<- ifelse(probtrainm4>threshold2, 'Voluntary Resignation', 'Current employee')
table(trainset$Attrition, pass.hat.trainm4)
mean(pass.hat.trainm4==trainset$Attrition)

# remove employee source-------------------------------
model5 <- glm(Attrition ~ Age + Department + DistanceFromHome + JobRole + MaritalStatus + AverageTenure + PriorYearsOfExperience, family = binomial, data = ibm1)
summary(model5)
vif(model5)
probmodel5 <- predict(model5, type = 'response')
pass.hat5 <- ifelse(probmodel5>threshold2, 'Voluntary Resignation', 'Current employee')
table(ibm1$Attrition, pass.hat5)
mean(pass.hat5==ibm1$Attrition)
OR5 <- exp(coef(model5))
OR5
ORCI5 <- exp(confint(model5))
ORCI5

trainm5 <- glm(Attrition ~ Age+ Department+ DistanceFromHome+ JobRole + MaritalStatus + AverageTenure + PriorYearsOfExperience, family = binomial, data = trainset)
summary(trainm5)
probtestm5 <- predict(trainm5, type = 'response', newdata = testset)
pass.hat.testm5 <- ifelse(probtestm5>threshold2, 'Voluntary Resignation', 'Current employee')
table(testset$Attrition, pass.hat.testm5)
mean(pass.hat.testm5==testset$Attrition)

probtrainm5 <- predict(trainm5, type = 'response')
pass.hat.trainm5<- ifelse(probtrainm5>threshold2, 'Voluntary Resignation', 'Current employee')
table(trainset$Attrition, pass.hat.trainm5)
mean(pass.hat.trainm5==trainset$Attrition)

# remove averagetenure----------------------------------
model6 <- glm(Attrition ~ Age + Department + DistanceFromHome + JobRole + MaritalStatus + PriorYearsOfExperience, family = binomial, data = ibm1)
summary(model6)
vif(model6)
probmodel6 <- predict(model6, type = 'response')
pass.hat6 <- ifelse(probmodel6>threshold2, 'Voluntary Resignation', 'Current employee')
table(ibm1$Attrition, pass.hat6)
mean(pass.hat6==ibm1$Attrition)
OR6 <- exp(coef(model6))
OR6
ORCI6 <- exp(confint(model6))
ORCI6

trainm6 <- glm(Attrition ~ Age+ Department+ DistanceFromHome+ JobRole + MaritalStatus + PriorYearsOfExperience, family = binomial, data = trainset)
summary(trainm6)
probtestm6 <- predict(trainm6, type = 'response', newdata = testset)
pass.hat.testm6 <- ifelse(probtestm6>threshold2, 'Voluntary Resignation', 'Current employee')
table(testset$Attrition, pass.hat.testm6)
mean(pass.hat.testm6==testset$Attrition)

probtrainm6 <- predict(trainm6, type = 'response')
pass.hat.trainm6<- ifelse(probtrainm6>threshold2, 'Voluntary Resignation', 'Current employee')
table(trainset$Attrition, pass.hat.trainm6)
mean(pass.hat.trainm6==trainset$Attrition)

## Final model model 5
OR <- exp(coef(model5))
OR
OR.CI <- exp(confint(model5))
OR.CI

# CART==========================================
# CART model for 'allocating' candidates to job openings in departments based on their skillset, experience and traits
# Match shortlisted candidates with relevant job openings
# Base the cart model on current employees
ibm3<-ibm[ibm$Attrition=='Current employee']
dim(ibm3)
# Run the CART model to profile current employees to Departments
cart3.ibm3 <- rpart(Department ~ Age + Department +DistanceFromHome + Education +EducationField + `Employee Source`+ Gender + JobRole + MaritalStatus +AverageTenure + TotalWorkingYears, data = ibm3, method = "class", control = rpart.control(minsplit = 500, cp = 0))
rpart.plot(cart3.ibm3)
plotcp(cart3.ibm3)
cart3.opt.ibm3 <- prune(cart3.ibm3, cp = 0.0022)
rpart.plot(cart3.opt.ibm3)
cart3.opt.ibm3$variable.importance

# Run logistic regression for current employees - here making use of data available post hiring process. (Hired already)
ibm.m1 <- glm(Attrition ~ MonthlyIncome+ PercentSalaryHike + TrainingTimesLastYear + BusinessTravel + OverTime + StockOptionLevel + EnvironmentSatisfaction + JobSatisfaction + JobInvolvement + RelationshipSatisfaction + WorkLifeBalance, family = binomial, data = ibm1)
summary(ibm.m1)
vif(ibm.m1)
ORm1 <- exp(coef(ibm.m1))
ORm1
ORCIm1 <- exp(confint(ibm.m1))
ORCIm1

# Here, we are interested to figuring what are the significant variables in keeping the employees. No prediction would be done hence, we are not conducting a train-test split.
# improve on model1 by removing MonthlyIncome because ORCI1 shows a 95% chance it would be 1 - no effect.
ibm.m2 <- glm(Attrition ~ PercentSalaryHike + TrainingTimesLastYear + BusinessTravel + OverTime + StockOptionLevel + EnvironmentSatisfaction + JobSatisfaction + JobInvolvement + RelationshipSatisfaction + WorkLifeBalance, family = binomial, data = ibm1)
summary(ibm.m2)
vif(ibm.m2)
ORm2 <- exp(coef(ibm.m2))
ORm2
ORCIm2 <- exp(confint(ibm.m2))
ORCIm2
# Based on our multi-variate analysis and hypothesis formed, create a model 2
ibm.m3 <- glm(Attrition ~ PercentSalaryHike + BusinessTravel + OverTime + EnvironmentSatisfaction + JobInvolvement + RelationshipSatisfaction + WorkLifeBalance, family = binomial, data=ibm1)
summary(ibm.m3)
vif(ibm.m3)
ORm3 <- exp(coef(ibm.m3))
ORm3
ORCIm3 <- exp(confint(ibm.m3))
ORCIm3
# it appears ibm.m3 is overall a better model. -- conclude that to keep their employees, the company can focus on these variables
