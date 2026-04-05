DECLARE
	CURSOR CUR_CONS_RCPT_NO IS
	SELECT CONS_RCPT_NO, ATTRIBUTE7, ATTRIBUTE8
	FROM ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT@ebstohr
	WHERE CONS_RCPT_NO IS NOT NULL
	GROUP BY CONS_RCPT_NO, ATTRIBUTE7, ATTRIBUTE8; 

	CURSOR RCPT_CUR(P_CONS_RCPT_NO VARCHAR2, P_ATTRIBUTE7 VARCHAR2, P_ATTRIBUTE8 VARCHAR2) IS
	SELECT PARTY_NUMBER
	, PARTY_NAME
	, PARTY_LOCATION
	, RECEIPT_NUMBER
	, PARTY_AMT
	, ATTRIBUTE_CATEGORY
	, ATTRIBUTE7
	, ATTRIBUTE8
	, ATTRIBUTE9
	, ATTRIBUTE11
	, RECEIPT_DATE
	, PROCESS_DATE12
	, BANK_ACC_ID
	, BANK_ACC_NUMBER
	, BANK_ACC_NAME
	, RECEIPT_METHOD_ID
	, CONS_RCPT_NO
	, ERP_CUSTOMER_NUMBER
	FROM ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT@ebstohr
	WHERE 1=1
	AND ATTRIBUTE7 = P_ATTRIBUTE7
	AND ATTRIBUTE8 = P_ATTRIBUTE8
	AND CONS_RCPT_NO = P_CONS_RCPT_NO;

	L_RETURN_STATUS VARCHAR2(1);
	L_MSG_COUNT NUMBER;
	L_MSG_DATA VARCHAR2(2000);
	L_CR_ID NUMBER;
	 
	-- DUMMY ACCOUNT PARAMETERS (REPLACE WITH YOUR ACTUAL IDS)
	L_BANK_ACCT_ID NUMBER := NULL; -- ID OF YOUR DUMMY BANK ACCOUNT
	L_RECEIPT_METH_ID NUMBER := 72136; -- ID OF YOUR RECEIPT METHOD
	L_CUST_ID NUMBER := 0; -- CUSTOMER ID
	L_SITE_USE_ID NUMBER := 466971; -- CUSTOMER SITE USE ID
	L_ORG_ID NUMBER := 288; -- OPERATING UNIT ID
	
	LN_INT_RCPT_NO NUMBER := 0;
	LN_TOTAL_RCPT_AMT NUMBER:=0;
	LN_msg_index_out NUMBER;
	--LN_CURRENT_AMT NUMBER := 0;
	
	
	LC_DATA VARCHAR2(4000);
	l_cash_receipt_id NUMBER;
	l_cash_receipt_NUM VARCHAR2(100):='12.22';
	
   ln_receivables_trx_id number:=7195;
