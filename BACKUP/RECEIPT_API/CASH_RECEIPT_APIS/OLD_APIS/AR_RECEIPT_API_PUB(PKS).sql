CREATE OR REPLACE Package APPS.AR_RECEIPT_API_PUB AUTHID CURRENT_USER AS
/* $Header: ARXPRECS.pls 120.40.12020000.6 2016/08/03 09:53:52 aravipud ship $           */
/*#
* Receipt APIs provide an extension to existing
* functionality for creating and manipulating receipts
* through standard AR Receipts forms and lockboxes.
* @rep:scope public
* @rep:metalink 236938.1 See OracleMetaLink note 236938.1
* @rep:product AR
* @rep:lifecycle active
* @rep:displayname Receipt
* @rep:category BUSINESS_ENTITY AR_RECEIPT
*/

--Start of comments
--API name : ReceiptsAPI
--Type     : Public.
--Function : Create , apply, unapply and reverse Receipts
--Pre-reqs :
--
-- Notes : Note text
--
-- Modification History
-- Date         Name          Description
-- 10-19-00     Debbie Jancis Modified for tca uptake.  Replaced all
--                            occurances of ra customer tables with
--                            their hz counterparts.
-- 25-MAR-2002  jbeckett      Bug 2270809,2270825 - Additional claim validation
--                            Added dbdrv commands
-- 14-FEB-2003  jbeckett      Bug 2571910 - new procedure Apply_Open_Receipt().
--
-- 03-NOV-2003           Obaidur Rashid
--
--  Description of changes:
--  =======================
--
--    Changes for the CONSOLIDATE BANK ACCOUNTS project are done in this
--    version.  List of changes are given below.
--
--    PLEASE NOTE ONLY SOME OF THESE MAY APPLY TO THIS FILE.
--
--    1. References to ap_bank_branches has been changed to ce_bank_branches_v
--       where possible.
--
--    2. Reference to ap_bank_accounts for internal bank accounts has been
--       changed to ce_bank_acct_uses.  An additional join may have been added
--       to ce_bank_accounts table if the column selected does not appear in
--       the uses table.
--
--    3. All bank branch/bank account related identifiers declared with %TYPE
--       has been appropriately changed to point to the new data model.
--
--    4. All local identifiers holding the remittance_bank_account_id has been
--       renamed to remit_bank_acct_use_id signifying what it holds now.
--       Please note that parameters for subroutines are left alone even though
--       they too hold use ids now.
--
--    5. Some columns are renamed when mapped in the new data model, so those
--       changes are also made.
--
--    6. For internal bank account, the Where clause conditions involving
--       ap_bank_accounts.set_of_books_id has been omitted as it is now
--       redundant and the column set_of_books_id column is obsolete.
--
-- 02-Feb-2005  Debbie Jancis Added p_customer_reason to activity_application
--              for Enh 4145224
-- 25-Feb-2005  Added API Create_Apply_On_Acc for forward port bug 3398539

--    Changes for the PAYMENT UPTAKE PROJECT project are done in this
--    version.  List of changes are given below.
--
--    1.Removed bank_account_id ,bank_branch_id from Customer_Rec
--
--    2. Removed customer_bank_account_id,customer_bank_account_num,
--        customer_bank_account_name from G_create_cash_rec_type .
--
--    3. Replaced customer_bank_account_id,customer_bank_account_num,
--        customer_bank_account_name
--        with
--       p_trxn_extension_id
--      In the following packages
--      PROCEDURE Create_cash
--      PROCEDURE Create_and_apply
--      PROCEDURE Create_Apply_On_Acc
--
-- 02-Jun-2006  LLCA : Added API Apply_In_Detail
-- 26-Feb-2015  Jixun Huang : ER#20226110: UI&API CHANGES : IMPLEMENTATION OF GDF IN MISC RECEIPTS DISTRIBUTIONS WINDOW
--=============================================================================


TYPE Receipt_Method_Rec     IS RECORD
   (
    receipt_method_id      ar_receipt_methods.receipt_method_id%TYPE,
    remit_bank_acct_use_id ar_cash_receipts.remit_bank_acct_use_id%TYPE
   );

TYPE Customer_Rec   IS  RECORD
         (customer_id          ar_cash_receipts.pay_from_customer%TYPE,
          site_use_id          ar_cash_receipts.customer_site_use_id%TYPE
         );

TYPE attribute_rec_type IS RECORD(
                        attribute_category    VARCHAR2(30) DEFAULT NULL,
                        attribute1            VARCHAR2(150) DEFAULT NULL,
       					attribute2            VARCHAR2(150) DEFAULT NULL,
        				attribute3            VARCHAR2(150) DEFAULT NULL,
        				attribute4            VARCHAR2(150) DEFAULT NULL,
       					attribute5            VARCHAR2(150) DEFAULT NULL,
        				attribute6            VARCHAR2(150) DEFAULT NULL,
        				attribute7            VARCHAR2(150) DEFAULT NULL,
        				attribute8            VARCHAR2(150) DEFAULT NULL,
        				attribute9            VARCHAR2(150) DEFAULT NULL,
        				attribute10           VARCHAR2(150) DEFAULT NULL,
        				attribute11           VARCHAR2(150) DEFAULT NULL,
        				attribute12           VARCHAR2(150) DEFAULT NULL,
        				attribute13           VARCHAR2(150) DEFAULT NULL,
        				attribute14           VARCHAR2(150) DEFAULT NULL,
        				attribute15           VARCHAR2(150) DEFAULT NULL);
TYPE attribute_rec_tbl_type IS TABLE OF AR_RECEIPT_API_PUB.attribute_rec_type
INDEX BY BINARY_INTEGER;

TYPE global_attribute_rec_type IS RECORD(
            global_attribute_category     VARCHAR2(30) default null,
            global_attribute1             VARCHAR2(150) default NULL,
            global_attribute2             VARCHAR2(150) DEFAULT NULL,
            global_attribute3             VARCHAR2(150) DEFAULT NULL,
        	global_attribute4             VARCHAR2(150) DEFAULT NULL,
        	global_attribute5             VARCHAR2(150) DEFAULT NULL,
        	global_attribute6             VARCHAR2(150) DEFAULT NULL,
        	global_attribute7             VARCHAR2(150) DEFAULT NULL,
        	global_attribute8             VARCHAR2(150) DEFAULT NULL,
        	global_attribute9             VARCHAR2(150) DEFAULT NULL,
        	global_attribute10            VARCHAR2(150) DEFAULT NULL,
        	global_attribute11            VARCHAR2(150) DEFAULT NULL,
        	global_attribute12            VARCHAR2(150) DEFAULT NULL,
        	global_attribute13            VARCHAR2(150) DEFAULT NULL,
        	global_attribute14            VARCHAR2(150) DEFAULT NULL,
        	global_attribute15            VARCHAR2(150) DEFAULT NULL,
        	global_attribute16            VARCHAR2(150) DEFAULT NULL,
        	global_attribute17            VARCHAR2(150) DEFAULT NULL,
        	global_attribute18            VARCHAR2(150) DEFAULT NULL,
        	global_attribute19            VARCHAR2(150) DEFAULT NULL,
        	global_attribute20            VARCHAR2(150) DEFAULT NULL);

TYPE global_attribute_rec_type_upd IS RECORD(
                global_attribute_category     VARCHAR2(30)  default FND_API.G_MISS_CHAR,
                global_attribute1             VARCHAR2(150) default FND_API.G_MISS_CHAR,
                global_attribute2             VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute3             VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute4             VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute5             VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute6             VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute7             VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute8             VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute9             VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute10            VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute11            VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute12            VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute13            VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute14            VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute15            VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute16            VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute17            VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute18            VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute19            VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR,
                global_attribute20            VARCHAR2(150) DEFAULT FND_API.G_MISS_CHAR);

TYPE apply_out_rec_type   IS  RECORD
         (receivable_application_id ar_receivable_applications.receivable_application_id%TYPE
         );
attribute_rec_const  attribute_rec_type;
global_attribute_rec_const global_attribute_rec_type;

global_attribute_rec_upd_cons  global_attribute_rec_type_upd;
apply_out_rec  apply_out_rec_type;

--Bug 3628401
TYPE apply_on_account_rec_type IS RECORD
     (receivable_application_id ar_receivable_applications.receivable_application_id%TYPE
     );
g_apply_on_account_out_rec   apply_on_account_rec_type;


TYPE Rec_Method_Tbl_Type    IS TABLE OF Receipt_Method_Rec
                             INDEX BY BINARY_INTEGER;

TYPE Rec_Customer_Tbl_Type  IS TABLE OF Customer_Rec
                             INDEX BY BINARY_INTEGER;
TYPE  G_application_rec_type  IS  RECORD
    ( cash_receipt_id    ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
      receipt_number     ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      customer_trx_id    ra_customer_trx.customer_trx_id%TYPE DEFAULT NULL,
      trx_number         ra_customer_trx.trx_number%TYPE DEFAULT NULL,
      installment        ar_payment_schedules.terms_sequence_number%TYPE DEFAULT NULL,
      applied_payment_schedule_id    ar_payment_schedules.payment_schedule_id%TYPE DEFAULT NULL,
      customer_trx_line_id	ar_receivable_applications.applied_customer_trx_line_id%TYPE DEFAULT NULL,
      line_number           ra_customer_trx_lines.line_number%TYPE DEFAULT NULL,
      amount_applied_from   ar_receivable_applications.amount_applied_from%TYPE DEFAULT NULL,
      trans_to_receipt_rate ar_receivable_applications.trans_to_receipt_rate%TYPE DEFAULT NULL
      );
