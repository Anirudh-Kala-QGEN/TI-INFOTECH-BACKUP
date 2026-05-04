CREATE OR REPLACE PROCEDURE AUCUSTOM.TI_AR_CUST_INTERFACE_PROC_S (
    P_ORG_ID   IN     NUMBER,
    retcode       OUT VARCHAR2,
    errbuf        OUT VARCHAR2
)
IS
    L_ERR_MSG       VARCHAR2(500);
    v_ddl           VARCHAR2(100) := 'ALTER SESSION SET ISOLATION_LEVEL = READ COMMITTED';

    CURSOR DIST_CUST IS
        SELECT DISTINCT CUSTOMER_ID,
                        --                C.CUST_ACCT_SITE_ID ,
                        --                hcaa.ORIG_SYSTEM_REFERENCE,
--                        d.ORIG_SYSTEM_REFERENCE     ERP_SITE_USE_ID,
                (D.SITE_USE_ID) ERP_SITE_USE_ID, 
                        --                hcaa.cust_account_id,
                        AC.CUSTOMER_NUMBER,
                        hps.party_id,
                        ac.attribute14,
                        ac.attribute15
          --            --                , C.CREATION_DATE
          FROM AR_CUSTOMERS@hrtoebs            AC,
               HZ_PARTY_SITES@hrtoebs          HPS,
               HZ_CUST_ACCOUNTS_ALL@hrtoebs    HCAA,
               hz_cust_acct_sites_all@hrtoebs  c,
               hz_cust_site_uses_all@hrtoebs   d
         WHERE     ACCOUNT_NUMBER = CUSTOMER_NUMBER
               AND hps.party_id = hcaa.party_id
               AND hcaa.cust_account_id = c.cust_account_id
               AND c.cust_acct_site_id = d.cust_acct_site_id
               AND C.STATUS = 'A'
               AND d.site_use_code = 'BILL_TO'
--               AND ac.ATTRIBUTE15 IN  (7536846, 7535095, 7535896, 7536715)
               AND TRUNC(C.CREATION_DATE) = TRUNC(SYSDATE) 
                               --c2.agency_id                   --7200334
                                           --               and ac.ATTRIBUTE14 =
                                           --               and CUSTOMER_ID= 6122482'
                                           --               and AC.CUSTOMER_NUMBER in (157502)
                                           --               and customer_id = '6122482'
                                           --        ORDER BY C.CREATION_DATE DESC
                                           ;

BEGIN
    -- Set session isolation level
    EXECUTE IMMEDIATE v_ddl;

    -- Disable triggers once before the loop
    EXECUTE IMMEDIATE 'ALTER TRIGGER AU_CUSTOMER_SHIP_TO_TRG DISABLE';
    EXECUTE IMMEDIATE 'ALTER TRIGGER CUSTOMER_SHIP_ID_TRIG DISABLE';
    EXECUTE IMMEDIATE 'ALTER TRIGGER CUSTOMER_SHIP_TO_HIS_TRIG DISABLE';

    FOR C1 IN DIST_CUST LOOP
        BEGIN
            -- Update au_customer_master_new
            UPDATE au_customer_master_new
               SET ERP_PROCESS_FLAG = 'Y',
                   APPROVE_FLAG = 'Y',
                   ERP_CUSTOMER_ID = C1.CUSTOMER_ID,
                   ERP_PARTY_ID = C1.PARTY_ID,
                   ERP_CUSTOMER_NUMBER = C1.CUSTOMER_NUMBER
             WHERE agency_id = C1.ATTRIBUTE15
               AND (ERP_CUSTOMER_NUMBER IS NULL OR ERP_PARTY_ID IS NULL);
        EXCEPTION
            WHEN OTHERS THEN
                L_ERR_MSG := 'Error updating au_customer_master_new: ' || SQLERRM;
                errbuf := L_ERR_MSG;
        END;

COMMIT;

        BEGIN
            -- Update au_customer_ship_to
            UPDATE au_customer_ship_to
               SET ERP_PROCESS_FLAG = 'Y',
                   APPROVE_FLAG = 'Y',
                   ERP_CUSTOMER_ID = C1.CUSTOMER_ID,
                   ERP_PARTY_ID = C1.PARTY_ID,
                   ERP_CUSTOMER_NUMBER = C1.CUSTOMER_NUMBER,
                   ERP_SITE_USE_ID = C1.ERP_SITE_USE_ID,
                   ERP_CREATION_DATE = TRUNC(SYSDATE)
             WHERE agency_id = C1.ATTRIBUTE15
               AND centre_number = C1.ATTRIBUTE14
               AND ERP_CUSTOMER_NUMBER IS NULL;
        EXCEPTION
            WHEN OTHERS THEN
                L_ERR_MSG := 'Error updating au_customer_ship_to: ' || SQLERRM;
                errbuf := L_ERR_MSG;
        END;
        
        COMMIT;
        
    END LOOP;

    COMMIT;

    -- Call next process step
    BEGIN
    AUCUSTOM.TI_AR_CUST_INTERFACE_PROC_SS(
        P_ORG_ID => 288,
        retcode  => retcode,
        errbuf   => errbuf
    );
EXCEPTION
    WHEN OTHERS THEN
        errbuf := 'Error calling TI_AR_CUST_INTERFACE_PROC_SS: ' || SQLERRM;
        retcode := '1';
END;

COMMIT;

 BEGIN
    AUCUSTOM.TI_AR_CUST_INTERFACE_PROC_SSS(
        P_ORG_ID => 288,
        retcode  => retcode,
        errbuf   => errbuf
    );
    
EXCEPTION
    WHEN OTHERS THEN
        errbuf := 'Error calling TI_AR_CUST_INTERFACE_PROC_SSS: ' || SQLERRM;
        retcode := '1';
END;

COMMIT;

BEGIN
    AUCUSTOM.TI_AR_CUST_INTER_PROC_UPDT(
        P_ORG_ID => 288,
        retcode  => retcode,
        errbuf   => errbuf
    );
    
EXCEPTION
    WHEN OTHERS THEN
        errbuf := 'Error calling TI_AR_CUST_INTER_PROC_UPDT: ' || SQLERRM;
        retcode := '1';
END;

COMMIT;


    -- Set return code
    retcode := '0'; -- success
EXCEPTION
    WHEN OTHERS THEN
        retcode := '1';
        errbuf := 'Unhandled error in TI_AR_CUST_INTERFACE_PROC_S: ' || SQLERRM;
        
            -- Enable triggers after processing
    EXECUTE IMMEDIATE 'ALTER TRIGGER AU_CUSTOMER_SHIP_TO_TRG ENABLE';
    EXECUTE IMMEDIATE 'ALTER TRIGGER CUSTOMER_SHIP_ID_TRIG ENABLE';
    EXECUTE IMMEDIATE 'ALTER TRIGGER CUSTOMER_SHIP_TO_HIS_TRIG ENABLE';

    COMMIT;
    
END;
/
