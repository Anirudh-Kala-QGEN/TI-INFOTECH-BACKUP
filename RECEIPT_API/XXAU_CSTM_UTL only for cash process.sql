CREATE OR REPLACE PACKAGE BODY AUCUSTOM.XXAU_CSTM_UTL
AS
/*----------------------------------------------------------------
1.0 - xxa_ar_4cplus_receipt_p2 -this procedure used for trasfer receipt between 4cplus application and ERP application
2.0--xxau_daily_4cplus_receipt_err- this procedure used for sending  mail with recipt detials which have error during transfer to selected  person
3.0-- xxau_create_ar_cm_dm-- this procedure used for create AR credit memo and debit memeo without GST  Tax
4.0 ---xxa_ar_gate_receipt_p2_man--This procedure is used for creating the single Cash Receipt.based on unit and gl date paprameters
5.0---xxau_personal_emp_ledger--- this procedure used for fteching the all asstet detials whcih are relted with all employees .this procedure fetch all receord
and insert all records in one particuler temparory table .
6.0--xxau_cir_flctu_report -- this report used for calculating the data for circulation po and supply and showing fluctuation beetween them. and after fetch data
data wiill be insert in one global temparory table
7.0--xxau_create_ap_inv_p--- this procedure used for create payable invoice with gst or without gst .
8.0--xxau_error_up -- this procedure used for updated alle rror in staging table after completion payable open import program
9.0 --validate_imported_invoices---this procedure used for validate the all invocie after import
10.0--xxau_update_dff_dist--- this procedure used for update advance detials like mobile number in dfff on distribution in ap for vodafone invoices
11.0--xxau_update_tax_adv_dtl-- this procedure used for update gst advance detials for credit note like original invoice number ,date
12.0--xxa_ar_dcr_receipt_p3 -- this procedure used for import record in ERP from ADDB.ADDB_XXA_AR_TRANS_ERP_RCPT
12.01 ---xxau_ap_inv_load -- this procedure used for uplode the data in Ap invoice creation staging table through WEbADi
12.02 ----xxau_create_ar_cm_dm_cio---upload refund , receipt writeoff ,invoice writeoff  from CIO to ERP
12.03 --------xxau_create_ar_ajd_ajc_cio upload adjustment and wirte off from cio to erp month wise

----------------------------------------------------------------------*/
   PROCEDURE xxa_ar_4cplus_receipt_pm (
      errbuf    OUT      VARCHAR2,
      retcode   OUT      NUMBER,
      p_unit    IN       VARCHAR2                                      --V1.0
   )
/*  *************************************************************************************
  $Version                 xxa_ar_4cplus_receipt_p2       v1.0
  Name:                    xxa_ar_4cplus_receipt_p2
  Author:                  Ankit  Singhal
  Creation Date            06-Aug-2018

  DESCRIPTION              This procedure is used for creating the single
                           Cash Receipt.

******************************************************************************************/
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      CURSOR unit (p_unit1 VARCHAR2)
      IS
         (SELECT organization_id, organization_code, flex_value
            FROM xxau_accounting_unit_new
           WHERE organization_code NOT IN ('HSO')
             AND flex_value = NVL (p_unit, flex_value));

      CURSOR c1 (p_unit1 VARCHAR2)      --------------------for normal receipt
      IS
         SELECT tt.*, td1.bank_account_id, td1.bank_acct_use_id, td3.NAME,
                td3.receipt_method_id, fv.meaning,
                xxa_hr_util.xxau_hr001_get_new_val_company
                                                    (fv.attribute1)
                                                                   unit_code1,
                gl.segment1 unit_code
           FROM auerp.xxa_ar_trans_erp_rcpt tt,
                apps.ce_bank_acct_uses_all@hrtoebs td1,
                apps.ar_receipt_method_accounts_all@hrtoebs td2,
                apps.ar_receipt_methods@hrtoebs td3,
                apps.gl_code_combinations@hrtoebs gl,
                apps.fnd_lookup_values@hrtoebs fv
          WHERE tt.bank_acc_id = td1.bank_account_id
            AND td1.bank_acct_use_id = td2.remit_bank_acct_use_id
            AND td2.receipt_method_id = td3.receipt_method_id
            AND (    UPPER (td3.NAME) NOT LIKE '%CIR%'
                 AND UPPER (td3.NAME) NOT LIKE '%MISC%'
                 AND UPPER (td3.NAME) NOT LIKE '%HDFC_CMS%'
                 AND UPPER (td3.NAME) NOT LIKE '%TERM LOAN%'
                 AND UPPER (td3.NAME) NOT LIKE '%INT_SD_RECPT'
                )
            AND td1.org_id = td2.org_id
            AND fv.lookup_type = 'REVENUE CENTRE MASTER'
            AND tt.attribute4 = fv.lookup_code
            AND td1.org_id = 288
            AND td2.end_date IS NULL
            AND td3.end_date IS NULL
            --AND tt.receipt_number='BLY-1819-0000856'
            AND NVL (process_flag, 'N') = 'N'
            AND doctype = 'RCR'
            AND td2.cash_ccid = gl.code_combination_id
            AND gl.segment1 = NVL (p_unit1, gl.segment1)
            AND NVL (security_flag, 'N') = 'N';

      -----------------------------For cheque and receipt revers--------------------------------
      CURSOR fetch_rev (p_unit1 VARCHAR2)
      IS
         (SELECT tt.*, td1.bank_account_id, td1.bank_acct_use_id, td3.NAME,
                 td3.receipt_method_id, fv.meaning,
                 xxa_hr_util.xxau_hr001_get_new_val_company
                                                    (fv.attribute1)
                                                                   unit_code1,
                 gl.segment1 unit_code, ttrd.process_message rcr_process_msz,
                 SUBSTR (ttrd.process_message,
                         INSTR (ttrd.process_message, '-') + 1
                        ) cash_receipt_id,
                 DECODE (NVL (tt.cheque_bounce_reason, 'WRONG AMOUNT'),
                         'NSF', 'NSF',
                         'AM04', 'NSF',
                         'OTHER REASONS'
                        ) reason_code,
                 DECODE (tt.cheque_bounce_reason,
                         'NSF', 'NSF',
                         NULL, 'REV',
                         'REV'
                        ) rev_cate,
                 ttrd.receipt_date orig_rec_dt
            FROM auerp.xxa_ar_trans_erp_rcpt tt,
                 apps.ce_bank_acct_uses_all@hrtoebs td1,
                 apps.ar_receipt_method_accounts_all@hrtoebs td2,
                 apps.ar_receipt_methods@hrtoebs td3,
                 apps.gl_code_combinations@hrtoebs gl,
                 apps.fnd_lookup_values@hrtoebs fv,
                 auerp.xxa_ar_trans_erp_rcpt ttrd
           WHERE tt.bank_acc_id = td1.bank_account_id
             AND td1.bank_acct_use_id = td2.remit_bank_acct_use_id
             AND td2.receipt_method_id = td3.receipt_method_id
             AND (    UPPER (td3.NAME) NOT LIKE '%CIR%'
                  AND UPPER (td3.NAME) NOT LIKE '%MISC%'
                  AND UPPER (td3.NAME) NOT LIKE '%HDFC_CMS%'
                  AND UPPER (td3.NAME) NOT LIKE '%TERM LOAN%'
                  AND UPPER (td3.NAME) NOT LIKE '%INT_SD_RECPT'
                 )
             AND td1.org_id = td2.org_id
             AND fv.lookup_type = 'REVENUE CENTRE MASTER'
             AND tt.attribute4 = fv.lookup_code
             AND td1.org_id = 288
             AND td2.end_date IS NULL
             AND td3.end_date IS NULL
             --AND tt.receipt_number='BLY-1819-0000856'
             AND NVL (tt.process_flag, 'N') = 'N'
             AND tt.doctype = 'RDN'
             AND td2.cash_ccid = gl.code_combination_id
             AND gl.segment1 = NVL (p_unit1, gl.segment1)
             --AND NVL (tt.security_flag, 'N') = 'N'
             AND tt.composite_receipt_id = ttrd.composite_receipt_id
             AND ttrd.doctype = 'RCR'
             AND NVL (ttrd.process_flag, 'N') = 'S');

      ----------------------------for security deposite-----------------------------
      CURSOR c_sd (p_unit1 VARCHAR2)
      IS
         SELECT tt.*, td1.bank_account_id, td1.bank_acct_use_id, td3.NAME,
                td3.receipt_method_id, fv.meaning,
                xxa_hr_util.xxau_hr001_get_new_val_company
                                                    (fv.attribute1)
                                                                   unit_code1,
                gl.segment1 unit_code
           FROM auerp.xxa_ar_trans_erp_rcpt tt,
                apps.ce_bank_acct_uses_all@hrtoebs td1,
                apps.ar_receipt_method_accounts_all@hrtoebs td2,
                apps.ar_receipt_methods@hrtoebs td3,
                apps.gl_code_combinations@hrtoebs gl,
                apps.fnd_lookup_values@hrtoebs fv
          WHERE tt.bank_acc_id = td1.bank_account_id
            AND td1.bank_acct_use_id = td2.remit_bank_acct_use_id
            AND td2.receipt_method_id = td3.receipt_method_id
            AND (    UPPER (td3.NAME) NOT LIKE '%CIR%'
                 AND UPPER (td3.NAME) NOT LIKE '%MISC%'
                 AND UPPER (td3.NAME) NOT LIKE '%HDFC_CMS%'
                 AND UPPER (td3.NAME) NOT LIKE '%TERM LOAN%'
                 AND UPPER (td3.NAME) NOT LIKE '%INT_SD_RECPT'
                )
            AND td1.org_id = td2.org_id
            AND td1.org_id = 288
            AND NVL (process_flag, 'N') = 'N'
            AND doctype IN ('RCR', 'RFD')
            AND td2.end_date IS NULL
            AND td3.end_date IS NULL
            AND fv.lookup_type = 'REVENUE CENTRE MASTER'
            AND tt.attribute4 = fv.lookup_code
            --  AND gl.segment1 =
                  ---    xxa_hr_util.xxau_hr001_get_new_val_company (fv.attribute1)
            AND td2.cash_ccid = gl.code_combination_id
            AND gl.segment1 = NVL (p_unit1, gl.segment1)
            AND NVL (security_flag, 'N') = 'Y'
                                              --- AND COMPOSITE_RECEIPT_ID in (321599)
      ;

      CURSOR c3 (p_receipt_id NUMBER)
      IS
         SELECT d.attribute_category, d.attribute14, d.attribute11
           FROM auerp.xxa_ar_trans_erp_rcpt d
          WHERE 1 = 1 AND d.composite_receipt_id = p_receipt_id;

      ---------------------------for PR receipt Update----------------------
      CURSOR fetch1_pr
      IS
         (SELECT SUBSTR (process_message,
                         INSTR (process_message, '-') + 1
                        ) receipt_id,
                 attribute11
            FROM auerp.xxa_ar_trans_erp_rcpt tt
           WHERE creation_date > SYSDATE - 5
             AND attribute11 IS NOT NULL
             AND LENGTH (attribute11) > 15
             AND process_flag = 'S'
             AND doctype = 'RCR'
             AND NOT EXISTS (
                    SELECT 'y'
                      FROM apps.ar_cash_receipts_all@hrtoebs
                     WHERE cash_receipt_id =
                              SUBSTR (process_message,
                                      INSTR (process_message, '-') + 1
                                     )
                       AND attribute11 = tt.attribute11)
             AND NOT EXISTS (SELECT 'y'
                               FROM auerp.xxa_ar_trans_erp_rcpt_mod
                              WHERE attribute11_old = tt.attribute11));

      ----------------duplicate receipt number amount and party  type issue resolved -------------------
      CURSOR ft_dup
      IS
         (SELECT 'SUCCESS' || '-' || tt1.cash_receipt_id process_msz,
                 tt.ROWID row_id
            FROM auerp.xxa_ar_trans_erp_rcpt tt,
                 ar_cash_receipts_all@hrtoebs tt1
           WHERE tt1.attribute1 = TO_CHAR (tt.composite_receipt_id)
             AND tt1.receipt_date = tt.receipt_date
             AND tt1.status NOT IN ('REV')
             AND (   tt.process_message =
                        'A cash receipt with this number, date, amount and customer already exists.'
                  OR tt.process_message =
                        'A miscellaneous receipt with this number, date and amount already exists.'
                 ));

      ----------------reverse done but not updated in erp and status on 10g type issue resolved -------------------
      CURSOR ft_rev
      IS
         (SELECT 'SUCCESS REVERS' || '-' || tt1.cash_receipt_id process_msz,
                 tt.ROWID row_id
            FROM auerp.xxa_ar_trans_erp_rcpt tt,
                 ar_cash_receipts_all@hrtoebs tt1
           WHERE tt1.attribute1 = TO_CHAR (tt.composite_receipt_id)
             AND tt1.receipt_date = tt.receipt_date
             AND tt1.status IN ('REV')
             AND (   tt.process_message LIKE
                                            'Invalid cash receipt identifier%'
                  OR tt.process_message IS NULL
                 ));

--------------------------update modify pr receipt in erp ------------------------
      CURSOR fetch1_pr_n
      IS
         (SELECT *
            FROM (SELECT tt1.cash_receipt_id, tt.attribute11_new,
                         tt.ROWID stg_row_id, tt.attribute15_new
                    FROM auerp.xxa_ar_trans_erp_rcpt_mod tt,
                         apps.ar_cash_receipts_all@hrtoebs tt1
                   WHERE tt.attribute11_old = tt1.attribute11
                     AND tt.receipt_number = tt1.attribute9
                     AND tt1.receipt_date = tt.receipt_date
                     AND NVL (tt.process_flag, 'N') = 'N'
                  UNION ALL
                  SELECT tt1.cash_receipt_id, tt.attribute11_new,
                         tt.ROWID stg_row_id, tt.attribute15_new
                    FROM auerp.xxa_ar_trans_erp_rcpt_mod tt,
                         apps.ar_cash_receipts_all@hrtoebs tt1
                   WHERE tt1.attribute11 IS NULL
                     AND tt.receipt_number = tt1.attribute9
                     AND tt1.receipt_date = tt.receipt_date
                     AND NVL (tt.process_flag, 'N') = 'N'));

      ---------------------------check receipt exists then update flag ---------------------
      CURSOR ft_check
      IS
         (SELECT tt1.composite_receipt_id, tt.cash_receipt_id,
                 tt.creation_date receipt_date
            FROM auerp.xxa_ar_trans_erp_rcpt tt1,
                 ar_cash_receipts_all@hrtoebs tt
           WHERE tt.attribute1 = TO_CHAR (tt1.composite_receipt_id)
             AND tt.attribute9 = tt1.attribute9
             AND NVL (tt1.process_flag, 'N') IN ('E', 'N')
             AND doctype = 'RCR');

      --- out parameters
      l_return_status          VARCHAR2 (1);
      l_msg_count              NUMBER;
      l_msg_data               VARCHAR2 (4000)                         := NULL;
      l_cash_receipt_id        NUMBER;
      l_misc_receipt_id        NUMBER;
      l_error_mesg             VARCHAR2 (4000)                         := NULL;
      p_count                  NUMBER;
      v_rec_trx_id             NUMBER;
      lv_receipt_method_name   VARCHAR2 (80);
      ln_receipt_method_id     NUMBER                                     := 0;
      x_return_status          VARCHAR2 (30)                           := NULL;
      x_msg_count              NUMBER;
      x_msg_data               VARCHAR2 (4000)                         := NULL;
      p_cr_id                  NUMBER;
      p_misc_receipt_id        NUMBER;
      v_unit_name              VARCHAR2 (3);
      err                      VARCHAR2 (400);
      ebf                      NUMBER;
      p_attribute_rec_type     apps.ar_receipt_api_pub.attribute_rec_type@hrtoebs;
      v_receipt_no             VARCHAR2 (40)                           := NULL;
---  v_rec_trx_id             NUMBER;
      v_return_status          VARCHAR2 (1);
      v_msg_count              NUMBER;
      v_msg_data               VARCHAR2 (2000);
      v_context                VARCHAR2 (2);
      i                        NUMBER;
      v_receipt_date           DATE;
      v_revers_date            DATE;
      v_check                  NUMBER                                     := 0;
      p_date                   DATE                                    := NULL;
   BEGIN
      -- DBMS_OUTPUT.put_line ('START');
      apps.fnd_global.apps_initialize@hrtoebs (2482, 52024, 222);
      apps.mo_global.set_policy_context@hrtoebs ('S', 288);

      --  DBMS_OUTPUT.put_line ('START111');
        ---------- code for cash receipts ----------
       -- DBMS_OUTPUT.put_line ('cash receipt 111');

      -------------------------------------check payment refund entry and update flag for manual entry--------------------------------
      BEGIN
         UPDATE auerp.xxa_ar_trans_erp_rcpt
            SET process_message =
                   'Enter Manually for Payment refund this not a security Refund',
                process_flag = 'M'
          WHERE NVL (process_flag, 'N') IN ('N')
            AND doctype = 'RFD'
            AND security_flag = 'N';

         COMMIT;
      END;

-------------------------------------------------------------end --------------------------------------------------

      --------------------------------update Error flag in to N for 'Related receipt is already reconciled in ERP' receipt error-------------------
      BEGIN
         UPDATE auerp.xxa_ar_trans_erp_rcpt
            SET process_flag = 'N'
          WHERE NVL (process_flag, 'N') IN ('E')
            AND process_message =
                                'Related receipt is already reconciled in ERP';

         COMMIT;
      END;

      -----------------------------check receipt and update ---------------------------
      BEGIN
         FOR ft1 IN ft_check
         LOOP
            UPDATE auerp.xxa_ar_trans_erp_rcpt
               SET process_flag = 'S',
                   process_message = 'SUCCESS' || '-' || ft1.cash_receipt_id,
                   process_date = SYSDATE
             WHERE composite_receipt_id = ft1.composite_receipt_id
               AND doctype = 'RCR';
         END LOOP;
      END;

-----------------------------------------------------------------------------------------------------------------
      FOR unit_m IN unit (p_unit)
      LOOP
         FOR i IN c1 (unit_m.flex_value)
         LOOP
            l_msg_data := NULL;
            l_msg_count := NULL;
            l_return_status := NULL;
            p_attribute_rec_type.attribute_category := i.attribute_category;
            p_attribute_rec_type.attribute1 := i.composite_receipt_id;
            p_attribute_rec_type.attribute2 := NVL (i.attribute2, 5);
            p_attribute_rec_type.attribute3 := NVL (i.attribute3, 'N');
            p_attribute_rec_type.attribute4 := NVL (i.attribute4, 'N');

            --- p_attribute_rec_type.attribute5 := NVL (i.attribute5, 'N');
            IF i.receipt_number LIKE 'ONL%'
            THEN
               IF i.attribute4 = 56
               THEN
                  p_attribute_rec_type.attribute5 := 223;
               ELSE
                  p_attribute_rec_type.attribute5 := i.attribute4;
               END IF;
            ELSE
               p_attribute_rec_type.attribute5 := NVL (i.attribute5, 'N');
            END IF;

            p_attribute_rec_type.attribute6 := i.receipt_date;
            p_attribute_rec_type.attribute7 := i.attribute7;
            p_attribute_rec_type.attribute8 :=
               i.party_number || '-' || i.party_name || '-'
               || i.party_location;
            p_attribute_rec_type.attribute9 := i.attribute9;

            IF i.attribute_category = 'AU_Receipt_Info'
            THEN
               p_attribute_rec_type.attribute10 := i.attribute10;
               p_attribute_rec_type.attribute12 := i.attribute12;
            ELSE
               p_attribute_rec_type.attribute12 := i.attribute12;
               p_attribute_rec_type.attribute10 := i.attribute10;
            END IF;

            -- DBMS_OUTPUT.put_line ('Main cash receipt ');
            p_attribute_rec_type.attribute11 := i.attribute11;
            p_attribute_rec_type.attribute13 := i.attribute13;
            p_attribute_rec_type.attribute14 := i.attribute14;
            p_attribute_rec_type.attribute15 := i.attribute15;

            IF i.attribute2 IN ('1', '7', '8')
            THEN
               v_receipt_no := i.chno;
            ELSE
               v_receipt_no := i.receipt_number;
            END IF;

            IF p_date IS NULL
            THEN
               v_receipt_date := i.receipt_date;
            ELSE
               v_receipt_date := p_date;
            END IF;

            IF i.party_number IS NOT NULL
            THEN
               -- DBMS_OUTPUT.put_line ('party number not null ');
               apps.ar_receipt_api_pub.create_cash@hrtoebs
                                 (p_api_version               => 1.0,
                                  p_init_msg_list             => 'T',
                                  p_commit                    => 'F',
                                  p_validation_level          => 100,
                                  x_return_status             => l_return_status,
                                  x_msg_count                 => l_msg_count,
                                  x_msg_data                  => l_msg_data,
                                  p_currency_code             => 'INR',
                                  p_amount                    => i.party_amt,
                                  p_receipt_number            => v_receipt_no,
                                  p_receipt_date              => v_receipt_date,
                                  p_gl_date                   => v_receipt_date,
                                  p_comments                  => i.comments,
                                  p_attribute_rec             => p_attribute_rec_type,
                                  p_customer_number           => '110155',
                                  ----------------------Advt - Customer
                                  p_receipt_method_id         => i.receipt_method_id,
                                  p_cr_id                     => l_cash_receipt_id,
                                  p_global_attribute_rec      => NULL,
                                  p_org_id                    => 288
                                 );
            ELSIF i.party_number IS NULL
            THEN
               -- DBMS_OUTPUT.put_line ('party number null ');
               apps.ar_receipt_api_pub.create_cash@hrtoebs
                                 (p_api_version               => 1.0,
                                  p_init_msg_list             => 'T',
                                  p_commit                    => 'T',
                                  p_validation_level          => 100,
                                  x_return_status             => l_return_status,
                                  x_msg_count                 => l_msg_count,
                                  x_msg_data                  => l_msg_data,
                                  p_currency_code             => 'INR',
                                  p_amount                    => i.party_amt,
                                  p_receipt_number            => v_receipt_no,
                                  p_receipt_date              => v_receipt_date,
                                  p_comments                  => i.comments,
                                  p_gl_date                   => v_receipt_date,
                                  p_attribute_rec             => p_attribute_rec_type,
                                  p_receipt_method_id         => i.receipt_method_id,
                                  p_cr_id                     => l_cash_receipt_id,
                                  p_global_attribute_rec      => NULL,
                                  p_org_id                    => 288
                                 );
            END IF;

--------------------------------------------------------
           -- DBMS_OUTPUT.put_line ('id  ' || l_cash_receipt_id);
            BEGIN
               IF l_cash_receipt_id IS NULL
               THEN
                  -- DBMS_OUTPUT.put_line ('id  null');
                  IF l_msg_count = 1
                  THEN
                     l_error_mesg := l_msg_data;
                  ELSIF l_msg_count > 1
                  THEN
                     l_msg_data := NULL;

                     LOOP
                        --  DBMS_OUTPUT.put_line ('in loop null');
                        p_count := p_count + 1;
                        l_msg_data := NULL;
                        l_msg_data := l_msg_data;

                        IF l_msg_data IS NULL
                        THEN
                           EXIT;
                        END IF;
                     END LOOP;

                     l_error_mesg := l_error_mesg || '-' || l_msg_data;
                  END IF;

                  --  DBMS_OUTPUT.put_line ('55555');
                  --  DBMS_OUTPUT.put_line (l_error_mesg);
                   -- DBMS_OUTPUT.put_line ('COMP ID - ' || i.composite_receipt_id);
                   -- DBMS_OUTPUT.put_line ('rcpt ID - ' || i.receipt_number);
                   -- DBMS_OUTPUT.put_line ('srno ID - ' || i.serial_number);
                  UPDATE auerp.xxa_ar_trans_erp_rcpt d
                     SET d.process_flag = 'E',
                         d.process_message = l_error_mesg,
                         d.process_date = SYSDATE
                   WHERE d.composite_receipt_id = i.composite_receipt_id
                     AND d.receipt_number = i.receipt_number
                     AND d.doctype = 'RCR'
                     AND d.serial_number = i.serial_number;
               --DBMS_OUTPUT.put_line ('666666655555');
               ELSE
                    --p_cr_id := l_cash_receipt_id;
                  --  DBMS_OUTPUT.put_line ('COMP ID Y - ' || i.composite_receipt_id);
                   -- DBMS_OUTPUT.put_line ('rcpt ID Y - ' || i.receipt_number);
                   -- DBMS_OUTPUT.put_line ('srno ID Y - ' || i.serial_number);
                  UPDATE auerp.xxa_ar_trans_erp_rcpt d
                     SET d.process_flag = 'S',
                         d.process_message =
                                         'SUCCESS' || '-' || l_cash_receipt_id,
                         d.process_date = SYSDATE
                   WHERE d.composite_receipt_id = i.composite_receipt_id
                     AND d.receipt_number = i.receipt_number
                     AND d.doctype = 'RCR'
                     AND d.serial_number = i.serial_number;
               END IF;

               COMMIT;
            END;

            --  DBMS_OUTPUT.put_line ('DONE');
            FOR ii IN c3 (i.composite_receipt_id)
            LOOP
------------------------------------------
               IF ii.attribute_category = 'AU_Receipt_Info'
               THEN
                  IF     ii.attribute14 IS NOT NULL
                     AND ii.attribute14 NOT LIKE '%NOT%'
                  THEN
                     UPDATE aucustom.xxau_pr_trans_det d
                        SET d.flag = 'P'
                      WHERE d.prov_receipt_no = ii.attribute14;
                  END IF;
               ELSE
                  IF     ii.attribute11 IS NOT NULL
                     AND ii.attribute11 NOT LIKE '%NOT%'
                  THEN
                     UPDATE aucustom.xxau_pr_trans_det d
                        SET d.flag = 'P'
                      WHERE d.prov_receipt_no = ii.attribute11;
                  END IF;
               END IF;

               COMMIT;
            END LOOP;
         END LOOP;

         ---------------------------------------for security Deposite-----------------------------------
         BEGIN
            FOR j IN c_sd (unit_m.flex_value)
            LOOP
               l_msg_data := NULL;
               l_msg_count := NULL;
               l_return_status := NULL;

               IF j.bank_acc_number = 'TDS PAYABLE ADVT SECURITY INT.'
               THEN
                  BEGIN
                     SELECT tt.receivables_trx_id
                       ---,tt.name,gl.segment1                                    -- 1025
                     INTO   v_rec_trx_id
                       FROM apps.ar_receivables_trx_all@hrtoebs tt,
                            gl_code_combinations_kfv@hrtoebs gl
                      WHERE tt.code_combination_id = gl.code_combination_id
                        AND tt.org_id = 288
                        AND tt.TYPE = 'MISCCASH'
                        AND tt.NAME NOT IN
                               ('Cheques in Hand', 'Cash Clearing Account',
                                'Misc Income', 'Misc Receipts')
                        AND UPPER (tt.NAME) NOT LIKE '%ADV%REFUND%'
                        AND UPPER (tt.NAME) NOT LIKE '%CASH%CLEARING%'
                        AND UPPER (tt.NAME) LIKE '%ADVT'
                        AND tt.status = 'A'
                        AND tt.end_date_active IS NULL
                        AND gl.segment1 = j.unit_code1;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_rec_trx_id := 0;
                  END;
               ELSE
                  BEGIN
                     SELECT tt.receivables_trx_id
                       ---,tt.name,gl.segment1                                    -- 1025
                     INTO   v_rec_trx_id
                       FROM apps.ar_receivables_trx_all@hrtoebs tt,
                            gl_code_combinations_kfv@hrtoebs gl
                      WHERE tt.code_combination_id = gl.code_combination_id
                        AND tt.org_id = 288
                        AND tt.TYPE = 'MISCCASH'
                        AND tt.NAME NOT IN
                               ('Cheques in Hand', 'Cash Clearing Account',
                                'Misc Income', 'Misc Receipts')
                        AND UPPER (tt.NAME) NOT LIKE '%ADV%REFUND%'
                        AND UPPER (tt.NAME) NOT LIKE '%CASH%CLEARING%'
                        AND UPPER (tt.NAME) LIKE '%ADVT'
                        AND tt.status = 'A'
                        AND tt.end_date_active IS NULL
                        ---AND gl.segment1 = j.unit_code;--------------change date on 18-sep-2022 behaf of harsh ji
                        AND gl.segment1 = j.unit_code1;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_rec_trx_id := 0;
                  END;
               END IF;

               ---- v_rec_trx_id:=1189;---for testing
               p_attribute_rec_type.attribute_category := j.attribute_category;
               p_attribute_rec_type.attribute1 := j.composite_receipt_id;
               p_attribute_rec_type.attribute2 := NVL (j.attribute2, 5);
               p_attribute_rec_type.attribute3 := NVL (j.attribute3, 'N');
               p_attribute_rec_type.attribute4 := NVL (j.attribute4, 'N');

               --p_attribute_rec_type.attribute4 := NVL (j.attribute4, 'N');

               --- p_attribute_rec_type.attribute5 := NVL (i.attribute5, 'N');
               IF j.receipt_number LIKE 'ONL%'
               THEN
                  IF j.attribute4 = 56
                  THEN
                     p_attribute_rec_type.attribute5 := 223;
                  ELSE
                     p_attribute_rec_type.attribute5 := j.attribute4;
                  END IF;
               ELSE
                  p_attribute_rec_type.attribute5 := NVL (j.attribute5, 'N');
               END IF;

               -- p_attribute_rec_type.attribute5 := NVL (j.attribute5, 'N');
               p_attribute_rec_type.attribute6 := j.receipt_date;
               p_attribute_rec_type.attribute7 := j.attribute7;
               p_attribute_rec_type.attribute8 :=
                  j.party_number || '-' || j.party_name || '-'
                  || j.party_location;
               p_attribute_rec_type.attribute9 := j.attribute9;

               IF j.attribute_category = 'AU_Receipt_Info'
               THEN
                  p_attribute_rec_type.attribute10 := j.attribute10;
                  p_attribute_rec_type.attribute12 := j.attribute12;
               ELSE
                  p_attribute_rec_type.attribute12 := j.attribute12;
                  p_attribute_rec_type.attribute10 := j.attribute10;
               END IF;

               --DBMS_OUTPUT.put_line ('security Receipt cash receipt ');
               p_attribute_rec_type.attribute11 := j.attribute11;
               p_attribute_rec_type.attribute13 := j.attribute13;
               p_attribute_rec_type.attribute14 := j.attribute14;
               p_attribute_rec_type.attribute15 := j.attribute15;

               IF j.attribute2 = '1'
               THEN
                  v_receipt_no := j.chno;
               ELSE
                  v_receipt_no := j.receipt_number;
               END IF;

               IF p_date IS NULL
               THEN
                  v_receipt_date := j.receipt_date;
               ELSE
                  v_receipt_date := p_date;
               END IF;

               apps.ar_receipt_api_pub.create_misc@hrtoebs
                                  (
                                   --- api parameters
                                   p_api_version                  => 1.0,
                                   p_init_msg_list                => 'T',
                                   p_commit                       => 'F',
                                   p_validation_level             => 100,
                                   -- out parameters
                                   x_return_status                => l_return_status,
                                   x_msg_count                    => l_msg_count,
                                   x_msg_data                     => l_msg_data,
                                   p_currency_code                => 'INR',
                                   p_amount                       => j.party_amt,
                                   p_receipt_date                 => v_receipt_date,
                                   p_gl_date                      => v_receipt_date,
                                   p_receipt_method_id            => j.receipt_method_id,
                                   p_attribute_record             => p_attribute_rec_type,
                                   p_activity                     => 'Misc Receipts',
                                   p_misc_receipt_id              => l_misc_receipt_id,
                                   p_receipt_number               => v_receipt_no,
                                   p_exchange_rate_type           => NULL,
                                   p_receivables_trx_id           => v_rec_trx_id,
                                   p_global_attribute_record      => NULL,
                                   p_org_id                       => 288
                                  );

               IF l_misc_receipt_id IS NOT NULL
               THEN
                  BEGIN
                     UPDATE auerp.xxa_ar_trans_erp_rcpt d
                        SET d.process_flag = 'S',
                            d.process_message =
                                         'SUCCESS' || '-' || l_misc_receipt_id,
                            d.process_date = SYSDATE
                      WHERE d.composite_receipt_id = j.composite_receipt_id
                        AND d.receipt_number = j.receipt_number
                        AND d.doctype IN ('RCR', 'RFD')
                        AND d.serial_number = j.serial_number;
                  END;
               ELSE
                  BEGIN
                     IF l_msg_count = 1
                     THEN
                        l_error_mesg := l_msg_data;
                     ELSIF l_msg_count > 1
                     THEN
                        l_msg_data := NULL;

                        LOOP
                           -- DBMS_OUTPUT.put_line ('in loop null');
                           p_count := p_count + 1;
                           l_msg_data := NULL;
                           l_msg_data := l_msg_data;

                           IF l_msg_data IS NULL
                           THEN
                              EXIT;
                           END IF;
                        END LOOP;

                        l_error_mesg := l_error_mesg || '-' || l_msg_data;
                     END IF;

                     UPDATE auerp.xxa_ar_trans_erp_rcpt d
                        SET d.process_flag = 'E',
                            d.process_message = l_error_mesg,
                            d.process_date = SYSDATE
                      WHERE d.composite_receipt_id = j.composite_receipt_id
                        AND d.receipt_number = j.receipt_number
                        AND d.doctype IN ('RCR', 'RFD')
                        AND d.serial_number = j.serial_number;
                  END;
               END IF;

               COMMIT;

               ---------------------update pr status in 10g--------------------------
               FOR ii IN c3 (j.composite_receipt_id)
               LOOP
------------------------------------------
                  IF ii.attribute_category = 'AU_Receipt_Info'
                  THEN
                     IF     ii.attribute14 IS NOT NULL
                        AND ii.attribute14 NOT LIKE '%NOT%'
                     THEN
                        UPDATE aucustom.xxau_pr_trans_det d
                           SET d.flag = 'P'
                         WHERE d.prov_receipt_no = ii.attribute14;
                     END IF;
                  ELSE
                     IF     ii.attribute11 IS NOT NULL
                        AND ii.attribute11 NOT LIKE '%NOT%'
                     THEN
                        UPDATE aucustom.xxau_pr_trans_det d
                           SET d.flag = 'P'
                         WHERE d.prov_receipt_no = ii.attribute11;
                     END IF;
                  END IF;

                  COMMIT;
               END LOOP;      ----------------pr status update----------------
            END LOOP;                             -----------------sd loop end
         END;

----------------------------------reverse receipt------------------------------------------
         FOR fetch2 IN fetch_rev (unit_m.flex_value)
         LOOP
            v_check := 0;
            l_msg_data := NULL;
            v_msg_count := NULL;
            v_return_status := NULL;

            BEGIN
               SELECT COUNT (1)
                 INTO v_check
                 FROM ce_statement_reconcils_all@hrtoebs csra,
                      ce_statement_lines@hrtoebs csl,
                      ar_cash_receipt_history_all@hrtoebs acrh
                WHERE reference_id = acrh.cash_receipt_history_id
                  AND csra.statement_line_id = csl.statement_line_id
                  AND csl.status = 'RECONCILED'
                  AND csra.reference_type = 'RECEIPT'
                  AND csra.status_flag = 'M'
                  AND csra.current_record_flag = 'Y'
                  AND csra.org_id = 288
                  AND acrh.org_id = 288
                  AND acrh.cash_receipt_id = fetch2.cash_receipt_id;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_check := 0;
               WHEN OTHERS
               THEN
                  v_check := 0;
            END;

            IF v_check = 0
            THEN
               BEGIN
                  p_attribute_rec_type.attribute_category :=
                                                    fetch2.attribute_category;
                  p_attribute_rec_type.attribute1 :=
                                                  fetch2.composite_receipt_id;
                  p_attribute_rec_type.attribute2 :=
                                                   NVL (fetch2.attribute2, 5);
                  p_attribute_rec_type.attribute3 :=
                                                 NVL (fetch2.attribute3, 'N');
                  p_attribute_rec_type.attribute4 :=
                                                 NVL (fetch2.attribute4, 'N');

                                                       --    p_attribute_rec_type.attribute4 := NVL (fetch2.attribute4, 'N');
                  --- p_attribute_rec_type.attribute5 := NVL (i.attribute5, 'N');
                  IF fetch2.receipt_number LIKE 'ONL%'
                  THEN
                     IF fetch2.attribute4 = 56
                     THEN
                        p_attribute_rec_type.attribute5 := 223;
                     ELSE
                        p_attribute_rec_type.attribute5 := fetch2.attribute4;
                     END IF;
                  ELSE
                     p_attribute_rec_type.attribute5 :=
                                                 NVL (fetch2.attribute5, 'N');
                  END IF;

                  --p_attribute_rec_type.attribute5 :=
                                        --            NVL (fetch2.attribute5, 'N');
                  p_attribute_rec_type.attribute6 :=
                                                  NVL (fetch2.attribute6, 'N');
                  p_attribute_rec_type.attribute7 := fetch2.attribute7;
                  p_attribute_rec_type.attribute8 :=
                        fetch2.party_number
                     || '-'
                     || fetch2.party_name
                     || '-'
                     || fetch2.party_location;
                  p_attribute_rec_type.attribute9 := fetch2.attribute9;

                  IF fetch2.attribute_category = 'AU_Receipt_Info'
                  THEN
                     p_attribute_rec_type.attribute10 := fetch2.attribute10;
                     p_attribute_rec_type.attribute12 := fetch2.attribute12;
                  ELSE
                     p_attribute_rec_type.attribute12 := fetch2.attribute12;
                     p_attribute_rec_type.attribute10 := fetch2.attribute10;
                  END IF;

                  IF fetch2.ref_receiptdt < fetch2.orig_rec_dt
                  THEN
                     v_revers_date := fetch2.orig_rec_dt;
                  ELSE
                     v_revers_date := fetch2.ref_receiptdt;
                  END IF;

                  -- DBMS_OUTPUT.put_line ('revers receipt ');
                  p_attribute_rec_type.attribute11 := fetch2.attribute11;
                  p_attribute_rec_type.attribute13 := fetch2.attribute13;
                  p_attribute_rec_type.attribute14 := fetch2.attribute14;
                  p_attribute_rec_type.attribute15 := fetch2.attribute15;
                  ar_receipt_api_pub.REVERSE@hrtoebs
                                (p_api_version                 => 1.0,
                                 p_init_msg_list               => 'T',
                                 p_commit                      => 'F',
                                 p_validation_level            => '100',
                                 x_return_status               => v_return_status,
                                 x_msg_count                   => v_msg_count,
                                 x_msg_data                    => l_msg_data,
                                 p_cash_receipt_id             => fetch2.cash_receipt_id,
                                 p_receipt_number              => NULL,
                                 p_reversal_category_code      => fetch2.rev_cate,
                                 p_reversal_category_name      => NULL,
                                 p_reversal_gl_date            => v_revers_date,
                                 p_reversal_date               => v_revers_date,
                                 p_reversal_reason_code        => fetch2.reason_code,
                                 p_reversal_reason_name        => NULL,
                                 p_reversal_comments           => NULL,
                                 p_called_from                 => NULL,
                                 p_cancel_claims_flag          => 'Y',
                                 p_attribute_rec               => p_attribute_rec_type,
                                 p_global_attribute_rec        => NULL,
                                 p_org_id                      => 288
                                );

                  -- DBMS_OUTPUT.put_line (   'Receipt Reversal is Sucessful--'
                      --                   || v_return_status
                        --                );
                  IF v_return_status = 'S'
                  THEN
                     --DBMS_OUTPUT.put_line ('Receipt Reversal is Sucessful');
                     UPDATE auerp.xxa_ar_trans_erp_rcpt d
                        SET d.process_flag = 'S',
                            d.process_message =
                               'SUCCESS REVERS' || '-'
                               || fetch2.cash_receipt_id,
                            d.process_date = SYSDATE
                      WHERE d.composite_receipt_id =
                                                   fetch2.composite_receipt_id
                        --AND d.receipt_number = fetch2.receipt_number
                        AND d.doctype = 'RDN';

                     COMMIT;
                  -- AND d.serial_number = fetch2.serial_number;
                  ELSE
                     BEGIN
                        ---DBMS_OUTPUT.put_line ('Message count ' || v_msg_count);
                        IF v_msg_count > 0
                        THEN
                           FOR j IN 1 .. fnd_msg_pub.count_msg@hrtoebs
                           LOOP
                              fnd_msg_pub.get@hrtoebs (p_msg_index          => j,
                                                       p_encoded            => 'F',
                                                       p_data               => l_msg_data,
                                                       p_msg_index_out      => i
                                                      );
                           --  DBMS_OUTPUT.put_line (   'Message count '
                                               --    || l_msg_data
                                               --   );
                           END LOOP;
                        END IF;

                        BEGIN
                           UPDATE auerp.xxa_ar_trans_erp_rcpt d
                              SET d.process_flag = 'E',
                                  d.process_message = l_msg_data,
                                  d.process_date = SYSDATE
                            WHERE d.composite_receipt_id =
                                                   fetch2.composite_receipt_id
                              AND d.receipt_number = fetch2.receipt_number
                              AND d.doctype = 'RDN'
                              AND d.serial_number = fetch2.serial_number;

                           COMMIT;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;
                     END;
                  END IF;
               END;
            ELSE
               BEGIN
                  UPDATE auerp.xxa_ar_trans_erp_rcpt d
                     SET d.process_flag = 'E',
                         d.process_message =
                                'Related receipt is already reconciled in ERP',
                         d.process_date = SYSDATE
                   WHERE d.composite_receipt_id = fetch2.composite_receipt_id
                     AND d.receipt_number = fetch2.receipt_number
                     AND d.doctype = 'RDN'
                     AND d.serial_number = fetch2.serial_number;

                  COMMIT;
               END;
            END IF;

            COMMIT;
         END LOOP;                        -------------------reverse loop end;
      END LOOP;                         ------------------------unit loop end;

      BEGIN
         UPDATE auerp.xxa_ar_trans_erp_rcpt tt
            SET process_message =
                    'Dublicate because cheque number have two or more receipt',
                process_flag = 'N',
                chno = chno || '-D_' || SUBSTR (composite_receipt_id, -2, 2),
                process_date = SYSDATE
          WHERE tt.process_message =
                   'A cash receipt with this number, date, amount and customer already exists.'
            AND NOT EXISTS (
                   SELECT 'Y'
                     FROM ar_cash_receipts_all@hrtoebs
                    WHERE attribute1 = TO_CHAR (tt.composite_receipt_id)
                      AND receipt_date = tt.receipt_date
                      AND status NOT IN ('REV'));

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         FOR ft1_dup IN ft_dup
         LOOP
            UPDATE auerp.xxa_ar_trans_erp_rcpt tt
               SET process_message = ft1_dup.process_msz,
                   process_flag = 'S',
                   process_date = SYSDATE,
                   process_message12 = 'After Error '
             WHERE ROWID = ft1_dup.row_id;
         END LOOP;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         FOR ft_rev1 IN ft_rev
         LOOP
            UPDATE auerp.xxa_ar_trans_erp_rcpt tt
               SET process_message = ft_rev1.process_msz,
                   process_flag = 'S',
                   process_date = SYSDATE,
                   process_message12 = 'After Revers'
             WHERE ROWID = ft_rev1.row_id;
         END LOOP;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      ----------------------------for update PR receipt Number----------------------------------
      BEGIN
         FOR fetch2 IN fetch1_pr
         LOOP
            UPDATE apps.ar_cash_receipts_all@hrtoebs
               SET attribute11 = fetch2.attribute11
             WHERE cash_receipt_id = fetch2.receipt_id;

            COMMIT;
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         FOR fetch_pr_n IN fetch1_pr_n
         LOOP
            UPDATE apps.ar_cash_receipts_all@hrtoebs
               SET attribute11 = fetch_pr_n.attribute11_new,
                   attribute15 = fetch_pr_n.attribute15_new
             WHERE cash_receipt_id = fetch_pr_n.cash_receipt_id;

            UPDATE auerp.xxa_ar_trans_erp_rcpt_mod
               SET process_flag = 'S',
                   process_msg = 'Success',
                   process_date = SYSDATE
             WHERE ROWID = fetch_pr_n.stg_row_id;

            COMMIT;
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END xxa_ar_4cplus_receipt_pm;

   PROCEDURE xxa_ar_4cplus_receipt_p2 (
      errbuf    OUT      VARCHAR2,
      retcode   OUT      NUMBER,
      p_unit    IN       VARCHAR2 DEFAULT NULL,
      p_date    IN       DATE DEFAULT NULL                              --V1.0
   )
/*  *************************************************************************************
  $Version                 xxa_ar_4cplus_receipt_p2       v1.0
  Name:                    xxa_ar_4cplus_receipt_p2
  Author:                  Ankit  Singhal
  Creation Date            06-Aug-2018

  DESCRIPTION              This procedure is used for creating the single
                           Cash Receipt.

******************************************************************************************/
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      CURSOR unit (p_unit1 VARCHAR2)
      IS
         (SELECT organization_id, organization_code, flex_value
            FROM xxau_accounting_unit_new
           WHERE organization_code NOT IN ('HSO')
             AND flex_value = NVL (p_unit, flex_value));

      CURSOR c1 (p_unit1 VARCHAR2)      --------------------for normal receipt
      IS
         SELECT tt.*, td1.bank_account_id, td1.bank_acct_use_id, td3.NAME,
                td3.receipt_method_id, fv.meaning,
                xxa_hr_util.xxau_hr001_get_new_val_company
                                                    (fv.attribute1)
                                                                   unit_code1,
                gl.segment1 unit_code
           FROM auerp.xxa_ar_trans_erp_rcpt tt,
                apps.ce_bank_acct_uses_all@hrtoebs td1,
                apps.ar_receipt_method_accounts_all@hrtoebs td2,
                apps.ar_receipt_methods@hrtoebs td3,
                apps.gl_code_combinations@hrtoebs gl,
                apps.fnd_lookup_values@hrtoebs fv
          WHERE tt.bank_acc_id = td1.bank_account_id
            AND td1.bank_acct_use_id = td2.remit_bank_acct_use_id
            AND td2.receipt_method_id = td3.receipt_method_id
            AND (    UPPER (td3.NAME) NOT LIKE '%CIR%'
                 AND UPPER (td3.NAME) NOT LIKE '%MISC%'
                 AND UPPER (td3.NAME) NOT LIKE '%HDFC_CMS%'
                 AND UPPER (td3.NAME) NOT LIKE '%TERM LOAN%'
                 AND UPPER (td3.NAME) NOT LIKE '%INT_SD_RECPT'
                )
            AND td1.org_id = td2.org_id
            AND fv.lookup_type = 'REVENUE CENTRE MASTER'
            AND tt.attribute4 = fv.lookup_code
            AND td1.org_id = 288
            AND td2.end_date IS NULL
            AND td3.end_date IS NULL
            --AND tt.receipt_number='BLY-1819-0000856'
            AND NVL (process_flag, 'N') = 'N'
            AND doctype = 'RCR'
            AND td2.cash_ccid = gl.code_combination_id
            AND gl.segment1 = NVL (p_unit1, gl.segment1)
            AND NVL (security_flag, 'N') = 'N';

      -----------------------------For cheque and receipt revers--------------------------------
      CURSOR fetch_rev (p_unit1 VARCHAR2)
      IS
         (SELECT tt.*, td1.bank_account_id, td1.bank_acct_use_id, td3.NAME,
                 td3.receipt_method_id, fv.meaning,
                 xxa_hr_util.xxau_hr001_get_new_val_company
                                                    (fv.attribute1)
                                                                   unit_code1,
                 gl.segment1 unit_code, ttrd.process_message rcr_process_msz,
                 SUBSTR (ttrd.process_message,
                         INSTR (ttrd.process_message, '-') + 1
                        ) cash_receipt_id,
                 DECODE (NVL (tt.cheque_bounce_reason, 'WRONG AMOUNT'),
                         'NSF', 'NSF',
                         'AM04', 'NSF',
                         'OTHER REASONS'
                        ) reason_code,
                 DECODE (tt.cheque_bounce_reason,
                         'NSF', 'NSF',
                         NULL, 'REV',
                         'REV'
                        ) rev_cate,
                 ttrd.receipt_date orig_rec_dt
            FROM auerp.xxa_ar_trans_erp_rcpt tt,
                 apps.ce_bank_acct_uses_all@hrtoebs td1,
                 apps.ar_receipt_method_accounts_all@hrtoebs td2,
                 apps.ar_receipt_methods@hrtoebs td3,
                 apps.gl_code_combinations@hrtoebs gl,
                 apps.fnd_lookup_values@hrtoebs fv,
                 auerp.xxa_ar_trans_erp_rcpt ttrd
           WHERE tt.bank_acc_id = td1.bank_account_id
             AND td1.bank_acct_use_id = td2.remit_bank_acct_use_id
             AND td2.receipt_method_id = td3.receipt_method_id
             AND (    UPPER (td3.NAME) NOT LIKE '%CIR%'
                  AND UPPER (td3.NAME) NOT LIKE '%MISC%'
                  AND UPPER (td3.NAME) NOT LIKE '%HDFC_CMS%'
                  AND UPPER (td3.NAME) NOT LIKE '%TERM LOAN%'
                  AND UPPER (td3.NAME) NOT LIKE '%INT_SD_RECPT'
                 )
             AND td1.org_id = td2.org_id
             AND fv.lookup_type = 'REVENUE CENTRE MASTER'
             AND tt.attribute4 = fv.lookup_code
             AND td1.org_id = 288
             AND td2.end_date IS NULL
             AND td3.end_date IS NULL
             --AND tt.receipt_number='BLY-1819-0000856'
             AND NVL (tt.process_flag, 'N') = 'N'
             AND tt.doctype = 'RDN'
             AND td2.cash_ccid = gl.code_combination_id
             AND gl.segment1 = NVL (p_unit1, gl.segment1)
             -- AND NVL (tt.security_flag, 'N') = 'N'
             AND tt.composite_receipt_id = ttrd.composite_receipt_id
             AND ttrd.doctype = 'RCR'
             AND NVL (ttrd.process_flag, 'N') = 'S');

      ----------------------------for security deposite-----------------------------
      CURSOR c_sd (p_unit1 VARCHAR2)
      IS
         SELECT tt.*, td1.bank_account_id, td1.bank_acct_use_id, td3.NAME,
                td3.receipt_method_id, fv.meaning,
                xxa_hr_util.xxau_hr001_get_new_val_company
                                                    (fv.attribute1)
                                                                   unit_code1,
                gl.segment1 unit_code
           FROM auerp.xxa_ar_trans_erp_rcpt tt,
                apps.ce_bank_acct_uses_all@hrtoebs td1,
                apps.ar_receipt_method_accounts_all@hrtoebs td2,
                apps.ar_receipt_methods@hrtoebs td3,
                apps.gl_code_combinations@hrtoebs gl,
                apps.fnd_lookup_values@hrtoebs fv
          WHERE tt.bank_acc_id = td1.bank_account_id
            AND td1.bank_acct_use_id = td2.remit_bank_acct_use_id
            AND td2.receipt_method_id = td3.receipt_method_id
            AND (    UPPER (td3.NAME) NOT LIKE '%CIR%'
                 AND UPPER (td3.NAME) NOT LIKE '%MISC%'
                 AND UPPER (td3.NAME) NOT LIKE '%HDFC_CMS%'
                 AND UPPER (td3.NAME) NOT LIKE '%TERM LOAN%'
                 AND UPPER (td3.NAME) NOT LIKE '%INT_SD_RECPT'
                )
            AND td1.org_id = td2.org_id
            AND td1.org_id = 288
            AND NVL (process_flag, 'N') = 'N'
            AND doctype IN ('RCR', 'RFD')
            AND td2.end_date IS NULL
            AND td3.end_date IS NULL
            AND fv.lookup_type = 'REVENUE CENTRE MASTER'
            AND tt.attribute4 = fv.lookup_code
            --  AND gl.segment1 =
                  ---    xxa_hr_util.xxau_hr001_get_new_val_company (fv.attribute1)
            AND td2.cash_ccid = gl.code_combination_id
            AND gl.segment1 = NVL (p_unit1, gl.segment1)
            AND NVL (security_flag, 'N') = 'Y'
                                              --- AND COMPOSITE_RECEIPT_ID in (321599)
      ;

      CURSOR c3 (p_receipt_id NUMBER)
      IS
         SELECT d.attribute_category, d.attribute14, d.attribute11
           FROM auerp.xxa_ar_trans_erp_rcpt d
          WHERE 1 = 1 AND d.composite_receipt_id = p_receipt_id;

      ---------------------------for PR receipt Update----------------------
      CURSOR fetch1_pr
      IS
         (SELECT SUBSTR (process_message,
                         INSTR (process_message, '-') + 1
                        ) receipt_id,
                 attribute11
            FROM auerp.xxa_ar_trans_erp_rcpt tt
           WHERE creation_date > SYSDATE - 5
             AND attribute11 IS NOT NULL
             AND LENGTH (attribute11) > 15
             AND process_flag = 'S'
             AND doctype = 'RCR'
             AND NOT EXISTS (
                    SELECT 'y'
                      FROM apps.ar_cash_receipts_all@hrtoebs
                     WHERE cash_receipt_id =
                              SUBSTR (process_message,
                                      INSTR (process_message, '-') + 1
                                     )
                       AND attribute11 = tt.attribute11)
             AND NOT EXISTS (SELECT 'y'
                               FROM auerp.xxa_ar_trans_erp_rcpt_mod
                              WHERE attribute11_old = tt.attribute11));

      ----------------duplicate receipt number amount and party  type issue resolved -------------------
      CURSOR ft_dup
      IS
         (SELECT 'SUCCESS' || '-' || tt1.cash_receipt_id process_msz,
                 tt.ROWID row_id
            FROM auerp.xxa_ar_trans_erp_rcpt tt,
                 ar_cash_receipts_all@hrtoebs tt1
           WHERE tt1.attribute1 = TO_CHAR (tt.composite_receipt_id)
             AND tt1.receipt_date = tt.receipt_date
             AND tt1.status NOT IN ('REV')
             AND (   tt.process_message =
                        'A cash receipt with this number, date, amount and customer already exists.'
                  OR tt.process_message =
                        'A miscellaneous receipt with this number, date and amount already exists.'
                 ));

      ----------------reverse done but not updated in erp and status on 10g type issue resolved -------------------
      CURSOR ft_rev
      IS
         (SELECT 'SUCCESS REVERS' || '-' || tt1.cash_receipt_id process_msz,
                 tt.ROWID row_id
            FROM auerp.xxa_ar_trans_erp_rcpt tt,
                 ar_cash_receipts_all@hrtoebs tt1
           WHERE tt1.attribute1 = TO_CHAR (tt.composite_receipt_id)
             AND tt1.receipt_date = tt.receipt_date
             AND tt1.status IN ('REV')
             AND (   tt.process_message LIKE
                                            'Invalid cash receipt identifier%'
                  OR tt.process_message IS NULL
                 ));

--------------------------update modify pr receipt in erp ------------------------
      CURSOR fetch1_pr_n
      IS
         (SELECT *
            FROM (SELECT tt1.cash_receipt_id, tt.attribute11_new,
                         tt.ROWID stg_row_id, tt.attribute15_new
                    FROM auerp.xxa_ar_trans_erp_rcpt_mod tt,
                         apps.ar_cash_receipts_all@hrtoebs tt1
                   WHERE tt.attribute11_old = tt1.attribute11
                     AND tt.receipt_number = tt1.attribute9
                     AND tt1.receipt_date = tt.receipt_date
                     AND NVL (tt.process_flag, 'N') = 'N'
                  UNION ALL
                  SELECT tt1.cash_receipt_id, tt.attribute11_new,
                         tt.ROWID stg_row_id, tt.attribute15_new
                    FROM auerp.xxa_ar_trans_erp_rcpt_mod tt,
                         apps.ar_cash_receipts_all@hrtoebs tt1
                   WHERE tt1.attribute11 IS NULL
                     AND tt.receipt_number = tt1.attribute9
                     AND tt1.receipt_date = tt.receipt_date
                     AND NVL (tt.process_flag, 'N') = 'N'));

      ---------------------------check receipt exists then update flag ---------------------
      CURSOR ft_check
      IS
         (SELECT tt1.composite_receipt_id, tt.cash_receipt_id,
                 tt.creation_date receipt_date
            FROM auerp.xxa_ar_trans_erp_rcpt tt1,
                 ar_cash_receipts_all@hrtoebs tt
           WHERE tt.attribute1 = TO_CHAR (tt1.composite_receipt_id)
             AND tt.attribute9 = tt1.attribute9
             AND NVL (tt1.process_flag, 'N') IN ('E', 'N')
             AND doctype = 'RCR');

      --- out parameters
      l_return_status          VARCHAR2 (1);
      l_msg_count              NUMBER;
      l_msg_data               VARCHAR2 (4000)                         := NULL;
      l_cash_receipt_id        NUMBER;
      l_misc_receipt_id        NUMBER;
      l_error_mesg             VARCHAR2 (4000)                         := NULL;
      p_count                  NUMBER;
      v_rec_trx_id             NUMBER;
      lv_receipt_method_name   VARCHAR2 (80);
      ln_receipt_method_id     NUMBER                                     := 0;
      x_return_status          VARCHAR2 (30)                           := NULL;
      x_msg_count              NUMBER;
      x_msg_data               VARCHAR2 (4000)                         := NULL;
      p_cr_id                  NUMBER;
      p_misc_receipt_id        NUMBER;
      v_unit_name              VARCHAR2 (3);
      err                      VARCHAR2 (400);
      ebf                      NUMBER;
      p_attribute_rec_type     apps.ar_receipt_api_pub.attribute_rec_type@hrtoebs;
      v_receipt_no             VARCHAR2 (40)                           := NULL;
---  v_rec_trx_id             NUMBER;
      v_return_status          VARCHAR2 (1);
      v_msg_count              NUMBER;
      v_msg_data               VARCHAR2 (2000);
      v_context                VARCHAR2 (2);
      i                        NUMBER;
      v_receipt_date           DATE;
      v_revers_date            DATE;
      v_check                  NUMBER                                     := 0;
   BEGIN
      -- DBMS_OUTPUT.put_line ('START');
      apps.fnd_global.apps_initialize@hrtoebs (2482, 52024, 222);
      apps.mo_global.set_policy_context@hrtoebs ('S', 288);

      -- DBMS_OUTPUT.put_line ('START111');
       ---------- code for cash receipts ----------
       --DBMS_OUTPUT.put_line ('cash receipt 111');

      -------------------------------------check payment refund entry and update flag for manual entry--------------------------------
      BEGIN
         UPDATE auerp.xxa_ar_trans_erp_rcpt
            SET process_message =
                   'Enter Manually for Payment refund this not a security Refund',
                process_flag = 'M'
          WHERE NVL (process_flag, 'N') IN ('N')
            AND doctype = 'RFD'
            AND security_flag = 'N';

         COMMIT;
      END;

-------------------------------------------------------------end --------------------------------------------------

      --------------------------------update Error flag in to N for 'Related receipt is already reconciled in ERP' receipt error-------------------
      BEGIN
         UPDATE auerp.xxa_ar_trans_erp_rcpt
            SET process_flag = 'N'
          WHERE NVL (process_flag, 'N') IN ('E')
            AND process_message =
                                'Related receipt is already reconciled in ERP';

         COMMIT;
      END;

      -----------------------------check receipt and update ---------------------------
      BEGIN
         FOR ft1 IN ft_check
         LOOP
            UPDATE auerp.xxa_ar_trans_erp_rcpt
               SET process_flag = 'S',
                   process_message = 'SUCCESS' || '-' || ft1.cash_receipt_id,
                   process_date = SYSDATE
             WHERE composite_receipt_id = ft1.composite_receipt_id
               AND doctype = 'RCR';
         END LOOP;
      END;

-----------------------------------------------------------------------------------------------------------------
      FOR unit_m IN unit (p_unit)
      LOOP
         BEGIN
            FOR i IN c1 (unit_m.flex_value)
            LOOP
               l_msg_data := NULL;
               l_msg_count := NULL;
               l_return_status := NULL;
               p_attribute_rec_type.attribute_category :=
                                                         i.attribute_category;
               p_attribute_rec_type.attribute1 := i.composite_receipt_id;
               p_attribute_rec_type.attribute2 := NVL (i.attribute2, 5);
               p_attribute_rec_type.attribute3 := NVL (i.attribute3, 'N');
               p_attribute_rec_type.attribute4 := NVL (i.attribute4, 'N');

               --- p_attribute_rec_type.attribute5 := NVL (i.attribute5, 'N');
               IF i.receipt_number LIKE 'ONL%'
               THEN
                  IF i.attribute4 = 56
                  THEN
                     p_attribute_rec_type.attribute5 := 223;
                  ELSE
                     p_attribute_rec_type.attribute5 := i.attribute4;
                  END IF;
               ELSE
                  p_attribute_rec_type.attribute5 := NVL (i.attribute5, 'N');
               END IF;

               p_attribute_rec_type.attribute6 := i.receipt_date;
               p_attribute_rec_type.attribute7 := i.attribute7;
               p_attribute_rec_type.attribute8 :=
                  i.party_number || '-' || i.party_name || '-'
                  || i.party_location;
               p_attribute_rec_type.attribute9 := i.attribute9;

               IF i.attribute_category = 'AU_Receipt_Info'
               THEN
                  p_attribute_rec_type.attribute10 := i.attribute10;
                  p_attribute_rec_type.attribute12 := i.attribute12;
               ELSE
                  p_attribute_rec_type.attribute12 := i.attribute12;
                  p_attribute_rec_type.attribute10 := i.attribute10;
               END IF;

               -- DBMS_OUTPUT.put_line ('Main cash receipt ');
               p_attribute_rec_type.attribute11 := i.attribute11;
               p_attribute_rec_type.attribute13 := i.attribute13;
               p_attribute_rec_type.attribute14 := i.attribute14;
               p_attribute_rec_type.attribute15 := i.attribute15;

               IF i.attribute2 IN ('1', '7', '8')
               THEN
                  v_receipt_no := i.chno;
               ELSE
                  v_receipt_no := i.receipt_number;
               END IF;

               IF p_date IS NULL
               THEN
                  v_receipt_date := i.receipt_date;
               ELSE
                  v_receipt_date := p_date;
               END IF;

               IF i.party_number IS NOT NULL
               THEN
                  -- DBMS_OUTPUT.put_line ('party number not null ');
                  apps.ar_receipt_api_pub.create_cash@hrtoebs
                                 (p_api_version               => 1.0,
                                  p_init_msg_list             => 'T',
                                  p_commit                    => 'F',
                                  p_validation_level          => 100,
                                  x_return_status             => l_return_status,
                                  x_msg_count                 => l_msg_count,
                                  x_msg_data                  => l_msg_data,
                                  p_currency_code             => 'INR',
                                  p_amount                    => i.party_amt,
                                  p_receipt_number            => v_receipt_no,
                                  p_receipt_date              => v_receipt_date,
                                  p_gl_date                   => v_receipt_date,
                                  p_comments                  => i.comments,
                                  p_attribute_rec             => p_attribute_rec_type,
                                  p_customer_number           => '110155',
                                  ----------------------Advt - Customer
                                  p_receipt_method_id         => i.receipt_method_id,
                                  p_cr_id                     => l_cash_receipt_id,
                                  p_global_attribute_rec      => NULL,
                                  p_org_id                    => 288
                                 );
               ELSIF i.party_number IS NULL
               THEN
                  -- DBMS_OUTPUT.put_line ('party number null ');
                  apps.ar_receipt_api_pub.create_cash@hrtoebs
                                 (p_api_version               => 1.0,
                                  p_init_msg_list             => 'T',
                                  p_commit                    => 'T',
                                  p_validation_level          => 100,
                                  x_return_status             => l_return_status,
                                  x_msg_count                 => l_msg_count,
                                  x_msg_data                  => l_msg_data,
                                  p_currency_code             => 'INR',
                                  p_amount                    => i.party_amt,
                                  p_receipt_number            => v_receipt_no,
                                  p_receipt_date              => v_receipt_date,
                                  p_comments                  => i.comments,
                                  p_gl_date                   => v_receipt_date,
                                  p_attribute_rec             => p_attribute_rec_type,
                                  p_receipt_method_id         => i.receipt_method_id,
                                  p_cr_id                     => l_cash_receipt_id,
                                  p_global_attribute_rec      => NULL,
                                  p_org_id                    => 288
                                 );
               END IF;

--------------------------------------------------------
           -- DBMS_OUTPUT.put_line ('id  ' || l_cash_receipt_id);
               IF l_cash_receipt_id IS NULL
               THEN
                  BEGIN
                     -- DBMS_OUTPUT.put_line ('id  null');
                     IF l_msg_count = 1
                     THEN
                        l_error_mesg := l_msg_data;
                     ELSIF l_msg_count > 1
                     THEN
                        l_msg_data := NULL;

                        LOOP
                           -- DBMS_OUTPUT.put_line ('in loop null');
                           p_count := p_count + 1;
                           l_msg_data := NULL;
                           l_msg_data := l_msg_data;

                           IF l_msg_data IS NULL
                           THEN
                              EXIT;
                           END IF;
                        END LOOP;

                        l_error_mesg := l_error_mesg || '-' || l_msg_data;
                     END IF;

                     -- DBMS_OUTPUT.put_line ('55555');
                     -- DBMS_OUTPUT.put_line (l_error_mesg);
                      --DBMS_OUTPUT.put_line ('COMP ID - ' || i.composite_receipt_id);
                      --DBMS_OUTPUT.put_line ('rcpt ID - ' || i.receipt_number);
                      --DBMS_OUTPUT.put_line ('srno ID - ' || i.serial_number);
                     UPDATE auerp.xxa_ar_trans_erp_rcpt d
                        SET d.process_flag = 'E',
                            d.process_message = l_error_mesg,
                            d.process_date = SYSDATE
                      WHERE d.composite_receipt_id = i.composite_receipt_id
                        AND d.receipt_number = i.receipt_number
                        AND d.doctype = 'RCR'
                        AND d.serial_number = i.serial_number;

                     COMMIT;
                  -- DBMS_OUTPUT.put_line ('666666655555');
                  END;
               ELSE
                  BEGIN
                       --p_cr_id := l_cash_receipt_id;
                     --  DBMS_OUTPUT.put_line ('COMP ID Y - ' || i.composite_receipt_id);
                     --  DBMS_OUTPUT.put_line ('rcpt ID Y - ' || i.receipt_number);
                      -- DBMS_OUTPUT.put_line ('srno ID Y - ' || i.serial_number);
                     UPDATE auerp.xxa_ar_trans_erp_rcpt d
                        SET d.process_flag = 'S',
                            d.process_message =
                                         'SUCCESS' || '-' || l_cash_receipt_id,
                            d.process_date = SYSDATE
                      WHERE d.composite_receipt_id = i.composite_receipt_id
                        AND d.receipt_number = i.receipt_number
                        AND d.doctype = 'RCR'
                        AND d.serial_number = i.serial_number;

                     COMMIT;
                  END;
               END IF;

               FOR ii IN c3 (i.composite_receipt_id)
               LOOP
------------------------------------------
                  IF ii.attribute_category = 'AU_Receipt_Info'
                  THEN
                     IF     ii.attribute14 IS NOT NULL
                        AND ii.attribute14 NOT LIKE '%NOT%'
                     THEN
                        UPDATE aucustom.xxau_pr_trans_det d
                           SET d.flag = 'P'
                         WHERE d.prov_receipt_no = ii.attribute14;
                     END IF;
                  ELSE
                     IF     ii.attribute11 IS NOT NULL
                        AND ii.attribute11 NOT LIKE '%NOT%'
                     THEN
                        UPDATE aucustom.xxau_pr_trans_det d
                           SET d.flag = 'P'
                         WHERE d.prov_receipt_no = ii.attribute11;
                     END IF;
                  END IF;

                  COMMIT;
               END LOOP;
            END LOOP;
         END;

         ---------------------------------------for security Deposite-----------------------------------
         BEGIN
            FOR j IN c_sd (unit_m.flex_value)
            LOOP
               l_msg_data := NULL;
               l_msg_count := NULL;
               l_return_status := NULL;

               IF j.bank_acc_number = 'TDS PAYABLE ADVT SECURITY INT.'
               THEN
                  BEGIN
                     SELECT tt.receivables_trx_id
                       ---,tt.name,gl.segment1                                    -- 1025
                     INTO   v_rec_trx_id
                       FROM apps.ar_receivables_trx_all@hrtoebs tt,
                            gl_code_combinations_kfv@hrtoebs gl
                      WHERE tt.code_combination_id = gl.code_combination_id
                        AND tt.org_id = 288
                        AND tt.TYPE = 'MISCCASH'
                        AND tt.NAME NOT IN
                               ('Cheques in Hand', 'Cash Clearing Account',
                                'Misc Income', 'Misc Receipts')
                        AND UPPER (tt.NAME) NOT LIKE '%ADV%REFUND%'
                        AND UPPER (tt.NAME) NOT LIKE '%CASH%CLEARING%'
                        AND UPPER (tt.NAME) LIKE '%ADVT'
                        AND tt.status = 'A'
                        AND tt.end_date_active IS NULL
                        AND gl.segment1 = j.unit_code1;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_rec_trx_id := 0;
                  END;
               ELSE
                  BEGIN
                     SELECT tt.receivables_trx_id
                       ---,tt.name,gl.segment1                                    -- 1025
                     INTO   v_rec_trx_id
                       FROM apps.ar_receivables_trx_all@hrtoebs tt,
                            gl_code_combinations_kfv@hrtoebs gl
                      WHERE tt.code_combination_id = gl.code_combination_id
                        AND tt.org_id = 288
                        AND tt.TYPE = 'MISCCASH'
                        AND tt.NAME NOT IN
                               ('Cheques in Hand', 'Cash Clearing Account',
                                'Misc Income', 'Misc Receipts')
                        AND UPPER (tt.NAME) NOT LIKE '%ADV%REFUND%'
                        AND UPPER (tt.NAME) NOT LIKE '%CASH%CLEARING%'
                        AND UPPER (tt.NAME) LIKE '%ADVT'
                        AND tt.status = 'A'
                        AND tt.end_date_active IS NULL
                        ---AND gl.segment1 = j.unit_code;------------cahnge behaf of Harsh ji 18-sep-2022
                        AND gl.segment1 = j.unit_code1;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_rec_trx_id := 0;
                  END;
               END IF;

               ---- v_rec_trx_id:=1189;---for testing
               p_attribute_rec_type.attribute_category := j.attribute_category;
               p_attribute_rec_type.attribute1 := j.composite_receipt_id;
               p_attribute_rec_type.attribute2 := NVL (j.attribute2, 5);
               p_attribute_rec_type.attribute3 := NVL (j.attribute3, 'N');
               p_attribute_rec_type.attribute4 := NVL (j.attribute4, 'N');

               --p_attribute_rec_type.attribute4 := NVL (j.attribute4, 'N');

               --- p_attribute_rec_type.attribute5 := NVL (i.attribute5, 'N');
               IF j.receipt_number LIKE 'ONL%'
               THEN
                  IF j.attribute4 = 56
                  THEN
                     p_attribute_rec_type.attribute5 := 223;
                  ELSE
                     p_attribute_rec_type.attribute5 := j.attribute4;
                  END IF;
               ELSE
                  p_attribute_rec_type.attribute5 := NVL (j.attribute5, 'N');
               END IF;

               -- p_attribute_rec_type.attribute5 := NVL (j.attribute5, 'N');
               p_attribute_rec_type.attribute6 := j.receipt_date;
               p_attribute_rec_type.attribute7 := j.attribute7;
               p_attribute_rec_type.attribute8 :=
                  j.party_number || '-' || j.party_name || '-'
                  || j.party_location;
               p_attribute_rec_type.attribute9 := j.attribute9;

               IF j.attribute_category = 'AU_Receipt_Info'
               THEN
                  p_attribute_rec_type.attribute10 := j.attribute10;
                  p_attribute_rec_type.attribute12 := j.attribute12;
               ELSE
                  p_attribute_rec_type.attribute12 := j.attribute12;
                  p_attribute_rec_type.attribute10 := j.attribute10;
               END IF;

               DBMS_OUTPUT.put_line ('security Receipt cash receipt ');
               p_attribute_rec_type.attribute11 := j.attribute11;
               p_attribute_rec_type.attribute13 := j.attribute13;
               p_attribute_rec_type.attribute14 := j.attribute14;
               p_attribute_rec_type.attribute15 := j.attribute15;

               IF j.attribute2 = '1'
               THEN
                  v_receipt_no := j.chno;
               ELSE
                  v_receipt_no := j.receipt_number;
               END IF;

               IF p_date IS NULL
               THEN
                  v_receipt_date := j.receipt_date;
               ELSE
                  v_receipt_date := p_date;
               END IF;

               apps.ar_receipt_api_pub.create_misc@hrtoebs
                                  (
                                   --- api parameters
                                   p_api_version                  => 1.0,
                                   p_init_msg_list                => 'T',
                                   p_commit                       => 'F',
                                   p_validation_level             => 100,
                                   -- out parameters
                                   x_return_status                => l_return_status,
                                   x_msg_count                    => l_msg_count,
                                   x_msg_data                     => l_msg_data,
                                   p_currency_code                => 'INR',
                                   p_amount                       => j.party_amt,
                                   p_receipt_date                 => v_receipt_date,
                                   p_gl_date                      => v_receipt_date,
                                   p_receipt_method_id            => j.receipt_method_id,
                                   p_attribute_record             => p_attribute_rec_type,
                                   p_activity                     => 'Misc Receipts',
                                   p_misc_receipt_id              => l_misc_receipt_id,
                                   p_receipt_number               => v_receipt_no,
                                   p_exchange_rate_type           => NULL,
                                   p_receivables_trx_id           => v_rec_trx_id,
                                   p_global_attribute_record      => NULL,
                                   p_org_id                       => 288
                                  );

               IF l_misc_receipt_id IS NOT NULL
               THEN
                  BEGIN
                     UPDATE auerp.xxa_ar_trans_erp_rcpt d
                        SET d.process_flag = 'S',
                            d.process_message =
                                         'SUCCESS' || '-' || l_misc_receipt_id,
                            d.process_date = SYSDATE
                      WHERE d.composite_receipt_id = j.composite_receipt_id
                        AND d.receipt_number = j.receipt_number
                        AND d.doctype IN ('RCR', 'RFD')
                        AND d.serial_number = j.serial_number;
                  END;
               ELSE
                  BEGIN
                     IF l_msg_count = 1
                     THEN
                        l_error_mesg := l_msg_data;
                     ELSIF l_msg_count > 1
                     THEN
                        l_msg_data := NULL;

                        LOOP
                           DBMS_OUTPUT.put_line ('in loop null');
                           p_count := p_count + 1;
                           l_msg_data := NULL;
                           l_msg_data := l_msg_data;

                           IF l_msg_data IS NULL
                           THEN
                              EXIT;
                           END IF;
                        END LOOP;

                        l_error_mesg := l_error_mesg || '-' || l_msg_data;
                     END IF;

                     UPDATE auerp.xxa_ar_trans_erp_rcpt d
                        SET d.process_flag = 'E',
                            d.process_message = l_error_mesg,
                            d.process_date = SYSDATE
                      WHERE d.composite_receipt_id = j.composite_receipt_id
                        AND d.receipt_number = j.receipt_number
                        AND d.doctype IN ('RCR', 'RFD')
                        AND d.serial_number = j.serial_number;
                  END;
               END IF;

               COMMIT;

               ---------------------update pr status in 10g--------------------------
               FOR ii IN c3 (j.composite_receipt_id)
               LOOP
------------------------------------------
                  IF ii.attribute_category = 'AU_Receipt_Info'
                  THEN
                     IF     ii.attribute14 IS NOT NULL
                        AND ii.attribute14 NOT LIKE '%NOT%'
                     THEN
                        UPDATE aucustom.xxau_pr_trans_det d
                           SET d.flag = 'P'
                         WHERE d.prov_receipt_no = ii.attribute14;
                     END IF;
                  ELSE
                     IF     ii.attribute11 IS NOT NULL
                        AND ii.attribute11 NOT LIKE '%NOT%'
                     THEN
                        UPDATE aucustom.xxau_pr_trans_det d
                           SET d.flag = 'P'
                         WHERE d.prov_receipt_no = ii.attribute11;
                     END IF;
                  END IF;

                  COMMIT;
               END LOOP;      ----------------pr status update----------------
            END LOOP;                             -----------------sd loop end
         END;

         BEGIN
----------------------------------reverse receipt------------------------------------------
            FOR fetch2 IN fetch_rev (unit_m.flex_value)
            LOOP
               v_check := 0;
               l_msg_data := NULL;
               v_msg_count := NULL;
               v_return_status := NULL;

               BEGIN
                  SELECT COUNT (1)
                    INTO v_check
                    FROM ce_statement_reconcils_all@hrtoebs csra,
                         ce_statement_lines@hrtoebs csl,
                         ar_cash_receipt_history_all@hrtoebs acrh
                   WHERE reference_id = acrh.cash_receipt_history_id
                     AND csra.statement_line_id = csl.statement_line_id
                     AND csl.status = 'RECONCILED'
                     AND csra.reference_type = 'RECEIPT'
                     AND csra.status_flag = 'M'
                     AND csra.current_record_flag = 'Y'
                     AND csra.org_id = 288
                     AND acrh.org_id = 288
                     AND acrh.cash_receipt_id = fetch2.cash_receipt_id;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_check := 0;
                  WHEN OTHERS
                  THEN
                     v_check := 0;
               END;

               IF v_check = 0
               THEN
                  BEGIN
                     p_attribute_rec_type.attribute_category :=
                                                    fetch2.attribute_category;
                     p_attribute_rec_type.attribute1 :=
                                                  fetch2.composite_receipt_id;
                     p_attribute_rec_type.attribute2 :=
                                                   NVL (fetch2.attribute2, 5);
                     p_attribute_rec_type.attribute3 :=
                                                 NVL (fetch2.attribute3, 'N');
                     p_attribute_rec_type.attribute4 :=
                                                 NVL (fetch2.attribute4, 'N');

                                                          --    p_attribute_rec_type.attribute4 := NVL (fetch2.attribute4, 'N');
                     --- p_attribute_rec_type.attribute5 := NVL (i.attribute5, 'N');
                     IF fetch2.receipt_number LIKE 'ONL%'
                     THEN
                        IF fetch2.attribute4 = 56
                        THEN
                           p_attribute_rec_type.attribute5 := 223;
                        ELSE
                           p_attribute_rec_type.attribute5 :=
                                                            fetch2.attribute4;
                        END IF;
                     ELSE
                        p_attribute_rec_type.attribute5 :=
                                                 NVL (fetch2.attribute5, 'N');
                     END IF;

                     --p_attribute_rec_type.attribute5 :=
                                           --            NVL (fetch2.attribute5, 'N');
                     p_attribute_rec_type.attribute6 :=
                                                  NVL (fetch2.attribute6, 'N');
                     p_attribute_rec_type.attribute7 := fetch2.attribute7;
                     p_attribute_rec_type.attribute8 :=
                           fetch2.party_number
                        || '-'
                        || fetch2.party_name
                        || '-'
                        || fetch2.party_location;
                     p_attribute_rec_type.attribute9 := fetch2.attribute9;

                     IF fetch2.attribute_category = 'AU_Receipt_Info'
                     THEN
                        p_attribute_rec_type.attribute10 :=
                                                           fetch2.attribute10;
                        p_attribute_rec_type.attribute12 :=
                                                           fetch2.attribute12;
                     ELSE
                        p_attribute_rec_type.attribute12 :=
                                                           fetch2.attribute12;
                        p_attribute_rec_type.attribute10 :=
                                                           fetch2.attribute10;
                     END IF;

                     IF fetch2.ref_receiptdt < fetch2.orig_rec_dt
                     THEN
                        v_revers_date := fetch2.orig_rec_dt;
                     ELSE
                        v_revers_date := fetch2.ref_receiptdt;
                     END IF;

                     DBMS_OUTPUT.put_line ('revers receipt ');
                     p_attribute_rec_type.attribute11 := fetch2.attribute11;
                     p_attribute_rec_type.attribute13 := fetch2.attribute13;
                     p_attribute_rec_type.attribute14 := fetch2.attribute14;
                     p_attribute_rec_type.attribute15 := fetch2.attribute15;
                     ar_receipt_api_pub.REVERSE@hrtoebs
                                (p_api_version                 => 1.0,
                                 p_init_msg_list               => 'T',
                                 p_commit                      => 'F',
                                 p_validation_level            => '100',
                                 x_return_status               => v_return_status,
                                 x_msg_count                   => v_msg_count,
                                 x_msg_data                    => l_msg_data,
                                 p_cash_receipt_id             => fetch2.cash_receipt_id,
                                 p_receipt_number              => NULL,
                                 p_reversal_category_code      => fetch2.rev_cate,
                                 p_reversal_category_name      => NULL,
                                 p_reversal_gl_date            => v_revers_date,
                                 p_reversal_date               => v_revers_date,
                                 p_reversal_reason_code        => fetch2.reason_code,
                                 p_reversal_reason_name        => NULL,
                                 p_reversal_comments           => NULL,
                                 p_called_from                 => NULL,
                                 p_cancel_claims_flag          => 'Y',
                                 p_attribute_rec               => p_attribute_rec_type,
                                 p_global_attribute_rec        => NULL,
                                 p_org_id                      => 288
                                );
                     DBMS_OUTPUT.put_line
                                         (   'Receipt Reversal is Sucessful--'
                                          || v_return_status
                                         );

                     IF v_return_status = 'S'
                     THEN
                        --DBMS_OUTPUT.put_line ('Receipt Reversal is Sucessful');
                        UPDATE auerp.xxa_ar_trans_erp_rcpt d
                           SET d.process_flag = 'S',
                               d.process_message =
                                     'SUCCESS REVERS'
                                  || '-'
                                  || fetch2.cash_receipt_id,
                               d.process_date = SYSDATE
                         WHERE d.composite_receipt_id =
                                                   fetch2.composite_receipt_id
                           -- AND d.receipt_number = fetch2.receipt_number
                           AND d.doctype = 'RDN';
                     --AND d.serial_number = fetch2.serial_number;
                     ELSE
                        BEGIN
                           ---DBMS_OUTPUT.put_line ('Message count ' || v_msg_count);
                           IF v_msg_count > 0
                           THEN
                              FOR j IN 1 .. fnd_msg_pub.count_msg@hrtoebs
                              LOOP
                                 fnd_msg_pub.get@hrtoebs
                                                       (p_msg_index          => j,
                                                        p_encoded            => 'F',
                                                        p_data               => l_msg_data,
                                                        p_msg_index_out      => i
                                                       );
                                 DBMS_OUTPUT.put_line (   'Message count '
                                                       || l_msg_data
                                                      );
                              END LOOP;
                           END IF;

                           BEGIN
                              UPDATE auerp.xxa_ar_trans_erp_rcpt d
                                 SET d.process_flag = 'E',
                                     d.process_message = l_msg_data,
                                     d.process_date = SYSDATE
                               WHERE d.composite_receipt_id =
                                                   fetch2.composite_receipt_id
                                 AND d.receipt_number = fetch2.receipt_number
                                 AND d.doctype = 'RDN'
                                 AND d.serial_number = fetch2.serial_number;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;
                        END;
                     END IF;
                  END;
               ELSE
                  BEGIN
                     UPDATE auerp.xxa_ar_trans_erp_rcpt d
                        SET d.process_flag = 'E',
                            d.process_message =
                                'Related receipt is already reconciled in ERP',
                            d.process_date = SYSDATE
                      WHERE d.composite_receipt_id =
                                                   fetch2.composite_receipt_id
                        AND d.receipt_number = fetch2.receipt_number
                        AND d.doctype = 'RDN'
                        AND d.serial_number = fetch2.serial_number;
                  END;
               END IF;

               COMMIT;
            END LOOP;
         END;                             -------------------reverse loop end;
      END LOOP;                         ------------------------unit loop end;

      BEGIN
         UPDATE auerp.xxa_ar_trans_erp_rcpt tt
            SET process_message =
                    'Dublicate because cheque number have two or more receipt',
                process_flag = 'N',
                chno = chno || '-D_' || SUBSTR (composite_receipt_id, -2, 2),
                process_date = SYSDATE
          WHERE tt.process_message =
                   'A cash receipt with this number, date, amount and customer already exists.'
            AND NOT EXISTS (
                   SELECT 'Y'
                     FROM ar_cash_receipts_all@hrtoebs
                    WHERE attribute1 = TO_CHAR (tt.composite_receipt_id)
                      AND receipt_date = tt.receipt_date
                      AND status NOT IN ('REV'));

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         FOR ft1_dup IN ft_dup
         LOOP
            UPDATE auerp.xxa_ar_trans_erp_rcpt tt
               SET process_message = ft1_dup.process_msz,
                   process_flag = 'S',
                   process_date = SYSDATE,
                   process_message12 = 'After Error '
             WHERE ROWID = ft1_dup.row_id;
         END LOOP;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         FOR ft_rev1 IN ft_rev
         LOOP
            UPDATE auerp.xxa_ar_trans_erp_rcpt tt
               SET process_message = ft_rev1.process_msz,
                   process_flag = 'S',
                   process_date = SYSDATE,
                   process_message12 = 'After Revers'
             WHERE ROWID = ft_rev1.row_id;
         END LOOP;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      ----------------------------for update PR receipt Number----------------------------------
      BEGIN
         FOR fetch2 IN fetch1_pr
         LOOP
            UPDATE apps.ar_cash_receipts_all@hrtoebs
               SET attribute11 = fetch2.attribute11
             WHERE cash_receipt_id = fetch2.receipt_id;

            COMMIT;
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         FOR fetch_pr_n IN fetch1_pr_n
         LOOP
            UPDATE apps.ar_cash_receipts_all@hrtoebs
               SET attribute11 = fetch_pr_n.attribute11_new,
                   attribute15 = fetch_pr_n.attribute15_new
             WHERE cash_receipt_id = fetch_pr_n.cash_receipt_id;

            UPDATE auerp.xxa_ar_trans_erp_rcpt_mod
               SET process_flag = 'S',
                   process_msg = 'Success',
                   process_date = SYSDATE
             WHERE ROWID = fetch_pr_n.stg_row_id;

            COMMIT;
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END xxa_ar_4cplus_receipt_p2;

   PROCEDURE xxa_ar_dcr_receipt_p3 (
      errbuf    OUT      VARCHAR2,
      retcode   OUT      NUMBER,
      p_unit    IN       VARCHAR2 DEFAULT NULL,
      p_date    IN       DATE DEFAULT NULL                              --V1.0
   )
/*  *************************************************************************************
  $Version                 xxa_ar_dcr_receipt_p3       v1.0
  Name:                    xxa_ar_dcr_receipt_p3
  Author:                  Ankush Goel
  Creation Date            15-APR-2021

  DESCRIPTION              This procedure is used for creating the single
                           AU_Receipt_Info Receipt wise.

******************************************************************************************/
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      CURSOR unit (p_unit1 VARCHAR2)
      IS
         (SELECT organization_id, organization_code, flex_value
            FROM xxau_accounting_unit_new
           WHERE organization_code NOT IN ('HSO')
             AND flex_value = NVL (p_unit, flex_value));

      CURSOR c1 (p_unit1 VARCHAR2)      --------------------for normal receipt
      IS
         SELECT tt.composite_receipt_id, tt.serial_number, tt.party_number,
                tt.party_name, tt.party_location, tt.receipt_number,
                tt.party_amt, tt.attribute_category, tt.attribute1,
                tt.attribute2, tt.attribute3, tt.attribute4, tt.attribute5,
                tt.attribute6, tt.attribute7, tt.attribute8, tt.attribute9,
                tt.attribute10, tt.attribute11, tt.attribute12,
                tt.attribute13, tt.attribute14, tt.attribute15,
                tt.process_flag, tt.process_message, tt.process_date,
                tt.created_by, tt.creation_date, tt.last_updated_by,
                tt.last_update_date, tt.comments, tt.process_flag12,
                tt.process_message12, tt.process_date12, tt.receipt_date,
                tt.chno, tt.bank_acc_id, tt.bank_acc_number, tt.bank_acc_name,
                tt.doctype, tt.ref_receiptno, tt.ref_receiptdt,
                tt.ref_doctype, tt.security_flag, tt.cons_type,
                tt.cons_rcpt_no, tt.cheque_bounce_reason,
                tt.receipt_method_id, tt.prov_recptdt rct_date,
                tt.erp_customer_number cust_no, gl.segment1 unit_code
           FROM addb.addb_xxa_ar_trans_erp_rcpt tt,
                apps.ar_receipt_method_accounts_all@hrtoebs td2,
                apps.ar_receipt_methods@hrtoebs td3,
                apps.gl_code_combinations@hrtoebs gl
          WHERE tt.receipt_method_id = td3.receipt_method_id
            AND td3.receipt_method_id = td2.receipt_method_id
            AND td2.org_id = 288
            AND td2.end_date IS NULL
            AND td3.end_date IS NULL
            AND NVL (process_flag, 'N') = 'N'
            AND doctype = 'RCR'
            AND td2.cash_ccid = gl.code_combination_id
            AND gl.segment1 = NVL (p_unit1, gl.segment1)
            AND NVL (security_flag, 'N') = 'N'
			AND tt.cons_rcpt_no is null										  
                                              --AND tt.composite_receipt_id=14661
      ;

               /*SELECT tt.composite_receipt_id, tt.serial_number, tt.party_number,
                      tt.party_name, tt.party_location, tt.receipt_number,
                      tt.party_amt, tt.attribute_category, tt.attribute1,
                      tt.attribute2, tt.attribute3, tt.attribute4, tt.attribute5,
                      tt.attribute6, tt.attribute7, tt.attribute8, tt.attribute9,
                      tt.attribute10, tt.attribute11, tt.attribute12,
                      tt.attribute13, tt.attribute14, tt.attribute15,
                      tt.process_flag, tt.process_message, tt.process_date,
                      tt.created_by, tt.creation_date, tt.last_updated_by,
                      tt.last_update_date, tt.comments, tt.process_flag12,
                      tt.process_message12, tt.process_date12, tt.receipt_date,
                      tt.chno, tt.bank_acc_id, tt.bank_acc_number, tt.bank_acc_name,
                      tt.doctype, tt.ref_receiptno, tt.ref_receiptdt,
                      tt.ref_doctype, tt.security_flag, tt.cons_type,
                      tt.cons_rcpt_no, tt.cheque_bounce_reason,
                      tt.receipt_method_id rcpt_id, tt.prov_recptdt rct_date,
                      tt.erp_customer_number cust_no, td1.bank_account_id,
                      td1.bank_acct_use_id, td3.NAME, td3.receipt_method_id,

      --                fv.meaning,
      --                xxa_hr_util.xxau_hr001_get_new_val_company (fv.attribute1)unit_code1,
                      gl.segment1 unit_code
                 FROM addb.addb_xxa_ar_trans_erp_rcpt tt,
                                                 --commented by Ankush Goel 19-04-21
      --           auerp.xxa_ar_trans_erp_rcpt tt, --commented by Ankush Goel 19-04-21
                      apps.ce_bank_acct_uses_all@hrtoebs td1,
                      apps.ar_receipt_method_accounts_all@hrtoebs td2,
                      apps.ar_receipt_methods@hrtoebs td3,
                      apps.gl_code_combinations@hrtoebs gl
      --                ,apps.fnd_lookup_values@hrtoebs fv
               WHERE  tt.bank_acc_id = td1.bank_account_id
                  AND td1.bank_acct_use_id = td2.remit_bank_acct_use_id
                  AND td2.receipt_method_id = td3.receipt_method_id
                  AND (    UPPER (td3.NAME) NOT LIKE '%CIR%'
                       AND UPPER (td3.NAME) NOT LIKE '%MISC%'
                       AND UPPER (td3.NAME) NOT LIKE '%HDFC_CMS%'
                       AND UPPER (td3.NAME) NOT LIKE '%TERM LOAN%'
                       AND UPPER (td3.NAME) NOT LIKE '%INT_SD_RECPT'
                      )
                  AND td1.org_id = td2.org_id
      --            AND fv.lookup_type = 'REVENUE CENTRE MASTER'
      --            AND tt.attribute4 = fv.lookup_code
                  AND td1.org_id = 288
                  AND td2.end_date IS NULL
                  AND td3.end_date IS NULL
                  --AND tt.receipt_number='BLY-1819-0000856'
                  AND NVL (process_flag, 'N') = 'N'
                  AND doctype = 'RCR'
                  AND td2.cash_ccid = gl.code_combination_id
                  AND gl.segment1 = NVL (p_unit1, gl.segment1)
                  AND NVL (security_flag, 'N') = 'N';*/

      --            AND td3.RECEIPT_METHOD_ID=1034;
      CURSOR c3 (p_receipt_id NUMBER)
      IS
         SELECT d.attribute_category, d.attribute14, d.attribute11
           FROM addb.addb_xxa_ar_trans_erp_rcpt d
          WHERE 1 = 1 AND d.composite_receipt_id = p_receipt_id;

      CURSOR ft_update
      IS
         (SELECT tt.composite_receipt_id, tt.ROWID row_id,
                 tt1.cash_receipt_id
            FROM addb.addb_xxa_ar_trans_erp_rcpt tt,
                 apps.ar_cash_receipts_all@hrtoebs tt1
           WHERE 1 = 1                        -----PROCESS_DATE>='27-oct-2021'
             AND TO_CHAR (tt.composite_receipt_id) = tt1.attribute1
             AND tt1.attribute9 = tt.receipt_number
             AND NVL (tt.process_flag, 'N') IN ('N', 'E'));

      l_return_status          VARCHAR2 (1);
      l_msg_count              NUMBER;
      l_msg_data               VARCHAR2 (4000)                         := NULL;
      l_cash_receipt_id        NUMBER;
      l_misc_receipt_id        NUMBER;
      l_error_mesg             VARCHAR2 (4000)                         := NULL;
      p_count                  NUMBER;
      v_rec_trx_id             NUMBER;
      lv_receipt_method_name   VARCHAR2 (80);
      ln_receipt_method_id     NUMBER                                     := 0;
      x_return_status          VARCHAR2 (30)                           := NULL;
      x_msg_count              NUMBER;
      x_msg_data               VARCHAR2 (4000)                         := NULL;
      p_cr_id                  NUMBER;
      p_misc_receipt_id        NUMBER;
      v_unit_name              VARCHAR2 (3);
      err                      VARCHAR2 (400);
      ebf                      NUMBER;
      p_attribute_rec_type     apps.ar_receipt_api_pub.attribute_rec_type@hrtoebs;
      v_receipt_no             VARCHAR2 (40)                           := NULL;
      v_return_status          VARCHAR2 (1);
      v_msg_count              NUMBER;
      v_msg_data               VARCHAR2 (2000);
      v_context                VARCHAR2 (2);
      i                        NUMBER;
      v_receipt_date           DATE;
      v_revers_date            DATE;
      v_check                  NUMBER                                     := 0;
   BEGIN
      -- DBMS_OUTPUT.put_line ('START');
      apps.fnd_global.apps_initialize@hrtoebs (2482, 52024, 222);
      apps.mo_global.set_policy_context@hrtoebs ('S', 288);
      apps.fnd_file.put_line@hrtoebs (fnd_file.output,
                                      'Table is empty successfully'
                                     );

      BEGIN
         UPDATE addb.addb_xxa_ar_trans_erp_rcpt
            SET process_message =
                   'Enter Manually for Payment refund this not a security Refund',
                process_flag = 'M'
          WHERE NVL (process_flag, 'N') IN ('N')
            AND doctype = 'RFD'
            AND security_flag = 'N';

         aucustom.xxses_debug_prc ('Update table process_flag M to - A ',
                                   'Update script S2'
                                  );
         COMMIT;
      END;

      BEGIN
         UPDATE addb.addb_xxa_ar_trans_erp_rcpt
            SET process_flag = 'N'
          WHERE NVL (process_flag, 'N') IN ('E')
            AND process_message =
                                'Related receipt is already reconciled in ERP';

         aucustom.xxses_debug_prc ('update table in process flag N to - B ',
                                   'Update scricpt S3'
                                  );
         COMMIT;
      END;

      BEGIN
         FOR ft IN ft_update
         LOOP
            UPDATE addb.addb_xxa_ar_trans_erp_rcpt
               SET process_flag = 'S',
                   process_message = 'SUCCESS-' || ft.cash_receipt_id,
                   process_date = SYSDATE,
                   process_message12 = 'Through Update Query'
             WHERE ROWID = ft.row_id
               AND composite_receipt_id = ft.composite_receipt_id;

            COMMIT;
         END LOOP;
      END;

      FOR unit_m IN unit (p_unit)
      LOOP
         aucustom.xxses_debug_prc ('Start c1');

         BEGIN
            FOR i IN c1 (unit_m.flex_value)
            LOOP
               l_msg_data := NULL;
               l_msg_count := NULL;
               l_return_status := NULL;
               l_cash_receipt_id := NULL;
               p_attribute_rec_type.attribute_category :=
                                                         i.attribute_category;
               aucustom.xxses_debug_prc
                          ('p_attribute_rec_type.attribute_category to - C ',
                           'i.attribute_category....' || i.attribute_category
                          );
               p_attribute_rec_type.attribute1 := i.composite_receipt_id;
               ---------------Reference ID
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute1 to - D ',
                                       'i.composite_receipt_id....'
                                    || i.composite_receipt_id
                                   );
               --p_attribute_rec_type.attribute2 := NVL (i.attribute2, 11);
               p_attribute_rec_type.attribute2 := NVL (i.attribute2, 5);
               -----------------Receipt type
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute2 to - E ',
                                    'i.attribute2....' || i.attribute2
                                   );
               p_attribute_rec_type.attribute3 := NVL (i.attribute3, 'N');
               --------------Dispaly
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute3 to - F ',
                                    'i.attribute3....' || i.attribute3
                                   );
               p_attribute_rec_type.attribute4 := NVL (i.attribute4, 'N');
               ---------------Covering
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute4 to - G ',
                                    'i.attribute4....' || i.attribute4
                                   );
               p_attribute_rec_type.attribute6 := NVL (i.attribute6, 'N');
               ------sgned
               p_attribute_rec_type.attribute5 := NVL (i.attribute5, 'N');
               ---------------stamped
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute5 to - I ',
                                    'i.attribute5....' || i.attribute5
                                   );
               p_attribute_rec_type.attribute10 := i.attribute12;
               p_attribute_rec_type.attribute11 := i.attribute13;
               ---------------bank Name
               --p_attribute_rec_type.attribute9 := i.attribute9;
               p_attribute_rec_type.attribute9 := i.attribute11;
																

               -------------------compisite_reference_dcr_receipt_no
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute9 to - J ',
                                    'i.attribute9....' || i.attribute9
                                   );
               --     p_attribute_rec_type.attribute11 := i.attribute11;
--               p_attribute_rec_type.attribute14 := i.attribute11; -- COMMENTED ON 30-SEP-2025 ON REQUEST OF NARESH JI (NO Validation Required for DCR Circulation Receipt Number)
                --p_attribute_rec_type.attribute13 := i.attribute11; --enabled ON 30-SEP-2025 ON REQUEST OF NARESH JI (NO Validation Required for DCR Circulation Receipt Number) it is IFSC Code
				p_attribute_rec_type.attribute13 := i.attribute13; 															 
               ---------pr receipt
               aucustom.xxses_debug_prc
                                  ('p_attribute_rec_type.attribute10 to - K ',
                                   'i.attribute11....' || i.attribute11
                                  );
               p_attribute_rec_type.attribute12 := i.attribute14;
               -----------------bank branch
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute8 to - L ',
                                    'i.attribute8....' || i.attribute8
                                   );
               p_attribute_rec_type.attribute15 := i.attribute15;
               -------------pr date
               aucustom.xxses_debug_prc
                                  ('p_attribute_rec_type.attribute15 to - N ',
                                   'i.attribute15....' || i.attribute15
                                  );

               IF i.attribute2 IN ('1', '10', '7')
               THEN
                  IF i.chno IS NULL
                  THEN
                     v_receipt_no := i.receipt_number;
                  ELSE
                     v_receipt_no := i.chno;
                  END IF;
               ELSE
                  v_receipt_no := i.receipt_number;
               END IF;

               IF p_date IS NULL
               THEN
                  ---- v_receipt_date := i.receipt_date;-------------for cio receipt not for DCR
                  v_receipt_date := TRUNC (SYSDATE);
               ELSE
                  --   v_receipt_date := p_date;-------------for cio receipt not for DCR
                  v_receipt_date := TRUNC (SYSDATE);
               END IF;

               IF i.party_number IS NOT NULL
               THEN
                  -- DBMS_OUTPUT.put_line ('party number not null ');
                  aucustom.xxses_debug_prc
                                      ('if party number is not null to - O ',
                                       'i.party_number....' || i.party_number
                                      );
                  apps.ar_receipt_api_pub.create_cash@hrtoebs
                                  (p_api_version               => 1.0,
                                   p_init_msg_list             => 'T',
                                   p_commit                    => 'F',
                                   p_validation_level          => 100,
                                   x_return_status             => l_return_status,
                                   x_msg_count                 => l_msg_count,
                                   x_msg_data                  => l_msg_data,
                                   p_currency_code             => 'INR',
                                   p_amount                    => i.party_amt,
                                   p_receipt_number            => v_receipt_no,
                                   p_receipt_date              => v_receipt_date,
                                   p_gl_date                   => v_receipt_date,
                                   p_comments                  => i.comments,
                                   p_attribute_rec             => p_attribute_rec_type,
                                   p_customer_number           => i.cust_no,
--                                  p_customer_number           => '110155',
                                   p_receipt_method_id         => i.receipt_method_id,
                                   p_cr_id                     => l_cash_receipt_id,
                                   p_global_attribute_rec      => NULL,
                                   p_org_id                    => 288
                                  );
               ELSIF i.party_number IS NULL
               -- Asked to gaurav for confirmation
               THEN
                  aucustom.xxses_debug_prc
                                          ('if party number is null to - P ',
                                              'i.party_number....'
                                           || i.party_number
                                          );
                  -- DBMS_OUTPUT.put_line ('party number null ');
                  apps.ar_receipt_api_pub.create_cash@hrtoebs
                                  (p_api_version               => 1.0,
                                   p_init_msg_list             => 'T',
                                   p_commit                    => 'T',
                                   p_validation_level          => 100,
                                   x_return_status             => l_return_status,
                                   x_msg_count                 => l_msg_count,
                                   x_msg_data                  => l_msg_data,
                                   p_currency_code             => 'INR',
                                   p_amount                    => i.party_amt,
                                   p_receipt_number            => v_receipt_no,
                                   p_receipt_date              => v_receipt_date,
                                   p_comments                  => i.comments,
                                   p_gl_date                   => v_receipt_date,
                                   p_attribute_rec             => p_attribute_rec_type,
                                   p_receipt_method_id         => i.receipt_method_id,
                                   p_cr_id                     => l_cash_receipt_id,
                                   p_global_attribute_rec      => NULL,
                                   p_org_id                    => 288
                                  );
               END IF;

--------------------------------------------------------
           -- DBMS_OUTPUT.put_line ('id  ' || l_cash_receipt_id);
               aucustom.xxses_debug_prc ('if case_receipt_id is null to - Q ',
                                            'l_cash_receipt_id....'
                                         || l_cash_receipt_id
                                        );

               IF l_cash_receipt_id IS NULL
               THEN
                  BEGIN
                     IF l_msg_count = 1
                     THEN
                        l_error_mesg := l_msg_data;
                        aucustom.xxses_debug_prc ('l_msg_data ' || l_msg_data);
                     ELSIF l_msg_count > 1
                     THEN
                        l_msg_data := NULL;

                        LOOP
                           p_count := p_count + 1;
                           l_msg_data := NULL;
                           l_msg_data := l_msg_data;

                           IF l_msg_data IS NULL
                           THEN
                              EXIT;
                           END IF;
                        END LOOP;

                        l_error_mesg := l_error_mesg || '-' || l_msg_data;
                        aucustom.xxses_debug_prc (   'Message'
                                                  || p_count
                                                  || '.'
                                                  || l_error_mesg
                                                 );
                     END IF;

                     aucustom.xxses_debug_prc
                                           ('if case_receipt_id null to - T ',
                                            l_error_mesg
                                           );   --'L_REC_CNT....'||L_REC_CNT);
                     aucustom.xxses_debug_prc ('COMP ID to - U',
                                               i.composite_receipt_id
                                              );
                     --'L_REC_CNT....'||L_REC_CNT);
                     aucustom.xxses_debug_prc ('Rcpt ID to - V ',
                                               i.receipt_number
                                              );
                     --'L_REC_CNT....'||L_REC_CNT);
                     aucustom.xxses_debug_prc ('srno ID to - W ',
                                               i.serial_number
                                              );

                     --'L_REC_CNT....'||L_REC_CNT);
                     UPDATE addb.addb_xxa_ar_trans_erp_rcpt d
                        SET d.process_flag = 'E',
                            d.process_message = l_error_mesg,
                            d.process_date = SYSDATE
                      WHERE d.composite_receipt_id = i.composite_receipt_id
                        AND d.receipt_number = i.receipt_number
                        AND d.doctype = 'RCR'
                        AND d.serial_number = i.serial_number;

                     COMMIT;
                     aucustom.xxses_debug_prc
                                    ('Error massage and message data to - X ',
                                     l_error_mesg || ',' || l_msg_data
                                    );
                  END;
               ELSE
                  BEGIN
                     UPDATE addb.addb_xxa_ar_trans_erp_rcpt d
                        SET d.process_flag = 'S',
                            d.process_message =
                                         'SUCCESS' || '-' || l_cash_receipt_id,
                            d.process_date = SYSDATE,
                            process_message12 = 'Through Update API'      ---,
                      --d.receipt_date = SYSDATE
                     WHERE  d.composite_receipt_id = i.composite_receipt_id
                        AND d.receipt_number = i.receipt_number
                        AND d.doctype = 'RCR'
                        AND d.serial_number = i.serial_number;

                     aucustom.xxses_debug_prc
                                           ('update table processflag to - Y',
                                            'S'
                                           );   --'L_REC_CNT....'||L_REC_CNT);
                     COMMIT;
                  END;
               END IF;
            END LOOP;
         END;
      END LOOP;

      BEGIN
         UPDATE addb.addb_xxa_ar_trans_erp_rcpt tt
            SET process_message =
                    'Dublicate because cheque number have two or more receipt',
                process_flag = 'N',
                chno = chno || '-D_' || SUBSTR (composite_receipt_id, -2, 2),
                process_date = SYSDATE
          WHERE tt.process_message =
                   'A cash receipt with this number, date, amount and customer already exists.'
            AND NOT EXISTS (
                   SELECT 'Y'
                     FROM ar_cash_receipts_all@hrtoebs
                    WHERE attribute1 = TO_CHAR (tt.composite_receipt_id)
                      AND receipt_date = tt.receipt_date
                      AND status NOT IN ('REV'));

         aucustom.xxses_debug_prc
            ('Duplicate record because of cheq number to - Z ',
             'A cash receipt with this number, date, amount and customer already exists.'
            );
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         UPDATE addb.addb_xxa_ar_trans_erp_rcpt tt
            SET process_message =
                      'SUCCESS'
                   || '-'
                   || (SELECT cash_receipt_id
                         FROM ar_cash_receipts_all@hrtoebs
                        WHERE attribute1 = TO_CHAR (tt.composite_receipt_id)
                          AND receipt_date = tt.receipt_date
                          AND status NOT IN ('REV')),
                process_flag = 'S',
                process_date = SYSDATE                                     --,
          -- receipt_date = SYSDATE
         WHERE  tt.process_message =
                   'A cash receipt with this number, date, amount and customer already exists.'
            AND EXISTS (
                   SELECT 'Y'
                     FROM ar_cash_receipts_all@hrtoebs
                    WHERE attribute1 = TO_CHAR (tt.composite_receipt_id)
                      AND receipt_date = tt.receipt_date
                      AND status NOT IN ('REV'));

         aucustom.xxses_debug_prc
            ('Duplicate record because of cheq number to - A1 ',
             'A cash receipt with this number, date, amount and customer already exists.'
            );
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         UPDATE addb.addb_xxa_ar_trans_erp_rcpt tt
            SET process_message =
                      'SUCCESS REVERS'
                   || '-'
                   || (SELECT cash_receipt_id
                         FROM ar_cash_receipts_all@hrtoebs
                        WHERE attribute1 = TO_CHAR (tt.composite_receipt_id)
                          AND status IN ('REV')),
                process_flag = 'S',
                process_date = SYSDATE                                   ----,
          --- receipt_date = SYSDATE
         WHERE  (   tt.process_message LIKE 'Invalid cash receipt identifier%'
                 OR tt.process_message IS NULL
                )
            AND EXISTS (
                   SELECT 'Y'
                     FROM ar_cash_receipts_all@hrtoebs
                    WHERE attribute1 = TO_CHAR (tt.composite_receipt_id)
                      AND status IN ('REV'));

         aucustom.xxses_debug_prc
                          ('Duplicate record because of cheq number to - A2 ',
                           'Invalid cash receipt identifier%'
                          );
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END xxa_ar_dcr_receipt_p3;

   PROCEDURE xxau_daily_4cplus_receipt_err (
      errbuf    OUT   VARCHAR2,
      retcode   OUT   NUMBER
   )
   IS
      CURSOR fetch_data
      IS
         (SELECT 'composite_receipt_id|party_number|party_name|party_location|receipt_number|receipt_date|chno|party_amt|CHECK_DESC|bank_acc_number|doctype|reeipt_revers_date|process_flag|process_message'
                                                                    AS data1
            FROM DUAL
          UNION ALL
          SELECT    composite_receipt_id
                 || '|'
                 || party_number
                 || '|'
                 || REPLACE (party_name, ',', '')
                 || '|'
                 || party_location
                 || '|'
                 || receipt_number
                 || '|'
                 || receipt_date
                 || '|'
                 || chno
                 || '|'
                 || party_amt
                 || '|'
                 || tt1.check_desc
                 || '|'
                 || bank_acc_number
                 || '|'
                 || doctype
                 || '|'
                 || ref_receiptdt
                 || '|'
                 || process_flag
                 || '|'
                 || process_message AS data1
            FROM auerp.xxa_ar_trans_erp_rcpt tt, check_local tt1
           WHERE NVL (process_flag, 'N') IN ('E', 'N')
             AND tt.attribute2 = tt1.check_type);

      l_request_id     NUMBER;
      lc_dir_name      VARCHAR2 (80);
      lc_file_name     VARCHAR2 (80);
      v_file           UTL_FILE.file_type;
      lc_mail_from     VARCHAR2 (200)
                                     := 'amarujalaadaccount@del.amarujala.com';
      l_subject        VARCHAR2 (250);
      l_subject_text   VARCHAR2 (250);
      l_errbuf         VARCHAR2 (2000);
      l_retcode        NUMBER;
      p_from_date      DATE;
      p_to_date        DATE;
      p_date           DATE;
      p_date1          VARCHAR2 (30);
      to_mail          VARCHAR2 (2000);
      mail_to_eng      VARCHAR2 (50);
      v_eng_count      NUMBER             := 0;
   BEGIN
      l_request_id := apps.fnd_global.conc_request_id@hrtoebs;

      BEGIN
         SELECT flv.description
           INTO lc_dir_name                                         --/var/tmp
           FROM apps.fnd_lookup_values_vl@hrtoebs flv
          WHERE flv.lookup_type = 'XXA_FILE_LOCATION'
            AND flv.lookup_code = 'AR-RECEIPT';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            -- FND_FILE.PUT_LINE(FND_FILE.LOG, 'The Diectory is not Correct');
            NULL;
      END;

      lc_file_name := NULL;
      -- File Name and  File Path
      lc_file_name :=
              'receipt_err_' || TO_CHAR (SYSDATE, 'DD-MM-YY_HH24:MI')
              || '.csv';
      v_file :=
         UTL_FILE.fopen (LOCATION          => lc_dir_name,
                         filename          => lc_file_name,
                         open_mode         => 'w',
                         max_linesize      => 32767
                        );
      mail_to_eng := '';
      v_eng_count := 0;

      FOR fetch2 IN fetch_data
      LOOP
         DBMS_OUTPUT.put_line (fetch2.data1);
         UTL_FILE.put_line (v_file, fetch2.data1);
      END LOOP;

      UTL_FILE.fclose (v_file);
      l_subject_text :=
                     'Receipt Error (4cplus)' || TO_CHAR (SYSDATE, 'DD_MM_YY');
      l_subject :=
            'Please Find error detials in 4cplus receipt -'
         || TO_CHAR (SYSDATE, 'DD_MM_YY');
      to_mail := NULL;

      BEGIN
         xxa_email_pkg.send_email_attachment
            (errbuf           => l_errbuf,
             retcode          => l_retcode,
             p_file_name      => lc_file_name,
             p_dir_name       => 'XXA_SMTP_MAIL',
             p_email_frm      => lc_mail_from,
             p_email_to       => 'erpsupport@itsyoko.com;ompal@bs.amarujala.com;ansulg@bs.amarujala.com;Nareshr@mrt.amarujala.com;sudhanshub@mrt.amarujala.com;harshs@mrt.amarujala.com;BRS_AUL@AMARUJALA.COM',
                                                                 -----to_mail||';
                 ---'vinaysheel@del.amarujala.com',--'Monikak@del.amarujala.com',
             --P_EMAIL_TO  => 'adknack@rediffmail.com;monikak@del.amarujala.com;nat-adaccounts@del.amarujala.com;amarujalapublications2013@gmail.com;moaz.ahmad@pathinfotech.com',
             --P_EMAIL_TO  => 'adknack06@gmail.com;adknackdel@gmail.com;monikak@del.amarujala.com;moaz.ahmad@pathinfotech.com',
             p_subject        => l_subject_text,
             --'Please find attached the MRV Data for Customer ' ||CUST.inv_ins_code,
             p_msg_body       => l_subject
            );
      EXCEPTION
         WHEN OTHERS
         THEN
            xxa_email_pkg.send_email_attachment
                               (errbuf           => l_errbuf,
                                retcode          => l_retcode,
                                p_file_name      => lc_file_name,
                                p_dir_name       => 'XXA_SMTP_MAIL',
                                p_email_frm      => lc_mail_from,
                                p_email_to       => 'erpsupport@itsyoko.com',
                                --'vinaysheel@del.amarujala.com',
                                p_subject        =>    'Error '
                                                    || l_subject_text
                                                    || TRUNC (SYSDATE),
                                p_msg_body       =>    'Receipt In Error (4CPLUS):'
                                                    || TRUNC (SYSDATE)
                               );
      END;                                                     ---- main _unit
   END xxau_daily_4cplus_receipt_err;

   PROCEDURE xxau_create_ar_cm_dm_cio (
      errbuff   OUT      NUMBER,
      retcode   OUT      NUMBER,
      p_unit    IN       VARCHAR2 DEFAULT NULL
   )
   IS
      l_batch_source_id        NUMBER;
      l_cust_trx_type_id       NUMBER;
      l_bill_to_cust_id        NUMBER;
      l_ship_to_cust_id        NUMBER;
      l_ship_to_site_use_id    NUMBER;
      l_bill_to_site_use_id    NUMBER;
      l_ccid                   NUMBER;
      l_inv_item_id            NUMBER;
      trx_header_id_v          NUMBER;
      trx_line_id_v            NUMBER;
      trx_dist_id_v            NUMBER;
      l_count                  NUMBER;
      l_return_status          VARCHAR2 (1);
      l_msg_count              NUMBER;
      l_msg_data               VARCHAR2 (2000);
      l_error_msg              VARCHAR2 (2000);
      l_cust_trx_id            NUMBER;
      l_trx_num                VARCHAR2 (20);
      l_length                 NUMBER;
      l_batch_source_rec       ar_invoice_api_pub.batch_source_rec_type@hrtoebs;
      l_trx_header_tbl         ar_invoice_api_pub.trx_header_tbl_type@hrtoebs;
      l_trx_lines_tbl          ar_invoice_api_pub.trx_line_tbl_type@hrtoebs;
      l_trx_dist_tbl           ar_invoice_api_pub.trx_dist_tbl_type@hrtoebs;
      l_trx_salescredits_tbl   ar_invoice_api_pub.trx_salescredits_tbl_type@hrtoebs;

      CURSOR cheader (p_unit1 VARCHAR2)
      IS
         SELECT   (SELECT operating_unit
                     FROM apps.org_organization_definitions@hrtoebs
                    WHERE organization_code = gl.segment1) operating_unit,
                  (SELECT organization_id
                     FROM apps.org_organization_definitions@hrtoebs
                    WHERE organization_code = gl.segment1) organization_id,
                  tt.composite_receipt_id header_number, 1 line_number,
                  ('MANUAL-OTHER') trx_source,
                  (SELECT NAME
                     FROM apps.ra_cust_trx_types_all@hrtoebs rctt,
                          gl_code_combinations@hrtoebs gl2
                    WHERE rctt.org_id =
                             (SELECT operating_unit
                                FROM apps.org_organization_definitions@hrtoebs
                               WHERE organization_code = gl.segment1)
                      AND rctt.TYPE = 'INV'
                      AND rctt.NAME LIKE '%RFD%CIO%'
                      AND rctt.gl_id_rec = gl2.code_combination_id
                      AND gl2.segment1 = gl.segment1) cust_trx_type,
                  'INR' trx_currency,
                  (SELECT customer_number
                     FROM ar_customers
                    WHERE customer_name =
                                       'Advt - Customer')
                                                        bill_to_customer_num,
                  tt.receipt_date orig_inv_date,
                  tt.receipt_date orig_gl_date,
                  NVL (tt.comments,
                       'Payment Refund From CIO'
                      ) header_description,
                  1 quantity_invoiced,
                  (-1 * tt.party_amt) unit_selling_price,
                     'Payment Refund From CIO-'
                  || tt.receipt_number line_description,
                  tt.receipt_number orig_inv_num, tt.composite_receipt_id,
                  tt.party_number, tt.party_name, tt.party_location,
                  td1.bank_account_id, td1.bank_acct_use_id, td3.NAME,
                  td3.receipt_method_id, fv.meaning,
                  xxa_hr_util.xxau_hr001_get_new_val_company
                                                    (fv.attribute1)
                                                                  unit_code1,
                  gl.segment1 unit_code
             FROM auerp.xxa_ar_trans_erp_rcpt tt,
                  apps.ce_bank_acct_uses_all@hrtoebs td1,
                  apps.ar_receipt_method_accounts_all@hrtoebs td2,
                  apps.ar_receipt_methods@hrtoebs td3,
                  apps.gl_code_combinations@hrtoebs gl,
                  apps.fnd_lookup_values@hrtoebs fv
            WHERE tt.bank_acc_id = td1.bank_account_id
              AND td1.bank_acct_use_id = td2.remit_bank_acct_use_id
              AND td2.receipt_method_id = td3.receipt_method_id
              AND (    UPPER (td3.NAME) NOT LIKE '%CIR%'
                   AND UPPER (td3.NAME) NOT LIKE '%MISC%'
                   AND UPPER (td3.NAME) NOT LIKE '%HDFC_CMS%'
                   AND UPPER (td3.NAME) NOT LIKE '%TERM LOAN%'
                   AND UPPER (td3.NAME) NOT LIKE '%INT_SD_RECPT'
                  )
              AND td1.org_id = td2.org_id
              AND td1.org_id = 288
              -- AND tt.receipt_number = 'RFD-MRD-21080001'
              AND NVL (process_flag, 'N') IN ('N', 'M')
              AND tt.receipt_date >= '1-aug-2021'
              AND doctype IN ('RFD')
              AND td2.end_date IS NULL
              AND td3.end_date IS NULL
              AND fv.lookup_type = 'REVENUE CENTRE MASTER'
              AND tt.attribute4 = fv.lookup_code
              --  AND gl.segment1 =
                    ---    xxa_hr_util.xxau_hr001_get_new_val_company (fv.attribute1)
              AND td2.cash_ccid = gl.code_combination_id
              AND gl.segment1 = NVL (p_unit1, gl.segment1)
              AND NVL (security_flag, 'N') = 'N'
         --AND line_number = '1'
         ORDER BY tt.composite_receipt_id;

      CURSOR clines (l_header_num NUMBER, p_unit1 VARCHAR2)
      IS
         SELECT (SELECT operating_unit
                   FROM apps.org_organization_definitions@hrtoebs
                  WHERE organization_code = gl.segment1) operating_unit,
                (SELECT organization_id
                   FROM apps.org_organization_definitions@hrtoebs
                  WHERE organization_code = gl.segment1) organization_id,
                tt.composite_receipt_id header_number, 1 line_number,
                ('MANUAL-OTHER') trx_source,
                (SELECT NAME
                   FROM apps.ra_cust_trx_types_all@hrtoebs rctt,
                        gl_code_combinations@hrtoebs gl2
                  WHERE rctt.org_id =
                           (SELECT operating_unit
                              FROM apps.org_organization_definitions@hrtoebs
                             WHERE organization_code = gl.segment1)
                    AND rctt.TYPE = 'INV'
                    AND rctt.NAME LIKE '%RFD%CIO%'
                    AND rctt.gl_id_rec = gl2.code_combination_id
                    AND gl2.segment1 = gl.segment1) cust_trx_type,
                'INR' trx_currency,
                (SELECT customer_number
                   FROM ar_customers
                  WHERE customer_name =
                                       'Advt - Customer')
                                                         bill_to_customer_num,
                tt.receipt_date orig_inv_date, tt.receipt_date orig_gl_date,
                NVL (tt.comments,
                     'Payment Refund From CIO'
                    ) header_description,
                1 quantity_invoiced, (-1 * tt.party_amt) unit_selling_price,
                   'Payment Refund From CIO-'
                || tt.receipt_number line_description,
                tt.receipt_number orig_inv_num, tt.composite_receipt_id,
                tt.party_number, tt.party_name, tt.party_location,
                td1.bank_account_id, td1.bank_acct_use_id, td3.NAME,
                td3.receipt_method_id, fv.meaning,
                xxa_hr_util.xxau_hr001_get_new_val_company
                                                    (fv.attribute1)
                                                                   unit_code1,
                gl.segment1 unit_code
           FROM auerp.xxa_ar_trans_erp_rcpt tt,
                apps.ce_bank_acct_uses_all@hrtoebs td1,
                apps.ar_receipt_method_accounts_all@hrtoebs td2,
                apps.ar_receipt_methods@hrtoebs td3,
                apps.gl_code_combinations@hrtoebs gl,
                apps.fnd_lookup_values@hrtoebs fv
          WHERE tt.bank_acc_id = td1.bank_account_id
            AND td1.bank_acct_use_id = td2.remit_bank_acct_use_id
            AND td2.receipt_method_id = td3.receipt_method_id
            AND (    UPPER (td3.NAME) NOT LIKE '%CIR%'
                 AND UPPER (td3.NAME) NOT LIKE '%MISC%'
                 AND UPPER (td3.NAME) NOT LIKE '%HDFC_CMS%'
                 AND UPPER (td3.NAME) NOT LIKE '%TERM LOAN%'
                 AND UPPER (td3.NAME) NOT LIKE '%INT_SD_RECPT'
                )
            AND td1.org_id = td2.org_id
            AND td1.org_id = 288
            AND NVL (process_flag, 'N') IN ('N', 'M')
            AND tt.receipt_date >= '1-aug-2021'
            AND doctype IN ('RFD')
            AND td2.end_date IS NULL
            AND td3.end_date IS NULL
            AND fv.lookup_type = 'REVENUE CENTRE MASTER'
            AND tt.attribute4 = fv.lookup_code
            --  AND gl.segment1 =
                  ---    xxa_hr_util.xxau_hr001_get_new_val_company (fv.attribute1)
            AND td2.cash_ccid = gl.code_combination_id
            AND gl.segment1 = NVL (p_unit1, gl.segment1)
            AND NVL (security_flag, 'N') = 'N'
            AND tt.composite_receipt_id = l_header_num;
   BEGIN
      mo_global.init@hrtoebs ('AR');
      mo_global.set_policy_context@hrtoebs ('S', 288);
      fnd_global.apps_initialize@hrtoebs (user_id           => 1455,
                                          resp_id           => 51988,
                                          resp_appl_id      => 222
                                         );

      FOR vheader IN cheader (p_unit)
      LOOP
         trx_header_id_v := NULL;
         l_batch_source_id := NULL;
         l_cust_trx_type_id := NULL;
         l_bill_to_cust_id := NULL;
         l_ship_to_cust_id := NULL;
         l_bill_to_site_use_id := NULL;
         l_ship_to_site_use_id := NULL;
         l_error_msg := NULL;

         BEGIN
            SELECT batch_source_id
              INTO l_batch_source_id
              FROM ra_batch_sources_all@hrtoebs rbsa,
                   hr_operating_units@hrtoebs hou
             WHERE rbsa.org_id = hou.organization_id
               AND rbsa.NAME = vheader.trx_source
               AND hou.organization_id = vheader.operating_unit;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error_msg :=
                     vheader.trx_source
                  || '-Invalid Transaction source'
                  || ' For Header Number- '
                  || vheader.header_number;
         --- fnd_file.put_line(fnd_file.log,l_error_msg);
         END;

         BEGIN
            SELECT cust_trx_type_id
              INTO l_cust_trx_type_id
              FROM ra_cust_trx_types_all@hrtoebs rcta,
                   hr_operating_units@hrtoebs hou
             WHERE rcta.org_id = hou.organization_id
               AND rcta.NAME = vheader.cust_trx_type
               AND hou.organization_id = vheader.operating_unit;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error_msg :=
                     vheader.cust_trx_type
                  || '-Invalid Customer Transaction Type'
                  || ' For Header Number- '
                  || vheader.header_number;
         --- fnd_file.put_line(fnd_file.log,l_error_msg);
         END;

         BEGIN
            SELECT cust_account_id
              INTO l_bill_to_cust_id
              FROM hz_cust_accounts@hrtoebs
             WHERE account_number = TO_CHAR (vheader.bill_to_customer_num);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error_msg :=
                     vheader.bill_to_customer_num
                  || '-Invalid Bill to Customer Number'
                  || ' For Header Number- '
                  || vheader.header_number;
         --- fnd_file.put_line(fnd_file.log,l_error_msg);
         END;

         BEGIN
            SELECT hcsu.site_use_id
              INTO l_bill_to_site_use_id
              FROM hz_parties@hrtoebs hp,
                   hz_cust_accounts@hrtoebs hca,
                   hz_cust_acct_sites_all@hrtoebs hcas,
                   hz_cust_site_uses_all@hrtoebs hcsu,
                   hz_party_sites@hrtoebs hps,
                   hz_locations@hrtoebs hl                                 --,
             --- hr_operating_units@hrtoebs hou
            WHERE  1 = 1
               AND hca.party_id = hp.party_id
               AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
               AND hca.cust_account_id = l_bill_to_cust_id
               AND hca.cust_account_id = hcas.cust_account_id
               AND hcas.party_site_id = hps.party_site_id
               AND hps.location_id = hl.location_id
               AND hcsu.site_use_code = 'BILL_TO'
               AND hcsu.primary_flag = 'Y'
               ---AND hca.account_number=vHeader.BILL_TO_CUSTOMER_NUM
               --AND hcsu.location = vHeader.bill_to_location
               AND hcsu.org_id = 288
               ---AND hou.organization_id = vHeader.operating_unit
               AND hca.status = 'A'
               AND hcsu.status = 'A';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error_msg :=
                     vheader.bill_to_customer_num
                  || '-Invalid Bill to Location'
                  || ' For Header Number- '
                  || vheader.header_number;
         --fnd_file.put_line(fnd_file.log,l_error_msg);
         END;

         /* BEGIN

          SELECT hcsu.site_use_id
            INTO l_ship_to_site_use_id
            FROM hz_parties hp,
                 hz_cust_accounts hca,
                 hz_cust_acct_sites_all hcas,
                 hz_cust_site_uses_all hcsu,
                 hz_party_sites hps,
                 hz_locations hl,
                 hr_operating_units hou
           WHERE  1 = 1
             AND hca.party_id = hp.party_id
             AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
             AND hca.cust_account_id = l_ship_to_cust_id
             AND hca.cust_account_id = hcas.cust_account_id
             AND hcas.party_site_id = hps.party_site_id
             AND hps.location_id = hl.location_id
             and hcsu.site_use_code = 'BILL_TO'
              AND hcsu.PRIMARY_FLAG='Y'
             ---AND hcsu.location = vHeader.ship_to_location
             AND hcsu.org_id = 101-----hou.organization_id
             --AND hou.organization_id = vHeader.operating_unit
             AND hca.status = 'A'
             AND hcsu.status = 'A';

             EXCEPTION
             when others then
             l_error_msg := vHeader.ship_to_location|| '-Invalid ship to Location'||' For Header Number- '||vHeader.header_number;
            --- fnd_file.put_line(fnd_file.log,l_error_msg);

          END;*/
         SELECT ra_customer_trx_s.NEXTVAL@hrtoebs
           INTO trx_header_id_v
           FROM DUAL;

         l_batch_source_rec.batch_source_id := l_batch_source_id;
         l_trx_header_tbl (1).trx_header_id := trx_header_id_v;
         l_trx_header_tbl (1).trx_date := vheader.orig_inv_date;
         l_trx_header_tbl (1).gl_date := vheader.orig_gl_date;
         l_trx_header_tbl (1).trx_currency := vheader.trx_currency;
         l_trx_header_tbl (1).bill_to_customer_id := l_bill_to_cust_id;
         l_trx_header_tbl (1).bill_to_site_use_id := l_bill_to_site_use_id;
         -- l_trx_header_tbl(1).ship_to_customer_id             := l_ship_to_cust_id;
         -- l_trx_header_tbl(1).ship_to_site_use_id             := l_ship_to_site_use_id;
         l_trx_header_tbl (1).cust_trx_type_id := l_cust_trx_type_id;
         l_trx_header_tbl (1).reference_number := vheader.orig_inv_num;
         l_trx_header_tbl (1).comments := vheader.header_description;
         l_trx_header_tbl (1).term_id := 5;       -------------------IMMEDIATE
         l_trx_header_tbl (1).interface_header_attribute1 :=
                                                          vheader.orig_inv_num;
       -- l_trx_header_tbl(1).status_trx                      := 'OP';
       -- l_trx_header_tbl(1).printing_option                 := 'PRI';
--        l_trx_header_tbl(1).attribute6                      := '-1';
--        l_trx_header_tbl(1).attribute_category              := 'INVOICE LC/INFO';
--        l_trx_header_tbl(1).attribute7                      := NULL;
         l_trx_header_tbl (1).attribute1 := vheader.composite_receipt_id;

--l_trx_header_tbl(1).attribute2                      := vHeader.srv_number;
--l_trx_header_tbl(1).attribute3                     := vHeader.srv_number;
--        l_trx_header_tbl(1).attribute4                      := to_char(vHeader.srv_date,'YYYY/MM/DD');
--        l_trx_header_tbl(1).interface_header_attribute10    := vHeader.organization_id;
--        l_trx_header_tbl(1).purchase_order                  := vHeader.other_info;
         FOR vlines IN clines (vheader.header_number, p_unit)
         LOOP
            trx_line_id_v := NULL;
            trx_dist_id_v := NULL;
            l_ccid := NULL;
            l_inv_item_id := NULL;

            /*BEGIN

                SELECT  code_combination_id
                INTO  l_ccid
                FROM  gl_code_combinations_kfv
                WHERE  concatenated_segments = TRIM(vLines.account);

            EXCEPTION
                when others then
                l_error_msg := vLines.account|| '-Invalid Revenue Account'||' For Header Number- '||vHeader.header_number||' and Line Number- '||vLines.Line_number;
               --- fnd_file.put_line(fnd_file.log,l_error_msg);

            END;*/

            /*BEGIN

                SELECT  inventory_item_id
                INTO  l_inv_item_id
                FROM  mtl_system_items_b
                WHERE  organization_id = vLines.organization_id
                AND  segment1 = TRIM(vLines.inventory_item);

            EXCEPTION
                when others then
                l_error_msg := vLines.inventory_item|| '-Invalid Inventory Item'||' For Header Number- '||vHeader.header_number||' and Line Number- '||vLines.Line_number;
               --- fnd_file.put_line(fnd_file.log,l_error_msg);

            END;*/
            SELECT ra_customer_trx_lines_s.NEXTVAL@hrtoebs
              INTO trx_line_id_v
              FROM DUAL;

            -- SELECT RA_CUST_TRX_LINE_GL_DIST_S.NEXTVAL INTO trx_dist_id_v FROM DUAL;
            l_trx_lines_tbl (vlines.line_number).trx_header_id :=
                                                               trx_header_id_v;
            l_trx_lines_tbl (vlines.line_number).trx_line_id := trx_line_id_v;
            --l_trx_lines_tbl (vlines.line_number).reason_code := 'WAIVE OFF';----use in credit not
            l_trx_lines_tbl (vlines.line_number).line_number :=
                                                            vlines.line_number;
            --l_trx_lines_tbl(vLines.line_number).inventory_item_id  := l_inv_item_id;
            l_trx_lines_tbl (vlines.line_number).description :=
                                                       vlines.line_description;
            l_trx_lines_tbl (vlines.line_number).quantity_invoiced :=
                                                      vlines.quantity_invoiced;
            l_trx_lines_tbl (vlines.line_number).amount :=
                                                     vlines.unit_selling_price;
            l_trx_lines_tbl (vlines.line_number).unit_selling_price :=
                                                     vlines.unit_selling_price;
            l_trx_lines_tbl (vlines.line_number).line_type := 'LINE';
--        l_trx_dist_tbl(vLines.line_number).trx_header_id       := trx_header_id_v;
--        l_trx_dist_tbl(vLines.line_number).trx_line_id         := trx_line_id_v ;
--        l_trx_dist_tbl(vLines.line_number).trx_dist_id         := trx_dist_id_v ;
--        l_trx_dist_tbl(vLines.line_number).account_class       := 'REV';
--        l_trx_dist_tbl(vLines.line_number).percent             := 100 ;
--        l_trx_dist_tbl(vLines.line_number).code_combination_id := l_ccid;
         END LOOP;

         ar_invoice_api_pub.create_single_invoice@hrtoebs
                            (p_api_version               => 1.0,
                             p_init_msg_list             => 'F',
                             p_commit                    => 'F',
                             p_batch_source_rec          => l_batch_source_rec,
                             p_trx_header_tbl            => l_trx_header_tbl,
                             p_trx_lines_tbl             => l_trx_lines_tbl,
                             p_trx_dist_tbl              => l_trx_dist_tbl,
                             p_trx_salescredits_tbl      => l_trx_salescredits_tbl,
                             x_customer_trx_id           => l_cust_trx_id,
                             x_return_status             => l_return_status,
                             x_msg_count                 => l_msg_count,
                             x_msg_data                  => l_msg_data
                            );

         IF l_return_status = 'E' OR l_return_status = 'U'
         THEN
            --- fnd_file.put_line(fnd_file.log,'API Error- unexpected errors found!');
            UPDATE auerp.xxa_ar_trans_erp_rcpt
               SET process_flag = 'E',
                   process_message = l_msg_data,
                   process_date = SYSDATE
             WHERE composite_receipt_id = vheader.header_number;
         ELSE
            SELECT COUNT (*)
              INTO l_count
              FROM ar_trx_errors_gt@hrtoebs
             WHERE error_message IS NOT NULL;

            IF l_count > 0
            THEN
               BEGIN
                  l_error_msg := NULL;

                  FOR fet IN (SELECT error_message
                                INTO l_error_msg
                                FROM ar_trx_errors_gt@hrtoebs
                               WHERE error_message IS NOT NULL)
                  LOOP
                     l_error_msg := l_error_msg || fet.error_message;
                  END LOOP;

                  UPDATE auerp.xxa_ar_trans_erp_rcpt
                     SET process_flag = 'E',
                         process_message = l_error_msg,
                         process_date = SYSDATE
                   WHERE composite_receipt_id = vheader.header_number;
               --- fnd_file.put_line(fnd_file.log,'API Error- '||l_error_msg);
               END;
            ELSE
               SELECT trx_number
                 INTO l_trx_num
                 FROM ar_trx_header_gt@hrtoebs
                WHERE customer_trx_id = l_cust_trx_id;

               UPDATE auerp.xxa_ar_trans_erp_rcpt
                  SET process_flag = 'S',
                      process_message = 'SUCCESS - ' || l_cust_trx_id,
                      process_message12 = l_trx_num,
                      process_date = SYSDATE
                WHERE composite_receipt_id = vheader.header_number;
            END IF;
         END IF;
      END LOOP;

      -- COMMIT;
      BEGIN
         aucustom.xxau_auto_mail_rfd_cio;
      END;
   END xxau_create_ar_cm_dm_cio;

   PROCEDURE xxau_create_ar_ajd_ajc_cio (
      errbuff   OUT      NUMBER,
      retcode   OUT      NUMBER,
      p_unit    IN       VARCHAR2 DEFAULT NULL,
      p_month   IN       VARCHAR2
   )
   IS
      l_batch_source_id        NUMBER;
      l_cust_trx_type_id       NUMBER;
      l_bill_to_cust_id        NUMBER;
      l_ship_to_cust_id        NUMBER;
      l_ship_to_site_use_id    NUMBER;
      l_bill_to_site_use_id    NUMBER;
      l_ccid                   NUMBER;
      l_inv_item_id            NUMBER;
      trx_header_id_v          NUMBER;
      trx_line_id_v            NUMBER;
      trx_dist_id_v            NUMBER;
      l_count                  NUMBER;
      l_return_status          VARCHAR2 (1);
      l_msg_count              NUMBER;
      l_msg_data               VARCHAR2 (2000);
      l_error_msg              VARCHAR2 (2000);
      l_cust_trx_id            NUMBER;
      l_trx_num                VARCHAR2 (20);
      l_length                 NUMBER;
      l_batch_source_rec       ar_invoice_api_pub.batch_source_rec_type@hrtoebs;
      l_trx_header_tbl         ar_invoice_api_pub.trx_header_tbl_type@hrtoebs;
      l_trx_lines_tbl          ar_invoice_api_pub.trx_line_tbl_type@hrtoebs;
      l_trx_dist_tbl           ar_invoice_api_pub.trx_dist_tbl_type@hrtoebs;
      l_trx_salescredits_tbl   ar_invoice_api_pub.trx_salescredits_tbl_type@hrtoebs;

      CURSOR cheader (p_unit1 VARCHAR2, p_month1 VARCHAR2)
      IS
         SELECT (SELECT operating_unit
                   FROM apps.org_organization_definitions@hrtoebs
                  WHERE organization_code = flv.tag) operating_unit,
                (SELECT organization_id
                   FROM apps.org_organization_definitions@hrtoebs
                  WHERE organization_code = flv.tag) organization_id,
                   tt.revenue_centre_id
                || TO_CHAR (invoice_date, 'ddmm') header_number,
                line_num line_number, ('MANUAL-OTHER') trx_source,
                (SELECT NAME
                   FROM apps.ra_cust_trx_types_all@hrtoebs rctt,
                        gl_code_combinations@hrtoebs gl2
                  WHERE rctt.org_id =
                           (SELECT operating_unit
                              FROM apps.org_organization_definitions@hrtoebs
                             WHERE organization_code = flv.tag)
                    AND rctt.TYPE =
                           DECODE (tt.invoice_type,
                                   'AJD', 'INV',
                                   'AJC', 'CM'
                                  )
                    AND rctt.NAME LIKE
                              '%'
                           || DECODE (tt.invoice_type,
                                      'AJD', 'Rec/CM_W/off-CIO',
                                      'AJC', 'Inv_W/off-CIO'
                                     )
                    AND rctt.gl_id_rec = gl2.code_combination_id
                    AND gl2.segment1 = flv.tag) cust_trx_type,
                'INR' trx_currency,
                (SELECT customer_number
                   FROM ar_customers
                  WHERE customer_name =
                                       'Advt - Customer')
                                                        bill_to_customer_num,
                tt.invoice_date orig_inv_date, tt.gl_date orig_gl_date,
                NVL (tt.revenue_description,
                     'Payment Refund From CIO'
                    ) header_description,
                1 quantity_invoiced, (tt.total_amount) unit_selling_price,
                   tt.invoice_type
                || ' From CIO-'
                || tt.revenue_description line_description,
                   tt.revenue_centre_id
                || invoice_type
                || invoice_date
                || total_amount orig_inv_num,
                   tt.revenue_centre_id
                || TO_CHAR (invoice_date, 'ddmm') composite_receipt_id,
                flv.tag unit_code, tt.invoice_type
           FROM xxa_ar_trans_erp_bills tt,
                apps.fnd_lookup_values_vl@hrtoebs flv
          WHERE tt.invoice_date >= '1-jul-2021'
            AND tt.invoice_type IN ('AJD', 'AJC')
            AND tt.revenue_centre_id = flv.lookup_code
            AND flv.lookup_type = 'REVENUE_CENTRE_SUM'
            AND flv.tag = NVL (p_unit1, flv.tag)
            AND tt.process_status_flag IN ('N', 'H')
            AND tt.MONTH = p_month1
                                   --AND tt.revenue_centre_id=1
      ;

      CURSOR clines (
         l_header_num   NUMBER,
         p_unit1        VARCHAR2,
         p_month1       VARCHAR2,
         p_type         VARCHAR2,
         p_inv_num      VARCHAR2
      )
      IS
         SELECT (SELECT operating_unit
                   FROM apps.org_organization_definitions@hrtoebs
                  WHERE organization_code = flv.tag) operating_unit,
                (SELECT organization_id
                   FROM apps.org_organization_definitions@hrtoebs
                  WHERE organization_code = flv.tag) organization_id,
                   tt.revenue_centre_id
                || TO_CHAR (invoice_date, 'ddmm') header_number,
                line_num line_number, ('MANUAL-OTHER') trx_source,
                (SELECT NAME
                   FROM apps.ra_cust_trx_types_all@hrtoebs rctt,
                        gl_code_combinations@hrtoebs gl2
                  WHERE rctt.org_id =
                           (SELECT operating_unit
                              FROM apps.org_organization_definitions@hrtoebs
                             WHERE organization_code = flv.tag)
                    AND rctt.TYPE =
                           DECODE (tt.invoice_type,
                                   'AJD', 'INV',
                                   'AJC', 'CM'
                                  )
                    AND rctt.NAME LIKE
                              '%'
                           || DECODE (tt.invoice_type,
                                      'AJD', 'Rec/CM_W/off-CIO',
                                      'AJC', 'Inv_W/off-CIO'
                                     )
                    AND rctt.gl_id_rec = gl2.code_combination_id
                    AND gl2.segment1 = flv.tag) cust_trx_type,
                'INR' trx_currency,
                (SELECT customer_number
                   FROM ar_customers
                  WHERE customer_name =
                                       'Advt - Customer')
                                                         bill_to_customer_num,
                tt.invoice_date orig_inv_date, tt.gl_date orig_gl_date,
                NVL (tt.revenue_description,
                     'Payment Refund From CIO'
                    ) header_description,
                1 quantity_invoiced, (tt.total_amount) unit_selling_price,
                   tt.invoice_type
                || ' From CIO-'
                || tt.revenue_description line_description,
                   tt.revenue_centre_id
                || invoice_type
                || invoice_date
                || total_amount orig_inv_num,
                   tt.revenue_centre_id
                || TO_CHAR (invoice_date, 'ddmm') composite_receipt_id,
                flv.tag unit_code, tt.invoice_type
           FROM xxa_ar_trans_erp_bills tt,
                apps.fnd_lookup_values_vl@hrtoebs flv
          WHERE tt.invoice_date >= '1-jul-2021'
            AND tt.invoice_type IN ('AJD', 'AJC')
            AND tt.invoice_type = p_type
            AND    tt.revenue_centre_id
                || invoice_type
                || invoice_date
                || total_amount = p_inv_num
            AND tt.revenue_centre_id = flv.lookup_code
            AND flv.lookup_type = 'REVENUE_CENTRE_SUM'
            AND flv.tag = NVL (p_unit1, flv.tag)
            AND tt.revenue_centre_id || TO_CHAR (tt.invoice_date, 'ddmm') =
                                                                  l_header_num
            AND tt.process_status_flag IN ('N', 'H')
            AND tt.MONTH = p_month1;
   BEGIN
      mo_global.init@hrtoebs ('AR');
      mo_global.set_policy_context@hrtoebs ('S', 288);
      fnd_global.apps_initialize@hrtoebs (user_id           => 1455,
                                          resp_id           => 51988,
                                          resp_appl_id      => 222
                                         );

      FOR vheader IN cheader (p_unit, p_month)
      LOOP
         trx_header_id_v := NULL;
         l_batch_source_id := NULL;
         l_cust_trx_type_id := NULL;
         l_bill_to_cust_id := NULL;
         l_ship_to_cust_id := NULL;
         l_bill_to_site_use_id := NULL;
         l_ship_to_site_use_id := NULL;
         l_error_msg := NULL;

         BEGIN
            SELECT batch_source_id
              INTO l_batch_source_id
              FROM ra_batch_sources_all@hrtoebs rbsa,
                   hr_operating_units@hrtoebs hou
             WHERE rbsa.org_id = hou.organization_id
               AND rbsa.NAME = vheader.trx_source
               AND hou.organization_id = vheader.operating_unit;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error_msg :=
                     vheader.trx_source
                  || '-Invalid Transaction source'
                  || ' For Header Number- '
                  || vheader.header_number;
         --- fnd_file.put_line(fnd_file.log,l_error_msg);
         END;

         BEGIN
            SELECT cust_trx_type_id
              INTO l_cust_trx_type_id
              FROM ra_cust_trx_types_all@hrtoebs rcta,
                   hr_operating_units@hrtoebs hou
             WHERE rcta.org_id = hou.organization_id
               AND rcta.NAME = vheader.cust_trx_type
               AND hou.organization_id = vheader.operating_unit;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error_msg :=
                     vheader.cust_trx_type
                  || '-Invalid Customer Transaction Type'
                  || ' For Header Number- '
                  || vheader.header_number;
         --- fnd_file.put_line(fnd_file.log,l_error_msg);
         END;

         BEGIN
            SELECT cust_account_id
              INTO l_bill_to_cust_id
              FROM hz_cust_accounts@hrtoebs
             WHERE account_number = TO_CHAR (vheader.bill_to_customer_num);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error_msg :=
                     vheader.bill_to_customer_num
                  || '-Invalid Bill to Customer Number'
                  || ' For Header Number- '
                  || vheader.header_number;
         --- fnd_file.put_line(fnd_file.log,l_error_msg);
         END;

         BEGIN
            SELECT hcsu.site_use_id
              INTO l_bill_to_site_use_id
              FROM hz_parties@hrtoebs hp,
                   hz_cust_accounts@hrtoebs hca,
                   hz_cust_acct_sites_all@hrtoebs hcas,
                   hz_cust_site_uses_all@hrtoebs hcsu,
                   hz_party_sites@hrtoebs hps,
                   hz_locations@hrtoebs hl                                 --,
             --- hr_operating_units@hrtoebs hou
            WHERE  1 = 1
               AND hca.party_id = hp.party_id
               AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
               AND hca.cust_account_id = l_bill_to_cust_id
               AND hca.cust_account_id = hcas.cust_account_id
               AND hcas.party_site_id = hps.party_site_id
               AND hps.location_id = hl.location_id
               AND hcsu.site_use_code = 'BILL_TO'
               AND hcsu.primary_flag = 'Y'
               ---AND hca.account_number=vHeader.BILL_TO_CUSTOMER_NUM
               --AND hcsu.location = vHeader.bill_to_location
               AND hcsu.org_id = 288
               ---AND hou.organization_id = vHeader.operating_unit
               AND hca.status = 'A'
               AND hcsu.status = 'A';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error_msg :=
                     vheader.bill_to_customer_num
                  || '-Invalid Bill to Location'
                  || ' For Header Number- '
                  || vheader.header_number;
         --fnd_file.put_line(fnd_file.log,l_error_msg);
         END;

         /* BEGIN

          SELECT hcsu.site_use_id
            INTO l_ship_to_site_use_id
            FROM hz_parties hp,
                 hz_cust_accounts hca,
                 hz_cust_acct_sites_all hcas,
                 hz_cust_site_uses_all hcsu,
                 hz_party_sites hps,
                 hz_locations hl,
                 hr_operating_units hou
           WHERE  1 = 1
             AND hca.party_id = hp.party_id
             AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
             AND hca.cust_account_id = l_ship_to_cust_id
             AND hca.cust_account_id = hcas.cust_account_id
             AND hcas.party_site_id = hps.party_site_id
             AND hps.location_id = hl.location_id
             and hcsu.site_use_code = 'BILL_TO'
              AND hcsu.PRIMARY_FLAG='Y'
             ---AND hcsu.location = vHeader.ship_to_location
             AND hcsu.org_id = 101-----hou.organization_id
             --AND hou.organization_id = vHeader.operating_unit
             AND hca.status = 'A'
             AND hcsu.status = 'A';

             EXCEPTION
             when others then
             l_error_msg := vHeader.ship_to_location|| '-Invalid ship to Location'||' For Header Number- '||vHeader.header_number;
            --- fnd_file.put_line(fnd_file.log,l_error_msg);

          END;*/
         SELECT ra_customer_trx_s.NEXTVAL@hrtoebs
           INTO trx_header_id_v
           FROM DUAL;

         l_batch_source_rec.batch_source_id := l_batch_source_id;
         l_trx_header_tbl (1).trx_header_id := trx_header_id_v;
         l_trx_header_tbl (1).trx_date := vheader.orig_inv_date;
         l_trx_header_tbl (1).gl_date := vheader.orig_gl_date;
         l_trx_header_tbl (1).trx_currency := vheader.trx_currency;
         l_trx_header_tbl (1).bill_to_customer_id := l_bill_to_cust_id;
         l_trx_header_tbl (1).bill_to_site_use_id := l_bill_to_site_use_id;
         -- l_trx_header_tbl(1).ship_to_customer_id             := l_ship_to_cust_id;
         -- l_trx_header_tbl(1).ship_to_site_use_id             := l_ship_to_site_use_id;
         l_trx_header_tbl (1).cust_trx_type_id := l_cust_trx_type_id;
         l_trx_header_tbl (1).reference_number := vheader.orig_inv_num;
         l_trx_header_tbl (1).comments := vheader.header_description;

         IF vheader.invoice_type IN ('AJD')
         THEN
            l_trx_header_tbl (1).term_id := 5;   -------------------IMMEDIATE
         ELSE
            l_trx_header_tbl (1).term_id := NULL;
         END IF;

         l_trx_header_tbl (1).interface_header_attribute1 :=
                                                          vheader.orig_inv_num;
       -- l_trx_header_tbl(1).status_trx                      := 'OP';
       -- l_trx_header_tbl(1).printing_option                 := 'PRI';
--        l_trx_header_tbl(1).attribute6                      := '-1';
--        l_trx_header_tbl(1).attribute_category              := 'INVOICE LC/INFO';
--        l_trx_header_tbl(1).attribute7                      := NULL;
         l_trx_header_tbl (1).attribute1 := vheader.composite_receipt_id;

--l_trx_header_tbl(1).attribute2                      := vHeader.srv_number;
--l_trx_header_tbl(1).attribute3                     := vHeader.srv_number;
--        l_trx_header_tbl(1).attribute4                      := to_char(vHeader.srv_date,'YYYY/MM/DD');
--        l_trx_header_tbl(1).interface_header_attribute10    := vHeader.organization_id;
--        l_trx_header_tbl(1).purchase_order                  := vHeader.other_info;
         FOR vlines IN clines (vheader.header_number,
                               vheader.unit_code,
                               p_month,
                               vheader.invoice_type,
                               vheader.orig_inv_num
                              )
         LOOP
            trx_line_id_v := NULL;
            trx_dist_id_v := NULL;
            l_ccid := NULL;
            l_inv_item_id := NULL;

            /*BEGIN

                SELECT  code_combination_id
                INTO  l_ccid
                FROM  gl_code_combinations_kfv
                WHERE  concatenated_segments = TRIM(vLines.account);

            EXCEPTION
                when others then
                l_error_msg := vLines.account|| '-Invalid Revenue Account'||' For Header Number- '||vHeader.header_number||' and Line Number- '||vLines.Line_number;
               --- fnd_file.put_line(fnd_file.log,l_error_msg);

            END;*/

            /*BEGIN

                SELECT  inventory_item_id
                INTO  l_inv_item_id
                FROM  mtl_system_items_b
                WHERE  organization_id = vLines.organization_id
                AND  segment1 = TRIM(vLines.inventory_item);

            EXCEPTION
                when others then
                l_error_msg := vLines.inventory_item|| '-Invalid Inventory Item'||' For Header Number- '||vHeader.header_number||' and Line Number- '||vLines.Line_number;
               --- fnd_file.put_line(fnd_file.log,l_error_msg);

            END;*/
            SELECT ra_customer_trx_lines_s.NEXTVAL@hrtoebs
              INTO trx_line_id_v
              FROM DUAL;

            -- SELECT RA_CUST_TRX_LINE_GL_DIST_S.NEXTVAL INTO trx_dist_id_v FROM DUAL;
            l_trx_lines_tbl (vlines.line_number).trx_header_id :=
                                                               trx_header_id_v;
            l_trx_lines_tbl (vlines.line_number).trx_line_id := trx_line_id_v;
            --l_trx_lines_tbl (vlines.line_number).reason_code := 'WAIVE OFF';----use in credit not
            l_trx_lines_tbl (vlines.line_number).line_number :=
                                                            vlines.line_number;
            --l_trx_lines_tbl(vLines.line_number).inventory_item_id  := l_inv_item_id;
            l_trx_lines_tbl (vlines.line_number).description :=
                                                       vlines.line_description;

            IF vlines.invoice_type IN ('AJD')
            THEN
               l_trx_lines_tbl (vlines.line_number).quantity_invoiced :=
                                                     vlines.quantity_invoiced;
               l_trx_lines_tbl (vlines.line_number).amount :=
                                                    vlines.unit_selling_price;
               l_trx_lines_tbl (vlines.line_number).unit_selling_price :=
                                                    vlines.unit_selling_price;
            ELSE
               l_trx_lines_tbl (vlines.line_number).quantity_invoiced := NULL;
               l_trx_lines_tbl (vlines.line_number).amount :=
                                            (-1 * vlines.unit_selling_price
                                            );
               l_trx_lines_tbl (vlines.line_number).unit_selling_price := NULL;
            END IF;

            l_trx_lines_tbl (vlines.line_number).line_type := 'LINE';
--        l_trx_dist_tbl(vLines.line_number).trx_header_id       := trx_header_id_v;
--        l_trx_dist_tbl(vLines.line_number).trx_line_id         := trx_line_id_v ;
--        l_trx_dist_tbl(vLines.line_number).trx_dist_id         := trx_dist_id_v ;
--        l_trx_dist_tbl(vLines.line_number).account_class       := 'REV';
--        l_trx_dist_tbl(vLines.line_number).percent             := 100 ;
--        l_trx_dist_tbl(vLines.line_number).code_combination_id := l_ccid;
         END LOOP;

         ar_invoice_api_pub.create_single_invoice@hrtoebs
                            (p_api_version               => 1.0,
                             p_init_msg_list             => 'F',
                             p_commit                    => 'F',
                             p_batch_source_rec          => l_batch_source_rec,
                             p_trx_header_tbl            => l_trx_header_tbl,
                             p_trx_lines_tbl             => l_trx_lines_tbl,
                             p_trx_dist_tbl              => l_trx_dist_tbl,
                             p_trx_salescredits_tbl      => l_trx_salescredits_tbl,
                             x_customer_trx_id           => l_cust_trx_id,
                             x_return_status             => l_return_status,
                             x_msg_count                 => l_msg_count,
                             x_msg_data                  => l_msg_data
                            );

         IF l_return_status = 'E' OR l_return_status = 'U'
         THEN
            --- fnd_file.put_line(fnd_file.log,'API Error- unexpected errors found!');
            UPDATE auerp.xxa_ar_trans_erp_bills
               SET process_status_flag = 'E',
                   process_message = l_msg_data,
                   process_date = SYSDATE
             WHERE revenue_centre_id || TO_CHAR (invoice_date, 'ddmm') =
                                                         vheader.header_number
               AND    revenue_centre_id
                   || invoice_type
                   || invoice_date
                   || total_amount = vheader.orig_inv_num;
         ELSE
            SELECT COUNT (*)
              INTO l_count
              FROM ar_trx_errors_gt@hrtoebs
             WHERE error_message IS NOT NULL;

            IF l_count > 0
            THEN
               BEGIN
                  l_error_msg := NULL;

                  FOR fet IN (SELECT error_message
                                ---INTO l_error_msg
                              FROM   ar_trx_errors_gt@hrtoebs
                               WHERE error_message IS NOT NULL)
                  LOOP
                     l_error_msg := l_error_msg || fet.error_message;
                  END LOOP;

                  UPDATE auerp.xxa_ar_trans_erp_bills
                     SET process_status_flag = 'E',
                         process_message = l_error_msg,
                         process_date = SYSDATE
                   WHERE revenue_centre_id || TO_CHAR (invoice_date, 'ddmm') =
                                                         vheader.header_number
                     AND    revenue_centre_id
                         || invoice_type
                         || invoice_date
                         || total_amount = vheader.orig_inv_num;
               --- fnd_file.put_line(fnd_file.log,'API Error- '||l_error_msg);
               END;
            ELSE
               SELECT trx_number
                 INTO l_trx_num
                 FROM ar_trx_header_gt@hrtoebs
                WHERE customer_trx_id = l_cust_trx_id;

               UPDATE auerp.xxa_ar_trans_erp_bills
                  SET process_status_flag = 'S',
                      process_message = 'SUCCESS - ' || l_cust_trx_id,
                      process_date = SYSDATE,
                      erp_invoice_number = l_trx_num,
                      erp_invoice_id = l_cust_trx_id
                WHERE revenue_centre_id || TO_CHAR (invoice_date, 'ddmm') =
                                                         vheader.header_number
                  AND    revenue_centre_id
                      || invoice_type
                      || invoice_date
                      || total_amount = vheader.orig_inv_num;
            END IF;
         END IF;
      END LOOP;

      BEGIN
         aucustom.xxau_auto_mail_ajd_ajc_cio (p_month, p_unit);
      END;
   END xxau_create_ar_ajd_ajc_cio;

   PROCEDURE xxau_create_ar_cm_dm (errbuff OUT NUMBER, retcode OUT NUMBER)
   IS
      l_batch_source_id        NUMBER;
      l_cust_trx_type_id       NUMBER;
      l_bill_to_cust_id        NUMBER;
      l_ship_to_cust_id        NUMBER;
      l_ship_to_site_use_id    NUMBER;
      l_bill_to_site_use_id    NUMBER;
      l_ccid                   NUMBER;
      l_inv_item_id            NUMBER;
      trx_header_id_v          NUMBER;
      trx_line_id_v            NUMBER;
      trx_dist_id_v            NUMBER;
      l_count                  NUMBER;
      l_return_status          VARCHAR2 (1);
      l_msg_count              NUMBER;
      l_msg_data               VARCHAR2 (2000);
      l_error_msg              VARCHAR2 (2000);
      l_cust_trx_id            NUMBER;
      l_trx_num                VARCHAR2 (20);
      l_length                 NUMBER;
      l_batch_source_rec       ar_invoice_api_pub.batch_source_rec_type@hrtoebs;
      l_trx_header_tbl         ar_invoice_api_pub.trx_header_tbl_type@hrtoebs;
      l_trx_lines_tbl          ar_invoice_api_pub.trx_line_tbl_type@hrtoebs;
      l_trx_dist_tbl           ar_invoice_api_pub.trx_dist_tbl_type@hrtoebs;
      l_trx_salescredits_tbl   ar_invoice_api_pub.trx_salescredits_tbl_type@hrtoebs;

      CURSOR cheader
      IS
         SELECT   operating_unit, organization_id, trx_source, header_number,
                  header_description, orig_gl_date, cust_trx_type,
                  trx_currency, bill_to_customer_num, bill_to_location,
                  ship_to_customer_num, ship_to_location, orig_inv_num,
                  orig_inv_date, srv_number, srv_date, other_info
             FROM xxau_create_ar_inv_master
            WHERE NVL (process_flag, 'N') = 'N' AND line_number = '1'
         ORDER BY header_number;

      CURSOR clines (
         l_header_num     NUMBER,
         l_org_id         NUMBER,
         l_organization   NUMBER
      )
      IS
         SELECT organization_id, line_number, ACCOUNT, inventory_item,
                quantity_invoiced, uom, unit_selling_price, line_description
           FROM xxau_create_ar_inv_master
          WHERE header_number = l_header_num
            AND operating_unit = l_org_id
            AND organization_id = l_organization;
   BEGIN
      mo_global.init@hrtoebs ('AR');
      mo_global.set_policy_context@hrtoebs ('S', 101);
      fnd_global.apps_initialize@hrtoebs (user_id           => 2502,
                                          resp_id           => 50375,
                                          resp_appl_id      => 222
                                         );

      FOR vheader IN cheader
      LOOP
         trx_header_id_v := NULL;
         l_batch_source_id := NULL;
         l_cust_trx_type_id := NULL;
         l_bill_to_cust_id := NULL;
         l_ship_to_cust_id := NULL;
         l_bill_to_site_use_id := NULL;
         l_ship_to_site_use_id := NULL;
         l_error_msg := NULL;

         BEGIN
            SELECT batch_source_id
              INTO l_batch_source_id
              FROM ra_batch_sources_all@hrtoebs rbsa,
                   hr_operating_units@hrtoebs hou
             WHERE rbsa.org_id = hou.organization_id
               AND rbsa.NAME = vheader.trx_source
               AND hou.organization_id = vheader.operating_unit;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error_msg :=
                     vheader.trx_source
                  || '-Invalid Transaction source'
                  || ' For Header Number- '
                  || vheader.header_number;
         --- fnd_file.put_line(fnd_file.log,l_error_msg);
         END;

         BEGIN
            SELECT cust_trx_type_id
              INTO l_cust_trx_type_id
              FROM ra_cust_trx_types_all@hrtoebs rcta,
                   hr_operating_units@hrtoebs hou
             WHERE rcta.org_id = hou.organization_id
               AND rcta.NAME = vheader.cust_trx_type
               AND hou.organization_id = vheader.operating_unit;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error_msg :=
                     vheader.cust_trx_type
                  || '-Invalid Customer Transaction Type'
                  || ' For Header Number- '
                  || vheader.header_number;
         --- fnd_file.put_line(fnd_file.log,l_error_msg);
         END;

         BEGIN
            SELECT cust_account_id
              INTO l_bill_to_cust_id
              FROM hz_cust_accounts@hrtoebs
             WHERE account_number = TO_CHAR (vheader.bill_to_customer_num);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error_msg :=
                     vheader.bill_to_customer_num
                  || '-Invalid Bill to Customer Number'
                  || ' For Header Number- '
                  || vheader.header_number;
         --- fnd_file.put_line(fnd_file.log,l_error_msg);
         END;

         BEGIN
            SELECT hcsu.site_use_id
              INTO l_bill_to_site_use_id
              FROM hz_parties@hrtoebs hp,
                   hz_cust_accounts@hrtoebs hca,
                   hz_cust_acct_sites_all@hrtoebs hcas,
                   hz_cust_site_uses_all@hrtoebs hcsu,
                   hz_party_sites@hrtoebs hps,
                   hz_locations@hrtoebs hl                                 --,
             --- hr_operating_units@hrtoebs hou
            WHERE  1 = 1
               AND hca.party_id = hp.party_id
               AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
               AND hca.cust_account_id = l_bill_to_cust_id
               AND hca.cust_account_id = hcas.cust_account_id
               AND hcas.party_site_id = hps.party_site_id
               AND hps.location_id = hl.location_id
               AND hcsu.site_use_code = 'BILL_TO'
               AND hcsu.primary_flag = 'Y'
               ---AND hca.account_number=vHeader.BILL_TO_CUSTOMER_NUM
               --AND hcsu.location = vHeader.bill_to_location
               AND hcsu.org_id = 101
               ---AND hou.organization_id = vHeader.operating_unit
               AND hca.status = 'A'
               AND hcsu.status = 'A';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error_msg :=
                     vheader.bill_to_customer_num
                  || '-Invalid Bill to Location'
                  || ' For Header Number- '
                  || vheader.header_number;
         --fnd_file.put_line(fnd_file.log,l_error_msg);
         END;

         /* BEGIN

          SELECT hcsu.site_use_id
            INTO l_ship_to_site_use_id
            FROM hz_parties hp,
                 hz_cust_accounts hca,
                 hz_cust_acct_sites_all hcas,
                 hz_cust_site_uses_all hcsu,
                 hz_party_sites hps,
                 hz_locations hl,
                 hr_operating_units hou
           WHERE  1 = 1
             AND hca.party_id = hp.party_id
             AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
             AND hca.cust_account_id = l_ship_to_cust_id
             AND hca.cust_account_id = hcas.cust_account_id
             AND hcas.party_site_id = hps.party_site_id
             AND hps.location_id = hl.location_id
             and hcsu.site_use_code = 'BILL_TO'
              AND hcsu.PRIMARY_FLAG='Y'
             ---AND hcsu.location = vHeader.ship_to_location
             AND hcsu.org_id = 101-----hou.organization_id
             --AND hou.organization_id = vHeader.operating_unit
             AND hca.status = 'A'
             AND hcsu.status = 'A';

             EXCEPTION
             when others then
             l_error_msg := vHeader.ship_to_location|| '-Invalid ship to Location'||' For Header Number- '||vHeader.header_number;
            --- fnd_file.put_line(fnd_file.log,l_error_msg);

          END;*/
         SELECT ra_customer_trx_s.NEXTVAL@hrtoebs
           INTO trx_header_id_v
           FROM DUAL;

         l_batch_source_rec.batch_source_id := l_batch_source_id;
         l_trx_header_tbl (1).trx_header_id := trx_header_id_v;
         l_trx_header_tbl (1).trx_date := vheader.orig_inv_date;
         l_trx_header_tbl (1).gl_date := vheader.orig_gl_date;
         l_trx_header_tbl (1).trx_currency := vheader.trx_currency;
         l_trx_header_tbl (1).bill_to_customer_id := l_bill_to_cust_id;
         l_trx_header_tbl (1).bill_to_site_use_id := l_bill_to_site_use_id;
         -- l_trx_header_tbl(1).ship_to_customer_id             := l_ship_to_cust_id;
         -- l_trx_header_tbl(1).ship_to_site_use_id             := l_ship_to_site_use_id;
         l_trx_header_tbl (1).cust_trx_type_id := l_cust_trx_type_id;
         l_trx_header_tbl (1).interface_header_attribute1 :=
                                                    vheader.header_description;

       -- l_trx_header_tbl(1).status_trx                      := 'OP';
       -- l_trx_header_tbl(1).printing_option                 := 'PRI';
--        l_trx_header_tbl(1).attribute6                      := '-1';
--        l_trx_header_tbl(1).attribute_category              := 'INVOICE LC/INFO';
--        l_trx_header_tbl(1).attribute7                      := NULL;
--        l_trx_header_tbl(1).attribute1                      := vHeader.srv_number;
--        l_trx_header_tbl(1).attribute4                      := to_char(vHeader.srv_date,'YYYY/MM/DD');
--        l_trx_header_tbl(1).interface_header_attribute10    := vHeader.organization_id;
--        l_trx_header_tbl(1).purchase_order                  := vHeader.other_info;
         FOR vlines IN clines (vheader.header_number,
                               vheader.operating_unit,
                               vheader.organization_id
                              )
         LOOP
            trx_line_id_v := NULL;
            trx_dist_id_v := NULL;
            l_ccid := NULL;
            l_inv_item_id := NULL;

            /*BEGIN

                SELECT  code_combination_id
                INTO  l_ccid
                FROM  gl_code_combinations_kfv
                WHERE  concatenated_segments = TRIM(vLines.account);

            EXCEPTION
                when others then
                l_error_msg := vLines.account|| '-Invalid Revenue Account'||' For Header Number- '||vHeader.header_number||' and Line Number- '||vLines.Line_number;
               --- fnd_file.put_line(fnd_file.log,l_error_msg);

            END;*/

            /*BEGIN

                SELECT  inventory_item_id
                INTO  l_inv_item_id
                FROM  mtl_system_items_b
                WHERE  organization_id = vLines.organization_id
                AND  segment1 = TRIM(vLines.inventory_item);

            EXCEPTION
                when others then
                l_error_msg := vLines.inventory_item|| '-Invalid Inventory Item'||' For Header Number- '||vHeader.header_number||' and Line Number- '||vLines.Line_number;
               --- fnd_file.put_line(fnd_file.log,l_error_msg);

            END;*/
            SELECT ra_customer_trx_lines_s.NEXTVAL@hrtoebs
              INTO trx_line_id_v
              FROM DUAL;

            -- SELECT RA_CUST_TRX_LINE_GL_DIST_S.NEXTVAL INTO trx_dist_id_v FROM DUAL;
            l_trx_lines_tbl (vlines.line_number).trx_header_id :=
                                                               trx_header_id_v;
            l_trx_lines_tbl (vlines.line_number).trx_line_id := trx_line_id_v;
            l_trx_lines_tbl (vlines.line_number).reason_code := 'WAIVE OFF';
            l_trx_lines_tbl (vlines.line_number).line_number :=
                                                            vlines.line_number;
            --l_trx_lines_tbl(vLines.line_number).inventory_item_id  := l_inv_item_id;
            l_trx_lines_tbl (vlines.line_number).description :=
                                                       vlines.line_description;
            --l_trx_lines_tbl (vlines.line_number).quantity_invoiced :=
                                                       ---  vlines.quantity_invoiced;
            l_trx_lines_tbl (vlines.line_number).amount :=
                                                     vlines.unit_selling_price;
            l_trx_lines_tbl (vlines.line_number).line_type := 'LINE';
--        l_trx_dist_tbl(vLines.line_number).trx_header_id       := trx_header_id_v;
--        l_trx_dist_tbl(vLines.line_number).trx_line_id         := trx_line_id_v ;
--        l_trx_dist_tbl(vLines.line_number).trx_dist_id         := trx_dist_id_v ;
--        l_trx_dist_tbl(vLines.line_number).account_class       := 'REV';
--        l_trx_dist_tbl(vLines.line_number).percent             := 100 ;
--        l_trx_dist_tbl(vLines.line_number).code_combination_id := l_ccid;
         END LOOP;

         ar_invoice_api_pub.create_single_invoice@hrtoebs
                            (p_api_version               => 1.0,
                             p_init_msg_list             => 'F',
                             p_commit                    => 'F',
                             p_batch_source_rec          => l_batch_source_rec,
                             p_trx_header_tbl            => l_trx_header_tbl,
                             p_trx_lines_tbl             => l_trx_lines_tbl,
                             p_trx_dist_tbl              => l_trx_dist_tbl,
                             p_trx_salescredits_tbl      => l_trx_salescredits_tbl,
                             x_customer_trx_id           => l_cust_trx_id,
                             x_return_status             => l_return_status,
                             x_msg_count                 => l_msg_count,
                             x_msg_data                  => l_msg_data
                            );

         IF l_return_status = 'E' OR l_return_status = 'U'
         THEN
            --- fnd_file.put_line(fnd_file.log,'API Error- unexpected errors found!');
            UPDATE xxau_create_ar_inv_master
               SET process_flag = 'E',
                   process_msz = l_msg_data
             WHERE header_number = vheader.header_number;
         ELSE
            SELECT COUNT (*)
              INTO l_count
              FROM ar_trx_errors_gt@hrtoebs
             WHERE error_message IS NOT NULL;

            IF l_count > 0
            THEN
               SELECT error_message
                 INTO l_error_msg
                 FROM ar_trx_errors_gt@hrtoebs
                WHERE error_message IS NOT NULL;

               UPDATE xxau_create_ar_inv_master
                  SET process_flag = 'E',
                      process_msz = l_error_msg
                WHERE header_number = vheader.header_number;
            --- fnd_file.put_line(fnd_file.log,'API Error- '||l_error_msg);
            ELSE
               UPDATE xxau_create_ar_inv_master
                  SET process_flag = 'P'
                WHERE header_number = vheader.header_number;

               SELECT trx_number
                 INTO l_trx_num
                 FROM ar_trx_header_gt@hrtoebs
                WHERE customer_trx_id = l_cust_trx_id;
            END IF;
         END IF;
      END LOOP;
   END xxau_create_ar_cm_dm;

   PROCEDURE xxa_ar_gate_receipt_p2_man (p_unit VARCHAR2, p_gl_date DATE)
   IS
      -- cursor for cash receipt creation
      CURSOR c1
      IS
         SELECT m.receipt_method_id, m.gl_date, m.receipt_date,
                d.composite_receipt_id,
                m.composite_receipt_no composite_receipt_no, d.serial_number,
                d.party_number, d.party_name, d.party_location,
                d.receipt_number receipt_number, d.party_amt party_amt,
                d.created_by, d.creation_date, d.last_updated_by,
                d.last_update_date, d.comments, 288 org_id,

                --    101 org_id,                                   --V1.0
                'INR' currency_code, hca.cust_account_id customer_id,
                d.attribute_category, d.attribute1, d.attribute2,
                d.attribute3, d.attribute4, d.attribute5, d.attribute6,
                d.attribute7, d.attribute8, d.attribute9, d.attribute10,
                d.attribute11, d.attribute12, d.attribute13, d.attribute14,
                d.attribute15, bb.organization_code
           FROM aucustom.xxa_ar_composit_receipt_dtl d,
                aucustom.xxa_ar_composit_receipt_mst m,
                apps.hz_cust_accounts@hrtoebs hca,
                aucustom.xxau_accounting_unit bb,
                aucustom.user_master um
          WHERE 1 = 1
            AND hca.account_number(+) = d.party_number
            AND d.composite_receipt_id = m.composite_receipt_id
            AND m.payment_type = 'G'
            AND NVL (m.cancel_flag, 'N') = 'N'
            AND NVL (m.complete_flag, 'N') = 'N'
            AND NVL (d.process_flag, 'N') = 'N'
            AND accounting_unit = p_unit
            AND gl_date = p_gl_date
            -- AND m.composite_receipt_id = 416263
            AND um.organisation_id = d.created_by
            AND SUBSTR (um.unit_name, 1, 3) = bb.organization_code;

--AND nvl(um.gate_cash_user,'N') = 'Y';
      CURSOR c3 (p_receipt_id NUMBER)
      IS
         SELECT d.attribute_category, d.attribute14, d.attribute11
           FROM aucustom.xxa_ar_composit_receipt_dtl d,
                aucustom.xxa_ar_composit_receipt_mst m,
                apps.hz_cust_accounts@hrtoebs hca
          WHERE 1 = 1
            AND hca.account_number(+) = d.party_number
            AND d.composite_receipt_id = m.composite_receipt_id
            AND d.composite_receipt_id = p_receipt_id;

      --- out parameters
      l_return_status          VARCHAR2 (1);
      l_msg_count              NUMBER;
      l_msg_data               VARCHAR2 (4000)                         := NULL;
      l_cash_receipt_id        NUMBER;
      l_misc_receipt_id        NUMBER;
      l_error_mesg             VARCHAR2 (4000)                         := NULL;
      p_count                  NUMBER;
      v_rec_trx_id             NUMBER;
      lv_receipt_method_name   VARCHAR2 (80);
      ln_receipt_method_id     NUMBER                                     := 0;
      x_return_status          VARCHAR2 (30)                           := NULL;
      x_msg_count              NUMBER;
      x_msg_data               VARCHAR2 (4000)                         := NULL;
      p_cr_id                  NUMBER;
      p_misc_receipt_id        NUMBER;
      v_unit_name              VARCHAR2 (3);
      err                      VARCHAR2 (400);
      ebf                      NUMBER;
      p_attribute_rec_type     apps.ar_receipt_api_pub.attribute_rec_type@hrtoebs;
   BEGIN
      apps.fnd_global.apps_initialize@hrtoebs (2482, 52024, 222);
      apps.mo_global.set_policy_context@hrtoebs ('S', 288);
      l_misc_receipt_id := 111;

      IF l_misc_receipt_id IS NOT NULL
      THEN
         ---------- code for cash receipts ----------
         DBMS_OUTPUT.put_line ('cash receipt 111');

         FOR i IN c1
         LOOP
            p_attribute_rec_type.attribute_category := i.attribute_category;
            p_attribute_rec_type.attribute1 := i.attribute1;
            p_attribute_rec_type.attribute2 := NVL (i.attribute2, 5);
            p_attribute_rec_type.attribute3 := NVL (i.attribute3, 'N');
            p_attribute_rec_type.attribute4 := NVL (i.attribute4, 'N');
            p_attribute_rec_type.attribute5 := NVL (i.attribute5, 'N');
            p_attribute_rec_type.attribute6 := NVL (i.attribute6, 'N');
            p_attribute_rec_type.attribute7 := i.attribute7;
            p_attribute_rec_type.attribute8 := i.attribute8;
            p_attribute_rec_type.attribute9 := i.composite_receipt_id;

            IF i.attribute_category = 'AU_Receipt_Info'
            THEN
               p_attribute_rec_type.attribute10 := i.attribute10;
               p_attribute_rec_type.attribute12 := i.attribute12;
            ELSE
               p_attribute_rec_type.attribute12 := i.attribute12;
               p_attribute_rec_type.attribute10 := i.attribute10;
            END IF;

            DBMS_OUTPUT.put_line ('cash receipt ');
            p_attribute_rec_type.attribute11 := i.attribute11;
            p_attribute_rec_type.attribute13 := i.attribute13;
            p_attribute_rec_type.attribute14 := i.attribute14;
            p_attribute_rec_type.attribute15 := i.attribute15;

            IF i.party_number IS NOT NULL
            THEN
               DBMS_OUTPUT.put_line ('party number not null ');
               apps.ar_receipt_api_pub.create_cash@hrtoebs
                                 (p_api_version               => 1.0,
                                  p_init_msg_list             => 'T',
                                  p_commit                    => 'F',
                                  p_validation_level          => 100,
                                  x_return_status             => l_return_status,
                                  x_msg_count                 => l_msg_count,
                                  x_msg_data                  => l_msg_data,
                                  p_currency_code             => i.currency_code,
                                  p_amount                    => i.party_amt,
                                  p_receipt_number            => i.composite_receipt_no,
                                  p_receipt_date              => i.receipt_date,
                                  p_gl_date                   => i.gl_date,
                                  p_comments                  => i.comments,
                                  p_attribute_rec             => p_attribute_rec_type,
                                  p_customer_number           => i.party_number,
                                  p_receipt_method_id         => i.receipt_method_id,
                                  p_cr_id                     => l_cash_receipt_id,
                                  p_global_attribute_rec      => NULL,
                                  p_org_id                    => 288
                                 );
            ELSIF i.party_number IS NULL
            THEN
               DBMS_OUTPUT.put_line ('party number null ');
               apps.ar_receipt_api_pub.create_cash@hrtoebs
                                 (p_api_version               => 1.0,
                                  p_init_msg_list             => 'T',
                                  p_commit                    => 'T',
                                  p_validation_level          => 100,
                                  x_return_status             => l_return_status,
                                  x_msg_count                 => l_msg_count,
                                  x_msg_data                  => l_msg_data,
                                  p_currency_code             => i.currency_code,
                                  p_amount                    => i.party_amt,
                                  p_receipt_number            => i.receipt_number,
                                  p_receipt_date              => i.receipt_date,
                                  p_comments                  => i.comments,
                                  p_gl_date                   => i.gl_date,
                                  p_attribute_rec             => p_attribute_rec_type,
                                  p_receipt_method_id         => i.receipt_method_id,
                                  p_cr_id                     => l_cash_receipt_id,
                                  p_global_attribute_rec      => NULL,
                                  p_org_id                    => 288
                                 );
            END IF;

--------------------------------------------------------
            DBMS_OUTPUT.put_line ('id  ' || l_cash_receipt_id);

            IF l_cash_receipt_id IS NULL
            THEN
               DBMS_OUTPUT.put_line ('id  null');

               IF l_msg_count = 1
               THEN
                  l_error_mesg := l_msg_data;
               ELSIF l_msg_count > 1
               THEN
                  l_msg_data := NULL;

                  LOOP
                     DBMS_OUTPUT.put_line ('in loop null');
                     p_count := p_count + 1;
                     l_msg_data := NULL;
                     l_msg_data := l_msg_data;

                     IF l_msg_data IS NULL
                     THEN
                        EXIT;
                     END IF;
                  END LOOP;

                  l_error_mesg := l_error_mesg || '-' || l_msg_data;
               END IF;

               DBMS_OUTPUT.put_line ('55555');
               DBMS_OUTPUT.put_line (l_error_mesg);
               DBMS_OUTPUT.put_line ('COMP ID - ' || i.composite_receipt_id);
               DBMS_OUTPUT.put_line ('rcpt ID - ' || i.receipt_number);
               DBMS_OUTPUT.put_line ('srno ID - ' || i.serial_number);

               UPDATE aucustom.xxa_ar_composit_receipt_dtl d
                  SET d.process_flag = 'E',
                      d.process_message = l_error_mesg,
                      d.process_date = SYSDATE
                WHERE d.composite_receipt_id = i.composite_receipt_id
                  --and d.receipt_number = substr(i.receipt_number,4)  ----added by deepak
                  AND d.receipt_number = i.receipt_number
                  AND d.serial_number = i.serial_number;

               DBMS_OUTPUT.put_line ('666666655555');
            ELSE
               BEGIN
                  p_cr_id := l_cash_receipt_id;
                  DBMS_OUTPUT.put_line (   'COMP ID Y - '
                                        || i.composite_receipt_id
                                       );
                  DBMS_OUTPUT.put_line ('rcpt ID Y - ' || i.receipt_number);
                  DBMS_OUTPUT.put_line ('srno ID Y - ' || i.serial_number);

                  UPDATE aucustom.xxa_ar_composit_receipt_dtl d
                     SET d.process_flag = 'S',
                         d.process_message =
                                         'SUCCESS' || '-' || l_cash_receipt_id,
                         d.process_date = SYSDATE
                   WHERE d.composite_receipt_id = i.composite_receipt_id;

                  DBMS_OUTPUT.put_line ('7777777777777777666666655555');

                  UPDATE aucustom.xxa_ar_composit_receipt_mst mst
                     SET mst.complete_flag = 'Y',
                         mst.process_flag = 'S',
                         mst.process_message =
                                         'SUCCESS' || '-' || l_cash_receipt_id,
                         mst.process_date = SYSDATE
                   WHERE mst.composite_receipt_id = i.composite_receipt_id;
               END;
            END IF;

            DBMS_OUTPUT.put_line ('DONE');

            FOR ii IN c3 (i.composite_receipt_id)
            LOOP
------------------------------------------
               IF ii.attribute_category = 'AU_Receipt_Info'
               THEN
                  IF     ii.attribute14 IS NOT NULL
                     AND ii.attribute14 NOT LIKE '%NOT%'
                  THEN
                     UPDATE aucustom.xxau_pr_trans_det d
                        SET d.flag = 'P'
                      WHERE d.prov_receipt_no = ii.attribute14;
                  END IF;
               ELSE
                  IF     ii.attribute11 IS NOT NULL
                     AND ii.attribute11 NOT LIKE '%NOT%'
                  THEN
                     UPDATE aucustom.xxau_pr_trans_det d
                        SET d.flag = 'P'
                      WHERE d.prov_receipt_no = ii.attribute11;
                  END IF;
               END IF;
------------------------------------------
            END LOOP;
         END LOOP;                              -- end loop for cash recreipts
      END IF;
   END xxa_ar_gate_receipt_p2_man;

   PROCEDURE xxau_personal_emp_ledger (
      p_org_id         NUMBER DEFAULT NULL,
      p_person_id      NUMBER DEFAULT NULL,
      p_item_from      VARCHAR2 DEFAULT NULL,
      p_item_to        VARCHAR2 DEFAULT NULL,
      p_mode           VARCHAR2 DEFAULT 'D',
      p_sub_inv_from   VARCHAR2 DEFAULT NULL,
      p_sub_inv_to     VARCHAR2 DEFAULT NULL
   )
   IS
      CURSOR fetch1
      IS
         (SELECT mp.organization_code, gl.segment1,
                 NVL
                    (aucustom.au_acct_description_fn (gl.segment1,
                                                      'AUPL_Company'
                                                     ),
                     aucustom.au_acct_description_fn (gl.segment1,
                                                      'AU_COMPANY'
                                                     )
                    ) company,
                 per.location_name, per.working_location,
                 (SELECT ffv.description
                    FROM apps.fnd_flex_value_sets@hrtoebs ffvs,
                         apps.fnd_flex_values_vl@hrtoebs ffv
                   WHERE ffvs.flex_value_set_id = ffv.flex_value_set_id
                     AND ffvs.flex_value_set_name = 'XXA_HR_DEPTT'
                     AND flex_value =
                            DECODE (LENGTH (per.attribute4),
                                    1, '0' || per.attribute4,
                                    per.attribute4
                                   )) department,
                 per.full_name employee_name, per.national_identifier,
                 per.employee_number, mmt.transaction_date trx_date,
                 msi.segment1 item, msi.description descr,
                 TRIM
                    (DECODE ((INSTR (mut.serial_number, CHR (13)) - 1),
                             -1, mut.serial_number,
                             SUBSTR (mut.serial_number,
                                     1,
                                     (INSTR (mut.serial_number, CHR (13)) - 1
                                     )
                                    )
                            )
                    ) serial_number,
                 DECODE (msi.serial_number_control_code,
                         1, mmt.transaction_quantity,
                         DECODE (mtt.transaction_type_name,
                                 'Miscellaneous issue', -1,
                                 1
                                )
                        ) qty,
                 mmt.actual_cost, mmt.transaction_id
            FROM xxau_mtl_transactions_sep18 mmt,
                 apps.mtl_system_items_b@hrtoebs msi,
                 aucustom.xxau_employee_master4inv per,
                 apps.mtl_transaction_types@hrtoebs mtt,
                 apps.mtl_unit_transactions@hrtoebs mut,
                 apps.mtl_parameters@hrtoebs mp,
                 apps.mtl_categories@hrtoebs mcat,
                 apps.mtl_item_categories@hrtoebs micat,
                 apps.mtl_category_sets@hrtoebs mcats,
                 apps.gl_code_combinations@hrtoebs gl
           WHERE mmt.inventory_item_id = msi.inventory_item_id
             AND mmt.organization_id = msi.organization_id
             AND mtt.transaction_type_id = mmt.transaction_type_id
             AND mtt.transaction_type_name IN
                    ('Miscellaneous issue', 'Miscellaneous receipt',
                     'Return from Department')
             AND REGEXP_REPLACE (mmt.attribute3, '[^0-9]+', '') =
                                                                 per.person_id
             AND mp.organization_id = NVL (p_org_id, mp.organization_id)
             AND per.person_id = NVL (p_person_id, per.person_id)
             --AND per.national_identifier = 'HO/1698'
             AND mmt.transaction_id = mut.transaction_id(+)
             AND mp.organization_id = mmt.organization_id
             AND mmt.transaction_quantity <> 0
             AND micat.category_id = mcat.category_id
             AND micat.inventory_item_id = msi.inventory_item_id
             AND msi.organization_id = micat.organization_id
             AND micat.category_set_id = mcats.category_set_id
             AND mmt.distribution_account_id = gl.code_combination_id(+)
             AND msi.segment1 NOT IN
                    ('FALAP04158_N', 'FALAP00269_N', 'FALAP02682_N',
                     'FALAP04726_N', 'FALAP05733_N')
             AND micat.category_set_id = 1100000021
             AND msi.segment1 BETWEEN NVL (p_item_from, msi.segment1)
                                  AND NVL (p_item_to, msi.segment1));

-----------------------------------brief report-------------------------------------
      CURSOR fetch3
      IS
         (SELECT   per.person_id, mp.organization_code, msi.segment1 item,
                   msi.description descr,
                   TRIM
                      (DECODE ((INSTR (mut.serial_number, CHR (13)) - 1),
                               -1, mut.serial_number,
                               SUBSTR (mut.serial_number,
                                       1,
                                       (INSTR (mut.serial_number, CHR (13))
                                        - 1
                                       )
                                      )
                              )
                      ) serial_number,
                   SUM (DECODE (msi.serial_number_control_code,
                                1, mmt.transaction_quantity,
                                DECODE (mtt.transaction_type_name,
                                        'Miscellaneous issue', -1,
                                        1
                                       )
                               )
                       ) qty,
                   MAX (mmt.actual_cost) actual_cost,
                   MAX (mmt.transaction_id) transaction_id
              FROM xxau_mtl_transactions_sep18 mmt,
                   apps.mtl_system_items_b@hrtoebs msi,
                   aucustom.xxau_employee_master4inv per,
                   apps.mtl_transaction_types@hrtoebs mtt,
                   apps.mtl_unit_transactions@hrtoebs mut,
                   apps.mtl_parameters@hrtoebs mp,
                   apps.mtl_categories@hrtoebs mcat,
                   apps.mtl_item_categories@hrtoebs micat,
                   apps.mtl_category_sets@hrtoebs mcats,
                   apps.gl_code_combinations@hrtoebs gl
             WHERE mmt.inventory_item_id = msi.inventory_item_id
               AND mmt.organization_id = msi.organization_id
               AND mtt.transaction_type_id = mmt.transaction_type_id
               AND mtt.transaction_type_name IN
                      ('Miscellaneous issue', 'Miscellaneous receipt',
                       'Return from Department')
               AND REGEXP_REPLACE (mmt.attribute3, '[^0-9]+', '') =
                                                                 per.person_id
               AND mp.organization_id = NVL (p_org_id, mp.organization_id)
               AND per.person_id = NVL (p_person_id, per.person_id)
               --AND per.national_identifier = 'HO/1698'
               AND mmt.transaction_id = mut.transaction_id(+)
               AND mp.organization_id = mmt.organization_id
               AND mmt.transaction_quantity <> 0
               AND micat.category_id = mcat.category_id
               AND micat.inventory_item_id = msi.inventory_item_id
               AND msi.organization_id = micat.organization_id
               AND micat.category_set_id = mcats.category_set_id
               AND mmt.distribution_account_id = gl.code_combination_id(+)
               AND msi.segment1 NOT IN
                      ('FALAP04158_N', 'FALAP00269_N', 'FALAP02682_N',
                       'FALAP04726_N', 'FALAP05733_N')
               AND micat.category_set_id = 1100000021
               AND msi.segment1 BETWEEN NVL (p_item_from, msi.segment1)
                                    AND NVL (p_item_to, msi.segment1)
          GROUP BY per.person_id,
                   mp.organization_code,
                   msi.segment1,
                   msi.description,
                   TRIM (DECODE ((INSTR (mut.serial_number, CHR (13)) - 1),
                                 -1, mut.serial_number,
                                 SUBSTR (mut.serial_number,
                                         1,
                                         (  INSTR (mut.serial_number,
                                                   CHR (13))
                                          - 1
                                         )
                                        )
                                )
                        )
            HAVING SUM (DECODE (msi.serial_number_control_code,
                                1, mmt.transaction_quantity,
                                DECODE (mtt.transaction_type_name,
                                        'Miscellaneous issue', -1,
                                        1
                                       )
                               )
                       ) <> 0);

      CURSOR fetchdel
      IS
         (SELECT   transaction_id, COUNT (1), MAX (ROWID) row_id
              FROM xxau_mtl_transactions_sep18
          GROUP BY transaction_id
            HAVING COUNT (1) > 1);

      v_active     VARCHAR2 (30)  := NULL;
      v_check      NUMBER         := 0;
      v_loc        VARCHAR2 (80)  := NULL;
      v_work_loc   VARCHAR2 (80)  := NULL;
      v_dept       VARCHAR2 (50)  := NULL;
      v_inv_loc    VARCHAR2 (220) := NULL;
      v_segment1   VARCHAR2 (30)  := NULL;
      v_company    VARCHAR2 (120) := NULL;
      v_emp_num    VARCHAR2 (30)  := NULL;
      v_emp_name   VARCHAR2 (120) := NULL;
      v_national   VARCHAR2 (30)  := NULL;
   BEGIN
-------------------------insert new records------------------------
      BEGIN
         BEGIN
            INSERT INTO xxau_mtl_transactions_sep18
               (SELECT tt.*
                  FROM mtl_material_transactions@hrtoebs tt,
                       mtl_transaction_types@hrtoebs mtt
                 WHERE tt.transaction_type_id = mtt.transaction_type_id
                   AND tt.attribute3 IS NOT NULL
                   AND tt.transaction_date > '31-mar-2018'
                   AND mtt.transaction_type_name IN
                          ('Miscellaneous issue', 'Miscellaneous receipt',
                           'Return from Department')
                   AND NOT EXISTS (SELECT 'y'
                                     FROM xxau_mtl_transactions_sep18
                                    WHERE transaction_id = tt.transaction_id));
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      --COMMIT;
      END;

      BEGIN
         BEGIN
            FOR fetch2 IN fetchdel
            LOOP
               DELETE FROM xxau_mtl_transactions_sep18
                     WHERE ROWID < fetch2.row_id
                       AND transaction_id = fetch2.transaction_id;
            END LOOP;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
            WHEN OTHERS
            THEN
               NULL;
         END;
      --COMMIT;
      END;

      IF p_mode = 'D'
      THEN
         BEGIN
-----------------fetch data for report------------------------------
            FOR fetch2 IN fetch1
            LOOP
               v_active := NULL;
               v_check := 0;

               ---------------------check active or inactive employee-----------------------------
               BEGIN
                  SELECT COUNT (*)
                    INTO v_check
                    FROM aucustom.xxau_employee_master4invc paaf
                   WHERE paaf.national_identifier = fetch2.national_identifier;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_check := 0;
                  WHEN OTHERS
                  THEN
                     v_check := 0;
               END;

               IF v_check > 0
               THEN
                  v_active := 'Active';
               ELSE
                  v_active := 'Inactive';
               END IF;

               -----------------------------fetch inventory location-------------------------------
               BEGIN
                  SELECT NVL
                            (aucustom.au_acct_description_fn (gl.segment3,
                                                              'AUPL_Location'
                                                             ),
                             aucustom.au_acct_description_fn (gl.segment3,
                                                              'AU_LOCATION'
                                                             )
                            )
                    INTO v_inv_loc
                    FROM mtl_material_transactions@hrtoebs mmt,
                         gl_code_combinations_kfv@hrtoebs gl
                   WHERE mmt.distribution_account_id = gl.code_combination_id
                     AND mmt.transaction_id = fetch2.transaction_id;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_inv_loc := NULL;
                  WHEN OTHERS
                  THEN
                     v_inv_loc := NULL;
               END;

               DBMS_OUTPUT.put_line ('Start');

               INSERT INTO aucustom.xxa_emp_personal_ledger_t
                           (organization_code, segment1,
                            company, inv_location, location_name,
                            working_location, department,
                            employee_name, national_identifier,
                            employee_number, trx_date,
                            item, descr, serial_number,
                            qty, actual_cost,
                            transaction_id, employee_status
                           )
                    VALUES (fetch2.organization_code, fetch2.segment1,
                            fetch2.company, v_inv_loc, fetch2.location_name,
                            fetch2.working_location, fetch2.department,
                            fetch2.employee_name, fetch2.national_identifier,
                            fetch2.employee_number, fetch2.trx_date,
                            fetch2.item, fetch2.descr, fetch2.serial_number,
                            fetch2.qty, fetch2.actual_cost,
                            fetch2.transaction_id, v_active
                           );
            END LOOP;
         END;
      ELSE
         BEGIN
            ------------------------------for breif report---------------------------
            FOR fetch2 IN fetch3
            LOOP
               v_active := NULL;
               v_check := 0;
               v_loc := NULL;
               v_work_loc := NULL;
               v_dept := NULL;

               ---------------------check active or inactive employee-----------------------------
               BEGIN
                  SELECT COUNT (*)
                    INTO v_check
                    FROM aucustom.xxau_employee_master4invc paaf
                   WHERE paaf.person_id = fetch2.person_id;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_check := 0;
                  WHEN OTHERS
                  THEN
                     v_check := 0;
               END;

               IF v_check > 0
               THEN
                  v_active := 'Active';
               ELSE
                  v_active := 'Inactive';
               END IF;

               -------------------------------find location,company,department,cost----------------------
               v_loc := NULL;
               v_work_loc := NULL;
               v_dept := NULL;
               v_national := NULL;
               v_emp_num := NULL;
               v_emp_name := NULL;

               BEGIN
                  SELECT per1.location_name, per1.working_location,
                         (SELECT ffv.description
                            FROM apps.fnd_flex_value_sets@hrtoebs ffvs,
                                 apps.fnd_flex_values_vl@hrtoebs ffv
                           WHERE ffvs.flex_value_set_id =
                                                         ffv.flex_value_set_id
                             AND ffvs.flex_value_set_name = 'XXA_HR_DEPTT'
                             AND flex_value =
                                    DECODE (LENGTH (per1.attribute4),
                                            1, '0' || per1.attribute4,
                                            per1.attribute4
                                           )),
                         per1.national_identifier, per1.employee_number,
                         per1.full_name
                    INTO v_loc, v_work_loc,
                         v_dept,
                         v_national, v_emp_num,
                         v_emp_name
                    FROM aucustom.xxau_employee_master4inv per1
                   WHERE per1.person_id = fetch2.person_id AND ROWNUM < 2;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_loc := NULL;
                     v_work_loc := NULL;
                     v_dept := NULL;
                     v_national := NULL;
                     v_emp_num := NULL;
                     v_emp_name := NULL;
                  WHEN OTHERS
                  THEN
                     v_loc := NULL;
                     v_work_loc := NULL;
                     v_dept := NULL;
                     v_national := NULL;
                     v_emp_num := NULL;
                     v_emp_name := NULL;
               END;

               -----------------------------fetch inventory location-------------------------------
               BEGIN
                  SELECT NVL
                            (aucustom.au_acct_description_fn (gl.segment3,
                                                              'AUPL_Location'
                                                             ),
                             aucustom.au_acct_description_fn (gl.segment3,
                                                              'AU_LOCATION'
                                                             )
                            ),
                         NVL (aucustom.au_acct_description_fn (gl.segment1,
                                                               'AUPL_Company'
                                                              ),
                              aucustom.au_acct_description_fn (gl.segment1,
                                                               'AU_COMPANY'
                                                              )
                             ),
                         gl.segment1
                    INTO v_inv_loc,
                         v_company,
                         v_segment1
                    FROM mtl_material_transactions@hrtoebs mmt,
                         gl_code_combinations_kfv@hrtoebs gl
                   WHERE mmt.distribution_account_id = gl.code_combination_id
                     AND mmt.transaction_id = fetch2.transaction_id;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_inv_loc := NULL;
                  WHEN OTHERS
                  THEN
                     v_inv_loc := NULL;
               END;

               DBMS_OUTPUT.put_line ('Start');

               INSERT INTO aucustom.xxa_emp_personal_ledger_t
                           (organization_code, segment1, company,
                            inv_location, location_name, working_location,
                            department, employee_name, employee_number,
                            national_identifier, trx_date, item, descr,
                            serial_number, qty,
                            actual_cost, transaction_id,
                            employee_status
                           )
                    VALUES (fetch2.organization_code, v_segment1, v_company,
                            v_inv_loc, v_loc, v_work_loc,
                            v_dept, v_emp_name, v_emp_num,
                            v_national, NULL, fetch2.item, fetch2.descr,
                            fetch2.serial_number, fetch2.qty,
                            fetch2.actual_cost, fetch2.transaction_id,
                            v_active
                           );
            END LOOP;
         END;
      END IF;
   END xxau_personal_emp_ledger;

   PROCEDURE xxau_cir_flctu_report (
      p_from_date     DATE,
      p_to_date       DATE,
      p_org_id        NUMBER,
      p_dak           NUMBER,
      p_customer_id   NUMBER,
      p_type          VARCHAR2
   )
   AS
      CURSOR fetch1
      IS
         (SELECT   au_ord_ar_int_inv_org, customer_name, customer_number,
                   customer_id, au_ord_ar_int_dak, site_use_id, LOCATION,
                   au_ord_ar_int_pub_date, SUM (supply_copies) supply_copies,
                   SUM (au_ord_ar_sub) subs_copies,
                   SUM (sup_amount) supply_amount, SUM (recv_qty) recv_qty,
                   SUM (recv_short_qty) recv_short_qty,
                   SUM (recv_lost_qty) recv_lost_qty,
                   SUM (total_recv_qty) total_recv_qty,
                   SUM (allowd_qty) allowd_qty,
                   SUM (allowd_short_qty) allowd_short_qty,
                   SUM (allowd_lost_qty) allowd_lost_qty,
                   SUM (total_allowd_qty) total_allowd_qty,
                   SUM (unsold_amount) unsold_amount,
                   (  (SUM (supply_copies) + SUM (au_ord_ar_sub))
                    - SUM (total_allowd_qty)
                   ) nps
              FROM (SELECT aop.au_ord_ar_int_inv_org, ar.customer_name,
                           ar.customer_number, ar.customer_id,
                           aop.au_ord_ar_int_dak, hcsu.site_use_id,
                           hcsu.LOCATION, aop.au_ord_ar_int_pub_date,
                           (  NVL (aop.au_ord_ar_int_po_qty, 0)
                            + NVL (aop.au_ord_ar_int_changes, 0)
                            + NVL (aop.au_ord_ar_int_post_changes, 0)
                           ) supply_copies,
                           aop.au_ord_ar_sub,
                           NVL (aop.au_ord_ar_int_amount, 0) sup_amount,
                           0 recv_qty, 0 recv_short_qty, 0 recv_lost_qty,
                           0 total_recv_qty, 0 allowd_qty, 0 allowd_short_qty,
                           0 allowd_lost_qty, 0 total_allowd_qty,
                           0 unsold_amount
                      FROM au_order_process_trans aop,
                           apps.hz_cust_site_uses_all@hrtoebs hcsu,
                           apps.ar_customers@hrtoebs ar
                     WHERE aop.au_ord_ar_int_pub_date BETWEEN p_from_date
                                                          AND p_to_date
                       AND aop.au_ord_ar_int_inv_org =
                                     NVL (p_org_id, aop.au_ord_ar_int_inv_org)
                       AND ar.customer_id =
                                           NVL (p_customer_id, ar.customer_id)
                       AND aop.au_ord_ar_int_dak =
                                            NVL (p_dak, aop.au_ord_ar_int_dak)
                       AND aop.au_ord_ar_int_cust_id = ar.customer_id
                       AND aop.au_ord_ar_int_ship_to = hcsu.site_use_id
                       AND hcsu.org_id = 288
                       AND NVL (aop.au_ord_ar_int_amount, 0) <> 0
                    UNION ALL
                    SELECT arr.au_rma_inv_org, ar.customer_name,
                           ar.customer_number, ar.customer_id, arr.au_rma_dak,
                           hcsu.site_use_id, hcsu.LOCATION,
                           arr.au_rma_supply_dt, 0, 0, 0,
                           NVL (arr.au_rma_rec_recv_qty, 0) recv_qty,
                           NVL (arr.au_rma_rec_short_qty, 0) recv_short_qty,
                           NVL (arr.au_rma_rec_lost_qty, 0) recv_lost_qty,
                           (  NVL (arr.au_rma_rec_recv_qty, 0)
                            + NVL (arr.au_rma_rec_short_qty, 0)
                            + NVL (arr.au_rma_rec_lost_qty, 0)
                           ) total_recv_qty,
                           NVL (arr.au_rma_acc_accp_qty, 0) allowd_qty,
                           NVL (arr.au_rma_acc_short_qty, 0) allowd_short_qty,
                           NVL (arr.au_rma_acc_lost_qty, 0) allowd_lost_qty,
                           (  NVL (arr.au_rma_acc_accp_qty, 0)
                            + NVL (arr.au_rma_acc_short_qty, 0)
                            + NVL (arr.au_rma_acc_lost_qty, 0)
                           ) total_allowd_qty,
                           (NVL (arr.au_rma_cm_rate, 0)) unsold_amount
                      FROM au_rma_return arr,
                           apps.hz_cust_site_uses_all@hrtoebs hcsu,
                           apps.ar_customers@hrtoebs ar
                     WHERE arr.au_rma_supply_dt BETWEEN p_from_date AND p_to_date
                       AND arr.au_rma_inv_org =
                                            NVL (p_org_id, arr.au_rma_inv_org)
                       AND arr.au_rma_cust_id = ar.customer_id
                       AND arr.au_rma_ship_to = hcsu.site_use_id
                       AND ar.customer_id =
                                           NVL (p_customer_id, ar.customer_id)
                       AND arr.au_rma_dak = NVL (p_dak, arr.au_rma_dak)
                       AND hcsu.org_id = 288)
          GROUP BY au_ord_ar_int_inv_org,
                   customer_name,
                   customer_number,
                   customer_id,
                   au_ord_ar_int_dak,
                   site_use_id,
                   LOCATION,
                   au_ord_ar_int_pub_date);

--------------------------------for receive date----------------------------------------
      CURSOR fetch3
      IS
         (SELECT   au_ord_ar_int_inv_org, customer_name, customer_number,
                   customer_id, au_ord_ar_int_dak, site_use_id, LOCATION,
                   au_ord_ar_int_pub_date, SUM (supply_copies) supply_copies,
                   SUM (au_ord_ar_sub) subs_copies,
                   SUM (sup_amount) supply_amount, SUM (recv_qty) recv_qty,
                   SUM (recv_short_qty) recv_short_qty,
                   SUM (recv_lost_qty) recv_lost_qty,
                   SUM (total_recv_qty) total_recv_qty,
                   SUM (allowd_qty) allowd_qty,
                   SUM (allowd_short_qty) allowd_short_qty,
                   SUM (allowd_lost_qty) allowd_lost_qty,
                   SUM (total_allowd_qty) total_allowd_qty,
                   SUM (unsold_amount) unsold_amount,
                   (  (SUM (supply_copies) + SUM (au_ord_ar_sub))
                    - SUM (total_allowd_qty)
                   ) nps
              FROM (SELECT aop.au_ord_ar_int_inv_org, ar.customer_name,
                           ar.customer_number, ar.customer_id,
                           aop.au_ord_ar_int_dak, hcsu.site_use_id,
                           hcsu.LOCATION, aop.au_ord_ar_int_pub_date,
                           (  NVL (aop.au_ord_ar_int_po_qty, 0)
                            + NVL (aop.au_ord_ar_int_changes, 0)
                            + NVL (aop.au_ord_ar_int_post_changes, 0)
                           ) supply_copies,
                           aop.au_ord_ar_sub,
                           NVL (aop.au_ord_ar_int_amount, 0) sup_amount,
                           0 recv_qty, 0 recv_short_qty, 0 recv_lost_qty,
                           0 total_recv_qty, 0 allowd_qty, 0 allowd_short_qty,
                           0 allowd_lost_qty, 0 total_allowd_qty,
                           0 unsold_amount
                      FROM au_order_process_trans aop,
                           apps.hz_cust_site_uses_all@hrtoebs hcsu,
                           apps.ar_customers@hrtoebs ar
                     WHERE aop.au_ord_ar_int_pub_date BETWEEN p_from_date
                                                          AND p_to_date
                       AND aop.au_ord_ar_int_inv_org =
                                     NVL (p_org_id, aop.au_ord_ar_int_inv_org)
                       AND ar.customer_id =
                                           NVL (p_customer_id, ar.customer_id)
                       AND aop.au_ord_ar_int_dak =
                                            NVL (p_dak, aop.au_ord_ar_int_dak)
                       AND aop.au_ord_ar_int_cust_id = ar.customer_id
                       AND aop.au_ord_ar_int_ship_to = hcsu.site_use_id
                       AND hcsu.org_id = 288
                       AND NVL (aop.au_ord_ar_int_amount, 0) <> 0
                    UNION ALL
                    SELECT arr.au_rma_inv_org, ar.customer_name,
                           ar.customer_number, ar.customer_id, arr.au_rma_dak,
                           hcsu.site_use_id, hcsu.LOCATION,
                           arr.au_rma_supply_dt, 0, 0, 0,
                           NVL (arr.au_rma_rec_recv_qty, 0) recv_qty,
                           NVL (arr.au_rma_rec_short_qty, 0) recv_short_qty,
                           NVL (arr.au_rma_rec_lost_qty, 0) recv_lost_qty,
                           (  NVL (arr.au_rma_rec_recv_qty, 0)
                            + NVL (arr.au_rma_rec_short_qty, 0)
                            + NVL (arr.au_rma_rec_lost_qty, 0)
                           ) total_recv_qty,
                           NVL (arr.au_rma_acc_accp_qty, 0) allowd_qty,
                           NVL (arr.au_rma_acc_short_qty, 0) allowd_short_qty,
                           NVL (arr.au_rma_acc_lost_qty, 0) allowd_lost_qty,
                           (  NVL (arr.au_rma_acc_accp_qty, 0)
                            + NVL (arr.au_rma_acc_short_qty, 0)
                            + NVL (arr.au_rma_acc_lost_qty, 0)
                           ) total_allowd_qty,
                           (NVL (arr.au_rma_cm_rate, 0)) unsold_amount
                      FROM au_rma_return arr,
                           apps.hz_cust_site_uses_all@hrtoebs hcsu,
                           apps.ar_customers@hrtoebs ar
                     WHERE arr.au_rma_recv_date BETWEEN p_from_date AND p_to_date
                       AND arr.au_rma_inv_org =
                                            NVL (p_org_id, arr.au_rma_inv_org)
                       AND arr.au_rma_cust_id = ar.customer_id
                       AND arr.au_rma_ship_to = hcsu.site_use_id
                       AND ar.customer_id =
                                           NVL (p_customer_id, ar.customer_id)
                       AND arr.au_rma_dak = NVL (p_dak, arr.au_rma_dak)
                       AND hcsu.org_id = 288)
          GROUP BY au_ord_ar_int_inv_org,
                   customer_name,
                   customer_number,
                   customer_id,
                   au_ord_ar_int_dak,
                   site_use_id,
                   LOCATION,
                   au_ord_ar_int_pub_date);

      v_dak        VARCHAR2 (120) := NULL;
      v_dak_code   VARCHAR2 (30)  := NULL;
      v_product    VARCHAR2 (80)  := NULL;
      v_supp       NUMBER         := 0;
   BEGIN
      IF p_type = 'SD'
      THEN
         BEGIN
            FOR fetch2 IN fetch1
            LOOP
-------------------------------------find product ---------------------------------
               BEGIN
                  SELECT product
                    INTO v_product
                    FROM xxau_customer_ship_to_merg
                   WHERE customer_id = fetch2.customer_id
                     AND ship_to = fetch2.site_use_id;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_product := 'Amar Ujala';
                  WHEN OTHERS
                  THEN
                     v_product := 'Amar Ujala';
               END;

------------------------------------
               IF fetch2.supply_copies = 0
               THEN
                  v_supp := ROUND (((fetch2.total_allowd_qty * 100) / 1), 2);
               ELSE
                  v_supp :=
                     ROUND ((  (fetch2.total_allowd_qty * 100)
                             / fetch2.supply_copies
                            ),
                            2
                           );
               END IF;

               INSERT INTO xxau_circ_flctn_rpt
                           (inv_org,
                            customer_name, customer_number,
                            customer_id, site_use_id,
                            LOCATION, dak_name, dak_code,
                            product, pub_date,
                            supply_copies, supply_amount,
                            subs_copeis, recv_qty,
                            recv_short, recv_lost,
                            total_rcv_qty, unsold_qty,
                            unsold_short, unsold_lost,
                            total_unsold_qty, unsold_amount,
                            nps, unsold_percent
                           )
                    VALUES (fetch2.au_ord_ar_int_inv_org,
                            fetch2.customer_name, fetch2.customer_number,
                            fetch2.customer_id, fetch2.site_use_id,
                            fetch2.LOCATION, v_dak, fetch2.au_ord_ar_int_dak,
                            v_product, fetch2.au_ord_ar_int_pub_date,
                            fetch2.supply_copies, fetch2.supply_amount,
                            fetch2.subs_copies, fetch2.recv_qty,
                            fetch2.recv_short_qty, fetch2.recv_lost_qty,
                            fetch2.total_recv_qty, fetch2.total_allowd_qty,
                            fetch2.allowd_short_qty, fetch2.allowd_lost_qty,
                            fetch2.total_allowd_qty, fetch2.unsold_amount,
                            fetch2.nps, v_supp
                           );
            END LOOP;
         END;
      ELSE
         BEGIN
            FOR fetch2 IN fetch3
            LOOP
-------------------------------------find product ---------------------------------
               BEGIN
                  SELECT product
                    INTO v_product
                    FROM xxau_customer_ship_to_merg
                   WHERE customer_id = fetch2.customer_id
                     AND ship_to = fetch2.site_use_id;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_product := 'Amar Ujala';
                  WHEN OTHERS
                  THEN
                     v_product := 'Amar Ujala';
               END;

------------------------------------
               IF fetch2.supply_copies = 0
               THEN
                  v_supp := ROUND (((fetch2.total_allowd_qty * 100) / 1), 2);
               ELSE
                  v_supp :=
                     ROUND ((  (fetch2.total_allowd_qty * 100)
                             / fetch2.supply_copies
                            ),
                            2
                           );
               END IF;

               INSERT INTO xxau_circ_flctn_rpt
                           (inv_org,
                            customer_name, customer_number,
                            customer_id, site_use_id,
                            LOCATION, dak_name, dak_code,
                            product, pub_date,
                            supply_copies, supply_amount,
                            subs_copeis, recv_qty,
                            recv_short, recv_lost,
                            total_rcv_qty, unsold_qty,
                            unsold_short, unsold_lost,
                            total_unsold_qty, unsold_amount,
                            nps, unsold_percent
                           )
                    VALUES (fetch2.au_ord_ar_int_inv_org,
                            fetch2.customer_name, fetch2.customer_number,
                            fetch2.customer_id, fetch2.site_use_id,
                            fetch2.LOCATION, v_dak, fetch2.au_ord_ar_int_dak,
                            v_product, fetch2.au_ord_ar_int_pub_date,
                            fetch2.supply_copies, fetch2.supply_amount,
                            fetch2.subs_copies, fetch2.recv_qty,
                            fetch2.recv_short_qty, fetch2.recv_lost_qty,
                            fetch2.total_recv_qty, fetch2.total_allowd_qty,
                            fetch2.allowd_short_qty, fetch2.allowd_lost_qty,
                            fetch2.total_allowd_qty, fetch2.unsold_amount,
                            fetch2.nps, v_supp
                           );
            END LOOP;
         END;
      END IF;
   END xxau_cir_flctu_report;

   PROCEDURE xxau_create_ap_inv_p (
      errbuff    OUT   NUMBER,
      retcode    OUT   NUMBER,
      p_source         VARCHAR2
   )
   IS
      l_error_msg             VARCHAR2 (2000) := NULL;
      l_invoice_id            NUMBER;
      l_inv_line_id           NUMBER;
      l_count                 NUMBER;
      l_location_id           NUMBER;
      l_vendor_id             NUMBER;
      l_vendor_site_id        NUMBER;
      l_tax_category_id       NUMBER;
      l_invoice_type          VARCHAR2 (20);
      l_hsn_code              VARCHAR2 (30);
      v_gl_code               NUMBER;
      v_term_id               NUMBER;
      ln_id_flex_num          NUMBER;
      v_method                VARCHAR2 (30);
      l_organization_id       NUMBER;
      v_jai_interface_lines   NUMBER;
      v_jai_interface_tax     NUMBER;
      v_tax_amount            NUMBER;
      l_orig_trx_id           NUMBER;
      l_orig_trx_date         DATE;

      CURSOR cinvoice (p_source VARCHAR2)
      IS
         SELECT   operating_unit, ORGANIZATION, header_num, invoice_num,
                  vendor_num, vendor_site_code, invoice_amount, description,
                  hsn_code, unit, tax_invoice_date, transaction_curr,
                  gl_date, source1, recoverable_flag, mobile_number
             FROM aucustom.xxau_create_ap_inv_master
            WHERE line_num = 1
              AND NVL (process_flag, 'N') = 'N'
              --AND invoice_num='SKP/18-19/CN-114'
              ---AND header_num BETWEEN 1 AND 2
              AND source1 = p_source
         ORDER BY header_num;

      CURSOR clines (
         l_header_num     NUMBER,
         l_org_id         NUMBER,
         l_organization   NUMBER,
         p_source1        VARCHAR2,
         p_inv            VARCHAR2
      )
      IS
         SELECT operating_unit, line_num, line_amount, description, unit,
                location1, division_location, department, tax_category,
                original_tax_invoice_num, original_tax_invoice_date,
                account1 expense_account, activity_code, tax_type
           FROM aucustom.xxau_create_ap_inv_master
          WHERE header_num = l_header_num
            AND operating_unit = l_org_id
            AND ORGANIZATION = l_organization
            AND source1 = p_source1
            AND invoice_num = p_inv;

      CURSOR ctax_lines (l_tax_category_id IN NUMBER)
      IS
         SELECT jtcl.tax_rate_id, jtcl.line_number, jtcl.tax_type_id,
                jtr.tax_rate_name, jtrd.tax_rate_percentage
           FROM jai_tax_category_lines@hrtoebs jtcl,
                jai_tax_rates@hrtoebs jtr,
                jai_tax_rate_details@hrtoebs jtrd
          WHERE jtcl.tax_category_id = l_tax_category_id
            AND jtcl.tax_type_id = jtr.tax_type_id
            AND jtr.tax_rate_id = jtrd.tax_rate_id
            AND jtcl.tax_rate_id = jtrd.tax_rate_id;
   BEGIN
      BEGIN
         l_error_msg := NULL;

         IF l_error_msg IS NULL
         THEN
            BEGIN
               FOR vinvoice IN cinvoice (p_source)
               LOOP
                  l_error_msg := NULL;
                  l_invoice_id := NULL;
                  l_inv_line_id := NULL;
                  l_location_id := NULL;
                  l_vendor_id := NULL;
                  l_vendor_site_id := NULL;
                  l_tax_category_id := NULL;
                  l_invoice_type := NULL;
                  v_gl_code := NULL;

                  IF vinvoice.invoice_amount >= 0
                  THEN
                     l_invoice_type := 'STANDARD';
                  ELSE
                     l_invoice_type := 'CREDIT';
                  END IF;

                  BEGIN
                     SELECT tt.location_id, tt.organization_id
                       INTO l_location_id, l_organization_id
                       FROM hr_all_organization_units@hrtoebs tt
                      WHERE tt.organization_id = vinvoice.ORGANIZATION
                        AND (tt.NAME LIKE 'AUPL%' OR tt.NAME LIKE 'DIV%');
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        l_error_msg :=
                              'error in organization-'
                           || vinvoice.ORGANIZATION
                           || '-and header num-'
                           || vinvoice.header_num;
                     WHEN OTHERS
                     THEN
                        l_error_msg :=
                              'error in organization-'
                           || vinvoice.ORGANIZATION
                           || '-and header num-'
                           || vinvoice.header_num;
                  END;

                  BEGIN
                     SELECT vendor_id, payment_method_lookup_code
                       INTO l_vendor_id, v_method
                       FROM ap_suppliers@hrtoebs
                      WHERE segment1 = vinvoice.vendor_num
                        AND enabled_flag = 'Y'
                        AND NVL (end_date_active, TRUNC (SYSDATE)) >
                                                            TRUNC (SYSDATE)
                                                            - 1;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        l_error_msg :=
                              'error in vendor-'
                           || vinvoice.vendor_num
                           || '-and header num-'
                           || vinvoice.header_num;
                     WHEN OTHERS
                     THEN
                        l_error_msg :=
                              'error in vendor-'
                           || vinvoice.vendor_num
                           || '-and header num-'
                           || vinvoice.header_num;
                  END;

                  BEGIN
                     SELECT vendor_site_id, terms_id
                       ----, payment_method_lookup_code
                     INTO   l_vendor_site_id, v_term_id                  ----,
                       FROM ap_supplier_sites_all@hrtoebs
                      WHERE vendor_id = l_vendor_id
                        AND UPPER (vendor_site_code) =
                                             UPPER (vinvoice.vendor_site_code)
                        AND org_id = vinvoice.operating_unit;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        l_error_msg :=
                              'error in vendor site-'
                           || UPPER (vinvoice.vendor_site_code)
                           || '-and header num-'
                           || vinvoice.header_num;
                     WHEN OTHERS
                     THEN
                        l_error_msg :=
                              'error in vendor site-'
                           || UPPER (vinvoice.vendor_site_code)
                           || '-and header num-'
                           || vinvoice.header_num;
                  END;

                  FOR check_cat IN clines (vinvoice.header_num,
                                           vinvoice.operating_unit,
                                           vinvoice.ORGANIZATION,
                                           vinvoice.source1,
                                           vinvoice.invoice_num
                                          )
                  LOOP
                     --------------------------check category-----------------------------
                     IF check_cat.tax_category IS NOT NULL
                     THEN
                        BEGIN
                           SELECT tax_category_id
                             INTO l_tax_category_id
                             FROM jai_tax_categories@hrtoebs
                            WHERE UPPER (tax_category_name) =
                                                UPPER (check_cat.tax_category)
                              AND org_id = vinvoice.operating_unit
                              AND NVL (effective_to, TRUNC (SYSDATE)) >
                                                            TRUNC (SYSDATE)
                                                            - 1;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              l_error_msg :=
                                    'error in tax category-'
                                 || UPPER (check_cat.tax_category)
                                 || '-and header num-'
                                 || vinvoice.header_num;
                              l_tax_category_id := NULL;
                           WHEN OTHERS
                           THEN
                              l_error_msg :=
                                    'error in tax category-'
                                 || UPPER (check_cat.tax_category)
                                 || '-and header num-'
                                 || vinvoice.header_num;
                              l_tax_category_id := NULL;
                        END;
                     END IF;

                     ----------------------------check internal invoice exist or not-----------------------------
                     IF check_cat.original_tax_invoice_num IS NOT NULL
                     THEN
                        BEGIN
                           SELECT invoice_id, invoice_date
                             INTO l_orig_trx_id, l_orig_trx_date
                             FROM apps.ap_invoices_all@hrtoebs
                            WHERE invoice_num =
                                            check_cat.original_tax_invoice_num
                              AND invoice_date =
                                           check_cat.original_tax_invoice_date
                              AND vendor_id = l_vendor_id
                              AND vendor_site_id = l_vendor_site_id;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              l_error_msg :=
                                    'original invoice not found-'
                                 || UPPER (check_cat.original_tax_invoice_num)
                                 || '-and header num-'
                                 || check_cat.original_tax_invoice_num;
                              l_orig_trx_id := NULL;
                              l_orig_trx_date := NULL;
                           WHEN OTHERS
                           THEN
                              l_error_msg :=
                                    'original invoice not found-'
                                 || UPPER (check_cat.original_tax_invoice_num)
                                 || '-and header num-'
                                 || check_cat.original_tax_invoice_num;
                              l_orig_trx_id := NULL;
                              l_orig_trx_date := NULL;
                        END;
                     END IF;
                  END LOOP;

                  IF l_error_msg IS NULL
                  THEN
                     SELECT ap_invoices_interface_s.NEXTVAL@hrtoebs
                       INTO l_invoice_id
                       FROM DUAL;

                     INSERT INTO ap_invoices_interface@hrtoebs
                                 (invoice_id, invoice_num,
                                  invoice_type_lookup_code, vendor_id,
                                  vendor_site_id, invoice_amount,
                                  invoice_date,
                                  description,
                                  SOURCE,
                                  org_id,
                                  calc_tax_during_import_flag,
                                  add_tax_to_inv_amt_flag,
                                  doc_category_code, terms_id,
                                  invoice_currency_code,
                                  payment_method_lookup_code, gl_date,
                                  GROUP_ID                   ----, attribute4,
                                  ---attribute_category
                                 --- supplier_tax_invoice_number
                                 )
                          VALUES (l_invoice_id, vinvoice.invoice_num,
                                  l_invoice_type, l_vendor_id,
                                  l_vendor_site_id, vinvoice.invoice_amount,
                                  vinvoice.tax_invoice_date,
                                  vinvoice.description,
                                  'MANUAL INVOICE ENTRY',
                                  vinvoice.operating_unit,
                                  DECODE (l_tax_category_id, NULL, NULL, 'Y'),
                                  DECODE (l_tax_category_id, NULL, NULL, 'Y'),
                                  NULL, v_term_id,
                                  vinvoice.transaction_curr,
                                  v_method, vinvoice.gl_date,
                                  vinvoice.source1
                                                 ----, vinvoice.mobile_number,
                                 ---'India Distributions'
                                 );

                     FOR vlines IN clines (vinvoice.header_num,
                                           vinvoice.operating_unit,
                                           vinvoice.ORGANIZATION,
                                           vinvoice.source1,
                                           vinvoice.invoice_num
                                          )
                     LOOP
                        BEGIN
                           SELECT code_combination_id
                             INTO v_gl_code
                             FROM apps.gl_code_combinations_kfv@hrtoebs x
                            WHERE x.concatenated_segments =
                                        vlines.unit
                                     || '.'
                                     || vlines.location1
                                     || '.'
                                     || vlines.division_location  ------ '999'
                                     || '.'
                                     || vlines.department
                                     || '.'
                                     || vlines.expense_account
                                     || '.'
                                     || vlines.activity_code
                                     || '.'
                                     || '999'
                                     || '.'
                                     || '999'
                                     || '.'
                                     || '999'
                                     || '.'
                                     || '999';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              BEGIN
                                 SELECT id_flex_num
                                   INTO ln_id_flex_num
                                   FROM apps.fnd_id_flex_structures@hrtoebs
                                  WHERE id_flex_code = 'GL#'
                                    AND id_flex_structure_code =
                                                       'AUPL_Chart_Of_Account';
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    ln_id_flex_num := NULL;
                              END;

                              v_gl_code :=
                                 fnd_flex_ext.get_ccid@hrtoebs
                                    (application_short_name      => 'SQLGL',
                                     key_flex_code               => 'GL#',
                                     structure_number            => ln_id_flex_num,
                                     validation_date             => SYSDATE,
                                     concatenated_segments       =>    vlines.unit
                                                                    || '.'
                                                                    || vlines.location1
                                                                    || '.'
                                                                    || vlines.division_location
                                                                    || '.'
                                                                    || vlines.department
                                                                    || '.'
                                                                    || vlines.expense_account
                                                                    || '.'
                                                                    || vlines.activity_code
                                                                    || '.'
                                                                    || '999'
                                                                    || '.'
                                                                    || '999'
                                                                    || '.'
                                                                    || '999'
                                                                    || '.'
                                                                    || '999'
                                    );
                        END;

                        SELECT ap_invoice_lines_interface_s.NEXTVAL@hrtoebs
                          INTO l_inv_line_id
                          FROM DUAL;

                        DBMS_OUTPUT.put_line (   'transaction_num'
                                              || vinvoice.invoice_num
                                             );
                        DBMS_OUTPUT.put_line ('l_inv_line_id' || l_inv_line_id);

                        INSERT INTO ap_invoice_lines_interface@hrtoebs
                                    (invoice_id, invoice_line_id,
                                     line_number, line_type_lookup_code,
                                     amount, description,
                                     org_id, dist_code_combination_id,
                                     reference_key1,
                                     reference_key2,
                                     reference_key3,
                                     accounting_date, attribute10,
                                     attribute_category
                                    )
                             VALUES (l_invoice_id, l_inv_line_id,
                                     vlines.line_num, 'ITEM',
                                     vlines.line_amount, vlines.description,
                                     vlines.operating_unit, v_gl_code,
                                     ---- Account Hard coded as per the user requirement
                                     DECODE (vlines.tax_category,
                                             NULL, NULL,
                                             vinvoice.invoice_num
                                            ),
                                     DECODE (vlines.tax_category,
                                             NULL, NULL,
                                             vlines.line_num
                                            ),
                                     DECODE (vlines.tax_category,
                                             NULL, NULL,
                                             'OFI TAX IMPORT'
                                            ),
                                     vinvoice.gl_date, vlines.tax_type,
                                     'Invoice Tax Nature'
                                    );

                        IF vlines.tax_category IS NOT NULL
                        THEN
                           v_jai_interface_lines := NULL;

                           SELECT jai_interface_lines_all_s.NEXTVAL@hrtoebs
                             INTO v_jai_interface_lines
                             FROM DUAL;

                           DBMS_OUTPUT.put_line (   ' v_jai_interface_lines'
                                                 || v_jai_interface_lines
                                                );

                           INSERT INTO jai_interface_lines_all@hrtoebs
                                       (interface_line_id,
                                        transaction_num,
                                        transaction_line_num,
                                        --- internal_trx_id,
                                        batch_source_name,
                                        org_id,
                                        organization_id, location_id,
                                        party_id, party_site_id,
                                        import_module, tax_category_id,
                                        taxable_event,
                                        intended_use,
                                        hsn_code, creation_date,
                                        last_updated_by, last_update_date,
                                        last_update_login, created_by
                                       )
                                VALUES (v_jai_interface_lines,
                                        vinvoice.invoice_num,
                                        vlines.line_num,

                                        ---l_orig_trx_id,
                                        'OFI TAX IMPORT',
                                        vinvoice.operating_unit,
                                        l_organization_id, l_location_id,
                                        l_vendor_id, l_vendor_site_id,
                                        'AP', l_tax_category_id,
                                        'STANDARD',
                                        DECODE (vinvoice.recoverable_flag,
                                                'Y', 'RECOVERABLE'
                                               ),
                                        vinvoice.hsn_code, SYSDATE,
                                        0, SYSDATE,
                                        -1, 0
                                       );

                           FOR vtax_lines IN ctax_lines (l_tax_category_id)
                           LOOP
                              v_jai_interface_tax := NULL;

                              SELECT jai_interface_tax_lines_all_s.NEXTVAL@hrtoebs
                                INTO v_jai_interface_tax
                                FROM DUAL;

                              v_tax_amount := 0;

                              IF UPPER (vinvoice.source1) LIKE 'VODA%'
                              THEN
                                 v_tax_amount :=
                                    ROUND ((  vlines.line_amount
                                            * vtax_lines.tax_rate_percentage
                                            / 100
                                           ),
                                           2
                                          );
                              ELSE
                                 v_tax_amount :=
                                    ROUND ((  vlines.line_amount
                                            * vtax_lines.tax_rate_percentage
                                            / 100
                                           )
                                          );
                              END IF;

                              INSERT INTO jai_interface_tax_lines_all@hrtoebs
                                          (interface_tax_line_id,
                                           interface_line_id,
                                           party_id, party_site_id,
                                           import_module, transaction_num,
                                           transaction_line_num,
                                           tax_line_no,
                                           external_tax_code, qty_rate,
                                           precedence_1, precedence_2,
                                           precedence_3, precedence_4,
                                           precedence_5, precedence_6,
                                           precedence_7, precedence_8,
                                           precedence_9, precedence_10,
                                           tax_id,
                                           tax_rate,
                                           uom, tax_amount,
                                           func_tax_amount,
                                           base_tax_amount,
                                           inclusive_tax_flag,
                                           code_combination_id,
                                           creation_date, created_by,
                                           last_update_date,
                                           last_update_login,
                                           last_updated_by, precedence_11,
                                           precedence_12, precedence_13,
                                           precedence_14, precedence_15,
                                           precedence_16, precedence_17,
                                           precedence_18, precedence_19,
                                           precedence_20,
                                           tax_invoice_num,
                                           tax_invoice_date, user_entered_av
                                          )
                                   VALUES (v_jai_interface_tax,
                                           v_jai_interface_lines,
                                           l_vendor_id, l_vendor_site_id,
                                           'AP', vinvoice.invoice_num,
                                           vlines.line_num,
                                           vtax_lines.line_number,
                                           'Null'          --EXTERNAL TAX CODE
                                                 , '',
                                           0                    --PRECEDENCE_1
                                            , '',
                                           '', '',
                                           '', '',
                                           '', '',
                                           '', '',
                                           vtax_lines.tax_rate_id   ----TAX_ID
                                                                 ,
                                           vtax_lines.tax_rate_percentage
                                                                         ---TAX_RATE
                              ,
                                           '', v_tax_amount       --TAX_AMOUNT
                                                           ,
                                           v_tax_amount      --FUNC TAX AMOUNT
                                                       ,
                                           v_tax_amount      --BASE TAX AMOUNT
                                                       ,
                                           'N'                --INCLUSIVE FLAG
                                              ,
                                           '',
                                           SYSDATE, 0,
                                           SYSDATE,
                                           -1,
                                           0, '',
                                           '', '',
                                           '', '',
                                           '', '',
                                           '', '',
                                           '',
                                           ''     --------vInvoice.invoice_num
                                             ,
                                           '', ''
                                          );
                           END LOOP;
                        END IF;
                     END LOOP;

                     UPDATE aucustom.xxau_create_ap_inv_master
                        SET process_flag = 'Y',
                            error_msz = 'Success'
                      WHERE header_num = vinvoice.header_num
                        AND invoice_num = vinvoice.invoice_num
                        AND tax_invoice_date = vinvoice.tax_invoice_date
                        AND source1 = p_source;
                  -- fnd_file.put_line (fnd_file.output,
                               --          vinvoice.header_num
                                --      || '                    '
                                 --     || vinvoice.invoice_num
                                  ---   );
                  ELSE
                     BEGIN
                        UPDATE aucustom.xxau_create_ap_inv_master
                           SET process_flag = 'E',
                               error_msz = l_error_msg
                         WHERE header_num = vinvoice.header_num
                           AND invoice_num = vinvoice.invoice_num
                           AND tax_invoice_date = vinvoice.tax_invoice_date
                           AND source1 = p_source;
                     END;
                  END IF;                                   ----errro check if
               END LOOP;
            ---- COMMIT;
            END;
         ELSE
            ----fnd_file.put_line (fnd_file.LOG, 'Error in above mentioned records');
            retcode := 1;
         END IF;
      END;
   END xxau_create_ap_inv_p;

   PROCEDURE xxau_update_tax_adv_dtl (
      errbuff    OUT   NUMBER,
      retcode    OUT   NUMBER,
      p_source         VARCHAR2
   )
   IS
      CURSOR fetch1 (p_source1 VARCHAR2)
      IS
         (SELECT DISTINCT tt.invoice_id, tt.invoice_num, tt.invoice_date,
                          tt1.original_tax_invoice_num,
                          tt1.original_tax_invoice_date
                     FROM apps.ap_invoices_all@hrtoebs tt,
                          aucustom.xxau_create_ap_inv_master tt1
                    WHERE EXISTS (
                             SELECT 'y'
                               FROM aucustom.xxau_create_ap_inv_master
                              WHERE process_flag = 'Y'
                                AND invoice_num = tt.invoice_num
                                AND tax_invoice_date = tt.invoice_date
                                AND source1 = p_source1
                                AND invoice_amount < 0)
                      AND EXISTS (
                             SELECT 'y'
                               FROM apps.jai_tax_det_factors@hrtoebs
                              WHERE trx_id = tt.invoice_id
                                AND original_tax_invoice_num IS NULL)
                      AND tt1.invoice_num = tt.invoice_num
                      AND tt1.tax_invoice_date = tt.invoice_date
                      AND tt1.source1 = p_source1
                      AND tt1.original_tax_invoice_num IS NOT NULL);
   BEGIN
      FOR fetch2 IN fetch1 (p_source)
      LOOP
         UPDATE apps.jai_tax_det_factors@hrtoebs
            SET original_tax_invoice_num = fetch2.original_tax_invoice_num,
                original_tax_invoice_date = fetch2.original_tax_invoice_date,
                tax_invoice_num = fetch2.invoice_num,
                tax_invoice_date = fetch2.invoice_date
          WHERE trx_id = fetch2.invoice_id;

         UPDATE apps.jai_tax_lines@hrtoebs
            SET tax_invoice_num = fetch2.invoice_num,
                tax_invoice_date = fetch2.invoice_date
          WHERE trx_id = fetch2.invoice_id;
      END LOOP;
   END xxau_update_tax_adv_dtl;

   PROCEDURE xxau_error_up (errbuff OUT NUMBER, retcode OUT NUMBER)
   IS
      CURSOR fetch_data (
         pinvoice_num     VARCHAR2,
         p_invoice_date   DATE,
         p_vendor_num     VARCHAR2,
         p_gl_date        DATE
      )
      IS
         (SELECT aia.invoice_num, aia.invoice_date, aia.gl_date,
                 pv.segment1 vendor_num, air.reject_lookup_code error_msz
            FROM ap_invoices_interface@hrtoebs aia,
                 po_vendors@hrtoebs pv,
                 ap_interface_rejections@hrtoebs air
           WHERE SOURCE = 'MANUAL INVOICE ENTRY'
             AND status = 'REJECTED'
             AND aia.vendor_id = pv.vendor_id
             AND aia.invoice_num = pinvoice_num
             AND aia.invoice_date = p_invoice_date
             AND aia.gl_date = p_gl_date
             AND pv.segment1 = p_vendor_num
             AND aia.invoice_id = air.parent_id);

      CURSOR fetch_data2 (
         pinvoice_num     VARCHAR2,
         p_invoice_date   DATE,
         p_vendor_num     VARCHAR2,
         p_gl_date        DATE
      )
      IS
         (SELECT aia.invoice_num, aia.invoice_date, aia.gl_date,
                 pv.segment1 vendor_num, air.reject_lookup_code error_msz
            FROM ap_invoices_interface@hrtoebs aia,
                 po_vendors@hrtoebs pv,
                 ap_interface_rejections@hrtoebs air,
                 ap_invoice_lines_interface@hrtoebs ail
           WHERE SOURCE = 'MANUAL INVOICE ENTRY'
             AND status = 'REJECTED'
             AND aia.vendor_id = pv.vendor_id
             AND aia.invoice_num = pinvoice_num
             AND aia.invoice_date = p_invoice_date
             AND aia.gl_date = p_gl_date
             AND pv.segment1 = p_vendor_num
             AND ail.invoice_line_id = air.parent_id
             AND ail.invoice_id = aia.invoice_id);

      CURSOR fetch_data3
      IS
         (SELECT DISTINCT aia.invoice_num, aia.invoice_date, aia.gl_date,
                          pv.segment1 vendor_num, aia.GROUP_ID,
                          aia.invoice_id
                     FROM ap_invoices_interface@hrtoebs aia,
                          po_vendors@hrtoebs pv
                    WHERE SOURCE = 'MANUAL INVOICE ENTRY'
                      AND status = 'REJECTED'
                      AND aia.vendor_id = pv.vendor_id);

      v_error   VARCHAR2 (2000) := NULL;
   BEGIN
      FOR fetch3 IN fetch_data3
      LOOP
         v_error := NULL;

         FOR fetch1 IN fetch_data (fetch3.invoice_num,
                                   fetch3.invoice_date,
                                   fetch3.vendor_num,
                                   fetch3.gl_date
                                  )
         LOOP
            v_error := v_error || ',' || fetch1.error_msz;
         END LOOP;

         FOR fetch1 IN fetch_data2 (fetch3.invoice_num,
                                    fetch3.invoice_date,
                                    fetch3.vendor_num,
                                    fetch3.gl_date
                                   )
         LOOP
            v_error := v_error || ',' || fetch1.error_msz;
         END LOOP;

         UPDATE aucustom.xxau_create_ap_inv_master
            SET error_msz = v_error,
                process_flag = 'E'
          WHERE invoice_num = fetch3.invoice_num
            AND tax_invoice_date = fetch3.invoice_date
            AND vendor_num = fetch3.vendor_num
            AND gl_date = fetch3.gl_date
            AND UPPER (source1) = UPPER (fetch3.GROUP_ID);

         DELETE      jai_interface_lines_all@hrtoebs
               WHERE transaction_num = fetch3.invoice_num;

         DELETE      jai_interface_tax_lines_all@hrtoebs
               WHERE transaction_num = fetch3.invoice_num;

         DELETE      ap_invoice_lines_interface@hrtoebs
               WHERE invoice_id = fetch3.invoice_id;

         DELETE      ap_invoices_interface@hrtoebs
               WHERE invoice_num = fetch3.invoice_num
                 AND invoice_date = fetch3.invoice_date
                 AND invoice_id = fetch3.invoice_id;
      ---- COMMIT;
      END LOOP;
   END xxau_error_up;

   PROCEDURE validate_imported_invoices (errbuff OUT NUMBER, retcode OUT NUMBER)
   IS
      CURSOR cur_imp_invoices
      IS
         (SELECT DISTINCT pv.vendor_id,
                          TO_CHAR (tt.tax_invoice_date,
                                   'YYYY/MM/DD HH24:MI:SS'
                                  ) tax_invoice_date,
                          tt.tax_invoice_date tax_invoice_date2,
                          tt.vendor_num, tt.source1
                     FROM ap_invoices_all@hrtoebs aia,
                          xxau_create_ap_inv_master tt,
                          po_vendors@hrtoebs pv
                    WHERE aia.invoice_num = tt.invoice_num
                      AND aia.invoice_date = tt.tax_invoice_date
                      AND aia.vendor_id = pv.vendor_id
                      AND pv.segment1 = tt.vendor_num
                      --AND UPPER(tt.source1) not like 'POLICY%'
                      --AND rownum<20
                      ----AND tt.invoice_num = '05IUP02814392396'
                      AND tt.process_flag = 'Y'
                      AND NVL (validate_flag, 'N') = 'N');

      CURSOR fetch3
      IS
         (SELECT aia.invoice_id, tt.mobile_number, tt.invoice_num,
                 aida.invoice_distribution_id, tt.invoice_num, tt.header_num,
                 tt.tax_invoice_date, tt.source1, tt.vendor_num
            FROM ap_invoices_all@hrtoebs aia,
                 xxau_create_ap_inv_master tt,
                 po_vendors@hrtoebs pv,
                 ap_invoice_distributions_all@hrtoebs aida
           WHERE aia.invoice_num = tt.invoice_num
             AND aia.invoice_date = tt.tax_invoice_date
             AND aia.vendor_id = pv.vendor_id
             AND pv.segment1 = tt.vendor_num
             AND tt.process_flag = 'Y'
             ---AND tt.validate_flag = 'C'
             AND UPPER (tt.source1) NOT LIKE 'POLICY%'
             AND aida.invoice_id = aia.invoice_id
             AND aida.line_type_lookup_code = 'ITEM'
             AND aida.attribute4 IS NULL);

      -- This condition is pickup invoices eligible for validation only
      ln_processed_cnt       NUMBER         DEFAULT 0;
      ln_failed_cnt          NUMBER         DEFAULT 0;
      ln_holds_cnt           NUMBER;
      lv_approval_status     VARCHAR2 (100);
      lv_funds_return_code   VARCHAR2 (100);
      l_sub_request_id       NUMBER         := NULL;
      l_resp_id              NUMBER         := NULL;
      l_app_id               NUMBER         := NULL;
      v_request_completed    BOOLEAN;
      v_request_id           NUMBER;
      v_phase                VARCHAR2 (80)  := NULL;
      v_status               VARCHAR2 (80)  := NULL;
      v_dev_phase            VARCHAR2 (30)  := NULL;
      v_dev_status           VARCHAR2 (30)  := NULL;
      v_message              VARCHAR2 (240);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      apps.fnd_global.apps_initialize@hrtoebs (1455, 51986, 200);

      FOR rec_imp_inv IN cur_imp_invoices
      LOOP
         IF UPPER (rec_imp_inv.source1) NOT LIKE 'ABCD%'
         THEN
            l_sub_request_id :=
               apps.fnd_request.submit_request@hrtoebs
                                               ('SQLAP',
                                                'APPRVL',
                                                'Invoice Validation',
                                                NULL,
                                                FALSE,
                                                288,
                                                'All',
                                                NULL,
                                                rec_imp_inv.tax_invoice_date,
                                                rec_imp_inv.tax_invoice_date,
                                                rec_imp_inv.vendor_id,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL
                                               --'N',
                                               --1000
                                               );
            COMMIT;
            DBMS_OUTPUT.put_line ('l_sub_request_id ' || l_sub_request_id);

            LOOP
               v_request_completed :=
                  apps.fnd_concurrent.wait_for_request@hrtoebs
                              (l_sub_request_id                  -- Request ID
                                               ,
                               0                              -- Time Interval
                                ,
                               0                         -- Total Time to wait
                                ,
                               v_phase
                                      -- Phase displyed on screen
                  ,
                               v_status          -- Status displayed on screen
                                       ,
                               v_dev_phase    -- Phase available for developer
                                          ,
                               v_dev_status  -- Status available for developer
                                           ,
                               v_message
                              -- Execution Message
                              );

               IF v_request_completed
               THEN
                  BEGIN
                     UPDATE aucustom.xxau_create_ap_inv_master
                        SET validate_flag = 'C',
                            v_error_msz =
                                  ' Invoice Validated.Status'
                               || v_message
                               || ln_holds_cnt
                      WHERE 1 = 1           ----header_num = fetch2.header_num
                        --AND invoice_num = rec_imp_inv.invoice_num
                        AND vendor_num = rec_imp_inv.vendor_num
                        AND source1 = rec_imp_inv.source1
                        AND process_flag = 'Y'
                        AND tax_invoice_date = rec_imp_inv.tax_invoice_date2;
                  END;

                  /*UPDATE aucustom.xxau_create_ap_inv_master
                     SET validate_flag = 'C',
                         v_error_msz =
                               ' Invoice Validated.Status'
                            || v_message
                            || ln_holds_cnt
                   WHERE header_num = rec_imp_inv.header_num
                     AND invoice_num = rec_imp_inv.invoice_num
                     AND tax_invoice_date = rec_imp_inv.tax_invoice_date
                     AND source1 = rec_imp_inv.source1;*/
                  COMMIT;
               END IF;

               EXIT WHEN v_request_completed;
            END LOOP;
         ELSE
            BEGIN
               UPDATE aucustom.xxau_create_ap_inv_master
                  SET validate_flag = 'C',
                      v_error_msz = 'No need Validate according to user'
                WHERE 1 = 1
                                            ----header_num = fetch2.header_num
                  --AND invoice_num = rec_imp_inv.invoice_num
                  AND vendor_num = rec_imp_inv.vendor_num
                  AND source1 = rec_imp_inv.source1
                  AND process_flag = 'Y'
                  AND tax_invoice_date = rec_imp_inv.tax_invoice_date2;

               COMMIT;
            END;
         END IF;
      END LOOP;
   END validate_imported_invoices;

   PROCEDURE xxau_update_dff_dist (errbuff OUT NUMBER, retcode OUT NUMBER)
   IS
      CURSOR fetch1
      IS
         (SELECT aia.invoice_id, tt.mobile_number, tt.invoice_num,
                 aida.invoice_distribution_id
            FROM ap_invoices_all@hrtoebs aia,
                 xxau_create_ap_inv_master tt,
                 po_vendors@hrtoebs pv,
                 ap_invoice_distributions_all@hrtoebs aida
           WHERE aia.invoice_num = tt.invoice_num
             AND aia.invoice_date = tt.tax_invoice_date
             AND aia.vendor_id = pv.vendor_id
             AND pv.segment1 = tt.vendor_num
             AND tt.process_flag = 'Y'
             AND tt.validate_flag = 'C'
             AND aida.invoice_id = aia.invoice_id
             AND UPPER (tt.source1) LIKE 'VODA%'
             AND aida.line_type_lookup_code = 'ITEM'
             AND aida.attribute4 IS NULL);
   BEGIN
      FOR fetch2 IN fetch1
      LOOP
         UPDATE ap_invoice_distributions_all@hrtoebs
            SET attribute_category = 'India Distributions',
                attribute4 = fetch2.mobile_number
          WHERE invoice_distribution_id = fetch2.invoice_distribution_id
            AND invoice_id = fetch2.invoice_id;
      END LOOP;
   END xxau_update_dff_dist;

   PROCEDURE xxau_ap_inv_load (
      p_operating_unit              NUMBER,
      p_organization                NUMBER,
      p_header_num                  NUMBER,
      p_line_num                    NUMBER,
      p_invoice_num                 VARCHAR2,
      p_tax_invoice_date            DATE,
      p_gl_date                     DATE,
      p_original_tax_invoice_num    VARCHAR2,
      p_original_tax_invoice_date   DATE,
      p_transaction_curr            VARCHAR2,
      p_vendor_num                  NUMBER,
      p_vendor_site_code            VARCHAR2,
      p_invoice_amount              NUMBER,
      p_description                 VARCHAR2,
      p_line_amount                 NUMBER,
      p_line_desc                   VARCHAR2,
      p_unit                        VARCHAR2,
      p_location1                   VARCHAR2,
      p_division_location           VARCHAR2,
      p_department                  VARCHAR2,
      p_account1                    VARCHAR2,
      p_activity_code               VARCHAR2,
      p_tax_category                VARCHAR2,
      p_hsn_code                    VARCHAR2,
      p_tax_type                    VARCHAR2,
      p_mobile_number               VARCHAR2,
      p_recoverable_flag            VARCHAR2,
      p_source1                     VARCHAR2
   )
   AS
      v_check        NUMBER;
      check_period   VARCHAR2 (2);
   BEGIN
      IF p_operating_unit IS NULL
      THEN
         raise_application_error (-20001, 'Operating Unit is mandatory');
      END IF;

      IF p_organization IS NULL
      THEN
         raise_application_error (-20001, 'Oraganization is mandatory');
      END IF;

      IF p_header_num IS NULL
      THEN
         raise_application_error (-20001, 'Header Number is mandatory');
      END IF;

      IF p_line_num IS NULL
      THEN
         raise_application_error (-20001, 'Line Number is mandatory');
      END IF;

      IF p_invoice_num IS NULL
      THEN
         raise_application_error (-20001, 'Invoice nunber is mandatory');
      END IF;

      IF p_tax_invoice_date IS NULL
      THEN
         raise_application_error (-20001, 'Invoice Date is mandatory');
      END IF;

      IF p_gl_date IS NULL
      THEN
         raise_application_error (-20001, 'Gl Date is mandatory');
      END IF;

      -------------------check Payable period is open or not  --------------------
      check_period := NULL;

      BEGIN
         BEGIN
            SELECT closing_status
              INTO check_period
              FROM gl_period_statuses@hrtoebs
             WHERE period_name = TO_CHAR (p_gl_date, 'MON-YY')
               AND application_id = 200;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               check_period := NULL;
            WHEN OTHERS
            THEN
               check_period := NULL;
         END;

         IF check_period <> 'O'
         THEN
            raise_application_error
                          (-20001,
                           'Payable Period has been closed for given GL Date'
                          );
         END IF;
      END;

      -------------------check GL period is open or not  --------------------
      check_period := NULL;

      BEGIN
         BEGIN
            SELECT closing_status
              INTO check_period
              FROM gl_period_statuses@hrtoebs
             WHERE period_name = TO_CHAR (p_gl_date, 'MON-YY')
               AND application_id = 101;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               check_period := NULL;
            WHEN OTHERS
            THEN
               check_period := NULL;
         END;

         IF check_period <> 'O'
         THEN
            raise_application_error
                               (-20001,
                                'GL Period has been closed for given GL Date'
                               );
         END IF;
      END;

      IF p_vendor_num IS NULL
      THEN
         raise_application_error (-20001, 'Vendor  is mandatory');
      END IF;

      IF p_vendor_site_code IS NULL
      THEN
         raise_application_error (-20001, 'Vendor Site is mandatory');
      END IF;

      IF p_invoice_amount IS NULL
      THEN
         raise_application_error (-20001, 'Invoice Amount is mandatory');
      END IF;

      IF p_description IS NULL
      THEN
         raise_application_error (-20001, 'Invoice Description is mandatory');
      END IF;

      -------------------check dublicate invoice number --------------------
      v_check := 0;

      BEGIN
         BEGIN
            SELECT COUNT (1)
              INTO v_check
              FROM apps.ap_invoices_all@hrtoebs
             WHERE invoice_num = p_invoice_num
               AND vendor_id = (SELECT vendor_id
                                  FROM po_vendors@hrtoebs
                                 WHERE segment1 = p_vendor_num);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_check := 0;
            WHEN OTHERS
            THEN
               v_check := 0;
         END;

         IF v_check > 0
         THEN
            raise_application_error
               (-20001,
                'Invoice Number are already exist for this vendor please chose another invoice number'
               );
         END IF;
      END;

      ---------------------------check original tax invoice in case is not null--------------------
      IF p_original_tax_invoice_num IS NOT NULL
      THEN
         BEGIN
            BEGIN
               SELECT COUNT (1)
                 INTO v_check
                 FROM apps.ap_invoices_all@hrtoebs
                WHERE invoice_num = p_original_tax_invoice_num
                  AND vendor_id = (SELECT vendor_id
                                     FROM apps.po_vendors@hrtoebs
                                    WHERE segment1 = p_vendor_num);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_check := 0;
               WHEN OTHERS
               THEN
                  v_check := 0;
            END;

            IF v_check = 0
            THEN
               raise_application_error
                  (-20001,
                   'Original tax invoice Number are not exist for this vendor please enter correct invoice number'
                  );
            END IF;
         END;
      END IF;

      IF p_line_amount IS NULL
      THEN
         raise_application_error (-20001, 'line amount is mandatory');
      END IF;

      IF p_line_desc IS NULL
      THEN
         raise_application_error (-20001, 'line Description is mandatory');
      END IF;

      IF p_unit IS NULL
      THEN
         raise_application_error (-20001, 'Company segment is mandatory');
      END IF;

      IF p_location1 IS NULL
      THEN
         raise_application_error (-20001, 'location is mandatory');
      END IF;

      IF p_division_location IS NULL
      THEN
         raise_application_error (-20001, 'Division location is mandatory');
      END IF;

      IF p_department IS NULL
      THEN
         raise_application_error (-20001, 'Department is mandatory');
      END IF;

      IF p_account1 IS NULL
      THEN
         raise_application_error (-20001, 'Natural Account is mandatory');
      END IF;

      IF p_activity_code IS NULL
      THEN
         raise_application_error (-20001, 'Activity is mandatory');
      END IF;

      IF p_source1 IS NULL
      THEN
         raise_application_error (-20001, 'Source is mandatory');
      END IF;

      INSERT INTO xxau_create_ap_inv_master
                  (operating_unit, ORGANIZATION, header_num,
                   line_num, invoice_num, tax_invoice_date, gl_date,
                   original_tax_invoice_num, original_tax_invoice_date,
                   transaction_curr, vendor_num, vendor_site_code,
                   invoice_amount, description, line_amount,
                   line_desc, unit, location1, division_location,
                   department, account1, activity_code, tax_category,
                   hsn_code, tax_type, mobile_number,
                   recoverable_flag, source1
                  )
           VALUES (p_operating_unit, p_organization, p_header_num,
                   p_line_num, p_invoice_num, p_tax_invoice_date, p_gl_date,
                   p_original_tax_invoice_num, p_original_tax_invoice_date,
                   p_transaction_curr, p_vendor_num, p_vendor_site_code,
                   p_invoice_amount, p_description, p_line_amount,
                   p_line_desc, p_unit, p_location1, p_division_location,
                   p_department, p_account1, p_activity_code, p_tax_category,
                   p_hsn_code, p_tax_type, p_mobile_number,
                   p_recoverable_flag, p_source1
                  );
   END xxau_ap_inv_load;

   PROCEDURE xxau_create_ap_myauartical (
      errbuff    OUT   NUMBER,
      retcode    OUT   NUMBER,
      p_source         VARCHAR2
   )
   IS
      l_error_msg             VARCHAR2 (2000) := NULL;
      l_invoice_id            NUMBER;
      l_inv_line_id           NUMBER;
      l_count                 NUMBER;
      l_location_id           NUMBER;
      l_vendor_id             NUMBER;
      l_vendor_site_id        NUMBER;
      l_tax_category_id       NUMBER;
      l_invoice_type          VARCHAR2 (20);
      l_hsn_code              VARCHAR2 (30);
      v_gl_code               NUMBER;
      v_term_id               NUMBER;
      ln_id_flex_num          NUMBER;
      v_method                VARCHAR2 (30);
      l_organization_id       NUMBER;
      v_jai_interface_lines   NUMBER;
      v_jai_interface_tax     NUMBER;
      v_tax_amount            NUMBER;
      l_orig_trx_id           NUMBER;
      l_orig_trx_date         DATE;
      v_category_code         VARCHAR2 (30);

      CURSOR cinvoice (p_source VARCHAR2)
      IS
         SELECT   operating_unit, ORGANIZATION, header_num, invoice_num,
                  vendor_num, vendor_site_code, invoice_amount, description,
                  hsn_code, unit, tax_invoice_date, transaction_curr,
                  gl_date, source1, recoverable_flag, mobile_number
             FROM aucustom.xxau_create_ap_inv_master1
            WHERE line_num = 1
              AND NVL (process_flag, 'N') = 'N'
              --AND invoice_num='SKP/18-19/CN-114'
              ---AND header_num BETWEEN 1 AND 2
              AND source1 = p_source
         ORDER BY header_num;

      CURSOR clines (
         l_header_num     NUMBER,
         l_org_id         NUMBER,
         l_organization   NUMBER,
         p_source1        VARCHAR2,
         p_inv            VARCHAR2
      )
      IS
         SELECT operating_unit, line_num, line_amount, description, unit,
                location1, division_location, department, tax_category,
                original_tax_invoice_num, original_tax_invoice_date,
                account1 expense_account, activity_code, tax_type
           FROM aucustom.xxau_create_ap_inv_master1
          WHERE header_num = l_header_num
            AND operating_unit = l_org_id
            AND ORGANIZATION = l_organization
            AND source1 = p_source1
            AND invoice_num = p_inv;

      CURSOR ctax_lines (l_tax_category_id IN NUMBER)
      IS
         SELECT jtcl.tax_rate_id, jtcl.line_number, jtcl.tax_type_id,
                jtr.tax_rate_name, jtrd.tax_rate_percentage
           FROM jai_tax_category_lines@hrtoebs jtcl,
                jai_tax_rates@hrtoebs jtr,
                jai_tax_rate_details@hrtoebs jtrd
          WHERE jtcl.tax_category_id = l_tax_category_id
            AND jtcl.tax_type_id = jtr.tax_type_id
            AND jtr.tax_rate_id = jtrd.tax_rate_id
            AND jtcl.tax_rate_id = jtrd.tax_rate_id;
   BEGIN
      BEGIN
         INSERT INTO aucustom.xxau_create_ap_inv_master1
            SELECT 288 operating_unit, 275 organization_id, 1 header_num,
                   1 line_num,
                      tranno
                   || '-'
                   || sname
                   || '-'
                   || TO_CHAR (pub_date, 'MON-YYYY') invoice_num,
                   pub_date tax_invoice_date, TRUNC (aprl_acc_date) gl_date,
                   NULL original_tax_invoice_num,
                   NULL original_tax_invoice_date, 'INR' transaction_curr,
                   (SELECT segment1
                      FROM ap_suppliers@hrtoebs
                     WHERE vendor_id = tt.vendor_id) vendor_num,
                   'CORP' vendor_site_code, amount invoice_amount,
                      'Article of '
                   || tranno
                   || '-'
                   || sname
                   || '-'
                   || TO_CHAR (pub_date, 'DD-MON-YYYY') description,
                   amount line_amount,
                      'Article of '
                   || tranno
                   || '-'
                   || sname
                   || '-'
                   || TO_CHAR (pub_date, 'DD-MON-YYYY') line_description,
                   112 unit, 9999 location1, 112 division_location,
                   104 department, 502120 account1, 9999 activity_code,
                   NULL tax_category, NULL hsn_code, NULL tax_type,
                   NULL mobile_number, NULL recoverable_flag,
                   'MYAUARTICAL' source1, NULL, NULL, NULL, NULL
              FROM xxmis.tran_edt_paymnt tt
             WHERE NVL (aprl_acc_sts, 'N') = 'Y'
               AND NOT EXISTS (
                      SELECT 'y'
                        FROM aucustom.xxau_create_ap_inv_master1
                       WHERE invoice_num =
                                   tt.tranno
                                || '-'
                                || tt.sname
                                || '-'
                                || TO_CHAR (tt.pub_date, 'MON-YYYY'));
      END;

      BEGIN
         l_error_msg := NULL;

         IF l_error_msg IS NULL
         THEN
            BEGIN
               FOR vinvoice IN cinvoice (p_source)
               LOOP
                  l_error_msg := NULL;
                  l_invoice_id := NULL;
                  l_inv_line_id := NULL;
                  l_location_id := NULL;
                  l_vendor_id := NULL;
                  l_vendor_site_id := NULL;
                  l_tax_category_id := NULL;
                  l_invoice_type := NULL;
                  v_gl_code := NULL;
                  v_category_code := NULL;

                  IF vinvoice.invoice_amount >= 0
                  THEN
                     l_invoice_type := 'STANDARD';
                  ELSE
                     l_invoice_type := 'CREDIT';
                  END IF;

                  BEGIN
                     SELECT tt.location_id, tt.organization_id
                       INTO l_location_id, l_organization_id
                       FROM hr_all_organization_units@hrtoebs tt
                      WHERE tt.organization_id = vinvoice.ORGANIZATION
                        AND (tt.NAME LIKE 'AUPL%' OR tt.NAME LIKE 'DIV%');
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        l_error_msg :=
                              'error in organization-'
                           || vinvoice.ORGANIZATION
                           || '-and header num-'
                           || vinvoice.header_num;
                     WHEN OTHERS
                     THEN
                        l_error_msg :=
                              'error in organization-'
                           || vinvoice.ORGANIZATION
                           || '-and header num-'
                           || vinvoice.header_num;
                  END;

                  BEGIN
                     SELECT vendor_id, payment_method_lookup_code
                       INTO l_vendor_id, v_method
                       FROM ap_suppliers@hrtoebs
                      WHERE segment1 = vinvoice.vendor_num
                        AND enabled_flag = 'Y'
                        AND NVL (end_date_active, TRUNC (SYSDATE)) >
                                                            TRUNC (SYSDATE)
                                                            - 1;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        l_error_msg :=
                              'error in vendor-'
                           || vinvoice.vendor_num
                           || '-and header num-'
                           || vinvoice.header_num;
                     WHEN OTHERS
                     THEN
                        l_error_msg :=
                              'error in vendor-'
                           || vinvoice.vendor_num
                           || '-and header num-'
                           || vinvoice.header_num;
                  END;

                  BEGIN
                     SELECT vendor_site_id, terms_id
                       ----, payment_method_lookup_code
                     INTO   l_vendor_site_id, v_term_id                  ----,
                       FROM ap_supplier_sites_all@hrtoebs
                      WHERE vendor_id = l_vendor_id
                        AND UPPER (vendor_site_code) =
                                             UPPER (vinvoice.vendor_site_code)
                        AND org_id = vinvoice.operating_unit;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        l_error_msg :=
                              'error in vendor site-'
                           || UPPER (vinvoice.vendor_site_code)
                           || '-and header num-'
                           || vinvoice.header_num;
                     WHEN OTHERS
                     THEN
                        l_error_msg :=
                              'error in vendor site-'
                           || UPPER (vinvoice.vendor_site_code)
                           || '-and header num-'
                           || vinvoice.header_num;
                  END;

                  --------------------find doc category_code-----------------------
                  BEGIN
                     SELECT doc_category_code
                       INTO v_category_code                              ----,
                       FROM xxau_doc_category_unit_wise
                      WHERE organization_id = vinvoice.ORGANIZATION;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        l_error_msg :=
                              'error in Category Code-'
                           || UPPER (vinvoice.vendor_site_code)
                           || '-and header num-'
                           || vinvoice.header_num;
                     WHEN OTHERS
                     THEN
                        l_error_msg :=
                              'error in Category Code-'
                           || UPPER (vinvoice.vendor_site_code)
                           || '-and header num-'
                           || vinvoice.header_num;
                  END;

                  FOR check_cat IN clines (vinvoice.header_num,
                                           vinvoice.operating_unit,
                                           vinvoice.ORGANIZATION,
                                           vinvoice.source1,
                                           vinvoice.invoice_num
                                          )
                  LOOP
                     --------------------------check category-----------------------------
                     IF check_cat.tax_category IS NOT NULL
                     THEN
                        BEGIN
                           SELECT tax_category_id
                             INTO l_tax_category_id
                             FROM jai_tax_categories@hrtoebs
                            WHERE UPPER (tax_category_name) =
                                                UPPER (check_cat.tax_category)
                              AND org_id = vinvoice.operating_unit
                              AND NVL (effective_to, TRUNC (SYSDATE)) >
                                                            TRUNC (SYSDATE)
                                                            - 1;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              l_error_msg :=
                                    'error in tax category-'
                                 || UPPER (check_cat.tax_category)
                                 || '-and header num-'
                                 || vinvoice.header_num;
                              l_tax_category_id := NULL;
                           WHEN OTHERS
                           THEN
                              l_error_msg :=
                                    'error in tax category-'
                                 || UPPER (check_cat.tax_category)
                                 || '-and header num-'
                                 || vinvoice.header_num;
                              l_tax_category_id := NULL;
                        END;
                     END IF;

                     ----------------------------check internal invoice exist or not-----------------------------
                     IF check_cat.original_tax_invoice_num IS NOT NULL
                     THEN
                        BEGIN
                           SELECT invoice_id, invoice_date
                             INTO l_orig_trx_id, l_orig_trx_date
                             FROM apps.ap_invoices_all@hrtoebs
                            WHERE invoice_num =
                                            check_cat.original_tax_invoice_num
                              AND invoice_date =
                                           check_cat.original_tax_invoice_date
                              AND vendor_id = l_vendor_id
                              AND vendor_site_id = l_vendor_site_id;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              l_error_msg :=
                                    'original invoice not found-'
                                 || UPPER (check_cat.original_tax_invoice_num)
                                 || '-and header num-'
                                 || check_cat.original_tax_invoice_num;
                              l_orig_trx_id := NULL;
                              l_orig_trx_date := NULL;
                           WHEN OTHERS
                           THEN
                              l_error_msg :=
                                    'original invoice not found-'
                                 || UPPER (check_cat.original_tax_invoice_num)
                                 || '-and header num-'
                                 || check_cat.original_tax_invoice_num;
                              l_orig_trx_id := NULL;
                              l_orig_trx_date := NULL;
                        END;
                     END IF;
                  END LOOP;

                  IF l_error_msg IS NULL
                  THEN
                     SELECT ap_invoices_interface_s.NEXTVAL@hrtoebs
                       INTO l_invoice_id
                       FROM DUAL;

                     INSERT INTO ap_invoices_interface@hrtoebs
                                 (invoice_id, invoice_num,
                                  invoice_type_lookup_code, vendor_id,
                                  vendor_site_id, invoice_amount,
                                  invoice_date,
                                  description,
                                  SOURCE,
                                  org_id,
                                  calc_tax_during_import_flag,
                                  add_tax_to_inv_amt_flag,
                                  doc_category_code, terms_id,
                                  invoice_currency_code,
                                  payment_method_lookup_code, gl_date,
                                  GROUP_ID                   ----, attribute4,
                                  ---attribute_category
                                 --- supplier_tax_invoice_number
                                 )
                          VALUES (l_invoice_id, vinvoice.invoice_num,
                                  l_invoice_type, l_vendor_id,
                                  l_vendor_site_id, vinvoice.invoice_amount,
                                  vinvoice.tax_invoice_date,
                                  vinvoice.description,
                                  'MANUAL INVOICE ENTRY',
                                  vinvoice.operating_unit,
                                  DECODE (l_tax_category_id, NULL, NULL, 'Y'),
                                  DECODE (l_tax_category_id, NULL, NULL, 'Y'),
                                  v_category_code, v_term_id,
                                  vinvoice.transaction_curr,
                                  v_method, vinvoice.gl_date,
                                  vinvoice.source1
                                                 ----, vinvoice.mobile_number,
                                 ---'India Distributions'
                                 );

                     FOR vlines IN clines (vinvoice.header_num,
                                           vinvoice.operating_unit,
                                           vinvoice.ORGANIZATION,
                                           vinvoice.source1,
                                           vinvoice.invoice_num
                                          )
                     LOOP
                        BEGIN
                           SELECT code_combination_id
                             INTO v_gl_code
                             FROM apps.gl_code_combinations_kfv@hrtoebs x
                            WHERE x.concatenated_segments =
                                        vlines.unit
                                     || '.'
                                     || vlines.location1
                                     || '.'
                                     || vlines.division_location  ------ '999'
                                     || '.'
                                     || vlines.department
                                     || '.'
                                     || vlines.expense_account
                                     || '.'
                                     || vlines.activity_code
                                     || '.'
                                     || '999'
                                     || '.'
                                     || '999'
                                     || '.'
                                     || '999'
                                     || '.'
                                     || '999';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              BEGIN
                                 SELECT id_flex_num
                                   INTO ln_id_flex_num
                                   FROM apps.fnd_id_flex_structures@hrtoebs
                                  WHERE id_flex_code = 'GL#'
                                    AND id_flex_structure_code =
                                                       'AUPL_Chart_Of_Account';
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    ln_id_flex_num := NULL;
                              END;

                              v_gl_code :=
                                 fnd_flex_ext.get_ccid@hrtoebs
                                    (application_short_name      => 'SQLGL',
                                     key_flex_code               => 'GL#',
                                     structure_number            => ln_id_flex_num,
                                     validation_date             => SYSDATE,
                                     concatenated_segments       =>    vlines.unit
                                                                    || '.'
                                                                    || vlines.location1
                                                                    || '.'
                                                                    || vlines.division_location
                                                                    || '.'
                                                                    || vlines.department
                                                                    || '.'
                                                                    || vlines.expense_account
                                                                    || '.'
                                                                    || vlines.activity_code
                                                                    || '.'
                                                                    || '999'
                                                                    || '.'
                                                                    || '999'
                                                                    || '.'
                                                                    || '999'
                                                                    || '.'
                                                                    || '999'
                                    );
                        END;

                        SELECT ap_invoice_lines_interface_s.NEXTVAL@hrtoebs
                          INTO l_inv_line_id
                          FROM DUAL;

                        DBMS_OUTPUT.put_line (   'transaction_num'
                                              || vinvoice.invoice_num
                                             );
                        DBMS_OUTPUT.put_line ('l_inv_line_id' || l_inv_line_id);

                        INSERT INTO ap_invoice_lines_interface@hrtoebs
                                    (invoice_id, invoice_line_id,
                                     line_number, line_type_lookup_code,
                                     amount, description,
                                     org_id, dist_code_combination_id,
                                     reference_key1,
                                     reference_key2,
                                     reference_key3,
                                     accounting_date, attribute10,
                                     attribute_category
                                    )
                             VALUES (l_invoice_id, l_inv_line_id,
                                     vlines.line_num, 'ITEM',
                                     vlines.line_amount, vlines.description,
                                     vlines.operating_unit, v_gl_code,
                                     ---- Account Hard coded as per the user requirement
                                     DECODE (vlines.tax_category,
                                             NULL, NULL,
                                             vinvoice.invoice_num
                                            ),
                                     DECODE (vlines.tax_category,
                                             NULL, NULL,
                                             vlines.line_num
                                            ),
                                     DECODE (vlines.tax_category,
                                             NULL, NULL,
                                             'OFI TAX IMPORT'
                                            ),
                                     vinvoice.gl_date, vlines.tax_type,
                                     'Invoice Tax Nature'
                                    );

                        IF vlines.tax_category IS NOT NULL
                        THEN
                           v_jai_interface_lines := NULL;

                           SELECT jai_interface_lines_all_s.NEXTVAL@hrtoebs
                             INTO v_jai_interface_lines
                             FROM DUAL;

                           DBMS_OUTPUT.put_line (   ' v_jai_interface_lines'
                                                 || v_jai_interface_lines
                                                );

                           INSERT INTO jai_interface_lines_all@hrtoebs
                                       (interface_line_id,
                                        transaction_num,
                                        transaction_line_num,
                                        --- internal_trx_id,
                                        batch_source_name,
                                        org_id,
                                        organization_id, location_id,
                                        party_id, party_site_id,
                                        import_module, tax_category_id,
                                        taxable_event,
                                        intended_use,
                                        hsn_code, creation_date,
                                        last_updated_by, last_update_date,
                                        last_update_login, created_by
                                       )
                                VALUES (v_jai_interface_lines,
                                        vinvoice.invoice_num,
                                        vlines.line_num,

                                        ---l_orig_trx_id,
                                        'OFI TAX IMPORT',
                                        vinvoice.operating_unit,
                                        l_organization_id, l_location_id,
                                        l_vendor_id, l_vendor_site_id,
                                        'AP', l_tax_category_id,
                                        'STANDARD',
                                        DECODE (vinvoice.recoverable_flag,
                                                'Y', 'RECOVERABLE'
                                               ),
                                        vinvoice.hsn_code, SYSDATE,
                                        0, SYSDATE,
                                        -1, 0
                                       );

                           FOR vtax_lines IN ctax_lines (l_tax_category_id)
                           LOOP
                              v_jai_interface_tax := NULL;

                              SELECT jai_interface_tax_lines_all_s.NEXTVAL@hrtoebs
                                INTO v_jai_interface_tax
                                FROM DUAL;

                              v_tax_amount := 0;

                              IF UPPER (vinvoice.source1) LIKE 'VODA%'
                              THEN
                                 v_tax_amount :=
                                    ROUND ((  vlines.line_amount
                                            * vtax_lines.tax_rate_percentage
                                            / 100
                                           ),
                                           2
                                          );
                              ELSE
                                 v_tax_amount :=
                                    ROUND ((  vlines.line_amount
                                            * vtax_lines.tax_rate_percentage
                                            / 100
                                           )
                                          );
                              END IF;

                              INSERT INTO jai_interface_tax_lines_all@hrtoebs
                                          (interface_tax_line_id,
                                           interface_line_id,
                                           party_id, party_site_id,
                                           import_module, transaction_num,
                                           transaction_line_num,
                                           tax_line_no,
                                           external_tax_code, qty_rate,
                                           precedence_1, precedence_2,
                                           precedence_3, precedence_4,
                                           precedence_5, precedence_6,
                                           precedence_7, precedence_8,
                                           precedence_9, precedence_10,
                                           tax_id,
                                           tax_rate,
                                           uom, tax_amount,
                                           func_tax_amount,
                                           base_tax_amount,
                                           inclusive_tax_flag,
                                           code_combination_id,
                                           creation_date, created_by,
                                           last_update_date,
                                           last_update_login,
                                           last_updated_by, precedence_11,
                                           precedence_12, precedence_13,
                                           precedence_14, precedence_15,
                                           precedence_16, precedence_17,
                                           precedence_18, precedence_19,
                                           precedence_20,
                                           tax_invoice_num,
                                           tax_invoice_date, user_entered_av
                                          )
                                   VALUES (v_jai_interface_tax,
                                           v_jai_interface_lines,
                                           l_vendor_id, l_vendor_site_id,
                                           'AP', vinvoice.invoice_num,
                                           vlines.line_num,
                                           vtax_lines.line_number,
                                           'Null'          --EXTERNAL TAX CODE
                                                 , '',
                                           0                    --PRECEDENCE_1
                                            , '',
                                           '', '',
                                           '', '',
                                           '', '',
                                           '', '',
                                           vtax_lines.tax_rate_id   ----TAX_ID
                                                                 ,
                                           vtax_lines.tax_rate_percentage
                                                                         ---TAX_RATE
                              ,
                                           '', v_tax_amount       --TAX_AMOUNT
                                                           ,
                                           v_tax_amount      --FUNC TAX AMOUNT
                                                       ,
                                           v_tax_amount      --BASE TAX AMOUNT
                                                       ,
                                           'N'                --INCLUSIVE FLAG
                                              ,
                                           '',
                                           SYSDATE, 0,
                                           SYSDATE,
                                           -1,
                                           0, '',
                                           '', '',
                                           '', '',
                                           '', '',
                                           '', '',
                                           '',
                                           ''     --------vInvoice.invoice_num
                                             ,
                                           '', ''
                                          );
                           END LOOP;
                        END IF;
                     END LOOP;

                     UPDATE aucustom.xxau_create_ap_inv_master1
                        SET process_flag = 'Y',
                            error_msz = 'Success'
                      WHERE header_num = vinvoice.header_num
                        AND invoice_num = vinvoice.invoice_num
                        AND tax_invoice_date = vinvoice.tax_invoice_date
                        AND source1 = p_source;
                  -- fnd_file.put_line (fnd_file.output,
                               --          vinvoice.header_num
                                --      || '                    '
                                 --     || vinvoice.invoice_num
                                  ---   );
                  ELSE
                     BEGIN
                        UPDATE aucustom.xxau_create_ap_inv_master1
                           SET process_flag = 'E',
                               error_msz = l_error_msg
                         WHERE header_num = vinvoice.header_num
                           AND invoice_num = vinvoice.invoice_num
                           AND tax_invoice_date = vinvoice.tax_invoice_date
                           AND source1 = p_source;
                     END;
                  END IF;                                   ----errro check if
               END LOOP;
            ---- COMMIT;
            END;
         ELSE
            ----fnd_file.put_line (fnd_file.LOG, 'Error in above mentioned records');
            retcode := 1;
         END IF;
      END;
   END xxau_create_ap_myauartical;

   PROCEDURE xxau_error_up_myau_ap (
      errbuff    OUT   NUMBER,
      retcode    OUT   NUMBER,
      p_source         VARCHAR2
   )
   IS
      CURSOR fetch_data (
         pinvoice_num     VARCHAR2,
         p_invoice_date   DATE,
         p_vendor_num     VARCHAR2,
         p_gl_date        DATE
      )
      IS
         (SELECT aia.invoice_num, aia.invoice_date, aia.gl_date,
                 pv.segment1 vendor_num, air.reject_lookup_code error_msz
            FROM ap_invoices_interface@hrtoebs aia,
                 po_vendors@hrtoebs pv,
                 ap_interface_rejections@hrtoebs air
           WHERE SOURCE = 'MANUAL INVOICE ENTRY'
             AND status = 'REJECTED'
             AND aia.vendor_id = pv.vendor_id
             AND aia.invoice_num = pinvoice_num
             AND aia.invoice_date = p_invoice_date
             AND aia.gl_date = p_gl_date
             AND pv.segment1 = p_vendor_num
             AND aia.invoice_id = air.parent_id);

      CURSOR fetch_data2 (
         pinvoice_num     VARCHAR2,
         p_invoice_date   DATE,
         p_vendor_num     VARCHAR2,
         p_gl_date        DATE
      )
      IS
         (SELECT aia.invoice_num, aia.invoice_date, aia.gl_date,
                 pv.segment1 vendor_num, air.reject_lookup_code error_msz
            FROM ap_invoices_interface@hrtoebs aia,
                 po_vendors@hrtoebs pv,
                 ap_interface_rejections@hrtoebs air,
                 ap_invoice_lines_interface@hrtoebs ail
           WHERE SOURCE = 'MANUAL INVOICE ENTRY'
             AND status = 'REJECTED'
             AND aia.vendor_id = pv.vendor_id
             AND aia.invoice_num = pinvoice_num
             AND aia.invoice_date = p_invoice_date
             AND aia.gl_date = p_gl_date
             AND pv.segment1 = p_vendor_num
             AND ail.invoice_line_id = air.parent_id
             AND ail.invoice_id = aia.invoice_id);

      CURSOR fetch_data3 (p_source1 VARCHAR2)
      IS
         (SELECT DISTINCT aia.invoice_num, aia.invoice_date, aia.gl_date,
                          pv.segment1 vendor_num, aia.GROUP_ID,
                          aia.invoice_id
                     FROM ap_invoices_interface@hrtoebs aia,
                          po_vendors@hrtoebs pv
                    WHERE SOURCE = 'MANUAL INVOICE ENTRY'
                      AND status = 'REJECTED'
                      AND aia.GROUP_ID = p_source1
                      AND aia.vendor_id = pv.vendor_id);

      v_error   VARCHAR2 (2000) := NULL;
   BEGIN
      FOR fetch3 IN fetch_data3 (p_source)
      LOOP
         v_error := NULL;

         FOR fetch1 IN fetch_data (fetch3.invoice_num,
                                   fetch3.invoice_date,
                                   fetch3.vendor_num,
                                   fetch3.gl_date
                                  )
         LOOP
            v_error := v_error || ',' || fetch1.error_msz;
         END LOOP;

         FOR fetch1 IN fetch_data2 (fetch3.invoice_num,
                                    fetch3.invoice_date,
                                    fetch3.vendor_num,
                                    fetch3.gl_date
                                   )
         LOOP
            v_error := v_error || ',' || fetch1.error_msz;
         END LOOP;

         UPDATE aucustom.xxau_create_ap_inv_master1
            SET error_msz = v_error,
                process_flag = 'E'
          WHERE invoice_num = fetch3.invoice_num
            AND tax_invoice_date = fetch3.invoice_date
            AND vendor_num = fetch3.vendor_num
            AND gl_date = fetch3.gl_date
            AND UPPER (source1) = UPPER (fetch3.GROUP_ID);

         DELETE      jai_interface_lines_all@hrtoebs
               WHERE transaction_num = fetch3.invoice_num;

         DELETE      jai_interface_tax_lines_all@hrtoebs
               WHERE transaction_num = fetch3.invoice_num;

         DELETE      ap_invoice_lines_interface@hrtoebs
               WHERE invoice_id = fetch3.invoice_id;

         DELETE      ap_invoices_interface@hrtoebs
               WHERE invoice_num = fetch3.invoice_num
                 AND invoice_date = fetch3.invoice_date
                 AND invoice_id = fetch3.invoice_id;
      ---- COMMIT;
      END LOOP;
   END xxau_error_up_myau_ap;

   PROCEDURE xxau_create_ap_myauempadvance (
      errbuff    OUT   NUMBER,
      retcode    OUT   NUMBER,
      p_source         VARCHAR2
   )
   IS
      l_error_msg             VARCHAR2 (2000) := NULL;
      l_invoice_id            NUMBER;
      l_inv_line_id           NUMBER;
      l_count                 NUMBER;
      l_location_id           NUMBER;
      l_vendor_id             NUMBER;
      l_vendor_site_id        NUMBER;
      l_tax_category_id       NUMBER;
      l_invoice_type          VARCHAR2 (20);
      l_hsn_code              VARCHAR2 (30);
      v_gl_code               NUMBER;
      v_term_id               NUMBER;
      ln_id_flex_num          NUMBER;
      v_method                VARCHAR2 (30);
      l_organization_id       NUMBER;
      v_jai_interface_lines   NUMBER;
      v_jai_interface_tax     NUMBER;
      v_tax_amount            NUMBER;
      l_orig_trx_id           NUMBER;
      l_orig_trx_date         DATE;
      v_category_code         VARCHAR2 (40);

      CURSOR cinvoice (p_source VARCHAR2)
      IS
         SELECT   operating_unit, ORGANIZATION, header_num, invoice_num,
                  vendor_num, vendor_site_code, invoice_amount, description,
                  hsn_code, unit, tax_invoice_date, transaction_curr,
                  gl_date, source1, recoverable_flag, mobile_number,
                  inv_type
             FROM aucustom.xxau_create_ap_inv_master2
            WHERE line_num = 1
              AND NVL (process_flag, 'N') = 'N'
              --AND invoice_num='SKP/18-19/CN-114'
              ---AND header_num BETWEEN 1 AND 2
              AND source1 = p_source
         ORDER BY header_num;

      CURSOR clines (
         l_header_num     NUMBER,
         l_org_id         NUMBER,
         l_organization   NUMBER,
         p_source1        VARCHAR2,
         p_inv            VARCHAR2
      )
      IS
         SELECT operating_unit, line_num, line_amount, description, unit,
                location1, division_location, department, tax_category,
                original_tax_invoice_num, original_tax_invoice_date,
                account1 expense_account, activity_code, tax_type
           FROM aucustom.xxau_create_ap_inv_master2
          WHERE header_num = l_header_num
            AND operating_unit = l_org_id
            AND ORGANIZATION = l_organization
            AND source1 = p_source1
            AND invoice_num = p_inv;

      CURSOR ctax_lines (l_tax_category_id IN NUMBER)
      IS
         SELECT jtcl.tax_rate_id, jtcl.line_number, jtcl.tax_type_id,
                jtr.tax_rate_name, jtrd.tax_rate_percentage
           FROM jai_tax_category_lines@hrtoebs jtcl,
                jai_tax_rates@hrtoebs jtr,
                jai_tax_rate_details@hrtoebs jtrd
          WHERE jtcl.tax_category_id = l_tax_category_id
            AND jtcl.tax_type_id = jtr.tax_type_id
            AND jtr.tax_rate_id = jtrd.tax_rate_id
            AND jtcl.tax_rate_id = jtrd.tax_rate_id;
   BEGIN
      BEGIN
         INSERT INTO aucustom.xxau_create_ap_inv_master2
            SELECT 288 operating_unit,
                   (SELECT organization_id
                      FROM xxau_accounting_unit_new
                     WHERE organization_code NOT IN ('HSO')
                       AND flex_value IN (
                              SELECT segment1
                                FROM gl_code_combinations_kfv@hrtoebs
                               WHERE code_combination_id IN (
                                        SELECT accts_pay_code_combination_id
                                          FROM ap_supplier_sites_all@hrtoebs
                                         WHERE vendor_site_id =
                                                             tt.vendor_site_id)))
                                                             organization_id,
                   1 header_num, 1 line_num,
                   (tt.advancetypecode || '-' || tt.invoice_number
                   ) invoice_num,
                   invoice_date tax_invoice_date, TRUNC (gl_date) gl_date,
                   NULL original_tax_invoice_num,
                   NULL original_tax_invoice_date, 'INR' transaction_curr,
                   (SELECT segment1
                      FROM ap_suppliers@hrtoebs
                     WHERE vendor_id = tt.vendor_id) vendor_num,
                   supplier_site vendor_site_code,
                   invoice_amount invoice_amount,
                   RTRIM (LTRIM (description)) description,
                   invoice_amount line_amount,
                   RTRIM (LTRIM (description)) line_description,
                   (SELECT segment1
                      FROM gl_code_combinations_kfv@hrtoebs
                     WHERE code_combination_id IN (
                                SELECT accts_pay_code_combination_id
                                  FROM ap_supplier_sites_all@hrtoebs
                                 WHERE vendor_site_id =
                                                       tt.vendor_site_id))
                                                                        unit,
                   9999 location1, 999 division_location, 999 department,
                   (SELECT pre_account2
                      FROM xxau_accountcode_maping
                     WHERE type_code = tt.advancetypecode) account1,

                   /* (SELECT lib_account1
                       FROM xxau_accountcode_maping
                      WHERE type_code = tt.advancetypecode) */
                   9999 activity_code, NULL tax_category, NULL hsn_code,
                   NULL tax_type, NULL mobile_number, NULL recoverable_flag,
                   'MYAUEMPADVANCE' source1, NULL, NULL, NULL, NULL, tt.ID,
                   UPPER (tt.type_of_invoice)
              FROM xxmis.emp_advance tt
             WHERE NVL (flagcode, 'N') = 'N'
               AND NOT EXISTS (
                      SELECT 'y'
                        FROM aucustom.xxau_create_ap_inv_master2
                       WHERE invoice_num =
                                tt.advancetypecode || '-' || tt.invoice_number);
      END;

      BEGIN
         UPDATE xxmis.emp_advance tt
            SET flagcode = 'Y'
          WHERE NVL (flagcode, 'N') = 'N'
            AND EXISTS (
                   SELECT 'y'
                     FROM aucustom.xxau_create_ap_inv_master2
                    WHERE invoice_num =
                                tt.advancetypecode || '-' || tt.invoice_number);
      END;

      BEGIN
         l_error_msg := NULL;

         IF l_error_msg IS NULL
         THEN
            BEGIN
               FOR vinvoice IN cinvoice (p_source)
               LOOP
                  l_error_msg := NULL;
                  l_invoice_id := NULL;
                  l_inv_line_id := NULL;
                  l_location_id := NULL;
                  l_vendor_id := NULL;
                  l_vendor_site_id := NULL;
                  l_tax_category_id := NULL;
                  l_invoice_type := NULL;
                  v_gl_code := NULL;
                  v_category_code := NULL;
                  /*  IF vinvoice.invoice_amount >= 0
                    THEN
                       l_invoice_type := 'STANDARD';
                    ELSE
                       l_invoice_type := 'CREDIT';
                    END IF;*/
                  l_invoice_type := vinvoice.inv_type;

                  BEGIN
                     SELECT tt.location_id, tt.organization_id
                       INTO l_location_id, l_organization_id
                       FROM hr_all_organization_units@hrtoebs tt
                      WHERE tt.organization_id = vinvoice.ORGANIZATION
                        AND (tt.NAME LIKE 'AUPL%' OR tt.NAME LIKE 'DIV%');
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        l_error_msg :=
                              'error in organization-'
                           || vinvoice.ORGANIZATION
                           || '-and header num-'
                           || vinvoice.header_num;
                     WHEN OTHERS
                     THEN
                        l_error_msg :=
                              'error in organization-'
                           || vinvoice.ORGANIZATION
                           || '-and header num-'
                           || vinvoice.header_num;
                  END;

                  BEGIN
                     SELECT vendor_id, payment_method_lookup_code
                       INTO l_vendor_id, v_method
                       FROM ap_suppliers@hrtoebs
                      WHERE segment1 = vinvoice.vendor_num
                        AND enabled_flag = 'Y'
                        AND NVL (end_date_active, TRUNC (SYSDATE)) >
                                                            TRUNC (SYSDATE)
                                                            - 1;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        l_error_msg :=
                              'error in vendor-'
                           || vinvoice.vendor_num
                           || '-and header num-'
                           || vinvoice.header_num;
                     WHEN OTHERS
                     THEN
                        l_error_msg :=
                              'error in vendor-'
                           || vinvoice.vendor_num
                           || '-and header num-'
                           || vinvoice.header_num;
                  END;

                  BEGIN
                     SELECT vendor_site_id, terms_id
                       ----, payment_method_lookup_code
                     INTO   l_vendor_site_id, v_term_id                  ----,
                       FROM ap_supplier_sites_all@hrtoebs
                      WHERE vendor_id = l_vendor_id
                        AND UPPER (vendor_site_code) =
                                             UPPER (vinvoice.vendor_site_code)
                        AND org_id = vinvoice.operating_unit;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        l_error_msg :=
                              'error in vendor site-'
                           || UPPER (vinvoice.vendor_site_code)
                           || '-and header num-'
                           || vinvoice.header_num;
                     WHEN OTHERS
                     THEN
                        l_error_msg :=
                              'error in vendor site-'
                           || UPPER (vinvoice.vendor_site_code)
                           || '-and header num-'
                           || vinvoice.header_num;
                  END;

--------------------find doc category_code-----------------------
                  BEGIN
                     SELECT doc_category_code
                       INTO v_category_code                              ----,
                       FROM xxau_doc_category_unit_wise
                      WHERE organization_id = vinvoice.ORGANIZATION;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        l_error_msg :=
                              'error in Category Code-'
                           || UPPER (vinvoice.vendor_site_code)
                           || '-and header num-'
                           || vinvoice.header_num;
                     WHEN OTHERS
                     THEN
                        l_error_msg :=
                              'error in Category Code-'
                           || UPPER (vinvoice.vendor_site_code)
                           || '-and header num-'
                           || vinvoice.header_num;
                  END;

                  FOR check_cat IN clines (vinvoice.header_num,
                                           vinvoice.operating_unit,
                                           vinvoice.ORGANIZATION,
                                           vinvoice.source1,
                                           vinvoice.invoice_num
                                          )
                  LOOP
                     --------------------------check category-----------------------------
                     IF check_cat.tax_category IS NOT NULL
                     THEN
                        BEGIN
                           SELECT tax_category_id
                             INTO l_tax_category_id
                             FROM jai_tax_categories@hrtoebs
                            WHERE UPPER (tax_category_name) =
                                                UPPER (check_cat.tax_category)
                              AND org_id = vinvoice.operating_unit
                              AND NVL (effective_to, TRUNC (SYSDATE)) >
                                                            TRUNC (SYSDATE)
                                                            - 1;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              l_error_msg :=
                                    'error in tax category-'
                                 || UPPER (check_cat.tax_category)
                                 || '-and header num-'
                                 || vinvoice.header_num;
                              l_tax_category_id := NULL;
                           WHEN OTHERS
                           THEN
                              l_error_msg :=
                                    'error in tax category-'
                                 || UPPER (check_cat.tax_category)
                                 || '-and header num-'
                                 || vinvoice.header_num;
                              l_tax_category_id := NULL;
                        END;
                     END IF;

                     ----------------------------check internal invoice exist or not-----------------------------
                     IF check_cat.original_tax_invoice_num IS NOT NULL
                     THEN
                        BEGIN
                           SELECT invoice_id, invoice_date
                             INTO l_orig_trx_id, l_orig_trx_date
                             FROM apps.ap_invoices_all@hrtoebs
                            WHERE invoice_num =
                                            check_cat.original_tax_invoice_num
                              AND invoice_date =
                                           check_cat.original_tax_invoice_date
                              AND vendor_id = l_vendor_id
                              AND vendor_site_id = l_vendor_site_id;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              l_error_msg :=
                                    'original invoice not found-'
                                 || UPPER (check_cat.original_tax_invoice_num)
                                 || '-and header num-'
                                 || check_cat.original_tax_invoice_num;
                              l_orig_trx_id := NULL;
                              l_orig_trx_date := NULL;
                           WHEN OTHERS
                           THEN
                              l_error_msg :=
                                    'original invoice not found-'
                                 || UPPER (check_cat.original_tax_invoice_num)
                                 || '-and header num-'
                                 || check_cat.original_tax_invoice_num;
                              l_orig_trx_id := NULL;
                              l_orig_trx_date := NULL;
                        END;
                     END IF;
                  END LOOP;

                  IF l_error_msg IS NULL
                  THEN
                     SELECT ap_invoices_interface_s.NEXTVAL@hrtoebs
                       INTO l_invoice_id
                       FROM DUAL;

                     INSERT INTO ap_invoices_interface@hrtoebs
                                 (invoice_id, invoice_num,
                                  invoice_type_lookup_code, vendor_id,
                                  vendor_site_id, invoice_amount,
                                  invoice_date,
                                  description,
                                  SOURCE,
                                  org_id,
                                  calc_tax_during_import_flag,
                                  add_tax_to_inv_amt_flag,
                                  doc_category_code, terms_id,
                                  invoice_currency_code,
                                  payment_method_lookup_code, gl_date,
                                  GROUP_ID                   ----, attribute4,
                                  ---attribute_category
                                 --- supplier_tax_invoice_number
                                 )
                          VALUES (l_invoice_id, vinvoice.invoice_num,
                                  l_invoice_type, l_vendor_id,
                                  l_vendor_site_id, vinvoice.invoice_amount,
                                  vinvoice.tax_invoice_date,
                                  vinvoice.description,
                                  'MANUAL INVOICE ENTRY',
                                  vinvoice.operating_unit,
                                  DECODE (l_tax_category_id, NULL, NULL, 'Y'),
                                  DECODE (l_tax_category_id, NULL, NULL, 'Y'),
                                  v_category_code, v_term_id,
                                  vinvoice.transaction_curr,
                                  v_method, vinvoice.gl_date,
                                  vinvoice.source1
                                                 ----, vinvoice.mobile_number,
                                 ---'India Distributions'
                                 );

                     FOR vlines IN clines (vinvoice.header_num,
                                           vinvoice.operating_unit,
                                           vinvoice.ORGANIZATION,
                                           vinvoice.source1,
                                           vinvoice.invoice_num
                                          )
                     LOOP
                        BEGIN
                           SELECT code_combination_id
                             INTO v_gl_code
                             FROM apps.gl_code_combinations_kfv@hrtoebs x
                            WHERE x.concatenated_segments =
                                        vlines.unit
                                     || '.'
                                     || vlines.location1
                                     || '.'
                                     || vlines.division_location  ------ '999'
                                     || '.'
                                     || vlines.department
                                     || '.'
                                     || vlines.expense_account
                                     || '.'
                                     || vlines.activity_code
                                     || '.'
                                     || '999'
                                     || '.'
                                     || '999'
                                     || '.'
                                     || '999'
                                     || '.'
                                     || '999';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              BEGIN
                                 SELECT id_flex_num
                                   INTO ln_id_flex_num
                                   FROM apps.fnd_id_flex_structures@hrtoebs
                                  WHERE id_flex_code = 'GL#'
                                    AND id_flex_structure_code =
                                                       'AUPL_Chart_Of_Account';
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    ln_id_flex_num := NULL;
                              END;

                              v_gl_code :=
                                 fnd_flex_ext.get_ccid@hrtoebs
                                    (application_short_name      => 'SQLGL',
                                     key_flex_code               => 'GL#',
                                     structure_number            => ln_id_flex_num,
                                     validation_date             => SYSDATE,
                                     concatenated_segments       =>    vlines.unit
                                                                    || '.'
                                                                    || vlines.location1
                                                                    || '.'
                                                                    || vlines.division_location
                                                                    || '.'
                                                                    || vlines.department
                                                                    || '.'
                                                                    || vlines.expense_account
                                                                    || '.'
                                                                    || vlines.activity_code
                                                                    || '.'
                                                                    || '999'
                                                                    || '.'
                                                                    || '999'
                                                                    || '.'
                                                                    || '999'
                                                                    || '.'
                                                                    || '999'
                                    );
                        END;

                        SELECT ap_invoice_lines_interface_s.NEXTVAL@hrtoebs
                          INTO l_inv_line_id
                          FROM DUAL;

                        DBMS_OUTPUT.put_line (   'transaction_num'
                                              || vinvoice.invoice_num
                                             );
                        DBMS_OUTPUT.put_line ('l_inv_line_id' || l_inv_line_id);

                        INSERT INTO ap_invoice_lines_interface@hrtoebs
                                    (invoice_id, invoice_line_id,
                                     line_number, line_type_lookup_code,
                                     amount, description,
                                     org_id, dist_code_combination_id,
                                     reference_key1,
                                     reference_key2,
                                     reference_key3,
                                     accounting_date, attribute10,
                                     attribute_category
                                    )
                             VALUES (l_invoice_id, l_inv_line_id,
                                     vlines.line_num, 'ITEM',
                                     vlines.line_amount, vlines.description,
                                     vlines.operating_unit, v_gl_code,
                                     ---- Account Hard coded as per the user requirement
                                     DECODE (vlines.tax_category,
                                             NULL, NULL,
                                             vinvoice.invoice_num
                                            ),
                                     DECODE (vlines.tax_category,
                                             NULL, NULL,
                                             vlines.line_num
                                            ),
                                     DECODE (vlines.tax_category,
                                             NULL, NULL,
                                             'OFI TAX IMPORT'
                                            ),
                                     vinvoice.gl_date, vlines.tax_type,
                                     'Invoice Tax Nature'
                                    );

                        IF vlines.tax_category IS NOT NULL
                        THEN
                           v_jai_interface_lines := NULL;

                           SELECT jai_interface_lines_all_s.NEXTVAL@hrtoebs
                             INTO v_jai_interface_lines
                             FROM DUAL;

                           DBMS_OUTPUT.put_line (   ' v_jai_interface_lines'
                                                 || v_jai_interface_lines
                                                );

                           INSERT INTO jai_interface_lines_all@hrtoebs
                                       (interface_line_id,
                                        transaction_num,
                                        transaction_line_num,
                                        --- internal_trx_id,
                                        batch_source_name,
                                        org_id,
                                        organization_id, location_id,
                                        party_id, party_site_id,
                                        import_module, tax_category_id,
                                        taxable_event,
                                        intended_use,
                                        hsn_code, creation_date,
                                        last_updated_by, last_update_date,
                                        last_update_login, created_by
                                       )
                                VALUES (v_jai_interface_lines,
                                        vinvoice.invoice_num,
                                        vlines.line_num,

                                        ---l_orig_trx_id,
                                        'OFI TAX IMPORT',
                                        vinvoice.operating_unit,
                                        l_organization_id, l_location_id,
                                        l_vendor_id, l_vendor_site_id,
                                        'AP', l_tax_category_id,
                                        'STANDARD',
                                        DECODE (vinvoice.recoverable_flag,
                                                'Y', 'RECOVERABLE'
                                               ),
                                        vinvoice.hsn_code, SYSDATE,
                                        0, SYSDATE,
                                        -1, 0
                                       );

                           FOR vtax_lines IN ctax_lines (l_tax_category_id)
                           LOOP
                              v_jai_interface_tax := NULL;

                              SELECT jai_interface_tax_lines_all_s.NEXTVAL@hrtoebs
                                INTO v_jai_interface_tax
                                FROM DUAL;

                              v_tax_amount := 0;

                              IF UPPER (vinvoice.source1) LIKE 'VODA%'
                              THEN
                                 v_tax_amount :=
                                    ROUND ((  vlines.line_amount
                                            * vtax_lines.tax_rate_percentage
                                            / 100
                                           ),
                                           2
                                          );
                              ELSE
                                 v_tax_amount :=
                                    ROUND ((  vlines.line_amount
                                            * vtax_lines.tax_rate_percentage
                                            / 100
                                           )
                                          );
                              END IF;

                              INSERT INTO jai_interface_tax_lines_all@hrtoebs
                                          (interface_tax_line_id,
                                           interface_line_id,
                                           party_id, party_site_id,
                                           import_module, transaction_num,
                                           transaction_line_num,
                                           tax_line_no,
                                           external_tax_code, qty_rate,
                                           precedence_1, precedence_2,
                                           precedence_3, precedence_4,
                                           precedence_5, precedence_6,
                                           precedence_7, precedence_8,
                                           precedence_9, precedence_10,
                                           tax_id,
                                           tax_rate,
                                           uom, tax_amount,
                                           func_tax_amount,
                                           base_tax_amount,
                                           inclusive_tax_flag,
                                           code_combination_id,
                                           creation_date, created_by,
                                           last_update_date,
                                           last_update_login,
                                           last_updated_by, precedence_11,
                                           precedence_12, precedence_13,
                                           precedence_14, precedence_15,
                                           precedence_16, precedence_17,
                                           precedence_18, precedence_19,
                                           precedence_20,
                                           tax_invoice_num,
                                           tax_invoice_date, user_entered_av
                                          )
                                   VALUES (v_jai_interface_tax,
                                           v_jai_interface_lines,
                                           l_vendor_id, l_vendor_site_id,
                                           'AP', vinvoice.invoice_num,
                                           vlines.line_num,
                                           vtax_lines.line_number,
                                           'Null'          --EXTERNAL TAX CODE
                                                 , '',
                                           0                    --PRECEDENCE_1
                                            , '',
                                           '', '',
                                           '', '',
                                           '', '',
                                           '', '',
                                           vtax_lines.tax_rate_id   ----TAX_ID
                                                                 ,
                                           vtax_lines.tax_rate_percentage
                                                                         ---TAX_RATE
                              ,
                                           '', v_tax_amount       --TAX_AMOUNT
                                                           ,
                                           v_tax_amount      --FUNC TAX AMOUNT
                                                       ,
                                           v_tax_amount      --BASE TAX AMOUNT
                                                       ,
                                           'N'                --INCLUSIVE FLAG
                                              ,
                                           '',
                                           SYSDATE, 0,
                                           SYSDATE,
                                           -1,
                                           0, '',
                                           '', '',
                                           '', '',
                                           '', '',
                                           '', '',
                                           '',
                                           ''     --------vInvoice.invoice_num
                                             ,
                                           '', ''
                                          );
                           END LOOP;
                        END IF;
                     END LOOP;

                     UPDATE aucustom.xxau_create_ap_inv_master2
                        SET process_flag = 'Y',
                            error_msz = 'Success'
                      WHERE header_num = vinvoice.header_num
                        AND invoice_num = vinvoice.invoice_num
                        AND tax_invoice_date = vinvoice.tax_invoice_date
                        AND source1 = p_source;
                  -- fnd_file.put_line (fnd_file.output,
                               --          vinvoice.header_num
                                --      || '                    '
                                 --     || vinvoice.invoice_num
                                  ---   );
                  ELSE
                     BEGIN
                        UPDATE aucustom.xxau_create_ap_inv_master2
                           SET process_flag = 'E',
                               error_msz = l_error_msg
                         WHERE header_num = vinvoice.header_num
                           AND invoice_num = vinvoice.invoice_num
                           AND tax_invoice_date = vinvoice.tax_invoice_date
                           AND source1 = p_source;
                     END;
                  END IF;                                   ----errro check if
               END LOOP;
            ---- COMMIT;
            END;
         ELSE
            ----fnd_file.put_line (fnd_file.LOG, 'Error in above mentioned records');
            retcode := 1;
         END IF;
      END;
   END xxau_create_ap_myauempadvance;

   PROCEDURE xxau_error_up_myauempadvance (
      errbuff    OUT   NUMBER,
      retcode    OUT   NUMBER,
      p_source         VARCHAR2
   )
   IS
      CURSOR fetch_data (
         pinvoice_num     VARCHAR2,
         p_invoice_date   DATE,
         p_vendor_num     VARCHAR2,
         p_gl_date        DATE
      )
      IS
         (SELECT aia.invoice_num, aia.invoice_date, aia.gl_date,
                 pv.segment1 vendor_num, air.reject_lookup_code error_msz
            FROM ap_invoices_interface@hrtoebs aia,
                 po_vendors@hrtoebs pv,
                 ap_interface_rejections@hrtoebs air
           WHERE SOURCE = 'MANUAL INVOICE ENTRY'
             AND status = 'REJECTED'
             AND aia.vendor_id = pv.vendor_id
             AND aia.invoice_num = pinvoice_num
             AND aia.invoice_date = p_invoice_date
             AND aia.gl_date = p_gl_date
             AND pv.segment1 = p_vendor_num
             AND aia.invoice_id = air.parent_id);

      CURSOR fetch_data2 (
         pinvoice_num     VARCHAR2,
         p_invoice_date   DATE,
         p_vendor_num     VARCHAR2,
         p_gl_date        DATE
      )
      IS
         (SELECT aia.invoice_num, aia.invoice_date, aia.gl_date,
                 pv.segment1 vendor_num, air.reject_lookup_code error_msz
            FROM ap_invoices_interface@hrtoebs aia,
                 po_vendors@hrtoebs pv,
                 ap_interface_rejections@hrtoebs air,
                 ap_invoice_lines_interface@hrtoebs ail
           WHERE SOURCE = 'MANUAL INVOICE ENTRY'
             AND status = 'REJECTED'
             AND aia.vendor_id = pv.vendor_id
             AND aia.invoice_num = pinvoice_num
             AND aia.invoice_date = p_invoice_date
             AND aia.gl_date = p_gl_date
             AND pv.segment1 = p_vendor_num
             AND ail.invoice_line_id = air.parent_id
             AND ail.invoice_id = aia.invoice_id);

      CURSOR fetch_data3 (p_source1 VARCHAR2)
      IS
         (SELECT DISTINCT aia.invoice_num, aia.invoice_date, aia.gl_date,
                          pv.segment1 vendor_num, aia.GROUP_ID,
                          aia.invoice_id
                     FROM ap_invoices_interface@hrtoebs aia,
                          po_vendors@hrtoebs pv
                    WHERE SOURCE = 'MANUAL INVOICE ENTRY'
                      AND status = 'REJECTED'
                      AND aia.GROUP_ID = p_source1
                      AND aia.vendor_id = pv.vendor_id);

      v_error   VARCHAR2 (2000) := NULL;
   BEGIN
      FOR fetch3 IN fetch_data3 (p_source)
      LOOP
         v_error := NULL;

         FOR fetch1 IN fetch_data (fetch3.invoice_num,
                                   fetch3.invoice_date,
                                   fetch3.vendor_num,
                                   fetch3.gl_date
                                  )
         LOOP
            v_error := v_error || ',' || fetch1.error_msz;
         END LOOP;

         FOR fetch1 IN fetch_data2 (fetch3.invoice_num,
                                    fetch3.invoice_date,
                                    fetch3.vendor_num,
                                    fetch3.gl_date
                                   )
         LOOP
            v_error := v_error || ',' || fetch1.error_msz;
         END LOOP;

         UPDATE aucustom.xxau_create_ap_inv_master2
            SET error_msz = v_error,
                process_flag = 'E'
          WHERE invoice_num = fetch3.invoice_num
            AND tax_invoice_date = fetch3.invoice_date
            AND vendor_num = fetch3.vendor_num
            AND gl_date = fetch3.gl_date
            AND UPPER (source1) = UPPER (fetch3.GROUP_ID);

         DELETE      jai_interface_lines_all@hrtoebs
               WHERE transaction_num = fetch3.invoice_num;

         DELETE      jai_interface_tax_lines_all@hrtoebs
               WHERE transaction_num = fetch3.invoice_num;

         DELETE      ap_invoice_lines_interface@hrtoebs
               WHERE invoice_id = fetch3.invoice_id;

         DELETE      ap_invoices_interface@hrtoebs
               WHERE invoice_num = fetch3.invoice_num
                 AND invoice_date = fetch3.invoice_date
                 AND invoice_id = fetch3.invoice_id;
      ---- COMMIT;
      END LOOP;
   END xxau_error_up_myauempadvance;

   PROCEDURE xxa_ar_onl_receipt_p3 (
      errbuf    OUT      VARCHAR2,
      retcode   OUT      NUMBER,
      p_unit    IN       VARCHAR2 DEFAULT NULL,
      p_date    IN       DATE DEFAULT NULL                              --V1.0
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      CURSOR unit (p_unit1 VARCHAR2)
      IS
         (SELECT organization_id, organization_code, flex_value
            FROM xxau_accounting_unit_new
           WHERE organization_code NOT IN ('HSO')
             AND flex_value = NVL (p_unit, flex_value));

      CURSOR c1 (p_unit1 VARCHAR2)      --------------------for normal receipt
      IS
         SELECT tt.composite_receipt_id, tt.serial_number, tt.party_number,
                tt.party_name, tt.party_location, tt.receipt_number,
                tt.party_amt, tt.attribute_category, tt.attribute1,
                tt.attribute2, tt.attribute3, tt.attribute4, tt.attribute5,
                tt.attribute6, tt.attribute7, tt.attribute8, tt.attribute9,
                tt.attribute10, tt.attribute11, tt.attribute12,
                tt.attribute13, tt.attribute14, tt.attribute15,
                tt.process_flag, tt.process_message, tt.process_date,
                tt.created_by, tt.creation_date, tt.last_updated_by,
                tt.last_update_date, tt.comments, tt.process_flag12,
                tt.process_message12, tt.process_date12, tt.receipt_date,
                tt.chno, tt.bank_acc_id, tt.bank_acc_number, tt.bank_acc_name,
                tt.doctype, tt.ref_receiptno, tt.ref_receiptdt,
                tt.ref_doctype, tt.security_flag, tt.cons_type,
                tt.cons_rcpt_no, tt.cheque_bounce_reason,
                tt.receipt_method_id, tt.prov_recptdt rct_date,
                tt.erp_customer_number cust_no, gl.segment1 unit_code
           FROM addb.addb_xxa_ar_trans_erp_rcpt_onl tt,
                apps.ar_receipt_method_accounts_all@hrtoebs td2,
                apps.ar_receipt_methods@hrtoebs td3,
                apps.gl_code_combinations@hrtoebs gl
          WHERE tt.receipt_method_id = td3.receipt_method_id
            AND td3.receipt_method_id = td2.receipt_method_id
            AND td2.org_id = 288
            AND td2.end_date IS NULL
            AND td3.end_date IS NULL
            AND NVL (process_flag, 'N') = 'N'
            AND doctype = 'RCR'
            AND td2.cash_ccid = gl.code_combination_id
            AND gl.segment1 = NVL (p_unit1, gl.segment1)
            AND NVL (security_flag, 'N') = 'N';

      CURSOR c3 (p_receipt_id NUMBER)
      IS
         SELECT d.attribute_category, d.attribute14, d.attribute11
           FROM addb.addb_xxa_ar_trans_erp_rcpt_onl d
          WHERE 1 = 1 AND d.composite_receipt_id = p_receipt_id;

      CURSOR ft_update
      IS
         (SELECT tt.composite_receipt_id, tt.ROWID row_id,
                 tt1.cash_receipt_id
            FROM addb.addb_xxa_ar_trans_erp_rcpt_onl tt,
                 apps.ar_cash_receipts_all@hrtoebs tt1
           WHERE 1 = 1
             AND TO_CHAR (tt.composite_receipt_id) = tt1.attribute1
             AND tt1.attribute9 = tt.receipt_number
             AND NVL (tt.process_flag, 'N') IN ('N', 'E'));

      l_return_status          VARCHAR2 (1);
      l_msg_count              NUMBER;
      l_msg_data               VARCHAR2 (4000)                         := NULL;
      l_cash_receipt_id        NUMBER;
      l_misc_receipt_id        NUMBER;
      l_error_mesg             VARCHAR2 (4000)                         := NULL;
      p_count                  NUMBER;
      v_rec_trx_id             NUMBER;
      lv_receipt_method_name   VARCHAR2 (80);
      ln_receipt_method_id     NUMBER                                     := 0;
      x_return_status          VARCHAR2 (30)                           := NULL;
      x_msg_count              NUMBER;
      x_msg_data               VARCHAR2 (4000)                         := NULL;
      p_cr_id                  NUMBER;
      p_misc_receipt_id        NUMBER;
      v_unit_name              VARCHAR2 (3);
      err                      VARCHAR2 (400);
      ebf                      NUMBER;
      p_attribute_rec_type     apps.ar_receipt_api_pub.attribute_rec_type@hrtoebs;
      v_receipt_no             VARCHAR2 (40)                           := NULL;
      v_return_status          VARCHAR2 (1);
      v_msg_count              NUMBER;
      v_msg_data               VARCHAR2 (2000);
      v_context                VARCHAR2 (2);
      i                        NUMBER;
      v_receipt_date           DATE;
      v_revers_date            DATE;
      v_check                  NUMBER                                     := 0;
   BEGIN
      -- DBMS_OUTPUT.put_line ('START');
      apps.fnd_global.apps_initialize@hrtoebs (2482, 52024, 222);
      apps.mo_global.set_policy_context@hrtoebs ('S', 288);
      apps.fnd_file.put_line@hrtoebs (fnd_file.output,
                                      'Table is empty successfully'
                                     );

      BEGIN
         FOR ft IN ft_update
         LOOP
            UPDATE addb.addb_xxa_ar_trans_erp_rcpt_onl
               SET process_flag = 'S',
                   process_message = 'SUCCESS-' || ft.cash_receipt_id,
                   process_date = SYSDATE,
                   process_message12 = 'Through Update Query'
             WHERE ROWID = ft.row_id
               AND composite_receipt_id = ft.composite_receipt_id;

            COMMIT;
         END LOOP;
      END;

      FOR unit_m IN unit (p_unit)
      LOOP
         aucustom.xxses_debug_prc ('Start c1');

         BEGIN
            FOR i IN c1 (unit_m.flex_value)
            LOOP
               l_msg_data := NULL;
               l_msg_count := NULL;
               l_return_status := NULL;
               l_cash_receipt_id := NULL;
               p_attribute_rec_type.attribute_category :=
                                                         i.attribute_category;
               aucustom.xxses_debug_prc
                          ('p_attribute_rec_type.attribute_category to - C ',
                           'i.attribute_category....' || i.attribute_category
                          );
               p_attribute_rec_type.attribute1 := i.composite_receipt_id;
               ---------------Reference ID
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute1 to - D ',
                                       'i.composite_receipt_id....'
                                    || i.composite_receipt_id
                                   );
               p_attribute_rec_type.attribute2 := NVL (i.attribute2, 5);
               -----------------Receipt type
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute2 to - E ',
                                    'i.attribute2....' || i.attribute2
                                   );
               p_attribute_rec_type.attribute3 := NVL (i.attribute3, 'N');
               --------------Dispaly
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute3 to - F ',
                                    'i.attribute3....' || i.attribute3
                                   );
               p_attribute_rec_type.attribute4 := NVL (i.attribute4, 'N');
               ---------------Covering
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute4 to - G ',
                                    'i.attribute4....' || i.attribute4
                                   );
               p_attribute_rec_type.attribute6 := NVL (i.attribute6, 'N');
               ------sgned
               p_attribute_rec_type.attribute5 := NVL (i.attribute5, 'N');
               ---------------stamped
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute5 to - I ',
                                    'i.attribute5....' || i.attribute5
                                   );
               p_attribute_rec_type.attribute10 := i.attribute12;
               p_attribute_rec_type.attribute11 := i.attribute13;
               ---------------bank Name
               p_attribute_rec_type.attribute9 := i.attribute9;
               -------------------compisite_reference_dcr_receipt_no
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute9 to - J ',
                                    'i.attribute9....' || i.attribute9
                                   );
               --     p_attribute_rec_type.attribute11 := i.attribute11;
               p_attribute_rec_type.attribute14 := i.attribute11;
               ---------pr receipt
               aucustom.xxses_debug_prc
                                  ('p_attribute_rec_type.attribute10 to - K ',
                                   'i.attribute11....' || i.attribute11
                                  );
               p_attribute_rec_type.attribute12 := i.attribute14;
               -----------------bank branch
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute8 to - L ',
                                    'i.attribute8....' || i.attribute8
                                   );
               p_attribute_rec_type.attribute15 := i.attribute15;
               -------------pr date
               aucustom.xxses_debug_prc
                                  ('p_attribute_rec_type.attribute15 to - N ',
                                   'i.attribute15....' || i.attribute15
                                  );

               IF i.attribute2 IN ('1', '10', '7', '8')
               THEN
                  IF i.chno IS NULL
                  THEN
                     v_receipt_no := i.receipt_number;
                  ELSE
                     v_receipt_no := i.chno;
                  END IF;
               ELSE
                  v_receipt_no := i.receipt_number;
               END IF;

               IF p_date IS NULL
               THEN
                  v_receipt_date := i.receipt_date;
               -- v_receipt_date := TRUNC (SYSDATE);-------------for cio receipt not for DCR
               ELSE
                  --v_receipt_date := p_date;-------------for cio receipt not for DCR
                  ---v_receipt_date := TRUNC (SYSDATE);
                  v_receipt_date := i.receipt_date;
               END IF;

               IF i.party_number IS NOT NULL
               THEN
                  -- DBMS_OUTPUT.put_line ('party number not null ');
                  aucustom.xxses_debug_prc
                                      ('if party number is not null to - O ',
                                       'i.party_number....' || i.party_number
                                      );
                  apps.ar_receipt_api_pub.create_cash@hrtoebs
                                  (p_api_version               => 1.0,
                                   p_init_msg_list             => 'T',
                                   p_commit                    => 'F',
                                   p_validation_level          => 100,
                                   x_return_status             => l_return_status,
                                   x_msg_count                 => l_msg_count,
                                   x_msg_data                  => l_msg_data,
                                   p_currency_code             => 'INR',
                                   p_amount                    => i.party_amt,
                                   p_receipt_number            => v_receipt_no,
                                   p_receipt_date              => v_receipt_date,
                                   p_gl_date                   => v_receipt_date,
                                   p_comments                  => i.comments,
                                   p_attribute_rec             => p_attribute_rec_type,
                                   p_customer_number           => i.cust_no,
--                                  p_customer_number           => '110155',
                                   p_receipt_method_id         => i.receipt_method_id,
                                   p_cr_id                     => l_cash_receipt_id,
                                   p_global_attribute_rec      => NULL,
                                   p_org_id                    => 288
                                  );
               ELSIF i.party_number IS NULL
               -- Asked to gaurav for confirmation
               THEN
                  aucustom.xxses_debug_prc
                                          ('if party number is null to - P ',
                                              'i.party_number....'
                                           || i.party_number
                                          );
                  -- DBMS_OUTPUT.put_line ('party number null ');
                  apps.ar_receipt_api_pub.create_cash@hrtoebs
                                  (p_api_version               => 1.0,
                                   p_init_msg_list             => 'T',
                                   p_commit                    => 'T',
                                   p_validation_level          => 100,
                                   x_return_status             => l_return_status,
                                   x_msg_count                 => l_msg_count,
                                   x_msg_data                  => l_msg_data,
                                   p_currency_code             => 'INR',
                                   p_amount                    => i.party_amt,
                                   p_receipt_number            => v_receipt_no,
                                   p_receipt_date              => v_receipt_date,
                                   p_comments                  => i.comments,
                                   p_gl_date                   => v_receipt_date,
                                   p_attribute_rec             => p_attribute_rec_type,
                                   p_receipt_method_id         => i.receipt_method_id,
                                   p_cr_id                     => l_cash_receipt_id,
                                   p_global_attribute_rec      => NULL,
                                   p_org_id                    => 288
                                  );
               END IF;

--------------------------------------------------------
           -- DBMS_OUTPUT.put_line ('id  ' || l_cash_receipt_id);
               aucustom.xxses_debug_prc ('if case_receipt_id is null to - Q ',
                                            'l_cash_receipt_id....'
                                         || l_cash_receipt_id
                                        );

               IF l_cash_receipt_id IS NULL
               THEN
                  BEGIN
                     IF l_msg_count = 1
                     THEN
                        l_error_mesg := l_msg_data;
                        aucustom.xxses_debug_prc ('l_msg_data ' || l_msg_data);
                     ELSIF l_msg_count > 1
                     THEN
                        l_msg_data := NULL;

                        LOOP
                           p_count := p_count + 1;
                           l_msg_data := NULL;
                           l_msg_data := l_msg_data;

                           IF l_msg_data IS NULL
                           THEN
                              EXIT;
                           END IF;
                        END LOOP;

                        l_error_mesg := l_error_mesg || '-' || l_msg_data;
                        aucustom.xxses_debug_prc (   'Message'
                                                  || p_count
                                                  || '.'
                                                  || l_error_mesg
                                                 );
                     END IF;

                     aucustom.xxses_debug_prc
                                           ('if case_receipt_id null to - T ',
                                            l_error_mesg
                                           );   --'L_REC_CNT....'||L_REC_CNT);
                     aucustom.xxses_debug_prc ('COMP ID to - U',
                                               i.composite_receipt_id
                                              );
                     --'L_REC_CNT....'||L_REC_CNT);
                     aucustom.xxses_debug_prc ('Rcpt ID to - V ',
                                               i.receipt_number
                                              );
                     --'L_REC_CNT....'||L_REC_CNT);
                     aucustom.xxses_debug_prc ('srno ID to - W ',
                                               i.serial_number
                                              );

                     --'L_REC_CNT....'||L_REC_CNT);
                     UPDATE addb.addb_xxa_ar_trans_erp_rcpt_onl d
                        SET d.process_flag = 'E',
                            d.process_message = l_error_mesg,
                            d.process_date = SYSDATE
                      WHERE d.composite_receipt_id = i.composite_receipt_id
                        -- AND d.receipt_number = i.receipt_number
                        AND d.doctype = 'RCR'
                        AND d.serial_number = i.serial_number;

                     COMMIT;
                     aucustom.xxses_debug_prc
                                    ('Error massage and message data to - X ',
                                     l_error_mesg || ',' || l_msg_data
                                    );
                  END;
               ELSE
                  BEGIN
                     UPDATE addb.addb_xxa_ar_trans_erp_rcpt_onl d
                        SET d.process_flag = 'S',
                            d.process_message =
                                         'SUCCESS' || '-' || l_cash_receipt_id,
                            d.process_date = SYSDATE,
                            process_message12 = 'Through Update API'      ---,
                      --d.receipt_date = SYSDATE
                     WHERE  d.composite_receipt_id = i.composite_receipt_id
                        -- AND d.receipt_number = i.receipt_number
                        AND d.doctype = 'RCR'
                        AND d.serial_number = i.serial_number;

                     COMMIT;
                     aucustom.xxses_debug_prc
                                           ('update table processflag to - Y',
                                            'S'
                                           );   --'L_REC_CNT....'||L_REC_CNT);
                  END;
               END IF;
            END LOOP;
         END;
      END LOOP;

      BEGIN
         UPDATE addb.addb_xxa_ar_trans_erp_rcpt_onl tt
            SET process_message =
                    'Dublicate because cheque number have two or more receipt',
                process_flag = 'N',
                chno = chno || '-D_' || SUBSTR (composite_receipt_id, -2, 2),
                process_date = SYSDATE
          WHERE tt.process_message =
                   'A cash receipt with this number, date, amount and customer already exists.'
            AND NOT EXISTS (
                   SELECT 'Y'
                     FROM ar_cash_receipts_all@hrtoebs
                    WHERE attribute1 = TO_CHAR (tt.composite_receipt_id)
                      AND receipt_date = tt.receipt_date
                      AND status NOT IN ('REV'));

         aucustom.xxses_debug_prc
            ('Duplicate record because of cheq number to - Z ',
             'A cash receipt with this number, date, amount and customer already exists.'
            );
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         UPDATE addb.addb_xxa_ar_trans_erp_rcpt_onl tt
            SET process_message =
                      'SUCCESS'
                   || '-'
                   || (SELECT cash_receipt_id
                         FROM ar_cash_receipts_all@hrtoebs
                        WHERE attribute1 = TO_CHAR (tt.composite_receipt_id)
                          AND receipt_date = tt.receipt_date
                          AND status NOT IN ('REV')),
                process_flag = 'S',
                process_date = SYSDATE                                     --,
          -- receipt_date = SYSDATE
         WHERE  tt.process_message =
                   'A cash receipt with this number, date, amount and customer already exists.'
            AND EXISTS (
                   SELECT 'Y'
                     FROM ar_cash_receipts_all@hrtoebs
                    WHERE attribute1 = TO_CHAR (tt.composite_receipt_id)
                      AND receipt_date = tt.receipt_date
                      AND status NOT IN ('REV'));

         aucustom.xxses_debug_prc
            ('Duplicate record because of cheq number to - A1 ',
             'A cash receipt with this number, date, amount and customer already exists.'
            );
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         UPDATE addb.addb_xxa_ar_trans_erp_rcpt_onl tt
            SET process_message =
                      'SUCCESS REVERS'
                   || '-'
                   || (SELECT cash_receipt_id
                         FROM ar_cash_receipts_all@hrtoebs
                        WHERE attribute1 = TO_CHAR (tt.composite_receipt_id)
                          AND status IN ('REV')),
                process_flag = 'S',
                process_date = SYSDATE
                                                                         ----,
          --- receipt_date = SYSDATE
         WHERE  (   tt.process_message LIKE 'Invalid cash receipt identifier%'
                 OR tt.process_message IS NULL
                )
            AND EXISTS (
                   SELECT 'Y'
                     FROM ar_cash_receipts_all@hrtoebs
                    WHERE attribute1 = TO_CHAR (tt.composite_receipt_id)
                      AND status IN ('REV'));

         aucustom.xxses_debug_prc
                          ('Duplicate record because of cheq number to - A2 ',
                           'Invalid cash receipt identifier%'
                          );
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END xxa_ar_onl_receipt_p3;
   ---------------------AMIT---------------15-MAY-2024
   PROCEDURE xxa_ar_onl_receipt_p4 (
      errbuf    OUT      VARCHAR2,
      retcode   OUT      NUMBER,
      p_unit    IN       VARCHAR2 DEFAULT NULL,
      p_date    IN       DATE DEFAULT NULL                              --V1.0
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      CURSOR unit (p_unit1 VARCHAR2)
      IS
         (SELECT organization_id, organization_code, flex_value
            FROM xxau_accounting_unit_new
           WHERE organization_code NOT IN ('HSO')
             AND flex_value = NVL (p_unit, flex_value));

      CURSOR c1 (p_unit1 VARCHAR2)      --------------------for normal receipt
      IS
         SELECT tt.composite_receipt_id, tt.serial_number, nvl(tt.party_number,dd.meaning) party_number ,
                tt.party_name, tt.party_location, tt.receipt_number,
                tt.party_amt, tt.attribute_category, tt.attribute1,
                tt.attribute2, tt.attribute3, tt.attribute4, tt.attribute5,
                tt.attribute6, tt.attribute7, tt.attribute8, tt.attribute9,
                tt.attribute10, tt.attribute11, tt.attribute12,
                tt.attribute13, tt.attribute14, tt.attribute15,
                tt.process_flag, tt.process_message, tt.process_date,
                tt.created_by, tt.creation_date, tt.last_updated_by,
                tt.last_update_date, tt.comments, tt.process_flag12,
                tt.process_message12, tt.process_date12, tt.receipt_date,
                tt.chno, tt.bank_acc_id, tt.bank_acc_number, tt.bank_acc_name,
                tt.doctype, tt.ref_receiptno, tt.ref_receiptdt,
                tt.ref_doctype, tt.security_flag, tt.cons_type,
                tt.cons_rcpt_no, tt.cheque_bounce_reason,
                tt.receipt_method_id, tt.prov_recptdt rct_date,
                nvl(tt.erp_customer_number,dd.meaning) cust_no, gl.segment1 unit_code
           FROM addb.addb_xxa_ar_trans_erp_pcc_onl tt,--addb.addb_xxa_ar_trans_erp_rcpt_onl tt,
                apps.ar_receipt_method_accounts_all@hrtoebs td2,
                apps.ar_receipt_methods@hrtoebs td3,
                apps.gl_code_combinations@hrtoebs gl,
                (select b.lookup_code,b.MEANING from FND_LOOKUP_TYPES_VL@hrtoebs a,
                          FND_LOOKUP_VALUES_VL@hrtoebs b
                 where a.lookup_type ='SCHEME CODE AR MAPPING'
                 and a.lookup_type =b.lookup_type
                 ) DD
          WHERE tt.receipt_method_id = td3.receipt_method_id
            AND td3.receipt_method_id = td2.receipt_method_id
            AND td2.org_id = 288
            AND td2.end_date IS NULL
            AND td3.end_date IS NULL
            AND NVL (process_flag, 'N') = 'N'
            and dd.lookup_code = tt.SCH_OPT 
            AND doctype = 'RCR'
            AND td2.cash_ccid = gl.code_combination_id
            AND gl.segment1 = NVL (p_unit1, gl.segment1)
            AND NVL (security_flag, 'N') = 'N';

      CURSOR c3 (p_receipt_id NUMBER)
      IS
         SELECT d.attribute_category, d.attribute14, d.attribute11
           from addb.addb_xxa_ar_trans_erp_pcc_onl d
          WHERE 1 = 1 AND d.composite_receipt_id = p_receipt_id;

      CURSOR ft_update
      IS
         (SELECT tt.composite_receipt_id, tt.ROWID row_id,
                 tt1.cash_receipt_id
            from addb.addb_xxa_ar_trans_erp_pcc_onl tt,
                 apps.ar_cash_receipts_all@hrtoebs tt1
           WHERE 1 = 1
             AND TO_CHAR (tt.composite_receipt_id) = tt1.attribute1
             AND tt1.attribute9 = tt.receipt_number
             AND NVL (tt.process_flag, 'N') IN ('N', 'E'));

      l_return_status          VARCHAR2 (1);
      l_msg_count              NUMBER;
      l_msg_data               VARCHAR2 (4000)                         := NULL;
      l_cash_receipt_id        NUMBER;
      l_misc_receipt_id        NUMBER;
      l_error_mesg             VARCHAR2 (4000)                         := NULL;
      p_count                  NUMBER;
      v_rec_trx_id             NUMBER;
      lv_receipt_method_name   VARCHAR2 (80);
      ln_receipt_method_id     NUMBER                                     := 0;
      x_return_status          VARCHAR2 (30)                           := NULL;
      x_msg_count              NUMBER;
      x_msg_data               VARCHAR2 (4000)                         := NULL;
      p_cr_id                  NUMBER;
      p_misc_receipt_id        NUMBER;
      v_unit_name              VARCHAR2 (3);
      err                      VARCHAR2 (400);
      ebf                      NUMBER;
      p_attribute_rec_type     apps.ar_receipt_api_pub.attribute_rec_type@hrtoebs;
      v_receipt_no             VARCHAR2 (40)                           := NULL;
      v_return_status          VARCHAR2 (1);
      v_msg_count              NUMBER;
      v_msg_data               VARCHAR2 (2000);
      v_context                VARCHAR2 (2);
      i                        NUMBER;
      v_receipt_date           DATE;
      v_revers_date            DATE;
      v_check                  NUMBER                                     := 0;
   BEGIN
       DBMS_OUTPUT.put_line ('START');
      apps.fnd_global.apps_initialize@hrtoebs (2482, 52024, 222);
      apps.mo_global.set_policy_context@hrtoebs ('S', 288);
      apps.fnd_file.put_line@hrtoebs (fnd_file.output,
                                      'Table is empty successfully'
                                     );

      BEGIN
         FOR ft IN ft_update
         LOOP
            UPDATE addb.ADDB_XXA_AR_TRANS_ERP_PCC_ONL
               SET process_flag = 'S',
                   process_message = 'SUCCESS-' || ft.cash_receipt_id,
                   process_date = SYSDATE,
                   process_message12 = 'Through Update Query'
             WHERE ROWID = ft.row_id
               AND composite_receipt_id = ft.composite_receipt_id;

            COMMIT;
         END LOOP;
      END;

      FOR unit_m IN unit (p_unit)
      LOOP
         aucustom.xxses_debug_prc ('Start c1');

         BEGIN
            FOR i IN c1 (unit_m.flex_value)
            LOOP
               l_msg_data := NULL;
               l_msg_count := NULL;
               l_return_status := NULL;
               l_cash_receipt_id := NULL;
               p_attribute_rec_type.attribute_category :=
                                                         i.attribute_category;
               aucustom.xxses_debug_prc
                          ('p_attribute_rec_type.attribute_category to - C ',
                           'i.attribute_category....' || i.attribute_category
                          );
               p_attribute_rec_type.attribute1 := i.composite_receipt_id;
               ---------------Reference ID
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute1 to - D ',
                                       'i.composite_receipt_id....'
                                    || i.composite_receipt_id
                                   );
               p_attribute_rec_type.attribute2 := NVL (i.attribute2, 5);
               -----------------Receipt type
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute2 to - E ',
                                    'i.attribute2....' || i.attribute2
                                   );
               p_attribute_rec_type.attribute3 := NVL (i.attribute3, 'N');
               --------------Dispaly
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute3 to - F ',
                                    'i.attribute3....' || i.attribute3
                                   );
               p_attribute_rec_type.attribute4 := NVL (i.attribute4, 'N');
               ---------------Covering
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute4 to - G ',
                                    'i.attribute4....' || i.attribute4
                                   );
               p_attribute_rec_type.attribute6 := NVL (i.attribute6, 'N');
               ------sgned
               p_attribute_rec_type.attribute5 := NVL (i.attribute5, 'N');
               ---------------stamped
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute5 to - I ',
                                    'i.attribute5....' || i.attribute5
                                   );
               p_attribute_rec_type.attribute10 := i.attribute12;
               p_attribute_rec_type.attribute11 := i.attribute13;
               ---------------bank Name
               p_attribute_rec_type.attribute9 := i.attribute9;
               -------------------compisite_reference_dcr_receipt_no
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute9 to - J ',
                                    'i.attribute9....' || i.attribute9
                                   );
               --     p_attribute_rec_type.attribute11 := i.attribute11;
               p_attribute_rec_type.attribute14 := i.attribute11;
               ---------pr receipt
               aucustom.xxses_debug_prc
                                  ('p_attribute_rec_type.attribute10 to - K ',
                                   'i.attribute11....' || i.attribute11
                                  );
               p_attribute_rec_type.attribute12 := i.attribute14;
               -----------------bank branch
               aucustom.xxses_debug_prc
                                   ('p_attribute_rec_type.attribute8 to - L ',
                                    'i.attribute8....' || i.attribute8
                                   );
               p_attribute_rec_type.attribute15 := i.attribute15;
               -------------pr date
               aucustom.xxses_debug_prc
                                  ('p_attribute_rec_type.attribute15 to - N ',
                                   'i.attribute15....' || i.attribute15
                                  );

               IF i.attribute2 IN ('1', '10', '7', '8')
               THEN
                  IF i.chno IS NULL
                  THEN
                     v_receipt_no := i.receipt_number;
                  ELSE
                     v_receipt_no := i.chno;
                  END IF;
               ELSE
                  v_receipt_no := i.receipt_number;
               END IF;

               IF p_date IS NULL
               THEN
                  v_receipt_date := i.receipt_date;
               -- v_receipt_date := TRUNC (SYSDATE);-------------for cio receipt not for DCR
               ELSE
                  --v_receipt_date := p_date;-------------for cio receipt not for DCR
                  ---v_receipt_date := TRUNC (SYSDATE);
                  v_receipt_date := i.receipt_date;
               END IF;

               IF i.party_number IS NOT NULL
               THEN
                   DBMS_OUTPUT.put_line ('party number not null ');
                  aucustom.xxses_debug_prc
                                      ('if party number is not null to - O ',
                                       'i.party_number....' || i.party_number
                                      );
                  begin
                    apps.ar_receipt_api_pub.create_cash@hrtoebs
                                  (p_api_version               => 1.0,
                                   p_init_msg_list             => 'T',
                                   p_commit                    => 'F',
                                   p_validation_level          => 100,
                                   x_return_status             => l_return_status,
                                   x_msg_count                 => l_msg_count,
                                   x_msg_data                  => l_msg_data,
                                   p_currency_code             => 'INR',
                                   p_amount                    => i.party_amt,
                                   p_receipt_number            => v_receipt_no,
                                   p_receipt_date              => v_receipt_date,
                                   p_gl_date                   => v_receipt_date,
                                   p_comments                  => i.comments,
                                   p_attribute_rec             => p_attribute_rec_type,
                                   p_customer_number           => i.cust_no,
--                                  p_customer_number           => '110155',
                                   p_receipt_method_id         => i.receipt_method_id,
                                   p_cr_id                     => l_cash_receipt_id,
                                   p_global_attribute_rec      => NULL,
                                   p_org_id                    => 288
                                  );

                                  DBMS_OUTPUT.put_line ('x_return_status '||i.cust_no||'-'||sqlerrm); 
                    exception when others then
                         DBMS_OUTPUT.put_line ('After creation of receipt '||sqlerrm);
                    end;                

               ELSIF i.party_number IS NULL
               -- Asked to gaurav for confirmation
               THEN
                  aucustom.xxses_debug_prc
                                          ('if party number is null to - P ',
                                              'i.party_number....'
                                           || i.party_number
                                          );
                   DBMS_OUTPUT.put_line ('party number null -2 ');
                  apps.ar_receipt_api_pub.create_cash@hrtoebs
                                  (p_api_version               => 1.0,
                                   p_init_msg_list             => 'T',
                                   p_commit                    => 'T',
                                   p_validation_level          => 100,
                                   x_return_status             => l_return_status,
                                   x_msg_count                 => l_msg_count,
                                   x_msg_data                  => l_msg_data,
                                   p_currency_code             => 'INR',
                                   p_amount                    => i.party_amt,
                                   p_receipt_number            => v_receipt_no,
                                   p_receipt_date              => v_receipt_date,
                                   p_comments                  => i.comments,
                                   p_gl_date                   => v_receipt_date,
                                   p_attribute_rec             => p_attribute_rec_type,
                                   p_receipt_method_id         => i.receipt_method_id,
                                   p_cr_id                     => l_cash_receipt_id,
                                   p_global_attribute_rec      => NULL,
                                   p_org_id                    => 288
                                  );
               END IF;

--------------------------------------------------------
            DBMS_OUTPUT.put_line ('id  ' || l_cash_receipt_id);
               aucustom.xxses_debug_prc ('if case_receipt_id is null to - Q ',
                                            'l_cash_receipt_id....'
                                         || l_cash_receipt_id
                                        );

               IF l_cash_receipt_id IS NULL
               THEN
                  BEGIN
                     IF l_msg_count = 1
                     THEN
                        l_error_mesg := l_msg_data;
                        aucustom.xxses_debug_prc ('l_msg_data ' || l_msg_data);
                     ELSIF l_msg_count > 1
                     THEN
                        l_msg_data := NULL;

                        LOOP
                           p_count := p_count + 1;
                           l_msg_data := NULL;
                           l_msg_data := l_msg_data;

                           IF l_msg_data IS NULL
                           THEN
                              EXIT;
                           END IF;
                        END LOOP;

                        l_error_mesg := l_error_mesg || '-' || l_msg_data;
                        aucustom.xxses_debug_prc (   'Message'
                                                  || p_count
                                                  || '.'
                                                  || l_error_mesg
                                                 );
                     END IF;

                     aucustom.xxses_debug_prc
                                           ('if case_receipt_id null to - T ',
                                            l_error_mesg
                                           );   --'L_REC_CNT....'||L_REC_CNT);
                     aucustom.xxses_debug_prc ('COMP ID to - U',
                                               i.composite_receipt_id
                                              );
                     --'L_REC_CNT....'||L_REC_CNT);
                     aucustom.xxses_debug_prc ('Rcpt ID to - V ',
                                               i.receipt_number
                                              );
                     --'L_REC_CNT....'||L_REC_CNT);
                     aucustom.xxses_debug_prc ('srno ID to - W ',
                                               i.serial_number
                                              );

                     --'L_REC_CNT....'||L_REC_CNT);
                     UPDATE addb.ADDB_XXA_AR_TRANS_ERP_PCC_ONL d
                        SET d.process_flag = 'E',
                            d.process_message = l_error_mesg,
                            d.process_date = SYSDATE
                      WHERE d.composite_receipt_id = i.composite_receipt_id
                        -- AND d.receipt_number = i.receipt_number
                        AND d.doctype = 'RCR'
                        AND d.serial_number = i.serial_number;

                     COMMIT;
                     aucustom.xxses_debug_prc
                                    ('Error massage and message data to - X ',
                                     l_error_mesg || ',' || l_msg_data
                                    );
                  END;
               ELSE
                  BEGIN
                     UPDATE addb.ADDB_XXA_AR_TRANS_ERP_PCC_ONL d
                        SET d.process_flag = 'S',
                            d.process_message =
                                         'SUCCESS' || '-' || l_cash_receipt_id,
                            d.process_date = SYSDATE,
                            process_message12 = 'Through Update API',      ---,
                      --d.receipt_date = SYSDATE
                      d.ERP_CUSTOMER_NUMBER = i.cust_no                                     --,
                     WHERE  d.composite_receipt_id = i.composite_receipt_id
                        -- AND d.receipt_number = i.receipt_number
                        AND d.doctype = 'RCR'
                        AND d.serial_number = i.serial_number;

                     COMMIT;
                     aucustom.xxses_debug_prc
                                           ('update table processflag to - Y',
                                            'S'
                                           );   --'L_REC_CNT....'||L_REC_CNT);
                  END;
               END IF;
            END LOOP;
         END;
      END LOOP;

      BEGIN
         UPDATE addb.ADDB_XXA_AR_TRANS_ERP_PCC_ONL tt
            SET process_message =
                    'Dublicate because cheque number have two or more receipt',
                process_flag = 'N',
                chno = chno || '-D_' || SUBSTR (composite_receipt_id, -2, 2),
                process_date = SYSDATE
          WHERE tt.process_message =
                   'A cash receipt with this number, date, amount and customer already exists.'
            AND NOT EXISTS (
                   SELECT 'Y'
                     FROM ar_cash_receipts_all@hrtoebs
                    WHERE attribute1 = TO_CHAR (tt.composite_receipt_id)
                      AND receipt_date = tt.receipt_date
                      AND status NOT IN ('REV'));

         aucustom.xxses_debug_prc
            ('Duplicate record because of cheq number to - Z ',
             'A cash receipt with this number, date, amount and customer already exists.'
            );
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         UPDATE addb.ADDB_XXA_AR_TRANS_ERP_PCC_ONL tt
            SET process_message =
                      'SUCCESS'
                   || '-'
                   || (SELECT cash_receipt_id
                         FROM ar_cash_receipts_all@hrtoebs
                        WHERE attribute1 = TO_CHAR (tt.composite_receipt_id)
                          AND receipt_date = tt.receipt_date
                          AND status NOT IN ('REV')),
                process_flag = 'S',
                process_date = SYSDATE                
          -- receipt_date = SYSDATE
         WHERE  tt.process_message =
                   'A cash receipt with this number, date, amount and customer already exists.'
            AND EXISTS (
                   SELECT 'Y'
                     FROM ar_cash_receipts_all@hrtoebs
                    WHERE attribute1 = TO_CHAR (tt.composite_receipt_id)
                      AND receipt_date = tt.receipt_date
                      AND status NOT IN ('REV'));

         aucustom.xxses_debug_prc
            ('Duplicate record because of cheq number to - A1 ',
             'A cash receipt with this number, date, amount and customer already exists.'
            );
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         UPDATE addb.ADDB_XXA_AR_TRANS_ERP_PCC_ONL tt
            SET process_message =
                      'SUCCESS REVERS'
                   || '-'
                   || (SELECT cash_receipt_id
                         FROM ar_cash_receipts_all@hrtoebs
                        WHERE attribute1 = TO_CHAR (tt.composite_receipt_id)
                          AND status IN ('REV')),
                process_flag = 'S',
                process_date = SYSDATE
                                                                         ----,
          --- receipt_date = SYSDATE
         WHERE  (   tt.process_message LIKE 'Invalid cash receipt identifier%'
                 OR tt.process_message IS NULL
                )
            AND EXISTS (
                   SELECT 'Y'
                     FROM ar_cash_receipts_all@hrtoebs
                    WHERE attribute1 = TO_CHAR (tt.composite_receipt_id)
                      AND status IN ('REV'));

         aucustom.xxses_debug_prc
                          ('Duplicate record because of cheq number to - A2 ',
                           'Invalid cash receipt identifier%'
                          );
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END xxa_ar_onl_receipt_p4;
END xxau_cstm_utl;
/