TYPE  G_create_cash_rec_type IS RECORD
    ( customer_id                 hz_cust_accounts.cust_account_id%TYPE,
      customer_name               hz_parties.party_name%TYPE,
      customer_number             hz_cust_accounts.account_number%TYPE,
      cust_site_use_id            hz_cust_site_uses.site_use_id%TYPE,
      location                    hz_cust_site_uses.location%TYPE,
      /* 6612301 */
      customer_bank_account_id    ar_cash_receipts.customer_bank_account_id%TYPE,
      customer_bank_account_num   iby_ext_bank_accounts_v.bank_account_number%TYPE,
      customer_bank_account_name  iby_ext_bank_accounts_v.bank_account_name%TYPE,
      remit_bank_acct_use_id      ce_bank_acct_uses_all.bank_acct_use_id%TYPE,
      remittance_bank_account_num ce_bank_accounts.bank_account_num%TYPE,
      remittance_bank_account_name ce_bank_accounts.bank_account_name%TYPE,
      receipt_method_id            ar_receipt_methods.receipt_method_id%TYPE,
      receipt_method_name          ar_receipt_methods.name%TYPE
      );
 TYPE G_unapp_rec_type   IS RECORD
     (trx_number        ra_customer_trx.trx_number%TYPE,
      customer_trx_id   ar_receivable_applications.customer_trx_id%TYPE,
      applied_ps_id     ar_receivable_applications.applied_payment_schedule_id%TYPE,
      cash_receipt_id   ar_receivable_applications.cash_receipt_id%TYPE,
      receipt_number    ar_cash_receipts.receipt_number%TYPE,
      receivable_application_id     ar_receivable_applications.receivable_application_id%TYPE);
 TYPE G_unapp_on_ac_rec  IS RECORD
     (cash_receipt_id   ar_receivable_applications.cash_receipt_id%TYPE,
      receipt_number    ar_cash_receipts.receipt_number%TYPE,
      receivable_application_id     ar_receivable_applications.receivable_application_id%TYPE);
 TYPE G_activity_unapp_rec IS RECORD
     (cash_receipt_id   ar_receivable_applications.cash_receipt_id%TYPE,
      receipt_number    ar_cash_receipts.receipt_number%TYPE,
      receivable_application_id     ar_receivable_applications.receivable_application_id%TYPE);

  Original_create_cash_info   G_create_cash_rec_type;
  Original_application_info   G_application_rec_type;
  Original_unapp_info         G_unapp_rec_type;
  Original_unapp_onac_info    G_unapp_on_ac_rec;
  Original_activity_unapp_info G_activity_unapp_rec;

TYPE llca_trx_lines_rec_type  IS RECORD (
      customer_trx_line_id         NUMBER DEFAULT NULL,
      line_number                  NUMBER DEFAULT NULL,
      line_amount                  NUMBER DEFAULT NULL,
      tax_amount                   NUMBER DEFAULT NULL,
      amount_applied               NUMBER DEFAULT NULL,
      amount_applied_from          NUMBER DEFAULT NULL,
      line_discount                NUMBER DEFAULT NULL,
      tax_discount                 NUMBER DEFAULT NULL,
      attribute_category           VARCHAR2(30) DEFAULT NULL,
      attribute1                   VARCHAR2(150) DEFAULT NULL,
      attribute2                   VARCHAR2(150) DEFAULT NULL,
      attribute3                   VARCHAR2(150) DEFAULT NULL,
      attribute4                   VARCHAR2(150) DEFAULT NULL,
      attribute5                   VARCHAR2(150) DEFAULT NULL,
      attribute6                   VARCHAR2(150) DEFAULT NULL,
      attribute7                   VARCHAR2(150) DEFAULT NULL,
      attribute8                   VARCHAR2(150) DEFAULT NULL,
      attribute9                   VARCHAR2(150) DEFAULT NULL,
      attribute10                  VARCHAR2(150) DEFAULT NULL,
      attribute11                  VARCHAR2(150) DEFAULT NULL,
      attribute12                  VARCHAR2(150) DEFAULT NULL,
      attribute13                  VARCHAR2(150) DEFAULT NULL,
      attribute14                  VARCHAR2(150) DEFAULT NULL,
      attribute15                  VARCHAR2(150) DEFAULT NULL
                                       );

TYPE llca_trx_lines_tbl_type IS TABLE OF llca_trx_lines_rec_type
        INDEX BY BINARY_INTEGER;

llca_def_trx_lines_tbl_type  llca_trx_lines_tbl_type;

TYPE CR_ID_TABLE     IS RECORD
   (
    cash_receipt_id      DBMS_SQL.NUMBER_TABLE,
    cc_error_code        DBMS_SQL.VARCHAR2_TABLE,
    cc_error_text        DBMS_SQL.VARCHAR2_TABLE,
    cc_instrtype         DBMS_SQL.VARCHAR2_TABLE
   );

--ER 7417553
TYPE misc_dist_rec_type IS RECORD
   (
    AMOUNT	                NUMBER          DEFAULT NULL,
    acctd_amount                number          DEFAULT NULL,
    PERCENT	                NUMBER          DEFAULT NULL,
    CODE_COMBINATION_ID	        NUMBER(15)      DEFAULT NULL,
    COMMENTS                    VARCHAR2(240)   DEFAULT NULL,
	/*Added for ER 24375569 start*/
	ATTRIBUTE_CATEGORY    VARCHAR2(30) DEFAULT NULL,
	ATTRIBUTE1            VARCHAR2(150) DEFAULT NULL,
	ATTRIBUTE2            VARCHAR2(150) DEFAULT NULL,
	ATTRIBUTE3            VARCHAR2(150) DEFAULT NULL,
	ATTRIBUTE4            VARCHAR2(150) DEFAULT NULL,
	ATTRIBUTE5            VARCHAR2(150) DEFAULT NULL,
	ATTRIBUTE6            VARCHAR2(150) DEFAULT NULL,
	ATTRIBUTE7            VARCHAR2(150) DEFAULT NULL,
	ATTRIBUTE8            VARCHAR2(150) DEFAULT NULL,
	ATTRIBUTE9            VARCHAR2(150) DEFAULT NULL,
	ATTRIBUTE10           VARCHAR2(150) DEFAULT NULL,
	ATTRIBUTE11           VARCHAR2(150) DEFAULT NULL,
	ATTRIBUTE12           VARCHAR2(150) DEFAULT NULL,
	ATTRIBUTE13           VARCHAR2(150) DEFAULT NULL,
	ATTRIBUTE14           VARCHAR2(150) DEFAULT NULL,
	ATTRIBUTE15           VARCHAR2(150) DEFAULT NULL,
	/*Added for ER 24375569 end*/
        --added by Jixun for ER#20226110 begin
        GLOBAL_ATTRIBUTE_CATEGORY       VARCHAR2(30)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE1               VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE2               VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE3               VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE4               VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE5               VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE6               VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE7               VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE8               VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE9               VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE10              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE11              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE12              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE13              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE14              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE15              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE16              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE17              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE18              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE19              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE20              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE21              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE22              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE23              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE24              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE25              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE26              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE27              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE28              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE29              VARCHAR2(150)    DEFAULT NULL,
        GLOBAL_ATTRIBUTE30              VARCHAR2(150)    DEFAULT NULL
        --added by Jixun for ER#20226110 end
   );


--ER 7417553
TYPE misc_dist_tbl_type IS TABLE OF misc_dist_rec_type
     INDEX BY BINARY_INTEGER;


/*#
 Use this procedure to create a single cash receipt for
* payment received in the form of a check or cash.
* manually created cash receipts.
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Create Cash Receipt
*/

