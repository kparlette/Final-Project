/* "Modeling and prediction for movies" */
/* MTH752 Final Project - K Parlette R Geller
/* ## Part 1: Data */
/* Load data */
/* Import of the two files - movies and revenue*/
FILENAME REFFILE '/home/u58259531/EPG1V2/MTH752/Final Project/movies.csv';

PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=WORK.FINALPROJECT replace;
	GETNAMES=YES;
	guessingrows=700;
RUN;

data work.finalproject;
	set work.finalproject;
	title_year=cats(title, thtr_rel_year);
run;

PROC CONTENTS DATA=WORK.FINALPROJECT;
run;

data work.finalproject;
	set work.finalproject;
	drop var1 imdb_url rt_url dvd_rel_year dvd_rel_month dvd_rel_day;
run;

proc sort data=work.finalproject out=FinalProject_ND noduprecs 
		dupout=FINALPROJECT_Dup;
	by _all_;
RUN;

FILENAME REFFILE2 
	'/home/u58259531/EPG1V2/MTH752/Final Project/box office upload.xlsx';

PROC IMPORT DATAFILE=REFFILE2 DBMS=XLSX OUT=WORK.MOVIE_REVENUE replace;
	GETNAMES=YES;
RUN;

data work.movie_revenue;
	set work.movie_revenue;
	movie_year=cats(movie, year);
run;

PROC CONTENTS DATA=WORK.MOVIE_REVENUE;
RUN;

/* Insert code */
/* Joining of tables and filtering*/
PROC SQL;
	Create table MOVIE_JOIN as Select * from WORK.FINALPROJECT_ND as x left join 
		WORK.MOVIE_REVENUE as y On x.title_year=y.movie_year;
Quit;

data work.MOVIE_JOIN;
	set work.MOVIE_JOIN;
	drop title_year movie_year movie year worldwide_box_office intl_box_office 
		actor4 actor5;

	IF domestic_box_office=0 THEN
		DELETE;
	*if domestic_box_office >100000000 then DELETE;
	Format domestic_box_office dollar25. 
		imdb_num_votes comma12.0 imdb_rating comma12.1;
	thtr_rel_month2=input(thtr_rel_month*100, 12.2);
	thtr_rel_day2=input(thtr_rel_day*100, 12.2);
	thtr_rel_year2=input(thtr_rel_year*100, 12.2);
	runtime2=input(runtime, 12.0);
run;

DATA work.movie_join;
	SET work.movie_join;
	length DBO_range $ 15;

	IF domestic_box_office > 250000000 THEN
		DBO_Range="a $250m+";
	ELSE IF domestic_box_office > 200000000 and domestic_box_office le 250000000 
		THEN
			DBO_Range="b $200-$250m";
	else if domestic_box_office > 150000000 and domestic_box_office le 200000000 
		THEN
			DBO_Range="c $150-$200m";
	else if domestic_box_office > 100000000 and domestic_box_office le 150000000 
		THEN
			DBO_Range="d $100-$150m";
	else if domestic_box_office > 7500000 and domestic_box_office le 100000000 THEN
		DBO_Range="e $75-$100m";
	else if domestic_box_office > 5000000 and domestic_box_office le 75000000 THEN
		DBO_Range="f $50-$75m";
	ELSE
		DBO_Range="g <50";
RUN;

/* ## Part 2: Research question */
/* ## Part 3: Exploratory data analysis */
/* Descriptive Statistics*/

ods graphics on;
ods rtf file="/home/u58259531/EPG1V2/output/FinalProject1-3.rtf" style=journal startpage=no;

PROC MEANS DATA=work.movie_join n mean median stddev stderr max min;
	VAR thtr_rel_year thtr_rel_month imdb_rating critics_score audience_score 
		domestic_box_office imdb_num_votes;
	title "Descriptive Statistics";
RUN;

/*Statistical Analysis*/
ods graphics on;
ods noproctitle;

/*Critics Score*/
proc reg data=work.movie_join alpha=.05;
	model domestic_box_office=critics_score / clb;
	title "Regression Analysis - Revenue versus Critics Score";
	title2 "K Parlette";
	run;

	/*Audience Score*/
proc reg data=work.movie_join alpha=.05;
	model domestic_box_office=audience_score / clb;
	title "Regression Analysis - Revenue versus Audience Score";
	title2 "K Parlette";
	run;

	/*IMDB Votes*/
proc reg data=work.movie_join alpha=.05;
	model domestic_box_office=imdb_num_votes / clb;
	title "Regression Analysis - Revenue versus IMDB Votes";
	title2 "K Parlette";
	run;

	/*IMDB Rating*/
proc reg data=work.movie_join alpha=.05;
	model domestic_box_office=imdb_rating / clb;
	title "Regression Analysis - Revenue versus IMDB Rating";
	title2 "K Parlette";
	run;

	/*Release Month*/
proc reg data=work.movie_join alpha=.05;
	model domestic_box_office=thtr_rel_month2 / clb;
	title "Regression Analysis - Revenue versus Release Month";
	title2 "K Parlette";
	run;

	/*Runtime*/
