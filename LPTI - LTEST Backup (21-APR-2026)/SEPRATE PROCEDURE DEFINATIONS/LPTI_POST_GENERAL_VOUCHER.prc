CREATE OR REPLACE PROCEDURE APPS.LPTI_POST_GENERAL_VOUCHER(ERRORBUF OUT VARCHAR2,
                                                      RECODE OUT VARCHAR2,
                                                      P_FDATE VARCHAR2,
                                                      P_TDATE VARCHAR2
                                                     )
                                                     IS
   x_user_id             NUMBER;
   x_sob_id              NUMBER;
   x_coa_id              NUMBER;
   x_user_source_name    VARCHAR2 (80);
   x_source_name         VARCHAR2 (30);
   x_appl_id             VARCHAR2 (50);
   x_resp_id             VARCHAR2 (50);
   x_summary_flag        VARCHAR2 (1)    := 'N';
   x_conc_id             NUMBER;
   x_posting_run_id      NUMBER;
   x_access_set_id       NUMBER;
   P_FROM_DATE           DATE;
   P_TO_DATE             DATE;   
   x_req_return_status   BOOLEAN;
   err_msg               VARCHAR2 (2000);
   
BEGIN
   fnd_message.CLEAR;
   
   P_FROM_DATE := FND_DATE.CANONICAL_TO_DATE(P_FDATE);
   P_TO_DATE   := FND_DATE.CANONICAL_TO_DATE(P_TDATE);
   
   fnd_file.put_line(fnd_file.output,'01');


for i  in (SELECT DISTINCT b.je_batch_id 
             FROM  gl_je_batches b
            where b.default_effective_date between P_FROM_DATE and P_TO_DATE
              and b.status <>'P'
              and b.je_batch_id in (select distinct je_batch_id from gl_je_headers a where a.je_batch_id=b.je_batch_id)
              --order by b.default_effective_date
              ) loop  

fnd_file.put_line(fnd_file.output,'02');

   SELECT user_id
     INTO x_user_id
     FROM fnd_user
    WHERE user_name = 'TIADMIN';

   SELECT application_id
     INTO x_appl_id
     FROM fnd_application
    WHERE application_short_name = 'SQLGL';

   SELECT responsibility_id
     INTO x_resp_id
     FROM fnd_application fa, fnd_responsibility_tl fr
    WHERE fa.application_short_name = 'SQLGL'
      AND fa.application_id = fr.application_id
      AND fr.responsibility_name = 'General Ledger Super User';

   fnd_global.apps_initialize (x_user_id, x_resp_id, x_appl_id);

   SELECT set_of_books_id, chart_of_accounts_id
     INTO x_sob_id, x_coa_id
     FROM gl_sets_of_books
    WHERE short_name = 'LPTI_SOB';

   SELECT gl_je_posting_s.NEXTVAL
     INTO x_posting_run_id
     FROM DUAL;

   /* SELECT gl_interface_control_pkg.get_unique_run_id 
        INTO V_RUN_ID 
        FROM DUAL;
     */   
        
    --GL_INTERFACE_CONTROL_PKG.insert_row(1001, v_run_id, '1', V_GROUP_ID, null);     

fnd_file.put_line (fnd_file.output,'posting ID: ' || TO_CHAR (x_posting_run_id));    

update gl_je_batches
set status='S',
POSTING_RUN_ID=x_posting_run_id
where je_batch_id=i.je_batch_id;

commit;


/*
   SELECT gl_access_sets_s.NEXTVAL
     INTO x_access_set_id
     FROM DUAL;*/

x_conc_id:=fnd_request.submit_request('SQLGL', 
                                      'GLPPOS', 
                                      '', 
                                      '', 
                                      FALSE,
                                      To_Char(1001),      
                                      To_Char(50268),
                                      To_Char(x_posting_run_id),
                                      chr(0),
                                      '','','','','','','','','','','','','','','','','','','','',
                                      '','','','','','','','','','','','','','','','','','','','',
                                      '','','','','','','','','','','','','','','','','','','','',
                                      '','','','','','','','','','','','','','','','','','','','',
                                      '','','','','','','','','','','','','','','',''
                                      );



                                        
fnd_file.put_line (fnd_file.output,'ID: ' || TO_CHAR (x_conc_id));               

    IF x_conc_id = 0
       THEN
          fnd_file.put_line (fnd_file.output,'ID=0: ' || TO_CHAR (x_conc_id));
          --fnd_message.retrieve (err_msg);
          DBMS_OUTPUT.put_line (err_msg);
          fnd_file.put_line (fnd_file.output,err_msg);
          DBMS_OUTPUT.put_line (fnd_message.get);
          fnd_file.put_line (fnd_file.output,fnd_message.get);
          fnd_message.raise_error;
    ELSE
          DBMS_OUTPUT.put_line ('Submitted request_id ' || x_conc_id);
          COMMIT;                                               -- submit the job
    END IF;
    
end loop;
END;
/
