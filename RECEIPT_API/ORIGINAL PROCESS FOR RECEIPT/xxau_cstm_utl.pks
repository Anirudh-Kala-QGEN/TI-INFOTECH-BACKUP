CREATE OR REPLACE PACKAGE AUCUSTOM.xxau_cstm_utl
AS
/*-------------------------------------------
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
--------------------------------------------*/
   PROCEDURE xxa_ar_4cplus_receipt_pm (
      errbuf    OUT      VARCHAR2,
      retcode   OUT      NUMBER,
      p_unit    IN       VARCHAR2                                      --V1.0
   );

   PROCEDURE xxa_ar_4cplus_receipt_p2 (
      errbuf    OUT      VARCHAR2,
      retcode   OUT      NUMBER,
      p_unit    IN       VARCHAR2 DEFAULT NULL,
      p_date    IN       DATE DEFAULT NULL                             --V1.0
   );

   PROCEDURE xxa_ar_dcr_receipt_p3 (
      errbuf    OUT      VARCHAR2,
      retcode   OUT      NUMBER,
      p_unit    IN       VARCHAR2 DEFAULT NULL,
      p_date    IN       DATE DEFAULT NULL                             --V1.0
   );

   PROCEDURE xxau_daily_4cplus_receipt_err (
      errbuf    OUT   VARCHAR2,
      retcode   OUT   NUMBER
   );

   PROCEDURE xxau_create_ar_cm_dm (errbuff OUT NUMBER, retcode OUT NUMBER);

   PROCEDURE xxau_create_ar_cm_dm_cio (
      errbuff   OUT      NUMBER,
      retcode   OUT      NUMBER,
      p_unit    IN       VARCHAR2 DEFAULT NULL
   );

   PROCEDURE xxau_create_ar_ajd_ajc_cio (
      errbuff   OUT      NUMBER,
      retcode   OUT      NUMBER,
      p_unit    IN       VARCHAR2 DEFAULT NULL,
      p_month   IN       VARCHAR2
   );

   PROCEDURE xxa_ar_gate_receipt_p2_man (p_unit VARCHAR2, p_gl_date DATE);

   PROCEDURE xxau_personal_emp_ledger (
      p_org_id         NUMBER DEFAULT NULL,
      p_person_id      NUMBER DEFAULT NULL,
      p_item_from      VARCHAR2 DEFAULT NULL,
      p_item_to        VARCHAR2 DEFAULT NULL,
      p_mode           VARCHAR2 DEFAULT 'D',
      p_sub_inv_from   VARCHAR2 DEFAULT NULL,
      p_sub_inv_to     VARCHAR2 DEFAULT NULL
   );

   PROCEDURE xxau_cir_flctu_report (
      p_from_date     DATE,
      p_to_date       DATE,
      p_org_id        NUMBER,
      p_dak           NUMBER,
      p_customer_id   NUMBER,
      p_type          VARCHAR2
   );

   PROCEDURE xxau_error_up (errbuff OUT NUMBER, retcode OUT NUMBER);

   PROCEDURE xxau_create_ap_inv_p (
      errbuff    OUT   NUMBER,
      retcode    OUT   NUMBER,
      p_source         VARCHAR2
   );

   PROCEDURE validate_imported_invoices (
      errbuff   OUT   NUMBER,
      retcode   OUT   NUMBER
   );

   PROCEDURE xxau_update_dff_dist (errbuff OUT NUMBER, retcode OUT NUMBER);

   PROCEDURE xxau_update_tax_adv_dtl (
      errbuff    OUT   NUMBER,
      retcode    OUT   NUMBER,
      p_source         VARCHAR2
   );

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
   );

   PROCEDURE xxau_create_ap_myauartical (
      errbuff    OUT   NUMBER,
      retcode    OUT   NUMBER,
      p_source         VARCHAR2
   );

   PROCEDURE xxau_error_up_myau_ap (
      errbuff    OUT   NUMBER,
      retcode    OUT   NUMBER,
      p_source         VARCHAR2
   );
   PROCEDURE xxau_create_ap_myauempadvance (
      errbuff    OUT   NUMBER,
      retcode    OUT   NUMBER,
      p_source         VARCHAR2
   );

   PROCEDURE xxau_error_up_myauempadvance (
      errbuff    OUT   NUMBER,
      retcode    OUT   NUMBER,
      p_source         VARCHAR2
   );
   PROCEDURE xxa_ar_onl_receipt_p3 (
      errbuf    OUT      VARCHAR2,
      retcode   OUT      NUMBER,
      p_unit    IN       VARCHAR2 DEFAULT NULL,
      p_date    IN       DATE DEFAULT NULL                             --V1.0
   );
   
   PROCEDURE xxa_ar_onl_receipt_p4 (
      errbuf    OUT      VARCHAR2,
      retcode   OUT      NUMBER,
      p_unit    IN       VARCHAR2 DEFAULT NULL,
      p_date    IN       DATE DEFAULT NULL                             --V1.0
   );
END xxau_cstm_utl;
/