Proc reg data=work.movie_join alpha=.05;
	model domestic_box_office=runtime2 / clb;
	title "Regression Analysis - Revenue versus Runtime";
	title2 "K Parlette";
	run;

	/*Distribution of Revenue by Category*/
proc freq data=work.MOVIE_JOIN;
	tables dbo_range / totpct;
	title "Domestic Box Office - Revenue Categories";
run;

proc univariate data=work.movie_join;
	var domestic_box_office;
	title "Domestic Box Office Revenue Statistics";
run;

ods graphics on;

proc freq data=work.movie_join;
	tables thtr_rel_month / plots=(freqplot(scale=percent));
	title "Distribution of Theater Release Month";
run;

proc means data=work.movie_join n mean std median;
	class best_pic_nom;
	var domestic_box_office;
run;

proc sgplot data=work.movie_join;
	hbox domestic_box_office / category=best_pic_nom;
	label domestic_box_office='Domestic Box Office Revenue' 
		best_pic_nom='Best_Pic_Nom';
	title "Horizontal Plot for Revenue versus Best Picture Nominees";
run;

proc sgplot data=work.movie_join;
	hbox domestic_box_office / category=mpaa_rating;
	label domestic_box_office='Domestic Box Office Revenue' 
		mpaa_Rating='MPAA Rating';
	title "Horizontal Plot for Revenue versus MPAA Rating";
run;

proc sgplot data=work.movie_join;
	hbox domestic_box_office / category=genre;
	label domestic_box_office='Domestic Box Office Revenue' genre='Movie Genre';
	title "Horizontal Plot for Revenue versus Movie Genre";
run;



/* ## Part 4: Modeling */

/*Creating Binary Variables*/
data work.movie_join2;
	set work.movie_join;
	if best_pic_nom eq 'yes' then best_pic_nom2=1;
	if best_pic_nom eq 'no' then best_pic_nom2=0;
	if best_pic_win eq 'yes' then best_pic_win2=1;
	if best_pic_win eq 'no' then best_pic_win2=0;
	if best_actor_win eq 'yes' then best_actor_win2=1;
	if best_actor_win eq 'no' then best_actor_win2=0;
	if best_dir_win eq 'yes' then best_dir_win2=1;
	if best_dir_win eq 'no' then best_dir_win2=0;
	if best_actress_win eq 'yes' then best_actress_win2=1;
	if best_actress_win eq 'no' then best_actress_win2=0;
	if top200_box eq 'yes' then top200_box2=1;
	if top200_box eq 'no' then top200_box2=0;
	if critics_rating eq 'Certified Fresh' then critics_rating2=2;
	if critics_rating eq 'Fresh' then critics_rating2=1;
	if critics_rating eq 'Rotten' then critics_rating2=0;
	if audience_rating eq 'Upright' then audience_rating2=1;
	if audience_rating eq 'Spilled' then audience_rating2=0;
	if mpaa_rating eq 'Unrated' then mpaa_ratings2=5;
	if mpaa_rating eq 'NC-17' then mpaa_ratings2=4;
	if mpaa_rating eq 'R' then mpaa_ratings2=3;
	if mpaa_rating eq 'PG-13' then mpaa_ratings2=2;	
	if mpaa_rating eq 'PG' then mpaa_ratings2=1;
	if mpaa_rating eq 'G' then mpaa_ratings2=0;
	if genre eq 'Drama' then genre2=0;
	if genre eq 'Comedy' then genre2=1;
	if genre eq 'Horror' then genre2=2;
	if genre eq 'Action & Adventure' then genre2=3;
	if genre eq 'Animation' then genre2=4;
	if genre eq 'Art House & International' then genre2=5;
	if genre eq 'Documentary' then genre2=6;
	if genre eq 'Mystery & Suspense' then genre2=7;
	if genre eq 'Musical & Performing Arts' then genre2=8;
	if genre eq 'Science Fiction & Fantasy' then genre2=9;
	if genre eq 'Other' then genre2=10;
	if runtime eq 'NA' then delete;
	drop best_pic_nom best_pic_win best_dir_win best_actress_win 
		best_actor_win top200_box critics_rating audience_rating title_type 
		runtime thtr_rel_year thtr_rel_month thtr_rel_day mpaa_rating genre;
run;

/*#1 All continous variables no selection*/
proc reg data=WORK.MOVIE_JOIN2 alpha=0.05 plots(only)=(diagnostics residuals 
		observedbypredicted);
	model Domestic_Box_Office=imdb_rating imdb_num_votes critics_score 
		audience_score thtr_rel_month2 thtr_rel_day2 thtr_rel_year2 runtime2 
		best_pic_nom2 best_pic_win2 best_actor_win2 best_dir_win2 best_actress_win2 
		top200_box2 critics_rating2 audience_rating2 mpaa_ratings2 / vif;
title 'All continuous variables';
run;

/*#2 Model - All continuous variables with AIC and Stepwise added*/

