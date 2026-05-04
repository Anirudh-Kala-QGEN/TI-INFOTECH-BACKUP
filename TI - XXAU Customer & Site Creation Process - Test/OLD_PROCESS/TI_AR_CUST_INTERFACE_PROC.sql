CREATE OR REPLACE PROCEDURE AUCUSTOM.TI_AR_CUST_INTERFACE_PROC (
    P_ORG_ID   IN     NUMBER,
    retcode       OUT VARCHAR2,
    errbuf        OUT VARCHAR2)
IS
    L_ERR_MSG         VARCHAR2 (500);
    L_ORIG_CUST_REF   VARCHAR2 (30);
    l_cust_unit       NUMBER (10);
    L_ORIG_ADDR_REF   VARCHAR2 (30);
    L_SITE_CODE       VARCHAR2 (30);
    L_CUST_STATUS     VARCHAR2 (30);
    L_CUST_TYPE       VARCHAR2 (30);
    L_ADDR1           VARCHAR2 (500);
    L_CUST_CATEGORY   VARCHAR2 (30);
    L_CUST_CLASS      VARCHAR2 (30);
--    v_ddl             VARCHAR2 (100)         := 'ALTER SESSION SET ISOLATION_LEVEL = READ COMMITTED';
    EXCP              EXCEPTION;
    ncustomer_id      NUMBER (10);
    nShip_to          NUMBER (10);
    nERP_number       NUMBER (10);
    nParty_id         NUMBER (10);


    CURSOR DIST_CUST IS

--        SELECT DISTINCT A.AGENCY_ID
--          FROM aucustom.xxau_agency_approval_detials A
--         where trunc (CREATION_DATE) >= '01-OCT-2024'
--AND APPROVE_REJECT = 'A'
--AND AGREEMENT_FLAG IS NOT NULL
----AND ERP_CUSTOMER_NUMBER IS NULL
----                AND A.AGENCY_ID IN (7379390)
--               AND NOT EXISTS (SELECT (1) FROM AR_CUSTOMERS@HRTOEBS B WHERE B.CUSTOMER_NUMBER = A.ERP_CUSTOMER_NUMBER )
--               AND NOT EXISTS  (SELECT (1) FROM RA_CUSTOMERS_INTERFACE_ALL@HRTOEBS B WHERE B.CUSTOMER_ATTRIBUTE15 = A.AGENCY_ID )       
SELECT * FROM
au_customer_master_new a
WHERE AGENCY_ID  IN (select AGENCY_ID 
                    from 
                    aucustom.xxau_agency_approval_detials 
                    where trunc(creation_date) >='01-OCT-2024'
                    AND APPROVE_REJECT = 'A'
                    AND AGREEMENT_FLAG = 'Y')
