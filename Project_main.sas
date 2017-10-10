/* Connecting to first excel file.*/
PROC IMPORT OUT=FAA1 
DATAFILE="/folders/myfolders/GASUE34_data/FAA1.xls"
       DBMS=xls REPLACE;
     	GETNAMES=YES;
RUN;
proc print data=FAA1(obs=4);
Title FAA1_Data;
run;
/* Connecting to second excel file.*/
PROC IMPORT OUT=FAA2
DATAFILE="/folders/myfolders/GASUE34_data/FAA2.xls"
       DBMS=xls REPLACE;
     	GETNAMES=YES;
RUN;
proc print data = FAA2(obs=4);
Title FAA2_Data;
run;

/*
Sorted first data set
 */
PROC SORT data=FAA1 out=stfaa1 ;
BY aircraft;
proc print data=stfaa1;
run;


/*
Sorted second data set
 */
PROC SORT data=FAA2 out=stfaa2;
BY aircraft;
proc print data=stfaa2;
run;
/*
 Since second data contains 50 empty, so we remove them.
 */

data stfaa2;
   set stfaa2;
   if (_n_ > 50); 
run;

/* Step1. Combining the two datasets. */

PROC SORT data=stfaa1;
BY aircraft; /*sorts the first data set. */
PROC SORT data=stfaa2;
BY aircraft; /*sorts the second data set. */
DATA combined_data;
SET stfaa1 stfaa2;
BY aircraft;
run;

/*
Looking at summary of data
 */
proc means data=combined_data;
run;


/*
Removing duplicate values if any present
 */
PROC SORT data=combined_data NODUPKEY;
BY speed_ground speed_air height pitch distance;
RUN;
proc means data=combined_data;
title summary statistics before data cleaning
run;

/* Checking the number of missing values for every column. */

proc means data=combined_data n nmiss;
title Missing rows;
run;
/* The duration column contains 150 missing values
and speed_air contains 700 missing rows. We would look at the histogram
of both variables */

proc chart data=combined_data;
vbar speed_air duration;
run;
/*
The histogram of spped_air is right skewed while
that of duration is almost normal. Still I would
keep all the rows containing the missing values.
 */

/* checking abnormal values in the data by checking for
following rules.

1. Distance < 6000
2. Height > 6 meters
3. Speed_ground between 30mph and 140mph
4. Duration > 40 mins 

I create a variable abnormal to indicate 
if any flight was abnormal or not based on above conditions.*/

data validatephase1;
	set combined_data;
	if duration < 40 then abnormal = "yes";
	else if height < 6 then abnormal ="yes";
	else if speed_ground < 30 or speed_ground > 140 then abnormal="yes";
	else if distance > 6000 then abnormal ="yes";
	else abnormal ="no";
run;

/* checking the number of abnormal rows. */

PROC FREQ DATA=validatephase1;
TABLE abnormal;
Title Abnormal values before removal of abnormal entries;
RUN;

/* Since abnormal data can be useful for research so we
put the rows containing abnormal data separately.
*/

data abnormal_data;
	set validatephase1;
	if abnormal = "yes";
run;
PROC FREQ DATA=abnormal_data;
TABLE abnormal;
Title abnormal data;
RUN;

data complete_data;
	set validatephase1;
	if abnormal = "no";
run;
PROC FREQ DATA=complete_data;
TABLE abnormal;
Title Final prepared data;
RUN;

/* Removing temporary column abnormal. */
data final_data;
	set complete_data;
	Drop abnormal;
run;	
proc means data=final_data;
title summary after data cleaning;
run;
/* Summarizing the data for different airlines.
1. Using proc univariate and plotting.*/


PROC SORT data=final_data;
BY aircraft;
proc univariate data=final_data normal plot;
	by aircraft;
	histogram ;
run;
/*
2. Using proc means.
 */
proc means data= final_data n nmiss max min mean
				median mode q1 q3 std var;
	by aircraft;
run;

/*we check summary statistics of data*/
proc means data=final_data n nmiss mean median std var q1 q3 min max range;
title Summary Statistics;
/* we check for number of observations for each aircraft */
proc freq data=final_data;
table aircraft;
title number of observations in each aircraft;
/* checking the summary statistics for each aircraft separately */
proc means data= final_data n nmiss max min mean std var range;
	by aircraft;
title summary for each aircraft;
/* We now use t-test and ANOVA as data is balanced across aircraft carriers
is to check if the mean value of duration varies across aircrafts */
proc ttest data=final_data;
	class aircraft;
	var distance;
title t-test for aircraft and distance;
proc anova data=final_data;
	class aircraft;
	model distance = aircraft;
	means aircraft;
title ANOVA test for aircraft and distance;
/* we observe that the results of t-test and ANOVA indicate that
both means and variances in landing distance are different for two aircrafts 
so aircraft has direct effect on distance.
We now check for correlation of distance with other numeric variables 
and also among other variables as well*/
proc plot data = final_data;
 plot distance*no_pasg;
 plot distance*speed_ground;
 plot distance*speed_air;
 plot distance*height;
 plot distance*pitch;
 plot duration*distance;
 plot height*distance;
 plot speed_ground*speed_air;
