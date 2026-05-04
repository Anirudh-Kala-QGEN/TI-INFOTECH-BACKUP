/* Formatted on 4/22/2026 11:31:36 AM (QP5 v5.365) */
CREATE OR REPLACE PROCEDURE AUAPIP.XXAU_INVOICE_UPLOAD_PROC_V
IS
    -- Local variables

    v_vendor_id                 NUMBER;

    v_vendor_site_id            NUMBER;

    v_invoice_id                NUMBER;

    in_tax_category_id          NUMBER;

    in_tax_rate_id              NUMBER;

    in_tax_type_id              NUMBER;

    in_liability_ccid           NUMBER;

    in_tax_rate_percentage      NUMBER;

    in_tax_rate_name            VARCHAR2 (80);

    IN_VENDOR_SITE_CODE         VARCHAR2 (10);

    in_TAX_ACCOUNT_ENTITY_ID    NUMBER;



    p_org_id                    NUMBER DEFAULT 386;

    p_set_books_id              NUMBER;

    ln_org_id                   NUMBER;

    ln_party_id                 NUMBER;

    ln_party_site_id            NUMBER;

    in_accd                     NUMBER;



    l_line_number               NUMBER;

    l_tax_line_number           NUMBER := 1;

    lv_tax_line_counter         NUMBER := 1;                -- ? DECLARED HERE



    v_user_id                   NUMBER := 2242;

    v_ap_line_id                NUMBER;



    ln_location_id              NUMBER;

    vcnt                        NUMBER := 0;



    ln_jai_interface_line_id    NUMBER;

    ln_jai_tax_line_id          NUMBER;



    v_code_combination_id_num   NUMBER;

    v_code_combination_concat   VARCHAR2 (4000);

    lv_tax_amount               NUMBER;

    -------------------------------------------------------------------------

    -- CGST/SGST/IGST Tax Cursor

    -------------------------------------------------------------------------

    CURSOR c_gst_taxes (p_taxcategory VARCHAR2, p_org_id NUMBER)
    IS
          SELECT tax_category_id,
                 rate_percentage,
                 tax_rate_name,
                 tax_rate_id,
                 tax_type_id,
                 tax_type_code,
                 RECOVERABLE_FLAG
            FROM ti_gst_tax_v@AUAPIPAPPSR12
           WHERE     UPPER (tax_category_name) = UPPER (p_taxcategory)
                 AND org_id = p_org_id
        ORDER BY rate_percentage;



    -------------------------------------------------------------------------

    -- HEADER CURSOR

    -------------------------------------------------------------------------

    CURSOR inv_data IS
          SELECT DISTINCT
                 B.INVOICENUMBER
                     AS INVOICE_NUMBER,
                 B.LEDGERID
                     AS LEDGER_ID,
                 B.PARTYNAME
                     AS PARTY_NAME,
                 B.VENDORSITECODE
                     AS VENDORSITECODE,
                 B.VENDORCODE
                     AS VENDOR_CODE,
                 B.GLDATE
                     AS GL_DATE,
                 NVL (B.INVOICEDATE, SYSDATE)
                     AS INVOICE_DATE,
                 B.CURRENCYCODE
                     AS INVOICE_CURRENCY_CODE,
                 B.CONVERSIONRATE
                     AS EXCHANGE_RATE,
                 B.UNIT
                     AS UNIT_CODE,
                 B.DEFAULT1
                     AS DEFAULT_1,
                 SUM (NVL (B.AMOUNT, 0))
                     AS INVOICE_AMOUNT,
                 (SELECT INVENTORY_ORGANIZATION_ID
                    FROM TI_AU_LOCATIONS_V@AUAPIPAPPSR12 L
                   WHERE     L.SET_OF_BOOKS_ID = B.LEDGERID
                         AND L.ORGANIZATION_CODE = TO_CHAR (B.UNIT))
                     AS LN_ORGANIZATION_ID,
                 (SELECT LOCATION_ID
                    FROM TI_AU_LOCATIONS_V@AUAPIPAPPSR12 L
                   WHERE     L.SET_OF_BOOKS_ID = B.LEDGERID
                         AND L.ORGANIZATION_CODE = TO_CHAR (B.UNIT))
                     AS LN_LOCATION_ID,
                 B.HSNCODE
                     AS HSN_CODE
            FROM API_INVOICES_PURC_V B
           WHERE     B.VENDORCODE IS NOT NULL
                 AND B.TAXCATEGORY IS NOT NULL
                 AND NOT EXISTS
                         (SELECT 1
                            FROM AP_INVOICES_ALL@AUAPIPAPPSR12 AIA
                           WHERE     AIA.INVOICE_NUM = B.INVOICENUMBER
                                 AND TRUNC (GL_DATE) >= '01-FEB-2026'
                                 AND AIA.VENDOR_ID IN
                                         (SELECT VENDOR_ID
                                            FROM PO_VENDORS@AUAPIPAPPSR12 POV
                                           WHERE POV.SEGMENT1 = B.VENDORCODE)) -- AND AIA.SOURCE = 'INVOICE GATEWAY')
                 AND NOT EXISTS
                         (SELECT 1
                            FROM AP_INVOICES_INTERFACE@AUAPIPAPPSR12
                           WHERE INVOICE_NUM = B.INVOICENUMBER)
                 AND NOT EXISTS
                         (SELECT 1
                            FROM AP_INVOICE_LINES_INTERFACE@AUAPIPAPPSR12
                           WHERE INVOICE_ID IN
                                     (SELECT INVOICE_ID
                                        FROM AP_INVOICES_INTERFACE@AUAPIPAPPSR12
                                       WHERE INVOICE_NUM = B.INVOICENUMBER))
                 AND NOT EXISTS
                         (SELECT 1
                            FROM JAI_INTERFACE_LINES_ALL@AUAPIPAPPSR12
                           WHERE     IMPORT_MODULE = 'AP'
                                 AND TRANSACTION_NUM = B.INVOICENUMBER)
                 AND NOT EXISTS
                         (SELECT 1
                            FROM JAI_INTERFACE_TAX_LINES_ALL@AUAPIPAPPSR12
                           WHERE     IMPORT_MODULE = 'AP'
                                 AND TRANSACTION_NUM = B.INVOICENUMBER)
                 AND EXISTS
                         (SELECT 1
                            FROM TI_VENDOR_DETAILS_V@AUAPIPAPPSR12 C ---VIEW FOR THIRD PARTY REGISTRATION VENDOR SITE---
                           WHERE     C.VENDOR_CODE = B.VENDORCODE
                                 AND C.UNIT = B.VENDORSITECODE
                                 AND C.SET_OF_BOOKS_ID = B.LEDGERID)
        --AND INVOICENUMBER IN ('MI/TI/24-25/0932')

        GROUP BY B.INVOICENUMBER,
                 B.PARTYNAME,
                 B.VENDORSITECODE,
                 B.VENDORCODE,
                 B.LEDGERID,
                 B.CURRENCYCODE,
                 B.UNIT,
                 B.GLDATE,
                 B.DEFAULT1,
                 B.HSNCODE,
                 B.CONVERSIONRATE,
                 NVL (B.INVOICEDATE, SYSDATE);

    -------------------------------------------------------------------------

    -- LINE CURSOR

    -------------------------------------------------------------------------

    CURSOR c_inv_line (p_inv_num IN VARCHAR2)
    IS
          SELECT B.AMOUNT,
                 B.DESCRIPTION,
                 NVL (B.GLDATE, SYSDATE)          AS GLDATE,
                 NVL (B.INVOICEDATE, SYSDATE)     INVOICE_DATE,
                 B.UNIT,
                 B.NATURALACCOUNT,
                 ROWNUM                           AS SEQ_NUM,
                 B.LOCATION,
                 B.DEPARTMENT,
                 B.FUTURE1,
                 B.FUTURE2,
                 B.FUTURE3,
                 B.FUTURE4,
                 B.BUSINESSTYPE,
                 B.TAXCATEGORY,
                 B.HSNCODE,
                 B.DEFAULT1,
                 B.TAXRATETAXAMOUNT,
                 B.TAXRECOVERABLEORNOT,
                 B.CONTEXTVALUE,
                 B.INVOICETAXTYPE
            FROM API_INVOICES_PURC_V B
           WHERE B.INVOICENUMBER = P_INV_NUM               -- '7186/CHD/25-26'
        ORDER BY B.AMOUNT;



    tot_tax_per                 NUMBER;

    totgst_amount               NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE ('=== CGST+SGST+IGST PROCESS STARTED ===');



    -------------------------------------------------------------------------

    -- INITIALIZE ENVIRONMENT

    -------------------------------------------------------------------------

    BEGIN
        SELECT set_of_books_id, organization_id
          INTO p_set_books_id, ln_org_id
          FROM hr_operating_units@AUAPIPAPPSR12
         WHERE organization_id = 386;



        DBMS_OUTPUT.PUT_LINE ('Operating Unit ID : ' || ln_org_id);

        DBMS_OUTPUT.PUT_LINE ('Set of Books ID   : ' || p_set_books_id);
    --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Operating Unit ID : ' || ln_org_id);

    --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Set of Books ID   : ' || p_set_books_id);



    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'ERROR: No operating unit found for org_id=386');
        --        FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR: No operating unit found for org_id=386');

        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE ('ERROR: ' || SQLERRM);
    --        FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR: ' || SQLERRM);

    END;



    -------------------------------------------------------------------------

    -- PROCESS EACH INVOICE

    -------------------------------------------------------------------------

    FOR rec_hdr IN inv_data
    LOOP
        BEGIN
            DBMS_OUTPUT.PUT_LINE ('Processing: ' || rec_hdr.invoice_number);



            -- Generate Invoice ID

            SELECT ap_invoices_interface_s.NEXTVAL@AUAPIPAPPSR12
              INTO v_invoice_id
              FROM DUAL;



            -- Vendor Lookup

            BEGIN
                SELECT VENDOR_ID, PARTY_ID
                  INTO V_VENDOR_ID, LN_PARTY_ID
                  FROM AP_SUPPLIERS@AUAPIPAPPSR12
                 WHERE SEGMENT1 = REC_HDR.VENDOR_CODE AND ENABLED_FLAG = 'Y';

                -- AND NVL(inactive_date, SYSDATE + 1) > SYSDATE

                -- AND ROWNUM = 1;



                -- Console debug

                DBMS_OUTPUT.PUT_LINE (
                    'Vendor Code  : ' || rec_hdr.vendor_code);

                DBMS_OUTPUT.PUT_LINE ('Vendor ID    : ' || v_vendor_id);

                DBMS_OUTPUT.PUT_LINE ('Party ID     : ' || ln_party_id);
            -- Concurrent Program log

            --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Vendor Code  : ' || rec_hdr.vendor_code);

            --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Vendor ID    : ' || v_vendor_id);

            --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Party ID     : ' || ln_party_id);



            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    DBMS_OUTPUT.PUT_LINE (
                           'ERROR: No active supplier found for vendor_code = '
                        || rec_hdr.vendor_code);
                --        FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR: No active supplier found for vendor_code = ' || rec_hdr.vendor_code);



                WHEN TOO_MANY_ROWS
                THEN
                    DBMS_OUTPUT.PUT_LINE (
                           'ERROR: Multiple suppliers found for vendor_code = '
                        || rec_hdr.vendor_code);
                --        FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR: Multiple suppliers found for vendor_code = ' || rec_hdr.vendor_code);



                WHEN OTHERS
                THEN
                    DBMS_OUTPUT.PUT_LINE ('ERROR: ' || SQLERRM);
            --        FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR: ' || SQLERRM);

            END;



            -- Vendor Site Lookup

            BEGIN
                SELECT VENDOR_SITE_ID,
                       PARTY_SITE_ID,
                       ACCTS_PAY_CODE_COMBINATION_ID,
                       VENDOR_SITE_CODE
                  INTO V_VENDOR_SITE_ID,
                       LN_PARTY_SITE_ID,
                       IN_ACCD,
                       IN_VENDOR_SITE_CODE
                  FROM AP_SUPPLIER_SITES_ALL@AUAPIPAPPSR12
                 WHERE     VENDOR_ID = V_VENDOR_ID
                       AND ACCTS_PAY_CODE_COMBINATION_ID IN
                               (SELECT CODE_COMBINATION_ID
                                  FROM GL_CODE_COMBINATIONS@AUAPIPAPPSR12
                                 WHERE SEGMENT1 = REC_HDR.VENDORSITECODE)
                       AND NVL (INACTIVE_DATE, SYSDATE + 1) > SYSDATE
                       -- AND vendor_site_code = rec_hdr.vendor_site_code

                       AND ORG_ID = LN_ORG_ID;



                -- Debug output

                DBMS_OUTPUT.PUT_LINE (
                    'Vendor ID            : ' || v_vendor_id);

                DBMS_OUTPUT.PUT_LINE ('Org ID               : ' || ln_org_id);

                DBMS_OUTPUT.PUT_LINE (
                    'Vendor Site ID       : ' || v_vendor_site_id);

                DBMS_OUTPUT.PUT_LINE (
                    'Party Site ID        : ' || ln_party_site_id);

                DBMS_OUTPUT.PUT_LINE ('AP CCID              : ' || in_accd);

                DBMS_OUTPUT.PUT_LINE (
                    'Vendor Site Code     : ' || in_vendor_site_code);
            -- Concurrent program log

            --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Vendor ID            : ' || v_vendor_id);

            --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Org ID               : ' || ln_org_id);

            --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Vendor Site ID       : ' || v_vendor_site_id);

            --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Party Site ID        : ' || ln_party_site_id);

            --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'AP CCID              : ' || in_accd);

            --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Vendor Site Code     : ' || in_vendor_site_code);



            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    v_vendor_site_id := NULL;

                    in_accd := NULL;



                    DBMS_OUTPUT.PUT_LINE (
                           'NO_DATA_FOUND: No active vendor site for Vendor ID='
                        || v_vendor_id
                        || ', Org ID='
                        || ln_org_id
                        || ', VendorSiteCode='
                        || rec_hdr.vendorsitecode);
                --        FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO_DATA_FOUND: No active vendor site for Vendor ID='|| v_vendor_id || ', Org ID=' || ln_org_id|| ', VendorSiteCode=' || rec_hdr.vendorsitecode);



                WHEN TOO_MANY_ROWS
                THEN
                    DBMS_OUTPUT.PUT_LINE (
                           'TOO_MANY_ROWS: Multiple vendor sites found for Vendor ID='
                        || v_vendor_id
                        || ', Org ID='
                        || ln_org_id
                        || ', VendorSiteCode='
                        || rec_hdr.vendorsitecode);
                --        FND_FILE.PUT_LINE(FND_FILE.LOG, 'TOO_MANY_ROWS: Multiple vendor sites found for Vendor ID=' || v_vendor_id || ', Org ID=' || ln_org_id|| ', VendorSiteCode=' || rec_hdr.vendorsitecode);



                WHEN OTHERS
                THEN
                    DBMS_OUTPUT.PUT_LINE ('ERROR: ' || SQLERRM);

                    --        FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR: ' || SQLERRM);

                    RAISE;
            END;



            -- Insert AP Header

            BEGIN
                INSERT INTO ap_invoices_interface@AUAPIPAPPSR12 (
                                invoice_id,
                                invoice_num,
                                invoice_amount,
                                invoice_currency_code,
                                gl_date,
                                source,
                                org_id,
                                invoice_type_lookup_code,
                                invoice_date,
                                vendor_id,
                                vendor_site_id,
                                description,
                                creation_date,
                                created_by,
                                last_updated_by,
                                last_update_date,
                                last_update_login,
                                calc_tax_during_import_flag,
                                reference_key1,
                                reference_key2,
                                reference_key3,
                                accts_pay_code_combination_id,
                                payment_method_lookup_code,
                                ATTRIBUTE15)
                     VALUES (v_invoice_id,
                             rec_hdr.invoice_number,
                             rec_hdr.invoice_amount,
                             NVL (rec_hdr.invoice_currency_code, 'INR'),
                             rec_hdr.gl_date,
                             'INVOICE GATEWAY',
                             ln_org_id,
                             'STANDARD',
                             REC_HDR.INVOICE_DATE,                   --SYSDATE
                             v_vendor_id,
                             v_vendor_site_id,
                             'CGST+SGST+IGST Import',
                             SYSDATE,
                             v_user_id,
                             v_user_id,
                             SYSDATE,
                             v_user_id,
                             'Y',
                             rec_hdr.invoice_number,
                             1,
                             'OFI TAX IMPORT',
                             in_accd,
                             'CHECK',
                             'AP_INDUS_API');



                -- Success logging (debug)

                DBMS_OUTPUT.PUT_LINE ('AP_INVOICES_INTERFACE INSERTED');

                DBMS_OUTPUT.PUT_LINE ('Invoice ID      : ' || v_invoice_id);

                DBMS_OUTPUT.PUT_LINE (
                    'Invoice Num     : ' || rec_hdr.invoice_number);

                DBMS_OUTPUT.PUT_LINE (
                    'Amount          : ' || rec_hdr.invoice_amount);

                DBMS_OUTPUT.PUT_LINE ('Vendor ID       : ' || v_vendor_id);

                DBMS_OUTPUT.PUT_LINE (
                    'Vendor Site ID  : ' || v_vendor_site_id);

                DBMS_OUTPUT.PUT_LINE ('Org ID          : ' || ln_org_id);
            -- Concurrent program log

            --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'AP_INVOICES_INTERFACE INSERTED');

            --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invoice ID      : ' || v_invoice_id);

            --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invoice Num     : ' || rec_hdr.invoice_number);

            --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Amount          : ' || rec_hdr.invoice_amount);

            --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Vendor ID       : ' || v_vendor_id);

            --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Vendor Site ID  : ' || v_vendor_site_id);

            --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Org ID          : ' || ln_org_id);



            EXCEPTION
                WHEN OTHERS
                THEN
                    DBMS_OUTPUT.PUT_LINE (
                        'INSERT FAILED (AP_INVOICES_INTERFACE)');

                    DBMS_OUTPUT.PUT_LINE (
                        'Invoice Num : ' || rec_hdr.invoice_number);

                    DBMS_OUTPUT.PUT_LINE ('ERROR       : ' || SQLERRM);



                    --        FND_FILE.PUT_LINE(FND_FILE.LOG, 'INSERT FAILED (AP_INVOICES_INTERFACE)');

                    --        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invoice Num : ' || rec_hdr.invoice_number);

                    --        FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR       : ' || SQLERRM);



                    RAISE;
            END;



            -------------------------------------------------------------------------

            -- LINE PROCESSING - CGST+SGST+IGST

            -------------------------------------------------------------------------

            l_line_number := 1;



            FOR rec_line IN c_inv_line (rec_hdr.invoice_number)
            LOOP
                -- Reset tax counter for each line

                lv_tax_line_counter := 1;                     -- ? FIXED SCOPE



                -- Code Combination

                v_code_combination_id_num := NULL;

                BEGIN
                    SELECT code_combination_id
                      INTO v_code_combination_id_num
                      FROM gl_code_combinations@AUAPIPAPPSR12
                     WHERE     NVL (segment1, '999') =
                               NVL (rec_line.unit, '999')
                           AND NVL (segment3, '999') =
                               NVL (rec_line.location, '999')
                           AND NVL (segment4, '99') =
                               NVL (rec_line.department, '99')
                           AND NVL (segment5, '999999') =
                               NVL (rec_line.naturalaccount, '999999')
                           AND NVL (segment9, '999') =
                               NVL (rec_line.DEFAULT1, '999')
                           AND NVL (segment8, '99') =
                               NVL (rec_line.businesstype, '99')
                           AND NVL (segment10, '99') =
                               NVL (rec_line.future1, '99')
                           AND NVL (segment11, '99') =
                               NVL (rec_line.future2, '99')
                           AND NVL (segment12, '99') =
                               NVL (rec_line.future3, '99')
                           AND NVL (segment13, '99') =
                               NVL (rec_line.future4, '99')
                           AND enabled_flag = 'Y'--           AND ROWNUM = 1

                                                 ;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        v_code_combination_id_num := NULL;



                        DBMS_OUTPUT.PUT_LINE (
                            'NO_DATA_FOUND: GL CCID not found');

                        DBMS_OUTPUT.PUT_LINE (
                               'UNIT='
                            || rec_line.unit
                            || ', LOC='
                            || rec_line.location
                            || ', DEPT='
                            || rec_line.department
                            || ', NAT='
                            || rec_line.naturalaccount);
                    --        FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO_DATA_FOUND: GL CCID not found');

                    --        FND_FILE.PUT_LINE(FND_FILE.LOG, 'UNIT=' || rec_line.unit ||', LOC=' || rec_line.location ||', DEPT=' || rec_line.department ||', NAT=' || rec_line.naturalaccount);



                    WHEN TOO_MANY_ROWS
                    THEN
                        DBMS_OUTPUT.PUT_LINE (
                            'TOO_MANY_ROWS: Multiple CCIDs matched');
                    --        FND_FILE.PUT_LINE(FND_FILE.LOG, 'TOO_MANY_ROWS: Multiple CCIDs matched');



                    WHEN OTHERS
                    THEN
                        v_code_combination_id_num := NULL;



                        DBMS_OUTPUT.PUT_LINE (
                            'ERROR resolving GL CCID: ' || SQLERRM);
                --        FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR resolving GL CCID: ' || SQLERRM);

                END;



                -- AP Line Insert

                SELECT ap_invoice_lines_interface_s.NEXTVAL@AUAPIPAPPSR12
                  INTO v_ap_line_id
                  FROM DUAL;

                INSERT INTO ap_invoice_lines_interface@AUAPIPAPPSR12 (
                                invoice_id,
                                invoice_line_id,
                                line_number,
                                line_group_number,
                                line_type_lookup_code,
                                amount,
                                description,
                                accounting_date,
                                org_id,
                                creation_date,
                                created_by,
                                last_updated_by,
                                last_update_date,
                                last_update_login,
                                dist_code_combination_id,
                                reference_key1,
                                reference_key2,
                                reference_key3,
                                ATTRIBUTE_CATEGORY,
                                ATTRIBUTE10,
                                ATTRIBUTE15)
                     VALUES (v_invoice_id,
                             v_ap_line_id,
                             l_line_number,
                             rec_line.seq_num,
                             'ITEM',
                             rec_line.amount,
                             rec_line.description,
                             rec_line.gldate,
                             ln_org_id,
                             SYSDATE,
                             v_user_id,
                             v_user_id,
                             SYSDATE,
                             v_user_id,
                             v_code_combination_id_num,
                             rec_hdr.invoice_number,
                             l_line_number,
                             'OFI TAX IMPORT',
                             rec_line.CONTEXTVALUE,
                             rec_line.INVOICETAXTYPE,
                             'AP_INDUS_API');



                UPDATE AP_INVOICES_INTERFACE@AUAPIPAPPSR12
                   SET DESCRIPTION =
                           CASE
                               WHEN LENGTH (rec_line.DESCRIPTION) >= 80
                               THEN
                                   SUBSTR (rec_line.DESCRIPTION, -80)
                               ELSE
                                   rec_line.DESCRIPTION
                           END
                 WHERE INVOICE_ID = v_invoice_id;



                -- ? MULTI-TAX LOOP (CGST+SGST+IGST)

                FOR rec_tax IN c_gst_taxes (rec_line.taxcategory, ln_org_id)
                LOOP
                    lv_tax_amount :=
                        rec_line.amount * rec_tax.rate_percentage / 100;



                    DBMS_OUTPUT.PUT_LINE (
                           'Tax: '
                        || rec_tax.tax_rate_name
                        || ' = '
                        || lv_tax_amount);



                    -- JAI Interface Line (ONLY FIRST TAX)

                    IF lv_tax_line_counter = 1
                    THEN
                        SELECT SUM (rate_percentage)
                          INTO tot_tax_per
                          FROM ti_gst_tax_v@AUAPIPAPPSR12
                         WHERE     UPPER (tax_category_name) =
                                   UPPER (rec_line.taxcategory)
                               AND org_id = ln_org_id;



                        totgst_amount := rec_line.amount * tot_tax_per / 100;



                        SELECT jai_interface_lines_all_s.NEXTVAL@AUAPIPAPPSR12
                          INTO ln_jai_interface_line_id
                          FROM DUAL;

                        INSERT INTO jai_interface_lines_all@AUAPIPAPPSR12 (
                                        org_id,
                                        organization_id,
                                        location_id,
                                        party_id,
                                        party_site_id,
                                        import_module,
                                        transaction_num,
                                        transaction_line_num,
                                        batch_source_name,
                                        creation_date,
                                        created_by,
                                        last_update_date,
                                        last_update_login,
                                        last_updated_by,
                                        interface_line_id,
                                        taxable_event,
                                        hsn_code,
                                        tax_category_id,
                                        taxable_basis,
                                        EXCLUSIVE_TAX_AMOUNT,
                                        INTENDED_USE,
                                        ATTRIBUTE15)
                                 VALUES (
                                            ln_org_id,
                                            NVL (rec_hdr.ln_organization_id,
                                                 ln_org_id),
                                            NVL (rec_hdr.ln_location_id, 0),
                                            v_vendor_id,
                                            NVL (v_vendor_site_id, 0),
                                            'AP',
                                            rec_hdr.invoice_number,
                                            l_line_number,
                                            'OFI TAX IMPORT',
                                            SYSDATE,
                                            v_user_id,
                                            SYSDATE,
                                            v_user_id,
                                            v_user_id,
                                            ln_jai_interface_line_id,
                                            'EXTERNAL',
                                            NVL (rec_line.hsncode, '9999'),
                                            rec_tax.tax_category_id,
                                            'LINE_AMOUNT',
                                            totgst_amount,
                                            DECODE (
                                                rec_tax.recoverable_flag,
                                                'Y', UPPER ('Recoverable'),
                                                NULL),
                                            'AP_INDUS_API');
                    END IF;



                    -- Tax Liability CCID

                    BEGIN
                        SELECT INTERIM_RECOVERY_CCID --RECOVERY_CCID--liability_ccid
                          INTO in_liability_ccid
                          FROM jai_tax_accounts_v@AUAPIPAPPSR12
                         WHERE     org_id = ln_org_id
                               AND organization_id =
                                   NVL (rec_hdr.ln_organization_id,
                                        ln_org_id)
                               AND tax_account_entity_id =
                                   rec_tax.tax_type_id--               AND ROWNUM = 1

                                                      ;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            in_liability_ccid := NULL;
                    END;



                    -- JAI Tax Line

                    SELECT jai_interface_tax_lines_all_s.NEXTVAL@AUAPIPAPPSR12
                      INTO ln_jai_tax_line_id
                      FROM DUAL;

                    INSERT INTO jai_interface_tax_lines_all@AUAPIPAPPSR12 (
                                    party_id,
                                    party_site_id,
                                    import_module,
                                    transaction_num,
                                    transaction_line_num,
                                    tax_line_no,
                                    creation_date,
                                    created_by,
                                    last_update_date,
                                    last_update_login,
                                    last_updated_by,
                                    interface_line_id,
                                    interface_tax_line_id,
                                    external_tax_code,
                                    tax_id,
                                    tax_amount,
                                    inclusive_tax_flag,
                                    code_combination_id)
                         VALUES (v_vendor_id,
                                 NVL (v_vendor_site_id, 0),
                                 'AP',
                                 rec_hdr.invoice_number,
                                 l_line_number,
                                 lv_tax_line_counter,
                                 SYSDATE,
                                 v_user_id,
                                 SYSDATE,
                                 v_user_id,
                                 v_user_id,
                                 ln_jai_interface_line_id,
                                 ln_jai_tax_line_id,
                                 rec_tax.tax_rate_name,
                                 rec_tax.tax_rate_id,
                                 lv_tax_amount,
                                 'N',
                                 in_liability_ccid);



                    COMMIT;

                    lv_tax_line_counter := lv_tax_line_counter + 1; -- ? FIXED - Now compiles!
                END LOOP;



                l_line_number := l_line_number + 1;
            END LOOP;
        EXCEPTION
            WHEN OTHERS
            THEN
                DBMS_OUTPUT.PUT_LINE ('Invoice Error: ' || SQLERRM);

                CONTINUE;
        END;
    END LOOP;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE ('=== PROCESS COMPLETED ===');
EXCEPTION
    WHEN OTHERS
    THEN
        ROLLBACK;

        DBMS_OUTPUT.PUT_LINE ('FATAL ERROR: ' || SQLERRM);

        RAISE;
--      SELECT * FROM API_INVOICES_PURC_V;

--      SELECT * FROM FROM API_INVOICES_PURC_V@APPSR12AUAPIP.AMARUJALA.COM B -- PROD TO AUAPIP ---PROCEDURE APPS.INS_TI_AP_INDUS_DATA -- TABLE TO STORE DATA --TI_AP_INDUS_DATA@AUAPIPAPPSR12



END XXAU_INVOICE_UPLOAD_PROC_v;
/