DECLARE
   p_api_version                 NUMBER;
   p_init_msg_list               VARCHAR2 (200);
   p_commit                      VARCHAR2 (200);
   p_validation_level            NUMBER;
   x_return_status               VARCHAR2 (200);
   x_msg_count                   NUMBER;
   x_msg_data                    VARCHAR2 (200);
   p_cash_receipt_id             NUMBER;
   p_pay_from_customer           NUMBER;
   p_comments                    VARCHAR2 (200);
   p_payment_trxn_extension_id   NUMBER;
   x_status                      VARCHAR2 (200);
   p_customer_bank_account_id    NUMBER;
   p_count                       NUMBER;
BEGIN
   p_api_version        := 1.0;
   p_init_msg_list      := fnd_api.g_true;
   p_commit             := fnd_api.g_false;
   p_validation_level   := fnd_api.g_valid_level_full;
   p_cash_receipt_id    := 12345;
   p_pay_from_customer  := 67890;
   p_comments           := 'TEST RECEIPT_API';
   
   AR_RECEIPT_UPDATE_API_PUB.UPDATE_RECEIPT_UNID_TO_UNAPP
          (p_api_version                    => p_api_version,
           p_init_msg_list                  => p_init_msg_list,
           p_commit                         => p_commit,
           p_validation_level               => p_validation_level,
           x_return_status                  => x_return_status,
           x_msg_count                      => x_msg_count,
           x_msg_data                       => x_msg_data,
           p_cash_receipt_id                => p_cash_receipt_id,
           p_pay_from_customer              => p_pay_from_customer,
           p_comments                       => p_comments,
           p_payment_trxn_extension_id      => p_payment_trxn_extension_id,
           x_status                         => x_status,
           p_customer_bank_account_id       => p_customer_bank_account_id
          );
   DBMS_OUTPUT.put_line ('X_RETURN_STATUS = ' || x_return_status);
   DBMS_OUTPUT.put_line ('X_MSG_COUNT = ' || x_msg_count);
   DBMS_OUTPUT.put_line ('X_MSG_DATA = ' || x_msg_data);
   DBMS_OUTPUT.put_line ('X_STATUS = ' || x_status);
   IF x_msg_count = 1
   THEN
      DBMS_OUTPUT.put_line ('l_msg_data ' || x_msg_data);
   ELSIF x_msg_count > 1
   THEN
      LOOP
         p_count := p_count + 1;
         x_msg_data := fnd_msg_pub.get (fnd_msg_pub.g_next, fnd_api.g_false);
         IF x_msg_data IS NULL
         THEN
            EXIT;
         END IF;
         DBMS_OUTPUT.put_line ('Message' || p_count || ' ---' || x_msg_data);
      END LOOP;
   END IF;
END;