proc glmselect data=WORK.MOVIE_JOIN2 outdesign(addinputvars)=Work.model2 
		plots=(criterionpanel);
	model Domestic_Box_Office=thtr_rel_month2 runtime2 best_pic_nom2 best_pic_win2 
		best_actor_win2 best_dir_win2 mpaa_ratings2 critics_rating2 imdb_num_votes 
		critics_score audience_score audience_rating2 top200_box2 best_actress_win2 
		thtr_rel_year2 imdb_rating thtr_rel_day2 / showpvalues 
		selection=stepwise
    
   (select=aic);
title '#2 Model - All continuous variables with AIC and Stepwise added';
run;

proc reg data=Work.model2 alpha=0.05 plots(only)=(diagnostics residuals 
		observedbypredicted);
	ods select ParameterEstimates DiagnosticsPanel ResidualPlot 
		ObservedByPredicted;
	model Domestic_Box_Office=&_GLSMOD / vif;
run;

/*#3 Model - Statistically insignificant variables and multicollinearity issues removed */

proc glmselect data=WORK.MOVIE_JOIN2 outdesign(addinputvars)=Work.model3 
		plots=(criterionpanel);
	model Domestic_Box_Office=thtr_rel_month2 runtime2 best_pic_nom2 best_pic_win2 
		best_actor_win2 best_dir_win2 mpaa_ratings2 critics_rating2 imdb_num_votes 
		critics_score top200_box2 audience_score / showpvalues 
		selection=stepwise
    
   (select=aic);
title 'Model 3 - Statistically insignificant variables and multicollinearity issues removed';
run;

proc reg data=Work.model3 alpha=0.05 plots(only)=(diagnostics residuals 
		observedbypredicted);
	ods select ParameterEstimates DiagnosticsPanel ResidualPlot 
		ObservedByPredicted;
	model Domestic_Box_Office=&_GLSMOD / vif;
	run;
	
/*Model 4 - Added cross varaibles for those with Multicollinearity*/
proc glmselect data=WORK.MOVIE_JOIN2 outdesign(addinputvars)=Work.model4 
		plots=(criterionpanel);
	model Domestic_Box_Office=audience_score thtr_rel_month2 thtr_rel_year2 
		runtime2 best_pic_nom2 best_pic_win2 best_actor_win2 best_dir_win2 
		top200_box2 audience_rating2 mpaa_ratings2 genre2 imdb_rating*imdb_num_votes 
		critics_score*critics_rating2 audience_score*audience_rating2 / showpvalues 
		selection=stepwise
    
   (select=aic);
title 'Model 4 - Added cross variables for those with Multicollinearity';
run;

proc reg data=Work.model4 alpha=0.05 plots(only)=(diagnostics residuals 
		observedbypredicted);
	ods select ParameterEstimates DiagnosticsPanel ResidualPlot 
		ObservedByPredicted;
	model Domestic_Box_Office=&_GLSMOD / vif;
	run;

/*Model 5 - Backwards Selection Process*/
proc glmselect data=WORK.MOVIE_JOIN2 outdesign(addinputvars)=Work.reg_design 
		plots=(criterionpanel);
	model Domestic_Box_Office=audience_score thtr_rel_month2 runtime2 
		best_pic_nom2 best_pic_win2 best_actor_win2 best_dir_win2 top200_box2 
		audience_rating2 mpaa_ratings2 genre2 imdb_num_votes critics_score 
		imdb_rating thtr_rel_day2 thtr_rel_year2 best_actress_win2 critics_rating2 / 
		showpvalues selection=backward
    
   (select=aic);
title 'Model 5 - Backwards Selection Process'
run;

proc reg data=Work.reg_design alpha=0.05 plots(only)=(diagnostics residuals 
		observedbypredicted);
	ods select ParameterEstimates DiagnosticsPanel ResidualPlot 
		ObservedByPredicted;
	model Domestic_Box_Office=&_GLSMOD / vif;
	run;
	
/*Model 6 - forward selection*/
proc glmselect data=WORK.MOVIE_JOIN2 outdesign(addinputvars)=Work.reg_design 
		plots=(criterionpanel);
	model Domestic_Box_Office=audience_score thtr_rel_month2 runtime2 
		best_pic_nom2 best_pic_win2 best_actor_win2 best_dir_win2 top200_box2 
		audience_rating2 mpaa_ratings2 imdb_num_votes critics_score imdb_rating 
		thtr_rel_day2 thtr_rel_year2 best_actress_win2 critics_rating2 genre2 / 
		showpvalues selection=forward 
    
   (select=aic);
title 'Model 6 - Forward Selection Process'
run;

proc reg data=Work.reg_design alpha=0.05 plots(only)=(diagnostics residuals 
		observedbypredicted);
	ods select ParameterEstimates DiagnosticsPanel ResidualPlot 
		ObservedByPredicted;
	model Domestic_Box_Office=&_GLSMOD / vif;
	run;	
	
/* ## Part 5: Prediction */
/* Insert code */
/* ## Part 6: Conclusion */

ods graphics off;
ods rtf close;