PROCEDURE Create_cash(
           -- Standard API parameters.
                 p_api_version      IN  NUMBER,
                 p_init_msg_list    IN  VARCHAR2 := FND_API.G_FALSE,
                 p_commit           IN  VARCHAR2 := FND_API.G_FALSE,
                 p_validation_level IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
                 x_return_status    OUT NOCOPY VARCHAR2,
                 x_msg_count        OUT NOCOPY NUMBER,
                 x_msg_data         OUT NOCOPY VARCHAR2,
                 -- Receipt info. parameters
                 p_usr_currency_code       IN  VARCHAR2 DEFAULT NULL, --the translated currency code
                 p_currency_code           IN  VARCHAR2 DEFAULT NULL,
                 p_usr_exchange_rate_type  IN  VARCHAR2 DEFAULT NULL,
                 p_exchange_rate_type      IN  VARCHAR2 DEFAULT NULL,
                 p_exchange_rate           IN  NUMBER   DEFAULT NULL,
                 p_exchange_rate_date      IN  DATE     DEFAULT NULL,
                 p_amount                  IN  NUMBER   DEFAULT NULL,
                 p_factor_discount_amount  IN  NUMBER   DEFAULT NULL,
                 p_receipt_number          IN  VARCHAR2 DEFAULT NULL,
                 p_receipt_date            IN  DATE     DEFAULT NULL,
                 p_gl_date                 IN  DATE     DEFAULT NULL,
                 p_maturity_date           IN  DATE     DEFAULT NULL,
                 p_postmark_date           IN  DATE     DEFAULT NULL,
                 p_customer_id             IN  NUMBER   DEFAULT NULL,
                 p_customer_name           IN  VARCHAR2 DEFAULT NULL,
                 p_customer_number         IN  VARCHAR2  DEFAULT NULL,
                 p_customer_bank_account_id IN NUMBER   DEFAULT NULL,
                 p_customer_bank_account_num   IN  VARCHAR2  DEFAULT NULL,
                 p_customer_bank_account_name  IN  VARCHAR2  DEFAULT NULL,
                 p_payment_trxn_extension_id  IN  NUMBER  DEFAULT NULL, --payment uptake changes bichatte
                 p_location                 IN  VARCHAR2 DEFAULT NULL,
                 p_customer_site_use_id     IN  NUMBER  DEFAULT NULL,
                 p_default_site_use        IN  VARCHAR2 DEFAULT  'Y', --bug4448307-4509459
                 p_customer_receipt_reference IN  VARCHAR2  DEFAULT NULL,
                 p_override_remit_account_flag IN  VARCHAR2 DEFAULT NULL,
                 p_remittance_bank_account_id  IN  NUMBER  DEFAULT NULL,
                 p_remittance_bank_account_num  IN VARCHAR2 DEFAULT NULL,
                 p_remittance_bank_account_name IN VARCHAR2 DEFAULT NULL,
                 p_deposit_date             IN  DATE     DEFAULT NULL,
                 p_receipt_method_id        IN  NUMBER   DEFAULT NULL,
                 p_receipt_method_name      IN  VARCHAR2 DEFAULT NULL,
                 p_doc_sequence_value       IN  NUMBER   DEFAULT NULL,
                 p_ussgl_transaction_code   IN  VARCHAR2 DEFAULT NULL,
                 p_anticipated_clearing_date IN DATE     DEFAULT NULL,
                 p_called_from               IN VARCHAR2 DEFAULT NULL,
                 p_attribute_rec         IN  attribute_rec_type DEFAULT attribute_rec_const,
       -- ******* Global Flexfield parameters *******
                 p_global_attribute_rec  IN global_attribute_rec_type DEFAULT global_attribute_rec_const,
                 p_comments             IN VARCHAR2 DEFAULT NULL,
      --   ***  Notes Receivable Additional Information  ***
                 p_issuer_name                  IN VARCHAR2  DEFAULT NULL,
                 p_issue_date                   IN DATE   DEFAULT NULL,
                 p_issuer_bank_branch_id        IN NUMBER  DEFAULT NULL,
                 p_org_id                       IN NUMBER  DEFAULT NULL,
                 p_installment                  IN NUMBER  DEFAULT NULL,
      --   ** OUT NOCOPY variables
                 p_cr_id		  OUT NOCOPY NUMBER
                  );

/*#
* Use this procedure to apply the cash receipts from  a customer
* to an invoice, debit memo, or other debit item.
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Apply Receipt
*/

PROCEDURE Apply(
-- Standard API parameters.
      p_api_version      IN  NUMBER,
      p_init_msg_list    IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit           IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status    OUT NOCOPY VARCHAR2,
      x_msg_count        OUT NOCOPY NUMBER,
      x_msg_data         OUT NOCOPY VARCHAR2,
 --  Receipt application parameters.
      p_cash_receipt_id         IN ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
      p_receipt_number          IN ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      p_customer_trx_id         IN ra_customer_trx.customer_trx_id%TYPE DEFAULT NULL,
      p_trx_number              IN ra_customer_trx.trx_number%TYPE DEFAULT NULL,
      p_installment             IN ar_payment_schedules.terms_sequence_number%TYPE DEFAULT NULL,
      p_applied_payment_schedule_id     IN ar_payment_schedules.payment_schedule_id%TYPE DEFAULT NULL,
      p_amount_applied          IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      -- this is the allocated receipt amount
      p_amount_applied_from     IN ar_receivable_applications.amount_applied_from%TYPE DEFAULT NULL,
      p_trans_to_receipt_rate   IN ar_receivable_applications.trans_to_receipt_rate%TYPE DEFAULT NULL,
      p_discount                IN ar_receivable_applications.earned_discount_taken%TYPE DEFAULT NULL,
      p_apply_date              IN ar_receivable_applications.apply_date%TYPE DEFAULT NULL,
      p_apply_gl_date                 IN ar_receivable_applications.gl_date%TYPE DEFAULT NULL,
      p_ussgl_transaction_code  IN ar_receivable_applications.ussgl_transaction_code%TYPE DEFAULT NULL,
      p_customer_trx_line_id	  IN ar_receivable_applications.applied_customer_trx_line_id%TYPE DEFAULT NULL,
      p_line_number             IN ra_customer_trx_lines.line_number%TYPE DEFAULT NULL,
      p_show_closed_invoices    IN VARCHAR2 DEFAULT 'N', /* Bug fix 2462013 */
      p_called_from             IN VARCHAR2 DEFAULT NULL,
      p_move_deferred_tax       IN VARCHAR2 DEFAULT 'Y',
      p_link_to_trx_hist_id     IN ar_receivable_applications.link_to_trx_hist_id%TYPE DEFAULT NULL,
      p_attribute_rec      IN attribute_rec_type DEFAULT attribute_rec_const,
	 -- ******* Global Flexfield parameters *******
      p_global_attribute_rec IN global_attribute_rec_type DEFAULT global_attribute_rec_const,
      p_comments                IN ar_receivable_applications.comments%TYPE DEFAULT NULL,
      p_payment_set_id          IN ar_receivable_applications.payment_set_id%TYPE DEFAULT NULL,
      p_application_ref_type         IN ar_receivable_applications.application_ref_type%TYPE DEFAULT NULL,
      p_application_ref_id           IN ar_receivable_applications.application_ref_id%TYPE DEFAULT NULL,
      p_application_ref_num          IN ar_receivable_applications.application_ref_num%TYPE DEFAULT NULL,
      p_secondary_application_ref_id IN ar_receivable_applications.secondary_application_ref_id%TYPE DEFAULT NULL,
      p_application_ref_reason       IN ar_receivable_applications.application_ref_reason%TYPE DEFAULT NULL,
      p_customer_reference           IN ar_receivable_applications.customer_reference%TYPE DEFAULT NULL,
      p_customer_reason              IN ar_receivable_applications.customer_reason%TYPE DEFAULT NULL,
      p_org_id                       IN NUMBER  DEFAULT NULL,
      p_disable_balance_check        IN VARCHAR2 DEFAULT 'N'
	  );

-- LLCA
PROCEDURE Apply_In_Detail(
-- Standard API parameters.
      p_api_version                  IN  NUMBER,
      p_init_msg_list                IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit                       IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level             IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status                OUT NOCOPY VARCHAR2,
      x_msg_count                    OUT NOCOPY NUMBER,
      x_msg_data                     OUT NOCOPY VARCHAR2,
 --  Receipt application parameters.
      p_cash_receipt_id              IN ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
      p_receipt_number               IN ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      p_customer_trx_id              IN ra_customer_trx.customer_trx_id%TYPE DEFAULT NULL,
      p_trx_number                   IN ra_customer_trx.trx_number%TYPE DEFAULT NULL,
      p_installment                  IN ar_payment_schedules.terms_sequence_number%TYPE DEFAULT NULL,
      p_applied_payment_schedule_id  IN ar_payment_schedules.payment_schedule_id%TYPE DEFAULT NULL,
-- LLCA Parameters
      p_llca_type		     IN VARCHAR2 DEFAULT 'S',
      p_llca_trx_lines_tbl           IN llca_trx_lines_tbl_type DEFAULT llca_def_trx_lines_tbl_type,
      p_group_id         	     IN VARCHAR2 DEFAULT NULL,   /* Bug 5284890 */
      p_line_amount		     IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      p_tax_amount		     IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      p_freight_amount		     IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      p_charges_amount		     IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      p_amount_applied               IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      p_line_discount                IN NUMBER DEFAULT NULL,
      p_tax_discount                 IN NUMBER DEFAULT NULL,
      p_freight_discount             IN NUMBER DEFAULT NULL,
      -- this is the allocated receipt amount
      p_amount_applied_from          IN ar_receivable_applications.amount_applied_from%TYPE DEFAULT NULL,
      p_trans_to_receipt_rate        IN ar_receivable_applications.trans_to_receipt_rate%TYPE DEFAULT NULL,
      p_discount                     IN ar_receivable_applications.earned_discount_taken%TYPE DEFAULT NULL,
      p_apply_date                   IN ar_receivable_applications.apply_date%TYPE DEFAULT NULL,
      p_apply_gl_date                IN ar_receivable_applications.gl_date%TYPE DEFAULT NULL,
      p_ussgl_transaction_code       IN ar_receivable_applications.ussgl_transaction_code%TYPE DEFAULT NULL,
      p_show_closed_invoices         IN VARCHAR2 DEFAULT 'N', /* Bug fix 2462013 */
      p_called_from                  IN VARCHAR2 DEFAULT NULL,
      p_move_deferred_tax            IN VARCHAR2 DEFAULT 'Y',
      p_link_to_trx_hist_id          IN ar_receivable_applications.link_to_trx_hist_id%TYPE DEFAULT NULL,
      p_attribute_rec                IN attribute_rec_type DEFAULT attribute_rec_const,
	 -- ******* Global Flexfield parameters *******
      p_global_attribute_rec         IN global_attribute_rec_type DEFAULT global_attribute_rec_const,
      p_comments                     IN ar_receivable_applications.comments%TYPE DEFAULT NULL,
      p_payment_set_id               IN ar_receivable_applications.payment_set_id%TYPE DEFAULT NULL,
      p_application_ref_type         IN ar_receivable_applications.application_ref_type%TYPE DEFAULT NULL,
      p_application_ref_id           IN ar_receivable_applications.application_ref_id%TYPE DEFAULT NULL,
      p_application_ref_num          IN ar_receivable_applications.application_ref_num%TYPE DEFAULT NULL,
      p_secondary_application_ref_id IN ar_receivable_applications.secondary_application_ref_id%TYPE DEFAULT NULL,
      p_application_ref_reason       IN ar_receivable_applications.application_ref_reason%TYPE DEFAULT NULL,
      p_customer_reference           IN ar_receivable_applications.customer_reference%TYPE DEFAULT NULL,
      p_customer_reason              IN ar_receivable_applications.customer_reason%TYPE DEFAULT NULL,
      p_org_id                       IN NUMBER  DEFAULT NULL,
      p_line_attribute_rec           IN attribute_rec_type DEFAULT attribute_rec_const
      );

 /*#
 * Use this procedure to unapply a cash receipt application against
 * a specified installment of a debit item or payment schedule ID.
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Unapply Receipt
 */

