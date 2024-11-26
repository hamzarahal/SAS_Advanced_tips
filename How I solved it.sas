/*****************How I solved it?***************************/
/*******************************************************************/

*******************Identify the overlap of dates in exposure intervals *********;

data ex;
infile datalines dlm='|' dsd missover;
input USUBJID : $10. EXSTDTC : $10. EXENDTC : $10. EXSEQ : best32.;
label ;
format ;
datalines4;
MYCSG-1001|2023-01-01|2023-01-10|1
MYCSG-1001|2023-01-11|2023-01-13|2
MYCSG-1001|2023-01-15|2023-01-18|3
MYCSG-1001|2023-01-16|2023-01-23|4
MYCSG-1001|2023-01-24|2023-01-25|5
MYCSG-1001|2023-01-25|2023-01-28|6
MYCSG-1002|2023-02-01|2023-02-10|1
MYCSG-1002|2023-02-11|2023-02-13|2
MYCSG-1002|2023-03-05|2023-03-30|3
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