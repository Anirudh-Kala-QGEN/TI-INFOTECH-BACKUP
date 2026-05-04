CREATE OR REPLACE PROCEDURE APPS.TI_UPLOAD_FLEX_VALUES1(
                                                        RETCODE OUT VARCHAR2,
                                                        ERRBUF OUT VARCHAR2
                                                      )
IS

BEGIN

DECLARE 
CURSOR c1 IS
        SELECT DISTINCT FILE_CODE,COSTING_NAME 
          FROM TOUR_COSTING_MAS@taprod_dblink
         WHERE FILE_CODE IS NOT NULL
           AND CANCEL_FLG <> 'Y'
           AND SBU_CODE ='0002'
           --AND FILE_CODE IN ('PLT17010001')
           AND FILE_CODE NOT IN (
                                 SELECT FLEX_VALUE 
                                   FROM FND_FLEX_VALUES  A, 
                                        FND_FLEX_VALUES_TL  B
                                  WHERE A.FLEX_VALUE_ID = B.FLEX_VALUE_ID
                                    AND PARENT_FLEX_VALUE_LOW = '12400'
                                 )
        and file_code in(select flex_value from proj_code                     )                                  
UNION
        SELECT DISTINCT SUBSTR(FILE_CODE,1,25),REMARKS 
          FROM PO_MAS@taprod_dblink
         WHERE ADDL_FIELD9 LIKE 'OPENING%'
           AND ADDL_FIELD9 IS NOT NULL
           AND FILE_CODE NOT IN (SELECT FLEX_VALUE 
                                   FROM FND_FLEX_VALUES  A, 
                                        FND_FLEX_VALUES_TL  B
                                  WHERE A.FLEX_VALUE_ID = B.FLEX_VALUE_ID
                                    AND PARENT_FLEX_VALUE_LOW = '12400'
                                )
            and file_code in(select flex_value from proj_code                     )                                 ;
                                
nCOUNT NUMBER:=0;

BEGIN

FOR I IN C1 LOOP
    nCOUNT:=0;
    SELECT COUNT(1) 
      INTO nCOUNT 
      FROM FND_FLEX_VALUES
     WHERE FLEX_VALUE =UPPER(I.FILE_CODE) 
       AND PARENT_FLEX_VALUE_LOW='12400';
            
        IF nCOUNT = 0  THEN
           
          begin
             INSERT INTO FND_FLEX_VALUES(
                                       FLEX_VALUE_SET_ID,
                                       FLEX_VALUE_ID,
                                       FLEX_VALUE,
                                       ENABLED_FLAG,
                                       SUMMARY_FLAG,
                                       COMPILED_VALUE_ATTRIBUTES,
                                       CREATION_DATE,LAST_UPDATE_DATE,
                                       CREATED_BY,
                                       LAST_UPDATED_BY,
                                       PARENT_FLEX_VALUE_LOW,
                                       ATTRIBUTE50
                                       )
                                VALUES (
                                       '1016629',--'1009629',
                                       FND_FLEX_VALUES_S.NEXTVAL,
                                       UPPER(I.FILE_CODE),'Y','N','Y'||CHR(10)||'Y',
                                       SYSDATE,
                                       SYSDATE,
                                       1130,
                                       1130,
                                       '12400',
                                       'TIUPLOAD'
                                       );
           exception when others then
                dbms_output.Put_line(I.FILE_CODE||sqlerrm);
           end;                            
               
               begin                        
                 INSERT INTO FND_FLEX_VALUES_TL(
                                        FLEX_VALUE_ID,
                                        LANGUAGE,
                                        SOURCE_LANG,
                                        FLEX_VALUE_MEANING,
                                        DESCRIPTION,
                                        CREATION_dATE,
                                        LAST_UPDATE_DATE,
                                        CREATED_BY,
                                        LAST_UPDATED_BY
                                        )
                                VALUES ( 
                                        FND_FLEX_VALUES_S.CURRVAL,
                                        'US',
                                        'US',
                                        UPPER(I.FILE_CODE),
                                        I.COSTING_NAME,
                                        SYSDATE,
                                        SYSDATE,
                                        1130,
                                        1130
                                        );
               exception when others then
                dbms_output.Put_line('-'||I.FILE_CODE||sqlerrm);
               end;                       
        END IF;
        
END LOOP;
COMMIT;
END;
END TI_UPLOAD_FLEX_VALUES1;
/
