CREATE OR REPLACE PROCEDURE APPS.PRO_SUB_GL_UPLOAD_OTHER
IS
   vcnt number;
   vnew_value number;

   BEGIN
   FOR   cur1 IN (select b.flex_value_id FLEX_VALUE_ID
                    ,a.LANGUAGE,a.LAST_UPDATE_DATE,a.LAST_UPDATED_BY,a.CREATION_DATE,a.CREATED_BY,a.LAST_UPDATE_LOGIN,a.DESCRIPTION,a.SOURCE_LANG,a.FLEX_VALUE_MEANING 
                  from FND_FLEX_VALUES_TL@apps_old a,FND_FLEX_VALUES b
                  where  a.flex_value_id = nvl(b.ATTRIBUTE12,b.flex_value_id)
                  and b.flex_value_set_id in('1016629')
                  and PARENT_FLEX_VALUE_LOW =12400
                  and trunc(b.creation_date) =trunc(sysdate)
                  
--                  select b.flex_value_id FLEX_VALUE_ID
--                    ,a.LANGUAGE,a.LAST_UPDATE_DATE,a.LAST_UPDATED_BY,a.CREATION_DATE,a.CREATED_BY,a.LAST_UPDATE_LOGIN,a.DESCRIPTION,a.SOURCE_LANG,a.FLEX_VALUE_MEANING 
--                  from FND_FLEX_VALUES_TL@apps_old a,FND_FLEX_VALUES b
--                  where  a.flex_value_id = nvl(b.ATTRIBUTE12,b.flex_value_id)
--                  and b.flex_value_set_id in('1016629')
--                  and PARENT_FLEX_VALUE_LOW !=12400
                  )
        

         LOOP
         
            DBMS_OUTPUT.PUT_LINE ('start TL-' || cur1.FLEX_VALUE_ID);
--              BEGIN
--                 SELECT COUNT (1)
--                   INTO vcnt
--                   FROM FND_FLEX_VALUES_TL
--                  WHERE flex_value_id = cur1.flex_value_id;
--              EXCEPTION
--                 WHEN OTHERS
--                 THEN
--                    vcnt := 0;
--              END;
--
--              IF vcnt = 0
             -- THEN
                 BEGIN
                    INSERT INTO FND_FLEX_VALUES_TL (FLEX_VALUE_ID,
                                                    LANGUAGE,
                                                    LAST_UPDATE_DATE,
                                                    LAST_UPDATED_BY,
                                                    CREATION_DATE,
                                                    CREATED_BY,
                                                    LAST_UPDATE_LOGIN,
                                                    DESCRIPTION,
                                                    SOURCE_LANG,
                                                    FLEX_VALUE_MEANING)
                         VALUES (cur1.FLEX_VALUE_ID,
                                 cur1.LANGUAGE,
                                 SYSDATE,
                                 cur1.LAST_UPDATED_BY,
                                 SYSDATE,
                                 cur1.CREATED_BY,
                                 cur1.LAST_UPDATE_LOGIN,
                                 cur1.DESCRIPTION,
                                 cur1.SOURCE_LANG,
                                 cur1.FLEX_VALUE_MEANING
                                 );
                 EXCEPTION
                    WHEN others
                    THEN
                       DBMS_OUTPUT.PUT_LINE (
                             'Error During insertion into Existing flex field TL-'
                          || cur1.FLEX_VALUE_ID);
                 END;
             -- END IF;

              COMMIT;

              IF vcnt > 0
              THEN
                 BEGIN
                    SELECT MAX (flex_value_id) + 1
                      INTO vnew_value
                      FROM FND_FLEX_VALUES_TL;
                 EXCEPTION
                    WHEN OTHERS
                    THEN
                       vnew_value := 0;
                 END;

                 IF vnew_value != 0
                 THEN
                    DBMS_OUTPUT.PUT_LINE (
                          'Error During insertion into Existing flex field SUB GL 12400  NEW -'
                       || cur1.FLEX_VALUE_ID);
                 END IF;
              END IF;
         
         end loop;
          EXCEPTION WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE(' Exception in cursor'|| SQLERRM || ' '|| SQLCODE);
          END;
/