BEGIN
	
	MO_GLOBAL.INIT('AR');
	FND_GLOBAL.APPS_INITIALIZE(USER_ID => 2482, RESP_ID => 20678, RESP_APPL_ID => 222); -- ?
	MO_GLOBAL.SET_POLICY_CONTEXT('S', l_org_id); --Amar Ujala Publications Limited
	
	FOR I IN CUR_CONS_RCPT_NO
	LOOP
		FOR J IN RCPT_CUR(I.CONS_RCPT_NO, I.ATTRIBUTE7, I.ATTRIBUTE8)
		LOOP
			BEGIN
				LN_INT_RCPT_NO:=LN_INT_RCPT_NO+1;
				DBMS_OUTPUT.PUT_LINE('CONC RCPT NO : '||I.CONS_RCPT_NO||'.'||LN_INT_RCPT_NO||' : Data  - ' || J.PARTY_NUMBER
																			||' - '|| J.PARTY_NAME
																			||' - '|| J.PARTY_LOCATION
																			||' - '|| J.RECEIPT_NUMBER
																			||' - '|| J.PARTY_AMT
																			||' - '|| J.ATTRIBUTE_CATEGORY
																			||' - '|| J.ATTRIBUTE7
																			||' - '|| J.ATTRIBUTE8
																			||' - '|| J.ATTRIBUTE9
																			||' - '|| J.ATTRIBUTE11
																			||' - '|| J.RECEIPT_DATE
																			||' - '|| J.PROCESS_DATE12
																			||' - '|| J.BANK_ACC_ID
																			||' - '|| J.BANK_ACC_NUMBER
																			||' - '|| J.BANK_ACC_NAME
																			||' - '|| J.CONS_RCPT_NO
																			||' - '|| J.RECEIPT_METHOD_ID
																			||' - '|| J.ERP_CUSTOMER_NUMBER);
				--LN_CURRENT_AMT:= J.PARTY_AMT;
				-- Call AR Receipt API for different customers under same bank
				BEGIN
					SELECT CUSTOMER_ID
					INTO L_CUST_ID
					FROM AR_CUSTOMERS
					WHERE CUSTOMER_NUMBER = J.ERP_CUSTOMER_NUMBER;
				EXCEPTION WHEN OTHERS THEN
				L_CUST_ID := NULL;
				DBMS_OUTPUT.PUT_LINE('Customer fetching error : '||SQLCODE||'-'||SQLERRM);
				END;
				AR_RECEIPT_API_PUB.Create_cash(
										p_api_version => 1.0,
										p_init_msg_list => FND_API.G_FALSE,
										p_commit => FND_API.G_FALSE, -- Commit the receipt
										p_validation_level => FND_API.G_VALID_LEVEL_FULL,
										
										-- Mandatory Fields
										p_receipt_number => TO_CHAR(I.CONS_RCPT_NO||'.'||LN_INT_RCPT_NO), -- invoice_num -> 
										p_amount => J.PARTY_AMT, -- 2
										p_currency_code => 'INR', --'INR'
										p_receipt_date => SYSDATE,
										p_gl_date => SYSDATE,
										
										-- Dummy Bank and Customer Information
										p_customer_id => l_cust_id, -- 6125400
										--p_customer_site_use_id => l_site_use_id, --466971	
										p_receipt_method_id => 8146,--DUMMY BANK MEERUT 
										--p_remittance_bank_account_id => l_bank_acct_id, -- Dummy Bank Here -> AR_CASH_RECEIPTS_ALL -> AR_RECEIPT_METHOD_ACCOUNTS_ALL -> CE_BANK_ACCOUNTS
										
										-- Output Parameters
										x_return_status => l_return_status,
										x_msg_count => l_msg_count,
										x_msg_data => l_msg_data,
										p_cr_id => l_cr_id
									  );
			
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
				THEN 
				LN_TOTAL_RCPT_AMT:=LN_TOTAL_RCPT_AMT+J.PARTY_AMT;
				COMMIT; 
			END IF;
			
			EXCEPTION
				WHEN OTHERS THEN
				
					IF LN_INT_RCPT_NO >0
					THEN 
						LN_INT_RCPT_NO:= LN_INT_RCPT_NO-1;
					ELSE
						LN_INT_RCPT_NO:=0;
					END IF;
					DBMS_OUTPUT.PUT_LINE('Error in PARAMETERISED CURSOR: '||SQLCODE||' - '||SQLERRM);
			END;
		END LOOP;
		-- Call AR Receipt API for different customers under same bank TO CREATE COMBINED RECEIPT
		AR_RECEIPT_API_PUB.CREATE_MISC
									   ( p_api_version => 1.0,
										 p_init_msg_list => FND_API.G_TRUE,
										 p_commit => FND_API.G_TRUE,
										 p_validation_level => FND_API.G_VALID_LEVEL_FULL,
										 x_return_status => l_return_status,
										 x_msg_count => l_msg_count,
										 x_msg_data => l_msg_data,
										 p_amount => LN_TOTAL_RCPT_AMT, 				-- AMOUNT ?
										 p_receipt_date => TRUNC(SYSDATE),	-- WHAT SHOULD BE THE RECEIPT DATE
										 p_gl_date => TRUNC(SYSDATE),	  	-- WHAT SHOULD BE THE GL_DATE
										 p_receipt_method_id => 1004,	  	-- (SELECT RECEIPT_METHOD_ID FROM ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT WHERE CONS_RCPT_NO = 12;)
										 p_activity => NULL,
                                         p_receivables_trx_id => ln_receivables_trx_id, 	
										 p_misc_receipt_id => l_cash_receipt_id ,
										 p_attribute_rec => l_attribute_rec,
										 p_receipt_number => l_cash_receipt_NUM);
			
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
				THEN 
				COMMIT; 
			END IF;
			DBMS_OUTPUT.PUT_LINE('l_cash_receipt_id : '||l_cash_receipt_id);
		LN_INT_RCPT_NO:=0;
		LN_TOTAL_RCPT_AMT:=0;
	END LOOP;
EXCEPTION
WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE('Error in MAIN CURSOR: '||SQLCODE||' - '||SQLERRM);
END;