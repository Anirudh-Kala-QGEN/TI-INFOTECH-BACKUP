/* FORMATTED ON 2026/01/16 14:59 (FORMATTER PLUS V4.8.8) */
DECLARE
   L_RETURN_STATUS      	VARCHAR2 (1);
   L_MSG_COUNT          	NUMBER;
   L_MSG_DATA           	VARCHAR2 (240);
   L_COUNT              	NUMBER;
   L_CASH_RECEIPT_ID    	NUMBER;
   L_MSG_DATA_OUT       	VARCHAR2 (240);
   L_MESG               	VARCHAR2 (240);
   LC_LOCATION          	VARCHAR2 (240);
   LC_RECEIPT_NUMBER    	VARCHAR2 (240);
   LC_CUSTOMER_NUMBER   	VARCHAR2 (240);
   LC_TRX_NUMBER        	VARCHAR2 (240);
   LC_CUSTOMER_ID       	VARCHAR2 (240);
   P_CUSTOMER_NAME      	VARCHAR2 (240);
   P_COUNT              	NUMBER;
   LN_AMOUNT            	NUMBER;
   L_CUSTOMER_TRX_ID    	NUMBER;
   P_ORG_ID             	NUMBER;
   GD_DATE              	DATE := SYSDATE;
   RD_RECEIPT_DATE 			DATE := SYSDATE;
   LN_RECEIPT_METHOD_ID 	NUMBER; 
   l_attribute_rec AR_RECEIPT_API_PUB.ATTRIBUTE_REC_TYPE;
BEGIN

    BEGIN 
        MO_GLOBAL.SET_POLICY_CONTEXT ('S', 82);   
        FND_GLOBAL.APPS_INITIALIZE(1337,20678,222); 
    END; 

   LN_AMOUNT := '50';
   LC_RECEIPT_NUMBER:='766849097';
   P_CUSTOMER_NAME := 'SUNSHINE ENTERPRISES';
   LC_CUSTOMER_ID := '136345'; 
   LC_CUSTOMER_NUMBER := '138455'; 
   LC_LOCATION := '131057';
   LC_TRX_NUMBER:='7668490213';
   L_CUSTOMER_TRX_ID := '845882';
   P_ORG_ID := '82';
   LN_RECEIPT_METHOD_ID := '1012';
   l_attribute_rec.ATTRIBUTE_CATEGORY := 'Misc';
   l_attribute_rec.ATTRIBUTE9 := 'AR_RECEIPT_API_PUB.CREATE_AND_APPLY';
   l_attribute_rec.ATTRIBUTE13 := TRUNC(SYSDATE);
   l_attribute_rec.ATTRIBUTE15 := 'MR'; 
-- Api start here
   AR_RECEIPT_API_PUB.CREATE_AND_APPLY
                           (P_API_VERSION            => 1.0,
                            P_INIT_MSG_LIST          => FND_API.G_TRUE,
                            P_COMMIT                 => FND_API.G_TRUE,
                            P_VALIDATION_LEVEL       => FND_API.G_VALID_LEVEL_FULL,
                            X_RETURN_STATUS          => L_RETURN_STATUS,
                            X_MSG_COUNT              => L_MSG_COUNT,
                            X_MSG_DATA               => L_MSG_DATA,
                            P_CURRENCY_CODE             => 'INR',
                            P_AMOUNT                 => LN_AMOUNT,
                            P_RECEIPT_NUMBER         => LC_RECEIPT_NUMBER,
                            P_RECEIPT_DATE           => RD_RECEIPT_DATE,
                            P_GL_DATE                => GD_DATE,
                            P_CUSTOMER_ID             => LC_CUSTOMER_ID,
                            --P_CUSTOMER_NUMBER        => LC_CUSTOMER_NUMBER,
                            P_LOCATION               => LC_LOCATION,
                            P_RECEIPT_METHOD_ID      => LN_RECEIPT_METHOD_ID,
                            P_TRX_NUMBER             => LC_TRX_NUMBER,
                            P_CR_ID                  => L_CASH_RECEIPT_ID,
                            P_ATTRIBUTE_REC          => L_ATTRIBUTE_REC,
                            P_ORG_ID                 => P_ORG_ID
                           );
   DBMS_OUTPUT.put_line ('Message count ' || l_msg_count);
   DBMS_OUTPUT.put_line ('Cash Receipt ID ' || l_cash_receipt_id);

   IF l_msg_count = 1
   THEN
      DBMS_OUTPUT.put_line ('l_msg_data ' || l_msg_data);
   ELSIF L_MSG_COUNT > 1
   THEN
      LOOP
         P_COUNT := P_COUNT + 1;
         L_MSG_DATA := FND_MSG_PUB.GET (FND_MSG_PUB.G_NEXT, FND_API.G_FALSE);

         IF L_MSG_DATA IS NULL
         THEN
            EXIT;
         END IF;

         DBMS_OUTPUT.put_line ('Message' || p_count || ' --- ' || l_msg_data);
      END LOOP;
   END IF;
END;