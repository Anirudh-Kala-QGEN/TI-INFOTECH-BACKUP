CURSOR CUSTOMER_CUR2 (
        P_CUST_NAME    VARCHAR2,
        P_UNIT         VARCHAR2,
        P_CUST_TYPE    VARCHAR2,
        P_ACCOUNT_DESC VARCHAR2
    ) IS
     SELECT DISTINCT
        CUSTOMER_NAME,
        UNIT,
        CUSTOMER_TYPE,
        CUSTOMER_CLASS CUSTOMER_CALSS_CODE,
        ADDRESS1,
        ADDRESS2,
        ADDRESS3,
        ADDRESS4,
        CITY,
        STATE,
        DECODE(
            UPPER(COUNTRY),
            'INDIA',
            'IN',
            UPPER(COUNTRY)
        )              COUNTRY,
        COUNTY,
        LOCATION1,
        STATION_NAME,
        PINCODE        POSTAL_CODE,
        'BILL_TO'      SITE_USE_CODE,
        DECODE(
            UPPER(PRIMARY_SITE_FALG),
            'YES',
            'Y',
            'N'
        )              PRIMARY_FLAG,
        'A'            STATUS,
        REC_ACCOUNT,
        PAYMENT_TERMS,
        CENTRE_NUMBER,
        AGENCY_ID
    FROM
        AUCUSTOM.XXAU_CUSTOMER_DETAILS@EBSTOHR T1
    WHERE
           (EXISTS (
       SELECT 1
       FROM AUCUSTOM.AU_CUSTOMER_SHIP_TO@EBSTOHR T2
       WHERE 1=1
         AND T2.AGENCY_ID = T1.AGENCY_ID
         AND T2.CENTRE_NUMBER = T1.CENTRE_NUMBER
         AND T2.ERP_SITE_USE_ID IS NULL
   )
   OR NVL(PROCESS_FLAG, 'N') = 'N')
        AND CUSTOMER_TYPE = P_CUST_TYPE
        AND UNIT = P_UNIT
        AND CUSTOMER_NAME = P_CUST_NAME
        AND ACCOUNT_DESCRIPTION = P_ACCOUNT_DESC;