PROCEDURE Unapply(
      -- Standard API parameters.
      p_api_version      IN  NUMBER,
      p_init_msg_list    IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit           IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status    OUT NOCOPY VARCHAR2 ,
      x_msg_count        OUT NOCOPY NUMBER ,
      x_msg_data         OUT NOCOPY VARCHAR2 ,
   -- *** Receipt Info. parameters *****
      p_receipt_number   IN  ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      p_cash_receipt_id  IN  ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
      p_trx_number       IN  ra_customer_trx.trx_number%TYPE DEFAULT NULL,
      p_customer_trx_id  IN  ra_customer_trx.customer_trx_id%TYPE DEFAULT NULL,
      p_installment      IN  ar_payment_schedules.terms_sequence_number%TYPE DEFAULT NULL,
      p_applied_payment_schedule_id IN ar_payment_schedules.payment_schedule_id%TYPE DEFAULT NULL,
      p_receivable_application_id   IN ar_receivable_applications.receivable_application_id%TYPE DEFAULT NULL,
      p_reversal_gl_date IN ar_receivable_applications.reversal_gl_date%TYPE DEFAULT NULL,
      p_called_from      IN VARCHAR2 DEFAULT NULL,
      p_cancel_claim_flag  IN VARCHAR2 DEFAULT 'Y',
      p_org_id             IN NUMBER  DEFAULT NULL
      );

 /*#
 * Use this procedure  to create a cash receipt and apply it
 * to a specified installment of a debit item.
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Create and Apply Receipt
 */


    PROCEDURE Create_and_apply(
-- Standard API parameters.
      p_api_version      IN  NUMBER,
      p_init_msg_list    IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit           IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status    OUT NOCOPY VARCHAR2,
      x_msg_count        OUT NOCOPY NUMBER,
      x_msg_data         OUT NOCOPY VARCHAR2,
 -- Receipt info. parameters
      p_usr_currency_code       IN  VARCHAR2 DEFAULT NULL, --the translated currency code
      p_currency_code      IN  ar_cash_receipts.currency_code%TYPE DEFAULT NULL,
      p_usr_exchange_rate_type  IN  VARCHAR2 DEFAULT NULL,
      p_exchange_rate_type IN  ar_cash_receipts.exchange_rate_type%TYPE DEFAULT NULL,
      p_exchange_rate      IN  ar_cash_receipts.exchange_rate%TYPE DEFAULT NULL,
      p_exchange_rate_date IN  ar_cash_receipts.exchange_date%TYPE DEFAULT NULL,
      p_amount                           IN  ar_cash_receipts.amount%TYPE DEFAULT NULL,
      p_factor_discount_amount           IN ar_cash_receipts.factor_discount_amount%TYPE DEFAULT NULL,
      p_receipt_number                   IN  ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      p_receipt_date                     IN  ar_cash_receipts.receipt_date%TYPE DEFAULT NULL,
      p_gl_date                          IN  ar_cash_receipt_history.gl_date%TYPE DEFAULT NULL,
      p_maturity_date                    IN  DATE DEFAULT NULL,
      p_postmark_date                    IN  DATE DEFAULT NULL,
      p_customer_id                      IN  ar_cash_receipts.pay_from_customer%TYPE DEFAULT NULL,
      p_customer_name                    IN  hz_parties.party_name%TYPE DEFAULT NULL,
      p_customer_number                  IN  hz_cust_accounts.account_number%TYPE DEFAULT NULL,
      p_customer_bank_account_id         IN  ar_cash_receipts.customer_bank_account_id%TYPE DEFAULT NULL,
      /* 6612301 */
      p_customer_bank_account_num        IN  iby_ext_bank_accounts_v.bank_account_number%TYPE DEFAULT NULL,
      p_customer_bank_account_name       IN  iby_ext_bank_accounts_v.bank_account_name%TYPE DEFAULT NULL,
      p_payment_trxn_extension_id        IN  NUMBER  DEFAULT NULL, --payment uptake changes bichatte
      p_location                         IN  hz_cust_site_uses.location%TYPE DEFAULT NULL,
      p_customer_site_use_id             IN  hz_cust_site_uses.site_use_id%TYPE DEFAULT NULL,
      p_default_site_use                 IN  VARCHAR2 DEFAULT  'Y', --The default site use bug4448307-4509459.
      p_customer_receipt_reference       IN  ar_cash_receipts.customer_receipt_reference%TYPE DEFAULT NULL,
      p_override_remit_account_flag      IN  ar_cash_receipts.override_remit_account_flag%TYPE DEFAULT NULL,
      p_remittance_bank_account_id       IN  ar_cash_receipts.remit_bank_acct_use_id%TYPE DEFAULT NULL,
      p_remittance_bank_account_num      IN  ce_bank_accounts.bank_account_num%TYPE DEFAULT NULL,
      p_remittance_bank_account_name     IN  ce_bank_accounts.bank_account_name%TYPE DEFAULT NULL,
      p_deposit_date                     IN  ar_cash_receipts.deposit_date%TYPE DEFAULT NULL,
      p_receipt_method_id                IN  ar_cash_receipts.receipt_method_id%TYPE DEFAULT NULL,
      p_receipt_method_name              IN  ar_receipt_methods.name%TYPE DEFAULT NULL,
      p_doc_sequence_value               IN  NUMBER   DEFAULT NULL,
      p_ussgl_transaction_code           IN  ar_cash_receipts.ussgl_transaction_code%TYPE DEFAULT NULL,
      p_anticipated_clearing_date        IN  ar_cash_receipts.anticipated_clearing_date%TYPE DEFAULT NULL,
      p_called_from                      IN VARCHAR2 DEFAULT NULL,
      p_attribute_rec                    IN attribute_rec_type DEFAULT attribute_rec_const,
       -- ******* Global Flexfield parameters *******
      p_global_attribute_rec  IN global_attribute_rec_type DEFAULT global_attribute_rec_const,
      p_receipt_comments      IN VARCHAR2 DEFAULT NULL,
     --   ***  Notes Receivable Additional Information  ***
      p_issuer_name           IN ar_cash_receipts.issuer_name%TYPE DEFAULT NULL,
      p_issue_date            IN ar_cash_receipts.issue_date%TYPE DEFAULT NULL,
      p_issuer_bank_branch_id IN ar_cash_receipts.issuer_bank_branch_id%TYPE DEFAULT NULL,
  --  ** OUT NOCOPY variables for Creating receipt
      p_cr_id		      OUT NOCOPY ar_cash_receipts.cash_receipt_id%TYPE,
   -- Receipt application parameters
      p_customer_trx_id         IN ra_customer_trx.customer_trx_id%TYPE DEFAULT NULL,
      p_trx_number              IN ra_customer_trx.trx_number%TYPE DEFAULT NULL,
      p_installment             IN ar_payment_schedules.terms_sequence_number%TYPE DEFAULT NULL,
      p_applied_payment_schedule_id     IN ar_payment_schedules.payment_schedule_id%TYPE DEFAULT NULL,
      p_amount_applied          IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      -- this is the allocated receipt amount
      p_amount_applied_from     IN ar_receivable_applications.amount_applied_from%TYPE DEFAULT NULL,
      p_trans_to_receipt_rate   IN ar_receivable_applications.trans_to_receipt_rate%TYPE DEFAULT NULL,
      p_discount                IN ar_receivable_applications.earned_discount_taken%TYPE DEFAULT NULL,
      p_apply_date              IN ar_receivable_applications.apply_date%TYPE DEFAULT NULL,
      p_apply_gl_date           IN ar_receivable_applications.gl_date%TYPE DEFAULT NULL,
      app_ussgl_transaction_code  IN ar_receivable_applications.ussgl_transaction_code%TYPE DEFAULT NULL,
      p_customer_trx_line_id	  IN ar_receivable_applications.applied_customer_trx_line_id%TYPE DEFAULT NULL,
      p_line_number             IN ra_customer_trx_lines.line_number%TYPE DEFAULT NULL,
      p_show_closed_invoices    IN VARCHAR2 DEFAULT 'N', /* Bug fix 2462013 */
      p_move_deferred_tax       IN VARCHAR2 DEFAULT 'Y',
      p_link_to_trx_hist_id     IN ar_receivable_applications.link_to_trx_hist_id%TYPE DEFAULT NULL,
      app_attribute_rec           IN attribute_rec_type DEFAULT attribute_rec_const,
  -- ******* Global Flexfield parameters *******
      app_global_attribute_rec    IN global_attribute_rec_type DEFAULT global_attribute_rec_const,
      app_comments                IN ar_receivable_applications.comments%TYPE DEFAULT NULL,
  -- OSTEINME 3/9/2001: added flag that indicates whether to call payment
  -- processor such as iPayments
      p_call_payment_processor    IN VARCHAR2 DEFAULT FND_API.G_FALSE,
      p_org_id             IN NUMBER  DEFAULT NULL
      -- OUT NOCOPY parameter for the Application
      );

 /*#
 * Use this procedure to reverse cash and miscellaneous receipts.
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Reverse Receipt
 */


