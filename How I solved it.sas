/*****************How I solved it?***************************/
/*******************************************************************/

*******************Identify the overlap of dates in exposure intervals *********;

data ex;
infile datalines dlm='|' dsd missover;
input USUBJID : $10. EXSTDTC : $10. EXENDTC : $10. EXSEQ : best32.;
label ;
format ;
datalines4;
SG-1001|2023-01-01|2023-01-10|1
SG-1001|2023-01-11|2023-01-13|2
SG-1001|2023-01-15|2023-01-18|3
SG-1001|2023-01-16|2023-01-23|4
SG-1001|2023-01-24|2023-01-25|5
SG-1001|2023-01-25|2023-01-28|6
SG-1002|2023-02-01|2023-02-10|1
SG-1002|2023-02-11|2023-02-13|2
SG-1002|2023-03-05|2023-03-30|3
;;;;
run;

*==============================================================================;
*Expand the records from start date to end date on each record;
*==============================================================================;
 
data ex01;
   set ex;
   startdt=input(exstdtc,??yymmdd10.);
   enddt=input(exendtc,??yymmdd10.);
 
   do date=startdt to enddt;
      output;
   end;
 
   format startdt enddt date date9.;
run;
 
*==============================================================================;
*Check if there exists more than one exseq on a single date value;
*==============================================================================;
 
proc sort data=ex01 out=dates01(keep=usubjid exseq date) nodupkey;
   by usubjid date exseq;
run;
 
data dates02;
   set dates01;
   by usubjid date;
   if not (first.date and last.date) then output;
run;
 
*==============================================================================;
*Subset the source records with issue;
*==============================================================================;
 
proc sort data=dates02 out=dates03(keep=usubjid exseq) nodupkey;
   by usubjid exseq;
run;
 
data issue_records;
   merge ex(in=a) dates03(in=b);
   by usubjid exseq;
   if a and b;
run;

***************************************Get the latest transfusion date on or before each lab collection date****************************
*****************************************************************************************************************************************;

data adlb;
infile datalines dlm='|' dsd missover;
input USUBJID : best32. PARAMCD : $8. ADT : DATE9. AVAL : best32. SEQ : best32.;
label ;
format ADT DATE9.;
datalines4;
1001|HGB|01FEB2010|12.3|1
1001|HGB|02FEB2010|12.2|2
1001|HGB|10FEB2010|12.3|3
1002|HGB|01JAN2010|13|4
1003|HGB|15MAY2010|10|5
;;;;
run;

data adtrans;
infile datalines dlm='|' dsd missover;
input USUBJID : best32. TRANSDT : DATE9.;
label ;
format TRANSDT DATE9.;;
datalines4;
1001|15JAN2010
1001|02FEB2010
1001|15FEB2010
1003|05MAR2009
;;;;
run;

*==============================================================================;
*Get all the transfusion dates before each lab date;
*==============================================================================;
 
proc sql;
   create table adlb02 as
      select a.*,b.transdt
      from adlb as a
      left join
      adtrans as b
      on a.usubjid=b.usubjid and  (. lt transdt le adt)
      order by a.usubjid,paramcd,adt,seq,transdt;
quit;
 
*==============================================================================;
*Identify the latest date of all available transfusion dates;
*==============================================================================;
 
data adlb03;
   set adlb02;
   by usubjid paramcd adt seq transdt;
   if last.seq;
run;

***************************************Last dosing date before an adverse event start date*******************************************;
***************************************************************************************************************************;

data adae;
infile datalines dlm='|' dsd missover;
input USUBJID : $20. ASTDT : DATE9. AETERM : $20. AESEQ : best32.;
label ;
format ASTDT DATE9.;
datalines4;
SG-1001|01JAN2023|event0|1
SG-1001|15JAN2023|event1|2
SG-1001|02FEB2023|event2|3
SG-1001|15FEB2023|event3|4
SG-1003|05MAR2023|event1|1
;;;;
run;

data ex;
infile datalines dlm='|' dsd missover;
input USUBJID : $10. EXSTDTC : $10. EXENDTC : $10. EXSEQ : best32.;
label ;
format ;
datalines4;
SG-1001|2023-01-01|2023-01-10|1
SG-1001|2023-01-11|2023-01-13|2
SG-1001|2023-01-15|2023-01-18|3
SG-1001|2023-01-16|2023-01-23|4
SG-1001|2023-01-24|2023-01-25|5
SG-1001|2023-01-25|2023-01-28|6
SG-1001|2023-02-01|2023-02-10|1
SG-1001|2023-02-11|2023-02-13|2
SG-1003|2023-03-05|2023-03-30|3
;;;;
run;

*==============================================================================;
*Expand the records from start date to end date on each record;
*==============================================================================;
 
data ex01;
   set ex;
   startdt=input(exstdtc,??yymmdd10.);
   enddt=input(exendtc,??yymmdd10.);
 
   do date=startdt to enddt;
      output;
   end;
 
   format startdt enddt date date9.;
run;
 
*==============================================================================;
*Get all the transfusion dates before each lab date;
*==============================================================================;
 
