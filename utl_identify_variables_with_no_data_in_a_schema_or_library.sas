Identify variables with no data in a schema or library

see
https://goo.gl/RdSTgj
https://communities.sas.com/t5/Base-SAS-Programming/Columns-with-no-data-check-all-datasets-in-library/m-p/436136

INPUT ( Three tables with varying missing columns )
===================================================

%let path=%sysfunc(pathname(work)); * path to work library;

proc format ;
      value $chr2mis ' '="MIS" other="POP";
      value num2mis .   ="MIS" other="POP";
run;quit

WORK.DSN1 total obs=5

   NAME      SEX    HEIGHT    WEIGHT    BMI    RACE

  Alfred      M      69.0      112.5     .
  Alice       F      56.5       84.0     .
  Barbara     F      65.3       98.0     .
  Carol       F      62.8      102.5     .
  Henry       M      63.5      102.5     .


WORK.DSN2 total obs=5

   NAME      SEX    AGE    HEIGHT    BMI

  Alfred      M      14     69.0      .
  Alice       F      13     56.5      .
  Barbara     F      13     65.3      .
  Carol       F      14     62.8      .
  Henry       M      14     63.5      .



WORK.DSN3 total obs=5

   NAME      AGE    WEIGHT    RACE

  Alfred      14     112.5
  Alice       13      84.0
  Barbara     13      98.0
  Carol       14     102.5
  Henry       14     102.5


EXAMPLE OUTPUT

               LOCATION                     TABLE        MISPOP

  d:\wrk\_TD7028_E6420_\DSN1.sas7bdat    Table NAME       POP
  d:\wrk\_TD7028_E6420_\DSN1.sas7bdat    Table SEX        POP
  d:\wrk\_TD7028_E6420_\DSN1.sas7bdat    Table HEIGHT     POP
  d:\wrk\_TD7028_E6420_\DSN1.sas7bdat    Table WEIGHT     POP
  d:\wrk\_TD7028_E6420_\DSN1.sas7bdat    Table BMI        MIS  (missing)
  d:\wrk\_TD7028_E6420_\DSN1.sas7bdat    Table RACE       MIS  (missing)


MAKE DATA
=========

    * meed to do this each time you rerun;
    proc datasets lib=work kill;
    run;quit;

    data dsn1(drop=age) dsn2(drop=race weight) dsn3(drop=bmi sex height);
      set sashelp.class(obs=5);
      retain bmi . race ' ';
    run;quit;

    %let path=%sysfunc(pathname(work)); * path to work library;

    proc format ;
          value $chr2mis ' '="MIS" other="POP";
          value num2mis .   ="MIS" other="POP";
    run;quit


PROCESS (all the code)
======================

   data _null_;

     if _n_=0 then do;
        %let rc=%sysfunc(dosubl('
           * much faster then dictionaries due to excessive default libanes on EG servers
           * ok for non programmers;
           ods output members=__meta(where=(memtype="DATA"));
           proc datasets library=work /* memtype=data bug does not work */;
           run;quit;
           ods output close;
           proc sql;
              select quote(name) into :_nams separated by ","
               from __meta where not (name eqt "__")
           ;quit;
         '));
       end;

       do mems=&_nams;
         call symputx("mems",mems);
         rc=dosubl('

            * freq into two categories missing and populated;
            ods output oneWayFreqs=__ChrMis;
            proc freq compress data="&path./&mems..sas7bdat";
            tables  _all_ / missing ;
            format  _character_ $chr2mis. _numeric_ num2mis.;
            run;quit;

            * make long and skinny;
            data __trecol(keep=location table mispop);
               retain location "&path.\&mems..sas7bdat";
               length location $200;
               set __ChrMis;
               mispop=coalescec(of F_:);  * normalize n columns to one column;
            run;quit;

            proc append base=want data=__trecol;
            run;quit;

         ');
       end;
   stop;
   run;quit;

OUTPUT
======

 work.want total obs=15

  Obs                 LOCATION                     TABLE        MISPOP

    1    d:\wrk\_TD7028_E6420_/DSN1.sas7bdat    Table NAME       POP
    2    d:\wrk\_TD7028_E6420_/DSN1.sas7bdat    Table SEX        POP
    3    d:\wrk\_TD7028_E6420_/DSN1.sas7bdat    Table HEIGHT     POP
    4    d:\wrk\_TD7028_E6420_/DSN1.sas7bdat    Table WEIGHT     POP
    5    d:\wrk\_TD7028_E6420_/DSN1.sas7bdat    Table BMI        MIS
    6    d:\wrk\_TD7028_E6420_/DSN1.sas7bdat    Table RACE       MIS

    7    d:\wrk\_TD7028_E6420_/DSN2.sas7bdat    Table NAME       POP
    8    d:\wrk\_TD7028_E6420_/DSN2.sas7bdat    Table SEX        POP
    9    d:\wrk\_TD7028_E6420_/DSN2.sas7bdat    Table AGE        POP
   10    d:\wrk\_TD7028_E6420_/DSN2.sas7bdat    Table HEIGHT     POP
   11    d:\wrk\_TD7028_E6420_/DSN2.sas7bdat    Table BMI        MIS

   12    d:\wrk\_TD7028_E6420_/DSN3.sas7bdat    Table NAME       POP
   13    d:\wrk\_TD7028_E6420_/DSN3.sas7bdat    Table AGE        POP
   14    d:\wrk\_TD7028_E6420_/DSN3.sas7bdat    Table WEIGHT     POP
   15    d:\wrk\_TD7028_E6420_/DSN3.sas7bdat    Table RACE       MIS