PROCEDURE Reverse(
-- Standard API parameters.
      p_api_version             IN  NUMBER,
      p_init_msg_list           IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit                  IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level        IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status           OUT NOCOPY VARCHAR2,
      x_msg_count               OUT NOCOPY NUMBER,
      x_msg_data                OUT NOCOPY VARCHAR2,
-- Receipt reversal related parameters
      p_cash_receipt_id         IN ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
      p_receipt_number          IN ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      p_reversal_category_code  IN ar_cash_receipts.reversal_category%TYPE DEFAULT NULL,
      p_reversal_category_name  IN ar_lookups.meaning%TYPE DEFAULT NULL,
      p_reversal_gl_date        IN ar_cash_receipt_history.reversal_gl_date%TYPE DEFAULT NULL,
      p_reversal_date           IN ar_cash_receipts.reversal_date%TYPE DEFAULT NULL,
      p_reversal_reason_code    IN ar_cash_receipts.reversal_reason_code%TYPE DEFAULT NULL,
      p_reversal_reason_name    IN ar_lookups.meaning%TYPE DEFAULT NULL,
      p_reversal_comments       IN ar_cash_receipts.reversal_comments%TYPE DEFAULT NULL,
      p_called_from             IN VARCHAR2 DEFAULT NULL,
      p_attribute_rec           IN attribute_rec_type DEFAULT attribute_rec_const,
      --p_global_attribute_rec    IN global_attribute_rec_type_upd DEFAULT global_attribute_rec_upd_cons
      p_global_attribute_rec    IN global_attribute_rec_type DEFAULT global_attribute_rec_const  ,
      p_cancel_claims_flag      IN VARCHAR2 DEFAULT 'Y',
      p_org_id             IN NUMBER  DEFAULT NULL
       );

 /*#
 * Use this procedure  to apply a cash receipt on account.
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Apply On-Account Receipt
 */


PROCEDURE Apply_on_account(
-- Standard API parameters.
      p_api_version      IN  NUMBER,
      p_init_msg_list    IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit           IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status    OUT NOCOPY VARCHAR2,
      x_msg_count        OUT NOCOPY NUMBER,
      x_msg_data         OUT NOCOPY VARCHAR2,
  --  Receipt application parameters.
      p_cash_receipt_id         IN ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
      p_receipt_number          IN ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      p_amount_applied          IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      p_apply_date              IN ar_receivable_applications.apply_date%TYPE DEFAULT NULL,
      p_apply_gl_date                 IN ar_receivable_applications.gl_date%TYPE DEFAULT NULL,
      p_ussgl_transaction_code  IN ar_receivable_applications.ussgl_transaction_code%TYPE DEFAULT NULL,
      p_attribute_rec      IN attribute_rec_type DEFAULT attribute_rec_const,
	 -- ******* Global Flexfield parameters *******
      p_global_attribute_rec IN global_attribute_rec_type DEFAULT global_attribute_rec_const,
      p_comments                IN ar_receivable_applications.comments%TYPE DEFAULT NULL,
      p_application_ref_num IN ar_receivable_applications.application_ref_num%TYPE DEFAULT NULL,
      p_secondary_application_ref_id IN ar_receivable_applications.secondary_application_ref_id%TYPE DEFAULT NULL,
      p_customer_reference IN ar_receivable_applications.customer_reference%TYPE DEFAULT NULL,
      p_called_from IN VARCHAR2 DEFAULT NULL,
      p_customer_reason IN ar_receivable_applications.customer_reason%TYPE DEFAULT NULL,
      p_secondary_app_ref_type IN
                ar_receivable_applications.secondary_application_ref_type%TYPE := null,
      p_secondary_app_ref_num IN
                ar_receivable_applications.secondary_application_ref_num%TYPE := null,
      p_org_id             IN NUMBER  DEFAULT NULL
	  );

/*#
* Use this procedure to unapply an on-account application of
* a specified cash receipt.
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Unapply On-Account Receipt
*/


PROCEDURE Unapply_on_account(
    -- Standard API parameters.
      p_api_version               IN  NUMBER,
      p_init_msg_list             IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit                    IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level          IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status             OUT NOCOPY VARCHAR2 ,
      x_msg_count                 OUT NOCOPY NUMBER ,
      x_msg_data                  OUT NOCOPY VARCHAR2 ,
   -- *** Receipt Info. parameters *****
      p_receipt_number            IN  ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      p_cash_receipt_id           IN  ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
      p_receivable_application_id IN ar_receivable_applications.receivable_application_id%TYPE DEFAULT NULL,
      p_reversal_gl_date          IN ar_receivable_applications.reversal_gl_date%TYPE DEFAULT NULL,
      p_org_id             IN NUMBER  DEFAULT NULL
      );

/*#
* Use this procedure to create an activity application on a cash receipt,
* including Short Term  Debit (STD) and Receipt Write-off applications.
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Receipt Activity Application
*/


PROCEDURE Activity_application(
    -- Standard API parameters.
      p_api_version                  IN  NUMBER,
      p_init_msg_list                IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit                       IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level             IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status                OUT NOCOPY VARCHAR2,
      x_msg_count                    OUT NOCOPY NUMBER,
      x_msg_data                     OUT NOCOPY VARCHAR2,
    -- Receipt application parameters.
      p_cash_receipt_id              IN ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
      p_receipt_number               IN ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      p_amount_applied               IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      p_applied_payment_schedule_id  IN ar_payment_schedules.payment_schedule_id%TYPE, --this has no default
      p_link_to_customer_trx_id	     IN ra_customer_trx.customer_trx_id%TYPE DEFAULT NULL,
      p_receivables_trx_id           IN ar_receivable_applications.receivables_trx_id%TYPE, --this has no default
      p_apply_date                   IN ar_receivable_applications.apply_date%TYPE DEFAULT NULL,
      p_apply_gl_date                IN ar_receivable_applications.gl_date%TYPE DEFAULT NULL,
      p_ussgl_transaction_code       IN ar_receivable_applications.ussgl_transaction_code%TYPE DEFAULT NULL,
      p_attribute_rec                IN attribute_rec_type DEFAULT attribute_rec_const,
    -- ******* Global Flexfield parameters *******
      p_global_attribute_rec         IN global_attribute_rec_type DEFAULT global_attribute_rec_const,
      p_comments                     IN ar_receivable_applications.comments%TYPE DEFAULT NULL,
      p_application_ref_type IN OUT NOCOPY
                ar_receivable_applications.application_ref_type%TYPE,
      p_application_ref_id IN OUT NOCOPY
                ar_receivable_applications.application_ref_id%TYPE,
      p_application_ref_num IN OUT NOCOPY
                ar_receivable_applications.application_ref_num%TYPE,
      p_secondary_application_ref_id IN OUT NOCOPY
                ar_receivable_applications.secondary_application_ref_id%TYPE,
      p_payment_set_id IN ar_receivable_applications.payment_set_id%TYPE DEFAULT NULL,
      p_receivable_application_id OUT NOCOPY ar_receivable_applications.receivable_application_id%TYPE,
      p_customer_reference IN ar_receivable_applications.customer_reference%TYPE DEFAULT NULL,
      p_val_writeoff_limits_flag    IN VARCHAR2 DEFAULT 'Y',
      p_called_from		    IN VARCHAR2 DEFAULT NULL,
      p_netted_receipt_flag	    IN VARCHAR2 DEFAULT NULL,
      p_netted_cash_receipt_id IN ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
      p_secondary_app_ref_type IN
                ar_receivable_applications.secondary_application_ref_type%TYPE := null,
      p_secondary_app_ref_num IN
                ar_receivable_applications.secondary_application_ref_num%TYPE := null,
      p_org_id             IN NUMBER  DEFAULT NULL,
      p_customer_reason IN
                ar_receivable_applications.customer_reason%TYPE DEFAULT NULL
     ,p_pay_group_lookup_code	IN  FND_LOOKUPS.lookup_code%TYPE DEFAULT NULL
     ,p_pay_alone_flag		IN  VARCHAR2 DEFAULT NULL
     ,p_payment_method_code	IN  ap_invoices.payment_method_code%TYPE DEFAULT NULL
     ,p_payment_reason_code	IN  ap_invoices.payment_reason_code%TYPE DEFAULT NULL
     ,p_payment_reason_comments	IN  ap_invoices.payment_reason_comments%TYPE DEFAULT NULL
     ,p_delivery_channel_code	IN  ap_invoices.delivery_channel_code%TYPE DEFAULT NULL
     ,p_remittance_message1	IN  ap_invoices.remittance_message1%TYPE DEFAULT NULL
     ,p_remittance_message2	IN  ap_invoices.remittance_message2%TYPE DEFAULT NULL
     ,p_remittance_message3	IN  ap_invoices.remittance_message3%TYPE DEFAULT NULL
     ,p_party_id		IN  hz_parties.party_id%TYPE DEFAULT NULL
     ,p_party_site_id		IN  hz_party_sites.party_site_id%TYPE DEFAULT NULL
     ,p_bank_account_id		IN  ar_cash_receipts.customer_bank_account_id%TYPE DEFAULT NULL
     ,p_payment_priority	IN  ap_invoices_interface.PAYMENT_PRIORITY%TYPE DEFAULT NULL  --Bug8290172
     ,p_terms_id		IN  ap_invoices_interface.TERMS_ID%TYPE DEFAULT NULL          --Bug8290172
      );

/*#
* Use this procedure to create a reversal of an activity application
* on a cash receipt including Short Term Debt and Receipt write-off.
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Receipt Activity Unapplication
*/