--and PROUCT_NAME = 'Amar Ujala'
AND ERP_CUSTOMER_NUMBER IS NULL
--           AND A.AGENCY_ID IN ()
AND NOT EXISTS (SELECT (1) FROM AR_CUSTOMERS@HRTOEBS B WHERE B.CUSTOMER_NUMBER = A.ERP_CUSTOMER_NUMBER )
AND NOT EXISTS  (SELECT (1) FROM RA_CUSTOMERS_INTERFACE_ALL@HRTOEBS B WHERE B.CUSTOMER_ATTRIBUTE15 = A.AGENCY_ID )
AND NOT EXISTS (SELECT (1) FROM R11_RA_CUSTOMERS B WHERE B.ATTRIBUTE15 = A.AGENCY_ID) ;



    CURSOR CUST_ADDR (P_CUST_CODE VARCHAR2)
    IS
     SELECT A.INV_ORG,
               A.AGENCY_NAME,
               A.AGENCY_ID,
               A.AGENCY_CATEGORY,
               A.AGENCY_ACCOUNT_TYPE,
               A.AGENCY_AREA_TYPE,
               A.AGREEMENT_START_DATE,
               A.AGREEMENT_END_DATE,
               A.DATE_OF_BIRTH,
               A.AGE,
               A.PAYMENT_TERM,
               A.RENEWAL_START_DATE,
               A.RENEWAL_END_DATE,
               A.EXCLUSIVE_NON_EXCLUSIVE,
               A.NAME_OF_STALL,
               A.SALE_THROUGH,
               A.NO_OF_HOWKERS,
               A.NAME_OF_NEWPAPER,
               A.SUPPLY,
               A.DROP_POINT,
               A.NEW_AGENCY_OPN_RSN,
               A.REPLACE_AGENCY_NAME,
               A.REPLACE_AGENCY_REASON,
               A.CLOSE_DATE,
               A.SUB_AGENCY_NAME,
               A.CONTROL_BY,
               A.ATTRIBUTE1,
               A.ATTRIBUTE2,
               A.ATTRIBUTE3,
               A.ATTRIBUTE4,
               A.ATTRIBUTE5,
               A.CREATION_DATE,
               A.CREATED_BY,
               A.LAST_UPDATE_DATE,
               A.LAST_UPDATED_BY,
               A.ORG_ID,
               A.EFFECTIVE_START_DATE,
               A.EFFECTIVE_END_DATE,
               A.OBJECT_VERSION,
               A.ACTIVE_FLAG,
               A.CUSTOMER_TYPE_NUMBER,
               A.ERP_PROCESS_FLAG,
               A.APPROVE_FLAG,
               A.ERP_CUSTOMER_ID,
               B.ERP_SITE_USE_ID,
               A.ERP_PARTY_ID,
               A.ERP_CUSTOMER_NUMBER,
               A.EMPLOYEE_ID,
               A.AGREEMENT_FLAG,
               B.CENTRE_NUMBER,
               B.ADDRESS,
               B.STATE,
               B.DISTRICT,
               B.CITY,
               B.MOBILE_NO,
               B.POSTAL_CODE,
               B.EMAIL,
               B.PAN,
               b.NAME_OF_CENTRE LOCATION1, 
                1 abc_type,
               DECODE (tt.prouct_name,
                       'Amar Ujala - Variant', 'Circulation Customers',
                       'Amar Ujala', 'Circulation Customers',
                       'Amar Ujala - Udaan', 'Udaan Customers',
                       'Amar Ujala - Safalta', 'NEW SAFALTA CUSTOMERS')
                   customer_type,
                  tt4.organization_code
               || '.9999.'
               || tt4.organization_code
               || '.102.205110.'
               || B.dak_code
               || '.999.999.999.999'
                   rec_account,
                   (SELECT code_combination_id
						FROM apps.gl_code_combinations_kfv@hrtoebs x
						WHERE x.concatenated_segments in (tt4.organization_code
									   || '.9999.'
									   || tt4.organization_code
									   || '.102.205110.'
									   || B.dak_code
									   || '.999.999.999.999')
						) ccd
				FROM 
				aucustom.xxau_agency_approval_detials  tt,
				au_customer_ship_to                    B,
				au_customer_master_new                 A,
				aucustom.xxau_inv_organization         tt4
				 WHERE TRUNC(TT.CREATION_DATE) >= DATE '2024-10-01'
				   AND NVL(TT.APPROVE_REJECT, 'N') = 'A'
				   AND NVL(TT.AGREEMENT_FLAG, 'N') = 'Y'
				   AND TT.AGENCY_ID = B.AGENCY_ID
				   AND TT.INV_ORG = B.INV_ORG
				   AND TT.CENTRE_NUMBER = B.CENTRE_NUMBER
				   AND TT.ERP_CUSTOMER_NUMBER IS NULL
				   AND A.AGENCY_ID = B.AGENCY_ID
				   AND A.INV_ORG = B.INV_ORG
				   AND A.ACTIVE_FLAG = 'Y'
				   AND A.AGENCY_ID IS NOT NULL
				   AND B.INV_ORG = tt4.inv_org_id
				   AND SYSDATE BETWEEN B.EFFECTIVE_START_DATE AND B.EFFECTIVE_END_DATE
				AND NVL(B.PRIMARY_FLAG, 'N') = 'Y'
				AND B.AGENCY_ID = P_CUST_CODE
;
   
