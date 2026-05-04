DECLARE
   P_API_VERSION                    NUMBER;
   P_INIT_MSG_LIST                  VARCHAR2 (200);
   P_COMMIT                         VARCHAR2 (200);
   P_VALIDATION_LEVEL               NUMBER;
   X_RETURN_STATUS                  VARCHAR2 (200);
   X_MSG_COUNT                      NUMBER;
   X_MSG_DATA                       VARCHAR2 (200);
   P_CASH_RECEIPT_ID                AR_CASH_RECEIPTS.CASH_RECEIPT_ID%TYPE;
   P_RECEIPT_NUMBER                 AR_CASH_RECEIPTS.RECEIPT_NUMBER%TYPE;
   P_AMOUNT_APPLIED                 AR_RECEIVABLE_APPLICATIONS.AMOUNT_APPLIED%TYPE;
   P_APPLY_DATE                     AR_RECEIVABLE_APPLICATIONS.APPLY_DATE%TYPE;
   P_APPLY_GL_DATE                  AR_RECEIVABLE_APPLICATIONS.GL_DATE%TYPE;
   P_USSGL_TRANSACTION_CODE         AR_RECEIVABLE_APPLICATIONS.USSGL_TRANSACTION_CODE%TYPE;
   P_ATTRIBUTE_REC                  AR_RECEIPT_API_PUB.ATTRIBUTE_REC_TYPE;
   P_GLOBAL_ATTRIBUTE_REC           AR_RECEIPT_API_PUB.GLOBAL_ATTRIBUTE_REC_TYPE;
   P_COMMENTS                       AR_RECEIVABLE_APPLICATIONS.COMMENTS%TYPE;
   P_APPLICATION_REF_NUM            AR_RECEIVABLE_APPLICATIONS.APPLICATION_REF_NUM%TYPE;
   P_SECONDARY_APPLICATION_REF_ID   AR_RECEIVABLE_APPLICATIONS.SECONDARY_APPLICATION_REF_ID%TYPE;
   P_CUSTOMER_REFERENCE             AR_RECEIVABLE_APPLICATIONS.CUSTOMER_REFERENCE%TYPE;
   P_CALLED_FROM                    VARCHAR2 (200);
   P_CUSTOMER_REASON                AR_RECEIVABLE_APPLICATIONS.CUSTOMER_REASON%TYPE;
   P_SECONDARY_APP_REF_TYPE         AR_RECEIVABLE_APPLICATIONS.SECONDARY_APPLICATION_REF_TYPE%TYPE;
   P_SECONDARY_APP_REF_NUM          AR_RECEIVABLE_APPLICATIONS.SECONDARY_APPLICATION_REF_NUM%TYPE;
   P_ORG_ID NUMBER := 82;
BEGIN
	BEGIN 
        MO_GLOBAL.SET_POLICY_CONTEXT('S',82);
        FND_GLOBAL.APPS_INITIALIZE(1337,20678,222); 
    END;
   ---- P_RECEIPT_NUMBER := '909RR9';
   P_CASH_RECEIPT_ID := 463622; ----<CASH RECEIPT ID >
   P_AMOUNT_APPLIED := 20;  ------<AMOUNT NEEDS TO ON ACCOUNTED>
   P_APPLY_DATE := TRUNC (SYSDATE);
   P_APPLY_GL_DATE := TRUNC (SYSDATE);

   AR_RECEIPT_API_PUB.APPLY_ON_ACCOUNT (
      P_API_VERSION                    => 1.0,
      P_INIT_MSG_LIST                  => FND_API.G_FALSE,
      P_COMMIT                         => FND_API.G_FALSE,
      P_VALIDATION_LEVEL               => FND_API.G_VALID_LEVEL_FULL,
      X_RETURN_STATUS                  => X_RETURN_STATUS,
      X_MSG_COUNT                      => X_MSG_COUNT,
      X_MSG_DATA                       => X_MSG_DATA,
      P_CASH_RECEIPT_ID                => P_CASH_RECEIPT_ID,
      P_RECEIPT_NUMBER                 => P_RECEIPT_NUMBER,
      P_AMOUNT_APPLIED                 => P_AMOUNT_APPLIED,
      P_APPLY_DATE                     => P_APPLY_DATE,
      P_APPLY_GL_DATE                  => P_APPLY_GL_DATE,
      P_ORG_ID                         => P_ORG_ID, ------ <ORG ID >
      P_USSGL_TRANSACTION_CODE         => P_USSGL_TRANSACTION_CODE,
      P_ATTRIBUTE_REC                  => P_ATTRIBUTE_REC,
      P_GLOBAL_ATTRIBUTE_REC           => P_GLOBAL_ATTRIBUTE_REC,
      P_COMMENTS                       => P_COMMENTS,
      P_APPLICATION_REF_NUM            => P_APPLICATION_REF_NUM,
      P_SECONDARY_APPLICATION_REF_ID   => P_SECONDARY_APPLICATION_REF_ID,
      P_CUSTOMER_REFERENCE             => P_CUSTOMER_REFERENCE,
      P_CALLED_FROM                    => P_CALLED_FROM,
      P_CUSTOMER_REASON                => P_CUSTOMER_REASON,
      P_SECONDARY_APP_REF_TYPE         => P_SECONDARY_APP_REF_TYPE,
      P_SECONDARY_APP_REF_NUM          => P_SECONDARY_APP_REF_NUM
   );

   IF (X_RETURN_STATUS = 'S')
   THEN
      COMMIT;

      DBMS_OUTPUT.PUT_LINE ('SUCCESS');
      DBMS_OUTPUT.PUT_LINE (
         'RETURN STATUS            = ' || SUBSTR (X_RETURN_STATUS, 1, 255)
      );
      DBMS_OUTPUT.PUT_LINE ('MESSAGE COUNT             = ' || X_MSG_COUNT);
      DBMS_OUTPUT.PUT_LINE ('MESSAGE DATA            = ' || X_MSG_DATA);
   ELSE
      ROLLBACK;

      DBMS_OUTPUT.PUT_LINE (
         'RETURN STATUS    = ' || SUBSTR (X_RETURN_STATUS, 1, 255)
      );
      DBMS_OUTPUT.PUT_LINE ('MESSAGE COUNT     = ' || TO_CHAR (X_MSG_COUNT));
      DBMS_OUTPUT.PUT_LINE (
         'MESSAGE DATA    = ' || SUBSTR (X_MSG_DATA, 1, 255)
      );
      DBMS_OUTPUT.PUT_LINE(APPS.FND_MSG_PUB.GET (
                              P_MSG_INDEX   => APPS.FND_MSG_PUB.G_LAST,
                              P_ENCODED     => APPS.FND_API.G_FALSE
                           ));

      IF X_MSG_COUNT >= 0
      THEN
         FOR I IN 1 .. 10
         LOOP
            DBMS_OUTPUT.PUT_LINE(I || '. '
                                 || SUBSTR (
                                       FND_MSG_PUB.GET (
                                          P_ENCODED   => FND_API.G_FALSE
                                       ),
                                       1,
                                       255
                                    ));
         END LOOP;
      END IF;
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.PUT_LINE ('EXCEPTION :' || SQLERRM);
END;