PROCEDURE Activity_unapplication(
    -- Standard API parameters.
      p_api_version      IN  NUMBER,
      p_init_msg_list    IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit           IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status    OUT NOCOPY VARCHAR2 ,
      x_msg_count        OUT NOCOPY NUMBER ,
      x_msg_data         OUT NOCOPY VARCHAR2 ,
   -- *** Receipt Info. parameters *****
      p_receipt_number   IN  ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      p_cash_receipt_id  IN  ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
      p_receivable_application_id   IN ar_receivable_applications.receivable_application_id%TYPE DEFAULT NULL,
      p_reversal_gl_date IN ar_receivable_applications.reversal_gl_date%TYPE DEFAULT NULL,
      p_called_from      IN VARCHAR2,
      p_org_id             IN NUMBER  DEFAULT NULL
      );

/*#
* Use this procedure to apply a cash receipt to other account activities,
* such as creating a claim investigation application with a
* noninvoice-related deduction or overpayment in Trade Management (if installed).
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Account Application on a Cash Receipt
*/


PROCEDURE Apply_other_account(
-- Standard API parameters.
      p_api_version      IN  NUMBER,
      p_init_msg_list    IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit           IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status    OUT NOCOPY VARCHAR2,
      x_msg_count        OUT NOCOPY NUMBER,
      x_msg_data         OUT NOCOPY VARCHAR2,
      p_receivable_application_id OUT NOCOPY ar_receivable_applications.receivable_application_id%TYPE,
  --  Receipt application parameters.
      p_cash_receipt_id         IN ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
      p_receipt_number          IN ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      p_amount_applied          IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      p_receivables_trx_id      IN ar_receivable_applications.receivables_trx_id%TYPE DEFAULT NULL,
      p_applied_payment_schedule_id      IN ar_receivable_applications.applied_payment_schedule_id%TYPE DEFAULT NULL,
      p_apply_date              IN ar_receivable_applications.apply_date%TYPE DEFAULT NULL,
      p_apply_gl_date                 IN ar_receivable_applications.gl_date%TYPE DEFAULT NULL,
      p_ussgl_transaction_code  IN ar_receivable_applications.ussgl_transaction_code%TYPE DEFAULT NULL,
      p_application_ref_type IN ar_receivable_applications.application_ref_type%TYPE DEFAULT NULL,
      p_application_ref_id   IN OUT NOCOPY ar_receivable_applications.application_ref_id%TYPE ,
      p_application_ref_num  IN OUT NOCOPY ar_receivable_applications.application_ref_num%TYPE ,
      p_secondary_application_ref_id IN OUT NOCOPY ar_receivable_applications.secondary_application_ref_id%TYPE ,
      p_payment_set_id               IN ar_receivable_applications.payment_set_id%TYPE DEFAULT NULL,
      p_attribute_rec      IN attribute_rec_type DEFAULT attribute_rec_const,
         -- ******* Global Flexfield parameters *******
      p_global_attribute_rec IN global_attribute_rec_type DEFAULT global_attribute_rec_const,
      p_comments                IN ar_receivable_applications.comments%TYPE DEFAULT NULL,
      p_application_ref_reason  IN ar_receivable_applications.application_ref_reason%TYPE DEFAULT NULL,
      p_customer_reference      IN ar_receivable_applications.customer_reference%TYPE DEFAULT NULL,
      p_customer_reason         IN ar_receivable_applications.customer_reason%TYPE DEFAULT NULL,
      p_called_from		IN VARCHAR2 DEFAULT NULL,
      p_org_id             IN NUMBER  DEFAULT NULL
          );

/*#
* Use this procedure to reverse a cash receipt to other account activity.
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Reversal of an Account Application
*/


PROCEDURE Unapply_other_account(
    -- Standard API parameters.
      p_api_version               IN  NUMBER,
      p_init_msg_list             IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit                    IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level          IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status             OUT NOCOPY VARCHAR2 ,
      x_msg_count                 OUT NOCOPY NUMBER ,
      x_msg_data                  OUT NOCOPY VARCHAR2 ,
   -- *** Receipt Info. parameters *****
      p_receipt_number            IN  ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      p_cash_receipt_id           IN  ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
      p_receivable_application_id IN  ar_receivable_applications.receivable_application_id%TYPE,
      p_reversal_gl_date          IN ar_receivable_applications.reversal_gl_date%TYPE DEFAULT NULL,
      p_cancel_claim_flag         IN  VARCHAR2 DEFAULT 'Y',
      p_called_from		  IN  VARCHAR2 DEFAULT NULL,
      p_org_id             IN NUMBER  DEFAULT NULL
      );


/*#
* Use this procedure to create a miscellaneous receipt.
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Create Miscellaneous Receipt
*/


PROCEDURE create_misc(
    -- Standard API parameters.
      p_api_version                  IN  NUMBER,
      p_init_msg_list                IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit                       IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level             IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status                OUT NOCOPY VARCHAR2 ,
      x_msg_count                    OUT NOCOPY NUMBER ,
      x_msg_data                     OUT NOCOPY VARCHAR2 ,
    -- Misc Receipt info. parameters
      p_usr_currency_code            IN  VARCHAR2 DEFAULT NULL, --the translated currency code
      p_currency_code                IN  VARCHAR2 DEFAULT NULL,
      p_usr_exchange_rate_type       IN  VARCHAR2 DEFAULT NULL,
      p_exchange_rate_type           IN  VARCHAR2 DEFAULT NULL,
      p_exchange_rate                IN  NUMBER   DEFAULT NULL,
      p_exchange_rate_date           IN  DATE     DEFAULT NULL,
      p_amount                       IN  NUMBER,
      p_receipt_number               IN  OUT NOCOPY VARCHAR2,
      p_receipt_date                 IN  DATE     DEFAULT NULL,
      p_gl_date                      IN  DATE     DEFAULT NULL,
      p_receivables_trx_id           IN  NUMBER   DEFAULT NULL,
      p_activity                     IN  VARCHAR2 DEFAULT NULL,
      p_misc_payment_source          IN  VARCHAR2 DEFAULT NULL,
      p_tax_code                     IN  VARCHAR2 DEFAULT NULL,
      p_vat_tax_id                   IN  VARCHAR2 DEFAULT NULL,
      p_tax_rate                     IN  NUMBER   DEFAULT NULL,
      p_tax_amount                   IN  NUMBER   DEFAULT NULL,
      p_deposit_date                 IN  DATE     DEFAULT NULL,
      p_reference_type               IN  VARCHAR2 DEFAULT NULL,
      p_reference_num                IN  VARCHAR2 DEFAULT NULL,
      p_reference_id                 IN  NUMBER   DEFAULT NULL,
      p_remittance_bank_account_id   IN  NUMBER   DEFAULT NULL,
      p_remittance_bank_account_num  IN  VARCHAR2 DEFAULT NULL,
      p_remittance_bank_account_name IN  VARCHAR2 DEFAULT NULL,
      p_receipt_method_id            IN  NUMBER   DEFAULT NULL,
      p_receipt_method_name          IN  VARCHAR2 DEFAULT NULL,
      p_doc_sequence_value           IN  NUMBER   DEFAULT NULL,
      p_ussgl_transaction_code       IN  VARCHAR2 DEFAULT NULL,
      p_anticipated_clearing_date    IN  DATE     DEFAULT NULL,
      p_attribute_record             IN  attribute_rec_type DEFAULT attribute_rec_const,
      p_global_attribute_record      IN  global_attribute_rec_type DEFAULT global_attribute_rec_const,
      p_comments                     IN  VARCHAR2 DEFAULT NULL,
      p_org_id                       IN NUMBER  DEFAULT NULL,
      p_misc_receipt_id              OUT NOCOPY NUMBER,
      p_called_from                  IN VARCHAR2 DEFAULT NULL,
      p_payment_trxn_extension_id    In ar_cash_receipts.payment_trxn_extension_id%TYPE DEFAULT NULL, /* Bug fix 3619780*/
      p_misc_dist_tbl                IN AR_RECEIPT_API_PUB.misc_dist_tbl_type);   /*ER 7417553*/

/*ER 7417553*/
      PROCEDURE create_misc(
    -- Standard API parameters.
      p_api_version                  IN  NUMBER,
      p_init_msg_list                IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit                       IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level             IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status                OUT NOCOPY VARCHAR2 ,
      x_msg_count                    OUT NOCOPY NUMBER ,
      x_msg_data                     OUT NOCOPY VARCHAR2 ,
    -- Misc Receipt info. parameters
      p_usr_currency_code            IN  VARCHAR2 DEFAULT NULL, --the translated currency code
      p_currency_code                IN  VARCHAR2 DEFAULT NULL,
      p_usr_exchange_rate_type       IN  VARCHAR2 DEFAULT NULL,
      p_exchange_rate_type           IN  VARCHAR2 DEFAULT NULL,
      p_exchange_rate                IN  NUMBER   DEFAULT NULL,
      p_exchange_rate_date           IN  DATE     DEFAULT NULL,
      p_amount                       IN  NUMBER,
      p_receipt_number               IN  OUT NOCOPY VARCHAR2,
      p_receipt_date                 IN  DATE     DEFAULT NULL,
      p_gl_date                      IN  DATE     DEFAULT NULL,
      p_receivables_trx_id           IN  NUMBER   DEFAULT NULL,
      p_activity                     IN  VARCHAR2 DEFAULT NULL,
      p_misc_payment_source          IN  VARCHAR2 DEFAULT NULL,
      p_tax_code                     IN  VARCHAR2 DEFAULT NULL,
      p_vat_tax_id                   IN  VARCHAR2 DEFAULT NULL,
      p_tax_rate                     IN  NUMBER   DEFAULT NULL,
      p_tax_amount                   IN  NUMBER   DEFAULT NULL,
      p_deposit_date                 IN  DATE     DEFAULT NULL,
      p_reference_type               IN  VARCHAR2 DEFAULT NULL,
      p_reference_num                IN  VARCHAR2 DEFAULT NULL,
      p_reference_id                 IN  NUMBER   DEFAULT NULL,
      p_remittance_bank_account_id   IN  NUMBER   DEFAULT NULL,
      p_remittance_bank_account_num  IN  VARCHAR2 DEFAULT NULL,
      p_remittance_bank_account_name IN  VARCHAR2 DEFAULT NULL,
      p_receipt_method_id            IN  NUMBER   DEFAULT NULL,
      p_receipt_method_name          IN  VARCHAR2 DEFAULT NULL,
      p_doc_sequence_value           IN  NUMBER   DEFAULT NULL,
      p_ussgl_transaction_code       IN  VARCHAR2 DEFAULT NULL,
      p_anticipated_clearing_date    IN  DATE     DEFAULT NULL,
      p_attribute_record             IN  attribute_rec_type DEFAULT attribute_rec_const,
      p_global_attribute_record      IN  global_attribute_rec_type DEFAULT global_attribute_rec_const,
      p_comments                     IN  VARCHAR2 DEFAULT NULL,
      p_org_id                       IN NUMBER  DEFAULT NULL,
      p_misc_receipt_id              OUT NOCOPY NUMBER,
      p_called_from                  IN VARCHAR2 DEFAULT NULL,
      p_payment_trxn_extension_id    In ar_cash_receipts.payment_trxn_extension_id%TYPE DEFAULT NULL);   /*ER 7417553*/


