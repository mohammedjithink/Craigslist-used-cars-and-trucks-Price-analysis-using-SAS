

dm 'clear log'; dm 'clear output';  

libname session1 "E:\Users\syt200000\Documents\My SAS Files\9.4\SAS_Project";
title;

*import data;
proc import out=work.project
datafile = "E:\Users\syt200000\Documents\My SAS Files\9.4\SAS_Project\usedcars.csv"
dbms= csv replace;
guessingrows=3000;
getnames=yes;
datarow=2;
run;



*drop unnecessary variables from the dataset;
Proc sql; 
Alter table WORK.PROJECT 
DROP url,region_url,VIN,paint_color,image_url,description,county,lat,long,posting_date; 
quit; 

*remove the rows where price=0;
Proc sql; 
delete from  WORK.PROJECT 
where price = 0 ; 
quit; 

*remove the rows that all major variables with no value;
Proc sql; 
delete from  WORK.PROJECT 
where year= . AND odometer =. and manufacturer=" "  and model=" " and condition=" " and cylinders=" " and fuel=" " and transmission= " "; 
quit; 

*find the missing values for numeric data;
proc means data = WORK.PROJECT n nmiss; 
var _numeric_; 
run; 

*the trend of missing numeric data;
ods select MissPattern;
proc mi data=WORK.PROJECT nimpute=0;
var odometer price year ;
run;


*impute the time with median of time variable;
proc stdize data=WORK.PROJECT out=project_new method=median reponly;
   var year ;
run;

*check again if the number of missing values of time is zero now after imputing;
proc means data = project_new n nmiss;
  var _numeric_;
run;

*sort the year variable;
proc sort data=project_new;
   by year;
run;

*impute the values of odometer with mean of odometer grouped by year;
proc stdize data=project_new out=project_new1 method=mean reponly;
   var odometer ;
by year;
run;

*check if all the numeric values are imputed;
proc means data = project_new1 n nmiss ;
  var _numeric_;
run;

*drop id column;
proc sql;
alter table project_new1 drop id;
quit;

*remove price outlier and logprice;
proc univariate data=project_new1 noprint; 
var price year; 
output out=percentiles3 pctlpts=95 to 100 by 1 pctlpre=price_ year_  
pctlname=P95 P96 P97 P98 P99 P100; 
run; 

 data project_new1; 
set project_new1(where=(price between 3000 and 70000)); 
logprice = log(price); 
run; 


***impute categorical variables;

*drop model variable;
PROC SQL; 
ALTER TABLE project_new1 DROP model; 
QUIT; 

*impute manufacturer variable;
Data project_new1; 
set project_new1; 
if (manufacturer=" ") then manufacturer = "missing"; 
run;

*impute condition variable;
proc sql; 
select  condition, 
count(*) as count 
from project_new1 
group by condition; 
run; 

Data project_new1; 
set project_new1; 
if (condition=" ") then condition="good"; 
run; 
 
*impute cylinders variable;
proc sql; 
select  cylinders, 
count(*) as count 
from project_new1 
group by cylinders; 
run; 

Data project_new1; 
set project_new1; 
if (cylinders =" ") then cylinders="6 cylinders"; 
run; 

*impute title_status variable;
proc sql; 
select  title_status,
count(*) as count 
from project_new1 
group by title_status; 
run; 

Data project_new1; 
set project_new1; 
if (title_status =" ") then title_status="clean"; 
run; 

*impute transimssion variable;
proc sql;
   select  transmission,
   count(*) as count
   from project_new1
   group by transmission;
   run;

Data project_new1;
set project_new1;
if (transmission =" ") then transmission= "automatic" ;
run;

*impute drive variable;
proc sql;
   select  drive,
   count(*) as count
   from project_new1
   group by drive;
   run;

Data project_new1;
set project_new1;
if (drive=" ") then drive= "4wd" ;
run;

*impute size variable;
proc sql;
   select  size,
   count(*) as count
   from project_new
   group by size;
   run;

Data project_new;
set project_new;
if (size=" ") then size= "  full-size" ;
run;

*impute type variable;
proc sql;
   select  type,
   count(*) as count
   from project_new1
   group by type;
   run;

Data project_new1;
set project_new1;
if (type=" ") then type= "SUV" ;
run;


*univariate log price;
proc univariate data=project_new1 normal noprint;
	var price logprice ;
	histogram price logprice  / normal kernel; 
	inset n mean std / position = ne;
	probplot price logprice;
	title "Distribution Analysis -price & logprice";
	run;
*boxplot of logprice;
proc sgplot data=project_new1;
    vbox logprice /
        fillattrs=(color=PAOY transparency=0.5);
run;


*univariate and boxplot year;
data project_new1; 
set project_new1(where=(year between 2003 and 2021)); 
run; 

 proc univariate data=project_new1 normal noprint;
	var year ;
	histogram year  / normal kernel; 
	inset n mean std / position = ne;
	probplot year;
	title "Distribution Analysis -year";
	run;

	proc sgplot data=project_new1;
    vbox year /
        fillattrs=(color=PAOY transparency=0.5);
run;

*univariate odometer;
data project_new1; 
set project_new1; 
logodometer = log(odometer); 
run; 

proc univariate data=project_new1 normal noprint;
	var logodometer;
	histogram logodometer / normal kernel; 
	inset n mean std / position = ne;
	probplot logodometer;
	title "Distribution Analysis -logodometer";
	run;

*linear regressions price by odometer;
ods graphics on;

proc reg data=project_new1 ;
   wyear: model logprice= logodometer year / vif;
   title 'Collinearity Diagnostics';
	run;
	quit;

proc reg data=project_new1  PLOTS(MAXPOINTS=none);
continuous: model logprice= logodometer year;
title "logprice-logodometer & year Model - Generate Diagnostic Plots";
run;



***ANOVA;
*logprice by title_status;
proc glm data=project_new1 PLOTS(MAXPOINTS=none ) ;
	class title_status;
	model logprice = title_status /ss3;
	title "ANOVA by title_status";
	run;
	quit;

*logprice by condition;
proc glm data=project_new1 PLOTS(MAXPOINTS=none ) ;
	class condition;
	model logprice = condition /ss3;
	title "ANOVA by condition";
	run;
	quit;



