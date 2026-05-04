CREATE OR REPLACE procedure APPS.lpti_ar_open_item_fifo (
                                        retcode out varchar2,
                                        errbuf out varchar2,
                                        P_AS_ON_DATE varchar2,
                                        p_currency_wise varchar2
                                        ) is 
                                        
  
  P_USER_ID VARCHAR2(200);
  P_TO_DATE                       DATE := FND_DATE.CANONICAL_TO_DATE(P_AS_ON_DATE);
BEGIN 
  /*------------------------------------------------
  P_AS_ON_DATE Parameter Must be date without Time
  /*------------------------------------------------
  --P_AS_ON_DATE := TRUNC(SYSDATE);
  /*------------------------------------------------*/
   
  P_USER_ID := '01136';
  
  if p_currency_wise='F' then 
      begin
      APS_AR_INV_AUTO_ADJ_PACK.GEN_AR_INV_AGEING ( P_TO_DATE, P_USER_ID );
      COMMIT;
      end; 
  elsif p_currency_wise='T' then
      begin
      APS_AR_INV_AUTO_ADJ_CUR_PACK1.GEN_AR_INV_AGEING (P_TO_DATE,P_USER_ID );
      COMMIT;
      end; 
  else
  null;
  end if;
   
END;
/
