DECLARE
    L_RETURN_STATUS VARCHAR2(240);
    L_MSG_COUNT NUMBER; 
    L_MSG_DATA VARCHAR2(240); 
    L_CASH_RECEIPT_ID NUMBER; 
    v_customer_number VARCHAR2(240); 
    v_cust_name VARCHAR(240); 
    v_amount NUMBER; 
    v_receipt_number NUMBER; 
    LC_DATA VARCHAR2(1000); 
    LN_msg_index_out NUMBER;
    
    l_attribute_rec AR_RECEIPT_API_PUB.ATTRIBUTE_REC_TYPE;
BEGIN 
    BEGIN 
        MO_GLOBAL.SET_POLICY_CONTEXT('S',82);
        FND_GLOBAL.APPS_INITIALIZE(1337,20678,222); 
    END; 
   /* FOR I IN C1 LOOP 
        BEGIN
            v_cust_name := I.customer_name;
            SELECT DISTINCT ARC.CUSTOMER_NUMBER 
            INTO v_customer_number 
            FROM AR_CUSTOMERS ARC 
            ,HZ_CUST_ACCOUNTS_ALL HCA 
            ,HZ_CUST_ACCT_SITES_ALL HCAS 
            WHERE HCA.CUST_ACCOUNT_ID = HCAS.CUST_ACCOUNT_ID 
            AND HCA.CUST_ACCOUNT_ID = ARC.CUSTOMER_ID 
            AND HCAS.ORG_ID = I.ORG_ID 
            AND LTRIM(RTRIM(UPPER(ARC.CUSTOMER_NAME))) = LTRIM(RTRIM(UPPER(v_cust_name))); 
            DBMS_OUTPUT.PUT_LINE ('Customer Id - '||v_customer_number);
        EXCEPTION 
            WHEN NO_DATA_FOUNd 
            THEN DBMS_OUTPUT.PUT_LINE(I.CUSTOMER_NAME||' Customer Error: '||SUBSTR(SQLERRM,1,150)); 
        END; */  
        
    v_amount:= 100; --to_number(substr(I.AMOUNT,1,length(I.AMOUNT)-1));  
    v_receipt_number := '7668497195';--to_number(I.RECEIPT_NUMBER); 
    l_attribute_rec.ATTRIBUTE_CATEGORY := 'Misc';
    l_attribute_rec.ATTRIBUTE9 := 'AR_RECEIPT_API_PUB.CREATE_CASH';
    l_attribute_rec.ATTRIBUTE13 := TRUNC(SYSDATE);
    l_attribute_rec.ATTRIBUTE15 := 'XX_QG_AK';  
    
	BEGIN   
		AR_RECEIPT_API_PUB.CREATE_CASH ( p_api_version => '1.0'
										, p_init_msg_list => FND_API.G_TRUE
										, p_commit => FND_API.G_TRUE
										, p_validation_level => FND_API.G_VALID_LEVEL_FULL
										, x_return_status => l_return_status
										, x_msg_count => l_msg_count
										, x_msg_data => l_msg_data
										, p_currency_code => 'INR'
										, p_amount => v_amount
										, p_receipt_number => v_receipt_number
										, p_receipt_date => sysdate
										, p_gl_date => sysdate
										, p_customer_number => '138455'
										, p_org_id => 82
										, p_receipt_method_id => '1012'
										, p_attribute_rec => l_attribute_rec
										, p_cr_id => l_cash_receipt_id);  
										
		DBMS_OUTPUT.PUT_LINE('Cash Receipt RETURN DETAIL '||'-'||l_cash_receipt_id||'- Comments : '||l_msg_data||', Error Status: '||l_return_status); 

		IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
			FOR i IN 1 .. l_msg_count LOOP
				FND_MSG_PUB.GET(p_msg_index => FND_MSG_PUB.G_NEXT
											  ,  p_encoded => 'F'
											  ,  p_data => l_msg_data
											  ,  p_msg_index_out => LN_msg_index_out
												);
				DBMS_OUTPUT.PUT_LINE('A. Message ' || i ||' : '||l_msg_data|| ',  LN_MSG_INDEX_OUT : ' ||LN_MSG_INDEX_OUT);
				
				LC_DATA := FND_MSG_PUB.GET(p_msg_index => FND_MSG_PUB.G_NEXT
											  ,  p_encoded => 'F'
											  );
				DBMS_OUTPUT.PUT_LINE('B. Message ' || i ||' : '||LC_DATA|| ',  LN_MSG_INDEX_OUT : ' ||LN_MSG_INDEX_OUT);
			
			END LOOP; 
		ELSIF l_return_status = FND_API.G_RET_STS_SUCCESS
				THEN     COMMIT; 
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			DBMS_OUTPUT.PUT_LINE('An unexpected error occurred: ' || SQLERRM);
			ROLLBACK;
	END;

EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLERRM||'-'||l_msg_data); 
END;