Method_Cache_Tbl   Rec_Method_Tbl_Type ;
Customer_Cache_Tbl Rec_Customer_Tbl_Type;

PROCEDURE set_profile_for_testing(p_profile_doc_seq            VARCHAR2,
                                  p_profile_enable_cc          VARCHAR2,
                                  p_profile_appln_gl_date_def  VARCHAR2,
                                  p_profile_amt_applied_def    VARCHAR2,
                                  p_profile_cc_rate_type       VARCHAR2,
                                  p_profile_dsp_inv_rate       VARCHAR2,
                                  p_profile_create_bk_charges  VARCHAR2,
                                  p_profile_def_x_rate_type    VARCHAR2,
                                  p_pay_unrelated_inv_flag     VARCHAR2,
                                  p_unearned_discount          VARCHAR2);

/*#
* User this procedure to apply a cash receipt to another open receipt.
* Open receipts include unapplied cash, on-account cash, and claim investigation applications.
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Apply Receipt to Another Receipt
*/


PROCEDURE Apply_Open_Receipt(
-- Standard API parameters.
      p_api_version                  IN  NUMBER,
      p_init_msg_list                IN  VARCHAR2 DEFAULT FND_API.G_FALSE,
      p_commit                       IN  VARCHAR2 DEFAULT FND_API.G_FALSE,
      p_validation_level             IN  NUMBER   DEFAULT FND_API.G_VALID_LEVEL_FULL,
      x_return_status                OUT NOCOPY VARCHAR2,
      x_msg_count                    OUT NOCOPY NUMBER,
      x_msg_data                     OUT NOCOPY VARCHAR2,
 --  Receipt application parameters.
      p_cash_receipt_id              IN ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
      p_receipt_number               IN ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      p_applied_payment_schedule_id  IN ar_payment_schedules.payment_schedule_id%TYPE DEFAULT NULL,
      p_open_cash_receipt_id         IN ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
      p_open_receipt_number          IN ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      p_open_rec_app_id              IN ar_receivable_applications.receivable_application_id%TYPE DEFAULT NULL,
      p_amount_applied               IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      p_apply_date                   IN ar_receivable_applications.apply_date%TYPE DEFAULT NULL,
      p_apply_gl_date                IN ar_receivable_applications.gl_date%TYPE DEFAULT NULL,
      p_ussgl_transaction_code  IN ar_receivable_applications.ussgl_transaction_code%TYPE DEFAULT NULL,
      p_called_from                  IN VARCHAR2 DEFAULT NULL,
      p_attribute_rec                IN attribute_rec_type DEFAULT attribute_rec_const,
	 -- ******* Global Flexfield parameters *******
      p_global_attribute_rec         IN global_attribute_rec_type DEFAULT global_attribute_rec_const,
      p_comments                     IN ar_receivable_applications.comments%TYPE DEFAULT NULL,
      p_org_id             IN NUMBER  DEFAULT NULL,
      x_application_ref_num          OUT NOCOPY ar_receivable_applications.application_ref_num%TYPE,
      x_receivable_application_id    OUT NOCOPY ar_receivable_applications.receivable_application_id%TYPE,
      x_applied_rec_app_id           OUT NOCOPY ar_receivable_applications.receivable_application_id%TYPE,
      x_acctd_amount_applied_from    OUT NOCOPY ar_receivable_applications.acctd_amount_applied_from%TYPE,
      x_acctd_amount_applied_to      OUT NOCOPY ar_receivable_applications.acctd_amount_applied_to%TYPE
);

/*#
* Use this procedure to reverse a payment netting application on a  cash receipt.
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Reverse Application of a Receipt to Another Receipt
*/


PROCEDURE Unapply_Open_Receipt(
    -- Standard API parameters.
      p_api_version      IN  NUMBER,
      p_init_msg_list    IN  VARCHAR2 DEFAULT FND_API.G_FALSE,
      p_commit           IN  VARCHAR2 DEFAULT FND_API.G_FALSE,
      p_validation_level IN  NUMBER   DEFAULT FND_API.G_VALID_LEVEL_FULL,
      x_return_status    OUT NOCOPY VARCHAR2 ,
      x_msg_count        OUT NOCOPY NUMBER ,
      x_msg_data         OUT NOCOPY VARCHAR2 ,
      p_receivable_application_id   IN  ar_receivable_applications.receivable_application_id%TYPE,
      p_reversal_gl_date IN ar_receivable_applications.reversal_gl_date%TYPE DEFAULT NULL,
      p_called_from                  IN VARCHAR2 DEFAULT NULL,
      p_org_id             IN NUMBER  DEFAULT NULL);

/*=======================================================================
 | PUBLIC Procedure Create_Apply_On_Acc
 |
 | DESCRIPTION
 |      This API creates a receipt and applies it on the Account.
 |
 |      Parematers are the same as in create cash and Apply_on_Account
 |      except an extra parameter p_call_payment_processor has been added
 |      that should be passed as true for  iPayment to do the credit card
 |      processing.
 |
 |      For Creating receipts and applying to invoices please use
 |      Create_and Apply
 |      -------------------------------------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |
 |
 | RETURNS
 |      nothing
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date                  Author         Description of Changes
 | 16-FEB-2004           Jyoti Pandey      Created
 |                       This API has been created for Collections team
 |                       Bug 3398538. This replaces their call to
 |                       ar_receipt_api_pub.Create_cash which is not meant
 |                       for Credit card receipts
 |01-MAR-2004            Bug 3398538 and 3236769.
 |                       IMPORTANT:Renaming this API as
 |                       Create_Apply_On_Acc from create-cash_cc_internal
 |                       Create_cash_cc_internal is being obsoleted.
 |
 *=======================================================================*/