proc sql;
   create table adae02 as
      select a.*,b.date
      from adae as a
      left join
      ex01 as b
      on a.usubjid=b.usubjid and  (. lt date lt astdt)
      order by a.usubjid,aeseq,date;
quit;
 
*==============================================================================;
*Identify the latest date of all available transfusion dates;
*==============================================================================;
 
data adae03;
   set adae02;
   by usubjid aeseq date;
   if last.aeseq;
run;

/********************************************Check if an element start date is same as previous element end date in SE******************************************/
/***************************************************************************************************************************************************************/

/*=========================================================
Include the data file
=========================================================*/
data se;
infile datalines dlm='|' dsd missover;
input USUBJID : $20. TAETORD : best32. ETCD : $3. SESTDTC : $10. SEENDTC : $10.;
label ;
format ;
datalines4;
1001|1|SCR|2023-01-07|2023-01-10
1001|2|PBO|2023-01-10|2023-01-30
1001|3|FU|2023-02-01|2023-02-15
1002|1|SCR|2023-01-07|2023-01-10
M1002|2|PBO|2023-01-10|2023-01-30
1002|3|FU|2023-01-30|2023-02-15
;;;;
run;
 
 
options validvarname=upcase;
/*=========================================================
Programming for the Task
=========================================================*/
 
 
*==============================================================================;
*Sort the dataset based on subject and element order;
*==============================================================================;
 
proc sort data=se out=se01;
   by usubjid taetord;
run;
 
*==============================================================================;
*Retain the previous element's end date on to current record and check if they are the same;
*==============================================================================;
 
data se02;
   set se01;
   by usubjid taetord;
   length prev_end $10;
   prev_end=lag(seendtc);
   if first.usubjid then call missing(prev_end);
   if not first.usubjid then do;
      if prev_end ne sestdtc then flag="Y";
   end;
run;


****************************Change from previous non-missing result****************************************;
************************************************************************************************************;

data adlb;
infile datalines dlm='|' dsd missover;
input USUBJID : best32. PARAMCD : $8. ADY : best32. AVAL : best32.;
label ;
format ;
datalines4;
1001|GLUC|-4|123
1001|GLUC|1|120
1001|GLUC|8|132
1002|GLUC|2|154
1002|GLUC|8|152
1003|GLUC|-5|180
1003|GLUC|-1|184
1004|GLUC|1|101
1004|GLUC|8|
1004|GLUC|10|110
1004|GLUC|12|
;;;;
run;

options validvarname=upcase;
/*=========================================================
Programming for the Task
=========================================================*/
 
 
*==============================================================================;
*Sort the records such that they are chronological order;
*==============================================================================;
 
proc sort data=adlb out=adlb01;
   by usubjid paramcd ady;
run;
 
*==============================================================================;
*Retain the last non-missing result onto current record;
*==============================================================================;
 
data adlb02;
   set adlb01;
   by usubjid paramcd ady;
   retain prev_aval;
   if first.paramcd then call missing(prev_aval);
 
   if nmiss(prev_aval,aval)=0 then diff=aval-prev_aval;
 
   if aval ne . then prev_aval=aval;
   drop prev_aval;
run;
 
 
*******************************************Filter all records of subjects with a duplicate record in ADSL*********************************************;
*********************************************************************************************************************;

data adsl;
infile datalines dlm='|' dsd missover;
input USUBJID : $20. AGE : best32. SEX : $1. EOTSTT : $20.;
label ;
format ;
datalines4;
MYCSG-1001|35|M|COMPLETED
MYCSG-1002|67|F|ONGOING
MYCSG-1002|67|F|DISCONTINUED
MYCSG-1003|43|M|COMPLETED
MYCSG-1003|43|M|
MYCSG-1003||M|
;;;;
run;

options validvarname=upcase;
/*=========================================================
Programming for the Task
=========================================================*/
 
 
*==============================================================================;
*Solution using nouniquekeys option on proc sort;
*==============================================================================;
 
proc sort data=adsl   out=_x uniqueout=_y nouniquekeys;
    by usubjid;
run;
 
*==============================================================================;
*Solution using first and last dot variables approach;
*==============================================================================;
 
proc sort data=adsl;
   by usubjid;
run;
 
data _x1;
   set adsl;
   by usubjid;
   if not (first.usubjid and last.usubjid) then output;
run;
 
*==============================================================================;
*Solution using proc sql;
*==============================================================================;
 
proc sql;
   create table _x2 as
   select *,count(*) as count
   from adsl
   group by usubjid
   having count gt 1;
quit;

*************************************************************************************;
****************************************************************************************************************;

data dev;
infile datalines dlm='|' dsd missover;
input PARAMCD : $200. LABEL : $200. TRT1 : $10. TRT2 : $10.;
label ;
format ;
datalines4;
BMI|Category 1|xx ( xx.x)|xx ( xx.x)
BMI|Category 2|xx ( xx.x)|xx ( xx.x)
BMI|Category 3|xx ( xx.x)|xx ( xx.x)
CO2|Category 1|xx ( xx.x)|xx ( xx.x)
CO2|Category 2|xx ( xx.x)|xx ( xx.x)
CO2|Category 3|xx ( xx.x)|xx ( xx.x)
;;;;
run;

