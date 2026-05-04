DECLARE
   l_return_status   varchar2 (1);
   l_msg_count       number;
   l_msg_data        varchar2 (240);
   l_count           number;
   l_msg_data_out    varchar2 (240);
   l_mesg            varchar2 (240);
   p_count           number;
   l_Rec_num         varchar2 (100);
   l_trx_num         varchar2 (100);
BEGIN
/* To use this API we need the TRX_Number created with the same receipt method and customer;
 and also the status should be completed and we should have the amount in Balance due region 
 for the following trx number 7668490213
 1. created this invoice with same receipt method
 2. created it's line for amount
 3. completed it's status.
 4. now can run this API
 */

    BEGIN 
        MO_GLOBAL.SET_POLICY_CONTEXT ('S', 82);   
        FND_GLOBAL.APPS_INITIALIZE(1337,20678,222); 
    END; 

   AR_RECEIPT_API_PUB.APPLY (
      p_api_version        => 1.0,
      p_init_msg_list      => FND_API.G_TRUE,
      p_commit             => FND_API.G_TRUE,
      p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
      p_cash_receipt_id    => 463623,--- <CASH RECEIPT ID >
      p_customer_Trx_id    => 845882, ----<CUSTOMER TRX ID> 
      p_org_id             => 82, --<ORG_ID>>
--      p_installment        => 1, -- INSTALLMENT NUMBER  
      p_amount_applied     => 40,
      x_return_status      => l_return_status,
      x_msg_count          => l_msg_count,
      x_msg_data           => l_msg_data
   );
   DBMS_OUTPUT.put_line ('Status ' || l_return_status);
   DBMS_OUTPUT.put_line ('Message count ' || l_msg_count);

   IF l_msg_count = 1
   THEN
      DBMS_OUTPUT.put_line ('l_msg_data ' || l_msg_data);
   ELSIF l_msg_count > 1
   THEN
      LOOP
         p_count := p_count + 1;
         l_msg_data := FND_MSG_PUB.Get (FND_MSG_PUB.G_NEXT, FND_API.G_FALSE);

         IF l_msg_data IS NULL
         THEN
            EXIT;
         END IF;

         DBMS_OUTPUT.put_line ('Message' || p_count || '.' || l_msg_data);
      END LOOP;
   END IF;
END;