/*#
* Use this procedure to create and then apply a cash receipt to an on-account application.
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Create and Apply Cash Receipt to On-Account
*/



  PROCEDURE Create_Apply_On_Acc(
-- Standard API parameters.
      p_api_version      IN  NUMBER,
      p_init_msg_list    IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit           IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status    OUT NOCOPY VARCHAR2,
      x_msg_count        OUT NOCOPY NUMBER,
      x_msg_data         OUT NOCOPY VARCHAR2,
 -- Receipt info. parameters
      p_usr_currency_code  IN  VARCHAR2 DEFAULT NULL, --the translated currency code
      p_currency_code      IN  ar_cash_receipts.currency_code%TYPE DEFAULT NULL,
      p_usr_exchange_rate_type  IN  VARCHAR2 DEFAULT NULL,
      p_exchange_rate_type IN  ar_cash_receipts.exchange_rate_type%TYPE DEFAULT NULL,
      p_exchange_rate      IN  ar_cash_receipts.exchange_rate%TYPE DEFAULT NULL,
      p_exchange_rate_date IN  ar_cash_receipts.exchange_date%TYPE DEFAULT NULL,
      p_amount             IN  ar_cash_receipts.amount%TYPE DEFAULT NULL,
      p_factor_discount_amount IN ar_cash_receipts.factor_discount_amount%TYPE
                                  DEFAULT NULL,
      p_receipt_number    IN  ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      p_receipt_date      IN  ar_cash_receipts.receipt_date%TYPE DEFAULT NULL,
      p_gl_date           IN  ar_cash_receipt_history.gl_date%TYPE DEFAULT NULL,
      p_maturity_date     IN  DATE DEFAULT NULL,
      p_postmark_date     IN  DATE DEFAULT NULL,
      p_customer_id       IN  ar_cash_receipts.pay_from_customer%TYPE DEFAULT NULL,
      /* tca uptake */
      p_customer_name     IN  hz_parties.party_name%TYPE DEFAULT NULL,
      p_customer_number   IN  hz_cust_accounts.account_number%TYPE DEFAULT NULL,
      p_customer_bank_account_id    IN  ar_cash_receipts.customer_bank_account_id%TYPE
                                        DEFAULT NULL,
      /* 6612301 */
      p_customer_bank_account_num   IN  iby_ext_bank_accounts_v.bank_account_number%TYPE
                                        DEFAULT NULL,
      p_customer_bank_account_name  IN  iby_ext_bank_accounts_v.bank_account_name%TYPE
                                        DEFAULT NULL,
      p_payment_trxn_extension_id  IN  NUMBER  DEFAULT NULL, --payment uptake changes bichatte
      p_location                   IN  hz_cust_site_uses.location%TYPE DEFAULT NULL,
      p_customer_site_use_id       IN  hz_cust_site_uses.site_use_id%TYPE DEFAULT NULL,
      p_default_site_use           IN VARCHAR2 DEFAULT 'Y', --bug 4448307-4509459
      p_customer_receipt_reference IN  ar_cash_receipts.customer_receipt_reference%TYPE
                                       DEFAULT NULL,
      p_override_remit_account_flag  IN  ar_cash_receipts.override_remit_account_flag%TYPE
                                        DEFAULT NULL,
      p_remittance_bank_account_id   IN  NUMBER  DEFAULT NULL,
      p_remittance_bank_account_num  IN VARCHAR2 DEFAULT NULL,
      p_remittance_bank_account_name IN VARCHAR2 DEFAULT NULL,
      p_deposit_date           IN  ar_cash_receipts.deposit_date%TYPE DEFAULT NULL,
      p_receipt_method_id      IN  ar_cash_receipts.receipt_method_id%TYPE DEFAULT NULL,
      p_receipt_method_name    IN  ar_receipt_methods.name%TYPE DEFAULT NULL,
      p_doc_sequence_value     IN  NUMBER   DEFAULT NULL,
      p_ussgl_transaction_code IN  ar_cash_receipts.ussgl_transaction_code%TYPE
                                   DEFAULT NULL,
      p_anticipated_clearing_date IN  ar_cash_receipts.anticipated_clearing_date%TYPE
                                      DEFAULT NULL,
      p_called_from    IN VARCHAR2 DEFAULT NULL,
      p_attribute_rec  IN attribute_rec_type DEFAULT attribute_rec_const,
       -- ******* Global Flexfield parameters *******
      p_global_attribute_rec  IN global_attribute_rec_type
                                 DEFAULT global_attribute_rec_const,
      p_receipt_comments      IN VARCHAR2 DEFAULT NULL,
     --   ***  Notes Receivable Additional Information  ***
      p_issuer_name           IN ar_cash_receipts.issuer_name%TYPE DEFAULT NULL,
      p_issue_date            IN ar_cash_receipts.issue_date%TYPE DEFAULT NULL,
      p_issuer_bank_branch_id IN ar_cash_receipts.issuer_bank_branch_id%TYPE DEFAULT NULL,
  --  ** OUT NOCOPY variables for Creating receipt
      p_cr_id                 OUT NOCOPY ar_cash_receipts.cash_receipt_id%TYPE,
   -- Receipt application parameters
      p_amount_applied   IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      p_apply_date       IN ar_receivable_applications.apply_date%TYPE DEFAULT NULL,
      p_apply_gl_date    IN ar_receivable_applications.gl_date%TYPE DEFAULT NULL,
      app_ussgl_transaction_code  IN ar_receivable_applications.ussgl_transaction_code%TYPE DEFAULT NULL,
      app_attribute_rec  IN attribute_rec_type DEFAULT attribute_rec_const,
  -- ******* Global Flexfield parameters *******
      app_global_attribute_rec IN global_attribute_rec_type
                                  DEFAULT global_attribute_rec_const,
      app_comments             IN ar_receivable_applications.comments%TYPE DEFAULT NULL,
      p_application_ref_num    IN ar_receivable_applications.application_ref_num%TYPE
                                  DEFAULT NULL,
      p_secondary_application_ref_id IN
                ar_receivable_applications.secondary_application_ref_id%TYPE DEFAULT NULL,
      p_customer_reference IN ar_receivable_applications.customer_reference%TYPE
                              DEFAULT NULL,
      p_customer_reason IN ar_receivable_applications.customer_reason%TYPE DEFAULT NULL,
      p_secondary_app_ref_type IN
                ar_receivable_applications.secondary_application_ref_type%TYPE := null,
      p_secondary_app_ref_num IN
                ar_receivable_applications.secondary_application_ref_num%TYPE := null,

      p_call_payment_processor    IN VARCHAR2 DEFAULT FND_API.G_FALSE,
      p_org_id                    IN NUMBER  DEFAULT NULL
      ) ;

PROCEDURE  Copy_payment_extension(
              p_payment_trxn_extension_id         IN NUMBER,
              p_customer_id                       IN NUMBER,
              p_receipt_method_id                 IN NUMBER,
              p_org_id                            IN NUMBER,
              p_customer_site_use_id              IN NUMBER,
              p_receipt_number                    IN VARCHAR2,
              x_msg_count           OUT NOCOPY NUMBER,
              x_msg_data            OUT NOCOPY VARCHAR2,
              x_return_status       OUT NOCOPY VARCHAR2,
              o_payment_trxn_extension_id   OUT NOCOPY NUMBER,
              p_called_from    IN VARCHAR2 DEFAULT NULL,
	      p_receipt_date   IN DATE DEFAULT NULL
                 );

PROCEDURE process_payment_1(
                p_cash_receipt_id     IN  NUMBER,
                p_called_from         IN  VARCHAR2,
                p_response_error_code OUT NOCOPY VARCHAR2,
                x_msg_count           OUT NOCOPY NUMBER,
                x_msg_data            OUT NOCOPY VARCHAR2,
                x_return_status       OUT NOCOPY VARCHAR2,
                p_payment_trxn_extension_id IN NUMBER DEFAULT NULL
                );
PROCEDURE  Create_payment_extension(
              p_payment_trxn_extension_id         IN NUMBER,
              p_customer_id                       IN NUMBER,
              p_receipt_method_id                 IN NUMBER,
              p_org_id                            IN NUMBER,
              p_customer_site_use_id              IN NUMBER,
              p_receipt_number                    IN VARCHAR2,
              p_cash_receipt_id                   IN NUMBER,
              x_msg_count           OUT NOCOPY NUMBER,
              x_msg_data            OUT NOCOPY VARCHAR2,
              x_return_status       OUT NOCOPY VARCHAR2,
              o_payment_trxn_extension_id   OUT NOCOPY NUMBER,
              p_receipt_date   IN DATE DEFAULT NULL
                 );

/*
 This procedure is for internal use only
 This procedure is to change status of the Receipt from remittance to confirm
 under certain conditions determined by offline remittance
 Parameters for this procedure
 IN:
 p_Cash_receipts_id    CR_ID_TABLE    (A table of cash receipts)
 p_called_from         VARCHAR2       (Internal Use)

*/

PROCEDURE Reverse_Remittances_in_err(
           -- Standard API parameters.
                 p_api_version      IN  NUMBER,
                 p_cash_receipts_id IN  CR_ID_TABLE,
                 p_called_from      IN  VARCHAR2 DEFAULT NULL,
		 p_commit           IN  VARCHAR2 := FND_API.G_FALSE,
                 x_return_status    OUT NOCOPY VARCHAR2,
                 x_msg_count        OUT NOCOPY NUMBER,
                 x_msg_data         OUT NOCOPY VARCHAR2
                 );


/*
This procedure is used to create receipts in BULK mode.
Before calling this procedure , ar_create_receipts_gt table has to be populated.
Also set the org_context before calling this procedure
*/

PROCEDURE Create_Cash_Bulk(
           -- Standard API parameters.
                 p_api_version       IN  NUMBER DEFAULT 1.0,
                 p_init_msg_list     IN  VARCHAR2 := FND_API.G_FALSE,
                 p_commit            IN  VARCHAR2 := FND_API.G_FALSE,
                 p_validation_level  IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
		 p_fetch_bulk_commit IN	 NUMBER DEFAULT 1000,
                 x_return_status     OUT NOCOPY VARCHAR2,
                 x_msg_count         OUT NOCOPY NUMBER,
                 x_msg_data          OUT NOCOPY VARCHAR2
                );


PROCEDURE process_events(p_gt_id       NUMBER,
		         p_request_id  NUMBER,
			 p_org_id      NUMBER) ;


/* This procedure is created for Claims to be able to change the customer and site,
*  which should be reflected back in the receipt applications */
/* Bug  5165826: Added following procedure for TM enhancement 4696620 */

PROCEDURE Change_customer(
 	 -- Standard API parameters.
 	       p_api_version                  IN  NUMBER,
 	       p_init_msg_list                IN  VARCHAR2 := FND_API.G_FALSE,
 	       p_commit                       IN  VARCHAR2 := FND_API.G_FALSE,
 	       p_validation_level             IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
 	       x_return_status                OUT NOCOPY VARCHAR2,
 	       x_msg_count                    OUT NOCOPY NUMBER,
 	       x_msg_data                     OUT NOCOPY VARCHAR2,
 	  --  Receipt application parameters.
 	       p_cash_receipt_id              IN ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
 	       p_receivable_application_id    IN ar_receivable_applications.receivable_application_id%TYPE DEFAULT NULL,
 	       p_customer_id                  IN ar_cash_receipts.pay_from_customer%TYPE,
 	       p_location                     IN ar_cash_receipts.customer_site_use_id%TYPE
 	       ) ;

/* Added for bug 21391824 - Begin */

TYPE unbalanced_receipt IS RECORD (
  	cash_receipt_id	NUMBER,
  	message_code    VARCHAR2(100));

TYPE unbalanced_receipts IS TABLE OF unbalanced_receipt
     	INDEX BY BINARY_INTEGER;

PROCEDURE check_recp_balance_bulk(
                  p_called_from IN VARCHAR2,
                  p_unbalanced_cr_tbl OUT NOCOPY unbalanced_receipts,
                  x_return_status    OUT NOCOPY VARCHAR2);

/* Added for bug 21391824 - End */


END AR_RECEIPT_API_PUB;
/
