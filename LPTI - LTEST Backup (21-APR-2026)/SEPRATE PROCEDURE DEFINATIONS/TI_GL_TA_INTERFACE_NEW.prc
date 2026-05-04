CREATE OR REPLACE PROCEDURE APPS.TI_GL_TA_INTERFACE_NEW (
   errbuf     OUT VARCHAR2,
   retcode    OUT VARCHAR2,
   P_PERIOD_NAME    VARCHAR2
   )

IS
    p_set_books_id  number        := '2121';
    vDailry_rates number;

BEGIN

     FND_FILE.PUT_line (FND_FILE.LOG, 'START_PERIOD_NAME'||P_PERIOD_NAME);
     dbms_output.PUT_line ('START_PERIOD_NAME'||P_PERIOD_NAME);


        BEGIN
        LOOP
INSERT INTO GL_INTERFACE
            (STATUS,SET_OF_BOOKS_ID,REFERENCE1,REFERENCE2,REFERENCE4,REFERENCE5,REFERENCE10,
            SEGMENT1,
            SEGMENT2,
            SEGMENT3,
            SEGMENT4,
            SEGMENT5,
            SEGMENT6,
            SEGMENT7,
            SEGMENT8,
            ENTERED_DR,ENTERED_CR,ACCOUNTED_DR,ACCOUNTED_CR,ACCOUNTING_DATE,CURRENCY_CODE,ACTUAL_FLAG,
            USER_JE_CATEGORY_NAME,USER_JE_SOURCE_NAME,DATE_CREATED,CREATED_BY,REFERENCE11,REFERENCE12)
            SELECT
            'NEW' STATUS,
            '2121' SET_OF_BOOKS_ID,
            h.JE_BATCH_ID||'-'||'LPTI_MANUAL' BATCH_NAME,
            h.JE_BATCH_ID||'-'||'LPTI_MANUAL' BATCH_DESCRIPTION,
            h.name JOURNAL_NAME,
            h.DESCRIPTION JOURNAL_DESCRIPTION,
            l.DESCRIPTION LINE_DESCRIPTION,
            s.SEGMENT1,
            s.SEGMENT2,
            s.SEGMENT3,
            s.SEGMENT4,
            s.SEGMENT5,
            s.SEGMENT6,
            s.SEGMENT7,
            s.SEGMENT8,
            ROUND(TO_NUMBER(ABS(l.ENTERED_DR)),2) ENTERED_DR,
            ROUND(TO_NUMBER(ABS(l.ENTERED_CR)),2) ENTERED_CR,
            ROUND(TO_NUMBER(ABS(l.ENTERED_DR * NVL(H.CURRENCY_CONVERSION_RATE,1))),2) ACCOUNTED_DR,
            ROUND(TO_NUMBER(ABS(l.ENTERED_CR * NVL(H.CURRENCY_CONVERSION_RATE,1))),2) ACCOUNTED_CR,
            l.EFFECTIVE_DATE GL_DATE,
            h.CURRENCY_CODE CURR_CODE,
            'A' ACTUAL_FLG,
            'LPTI_MANUAL' JE_CATEGORY,
            'LPTI_MANUAL' JE_SOURCE,
            l.EFFECTIVE_DATE,
            1110 CREATED_BY,
            'TA_JOURNAL_IMPORT',
            NULL
            FROM
                 GL_JE_HEADERS@APPS_OLD.LPTI.COM h
                ,GL_JE_LINES@APPS_OLD.LPTI.COM l
                , GL_CODE_COMBINATIONS@APPS_OLD.LPTI.COM s 
            where h.JE_HEADER_ID = l.JE_HEADER_ID
            and s.CODE_COMBINATION_ID = l.CODE_COMBINATION_ID
            and h.PERIOD_NAME IN ('MAR-24','APR-24','MAY-24','JUN-24','JUL-24')
            AND h.JE_SOURCE NOT IN ('Payables', 'Receivables')           ;

        END LOOP;

        EXCEPTION
            WHEN OTHERS THEN
            FND_FILE.PUT_line (FND_FILE.LOG, 'EXCEPTION PERIOD_NAME'||P_PERIOD_NAME);
         DBMS_OUTPUT.PUT_LINE(SQLERRM);
       END;

        commit;

 END;
/