BEGIN
--    EXECUTE IMMEDIATE (v_ddl);

    FOR C1 IN DIST_CUST
    LOOP
        BEGIN
            SELECT TO_CHAR (TI_AR_CUSTOMERS_S.NEXTVAL)
              INTO L_ORIG_CUST_REF
              FROM DUAL;

            FOR C2 IN CUST_ADDR (C1.AGENCY_ID)
            LOOP
                BEGIN
                    /* ---  CHECKING THAT THE 'PARTY_SITE_USE_CODE' IS EXIST IN FND_LOOKUP_VALUES          */
                    BEGIN
                        SELECT DISTINCT unit, customer_type
                          INTO l_cust_unit, L_CUST_CLASS
                          FROM aucustom.xxau_customer_details       --@ebstohr
                         WHERE     
                         NVL (process_flag, 'N') = 'N'
                               AND 
                               agency_id = C1.agency_id;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            L_ERR_MSG :=
                                'CUSTOMER TYPE IS NOT AVAILABLE FOR :';
					dbms_output.put_line('Error While creating table'||'-'||'-'||sqlerrm);
                    END;

                    /*  CHECKING FOR THE ADDRESS LINE1                                              */
                    BEGIN
                        SELECT    C2.ADDRESS
                               || ', '
                               || C2.STATE
                               || ', '
                               || C2.POSTAL_CODE                 --C2.ADDRESS1
                          INTO L_ADDR1
                          FROM DUAL;

                        IF L_ADDR1 IS NULL
                        THEN
                            L_ADDR1 := '.';
                        END IF;
                    END;

                    /*  CHECKING FOR THE CUSTOMER CLASS CODE                                        */
                    BEGIN
                        SELECT DISTINCT unit, customer_type
                          INTO l_cust_unit, L_CUST_CLASS
                          FROM aucustom.xxau_customer_details       --@ebstohr
                         WHERE     
                         NVL (process_flag, 'N') = 'N'
                               AND 
                               agency_id = C1.agency_id;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            L_ERR_MSG :=
                                   'CUSTOMER TYPE IS NOT AVAILABLE FOR :'
                                || C2.AGENCY_CATEGORY;

					dbms_output.put_line('Error While creating table - 2'||'-'||'-'||sqlerrm);
                    END;

                    BEGIN
                        SELECT TO_CHAR (TI_AR_CUST_ADDRESSES_S.NEXTVAL)
                          INTO L_ORIG_ADDR_REF
                          FROM DUAL;
                    END;

                    BEGIN
                        INSERT INTO RA_CUSTOMERS_INTERFACE_ALL@hrtoebs (
                                        orig_system_customer_ref,
                                        customer_name,
                                        orig_system_address_ref,
                                        address1,
                                        address2,
                                        address3,
                                        address4,
                                        --LOCATION,
                                        city,
                                        county,
                                        state,
                                        province,
                                        country,
                                        postal_code,
                                        site_use_code,
                                        primary_site_use_flag,
                                        customer_status,
                                        insert_update_flag,
                                        last_updated_by,
                                        last_update_date,
                                        created_by,
                                        creation_date,
                                        CUSTOMER_ATTRIBUTE14,
                                        CUSTOMER_ATTRIBUTE15, --attribute19, --customer_number,
                                        customer_name_phonetic,
                                        customer_category_code,
                                        location,
                                        org_id,
                                        CUSTOMER_TYPE,
                                        CUSTOMER_ATTRIBUTE_CATEGORY, --ATTRIBUTE_CATEGORY, --'Circulation Customers'
                                        CUSTOMER_ATTRIBUTE1,      --ATTRIBUTE10
                                        CUSTOMER_ATTRIBUTE10,
                                        CUSTOMER_ATTRIBUTE11
                                        , gl_id_rec
                                                           )
                                 VALUES (
                                            L_ORIG_CUST_REF,
                                            C2.AGENCY_NAME,
                                            L_ORIG_ADDR_REF,
                                            NVL (
                                                   C2.ADDRESS
                                                || ', '
                                                || C2.STATE
                                                || ', '
                                                || C2.POSTAL_CODE,
                                                'N/A'),
                                            NULL,
                                            NULL,
                                            NULL,
                                            C2.CITY,
                                            C2.DISTRICT,--NVL ('IN', 'US'),--COUNTY
                                            C2.STATE,
                                            NULL,
                                            NVL ('IN', 'US'),
                                            NULL,
                                            'BILL_TO',
                                            'Y',
                                            'A',
                                            'I',
                                            -1,
                                            SYSDATE,
                                            -1,
                                            SYSDATE,
                                            c2.CENTRE_NUMBER,
                                            C2.AGENCY_ID,
                                            C2.AGENCY_NAME,
                                            'CUSTOMER',
                                            C2.LOCATION1,
                                            288,
                                            'R',
                                            C2.customer_type,
                                            C2.abc_type,
                                            C2.abc_type,
                                            C2.AGENCY_ID,
                                            c2.ccd);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            L_ERR_MSG :=
                                   'CUSTOMER TYPE IS NOT AVAILABLE FOR :'
                                || C2.AGENCY_CATEGORY;
                            dbms_output.put_line('Error While creating table'||'-'||'-'||sqlerrm);
                    END;


                    INSERT INTO ar.ra_customer_profiles_int_all@hrtoebs (
                                    orig_system_customer_ref,
                                    insert_update_flag,
                                    customer_profile_class_name,
                                    credit_hold,
                                    last_updated_by,
                                    last_update_date,
                                    created_by,
                                    creation_date,
                                    org_id)
                         VALUES (L_ORIG_CUST_REF,  -- orig_system_customer_ref
                                 'I',                    -- insert_update_flag
                                 'DEFAULT',   -- Should be valid profile class
                                 'N',         -- This can be 'Y','N' not null.
                                 -1,                        -- last_updated_by
                                 SYSDATE,                  -- last_update_date
                                 -1,                             -- created_by
                                 SYSDATE,                        -- created_by
                                 288                                 -- org_id
                                    );

                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            L_ERR_MSG :=
                                   'CUSTOMER TYPE IS NOT AVAILABLE FOR :'
                                || C2.AGENCY_CATEGORY;
                            dbms_output.put_line('Error While creating table'||'-'||'-'||sqlerrm);
                    END;

            END LOOP;

        EXCEPTION
            WHEN EXCP
            THEN
                ROLLBACK;
            WHEN OTHERS
            THEN
                ROLLBACK;
                L_ERR_MSG := SUBSTR (SQLERRM, 1, 500);
                --FND_FILE.PUT_LINE(FND_FILE.LOG, L_ERR_MSG);
                DBMS_OUTPUT.PUT_LINE (SQLERRM);
        END;

    END LOOP;

END;
/
