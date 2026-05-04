CREATE OR REPLACE PROCEDURE APPS.TI_AP_SUPPLIER_SITES_INT_NEW1      (ERRBUF OUT VARCHAR2,
                                                         RETCODE OUT VARCHAR2
                                                        )
 IS
 
 
 V_STATUS                BOOLEAN        := TRUE;
 V_RECORD_INSERTED       NUMBER         := 0;
 V_RECORD_REJECT         NUMBER         := 0;
 V_CONC_REQUEST_ID       NUMBER;
 V_VENDOR_ID             NUMBER;
 V_CITY_NAME             VARCHAR2(50);
 V_ADDRESSES             VARCHAR2(250);
 nCOUNT_V                NUMBER         :=0;
 nCOUNT_INT              NUMBER         :=0; 
 nVENDOR_NO              NUMBER; 
 vCITY                   VARCHAR2(10);
 V_CODE_COMBINATION_ID   NUMBER;
  v_city_code  varchar2(240);
 v_ADDRESS1   varchar2(240);
 v_ADDRESS2   varchar2(240);
 v_ADDRESS3   varchar2(240);
 v_PHONE_NO1  varchar2(20);
 v_PIN_NO     varchar2(10);
 v_EMAIL      varchar2(250);
 v_MOBILE_NO  varchar2(15); 
   l_ERRBUF     VARCHAR2 (32767);
    l_RETCODE    VARCHAR2 (32767);
    l_P_ORG_ID   VARCHAR2 (32767);
    P_SUPP_CODE   VARCHAr2(32767);
 
 BEGIN
 
     FOR I IN (
                      SELECT   TYPE || '-' || code segment1,
                                NAME,
                                ALT_NAME,
                                DECODE (TYPE,
                                        'V', 'VENDOR',
                                        'H', 'HOTEL',
                                        'G', 'GUIDE',
                                        'OTHERS')
                                   V_TYPE,
                                CITY_NAME,
                                ADDRESSES
                         FROM   VENDOR_VW_ALL@TAPROD_DBLINK A
                        WHERE   A.TYPE IN ('V', 'H', 'G') 
                            AND A.SBU_CODE = '0002'
                            AND TRUNC(A.ENTERED_DATE) >='01-JAN-2017'
                            AND A.ACTIVE_FLG='Y'
                            --and a.code ='H0007529'
                            AND A.TYPE || '-' || A.CODE NOT IN (SELECT   SEGMENT1 FROM AP_SUPPLIERS)
                            AND A.TYPE || '-' || A.CODE NOT IN (SELECT   SEGMENT1 FROM AP_SUPPLIERS_INT)   
           ) LOOP
      
     FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'1'); 
      
         
     BEGIN
     FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'4');
     SELECT  CITY_NAME,ADDRESSES
             INTO V_CITY_NAME,V_ADDRESSES
             FROM VENDOR_VW@TAPROD_DBLINK WHERE TYPE IN ('V','H','G')
              AND SBU_CODE ='0002'
              AND TYPE||'-'||CODE=I.SEGMENT1;
     EXCEPTION WHEN OTHERS THEN
     FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'5');
        V_CITY_NAME:=NULL;
        V_ADDRESSES:=NULL;
        --V_STATUS   :=FALSE;
     END;              
     
    begin
    select CITY_CODE,
           ADDRESS1,
           ADDRESS2,
           ADDRESS3,
           replace(PHONE_NO1,chr(32),'') PHONE_NO1,
           PIN_NO ,
           EMAIL,
           replace(MOBILE_NO,chr(32),'') MOBILE_NO
      into v_city_code,
           v_ADDRESS1,
           v_ADDRESS2,
           v_ADDRESS3,
           v_PHONE_NO1,
           v_PIN_NO ,
           v_EMAIL,
           v_MOBILE_NO         
      from ta_vendor_dtl 
     where type||'-'||code=I.SEGMENT1;
     FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'6');
     exception when others then
     v_ADDRESS1 :=V_ADDRESSES;
     v_ADDRESS2 :=null;
     v_ADDRESS3 :=null;
     v_PHONE_NO1:=null;
     v_PIN_NO   :=null  ;
     FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'7');
    end;
     
     
 DECLARE
    -- Variable declarations
  
BEGIN
    -- Variable initializations
    l_P_ORG_ID := 81;

    -- Call
    APPS.PKG_TA_AP_TRF_INT.TI_AP_VENDOR_INTERFACE_PROC (
        ERRBUF     => l_ERRBUF,
        RETCODE    => l_RETCODE,
        P_ORG_ID   => l_P_ORG_ID,
        P_SUPP_CODE => i.segment1);
        
       
    -- Transaction control
    COMMIT;

  
END;
   
   END LOOP;
   FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'10');
     

     IF V_STATUS = TRUE
     THEN
     COMMIT;
     V_RECORD_INSERTED := V_RECORD_INSERTED + 1;
     ELSE
     V_RECORD_REJECT := V_RECORD_REJECT + 1;
     END IF;
   
     FND_FILE.PUT_LINE (FND_FILE.OUTPUT,
                       'Number of Invoices Inserted are: ' || v_record_inserted
                       );
     FND_FILE.PUT_LINE (FND_FILE.OUTPUT,
                       'Number of Invoices Rejected are: ' || v_record_reject
                       );

                     
-----------------------------------------------------------------------------------------------------------------
/* call interface program "Supplier Sites Open Interface Import" to upload the Supplier Sitesn into base table */
-----------------------------------------------------------------------------------------------------------------

    IF V_RECORD_INSERTED > 0
    THEN
      FND_GLOBAL.APPS_INITIALIZE
                           (USER_ID           => FND_PROFILE.VALUE ('USER_ID'),
                            RESP_ID           => FND_PROFILE.VALUE ('RESP_ID'),
                            RESP_APPL_ID      => FND_PROFILE.VALUE ('RESP_APPL_ID')
                           );
                           
      V_CONC_REQUEST_ID :=
         FND_REQUEST.SUBMIT_REQUEST (APPLICATION                  => 'SQLAP',
                                         PROGRAM                  => 'APXSSIMP',
                                       ARGUMENT1                  => 'NEW',
                                       ARGUMENT2                  => 1000,
                                       ARGUMENT3                  => 'N',
                                       ARGUMENT4                  => 'N',
                                       ARGUMENT5                  => 'N',
                                       ARGUMENT6                  => '-99'
                                    );
      COMMIT;

      IF (V_CONC_REQUEST_ID = 0)
      THEN
         FND_FILE.PUT_LINE
                   (FND_FILE.OUTPUT,
                    'NOT Able TO Submit the Payable Interface Import Program'
                   );
         
         
      END IF;
      END IF;    
  
  

 EXCEPTION
 WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(SQLERRM);
 END;
/