data qc;
infile datalines dlm='|' dsd missover;
input PARAMCD : $200. LABEL : $200. TRT1 : $10. TRT2 : $10.;
label ;
format ;
datalines4;
BMI|Category 1|xx (xx.x)|xx (xx.x)
BMI|Category 2|xx (xx.x)|xx (xx.x)
BMI|Category 3|xx (xx.x)|xx (xx.x)
CO2|Category 1|xx (xx.x)|xx (xx.x)
CO2|Category 2|xx (xx.x)|xx (xx.x)
CO2|Category 3|xx (xx.x)|xx (xx.x)
;;;;
run;

options validvarname=upcase;
/*=========================================================
Programming for the Task
=========================================================*/
 
 
*==============================================================================;
*Run compare on actual datasets;
*==============================================================================;
 
proc compare base=dev compare=qc;
run;
 
*==============================================================================;
*Remove spaces from treatment columns;
*==============================================================================;
 
*------------------------------------------------------------------------------;
*dev;
*------------------------------------------------------------------------------;
 
data dev01;
   set dev;
 
   array trts[*] trt1 trt2;
 
   do i=1 to dim(trts);
      trts[i]=compress(trts[i]);
   end;
 
   drop i;
run;
 
*------------------------------------------------------------------------------;
*qc;
*------------------------------------------------------------------------------;
 
 
data qc01;
   set qc;
 
   array trts[*] trt1 trt2;
 
   do i=1 to dim(trts);
      trts[i]=compress(trts[i]);
   end;
 
   drop i;
run;
 
*==============================================================================;
*Run compare on updated datasets;
*==============================================================================;
 
proc compare base=dev01 compare=qc01;
run;

**************************************Check if at least one dose of a concomitant medication is taken within study*******************************************;
*****************************************************************************************************************;
 
data adsl;
infile datalines dlm='|' dsd missover;
input USUBJID : $20. TRTSDT : DATE9. TRTEDT : DATE9.;
label ;
format TRTSDT DATE9. TRTEDT DATE9.;;
datalines4;
1001|01MAR2010|30NOV2011
;;;;
run;

data cm;
infile datalines dlm='|' dsd missover;
input STUDYID : $5. USUBJID : $10. CMTRT : $20. CMSTDTC : $10. CMENDTC : $10. CMSEQ : best32.;
label USUBJID ='USUBJID';
format ;
datalines4;
1001|Treatment1|2008|2009|1
1001|Treatment2|2008|2010|2
1001|Treatment3|2008|2011|3
1001|Treatment4|2008|2012|4
1001|Treatment3|2010|2011|5
1001|Treatment5|2010-02-28|2010-02-29|6
1001|Treatment6|2010-03-01|2010-03-01|7
1001|Treatment7|2010-04-01|2011-03-14|8
1001|Treatment9|2011-11-15|2011-12-31|9
1001|Treatment8|2011-11-30|2011-11-30|10
1001|Treatment10|2011-12-15|2011-12-31|11
;;;;
run;

options validvarname=upcase;
/*=========================================================
Programming for the Task
=========================================================*/
 
 
*==============================================================================;
*Impute partial start and end dates;
*==============================================================================;
 
data cm01;
   set cm;
 
*------------------------------------------------------------------------------;
*start date;
*------------------------------------------------------------------------------;
 
   if length(cmstdtc)=10 then do;
     firstdate=cmstdtc;
   end;
   else if length(cmstdtc)=7 then do;
     firstdate=cats(cmstdtc,"-01");
   end;
   else if length(cmstdtc)=4 then do;
     firstdate=cats(cmstdtc,"-01-01");
   end;
 
*------------------------------------------------------------------------------;
*end date;
*------------------------------------------------------------------------------;
 
   if length(cmendtc)=10 then do;
     lastdate=cmendtc;
   end;
   else if length(cmendtc)=7 then do;
     lastdate=put(intnx("month",input(cats(cmendtc,"-01"),yymmdd10.),0,"e"),yymmdd10.);
   end;
   else if length(cmendtc)=4 then do;
     lastdate=cats(cmendtc,"-12-31");
   end;
 
   firstdt=input(firstdate,??yymmdd10.);
   lastdt=input(lastdate,??yymmdd10.);
 
   format firstdt lastdt date9.;
run;
 
*==============================================================================;
*Check if at least one dose is received within study treatment period
*==============================================================================;
 
proc sql;
   create table cm02 as
      select a.*,b.trtsdt,b.trtedt
      from cm01 as a
      left join
      adsl as b
      on a.usubjid=b.usubjid
      order by usubjid,cmseq
      ;
quit;
 
data cm03;
   set cm02;
 
   if ( . lt trtsdt le firstdt le trtedt) or
      (. lt trtsdt le lastdt le trtedt) or
      (. lt firstdt lt trtsdt and lastdt gt trtedt gt .) then flag="Y";
run;