/* from the X-Y plots we can see that duration has no clear
relation with other variables. Most of the graphs have spread data
indicating no clear relationship. 
But linear relationship exists between speed_ground and speed_air.
we check for correlation between variables now*/
proc corr data= final_data;
	var duration no_pasg speed_ground speed_air height
	pitch distance;
title correlation among variables;
/* It can be concluded that speed_air, speed_ground and distance have
very high correlation among one another.*/

/* We create a dummy variable for aircraft variable having
value 0 for boeing and 1 for airbus */
data final_data;
	set final_data;
	if aircraft = "airbus" then aircraft_value =1;
	else aircraft_value =0;
run;

/* We start with regression. For Regression I will create two separate data sets
also one for each aircraft.I will create models for each of these 3 data sets.
We would preferably use those variables which have high correlation with distance.*/
data boeingdata;
	set final_data;
	if aircraft = "boeing";
run;
data airbusdata;
	set final_data;
	if aircraft = "airbus";
run;


/* Model 1: Start with linear Regression using speed_ground as 
predictor for whole data*/
proc reg data=final_data;
 model distance= speed_ground;
run; /* Return R-squared value of .7529 and adj-rsqr .7526

/* Model 2:linear Regression for whole data using speed_air*/
proc reg data=final_data;
 model distance= speed_air;
run;/* Return R-squared value of .8897 and adj-rsqr .8891


/* Model 3:linear Regression for whole data using aircraft_value*/
proc reg data=final_data;
 model distance= aircraft_value;
run;/* Return R-squared value of .0127 and adj-rsqr .0122


/* Model 4:linear Regression for whole data using height*/
proc reg data=final_data;
 model distance= height;
run;/* Return R-squared value of .0527 and adj-rsqr .0517


/* Model 5:Start with multivariate linear Regression using speed_ground and speed_air
for whole data*/
proc reg data=final_data;
 model distance= speed_ground speed_air;
run;/* Return R-squared value of .8902 and adj-rsqr .8802

/* Model 6:Start with multivariate linear Regression using speed_air and height
for whole data*/
proc reg data=final_data;
 model distance= height speed_air;
run;/* Return R-squared value of .9093 and adj-rsqr .9083


/* Model 7:Start with multivariate linear Regression using speed_ground and height
for whole data*/
proc reg data=final_data;
 model distance= height speed_ground;
run;/* Return R-squared value of .7707 and adj-rsqr .7704

/* Model 8:Multivariate linear Regression using aircraft_value, height
amd speed_air for whole data*/
proc reg data=final_data;
 model distance= height aircraft_value speed_air;
run;/* Return R-squared value of .9502 and adj-rsqr .9496



/* Model 9:Multivariate linear Regression using speed_ground, aircraft
and speed_air for whole data*/
proc reg data=final_data;
 model distance= speed_ground height speed_air aircraft_value;
run;/* Return R-squared value of .9505 and adj-rsqr .9497


/* Model 10:Multivariate linear Regression using all variables for whole data*/
proc reg data=final_data;
 model distance= speed_ground speed_air aircraft_value duration height pitch;
run;/* Return R-squared value of .9744 and adj-rsqr .9736



/* Model 11:Start with linear Regression using speed_ground as 
predictor for boeingdata data*/
proc reg data=boeingdata;
 model distance= speed_ground;
run; /* Return R-squared value of .8109 and adj-rsqr .8104

/* Model 12:linear Regression for boeingdata data using speed_air*/
proc reg data=boeingdata;
 model distance= speed_air;
run;/* Return R-squared value of.9557 and adj-rsqr as .9553


/* Model 13:linear Regression for boeingdata data using speed_air*/
proc reg data=boeingdata;
 model distance= height;
run;/* Return R-squared value of.9557 and adj-rsqr as .9553

/* Model 13:Start with multivariate linear Regression using speed_ground and speed_air
for boeingdata data*/
proc reg data=boeingdata;
 model distance= speed_ground speed_air;
run;/* Return R-squared value of .9557 and adj-rsqr .9549


/* Model 14:Start with multivariate linear Regression using speed_ground and height
for boeingdata data*/
proc reg data=boeingdata;
 model distance= speed_ground height;
run;/* Return R-squared value of .8317 and adj-rsqr .8308




/* Model 15:Start with linear Regression using speed_ground as 
predictor for airbusdata data*/
proc reg data=airbusdata;
 model distance= speed_ground;
run; /* Return R-squared value of .8258 and adj r-sqr as .8254

/* Model 16:linear Regression for airbusdata data using speed_air*/
proc reg data=airbusdata;
 model distance= speed_air;
run;/* Return R-squared value of .9317 and adj r-sqr as .9309


/* Model 17:linear Regression for airbusdata data using height*/
proc reg data=airbusdata;
 model distance= height;
run;/* Return R-squared value of .0311 and adj r-sqr as .0302


/* Model 18:Start with multivariate linear Regression using speed_ground and speed_air
for airbusdata data*/
proc reg data=airbusdata;
 model distance= speed_ground speed_air;
run;/* Return R-squared value of .9341 and adj-rsqr as .9323

