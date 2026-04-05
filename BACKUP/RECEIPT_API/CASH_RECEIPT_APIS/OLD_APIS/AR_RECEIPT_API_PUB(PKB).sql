CREATE OR REPLACE PACKAGE BODY APPS.AR_RECEIPT_API_PUB AS
/* $Header: ARXPRECB.pls 120.142.12020000.39 2018/03/22 10:55:53 sunagesh ship $           */

PG_DEBUG varchar2(1) := NVL(FND_PROFILE.value('AFLOG_ENABLED'), 'N');
PG_BAL_CHECK_ENABLED varchar2(1) := NVL(FND_PROFILE.value('AR_ENABLE_JOURNAL_BAL_CHECK'),'Y');

/* =======================================================================
 | Global Data Types
 * ======================================================================*/

G_PKG_NAME     CONSTANT VARCHAR2(30) := 'AR_RECEIPT_API_PUB';

G_MSG_UERROR    CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR;
G_MSG_ERROR     CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_ERROR;
G_MSG_SUCCESS   CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_SUCCESS;
G_MSG_HIGH      CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_DEBUG_HIGH;
G_MSG_MEDIUM    CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_DEBUG_MEDIUM;
G_MSG_LOW       CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_DEBUG_LOW;

pg_update_claim_amount	 NUMBER; /* Bug 4170060 for rct to rct applications */

/*-----------------------------------------------------------------------+
 | Default bulk fetch size, and starting index                           |
 +-----------------------------------------------------------------------*/
MAX_ARRAY_SIZE          BINARY_INTEGER := 3000 ;
STARTING_INDEX          CONSTANT BINARY_INTEGER := 1;

--This routine initialize_profile_globals is used to set the profile option
--values in the corresponding package global variables. This kind of approach
--was adopted to enable the testing routine to assign different testcase values
--to the package global variables having the profile option values. So when we
--run the testing routine, the profile option package variables are overidden and
--the procedure initialize_profile_globals would not do any initialization in that
--case
PROCEDURE initialize_profile_globals IS
  BEGIN
   IF ar_receipt_lib_pvt.pg_profile_doc_seq = FND_API.G_MISS_CHAR THEN
      ar_receipt_lib_pvt.pg_profile_doc_seq
                       := fnd_profile.value('UNIQUE:SEQ_NUMBERS');
   END IF;
-- pofile option AR_ENABLE_CROSS_CURRENCY has been obsolited
-- it will now always be 'Y'
--   IF ar_receipt_lib_pvt.pg_profile_enable_cc = FND_API.G_MISS_CHAR THEN
      ar_receipt_lib_pvt.pg_profile_enable_cc:='Y';
--                      := fnd_profile.value('AR_ENABLE_CROSS_CURRENCY');
--   END IF;
   IF ar_receipt_lib_pvt.pg_profile_appln_gl_date_def = FND_API.G_MISS_CHAR  THEN
      ar_receipt_lib_pvt.pg_profile_appln_gl_date_def
                       := fnd_profile.value('AR_APPLICATION_GL_DATE_DEFAULT');
   END IF;
---Profile option: AR: Cash - default Amount Applied has been
-- obsoleted
   IF ar_receipt_lib_pvt.pg_profile_amt_applied_def = FND_API.G_MISS_CHAR  THEN
      ar_receipt_lib_pvt.pg_profile_amt_applied_def :='INV';
   END IF;
   IF ar_receipt_lib_pvt.pg_profile_cc_rate_type = FND_API.G_MISS_CHAR  THEN
      ar_receipt_lib_pvt.pg_profile_cc_rate_type
                     := ar_setup.value('AR_CROSS_CURRENCY_RATE_TYPE',null);
   -- null should be replaced with org_id, to find profile for diffrent org
   END IF;

   IF ar_receipt_lib_pvt.pg_profile_dsp_inv_rate = FND_API.G_MISS_CHAR  THEN
      ar_receipt_lib_pvt.pg_profile_dsp_inv_rate
                       := fnd_profile.value('DISPLAY_INVERSE_RATE');
   END IF;
   IF ar_receipt_lib_pvt.pg_profile_create_bk_charges = FND_API.G_MISS_CHAR  THEN
      ar_receipt_lib_pvt.pg_profile_create_bk_charges
                       := fnd_profile.value('AR_JG_CREATE_BANK_CHARGES');
   END IF;
   IF ar_receipt_lib_pvt.pg_profile_def_x_rate_type = FND_API.G_MISS_CHAR  THEN
      ar_receipt_lib_pvt.pg_profile_def_x_rate_type
                        := fnd_profile.value('AR_DEFAULT_EXCHANGE_RATE_TYPE');
   END IF;
   arp_util.debug('*******Profile Option Values************');
   arp_util.debug('pg_profile_appln_gl_date_def :'||ar_receipt_lib_pvt.pg_profile_appln_gl_date_def);
   arp_util.debug('pg_profile_amt_applied_def   :'||ar_receipt_lib_pvt.pg_profile_amt_applied_def);
   arp_util.debug('pg_profile_cc_rate_type      :'||ar_receipt_lib_pvt.pg_profile_cc_rate_type);
   arp_util.debug('pg_profile_doc_seq           :'||ar_receipt_lib_pvt.pg_profile_doc_seq);
   arp_util.debug('pg_profile_enable_cc         :'||ar_receipt_lib_pvt.pg_profile_enable_cc);
   arp_util.debug('pg_profile_dsp_inv_rate      :'||ar_receipt_lib_pvt.pg_profile_dsp_inv_rate);
   arp_util.debug('pg_profile_create_bk_charges :'||ar_receipt_lib_pvt.pg_profile_create_bk_charges);
   arp_util.debug('pg_profile_def_x_rate_type   :'||ar_receipt_lib_pvt.pg_profile_def_x_rate_type);

 END initialize_profile_globals;


PROCEDURE Create_cash_1(
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
                 p_customer_number         IN VARCHAR2  DEFAULT NULL,
                 p_customer_bank_account_id IN NUMBER   DEFAULT NULL,
                 p_customer_bank_account_num   IN  VARCHAR2  DEFAULT NULL,
                 p_customer_bank_account_name  IN  VARCHAR2  DEFAULT NULL,
                 p_payment_trxn_extension_id  IN  NUMBER  DEFAULT NULL, --payment uptake changes bichatte
                 p_location                 IN  VARCHAR2 DEFAULT NULL,
                 p_customer_site_use_id     IN  NUMBER  DEFAULT NULL,
                 p_default_site_use         IN VARCHAR2 DEFAULT 'Y', --The default site use bug 4448307-4509459
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
                 p_attribute_rec         IN  attribute_rec_type ,
       -- ******* Global Flexfield parameters *******
                 p_global_attribute_rec  IN global_attribute_rec_type,
                 p_comments             IN VARCHAR2 DEFAULT NULL,
      --   ***  Notes Receivable Additional Information  ***
                 p_issuer_name                  IN VARCHAR2  DEFAULT NULL,
                 p_issue_date                   IN DATE    DEFAULT NULL,
                 p_issuer_bank_branch_id        IN NUMBER  DEFAULT NULL,
      --added  parameters to differentiate between create_cash and create_and_apply
                 p_customer_trx_id              IN NUMBER  DEFAULT NULL,
                 p_trx_number                   IN VARCHAR2  DEFAULT NULL,
                 p_installment                  IN NUMBER  DEFAULT NULL,
                 p_applied_payment_schedule_id  IN NUMBER  DEFAULT NULL,
                 p_calling_api                  IN VARCHAR2 DEFAULT 'CREATE_CASH',
                 p_org_id                       IN NUMBER  DEFAULT NULL,
      --   ** OUT NOCOPY variables
                 p_cr_id		  OUT NOCOPY NUMBER
                  )
IS
l_api_name       CONSTANT VARCHAR2(20) := 'Create_cash';
l_api_version    CONSTANT NUMBER       := 1.0;

l_currency_code       ar_cash_receipts.currency_code%TYPE;
l_exchange_rate_type  ar_cash_receipts.exchange_rate_type%TYPE;
l_exchange_rate       ar_cash_receipts.exchange_rate%TYPE;
l_exchange_rate_date  ar_cash_receipts.exchange_date%TYPE;
l_amount              ar_cash_receipts.amount%TYPE;
l_factor_discount_amount ar_cash_receipts.factor_discount_amount%TYPE;
l_receipt_number      ar_cash_receipts.receipt_number%TYPE;
l_receipt_date        ar_cash_receipts.receipt_date%TYPE;
l_gl_date             ar_cash_receipt_history.gl_date%TYPE;
l_maturity_date       DATE;
l_customer_id         ar_cash_receipts.pay_from_customer%TYPE;
l_customer_name       hz_parties.party_name%TYPE;  /*tca uptake*/
l_customer_bank_account_id         ar_cash_receipts.customer_bank_account_id%TYPE;
/* 6612301 */
l_customer_bank_account_num        iby_ext_bank_accounts_v.bank_account_number%TYPE;
l_customer_bank_account_name       iby_ext_bank_accounts_v.bank_account_name%TYPE;
l_payment_trxn_extension_id        ar_cash_receipts.payment_trxn_extension_id%TYPE; /* bichatte payment uptake project */
l_customer_bank_branch_id          ar_cash_receipts.customer_bank_branch_id%TYPE;
l_location                         hz_cust_site_uses.location%TYPE;
l_customer_site_use_id             hz_cust_site_uses.site_use_id%TYPE;
l_customer_receipt_reference       ar_cash_receipts.customer_receipt_reference%TYPE;
l_override_remit_account_flag      ar_cash_receipts.override_remit_account_flag%TYPE;
l_remit_bank_acct_use_id          ar_cash_receipts.remit_bank_acct_use_id%TYPE;
l_remittance_bank_account_num      ce_bank_accounts.bank_account_num%TYPE;
l_deposit_date                     ar_cash_receipts.deposit_date%TYPE;
l_receipt_method_id                ar_cash_receipts.receipt_method_id%TYPE;
l_receipt_method_name              ar_receipt_methods.name%TYPE;
l_ussgl_transaction_code           ar_cash_receipts.ussgl_transaction_code%TYPE;
l_anticipated_clearing_date        ar_cash_receipts.anticipated_clearing_date%TYPE;
l_state                            VARCHAR2(30);
l_cr_id                            NUMBER;
l_ps_id                            NUMBER;
l_row_id                           VARCHAR2(30);
l_validation_status                VARCHAR2(2)    DEFAULT  FND_API.G_RET_STS_SUCCESS;
l_doc_seq_status                   VARCHAR2(10);
l_doc_sequence_id                  NUMBER;
l_doc_sequence_value               NUMBER;
l_postmark_date                    DATE;
l_cash_def_return_status           VARCHAR2(1);
l_val_return_status                VARCHAR2(1);
l_def_cash_id_return_status        VARCHAR2(1);
l_derive_cust_return_status        VARCHAR2(1);
l_dflex_val_return_status          VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS;
l_attribute_rec                    attribute_rec_type;
l_global_attribute_rec             global_attribute_rec_type;
l_gdflex_return_status             VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS;
l_creation_method_code             ar_receipt_classes.creation_method_code%TYPE;
l_creation_method                  VARCHAR2(1);
l_org_return_status                VARCHAR2(1);
l_org_id                           NUMBER;
l_legal_entity_id		   NUMBER; /* R12 LE uptake */
/* bichatte payment uptake */
l_copy_return_status VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
l_copy_msg_count           NUMBER;
l_copy_msg_data        VARCHAR2(2000);
l_copy_pmt_trxn_extension_id        ar_cash_receipts.payment_trxn_extension_id%TYPE; /* bichatte payment uptake project */
l_create_return_status VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
l_create_msg_count           NUMBER;
l_create_msg_data        VARCHAR2(2000);
l_create_pmt_trxn_extension_id        ar_cash_receipts.payment_trxn_extension_id%TYPE; /* bichatte payment uptake project */
l_default_site_use                 VARCHAR2(1);  --bug4448307-4509459
l_rec_creation_rule_code           ar_receipt_methods.receipt_creation_rule_code%TYPE;

BEGIN

 --assignment to local variables
l_currency_code               := p_currency_code;
l_exchange_rate_type          := p_exchange_rate_type;
l_exchange_rate               := p_exchange_rate;
l_exchange_rate_date          := trunc(p_exchange_rate_date);
l_amount                      := p_amount;
l_factor_discount_amount      := p_factor_discount_amount;
l_receipt_number              := p_receipt_number;
l_receipt_date                := trunc(p_receipt_date);
l_gl_date                     := trunc(p_gl_date);
l_maturity_date               := trunc(p_maturity_date);
l_customer_id                 := p_customer_id;
l_customer_name               := p_customer_name;
/* 6612301 */
l_customer_bank_account_id    := p_customer_bank_account_id;
l_customer_bank_account_num   := p_customer_bank_account_num;
l_customer_bank_account_name  := p_customer_bank_account_name;
l_payment_trxn_extension_id   := p_payment_trxn_extension_id; /* bichatte payment uptake project */
l_location                    := p_location;
l_customer_site_use_id        := p_customer_site_use_id;
l_customer_receipt_reference  := p_customer_receipt_reference;
l_override_remit_account_flag := p_override_remit_account_flag;
l_remit_bank_acct_use_id      := p_remittance_bank_account_id;
l_remittance_bank_account_num := p_remittance_bank_account_num;
l_deposit_date                := trunc(p_deposit_date);
l_receipt_method_id           := p_receipt_method_id;
l_receipt_method_name         := p_receipt_method_name;
l_ussgl_transaction_code      := p_ussgl_transaction_code;
l_anticipated_clearing_date   := trunc(p_anticipated_clearing_date);
l_postmark_date               := trunc(p_postmark_date);
l_doc_sequence_value          := p_doc_sequence_value;
l_attribute_rec               := p_attribute_rec;
l_global_attribute_rec        := p_global_attribute_rec;
l_org_id                      := p_org_id;
l_default_site_use            := p_default_site_use; --bug4448307-4509459

       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

      SAVEPOINT Create_cash_PVT;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*--------------------------------------------------------------+
        |   Initialize message list if p_init_msg_list is set to TRUE  |
        +--------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
          THEN
              FND_MSG_PUB.initialize;
        END IF;


        Original_create_cash_info.customer_id := p_customer_id;
        Original_create_cash_info.customer_name := p_customer_name;
        Original_create_cash_info.customer_number := p_customer_number; /*  Revert changes done for customer bank ref under payment uptake */
	/* 6612301 */
  Original_create_cash_info.customer_bank_account_id
                                           := p_customer_bank_account_id;
        Original_create_cash_info.customer_bank_account_num
                                             := p_customer_bank_account_num;
        Original_create_cash_info.customer_bank_account_name
                                            := p_customer_bank_account_name;
        Original_create_cash_info.remit_bank_acct_use_id
                                         := p_remittance_bank_account_id;
        Original_create_cash_info.remittance_bank_account_num
                                         := p_remittance_bank_account_num;
        Original_create_cash_info.remittance_bank_account_name
                                         := p_remittance_bank_account_name;
        Original_create_cash_info.receipt_method_id
                                         := p_receipt_method_id;
        Original_create_cash_info.receipt_method_name
                                         := p_receipt_method_name;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Create_cash_1: ' || 'Create_cash_receipt()+ ');
        END IF;
       /*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        x_return_status := FND_API.G_RET_STS_SUCCESS;
        l_doc_seq_status := FND_API.G_RET_STS_SUCCESS;

       /* SSA change */
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;
       ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);

       IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          x_return_status := FND_API.G_RET_STS_ERROR;
       ELSE

        /*-------------------------------------------------+
         | Initialize the profile option package variables |
         +-------------------------------------------------*/

           initialize_profile_globals;

       /*---------------------------------------------+
        |   ========== Start of API Body ==========   |
        +---------------------------------------------*/

        --If any value to id conversion fails then error status is returned
        -- bichatte removed customer bank variables payment uptake project (Reverted)
        -- we dont need to default the payment_trxn_extension_id

        ar_receipt_lib_pvt.Default_cash_ids(
                              p_usr_currency_code  ,
                              p_usr_exchange_rate_type,
                              p_customer_name,
                              p_customer_number,
                              p_location,
                              l_receipt_method_name,
                               /* 6612301 */
                              p_customer_bank_account_name,
                              p_customer_bank_account_num,
                              p_remittance_bank_account_name ,
                              p_remittance_bank_account_num ,
                              l_currency_code ,
                              l_exchange_rate_type ,
                              l_customer_id ,
                              l_customer_site_use_id,
                              l_receipt_method_id,
                               /* 6612301 */
                              l_customer_bank_account_id,
			                        l_customer_bank_branch_id,
                              l_remit_bank_acct_use_id ,
                              l_receipt_date, /* Bug fix 3135407 */
                              l_def_cash_id_return_status,
                              l_default_site_use --bug4448307-4509459
                              );

         IF p_calling_api  = 'CREATE_AND_APPLY'  THEN
          IF l_customer_id IS NULL AND
             l_def_cash_id_return_status = FND_API.G_RET_STS_SUCCESS AND
             l_currency_code IS NOT NULL
           THEN
           ar_receipt_lib_pvt.Derive_cust_info_from_trx(
                                       p_customer_trx_id,
                                       p_trx_number,
                                       p_installment,
                                       p_applied_payment_schedule_id,
                                       l_currency_code,
                                       l_customer_id,
                                       l_customer_site_use_id,
                                       l_derive_cust_return_status
                                            );
          END IF;
         END IF;
         IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug('Create_cash_1: ' || 'Default_cash_ids return status :'||l_derive_cust_return_status);
         END IF;
        ar_receipt_lib_pvt.Get_cash_defaults(
                     l_currency_code,
                     l_exchange_rate_type,
                     l_exchange_rate,
                     l_exchange_rate_date,
                     l_amount,
                     l_factor_discount_amount,
                     l_receipt_date,
                     l_gl_date,
                     l_maturity_date,
                     l_customer_receipt_reference,
                     l_override_remit_account_flag,
                     l_remit_bank_acct_use_id,
                     l_deposit_date,
                     l_receipt_method_id,
                     l_state,
                     l_anticipated_clearing_date,
                     p_called_from,
                     l_creation_method_code,
                     l_cash_def_return_status
                    );
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug('Create_cash_1: ' || 'Get_Cash_defaults return status :'||l_cash_def_return_status);
           END IF;

       /*------------------------------------------+
        |  Get legal_entity_id                     |
        +------------------------------------------*/  /* R12 LE uptake */
           l_legal_entity_id := ar_receipt_lib_pvt.get_legal_entity(l_remit_bank_acct_use_id);

       /*------------------------------------------+
        |  Validate the receipt information.       |
        |  Do not continue if there are errors.    |
        +------------------------------------------*/

        -- bichatte removed the custome bank variables since we dont need to
        -- validate them. payment uptake project. (Reverted)


        ar_receipt_val_pvt.Validate_Cash_Receipt(
                                            l_receipt_number,
                                            l_receipt_method_id,
                                            l_state,
                                            l_receipt_date,
                                            l_gl_date,
                                            l_maturity_date,
                                            l_deposit_date,
                                            l_amount,
                                            l_factor_discount_amount,
                                            l_customer_id,
                                            /* 6612301 */
                                            l_customer_bank_account_id,
                                            p_location,
                                            l_customer_site_use_id,
                                            l_remit_bank_acct_use_id,
                                            l_override_remit_account_flag,
                                            l_anticipated_clearing_date,
                                            l_currency_code,
                                            l_exchange_rate_type,
                                            l_exchange_rate,
                                            l_exchange_rate_date,
                                            l_doc_sequence_value,
                                            p_called_from,
                                            l_val_return_status
                                             );

         /* bug 3604739 / 3517523 : when receipt API is called from BR module, we bypass
            the validation for DFF */
         /* Bug 9214226 : Skip DFF validation for AR-AP Netting (receipt method id = -1) */
         IF p_called_from in ('BR_FACTORED_WITH_RECOURSE', 'BR_FACTORED_WITHOUT_RECOURSE',
	                      'AUTORECAPI','AUTORECAPI2') OR
			      l_receipt_method_id = -1  THEN
            NULL;
         ELSE
            --validate and default the flexfields
            ar_receipt_lib_pvt.Validate_Desc_Flexfield(
                                            l_attribute_rec,
                                            'AR_CASH_RECEIPTS',
                                            l_dflex_val_return_status
                                            );

            --validation and defaulting of the global descriptive flexfield
            JG_AR_CASH_RECEIPTS.Validate_gbl(
                                            l_global_attribute_rec.global_attribute_category,
                                            l_global_attribute_rec.global_attribute1,
                                            l_global_attribute_rec.global_attribute2,
                                            l_global_attribute_rec.global_attribute3,
                                            l_global_attribute_rec.global_attribute4,
                                            l_global_attribute_rec.global_attribute5,
                                            l_global_attribute_rec.global_attribute6,
                                            l_global_attribute_rec.global_attribute7,
                                            l_global_attribute_rec.global_attribute8,
                                            l_global_attribute_rec.global_attribute9,
                                            l_global_attribute_rec.global_attribute10,
                                            l_global_attribute_rec.global_attribute11,
                                            l_global_attribute_rec.global_attribute12,
                                            l_global_attribute_rec.global_attribute13,
                                            l_global_attribute_rec.global_attribute14,
                                            l_global_attribute_rec.global_attribute15,
                                            l_global_attribute_rec.global_attribute16,
                                            l_global_attribute_rec.global_attribute17,
                                            l_global_attribute_rec.global_attribute18,
                                            l_global_attribute_rec.global_attribute19,
                                            l_global_attribute_rec.global_attribute20,
                                            l_gdflex_return_status
                                            );
         END IF;

       END IF;

         IF l_cash_def_return_status <> FND_API.G_RET_STS_SUCCESS OR
            l_val_return_status <> FND_API.G_RET_STS_SUCCESS  OR
            l_def_cash_id_return_status <> FND_API.G_RET_STS_SUCCESS OR
            l_dflex_val_return_status <> FND_API.G_RET_STS_SUCCESS OR
            l_gdflex_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            x_return_status := FND_API.G_RET_STS_ERROR;
         END IF;

        --APANDIT : after the changes made for iReceivables credit card feature
        --the receipt api will also be creating the automatic receipts.
        --Bug 1817727

        /* 6612301 */
        IF NVL(l_creation_method_code, 'X') = 'MANUAL'
                THEN
                   l_creation_method := 'M';
                   l_payment_trxn_extension_id := NULL;
                ELSIF NVL(l_creation_method_code, 'X') = 'AUTOMATIC'
                THEN
                   l_creation_method := 'A';
                   l_customer_bank_account_id := NULL;
                ELSE
                   l_creation_method := 'M';
                   l_payment_trxn_extension_id := NULL;
        END IF;

        --Call the document sequence routine only there have been no errors
        --reported so far.
        IF x_return_status = FND_API.G_RET_STS_SUCCESS  THEN

           ar_receipt_lib_pvt.get_doc_seq(222,
                                          l_receipt_method_name,
                                          arp_global.set_of_books_id,
                                          l_creation_method,
                                          l_receipt_date,
                                          l_doc_sequence_value,
                                          l_doc_sequence_id,
                                          l_doc_seq_status
                                          );
        END IF;

      --If receipt number has not been passed in the document sequence value is
      --used as the receipt number.
        IF l_receipt_number IS NULL THEN
          IF l_doc_sequence_value IS NOT NULL THEN
            l_receipt_number := l_doc_sequence_value;
            --warning message
             IF FND_MSG_PUB.Check_Msg_Level(G_MSG_SUCCESS)
              THEN
                 FND_MESSAGE.SET_NAME('AR','AR_RAPI_RCPT_NUM_DFLT_DOC_SEQ');
                 FND_MSG_PUB.Add;
             END IF;
          ELSE
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Create_cash_1: ' || 'Receipt Number is null ');
            END IF;
            --raise error message
              FND_MESSAGE.SET_NAME('AR','AR_RAPI_RCPT_NUM_NULL');
              FND_MSG_PUB.Add;
              x_return_status := FND_API.G_RET_STS_ERROR;
          END IF;
        END IF;

   /* Bug 5364287 */
   arp_standard.debug ('x_return_status (' || x_return_status ||')');
   arp_standard.debug ('l_doc_seq_status (' || l_doc_seq_status ||')');
   IF (
              x_return_status         <> FND_API.G_RET_STS_SUCCESS
              OR l_doc_seq_status     <> FND_API.G_RET_STS_SUCCESS
      )
   THEN
              x_return_status := FND_API.G_RET_STS_ERROR ;
   ELSE

     -- HERE we have to call the payment engine in order to get the payment_trx_extension_id
     -- the conditions are if creation_method = 'A' and p_payment_trx_extension_id is null.
     -- bichatte payment_uptake project.

         arp_util.debug ('Create_cash -- CHECK' || p_installment );

     -- We have to check the receipt_creation_rule_code and
     -- accordingly call create or COPY



        select nvl(RECEIPT_CREATION_RULE_CODE,'MANUAL')
        into   l_rec_creation_rule_code
        from  AR_RECEIPT_METHODS
        where receipt_method_id = l_receipt_method_id;





      IF ( l_creation_method = 'A' and l_payment_trxn_extension_id is NULL) THEN

               arp_util.debug('Create_cash_122: ' || l_creation_method_code);
               arp_util.debug('Create_cash_122: ' || l_payment_trxn_extension_id );
              FND_MESSAGE.SET_NAME('AR','AR_CC_AUTH_FAILED');
              FND_MSG_PUB.Add;
              x_return_status := FND_API.G_RET_STS_ERROR;
      END IF;

   /*Bug 5614569
    Commented out the existing logic to call the create_payment_extension if the receipt creation
    rule code is anything other than 'PER_INVOICE'. For all the cases whenver we pass the Payment extesnion id
   for an Automatic Receipt Method  to create the receipt we need to call the copy_payment_extension */

   IF nvl(p_installment,1) = 1 THEN


      IF l_creation_method = 'A'  THEN
          arp_standard.debug('calling copy  Extension....');

           Copy_payment_extension (
              p_payment_trxn_extension_id => l_payment_trxn_extension_id,
              p_customer_id => l_customer_id,
              p_receipt_method_id =>l_receipt_method_id,
              p_org_id =>l_org_id,
              p_customer_site_use_id  =>l_customer_site_use_id,
              p_receipt_number=> l_receipt_number,
              x_msg_count => l_copy_msg_count,
              x_msg_data => l_copy_msg_data,
              x_return_status =>l_copy_return_status,
              o_payment_trxn_extension_id =>l_copy_pmt_trxn_extension_id,
	      p_called_from => p_called_from,
	      p_receipt_date => l_receipt_date
                 );

         IF l_copy_return_status <>  FND_API.G_RET_STS_SUCCESS THEN
               arp_util.debug('Create_cash_123: ' );
             FND_MESSAGE.set_name('AR', 'AR_CC_AUTH_FAILED');
             FND_MSG_PUB.Add;
              x_return_status := FND_API.G_RET_STS_ERROR;
         END IF;

            l_payment_trxn_extension_id := l_copy_pmt_trxn_extension_id;

 	  arp_standard.debug('calling copy  Extension  end ....');
  	 arp_standard.debug('calling copy  Extension  end ...2'|| to_char(l_copy_pmt_trxn_extension_id));
      END IF;

  ELSE
 arp_util.debug ('Create_cash -- CHECK2' || p_installment );
   IF l_creation_method = 'A'  THEN
   arp_standard.debug('calling CREATE  Extension....');
    Create_payment_extension (
       p_payment_trxn_extension_id => l_payment_trxn_extension_id,
       p_customer_id => l_customer_id,
       p_receipt_method_id =>l_receipt_method_id,
       p_org_id =>l_org_id,
       p_customer_site_use_id  =>l_customer_site_use_id,
       p_cash_receipt_id => l_cr_id,
       p_receipt_number=> l_receipt_number,
       x_msg_count => l_create_msg_count,
       x_msg_data => l_create_msg_data,
       x_return_status =>l_create_return_status,
       o_payment_trxn_extension_id =>l_create_pmt_trxn_extension_id,
       p_receipt_date => l_receipt_date
	 );

	 IF l_create_return_status <>  FND_API.G_RET_STS_SUCCESS THEN
              arp_util.debug('Create_cash_123: ' );
	      FND_MESSAGE.set_name('AR', 'AR_CC_AUTH_FAILED');
	      FND_MSG_PUB.Add;
	       x_return_status := FND_API.G_RET_STS_ERROR;
	 END IF;

	 l_payment_trxn_extension_id := l_create_pmt_trxn_extension_id;

	 arp_standard.debug('calling create  Extension  end ....');
	 arp_standard.debug('calling create  Extension end ...2'||
	 to_char(l_create_pmt_trxn_extension_id));


    END IF;


   END IF; -- p_installment check


 END IF;  /* Return Status */

       --Dump all the variables before calling the entity handler
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('Create_cash_1: ' || '*********DUMPING ALL THE VARIABLES ********');
         arp_util.debug('Create_cash_1: ' || 'l_currency_code = '||l_currency_code);
         arp_util.debug('Create_cash_1: ' || 'l_amount = '||to_char(l_amount));
         arp_util.debug('Create_cash_1: ' || 'l_customer_id = '||to_char(l_customer_id));
         arp_util.debug('Create_cash_1: ' || 'l_receipt_number = '||l_receipt_number);
         arp_util.debug('Create_cash_1: ' || 'l_receipt_date = '||to_char(l_receipt_date,'dd-mon-yy'));
         arp_util.debug('Create_cash_1: ' || 'l_gl_date = '||to_char(l_gl_date,'dd-mon-yy'));
         arp_util.debug('Create_cash_1: ' || 'l_maturity_date = '||to_char(l_maturity_date,'dd-mon-yyy'));
         arp_util.debug('Create_cash_1: ' || 'l_exchange_rate_type = '||l_exchange_rate_type);
         arp_util.debug('Create_cash_1: ' || 'l_exchange_rate = '||to_char(l_exchange_rate));
         arp_util.debug('Create_cash_1: ' || 'l_exchange_rate_date = '||to_char(l_exchange_rate_date,'dd-mon-yy'));
         arp_util.debug('Create_cash_1: ' || 'l_override_remit_account_flag = '||l_override_remit_account_flag);
         arp_util.debug('Create_cash_1: ' || 'l_remit_bank_acct_use_id = '||to_char(l_remit_bank_acct_use_id));
         arp_util.debug('Create_cash_1: ' || 'l_payment_trxn_extension_id = '||to_char(l_payment_trxn_extension_id));
         arp_util.debug('Create_cash_1: ' || 'l_customer_site_use_id = '||to_char(l_customer_site_use_id));
         arp_util.debug('Create_cash_1: ' || 'l_factor_discount_amount = '||to_char(l_factor_discount_amount));
         arp_util.debug('Create_cash_1: ' || 'l_deposit_date = '||to_char(l_deposit_date,'dd-mon-yy'));
         arp_util.debug('Create_cash_1: ' || 'l_receipt_method_id = '||to_char(l_receipt_method_id));
         arp_util.debug('Create_cash_1: ' || 'l_doc_sequence_value = '||to_char(l_doc_sequence_value));
         arp_util.debug('Create_cash_1: ' || 'l_legal_entity_id = '||to_char(l_legal_entity_id)); /* R12 LE uptake */
      END IF;
       /*------------------------------------------------------------+
        |  If any errors - including validation failures - occurred, |
        |  rollback any changes and return an error status.          |
        +------------------------------------------------------------*/
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('Create_cash_1: ' || 'x_return_status : '||x_return_status);
         arp_util.debug('Create_cash_1: ' || 'l_doc_seq_status : '||l_doc_seq_status);
      END IF;
	 IF (
              x_return_status         <> FND_API.G_RET_STS_SUCCESS
              OR l_doc_seq_status     <> FND_API.G_RET_STS_SUCCESS
             )
             THEN

              ROLLBACK TO Create_cash_PVT;

              x_return_status := FND_API.G_RET_STS_ERROR ;

              FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                        p_count => x_msg_count,
                                        p_data  => x_msg_data);

              IF PG_DEBUG in ('Y', 'C') THEN
                 arp_util.debug('Create_cash_1: ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
              END IF;
             Return;
        END IF;
          IF PG_DEBUG in ('Y', 'C') THEN
             arp_util.debug('Create_cash_1: ' || 'x_return_status '||x_return_status);
          END IF;
                 /* bichatte removed customer bank variables for the payment uptake project
                    added the l_payment_trxn_extension_id  */
      BEGIN
          arp_proc_receipts2.insert_cash_receipt(
  						l_currency_code,
						l_amount,
						l_customer_id,
						l_receipt_number,
						l_receipt_date,
						l_gl_date,
						l_maturity_date,
						p_comments,
						l_exchange_rate_type,
						l_exchange_rate,
						l_exchange_rate_date,
						NULL,  --batch_id
						l_attribute_rec.attribute_category,
						l_attribute_rec.attribute1,
						l_attribute_rec.attribute2,
						l_attribute_rec.attribute3,
						l_attribute_rec.attribute4,
						l_attribute_rec.attribute5,
						l_attribute_rec.attribute6,
						l_attribute_rec.attribute7,
						l_attribute_rec.attribute8,
						l_attribute_rec.attribute9,
						l_attribute_rec.attribute10,
						l_attribute_rec.attribute11,
						l_attribute_rec.attribute12,
						l_attribute_rec.attribute13,
						l_attribute_rec.attribute14,
						l_attribute_rec.attribute15,
						l_override_remit_account_flag,
						l_remit_bank_acct_use_id ,
                                                l_customer_bank_account_id ,
						l_customer_site_use_id,
						l_customer_receipt_reference ,
						l_factor_discount_amount ,
						l_deposit_date,
						l_receipt_method_id,
						l_doc_sequence_value,
						l_doc_sequence_id,
						l_ussgl_transaction_code ,
                                                NULL,   --Vat_tax_id
						l_anticipated_clearing_date ,
                                                l_customer_bank_branch_id,
                                                l_postmark_date,
						l_global_attribute_rec.global_attribute1,
						l_global_attribute_rec.global_attribute2,
						l_global_attribute_rec.global_attribute3,
						l_global_attribute_rec.global_attribute4,
						l_global_attribute_rec.global_attribute5,
						l_global_attribute_rec.global_attribute6,
						l_global_attribute_rec.global_attribute7,
						l_global_attribute_rec.global_attribute8,
						l_global_attribute_rec.global_attribute9,
						l_global_attribute_rec.global_attribute10,
						l_global_attribute_rec.global_attribute11,
						l_global_attribute_rec.global_attribute12,
						l_global_attribute_rec.global_attribute13,
						l_global_attribute_rec.global_attribute14,
						l_global_attribute_rec.global_attribute15,
						l_global_attribute_rec.global_attribute16,
						l_global_attribute_rec.global_attribute17,
						l_global_attribute_rec.global_attribute18,
						l_global_attribute_rec.global_attribute19,
						l_global_attribute_rec.global_attribute20,
						l_global_attribute_rec.global_attribute_category,
                                                p_issuer_name,
                                                trunc(p_issue_date), /* Bug fix 3135407 */
                                                p_issuer_bank_branch_id,
                                                null,  -- application_notes
						l_cr_id,
						l_ps_id,
						l_row_id,
						'RAPI',
						p_api_version
                                                ,p_called_from
						,l_legal_entity_id /* R12 LE updtake */
                                                ,l_payment_trxn_extension_id /* payment uptake */
				           );
         EXCEPTION
         WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN
                     ROLLBACK TO Create_Cash_PVT;

                      --  Display_Parameters;
                      x_return_status := FND_API.G_RET_STS_ERROR ;
                       FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                       FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','ARP_PROC_RECEIPTS2.INSERT_CASH_RECEIPT : '||SQLERRM);
                       FND_MSG_PUB.Add;

                       FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                                                  p_count  =>  x_msg_count,
                                                  p_data   => x_msg_data
                                                );
                      RETURN;
                ELSE
                   RAISE;
                END IF;

         END;

			p_cr_id := l_cr_id;
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Create_cash_1: ' || 'Cash Receipt id : '||to_char(l_cr_id));
            END IF;

       /*-------------------------------------------------------+
        | FND_MSG_PUB.Count_And_Get used  get the count of mesg.|
        | in the message stack. If there is only one message in |
        | the stack it retrieves this message                   |
        +-------------------------------------------------------*/

 	  FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                   p_count => x_msg_count,
                                   p_data  => x_msg_data
                                 );


       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Create_cash_1: ' || 'committing');
            END IF;
            Commit;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Create_cash_1: ' || 'Create_Cash_Receipt()- ');
        END IF;


EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Create_cash_1: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Create_cash_1: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Create_Cash_PVT;
                x_return_status := FND_API.G_RET_STS_ERROR ;

                --Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Create_cash_1: ' || SQLERRM, G_MSG_ERROR);
                END IF;
                ROLLBACK TO Create_Cash_PVT;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

               --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN
                     ROLLBACK TO Create_Cash_PVT;

                      --  Display_Parameters;
                      x_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','CREATE_CASH : '||SQLERRM);
                      FND_MSG_PUB.Add;

                      FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                                                 p_count  =>  x_msg_count,
                                                 p_data   => x_msg_data
                                                );
                      RETURN;
                ELSE
                      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','CREATE_CASH : '||SQLERRM);
                      FND_MSG_PUB.Add;
                END IF;

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Create_cash_1: ' || SQLCODE);
                   arp_util.debug('Create_cash_1: ' || SQLERRM);
                END IF;

                ROLLBACK TO Create_Cash_PVT;


                IF      FND_MSG_PUB.Check_Msg_Level
                THEN
                FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME,
                                        l_api_name
                                       );
                END IF;

             --   Display_Parameters;
                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

END Create_cash_1;

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
                 p_customer_number         IN VARCHAR2  DEFAULT NULL,
                 p_customer_bank_account_id IN NUMBER   DEFAULT NULL,
                 p_customer_bank_account_num   IN  VARCHAR2  DEFAULT NULL,
                 p_customer_bank_account_name  IN  VARCHAR2  DEFAULT NULL,
                 p_payment_trxn_extension_id  IN NUMBER DEFAULT NULL,
                 p_location                 IN  VARCHAR2 DEFAULT NULL,
                 p_customer_site_use_id     IN  NUMBER  DEFAULT NULL,
                 p_default_site_use         IN VARCHAR2  DEFAULT 'Y', --bug4448307-4509459
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
                 p_installment                  IN NUMBER DEFAULT NULL,
      --   ** OUT NOCOPY variables
                 p_cr_id		  OUT NOCOPY NUMBER
                  )
IS
l_api_name       CONSTANT VARCHAR2(20) := 'Create_cash';
l_api_version    CONSTANT NUMBER       := 1.0;

l_currency_code       ar_cash_receipts.currency_code%TYPE;
l_exchange_rate_type  ar_cash_receipts.exchange_rate_type%TYPE;
l_exchange_rate       ar_cash_receipts.exchange_rate%TYPE;
l_exchange_rate_date  ar_cash_receipts.exchange_date%TYPE;
l_amount              ar_cash_receipts.amount%TYPE;
l_factor_discount_amount ar_cash_receipts.factor_discount_amount%TYPE;
l_receipt_number      ar_cash_receipts.receipt_number%TYPE;
l_receipt_date        ar_cash_receipts.receipt_date%TYPE;
l_gl_date             ar_cash_receipt_history.gl_date%TYPE;
l_maturity_date       DATE;
l_customer_id         ar_cash_receipts.pay_from_customer%TYPE;
l_customer_name       hz_parties.party_name%TYPE; /* tca uptake */
l_payment_trxn_extension_id        ar_cash_receipts.payment_trxn_extension_id%TYPE;
l_location                         hz_cust_site_uses.location%TYPE;
l_customer_site_use_id             hz_cust_site_uses.site_use_id%TYPE;
l_customer_receipt_reference       ar_cash_receipts.customer_receipt_reference%TYPE;
l_override_remit_account_flag      ar_cash_receipts.override_remit_account_flag%TYPE;
l_remit_bank_acct_use_id       ar_cash_receipts.remit_bank_acct_use_id%TYPE;
l_remittance_bank_account_num      ce_bank_accounts.bank_account_num%TYPE;
l_deposit_date                     ar_cash_receipts.deposit_date%TYPE;
l_receipt_method_id                ar_cash_receipts.receipt_method_id%TYPE;
l_receipt_method_name              ar_receipt_methods.name%TYPE;
l_ussgl_transaction_code           ar_cash_receipts.ussgl_transaction_code%TYPE;
l_anticipated_clearing_date        ar_cash_receipts.anticipated_clearing_date%TYPE;
l_state VARCHAR2(30);
l_cr_id          NUMBER;
l_ps_id          NUMBER;
l_row_id         VARCHAR2(30);
l_validation_status  VARCHAR2(2)    := FND_API.G_RET_STS_SUCCESS;
l_doc_seq_status     VARCHAR2(10);
l_doc_sequence_id    NUMBER;
l_doc_sequence_value NUMBER;
l_postmark_date  DATE;
l_cash_def_return_status VARCHAR2(1);
l_val_return_status  VARCHAR2(1);
l_def_cash_id_return_status  VARCHAR2(1);
l_default_site_use VARCHAR2(1);  --bug4448307-4509459
BEGIN
   --call the internal routine
   Create_cash_1(
           -- Standard API parameters.
                 p_api_version ,
                 p_init_msg_list,
                 p_commit,
                 p_validation_level,
                 x_return_status,
                 x_msg_count,
                 x_msg_data ,
                 -- Receipt info. parameters
                 p_usr_currency_code, --the translated currency code
                 p_currency_code    ,
                 p_usr_exchange_rate_type ,
                 p_exchange_rate_type     ,
                 p_exchange_rate         ,
                 p_exchange_rate_date    ,
                 p_amount                ,
                 p_factor_discount_amount,
                 p_receipt_number        ,
                 p_receipt_date          ,
                 p_gl_date               ,
                 p_maturity_date         ,
                 p_postmark_date         ,
                 p_customer_id           ,
                 p_customer_name         ,
                 p_customer_number       ,
                 p_customer_bank_account_id ,
                 p_customer_bank_account_num ,
                 p_customer_bank_account_name ,
                 p_payment_trxn_extension_id , -- bichatte payment uptake project
                 p_location               ,
                 p_customer_site_use_id   ,
                 p_default_site_use,                 --BUG4448307-4509459
                 p_customer_receipt_reference ,
                 p_override_remit_account_flag ,
                 p_remittance_bank_account_id  ,
                 p_remittance_bank_account_num ,
                 p_remittance_bank_account_name ,
                 p_deposit_date             ,
                 p_receipt_method_id        ,
                 p_receipt_method_name      ,
                 p_doc_sequence_value       ,
                 p_ussgl_transaction_code   ,
                 p_anticipated_clearing_date ,
                 p_called_from               ,
                 p_attribute_rec         ,
       -- ******* Global Flexfield parameters *******
                 p_global_attribute_rec  ,
                 p_comments             ,
      --   ***  Notes Receivable Additional Information  ***
                 p_issuer_name    ,
                 p_issue_date     ,
                 p_issuer_bank_branch_id  ,
      --added  parameters to differentiate between create_cash and create_and_apply
                 NULL,
                 NULL,
                 p_installment,
                 NULL,
                 'CREATE_CASH',
                 p_org_id,
      --   ** OUT NOCOPY variables
                 p_cr_id
                  );

END Create_cash;


PROCEDURE Apply(
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
      p_amount_applied               IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      -- this is the allocated receipt amount
      p_amount_applied_from          IN ar_receivable_applications.amount_applied_from%TYPE DEFAULT NULL,
      p_trans_to_receipt_rate        IN ar_receivable_applications.trans_to_receipt_rate%TYPE DEFAULT NULL,
      p_discount                     IN ar_receivable_applications.earned_discount_taken%TYPE DEFAULT NULL,
      p_apply_date                   IN ar_receivable_applications.apply_date%TYPE DEFAULT NULL,
      p_apply_gl_date                IN ar_receivable_applications.gl_date%TYPE DEFAULT NULL,
      p_ussgl_transaction_code       IN ar_receivable_applications.ussgl_transaction_code%TYPE DEFAULT NULL,
      p_customer_trx_line_id	     IN ar_receivable_applications.applied_customer_trx_line_id%TYPE DEFAULT NULL,
      p_line_number                  IN ra_customer_trx_lines.line_number%TYPE DEFAULT NULL,
      p_show_closed_invoices         IN VARCHAR2 DEFAULT 'N', /* Bug fix 2462013 */
      p_called_from                  IN VARCHAR2 DEFAULT NULL,
      p_move_deferred_tax            IN VARCHAR2 DEFAULT 'Y',
      p_link_to_trx_hist_id          IN ar_receivable_applications.link_to_trx_hist_id%TYPE DEFAULT NULL,
      p_attribute_rec                IN attribute_rec_type DEFAULT attribute_rec_const,
	 -- ******* Global Flexfield parameters *******
      p_global_attribute_rec         IN global_attribute_rec_type DEFAULT global_attribute_rec_const,
      p_comments                     IN ar_receivable_applications.comments%TYPE,
      p_payment_set_id               IN ar_receivable_applications.payment_set_id%TYPE DEFAULT NULL,
      p_application_ref_type         IN ar_receivable_applications.application_ref_type%TYPE DEFAULT NULL,
      p_application_ref_id           IN ar_receivable_applications.application_ref_id%TYPE DEFAULT NULL,
      p_application_ref_num          IN ar_receivable_applications.application_ref_num%TYPE DEFAULT NULL,
      p_secondary_application_ref_id IN ar_receivable_applications.secondary_application_ref_id%TYPE DEFAULT NULL,
      p_application_ref_reason       IN ar_receivable_applications.application_ref_reason%TYPE DEFAULT NULL,
      p_customer_reference           IN ar_receivable_applications.customer_reference%TYPE DEFAULT NULL,
      p_customer_reason              IN ar_receivable_applications.customer_reason%TYPE DEFAULT NULL,
      p_org_id                       IN NUMBER  DEFAULT NULL,
      p_disable_balance_check        IN VARCHAR2 DEFAULT 'N'
      ) IS
l_api_name       CONSTANT VARCHAR2(20) := 'Apply';
l_api_version    CONSTANT NUMBER       := 1.0;
l_cash_receipt_id  NUMBER;
l_cr_gl_date       DATE;
l_cr_date          DATE;
l_cr_amount        NUMBER;
l_cr_unapp_amount  NUMBER;
l_cr_currency_code VARCHAR2(15);
l_customer_trx_id  NUMBER(15);
l_installment      NUMBER;
l_customer_trx_line_id NUMBER(15);
l_trx_due_date     DATE;
l_trx_currency_code VARCHAR2(15);
l_trx_gl_date   DATE;
l_apply_gl_date DATE;
l_calc_discount_on_lines_flag  VARCHAR2(1);
l_partial_discount_flag   VARCHAR2(1);
l_allow_overappln_flag VARCHAR2(1);
l_natural_appln_only_flag  VARCHAR2(1);
l_creation_sign VARCHAR2(30);
l_amount_applied NUMBER;
l_amount_applied_from  NUMBER;
l_trans_to_receipt_rate  NUMBER;
l_applied_payment_schedule_id  NUMBER;
l_cr_payment_schedule_id  NUMBER;
l_apply_date  DATE;
l_trx_date  DATE;
l_discount  NUMBER;
l_discount_earned_allowed  NUMBER;
l_discount_max_allowed  NUMBER;
l_term_id  NUMBER;
l_trx_line_amount NUMBER;
l_amount_due_original   NUMBER;
l_amount_due_remaining  NUMBER;
l_discount_earned  NUMBER;
l_discount_unearned  NUMBER;
l_new_amount_due_remaining NUMBER;
--OUT parameters of the entity handler
p_out_rec_application_id NUMBER;
p_acctd_amount_applied_from NUMBER;
p_acctd_amount_applied_to  NUMBER;
l_def_return_status  VARCHAR2(1);
l_val_return_status VARCHAR2(1);
l_app_validation_return_status VARCHAR2(1);
l_def_ids_return_status  VARCHAR2(1);
l_dflex_val_return_status  VARCHAR2(1);
l_attribute_rec         attribute_rec_type;
l_global_attribute_rec  global_attribute_rec_type;
l_remit_bank_acct_use_id    NUMBER;
l_receipt_method_id             NUMBER;
l_gdflex_return_status    VARCHAR2(1);
l_application_ref_id      ar_receivable_applications.application_ref_id%TYPE;
l_application_ref_num     ar_receivable_applications.application_ref_num%TYPE;
l_return_status           VARCHAR2(1);
l_msg_count               NUMBER;
l_msg_data                VARCHAR2(2000);
l_payment_set_id          NUMBER;
l_amount_due_remain_disc  NUMBER;         /* Bug 2535663 */
l_claim_reason_name       VARCHAR2(100);
l_org_return_status VARCHAR2(1);
l_org_id                           NUMBER;

-- LLCA
l_llca_type		varchar2(1) := NULL;
l_group_id              ra_customer_trx_lines.source_data_key4%TYPE := NULL;
l_line_amount		NUMBER;
l_tax_amount		NUMBER;
l_freight_amount	NUMBER;
l_charges_amount	NUMBER;
l_line_discount		NUMBER;
l_tax_discount		NUMBER;
l_freight_discount	NUMBER;
l_line_items_original   NUMBER;
l_line_items_remaining  NUMBER;
l_tax_original		NUMBER;
l_tax_remaining		NUMBER;
l_freight_original	NUMBER;
l_freight_remaining	NUMBER;
l_rec_charges_charged	NUMBER;
l_rec_charges_remaining NUMBER;
l_gt          NUMBER;
l_called_from   VARCHAR2(100) DEFAULT NULL;
l_disable_balance_check VARCHAR2(1);


BEGIN

       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

      SAVEPOINT Apply_PVT;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*--------------------------------------------------------------+
        |   Initialize message list if p_init_msg_list is set to TRUE  |
        +--------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
          THEN
              FND_MSG_PUB.initialize;
        END IF;

Original_application_info.cash_receipt_id             := p_cash_receipt_id;
Original_application_info.receipt_number              := p_receipt_number;
Original_application_info.customer_trx_id             := p_customer_trx_id;
Original_application_info.trx_number                  := p_trx_number;
Original_application_info.installment                 := p_installment;
Original_application_info.applied_payment_schedule_id := p_applied_payment_schedule_id;
Original_application_info.customer_trx_line_id        := p_customer_trx_line_id;
Original_application_info.line_number                 := p_line_number;
Original_application_info.amount_applied_from         := p_amount_applied_from;
Original_application_info.trans_to_receipt_rate       := p_trans_to_receipt_rate;


        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Apply()+ ');
        END IF;

       /*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/
        x_return_status := FND_API.G_RET_STS_SUCCESS;




 /* SSA change */
       l_org_id            := p_org_id;
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;
       ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);
       l_called_from := p_called_from;

      IF(p_called_from = 'OZFAPI') THEN

   if ( FND_API.to_Boolean(p_commit) = FALSE ) then
           select COUNT(*) into l_gt from ra_customer_trx_lines_gt where customer_trx_id=p_customer_trx_id;

           IF (l_gt > 0 )  then
      delete FROM ra_customer_trx_lines_gt where customer_trx_id=p_customer_trx_id;
       end if;

      end if;
       l_called_from := NULL;
      END IF;

  /* Added for bug 21391824 - Begin */
  l_disable_balance_check := p_disable_balance_check;

  IF PG_DEBUG in ('Y', 'C') THEN
    arp_util.debug('l_disable_balance_check: ' || l_disable_balance_check);
  END IF;
  /* Added for bug 21391824 - End */

   IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
 ELSE


        /*-------------------------------------------------+
         | Initialize the profile option package variables |
         +-------------------------------------------------*/

           initialize_profile_globals;


       /*---------------------------------------------+
        |   ========== Start of API Body ==========   |
        +---------------------------------------------*/

     l_cash_receipt_id        := p_cash_receipt_id;
     l_customer_trx_id        := p_customer_trx_id;
     l_installment            := p_installment;
     l_amount_applied         := p_amount_applied;
     l_amount_applied_from    := p_amount_applied_from;
     l_trans_to_receipt_rate  := p_trans_to_receipt_rate;
     l_discount               := p_discount;
     l_apply_date             := trunc(p_apply_date);
     l_apply_gl_date          := trunc(p_apply_gl_date);
     l_customer_trx_line_id   := p_customer_trx_line_id;
     l_applied_payment_schedule_id := p_applied_payment_schedule_id;
     l_attribute_rec          := p_attribute_rec;
     l_global_attribute_rec   := p_global_attribute_rec;
     l_payment_set_id         := p_payment_set_id;


          /*-----------------------+
           |                       |
           |ID TO VALUE CONVERSION |
           |                       |
           +-----------------------*/

        ar_receipt_lib_pvt.Default_appln_ids(
                            l_cash_receipt_id,
                            p_receipt_number,
                            l_customer_trx_id,
                            p_trx_number,
                            l_customer_trx_line_id, /* Bug fix 3435834 */
                            p_line_number,  /* Bug fix 3435834 */
                            l_installment,
                            l_applied_payment_schedule_id,
			    l_llca_type,
		            l_group_id ,   /* Bug 5284890 */
                            l_def_ids_return_status);


   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('Apply: ' || 'Defaulting Ids Return_status = '||l_def_ids_return_status);
   END IF;
          /*---------------------+
           |                     |
           |    DEFAULTING       |
           |                     |
           +---------------------*/
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('Apply: ' || 'l_amount_applied_from :'||to_char(l_amount_applied_from));
   END IF;
         ar_receipt_lib_pvt.Default_application_info(
              l_cash_receipt_id   ,
              l_cr_gl_date,
              l_cr_date,
              l_cr_amount,
              l_cr_unapp_amount,
              l_cr_currency_code ,
              l_customer_trx_id,
              l_installment,
              p_show_closed_invoices,
              l_customer_trx_line_id,
              l_trx_due_date,
              l_trx_currency_code,
              l_trx_date,
              l_trx_gl_date,
              l_apply_gl_date,
              l_calc_discount_on_lines_flag,
              l_partial_discount_flag,
              l_allow_overappln_flag,
              l_natural_appln_only_flag,
              l_creation_sign ,
              l_cr_payment_schedule_id ,
              l_applied_payment_schedule_id ,
              l_term_id ,
              l_amount_due_original ,
              l_amount_due_remaining,
              l_trx_line_amount,
              l_discount,
              l_apply_date ,
              l_discount_max_allowed,
              l_discount_earned_allowed,
              l_discount_earned,
              l_discount_unearned ,
              l_new_amount_due_remaining,
              l_remit_bank_acct_use_id,
              l_receipt_method_id,
              l_amount_applied ,
              l_amount_applied_from ,
              l_trans_to_receipt_rate,
      	      l_llca_type,
	      l_line_amount,
	      l_tax_amount,
	      l_freight_amount,
	      l_charges_amount,
	      l_line_discount,
	      l_tax_discount,
	      l_freight_discount,
      	      l_line_items_original,
	      l_line_items_remaining,
	      l_tax_original,
	      l_tax_remaining,
	      l_freight_original,
	      l_freight_remaining,
	      l_rec_charges_charged,
	      l_rec_charges_remaining,
              l_called_from,
              l_def_return_status
               );
IF PG_DEBUG in ('Y', 'C') THEN
   arp_util.debug('Apply: ' || 'l_amount_applied_from :'||to_char(l_amount_applied_from));
   arp_util.debug('Apply: ' || 'l_new_amount_due_remaining :'||to_char(l_new_amount_due_remaining));
   arp_util.debug('Apply: ' || 'Defaulting Return_status = '||l_def_return_status);
END IF;
          /*---------------------+
           |                     |
           |    VALIDATION       |
           |                     |
           +---------------------*/
    --The defaulting routine will raise error only if there is an error in
    --defaulting for any of the two entities : Cash receipt and Transaction.
    --So in this case there is no point in calling the validation routines as
    --at least on of the two main entities are invalid.
    --The invalid cash receipt is bound to give an invalid transaction error
    IF l_def_return_status = FND_API.G_RET_STS_SUCCESS  AND
       l_def_ids_return_status = FND_API.G_RET_STS_SUCCESS
      THEN

      IF (p_called_from = 'IGI_UNAPPLY') then /* bug 18147460 */
            l_natural_appln_only_flag := 'N';
      END IF;

          ar_receipt_val_pvt.Validate_Application_info(
                      l_apply_date,
                      l_cr_date,
                      l_trx_date,
                      l_apply_gl_date  ,
                      l_trx_gl_date,
                      l_cr_gl_date,
                      l_amount_applied,
                      l_applied_payment_schedule_id,
                      l_customer_trx_line_id,
                      l_trx_line_amount,
                      l_creation_sign,
                      l_allow_overappln_flag,
                      l_natural_appln_only_flag,
                      l_discount  ,
                      l_amount_due_remaining,
                      l_amount_due_original,
                      l_trans_to_receipt_rate,
                      l_cr_currency_code ,
                      l_trx_currency_code,
                      l_amount_applied_from ,
                      l_cr_unapp_amount ,
                      l_partial_discount_flag ,
                      l_discount_earned_allowed,
                      l_discount_max_allowed ,
                      p_move_deferred_tax,
      	      	      l_llca_type,
		      l_line_amount,
		      l_tax_amount,
		      l_freight_amount,
		      l_charges_amount,
		      l_line_discount,
		      l_tax_discount,
		      l_freight_discount,
		      l_line_items_original,
		      l_line_items_remaining,
		      l_tax_original,
		      l_tax_remaining,
		      l_freight_original,
		      l_freight_remaining,
		      l_rec_charges_charged,
		      l_rec_charges_remaining,
                      l_val_return_status
                          );
                      IF PG_DEBUG in ('Y', 'C') THEN
                         arp_util.debug('Apply: ' || 'Validation Return_status = '||l_val_return_status);
                      END IF;
    END IF;

        --Validate application reference details passed.
        /* Bug 2535663 - subtract discounts from amount due remaining */
        l_amount_due_remain_disc := (l_amount_due_remaining -
                                       l_discount_earned - l_discount_unearned);
	ar_receipt_val_pvt.validate_application_ref(
                              l_applied_payment_schedule_id,
                              p_application_ref_type,
                              p_application_ref_id,
                              p_application_ref_num,
                              p_secondary_application_ref_id,
                              l_cash_receipt_id,
                              l_amount_applied,
                              l_amount_due_remain_disc,
                              l_cr_currency_code,
                              l_trx_currency_code,
                              p_application_ref_reason,
                              l_app_validation_return_status
                               );

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Apply: ' || 'Application ref Validation return status :'||l_app_validation_return_status);
        END IF;

        /* Bug 9501452 Bypass DFF validation in case call is for AP/AR Netting*/
        IF nvl(l_receipt_method_id,-99) <> -1 THEN
        --validate and default the flexfields
        ar_receipt_lib_pvt.Validate_Desc_Flexfield(
                                        l_attribute_rec,
                                        'AR_RECEIVABLE_APPLICATIONS',
                                        l_dflex_val_return_status
                                                );


       --default and validate the global descriptive flexfield
        jg_ar_receivable_applications.apply(
                  p_apply_before_after        => 'BEFORE',
                  p_global_attribute_category => l_global_attribute_rec.global_attribute_category,
                  p_set_of_books_id           => arp_global.set_of_books_id,
                  p_cash_receipt_id           => l_cash_receipt_id,
                  p_receipt_date              => l_cr_date,
                  p_applied_payment_schedule_id => l_applied_payment_schedule_id,
                  p_amount_applied              => l_amount_applied,
                  p_unapplied_amount            => (l_cr_unapp_amount - l_amount_applied),
                  p_due_date                    => l_trx_due_date,
                  p_receipt_method_id           => l_receipt_method_id,
                  p_remittance_bank_account_id  => l_remit_bank_acct_use_id,
                  p_global_attribute1           => l_global_attribute_rec.global_attribute1,
                  p_global_attribute2           => l_global_attribute_rec.global_attribute2,
                  p_global_attribute3           => l_global_attribute_rec.global_attribute3,
                  p_global_attribute4           => l_global_attribute_rec.global_attribute4,
                  p_global_attribute5           => l_global_attribute_rec.global_attribute5,
                  p_global_attribute6           => l_global_attribute_rec.global_attribute6,
                  p_global_attribute7           => l_global_attribute_rec.global_attribute7,
                  p_global_attribute8           => l_global_attribute_rec.global_attribute8,
                  p_global_attribute9           => l_global_attribute_rec.global_attribute9,
                  p_global_attribute10          => l_global_attribute_rec.global_attribute10,
                  p_global_attribute11          => l_global_attribute_rec.global_attribute11,
                  p_global_attribute12          => l_global_attribute_rec.global_attribute12,
                  p_global_attribute13          => l_global_attribute_rec.global_attribute13,
                  p_global_attribute14          => l_global_attribute_rec.global_attribute14,
                  p_global_attribute15          => l_global_attribute_rec.global_attribute15,
                  p_global_attribute16          => l_global_attribute_rec.global_attribute16,
                  p_global_attribute17          => l_global_attribute_rec.global_attribute17,
                  p_global_attribute18          => l_global_attribute_rec.global_attribute18,
                  p_global_attribute19          => l_global_attribute_rec.global_attribute19,
                  p_global_attribute20          => l_global_attribute_rec.global_attribute20,
                  p_return_status               => l_gdflex_return_status);

        END IF;
END IF;

       IF l_def_ids_return_status <> FND_API.G_RET_STS_SUCCESS OR
          l_val_return_status     <> FND_API.G_RET_STS_SUCCESS OR
          l_def_return_status     <> FND_API.G_RET_STS_SUCCESS  OR
          l_dflex_val_return_status <> FND_API.G_RET_STS_SUCCESS OR
          l_app_validation_return_status <> FND_API.G_RET_STS_SUCCESS OR
          l_gdflex_return_status  <> FND_API.G_RET_STS_SUCCESS THEN
          x_return_status := FND_API.G_RET_STS_ERROR;
       END IF;

       /* Bug fix 3435834
          The messages should be retrieved irrespective of the return status */
       FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                        p_count => x_msg_count,
                                        p_data  => x_msg_data
                                       );

       IF x_return_status <> FND_API.G_RET_STS_SUCCESS
         THEN

            ROLLBACK TO Apply_PVT;

             x_return_status := FND_API.G_RET_STS_ERROR ;

             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Apply: ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
             END IF;
             Return;
        END IF;

      --Dump the input variables to the entity handler
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('Apply: ' || 'l_cr_payment_schedule_id      : '||to_char(l_cr_payment_schedule_id));
       arp_util.debug('Apply: ' || 'l_applied_payment_schedule_id : '||to_char(l_applied_payment_schedule_id));
       arp_util.debug('Apply: ' || 'l_amount_applied              : '||to_char(l_amount_applied));
       arp_util.debug('Apply: ' || 'l_amount_applied_from         : '||to_char(l_amount_applied_from));
       arp_util.debug('Apply: ' || 'l_trans_to_receipt_rate       : '||to_char(l_trans_to_receipt_rate));
       arp_util.debug('Apply: ' || 'l_trx_currency_code           : '||l_trx_currency_code);
       arp_util.debug('Apply: ' || 'l_cr_currency_code            : '||l_cr_currency_code);
       arp_util.debug('Apply: ' || 'l_discount_earned             : '||to_char(l_discount_earned));
       arp_util.debug('Apply: ' || 'l_discount_unearned           : '||to_char(l_discount_unearned));
       arp_util.debug('l_apply_date                  : '||to_char(l_apply_date,'DD-MON-YY'));
       arp_util.debug('l_apply_gl_date               : '||to_char(l_apply_gl_date,'DD-MON-YY'));
       arp_util.debug('Apply: ' || 'l_customer_trx_line_id        : '||to_char(l_customer_trx_line_id));
    END IF;

     --lock the receipt before calling the entity handler
       arp_cash_receipts_pkg.nowaitlock_p(p_cr_id => l_cash_receipt_id);

       /* Bug 4042420: lock the payment schedule of the applied transaction */
       arp_ps_pkg.nowaitlock_p (p_ps_id => l_applied_payment_schedule_id);

   /* Bug 3773036: Initializing the return status */
   l_return_status := FND_API.G_RET_STS_SUCCESS;

   BEGIN
     --call the entity handler
    arp_process_application.receipt_application(
	p_receipt_ps_id => l_cr_payment_schedule_id ,
	p_invoice_ps_id => l_applied_payment_schedule_id ,
        p_amount_applied => l_amount_applied ,
        p_amount_applied_from => l_amount_applied_from ,
        p_trans_to_receipt_rate => l_trans_to_receipt_rate ,
        p_invoice_currency_code => l_trx_currency_code ,
        p_receipt_currency_code => l_cr_currency_code ,
        p_earned_discount_taken => l_discount_earned ,
        p_unearned_discount_taken => l_discount_unearned ,
        p_apply_date => l_apply_date ,
	p_gl_date => l_apply_gl_date ,
	p_ussgl_transaction_code => p_ussgl_transaction_code ,
	p_customer_trx_line_id	=> l_customer_trx_line_id ,
        p_application_ref_type => p_application_ref_type,
        p_application_ref_id => p_application_ref_id,
        p_application_ref_num => p_application_ref_num,
        p_secondary_application_ref_id => p_secondary_application_ref_id,
        p_attribute_category => l_attribute_rec.attribute_category,
	p_attribute1 => l_attribute_rec.attribute1,
	p_attribute2 => l_attribute_rec.attribute2,
	p_attribute3 => l_attribute_rec.attribute3,
	p_attribute4 => l_attribute_rec.attribute4,
	p_attribute5 => l_attribute_rec.attribute5,
	p_attribute6 => l_attribute_rec.attribute6,
	p_attribute7 => l_attribute_rec.attribute7,
	p_attribute8 => l_attribute_rec.attribute8,
	p_attribute9 => l_attribute_rec.attribute9,
	p_attribute10 => l_attribute_rec.attribute10,
	p_attribute11 => l_attribute_rec.attribute11,
	p_attribute12 => l_attribute_rec.attribute12,
	p_attribute13 => l_attribute_rec.attribute13,
	p_attribute14 => l_attribute_rec.attribute14,
	p_attribute15 => l_attribute_rec.attribute15,
        p_global_attribute_category => p_global_attribute_rec.global_attribute_category,
        p_global_attribute1 => p_global_attribute_rec.global_attribute1,
        p_global_attribute2 => p_global_attribute_rec.global_attribute2,
        p_global_attribute3 => p_global_attribute_rec.global_attribute3,
        p_global_attribute4 => p_global_attribute_rec.global_attribute4,
        p_global_attribute5 => p_global_attribute_rec.global_attribute5,
        p_global_attribute6 => p_global_attribute_rec.global_attribute6,
        p_global_attribute7 => p_global_attribute_rec.global_attribute7,
        p_global_attribute8 => p_global_attribute_rec.global_attribute8,
        p_global_attribute9 => p_global_attribute_rec.global_attribute9,
        p_global_attribute10 => p_global_attribute_rec.global_attribute10,
        p_global_attribute11 => p_global_attribute_rec.global_attribute11,
        p_global_attribute12 => p_global_attribute_rec.global_attribute12,
        p_global_attribute13 => p_global_attribute_rec.global_attribute13,
        p_global_attribute14 => p_global_attribute_rec.global_attribute14,
        p_global_attribute15 => p_global_attribute_rec.global_attribute15,
        p_global_attribute16 => p_global_attribute_rec.global_attribute16,
        p_global_attribute17 => p_global_attribute_rec.global_attribute17,
        p_global_attribute18 => p_global_attribute_rec.global_attribute18,
        p_global_attribute19 => p_global_attribute_rec.global_attribute19,
        p_global_attribute20 => p_global_attribute_rec.global_attribute20,
        p_comments => p_comments ,
	p_module_name => 'RAPI',
	p_module_version => p_api_version ,
        x_application_ref_id => l_application_ref_id,
        x_application_ref_num => l_application_ref_num,
        x_return_status => l_return_status,
        x_msg_count => l_msg_count,
        x_msg_data  => l_msg_data,
	p_out_rec_application_id => p_out_rec_application_id ,
        p_acctd_amount_applied_from => p_acctd_amount_applied_from,
        p_acctd_amount_applied_to => p_acctd_amount_applied_to,
        x_claim_reason_name => l_claim_reason_name,
	p_called_from => l_called_from,
	p_move_deferred_tax     => p_move_deferred_tax,
        p_link_to_trx_hist_id   => p_link_to_trx_hist_id,
        p_amount_due_remaining  => NULL,
	p_payment_set_id        => l_payment_set_id,
        p_application_ref_reason => p_application_ref_reason,
        p_customer_reference     => p_customer_reference,
        p_customer_reason        => p_customer_reason,
        p_disable_balance_check  => l_disable_balance_check        -- /* Added for bug 21391824*/
                               );
      -- Assign receivable_application_id to package global variable
      -- So, it can used to perform follow on operation on given application
      apply_out_rec.receivable_application_id := p_out_rec_application_id;

   EXCEPTION
     WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN
                     ROLLBACK TO Apply_PVT;

                      --  Display_Parameters;
                      x_return_status := FND_API.G_RET_STS_ERROR ;
                       FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                       FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','ARP_PROCESS_APPLICATION.RECEIPT_APPLICATION '||SQLERRM);
                       FND_MSG_PUB.Add;

                       FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                                                  p_count  =>  x_msg_count,
                                                  p_data   => x_msg_data
                                                );
                      RETURN;
                ELSE
                   RAISE;
                END IF;
   END;

   /* Bug 3773036: raising error if return status is not success */
   IF l_return_status = FND_API.G_RET_STS_ERROR THEN
      RAISE FND_API.G_EXC_ERROR;
   END IF;
   IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;

      jg_ar_receivable_applications.apply(
                  p_apply_before_after        => 'AFTER',
                  p_global_attribute_category => l_global_attribute_rec.global_attribute_category,
                  p_set_of_books_id           => null,
                  p_cash_receipt_id           => null,
                  p_receipt_date              => null,
                  p_applied_payment_schedule_id => l_applied_payment_schedule_id,
                  p_amount_applied              => null,
                  p_unapplied_amount            => null,
                  p_due_date                    => null,
                  p_receipt_method_id           => null,
                  p_remittance_bank_account_id  => null,
                  p_global_attribute1           => l_global_attribute_rec.global_attribute1,
                  p_global_attribute2           => l_global_attribute_rec.global_attribute2,
                  p_global_attribute3           => l_global_attribute_rec.global_attribute3,
                  p_global_attribute4           => l_global_attribute_rec.global_attribute4,
                  p_global_attribute5           => l_global_attribute_rec.global_attribute5,
                  p_global_attribute6           => l_global_attribute_rec.global_attribute6,
                  p_global_attribute7           => l_global_attribute_rec.global_attribute7,
                  p_global_attribute8           => l_global_attribute_rec.global_attribute8,
                  p_global_attribute9           => l_global_attribute_rec.global_attribute9,
                  p_global_attribute10          => l_global_attribute_rec.global_attribute10,
                  p_global_attribute11          => l_global_attribute_rec.global_attribute11,
                  p_global_attribute12          => l_global_attribute_rec.global_attribute12,
                  p_global_attribute13          => l_global_attribute_rec.global_attribute13,
                  p_global_attribute14          => l_global_attribute_rec.global_attribute14,
                  p_global_attribute15          => l_global_attribute_rec.global_attribute15,
                  p_global_attribute16          => l_global_attribute_rec.global_attribute16,
                  p_global_attribute17          => l_global_attribute_rec.global_attribute17,
                  p_global_attribute18          => l_global_attribute_rec.global_attribute18,
                  p_global_attribute19          => l_global_attribute_rec.global_attribute19,
                  p_global_attribute20          => l_global_attribute_rec.global_attribute20,
                  p_return_status               => l_gdflex_return_status);
       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Apply: ' || 'committing');
            END IF;
              Commit;
        END IF;
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Apply ()- ');
        END IF;
EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Apply: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Apply_PVT;
                x_return_status := FND_API.G_RET_STS_ERROR ;

               -- Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply: ' || SQLERRM, G_MSG_ERROR);
                END IF;
                ROLLBACK TO Apply_PVT;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

               --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN

                      ROLLBACK TO Apply_PVT;

                      --If only one error message on the stack,
                      --retrive it

                      x_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','APPLY : '||SQLERRM);
                      FND_MSG_PUB.Add;

                      FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                                 p_count  =>  x_msg_count,
                                                 p_data   => x_msg_data
                                                );

                      RETURN;

                ELSE
                      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','APPLY : '||SQLERRM);
                      FND_MSG_PUB.Add;
                END IF;

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Apply: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Apply_PVT;

                IF      FND_MSG_PUB.Check_Msg_Level
                THEN
                FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME,
                                        l_api_name
                                       );
                END IF;

             --   Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

END Apply;

PROCEDURE Apply_In_Detail(
-- Standard API parameters.
      p_api_version                 IN  NUMBER,
      p_init_msg_list               IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit                      IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level            IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status               OUT NOCOPY VARCHAR2,
      x_msg_count                   OUT NOCOPY NUMBER,
      x_msg_data                    OUT NOCOPY VARCHAR2,
 --  Receipt application parameters.
      p_cash_receipt_id             IN ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
      p_receipt_number              IN ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      p_customer_trx_id             IN ra_customer_trx.customer_trx_id%TYPE DEFAULT NULL,
      p_trx_number                  IN ra_customer_trx.trx_number%TYPE DEFAULT NULL,
      p_installment                 IN ar_payment_schedules.terms_sequence_number%TYPE DEFAULT NULL,
      p_applied_payment_schedule_id IN ar_payment_schedules.payment_schedule_id%TYPE DEFAULT NULL,
-- LLCA Parameters
      p_llca_type		    IN VARCHAR2 DEFAULT 'S',
      p_llca_trx_lines_tbl          IN llca_trx_lines_tbl_type DEFAULT llca_def_trx_lines_tbl_type,
      p_group_id                    IN VARCHAR2 DEFAULT NULL,   /* Bug 5284890 */
      p_line_amount		    IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      p_tax_amount		    IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      p_freight_amount		    IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      p_charges_amount		    IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      p_amount_applied              IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      p_line_discount               IN NUMBER DEFAULT NULL,
      p_tax_discount                IN NUMBER DEFAULT NULL,
      p_freight_discount            IN NUMBER DEFAULT NULL,
      p_amount_applied_from         IN ar_receivable_applications.amount_applied_from%TYPE DEFAULT NULL,
      p_trans_to_receipt_rate       IN ar_receivable_applications.trans_to_receipt_rate%TYPE DEFAULT NULL,
      p_discount                    IN ar_receivable_applications.earned_discount_taken%TYPE DEFAULT NULL,
      p_apply_date                  IN ar_receivable_applications.apply_date%TYPE DEFAULT NULL,
      p_apply_gl_date               IN ar_receivable_applications.gl_date%TYPE DEFAULT NULL,
      p_ussgl_transaction_code      IN ar_receivable_applications.ussgl_transaction_code%TYPE DEFAULT NULL,
      p_show_closed_invoices        IN VARCHAR2 DEFAULT 'N',
      p_called_from                 IN VARCHAR2 DEFAULT NULL,
      p_move_deferred_tax           IN VARCHAR2 DEFAULT 'Y',
      p_link_to_trx_hist_id         IN ar_receivable_applications.link_to_trx_hist_id%TYPE DEFAULT NULL,
      p_attribute_rec               IN attribute_rec_type DEFAULT attribute_rec_const,
	 -- ******* Global Flexfield parameters *******
      p_global_attribute_rec        IN global_attribute_rec_type DEFAULT global_attribute_rec_const,
      p_comments                    IN ar_receivable_applications.comments%TYPE DEFAULT NULL,
      p_payment_set_id              IN ar_receivable_applications.payment_set_id%TYPE DEFAULT NULL,
      p_application_ref_type        IN ar_receivable_applications.application_ref_type%TYPE DEFAULT NULL,
      p_application_ref_id          IN ar_receivable_applications.application_ref_id%TYPE DEFAULT NULL,
      p_application_ref_num         IN ar_receivable_applications.application_ref_num%TYPE DEFAULT NULL,
      p_secondary_application_ref_id IN ar_receivable_applications.secondary_application_ref_id%TYPE DEFAULT NULL,
      p_application_ref_reason      IN ar_receivable_applications.application_ref_reason%TYPE DEFAULT NULL,
      p_customer_reference          IN ar_receivable_applications.customer_reference%TYPE DEFAULT NULL,
      p_customer_reason             IN ar_receivable_applications.customer_reason%TYPE DEFAULT NULL,
      p_org_id                      IN NUMBER  DEFAULT NULL,
      p_line_attribute_rec          IN attribute_rec_type DEFAULT attribute_rec_const
      ) IS

l_api_name			CONSTANT VARCHAR2(20) := 'Apply_In_Detail';
l_api_version			CONSTANT NUMBER       := 1.0;
l_cash_receipt_id		NUMBER;
l_cr_gl_date			DATE;
l_cr_date			DATE;
l_cr_amount			NUMBER;
l_cr_unapp_amount		NUMBER;
l_cr_currency_code		VARCHAR2(15);
l_customer_trx_id		NUMBER(15);
l_installment			NUMBER;
l_customer_trx_line_id		NUMBER(15);
l_trx_due_date			DATE;
l_trx_currency_code		VARCHAR2(15);
l_trx_gl_date			DATE;
l_apply_gl_date			DATE;
l_calc_discount_on_lines_flag	VARCHAR2(1);
l_partial_discount_flag		VARCHAR2(1);
l_allow_overappln_flag		VARCHAR2(1);
l_natural_appln_only_flag	VARCHAR2(1);
l_creation_sign			VARCHAR2(30);
l_amount_applied		NUMBER;
l_amount_applied_from		NUMBER;
l_line_amount			NUMBER;
l_tax_amount    		NUMBER;
l_freight_amount  		NUMBER;
l_charges_amount  		NUMBER;
l_line_discount  		NUMBER;
l_tax_discount  		NUMBER;
l_freight_discount  		NUMBER;
l_trans_to_receipt_rate		NUMBER;
l_applied_payment_schedule_id	NUMBER;
l_cr_payment_schedule_id	NUMBER;
l_apply_date			DATE;
l_trx_date			DATE;
l_discount			NUMBER;
l_discount_earned_allowed	NUMBER;
l_discount_max_allowed		NUMBER;
l_term_id			NUMBER;
l_trx_line_amount		NUMBER;
l_amount_due_original		NUMBER;
l_amount_due_remaining		NUMBER;
l_discount_earned		NUMBER;
l_discount_unearned		NUMBER;
l_new_amount_due_remaining	NUMBER;
p_out_rec_application_id	NUMBER;
p_acctd_amount_applied_from	NUMBER;
p_acctd_amount_applied_to	NUMBER;
l_def_return_status		VARCHAR2(1);
l_val_return_status		VARCHAR2(1);
l_app_validation_return_status	VARCHAR2(1);
l_def_ids_return_status		VARCHAR2(1);
l_dflex_val_return_status	VARCHAR2(1);
l_attribute_rec			attribute_rec_type;
l_global_attribute_rec		global_attribute_rec_type;
l_remit_bank_acct_use_id	NUMBER;
l_receipt_method_id             NUMBER;
l_gdflex_return_status		VARCHAR2(1);
l_application_ref_id            ar_receivable_applications.application_ref_id%TYPE;
l_application_ref_num           ar_receivable_applications.application_ref_num%TYPE;
l_return_status			VARCHAR2(1);
l_msg_count			NUMBER;
l_msg_data			VARCHAR2(2000);
l_payment_set_id		NUMBER;
l_amount_due_remain_disc	NUMBER;
l_claim_reason_name		VARCHAR2(100);
l_org_return_status		VARCHAR2(1);
l_gt_return_status		VARCHAR2(1);
l_org_id			NUMBER;

-- LLCA
l_line_items_original		NUMBER;
l_line_items_remaining		NUMBER;
l_tax_original			NUMBER;
l_tax_remaining			NUMBER;
l_freight_original		NUMBER;
l_freight_remaining		NUMBER;
l_rec_charges_charged		NUMBER;
l_rec_charges_remaining		NUMBER;
l_llca_type			VARCHAR2(1);
l_group_id                      ra_customer_trx_lines.source_data_key4%TYPE;
l_sum_amount_applied		NUMBER :=0;
l_sum_disc_earn_allow           NUMBER;
l_sum_disc_max_allow           NUMBER;
l_llca_msg_data			VARCHAR2(2000);
l_llca_return_status		VARCHAR2(1);
l_llca_msg_count		NUMBER;
l_llca_app_msg_data	        VARCHAR2(2000);
l_llca_app_return_status	VARCHAR2(1);
l_llca_app_msg_count		NUMBER;
lfc_msg_data			VARCHAR2(2000);
lfc_return_status		VARCHAR2(1);
lfc_msg_count			NUMBER;
llca_ra_rec			ar_receivable_applications%rowtype;
l_llca_trx_lines_tbl		llca_trx_lines_tbl_type;
l_line_number                   NUMBER;
l_count				NUMBER;
l_ad_dflex_val_return_status    VARCHAR2(1);
l_line_attribute_rec            attribute_rec_type;
BEGIN

     /*------------------------------------+
      |   Standard start of API savepoint  |
      +------------------------------------*/
       SAVEPOINT Apply_In_Detail_PVT;

      /*--------------------------------------------------+
       |   Standard call to check for call compatibility  |
       +--------------------------------------------------*/
        IF NOT FND_API.Compatible_API_Call(
                                           l_api_version,
                                           p_api_version,
                                           l_api_name,
                                           G_PKG_NAME
                                          )
        THEN
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

      /*--------------------------------------------------------------+
       |   Initialize message list if p_init_msg_list is set to TRUE  |
       +--------------------------------------------------------------*/

 	IF FND_API.to_Boolean( p_init_msg_list )
        THEN
              FND_MSG_PUB.initialize;
        END IF;

	Original_application_info.cash_receipt_id      := p_cash_receipt_id;
	Original_application_info.receipt_number       := p_receipt_number;
	Original_application_info.customer_trx_id      := p_customer_trx_id;
	Original_application_info.trx_number           := p_trx_number;
	Original_application_info.installment          := p_installment;
	Original_application_info.customer_trx_line_id := NULL;
	Original_application_info.line_number          := NULL;
	Original_application_info.amount_applied_from:= p_amount_applied_from;
	Original_application_info.trans_to_receipt_rate
			:= p_trans_to_receipt_rate;
	Original_application_info.applied_payment_schedule_id
			:= p_applied_payment_schedule_id;
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Apply_In_Detail()+ ');
        END IF;

       /*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/
        x_return_status := FND_API.G_RET_STS_SUCCESS;

       /* SSA change */
        l_org_id            := p_org_id;
        l_org_return_status := FND_API.G_RET_STS_SUCCESS;
        ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                               p_return_status =>l_org_return_status);

IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      x_return_status := FND_API.G_RET_STS_ERROR;
ELSE
        --Verify whether LLCA is allowed for given invoice
	IF NOT arp_standard.is_llca_allowed(l_org_id,p_customer_trx_id) THEN
	  FND_MESSAGE.set_name('AR', 'AR_SUMMARIZED_DIST_NO_LLCA_RCT');
	  FND_MSG_PUB.Add;
          x_return_status := FND_API.G_RET_STS_ERROR;
	  RAISE FND_API.G_EXC_ERROR;
	END IF;

       /*-------------------------------------------------+
        | Initialize the profile option package variables |
        +-------------------------------------------------*/

          initialize_profile_globals;

      /*---------------------------------------------+
       |   ===== Dump the Input Parameters ========  |
       +---------------------------------------------*/

       IF PG_DEBUG in ('Y', 'C') THEN
        arp_util.debug('=======================================================');
        arp_util.debug('   Apply_In_Detail (    INPUT PARAMETERS ........)+    ');
        arp_util.debug('=======================================================');
        arp_util.debug('p_api_version                 =>'||to_char(p_api_version));
        arp_util.debug('p_init_msg_list               =>'||p_init_msg_list);
        arp_util.debug('p_commit                      =>'||p_commit);
        arp_util.debug('p_validation_level            =>'||to_char(p_validation_level));
        arp_util.debug('p_cash_receipt_id             =>'||to_char(p_cash_receipt_id));
        arp_util.debug('p_receipt_number              =>'||p_receipt_number);
        arp_util.debug('p_customer_trx_id             =>'||to_char(p_customer_trx_id));
        arp_util.debug('p_trx_number                  =>'||p_trx_number);
        arp_util.debug('p_installment                 =>'||p_installment);
        arp_util.debug('p_applied_payment_schedule_id =>'||to_char(p_applied_payment_schedule_id));
        arp_util.debug('p_llca_type		      =>'||p_llca_type);
        arp_util.debug('p_group_id                    =>'||p_group_id);
        arp_util.debug('p_line_amount		      =>'||to_char(p_line_amount));
        arp_util.debug('p_tax_amount		      =>'||to_char(p_tax_amount));
        arp_util.debug('p_freight_amount	      =>'||to_char(p_freight_amount));
        arp_util.debug('p_charges_amount	      =>'||to_char(p_charges_amount));
        arp_util.debug('p_amount_applied              =>'||to_char(p_amount_applied));
        arp_util.debug('p_line_discount               =>'||to_char(p_line_discount));
        arp_util.debug('p_tax_discount                =>'||to_char(p_tax_discount));
        arp_util.debug('p_freight_discount            =>'||to_char(p_freight_discount));
        arp_util.debug('p_amount_applied_from         =>'||to_char(p_amount_applied_from));
        arp_util.debug('p_trans_to_receipt_rate       =>'||to_char(p_trans_to_receipt_rate));
        arp_util.debug('p_discount                    =>'||to_char(p_discount));
        arp_util.debug('p_apply_date                  =>'||to_char(p_apply_date));
        arp_util.debug('p_apply_gl_date               =>'||to_char(p_apply_gl_date));
        arp_util.debug('p_ussgl_transaction_code      =>'||p_ussgl_transaction_code);
        arp_util.debug('p_show_closed_invoices        =>'||p_show_closed_invoices);
        arp_util.debug('p_called_from                 =>'||p_called_from);
        arp_util.debug('p_move_deferred_tax           =>'||p_move_deferred_tax);
        arp_util.debug('p_link_to_trx_hist_id         =>'||p_link_to_trx_hist_id);
        arp_util.debug('p_comments                    =>'||p_comments);
        arp_util.debug('p_payment_set_id              =>'||p_payment_set_id);
        arp_util.debug('p_application_ref_type        =>'||p_application_ref_type);
        arp_util.debug('p_application_ref_id          =>'||p_application_ref_id);
        arp_util.debug('p_application_ref_num         =>'||p_application_ref_num);
        arp_util.debug('p_secondary_application_ref_id=>'||p_secondary_application_ref_id);
        arp_util.debug('p_application_ref_reason      =>'||p_application_ref_reason);
        arp_util.debug('p_customer_reference          =>'||p_customer_reference);
        arp_util.debug('p_customer_reason             =>'||p_customer_reason);
        arp_util.debug('p_org_id                      =>'||p_org_id);
        arp_util.debug('=======================================================');
       END IF;

      /*---------------------------------------------+
       |   ========== Start of API Body ==========   |
       +---------------------------------------------*/


     l_cash_receipt_id          := p_cash_receipt_id;
     l_customer_trx_id          := p_customer_trx_id;
     l_installment              := p_installment;
     l_amount_applied           := p_amount_applied;
     l_amount_applied_from      := p_amount_applied_from;
     l_trans_to_receipt_rate    := p_trans_to_receipt_rate;
     l_discount                 := Nvl(p_line_discount,0)+ Nvl(p_tax_discount,0)
                                   + Nvl(p_freight_discount,0);
     l_apply_date               := trunc(p_apply_date);
     l_apply_gl_date            := trunc(p_apply_gl_date);
     l_customer_trx_line_id     := NULL;
     l_applied_payment_schedule_id := p_applied_payment_schedule_id;
     l_attribute_rec            := p_attribute_rec;
     l_line_attribute_rec       := p_line_attribute_rec;
     l_global_attribute_rec     := p_global_attribute_rec;
     l_payment_set_id           := p_payment_set_id;

     l_llca_type                := p_llca_type;
     l_group_id                 := p_group_id; /* Bug 5284890 */
     l_line_amount              := p_line_amount;
     l_tax_amount               := p_tax_amount;
     l_freight_amount           := p_freight_amount;
     l_charges_amount           := p_charges_amount;
     l_line_discount            := p_line_discount;
     l_tax_discount             := p_tax_discount;
     l_freight_discount         := p_freight_discount;
     l_ad_dflex_val_return_status := FND_API.G_RET_STS_SUCCESS;

     ar_receipt_lib_pvt.populate_llca_gt(
	   p_customer_trx_id              => l_customer_trx_id,
	   p_llca_type                    => l_llca_type,
           p_llca_trx_lines_tbl		  => p_llca_trx_lines_tbl,
	   p_line_amount		  => l_line_amount,
	   p_tax_amount			  => l_tax_amount,
  	   p_freight_amount		  => l_freight_amount,
	   p_charges_amount		  => l_charges_amount,
	   p_line_discount		  => l_line_discount,
	   p_tax_discount		  => l_tax_discount,
	   p_freight_discount		  => l_freight_discount,
	   p_amount_applied		  => l_amount_applied,
	   p_amount_applied_from	  => l_amount_applied_from,
           p_return_status                => l_gt_return_status);

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('Apply_In_Detail: ' || 'Plsql table Return_status = '||l_gt_return_status);
   END IF;

       IF l_gt_return_status <> FND_API.G_RET_STS_SUCCESS
       THEN
            ROLLBACK TO Apply_In_Detail_PVT;
            x_return_status := FND_API.G_RET_STS_ERROR ;

	    IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Apply_In_Detail: ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
            END IF;
            Return;
        END IF;

         /*-----------------------+
          |                       |
          |ID TO VALUE CONVERSION |
          |                       |
          +-----------------------*/
      ar_receipt_lib_pvt.Default_appln_ids(
       p_cash_receipt_id              => l_cash_receipt_id,
       p_receipt_number               => p_receipt_number,
       p_customer_trx_id              => l_customer_trx_id,
       p_trx_number                   => p_trx_number,
       p_customer_trx_line_id	      => l_customer_trx_line_id,
       p_line_number                  => l_line_number,
       p_installment                  => l_installment,
       p_applied_payment_schedule_id  => l_applied_payment_schedule_id,
       p_llca_type                    => l_llca_type,
       p_group_id                     => l_group_id,
       p_return_status                => l_def_ids_return_status);

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('Apply_In_Detail: ' || 'Defaulting Ids Return_status = '||l_def_ids_return_status);
   END IF;

 -- Inorder to retained the errors on GT, we need to return the call without rollback.
 IF l_def_ids_return_status <> FND_API.G_RET_STS_SUCCESS
 Then
     select count(1) into l_count from ar_llca_trx_errors_gt
     where customer_trx_id = p_customer_trx_id;

     If l_count <> 0 AND p_llca_type = 'L'
     THEN
             x_return_status := FND_API.G_RET_STS_ERROR ;

             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Apply_In_Detail: ' || 'Error(s) occurred in PLSQL table parameters. ');
             END IF;
             Return;
     END IF;
  END IF ;
          /*---------------------+
           |                     |
           |    DEFAULTING       |
           |                     |
           +---------------------*/
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('Apply_In_Detail: ' || 'l_amount_applied_from :'||to_char(l_amount_applied_from));
   END IF;
         ar_receipt_lib_pvt.Default_application_info(
              p_cash_receipt_id             => l_cash_receipt_id   ,
              p_cr_gl_date                  => l_cr_gl_date,
              p_cr_date                     => l_cr_date,
              p_cr_amount                   => l_cr_amount,
              p_cr_unapp_amount             => l_cr_unapp_amount,
              p_cr_currency_code            => l_cr_currency_code ,
              p_customer_trx_id             => l_customer_trx_id,
              p_installment                 => l_installment,
              p_show_closed_invoices        => p_show_closed_invoices,
              p_customer_trx_line_id        => l_customer_trx_line_id,
              p_trx_due_date                => l_trx_due_date,
              p_trx_currency_code           => l_trx_currency_code,
              p_trx_date                    => l_trx_date,
              p_trx_gl_date                 => l_trx_gl_date,
              p_apply_gl_date               => l_apply_gl_date,
              p_calc_discount_on_lines_flag => l_calc_discount_on_lines_flag,
              p_partial_discount_flag       => l_partial_discount_flag,
              p_allow_overappln_flag        => l_allow_overappln_flag,
              p_natural_appln_only_flag     => l_natural_appln_only_flag,
              p_creation_sign               => l_creation_sign ,
              p_cr_payment_schedule_id      => l_cr_payment_schedule_id ,
              p_applied_payment_schedule_id => l_applied_payment_schedule_id ,
              p_term_id                     => l_term_id ,
              p_amount_due_original         => l_amount_due_original ,
	      p_amount_due_remaining        => l_amount_due_remaining,
              p_trx_line_amount             => l_trx_line_amount,
              p_discount                    => l_discount,
              p_apply_date                  => l_apply_date ,
              p_discount_max_allowed        => l_discount_max_allowed,
              p_discount_earned_allowed     => l_discount_earned_allowed,
              p_discount_earned             => l_discount_earned,
              p_discount_unearned           => l_discount_unearned ,
              p_new_amount_due_remaining    => l_new_amount_due_remaining,
              p_remittance_bank_account_id  => l_remit_bank_acct_use_id,
              p_receipt_method_id           => l_receipt_method_id,
              p_amount_applied              => l_amount_applied,
              p_amount_applied_from         => l_amount_applied_from,
              p_trans_to_receipt_rate       => l_trans_to_receipt_rate,
	      p_llca_type		    => l_llca_type,
              p_line_amount		    => l_line_amount,
              p_tax_amount		    => l_tax_amount,
              p_freight_amount		    => l_freight_amount,
              p_charges_amount		    => l_charges_amount,
              p_line_discount               => l_line_discount,
              p_tax_discount                => l_tax_discount,
              p_freight_discount            => l_freight_discount,
	      p_line_items_original	    => l_line_items_original,
	      p_line_items_remaining	    => l_line_items_remaining,
	      p_tax_original		    => l_tax_original,
	      p_tax_remaining		    => l_tax_remaining,
	      p_freight_original	    => l_freight_original,
	      p_freight_remaining	    => l_freight_remaining,
	      p_rec_charges_charged	    => l_rec_charges_charged,
	      p_rec_charges_remaining	    => l_rec_charges_remaining,
              p_called_from                 => p_called_from,
              p_return_status               => l_def_return_status
               );
IF PG_DEBUG in ('Y', 'C') THEN
   arp_util.debug('Apply_In_Detail: ' || 'l_amount_applied      :'||to_char(l_amount_applied));
   arp_util.debug('Apply_In_Detail: ' || 'l_amount_applied_from :'||to_char(l_amount_applied_from));
   arp_util.debug('Apply_In_Detail: ' || 'l_new_amount_due_remaining :'||to_char(l_new_amount_due_remaining));
   arp_util.debug('Apply_In_Detail: ' || 'Defaulting Return_status = '||l_def_return_status);
END IF;

          /*---------------------+
           |                     |
           |    VALIDATION       |
           |                     |
           +---------------------*/
 IF l_def_return_status = FND_API.G_RET_STS_SUCCESS  AND
    l_def_ids_return_status = FND_API.G_RET_STS_SUCCESS
 THEN
          ar_receipt_val_pvt.Validate_Application_info(
               p_apply_date                  => l_apply_date,
               p_cr_date                     => l_cr_date,
               p_trx_date                    => l_trx_date,
               p_apply_gl_date               => l_apply_gl_date  ,
               p_trx_gl_date                 => l_trx_gl_date,
               p_cr_gl_date                  => l_cr_gl_date,
               p_amount_applied              => l_amount_applied,
               p_applied_payment_schedule_id => l_applied_payment_schedule_id,
               p_customer_trx_line_id        => l_customer_trx_line_id,
               p_inv_line_amount             => l_trx_line_amount,
               p_creation_sign               => l_creation_sign,
               p_allow_overappln_flag	     => l_allow_overappln_flag,
               p_natural_appln_only_flag     => l_natural_appln_only_flag,
               p_discount                    => l_discount  ,
               p_amount_due_remaining        => l_amount_due_remaining,
               p_amount_due_original         => l_amount_due_original,
               p_trans_to_receipt_rate       => l_trans_to_receipt_rate,
               p_cr_currency_code            => l_cr_currency_code ,
               p_trx_currency_code           => l_trx_currency_code,
               p_amount_applied_from         => l_amount_applied_from,
               p_cr_unapp_amount             => l_cr_unapp_amount ,
               p_partial_discount_flag       => l_partial_discount_flag ,
               p_discount_earned_allowed     => l_discount_earned_allowed,
               p_discount_max_allowed        => l_discount_max_allowed ,
               p_move_deferred_tax           => p_move_deferred_tax,
 	       p_llca_type		     => l_llca_type,
 	       p_line_amount		     => l_line_amount,
	       p_tax_amount		     => l_tax_amount,
	       p_freight_amount		     => l_freight_amount,
	       p_charges_amount		     => l_charges_amount,
               p_line_discount               => l_line_discount,
               p_tax_discount                => l_tax_discount,
               p_freight_discount            => l_freight_discount,
	       p_line_items_original	     => l_line_items_original,
	       p_line_items_remaining	     => l_line_items_remaining,
	       p_tax_original		     => l_tax_original,
	       p_tax_remaining		     => l_tax_remaining,
	       p_freight_original	     => l_freight_original,
	       p_freight_remaining	     => l_freight_remaining,
	       p_rec_charges_charged	     => l_rec_charges_charged,
	       p_rec_charges_remaining	     => l_rec_charges_remaining,
               p_return_status               => l_val_return_status
                          );

               IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply_In_Detail: ' || 'Validation Return_status = '||l_val_return_status);
               END IF;

        /* Bug 9501452 Bypass DFF validation in case call is for AP/AR Netting*/
        IF nvl(l_receipt_method_id,-99) <> -1 THEN

        --validate and default the flexfields
        ar_receipt_lib_pvt.Validate_Desc_Flexfield(
                                        l_attribute_rec,
                                        'AR_RECEIVABLE_APPLICATIONS',
                                        l_dflex_val_return_status
                                                );


IF PG_DEBUG in ('Y', 'C') THEN
   arp_util.debug('Apply_In_Detail: ' || 'l_line_amount         :'||to_char(l_line_amount));
   arp_util.debug('Apply_In_Detail: ' || 'l_tax_amount          :'||to_char(l_tax_amount));
   arp_util.debug('Apply_In_Detail: ' || 'l_freight_amount      :'||to_char(l_freight_amount));
   arp_util.debug('Apply_In_Detail: ' || 'l_charges_amount      :'||to_char(l_charges_amount));
   arp_util.debug('Apply_In_Detail: ' || 'l_amount_applied      :'||to_char(l_amount_applied));
   arp_util.debug('Apply_In_Detail: ' || 'l_line_discount       :'||to_char(l_line_discount));
   arp_util.debug('Apply_In_Detail: ' || 'l_tax_discount        :'||to_char(l_tax_discount));
   arp_util.debug('Apply_In_Detail: ' || 'l_freight_discount    :'||to_char(l_freight_discount));
   arp_util.debug('Apply_In_Detail: ' || 'l_amount_applied_from :'||to_char(l_amount_applied_from));
   arp_util.debug('Apply_In_Detail: ' || 'Validate Return_status = '||l_val_return_status);
End If;
--bug7311231
       --validate and default the flexfields
       IF l_llca_type = 'S' OR l_llca_type = 'G'
        OR (l_llca_type = 'L' AND p_llca_trx_lines_tbl.COUNT = 0) THEN
          ar_receipt_lib_pvt.Validate_Desc_Flexfield(
                                       l_line_attribute_rec,
                                       'AR_ACTIVITY_DETAILS',
                                       l_ad_dflex_val_return_status
                                               );
       END IF;
       IF PG_DEBUG in ('Y', 'C') THEN
        arp_util.debug('Desc Flexfield Validation return status: '||l_ad_dflex_val_return_status);
       END IF;

       END IF;

       -- Validate the LLCA data and populate to AD and GT
       -- bug7311231, Modified the parameter list passing the flexfield info.
       ar_receipt_val_pvt.validate_llca_insert_ad(
	p_cash_receipt_id        => l_cash_receipt_id
	,p_customer_trx_id       => l_customer_trx_id
        ,p_customer_trx_line_id  => l_customer_trx_line_id
	,p_cr_unapp_amount       => l_cr_unapp_amount
        ,p_llca_type             => l_llca_type
        ,p_group_id              => l_group_id
        ,p_line_amount           => l_line_amount
	,p_tax_amount            => l_tax_amount
	,p_freight_amount        => l_freight_amount
	,p_charges_amount        => l_charges_amount
	,p_line_discount         => l_line_discount
	,p_tax_discount          => l_tax_discount
	,p_freight_discount      => l_freight_discount
	,p_amount_applied        => l_amount_applied
	,p_amount_applied_from   => l_amount_applied_from
	,p_trans_to_receipt_rate => l_trans_to_receipt_rate
	,p_invoice_currency_code => l_trx_currency_code
	,p_receipt_currency_code => l_cr_currency_code
	,p_earned_discount       => l_discount_earned_allowed
	,p_unearned_discount     => l_discount_unearned
	,p_max_discount          => l_discount_max_allowed
	,p_line_items_original	 => l_line_items_original
	,p_line_items_remaining	 => l_line_items_remaining
	,p_tax_original		 => l_tax_original
	,p_tax_remaining	 => l_tax_remaining
	,p_freight_original	 => l_freight_original
	,p_freight_remaining	 => l_freight_remaining
	,p_rec_charges_charged	 => l_rec_charges_charged
	,p_rec_charges_remaining => l_rec_charges_remaining
	,p_attribute_category	 => l_line_attribute_rec.attribute_category
	,p_attribute1		 => l_line_attribute_rec.attribute1
        ,p_attribute2		 => l_line_attribute_rec.attribute2
        ,p_attribute3		 => l_line_attribute_rec.attribute3
        ,p_attribute4	  	 => l_line_attribute_rec.attribute4
        ,p_attribute5		 => l_line_attribute_rec.attribute5
        ,p_attribute6		 => l_line_attribute_rec.attribute6
        ,p_attribute7		 => l_line_attribute_rec.attribute7
        ,p_attribute8		 => l_line_attribute_rec.attribute8
        ,p_attribute9		 => l_line_attribute_rec.attribute9
        ,p_attribute10		 => l_line_attribute_rec.attribute10
        ,p_attribute11		 => l_line_attribute_rec.attribute11
        ,p_attribute12		 => l_line_attribute_rec.attribute12
        ,p_attribute13		 => l_line_attribute_rec.attribute13
        ,p_attribute14		 => l_line_attribute_rec.attribute14
        ,p_attribute15		 => l_line_attribute_rec.attribute15
        ,p_comments		 => p_comments
	,p_return_status	 => l_llca_return_status
	,p_msg_count		 => l_llca_msg_count
	,p_msg_data		 => l_llca_msg_data
	);
   END IF;

       IF l_llca_return_status    = 'X'
       Then
             x_return_status := FND_API.G_RET_STS_ERROR ;
             Return;
       END IF ;

       IF l_def_ids_return_status <> FND_API.G_RET_STS_SUCCESS OR
          l_val_return_status     <> FND_API.G_RET_STS_SUCCESS OR
          l_def_return_status     <> FND_API.G_RET_STS_SUCCESS  OR
          l_dflex_val_return_status <> FND_API.G_RET_STS_SUCCESS OR
	  l_ad_dflex_val_return_status <> FND_API.G_RET_STS_SUCCESS OR
          l_app_validation_return_status <> FND_API.G_RET_STS_SUCCESS OR
          l_llca_return_status    <> FND_API.G_RET_STS_SUCCESS  THEN
          x_return_status := FND_API.G_RET_STS_ERROR;
       END IF;

       /* Bug fix 3435834
          The messages should be retrieved irrespective of the return status */
         FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                        p_count => x_msg_count,
                                        p_data  => x_msg_data
                                       );

       IF x_return_status <> FND_API.G_RET_STS_SUCCESS
       THEN

            ROLLBACK TO Apply_In_Detail_PVT;

             x_return_status := FND_API.G_RET_STS_ERROR ;

             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Apply_In_Detail: ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
             END IF;
             Return;
        END IF;

     -- Validate llca and insert application
     ar_receipt_val_pvt.validate_llca_insert_app(
	p_cash_receipt_id       => l_cash_receipt_id
	,p_customer_trx_id       => l_customer_trx_id
        ,p_disc_earn_allowed     => l_discount_earned_allowed
        ,p_disc_max_allowed      => l_discount_max_allowed
	,p_return_status	 => l_llca_app_return_status
	,p_msg_count		 => l_llca_app_msg_count
	,p_msg_data		 => l_llca_app_msg_data
         );



       --default and validate the global descriptive flexfield
        jg_ar_receivable_applications.apply(
                  p_apply_before_after        => 'BEFORE',
                  p_global_attribute_category => l_global_attribute_rec.global_attribute_category,
                  p_set_of_books_id           => arp_global.set_of_books_id,
                  p_cash_receipt_id           => l_cash_receipt_id,
                  p_receipt_date              => l_cr_date,
                  p_applied_payment_schedule_id => l_applied_payment_schedule_id,
                  p_amount_applied              => l_sum_amount_applied,
                  p_unapplied_amount            => (l_cr_unapp_amount
                                    -l_sum_amount_applied),
                  p_due_date                    => l_trx_due_date,
                  p_receipt_method_id           => l_receipt_method_id,
                  p_remittance_bank_account_id  => l_remit_bank_acct_use_id,
                  p_global_attribute1           => l_global_attribute_rec.global_attribute1,
                  p_global_attribute2           => l_global_attribute_rec.global_attribute2,
                  p_global_attribute3           => l_global_attribute_rec.global_attribute3,
                  p_global_attribute4           => l_global_attribute_rec.global_attribute4,
                  p_global_attribute5           => l_global_attribute_rec.global_attribute5,
                  p_global_attribute6           => l_global_attribute_rec.global_attribute6,
                  p_global_attribute7           => l_global_attribute_rec.global_attribute7,
                  p_global_attribute8           => l_global_attribute_rec.global_attribute8,
                  p_global_attribute9           => l_global_attribute_rec.global_attribute9,
                  p_global_attribute10          => l_global_attribute_rec.global_attribute10,
                  p_global_attribute11          => l_global_attribute_rec.global_attribute11,
                  p_global_attribute12          => l_global_attribute_rec.global_attribute12,
                  p_global_attribute13          => l_global_attribute_rec.global_attribute13,
                  p_global_attribute14          => l_global_attribute_rec.global_attribute14,
                  p_global_attribute15          => l_global_attribute_rec.global_attribute15,
                  p_global_attribute16          => l_global_attribute_rec.global_attribute16,
                  p_global_attribute17          => l_global_attribute_rec.global_attribute17,
                  p_global_attribute18          => l_global_attribute_rec.global_attribute18,
                  p_global_attribute19          => l_global_attribute_rec.global_attribute19,
                  p_global_attribute20          => l_global_attribute_rec.global_attribute20,
                  p_return_status               => l_gdflex_return_status);

END IF;

       IF l_llca_app_return_status <> FND_API.G_RET_STS_SUCCESS OR
          l_gdflex_return_status  <> FND_API.G_RET_STS_SUCCESS THEN
            x_return_status := FND_API.G_RET_STS_ERROR;
       END IF;

       /* Bug fix 3435834
          The messages should be retrieved irrespective of the return status */
         FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                        p_count => x_msg_count,
                                        p_data  => x_msg_data
                                       );

       IF x_return_status <> FND_API.G_RET_STS_SUCCESS
         THEN

            ROLLBACK TO Apply_In_Detail_PVT;

             x_return_status := FND_API.G_RET_STS_ERROR ;

             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Apply_In_Detail: ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
             END IF;
             Return;
        END IF;

      --Dump the input variables to the entity handler
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('Apply_In_Detail: ' || 'l_cr_payment_schedule_id      : '||to_char(l_cr_payment_schedule_id));
       arp_util.debug('Apply_In_Detail: ' || 'l_applied_payment_schedule_id : '||to_char(l_applied_payment_schedule_id));
       arp_util.debug('Apply_In_Detail: ' || 'l_amount_applied              : '||to_char(l_amount_applied));
       arp_util.debug('Apply_In_Detail: ' || 'l_amount_applied_from         : '||to_char(l_amount_applied_from));
       arp_util.debug('Apply_In_Detail: ' || 'l_trans_to_receipt_rate       : '||to_char(l_trans_to_receipt_rate));
       arp_util.debug('Apply_In_Detail: ' || 'l_trx_currency_code           : '||l_trx_currency_code);
       arp_util.debug('Apply_In_Detail: ' || 'l_cr_currency_code            : '||l_cr_currency_code);
       arp_util.debug('Apply_In_Detail: ' || 'l_discount_earned             : '||to_char(l_discount_earned));
       arp_util.debug('Apply_In_Detail: ' || 'l_discount_unearned           : '||to_char(l_discount_unearned));
       arp_util.debug('l_apply_date                  : '||to_char(l_apply_date,'DD-MON-YY'));
       arp_util.debug('l_apply_gl_date               : '||to_char(l_apply_gl_date,'DD-MON-YY'));
       arp_util.debug('Apply_In_Detail: ' || 'l_customer_trx_line_id        : '||to_char(l_customer_trx_line_id));
    END IF;

       --lock the receipt before calling the entity handler
       arp_cash_receipts_pkg.nowaitlock_p(p_cr_id => l_cash_receipt_id);

       -- lock the payment schedule of the applied transaction
       arp_ps_pkg.nowaitlock_p (p_ps_id => l_applied_payment_schedule_id);

       l_return_status := FND_API.G_RET_STS_SUCCESS;

   BEGIN
	     --call the entity handler
	      arp_process_det_pkg.final_commit(
		p_gl_date  => l_apply_gl_date,
 		p_apply_date => l_apply_date ,
	        p_attribute_category => l_attribute_rec.attribute_category,
		p_attribute1 => l_attribute_rec.attribute1,
		p_attribute2 => l_attribute_rec.attribute2,
		p_attribute3 => l_attribute_rec.attribute3,
		p_attribute4 => l_attribute_rec.attribute4,
		p_attribute5 => l_attribute_rec.attribute5,
		p_attribute6 => l_attribute_rec.attribute6,
		p_attribute7 => l_attribute_rec.attribute7,
		p_attribute8 => l_attribute_rec.attribute8,
		p_attribute9 => l_attribute_rec.attribute9,
		p_attribute10 => l_attribute_rec.attribute10,
		p_attribute11 => l_attribute_rec.attribute11,
		p_attribute12 => l_attribute_rec.attribute12,
		p_attribute13 => l_attribute_rec.attribute13,
		p_attribute14 => l_attribute_rec.attribute14,
		p_attribute15 => l_attribute_rec.attribute15,
	        p_global_attribute_category => p_global_attribute_rec.global_attribute_category,
		p_global_attribute1 => p_global_attribute_rec.global_attribute1,
	        p_global_attribute2 => p_global_attribute_rec.global_attribute2,
		p_global_attribute3 => p_global_attribute_rec.global_attribute3,
	        p_global_attribute4 => p_global_attribute_rec.global_attribute4,
		p_global_attribute5 => p_global_attribute_rec.global_attribute5,
	        p_global_attribute6 => p_global_attribute_rec.global_attribute6,
		p_global_attribute7 => p_global_attribute_rec.global_attribute7,
	        p_global_attribute8 => p_global_attribute_rec.global_attribute8,
		p_global_attribute9 => p_global_attribute_rec.global_attribute9,
	        p_global_attribute10 => p_global_attribute_rec.global_attribute10,
		p_global_attribute11 => p_global_attribute_rec.global_attribute11,
	        p_global_attribute12 => p_global_attribute_rec.global_attribute12,
		p_global_attribute13 => p_global_attribute_rec.global_attribute13,
	        p_global_attribute14 => p_global_attribute_rec.global_attribute14,
		p_global_attribute15 => p_global_attribute_rec.global_attribute15,
	        p_global_attribute16 => p_global_attribute_rec.global_attribute16,
	        p_global_attribute17 => p_global_attribute_rec.global_attribute17,
		p_global_attribute18 => p_global_attribute_rec.global_attribute18,
	        p_global_attribute19 => p_global_attribute_rec.global_attribute19,
		p_global_attribute20 => p_global_attribute_rec.global_attribute20,
	        p_comments => p_comments ,
	        p_amount_applied_from => l_amount_applied_from , /* Bug 5438627 */
	        p_trans_to_receipt_rate => l_trans_to_receipt_rate ,
		x_ra_rec             =>llca_ra_rec,
		x_return_status => lfc_return_status,
		x_msg_count => lfc_msg_count,
		x_msg_data  => lfc_msg_data
		);
               --Bug fix for 5645383
               IF lfc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                 x_return_status := FND_API.G_RET_STS_ERROR;
               END IF;
               FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                        p_count => x_msg_count,
                                        p_data  => x_msg_data
                                       );
               IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                 ROLLBACK TO Apply_In_Detail_PVT;
                 x_return_status := FND_API.G_RET_STS_ERROR ;
                 IF PG_DEBUG in ('Y', 'C') THEN
                    arp_util.debug('Apply_In_Detail: ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
                 END IF;
                 Return;
               END IF;

    -- Assign receivable_application_id to package global variable
      -- So, it can used to perform follow on operation on given application

		apply_out_rec.receivable_application_id := llca_ra_rec.receivable_application_id;

		update ar_activity_details
	         set source_table = 'RA',
		     source_id = llca_ra_rec.receivable_application_id
	       where source_id is null
	         and nvl(current_activity_flag, 'Y') = 'Y' -- Bug 7241111
	         and cash_receipt_id = l_cash_receipt_id
	         and customer_trx_line_id in (select customer_trx_line_id
						from ra_customer_trx_lines
	                                    where customer_trx_id = l_customer_trx_id);

                -- Clean the GT Table even though the table get refreshed in the commit stage.
                 delete from ar_llca_trx_lines_gt
                 where customer_trx_id = l_customer_trx_id;


   EXCEPTION
     WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN
                     ROLLBACK TO Apply_In_Detail_PVT;

                      --  Display_Parameters;
                      x_return_status := FND_API.G_RET_STS_ERROR ;
                       FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                       FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','ARP_PROCESS_APPLICATION.RECEIPT_APPLICATION '||SQLERRM);
                       FND_MSG_PUB.Add;

                       FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                                                  p_count  =>  x_msg_count,
                                                  p_data   => x_msg_data
                                                );
                      RETURN;
                ELSE
                     ROLLBACK TO Apply_In_Detail_PVT;
                   RAISE;
                END IF;
   END;

   /* Bug 3773036: raising error if return status is not success */
   IF l_return_status = FND_API.G_RET_STS_ERROR THEN
      RAISE FND_API.G_EXC_ERROR;
   END IF;
   IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;

      jg_ar_receivable_applications.apply(
                  p_apply_before_after        => 'AFTER',
                  p_global_attribute_category => l_global_attribute_rec.global_attribute_category,
                  p_set_of_books_id           => null,
                  p_cash_receipt_id           => null,
                  p_receipt_date              => null,
                  p_applied_payment_schedule_id => l_applied_payment_schedule_id,
                  p_amount_applied              => null,
                  p_unapplied_amount            => null,
                  p_due_date                    => null,
                  p_receipt_method_id           => null,
                  p_remittance_bank_account_id  => null,
                  p_global_attribute1           => l_global_attribute_rec.global_attribute1,
                  p_global_attribute2           => l_global_attribute_rec.global_attribute2,
                  p_global_attribute3           => l_global_attribute_rec.global_attribute3,
                  p_global_attribute4           => l_global_attribute_rec.global_attribute4,
                  p_global_attribute5           => l_global_attribute_rec.global_attribute5,
                  p_global_attribute6           => l_global_attribute_rec.global_attribute6,
                  p_global_attribute7           => l_global_attribute_rec.global_attribute7,
                  p_global_attribute8           => l_global_attribute_rec.global_attribute8,
                  p_global_attribute9           => l_global_attribute_rec.global_attribute9,
                  p_global_attribute10          => l_global_attribute_rec.global_attribute10,
                  p_global_attribute11          => l_global_attribute_rec.global_attribute11,
                  p_global_attribute12          => l_global_attribute_rec.global_attribute12,
                  p_global_attribute13          => l_global_attribute_rec.global_attribute13,
                  p_global_attribute14          => l_global_attribute_rec.global_attribute14,
                  p_global_attribute15          => l_global_attribute_rec.global_attribute15,
                  p_global_attribute16          => l_global_attribute_rec.global_attribute16,
                  p_global_attribute17          => l_global_attribute_rec.global_attribute17,
                  p_global_attribute18          => l_global_attribute_rec.global_attribute18,
                  p_global_attribute19          => l_global_attribute_rec.global_attribute19,
                  p_global_attribute20          => l_global_attribute_rec.global_attribute20,
                  p_return_status               => l_gdflex_return_status);
               --Bug fix for 5645383
               IF l_gdflex_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                 x_return_status := FND_API.G_RET_STS_ERROR;
               END IF;
               FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                        p_count => x_msg_count,
                                        p_data  => x_msg_data
                                       );
               IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                 ROLLBACK TO Apply_In_Detail_PVT;
                 x_return_status := FND_API.G_RET_STS_ERROR ;
                 IF PG_DEBUG in ('Y', 'C') THEN
                    arp_util.debug('Apply_In_Detail: ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
                 END IF;
                 Return;
               END IF;

       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Apply_In_Detail: ' || 'committing');
            END IF;
              Commit;
        END IF;
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Apply_In_Detail ()- ');
        END IF;
EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply_In_Detail: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Apply_In_Detail: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Apply_In_Detail_PVT;
                x_return_status := FND_API.G_RET_STS_ERROR ;

               -- Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply_In_Detail: ' || SQLERRM, G_MSG_ERROR);
                END IF;
                ROLLBACK TO Apply_In_Detail_PVT;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

               --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN

                      ROLLBACK TO Apply_In_Detail_PVT;

                      --If only one error message on the stack,
                      --retrive it

                      x_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','APPLY : '||SQLERRM);
                      FND_MSG_PUB.Add;

                      FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                                 p_count  =>  x_msg_count,
                                                 p_data   => x_msg_data
                                                );

                      RETURN;

                ELSE
                      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','APPLY : '||SQLERRM);
                      FND_MSG_PUB.Add;
                END IF;

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply_In_Detail: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Apply_In_Detail: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Apply_In_Detail_PVT;

                IF      FND_MSG_PUB.Check_Msg_Level
                THEN
                FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME,
                                        l_api_name
                                       );
                END IF;

             --   Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );
END Apply_In_Detail;

PROCEDURE Unapply(
      -- Standard API parameters.
      p_api_version                  IN  NUMBER,
      p_init_msg_list                IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit                       IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level             IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status                OUT NOCOPY VARCHAR2,
      x_msg_count                    OUT NOCOPY NUMBER,
      x_msg_data                     OUT NOCOPY VARCHAR2,
   -- *** Receipt Info. parameters *****
      p_receipt_number               IN  ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      p_cash_receipt_id              IN  ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
      p_trx_number                   IN  ra_customer_trx.trx_number%TYPE DEFAULT NULL,
      p_customer_trx_id              IN  ra_customer_trx.customer_trx_id%TYPE DEFAULT NULL,
      p_installment                  IN  ar_payment_schedules.terms_sequence_number%TYPE DEFAULT NULL,
      p_applied_payment_schedule_id  IN  ar_payment_schedules.payment_schedule_id%TYPE DEFAULT NULL,
      p_receivable_application_id    IN  ar_receivable_applications.receivable_application_id%TYPE DEFAULT NULL,
      p_reversal_gl_date             IN  ar_receivable_applications.reversal_gl_date%TYPE DEFAULT NULL,
      p_called_from                  IN  VARCHAR2 DEFAULT NULL,
      p_cancel_claim_flag            IN  VARCHAR2 DEFAULT 'Y',
      p_org_id             IN NUMBER  DEFAULT NULL
      )  IS
l_api_name       CONSTANT VARCHAR2(20) := 'Unapply';
l_api_version    CONSTANT NUMBER       := 1.0;

l_customer_trx_id              NUMBER;
l_applied_payment_schedule_id  NUMBER;
l_cash_receipt_id              NUMBER;
l_receivable_application_id    NUMBER;
l_reversal_gl_date             DATE;
l_apply_gl_date                DATE;
l_bal_due_remaining            NUMBER;
l_receipt_gl_date              DATE;
l_val_return_status            VARCHAR2(1);
l_derive_ids_ret_status        VARCHAR2(1);
l_glob_return_status           VARCHAR2(1);
l_clm_return_status            VARCHAR2(1);
l_application_ref_type         VARCHAR2(30);
l_secondary_app_ref_id         NUMBER;
l_amount_applied               NUMBER;
l_cr_unapp_amount              NUMBER;/* Added for 3119391 */
l_org_return_status VARCHAR2(1);
l_org_id                           NUMBER;
l_upg_flag                 varchar2(10); /*ADDED FOR BUG 	17326589*/
L_IGI_UPGRADE_DATA_FLAG     VARCHAR2(2); /*  Bug 18147460 */

BEGIN
       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

        SAVEPOINT Unapply_PVT;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;
       /*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        x_return_status := FND_API.G_RET_STS_SUCCESS;

       /*--------------------------------------------------------------+
        |   Initialize message list if p_init_msg_list is set to TRUE  |
        +--------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
          THEN
              FND_MSG_PUB.initialize;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('ar_receipt_api.Unapply()+ ');
        END IF;

         Original_unapp_info.trx_number := p_trx_number;
         Original_unapp_info.customer_trx_id := p_customer_trx_id;
         Original_unapp_info.applied_ps_id := p_applied_payment_schedule_id;
         Original_unapp_info.cash_receipt_id := p_cash_receipt_id;
         Original_unapp_info.receipt_number := p_receipt_number;
         Original_unapp_info.receivable_application_id := p_receivable_application_id;

/* SSA change */
       l_org_id            := p_org_id;
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;
       ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);
 IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
 ELSE

        /*-------------------------------------------------+
         | Initialize the profile option package variables |
         +-------------------------------------------------*/

           initialize_profile_globals;

       /*---------------------------------------------+
        |   ========== Start of API Body ==========   |
        +---------------------------------------------*/

        --Assign IN parameter values to local variables
        --which are also used as assignment targets.

         l_customer_trx_id := p_customer_trx_id;
         l_applied_payment_schedule_id := p_applied_payment_schedule_id;
         l_cash_receipt_id   := p_cash_receipt_id;
         l_receivable_application_id  := p_receivable_application_id;
         l_reversal_gl_date := trunc(p_reversal_gl_date);


        --Derive the id's for the entered values and if both the
        --values and the id's superceed the values

         ar_receipt_lib_pvt.Derive_unapp_ids(
                               p_trx_number ,
                               l_customer_trx_id ,
                               p_installment ,
                               l_applied_payment_schedule_id ,
                               p_receipt_number ,
                               l_cash_receipt_id ,
                               l_receivable_application_id,
                               p_called_from,
                               l_apply_gl_date,
                               l_derive_ids_ret_status
                                  );
         /*Added parameter l_cr_unapp_amount for bug 3119391 */
         ar_receipt_lib_pvt.Default_unapp_info(
                                l_receivable_application_id,
                                l_apply_gl_date,
                                l_cash_receipt_id,
                                l_reversal_gl_date,
                                l_receipt_gl_date,
				l_cr_unapp_amount);


         /*Added parameter l_cr_unapp_amount for bug 3119391 */
         ar_receipt_val_pvt.validate_unapp_info(
           l_receipt_gl_date,
           l_receivable_application_id, /* Bug fix 3266712 */
           l_reversal_gl_date,
           l_apply_gl_date,
           l_cr_unapp_amount,
           l_val_return_status);

		  /*Bug 16789203 Adding validation to prevent the reversal of the
         Receipt for Receipts where data has not been converted   */
		arp_util.debug('Before calling arp_acct_event_pkg.upgrade_status_per_doc, inside Unapply');

/*Bug 17326589*/
If p_called_from not in ('AUTORECAPI','AUTORECAPI2')
then

Begin
select 'Y' into l_upg_flag FROM DUAL
where exists(
select 'X'
FROM xla_transaction_entities_upg  xla, ar_cash_receipts_all cr
WHERE nvl(source_id_int_1,-99) = l_cash_receipt_id
AND xla.ledger_id = cr.SET_OF_BOOKS_ID
AND cr.cash_receipt_id = l_cash_receipt_id
AND xla.entity_code = 'RECEIPTS'
AND xla.upg_batch_id IS NOT NULL
AND xla.application_id=222
AND xla.upg_source_application_id = 222);

EXCEPTION
WHEN OTHERS THEN
l_upg_flag := 'N' ;
END;


If (nvl(l_upg_flag,'N') = 'Y' )
then
    Declare
        x_upgrade_status    VARCHAR2(100);
		x_return_status1		VARCHAR2(100);
		x_msg_count1		    NUMBER;
		x_msg_data1		    VARCHAR2(2000);
        l_msg_data1           VARCHAR2(2000);
    Begin

	arp_acct_event_pkg.upgrade_status_per_doc
		 (p_init_msg_list     => 'F', --BUG 20625046
		  p_entity_code       => 'RECEIPTS',
		  p_source_int_id     => l_cash_receipt_id,
		  x_upgrade_status    => x_upgrade_status,
		  x_return_status    => x_return_status1,
		  x_msg_count         => x_msg_count1,
		  x_msg_data          => x_msg_data1
		  );
		IF x_upgrade_status = 'N' THEN
			  arp_util.debug('Data2 has not been converted, Can not REVERSED');
			  FND_MESSAGE.SET_NAME('AR','AR_NOT_FULLY_UPG_DOC');
			  FND_MSG_PUB.ADD;
			  l_val_return_status:= FND_API.G_RET_STS_ERROR;
		  END IF;

		 IF x_return_status1 <> 'S' THEN
			  IF x_msg_count1 > 1 THEN
				  FOR i IN 1..x_msg_count1 LOOP
				  l_msg_data1 := SUBSTRB(l_msg_data1 ||FND_MSG_PUB.Get(-2)||'-',1,2000);
				  END LOOP;
				  ELSE
				  l_msg_data1 := x_msg_data1;
			  END IF;
		  arp_util.debug('Exception2 in arp_acct_event_pkg.upgrade_status_per_doc, x_return_status is U');
                  FND_MESSAGE.SET_NAME('AR','GENERIC_MESSAGE');
		  fnd_message.set_token('GENERIC_MESSAGE',l_msg_data1||'->'||SQLERRM);
		  FND_MSG_PUB.Add;
		  l_val_return_status:= FND_API.G_RET_STS_ERROR;
		 END IF;


    End;	--Bug 16789203 end
    end if;
end if;	/*Bug 17326589*/


         -- Bug 2270809
         -- If a claim was created with this app, then check the claim status.
         -- If not OPEN,CANCELLED,COMPLETE then disallow unapply
         SELECT application_ref_type,
                secondary_application_ref_id,
                amount_applied
         INTO   l_application_ref_type,
                l_secondary_app_ref_id,
                l_amount_applied
         FROM   ar_receivable_applications
         WHERE  receivable_application_id = l_receivable_application_id;
         IF (l_application_ref_type = 'CLAIM' AND
	     NVL(p_called_from,'RAPI') <> 'TRADE_MANAGEMENT')
         THEN
           ar_receipt_val_pvt.validate_claim_unapply(
                p_secondary_app_ref_id      =>  l_secondary_app_ref_id,
                p_invoice_ps_id             =>  l_applied_payment_schedule_id ,
                p_customer_trx_id           =>  l_customer_trx_id,
                p_cash_receipt_id           =>  l_cash_receipt_id,
                p_receipt_number            =>  p_receipt_number,
                p_amount_applied            =>  l_amount_applied,
                p_cancel_claim_flag         =>  p_cancel_claim_flag,
                p_return_status             =>  l_clm_return_status);
         END IF;

         IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug('Apply: ' || 'validation return status :'||l_val_return_status);
         END IF;

         jg_ar_receivable_applications.Unapply(
                                      l_cash_receipt_id,
                                      l_applied_payment_schedule_id,
				      l_glob_return_status );
--
END IF;

         IF l_derive_ids_ret_status <> FND_API.G_RET_STS_SUCCESS OR
            l_val_return_status <> FND_API.G_RET_STS_SUCCESS OR
            l_clm_return_status <> FND_API.G_RET_STS_SUCCESS OR
            l_glob_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            x_return_status := FND_API.G_RET_STS_ERROR ;
         END IF;

        IF x_return_status <> FND_API.G_RET_STS_SUCCESS
         THEN

            ROLLBACK TO Unapply_PVT;

             x_return_status := FND_API.G_RET_STS_ERROR ;

             FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                        p_count => x_msg_count,
                                        p_data  => x_msg_data
                                       );

             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Apply: ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
             END IF;
             Return;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Apply: ' || '*******DUMP THE INPUT PARAMETERS ********');
           arp_util.debug('Apply: ' || 'l_receivable_application_id :'||to_char(l_receivable_application_id));
           arp_util.debug('Apply: ' || 'l_reversal_gl_date :'||to_char(l_reversal_gl_date,'DD-MON-YY'));
        END IF;

	-- LLCA - Delete the activity record if llca exists. We need to modify the LLCA update
	-- logic to preserve the previous record details on AR_ACTIVITY_DETAILS instead of
	--- removing it.  Open bug exist for this issue.
	/*
	delete from ar_activity_details ad
	where ad.cash_receipt_id  = l_cash_receipt_id
        and  ad.customer_trx_line_id in
		(select customer_trx_line_id from ra_customer_trx_lines
		 where customer_trx_id = l_customer_trx_id);
         */

-- Bug 7241111 to retain the old application record under activity details

INSERT INTO AR_ACTIVITY_DETAILS(
                                CASH_RECEIPT_ID,
                                CUSTOMER_TRX_LINE_ID,
                                ALLOCATED_RECEIPT_AMOUNT,
                                AMOUNT,
                                TAX,
                                FREIGHT,
                                CHARGES,
                                LAST_UPDATE_DATE,
                                LAST_UPDATED_BY,
                                LINE_DISCOUNT,
                                TAX_DISCOUNT,
                                FREIGHT_DISCOUNT,
                                LINE_BALANCE,
                                TAX_BALANCE,
                                CREATION_DATE,
                                CREATED_BY,
                                LAST_UPDATE_LOGIN,
                                COMMENTS,
                                APPLY_TO,
                                ATTRIBUTE1,
                                ATTRIBUTE2,
                                ATTRIBUTE3,
                                ATTRIBUTE4,
                                ATTRIBUTE5,
                                ATTRIBUTE6,
                                ATTRIBUTE7,
                                ATTRIBUTE8,
                                ATTRIBUTE9,
                                ATTRIBUTE10,
                                ATTRIBUTE11,
                                ATTRIBUTE12,
                                ATTRIBUTE13,
                                ATTRIBUTE14,
                                ATTRIBUTE15,
                                ATTRIBUTE_CATEGORY,
                                GROUP_ID,
                                REFERENCE1,
                                REFERENCE2,
                                REFERENCE3,
                                REFERENCE4,
                                REFERENCE5,
                                OBJECT_VERSION_NUMBER,
                                CREATED_BY_MODULE,
                                SOURCE_ID,
                                SOURCE_TABLE,
                                LINE_ID,
			        CURRENT_ACTIVITY_FLAG)
                        SELECT
                                LLD.CASH_RECEIPT_ID,
                                LLD.CUSTOMER_TRX_LINE_ID,
                                LLD.ALLOCATED_RECEIPT_AMOUNT*-1,
                                LLD.AMOUNT*-1,
                                LLD.TAX*-1,
                                LLD.FREIGHT*-1,
                                LLD.CHARGES*-1,
                                LLD.LAST_UPDATE_DATE,
                                LLD.LAST_UPDATED_BY,
                                LLD.LINE_DISCOUNT,
                                LLD.TAX_DISCOUNT,
                                LLD.FREIGHT_DISCOUNT,
                                LLD.LINE_BALANCE,
                                LLD.TAX_BALANCE,
                                LLD.CREATION_DATE,
                                LLD.CREATED_BY,
                                LLD.LAST_UPDATE_LOGIN,
                                LLD.COMMENTS,
                                LLD.APPLY_TO,
                                LLD.ATTRIBUTE1,
                                LLD.ATTRIBUTE2,
                                LLD.ATTRIBUTE3,
                                LLD.ATTRIBUTE4,
                                LLD.ATTRIBUTE5,
                                LLD.ATTRIBUTE6,
                                LLD.ATTRIBUTE7,
                                LLD.ATTRIBUTE8,
                                LLD.ATTRIBUTE9,
                                LLD.ATTRIBUTE10,
                                LLD.ATTRIBUTE11,
                                LLD.ATTRIBUTE12,
                                LLD.ATTRIBUTE13,
                                LLD.ATTRIBUTE14,
                                LLD.ATTRIBUTE15,
                                LLD.ATTRIBUTE_CATEGORY,
                                LLD.GROUP_ID,
                                LLD.REFERENCE1,
                                LLD.REFERENCE2,
                                LLD.REFERENCE3,
                                LLD.REFERENCE4,
                                LLD.REFERENCE5,
                                LLD.OBJECT_VERSION_NUMBER,
                                LLD.CREATED_BY_MODULE,
                                LLD.SOURCE_ID,
                                LLD.SOURCE_TABLE,
                                ar_Activity_details_s.nextval,
                                'R'
                        FROM ar_Activity_details LLD
		        where LLD.cash_receipt_id = l_cash_receipt_id
			and nvl(LLD.CURRENT_ACTIVITY_FLAG, 'Y') = 'Y'
			and  LLD.customer_trx_line_id in
			(select customer_trx_line_id
			from ra_customer_trx_lines
			where customer_trx_id = l_customer_trx_id);

		   UPDATE ar_Activity_details dtl
		     set CURRENT_ACTIVITY_FLAG = 'N'
			where dtl.cash_receipt_id = l_cash_receipt_id
			and nvl(dtl.CURRENT_ACTIVITY_FLAG, 'Y') = 'Y'
			and  dtl.customer_trx_line_id in
			(select customer_trx_line_id
			from ra_customer_trx_lines
			where customer_trx_id = l_customer_trx_id);




        --lock the receipt before calling the entity handler
       arp_cash_receipts_pkg.nowaitlock_p(p_cr_id => l_cash_receipt_id);

       BEGIN
        --call the entity handler.
	/*  Bug 18147460 */
	 ar_receipt_lib_pvt.Is_IGI_Upgraded_Transation(p_cr_id => l_cash_receipt_id,
                              p_inv_ps_id  => l_applied_payment_schedule_id ,
                              p_igi_data_flag  =>L_IGI_UPGRADE_DATA_FLAG);

	  If(L_IGI_UPGRADE_DATA_FLAG = 'Y') then

	  ar_receipt_lib_pvt.Unapply_IGI_Upg_Transation(p_cash_receipt_id => l_cash_receipt_id,
                                                             p_customer_trx_id => l_customer_trx_id,
                                                             p_applied_payment_schedule_id => l_applied_payment_schedule_id,
                                                             p_receivable_application_id => l_receivable_application_id,
                                                             p_reversal_gl_date => l_reversal_gl_date,
                                                             p_installment => p_installment,
                                                             x_return_status => x_return_status,
                                                             x_msg_count => x_msg_count,
                                                             x_msg_data => x_msg_data);

                 IF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
                    ROLLBACK TO Unapply_PVT;
                    arp_util.debug('Apply: ' || 'Error(s) occurred.During Unapply_IGI_Upg_Transation');
                 END IF;

              L_IGI_UPGRADE_DATA_FLAG := 'N';

	  Else
          arp_process_application.reverse(
                                l_receivable_application_id,
                                l_reversal_gl_date,
                                trunc(sysdate),
                                'RAPI',
                                p_api_version,
                                l_bal_due_remaining,
                                p_called_from  );
	  end if;
       EXCEPTION
         WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN
                     ROLLBACK TO Unapply_PVT;

                      --  Display_Parameters;
                      x_return_status := FND_API.G_RET_STS_ERROR ;
                       FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                       FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','ARP_PROCESS_APPLICATION.REVERSE : '||SQLERRM);
                       FND_MSG_PUB.Add;

                       FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                                                  p_count  =>  x_msg_count,
                                                  p_data   => x_msg_data
                                                );
                      RETURN;
                ELSE
                   RAISE;
                END IF;

       END;
       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Apply: ' || 'committing');
            END IF;
              Commit;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('ar_receipt_api.Unapply ()- ');
        END IF;


EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Apply: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Unapply_PVT;
                x_return_status := FND_API.G_RET_STS_ERROR ;

              --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply: ' || SQLERRM, G_MSG_ERROR);
                END IF;
                ROLLBACK TO Unapply_PVT;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

               --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN

                      ROLLBACK TO Unapply_PVT;

                      x_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','UNAPPLY : '||SQLERRM);
                      FND_MSG_PUB.Add;

                      --If only one error message on the stack,
                      --retrive it

                      FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                                 p_count  =>  x_msg_count,
                                                 p_data   => x_msg_data
                                                );

                      RETURN;

                ELSE
                      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','UNAPPLY : '||SQLERRM);
                      FND_MSG_PUB.Add;
                END IF;

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Apply: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Unapply_PVT;

                IF      FND_MSG_PUB.Check_Msg_Level
                THEN
                FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME,
                                        l_api_name
                                       );
                END IF;

             --   Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

END Unapply;


procedure process_payment(
		p_cash_receipt_id     IN  NUMBER,
                p_called_from         IN  VARCHAR2,
                p_response_error_code OUT NOCOPY VARCHAR2,
                x_msg_count           OUT NOCOPY NUMBER,
                x_msg_data            OUT NOCOPY VARCHAR2,
		x_return_status       OUT NOCOPY VARCHAR2
                ) IS
/*
  CURSOR rct_info_cur IS
     SELECT cr.receipt_number,
	    cr.amount,
            cr.currency_code,
            rm.merchant_ref,
            rc.creation_status,
            ba.bank_branch_id,
            ba.bank_account_num,
	    ba.bank_account_name,
            ba.inactive_date,
            cr.unique_reference   --bug 3672953
     FROM   ar_cash_receipts cr,
            ar_receipt_methods rm,
	    ar_receipt_classes rc,
            ap_bank_accounts ba
     WHERE  cr.cash_receipt_id = p_cash_receipt_id
       AND  cr.customer_bank_account_id = ba.bank_account_id
       AND  cr.receipt_method_id = rm.receipt_method_id
       and  rm.receipt_class_id = rc.receipt_class_id;


  rct_info rct_info_cur%ROWTYPE;

  l_cr_rec ar_cash_receipts%ROWTYPE;


  l_payee_rec		IBY_Payment_Adapter_pub.Payee_Rec_type;
  l_customer_rec	IBY_Payment_Adapter_pub.Payer_Rec_type;
  l_tangible_rec	IBY_Payment_Adapter_pub.Tangible_Rec_type;
  l_pmtreqtrxn_rec	IBY_Payment_Adapter_pub.PmtReqTrxn_Rec_type;
  l_pmtinstr_rec        IBY_payment_adapter_pub.PmtInstr_Rec_type;
  l_cc_instr_rec        IBY_Payment_Adapter_pub.CreditCardInstr_Rec_Type;
  l_reqresp_rec         IBY_Payment_Adapter_pub.ReqResp_rec_type;
  l_riskinfo_rec        IBY_Payment_Adapter_pub.RiskInfo_rec_type;

  -- used for capture only:
  l_capturetrxn_rec     IBY_Payment_Adapter_pub.CaptureTrxn_rec_type;
  l_capresp_rec         IBY_Payment_Adapter_pub.CaptureResp_rec_type;


  l_payment_server_order_num VARCHAR2(80);
  l_action VARCHAR2(80);

  l_return_status VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
  l_msg_count NUMBER;
  l_msg_data  VARCHAR2(2000);
*/

BEGIN


          /* CALLED THE NEW PACKAGE HERE */


                        process_payment_1(
                               p_cash_receipt_id     => p_cash_receipt_id,
                               p_called_from         => p_called_from,
                               p_response_error_code => p_response_error_code,
                               x_msg_count           => x_msg_count,
                               x_msg_data            => x_msg_data,
                               x_return_status       => x_return_status);




/*
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('Apply: ' || 'Entering credit card processing...');
  END IF;

  OPEN rct_info_cur;
  FETCH rct_info_cur INTO rct_info;

  IF rct_info_cur%FOUND THEN

    -- first check if this is actually a credit card payment,
    -- indicated by bank_branch_id being 1 for the customer bank
    -- account

    IF rct_info.bank_branch_id = arp_global.CC_BANK_BRANCH_ID THEN

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_standard.debug('Apply: ' || 'credit card bank branch is '  ||
             arp_global.CC_BANK_BRANCH_ID || ' --> CC acct');
        END IF;

        -- determine whether to AUTHORIZE only or to
        -- CAPTURE and AUTHORIZE in one step.  This is
        -- dependent on the receipt creation status, i.e.,
        -- if the receipt is created as remitted or cleared, the
        -- funds need to be authorized and captured.  If the
        -- receipt is confirmed, the remittance process will
        -- handle the capture and at this time we'll only
        -- authorize the charges to the credit card.

        if rct_info.creation_status IN ('REMITTED', 'CLEARED') THEN
          l_action := 'AUTHANDCAPTURE';
        elsif rct_info.creation_status = 'CONFIRMED' THEN
          l_action := 'AUTHONLY';
        else
          IF PG_DEBUG in ('Y', 'C') THEN
             arp_standard.debug('Apply: ' || 'ERROR: Creation status is ' || rct_info.creation_status);
          END IF;

          FND_MESSAGE.set_name('AR', 'AR_PAY_PROCESS_INVALID_STATUS');
          FND_MSG_PUB.Add;

          x_return_status := FND_API.G_RET_STS_ERROR;  -- should never happen
          RETURN;
        end if;

        -- Step 1: (always performed):
        -- authorize credit card charge

	-- set up payee record:

	l_payee_rec.payee_id := rct_info.merchant_ref;

	-- set up payer (=customer) record:

	l_customer_rec.payer_name := rct_info.bank_account_name;

        -- set up cc instrument record:

        l_cc_instr_rec.cc_num     := rct_info.bank_account_num;
        l_cc_instr_rec.cc_ExpDate := rct_info.inactive_date;
        l_cc_instr_rec.cc_HolderName := rct_info.bank_account_name;

        -- set the credit card as the payment instrument

        l_pmtinstr_rec.creditcardinstr:= l_cc_instr_rec;

        -- set up 'tangible' record:

        select 'ARI_'||ar_payment_server_ord_num_s.nextval
        into l_payment_server_order_num
        from dual;

        l_tangible_rec.tangible_id     := l_payment_server_order_num;
        l_tangible_rec.tangible_amount := rct_info.amount;
        l_tangible_rec.currency_code   := rct_info.currency_code;
        l_tangible_rec.refinfo         := rct_info.receipt_number;


        l_pmtreqtrxn_rec.pmtmode   := 'ONLINE';
        l_pmtreqtrxn_rec.auth_type := 'AUTHONLY';

        --Bug 3672953 Also pass unique reference to iPayment APIs
        ---Check the value of unique reference and if null then
        ---generate the value
        l_pmtreqtrxn_rec.TrxnRef := nvl(rct_info.unique_reference,SYS_GUID() );


        -- call to iPayment API OraPmtReq to authorize funds

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_standard.debug('Apply: ' || 'Calling OraPmtReq');
           arp_standard.debug('Apply: ' || 'l_pmtreqtrxn_rec.pmtmode: ' || l_pmtreqtrxn_rec.pmtmode);
           arp_standard.debug('Apply: ' || 'l_pmtreqtrxn_rec.auth_type: ' || l_pmtreqtrxn_rec.auth_type);

           arp_standard.debug(  'l_pmtreqtrxn_rec.TrxnRef: ' || l_pmtreqtrxn_rec.TrxnRef);

           arp_standard.debug('Apply: ' || 'l_tangible_rec.tangible_id: ' ||  l_payment_server_order_num);
           arp_standard.debug('Apply: ' || 'l_tangible_rec.tangible_amount: ' || to_char(l_tangible_rec.tangible_amount) );
           arp_standard.debug('Apply: ' || 'l_tangible_rec.currency_code: ' ||l_tangible_rec.currency_code );
           arp_standard.debug('Apply: ' || 'l_tangible_rec.refinfo: ' || l_tangible_rec.refinfo);
           arp_standard.debug('Apply: ' || 'l_cc_instr_rec.cc_num: ' ||l_cc_instr_rec.cc_num );
           arp_standard.debug('Apply: ' || 'l_cc_instr_rec.cc_ExpDate: ' || to_char(l_cc_instr_rec.cc_ExpDate));
           arp_standard.debug('Apply: ' || 'l_cc_instr_rec.cc_HolderName: ' || l_cc_instr_rec.cc_HolderName );
           arp_standard.debug('Apply: ' || 'l_payee_rec.payee_id: ' ||l_payee_rec.payee_id );
           arp_standard.debug('Apply: ' || 'l_customer_rec.payer_name: ' || l_customer_rec.payer_name);
        END IF;

        IBY_Payment_Adapter_pub.OraPmtReq(
           p_api_version 	=> 1.0,
           p_init_msg_list 	=> FND_API.G_TRUE,
           p_commit       	=> FND_API.G_FALSE,
	   p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
	   p_ecapp_id           => 222,  -- AR product id
           x_return_status      => l_return_status,
           x_msg_count          => l_msg_count,
           x_msg_data           => l_msg_data,
           p_payee_rec          => l_payee_rec,
           p_payer_rec          => l_customer_rec,
           p_pmtinstr_rec       => l_pmtinstr_rec,
           p_tangible_rec       => l_tangible_rec,
           p_pmtreqtrxn_rec     => l_pmtreqtrxn_rec,
	   p_riskinfo_rec       => l_riskinfo_rec,
           x_reqresp_rec        => l_reqresp_rec);

	 IF PG_DEBUG in ('Y', 'C') THEN
	    arp_standard.debug('Apply: ' || 'l_return_status: ' || l_return_status);
	 END IF;

         x_msg_count           := l_msg_count;
         x_msg_data            := l_msg_data;
         p_response_error_code := l_reqresp_rec.response.errcode;

         IF PG_DEBUG in ('Y', 'C') THEN
            arp_standard.debug('Apply: ' || '-------------------------------------');
            arp_standard.debug('Apply: ' || 'l_reqresp_rec.response.errcode: ' || l_reqresp_rec.response.errcode);
            arp_standard.debug('Apply: ' || 'l_reqresp_rec.response.errmessage: ' || l_reqresp_rec.response.errmessage);
            arp_standard.debug('Apply: ' || 'l_reqresp_rec.errorlocation: ' || l_reqresp_rec.errorlocation);
            arp_standard.debug('Apply: ' || 'l_reqresp_rec.beperrcode: ' || l_reqresp_rec.beperrcode);
            arp_standard.debug('Apply: ' || 'l_reqresp_rec.beperrmessage: ' || l_reqresp_rec.beperrmessage);
            arp_standard.debug('Apply: ' || 'NVL(l_reqresp_rec.response.status,0): ' || to_char(NVL(l_reqresp_rec.response.status,0)));
            arp_standard.debug('Apply: ' || 'Authcode: ' || l_reqresp_rec.authcode);
            arp_standard.debug('Apply: ' || 'Trxn ID: ' || l_reqresp_rec.Trxn_ID);
            arp_standard.debug('Apply: ' || '-------------------------------------');
         END IF;

        -- check if call was successful
        --Add message to message stack only it it is called from iReceivables
        --if not pass the message stack received from iPayment

        IF (NVL(p_called_from,'NONE') = 'IREC') THEN
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_standard.debug('Apply: ' || 'l_MSG_COUNT=>'||to_char(l_MSG_COUNT));
           END IF;
           fnd_msg_pub.dump_list;
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_standard.debug('Apply: ' || 'Errors: ');
           END IF;
           IF(l_MSG_COUNT=1) THEN
              IF PG_DEBUG in ('Y', 'C') THEN
                 arp_standard.debug('Apply: ' || l_MSG_DATA);
              END IF;
           ELSIF(l_MSG_COUNT>1)THEN
              LOOP
                  l_MSG_DATA:=FND_MSG_PUB.GET(p_encoded=>FND_API.G_FALSE);
                  IF (l_MSG_DATA IS NULL)THEN
                     EXIT;
                  END IF;
                  IF PG_DEBUG in ('Y', 'C') THEN
                     arp_standard.debug('Apply: ' || l_MSG_DATA);
                  END IF;
              END LOOP;
           END IF;
        END IF;

        if (l_return_status <> FND_API.G_RET_STS_SUCCESS)
           AND (NVL(p_called_from,'NONE') = 'IREC')  then

          FND_MESSAGE.set_name('AR', 'AR_PAY_PROCESS_AUTHFAILURE');
          FND_MSG_PUB.Add;
          x_return_status := l_return_status;
          RETURN;
        elsif (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
           --bug 3398538
               arp_util.debug('Create_cash_124: ');
          FND_MESSAGE.set_name('AR', 'AR_CC_AUTH_FAILED');
          FND_MSG_PUB.Add;
          x_return_status := l_return_status;
          RETURN;
        end if;


        -- update cash receipt with authorization code and
        -- payment server order id (tangible id)

        ARP_CASH_RECEIPTS_PKG.set_to_dummy(l_cr_rec);
        l_cr_rec.approval_code := l_reqresp_rec.authcode;
        l_cr_rec.payment_server_order_num := l_tangible_rec.tangible_id;
        ARP_CASH_RECEIPTS_PKG.update_p(l_cr_rec, p_cash_receipt_id);

          IF PG_DEBUG in ('Y', 'C') THEN
             arp_standard.debug('Apply: ' || 'CR rec updated with payment server auth code');
          END IF;

        -- see if capture is also required

        if (l_action = 'AUTHANDCAPTURE') then

          IF PG_DEBUG in ('Y', 'C') THEN
             arp_standard.debug('Apply: ' || 'starting capture...');
          END IF;

          -- Step 2: (optional): capture funds

          l_capturetrxn_rec.Trxn_ID := l_reqresp_rec.trxn_id;
          l_capturetrxn_rec.PmtMode := 'ONLINE';
          l_capturetrxn_rec.currency := rct_info.currency_code;
          l_capturetrxn_rec.price := rct_info.amount;

          --Bug 3672953 Also pass unique reference to iPayment APIs
          ---Check the value of unique reference and if null then
          ---generate the value
          l_capturetrxn_rec.TrxnRef:= nvl(rct_info.unique_reference,SYS_GUID());



          IBY_Payment_Adapter_pub.OraPmtCapture(
               p_api_version 	    => 1.0,
               p_init_msg_list 	    => FND_API.G_FALSE,
               p_commit       	    => FND_API.G_FALSE,
   	       p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
	       p_ecapp_id           => 222,  -- AR product id
               x_return_status      => l_return_status,
               x_msg_count          => l_msg_count,
               x_msg_data           => l_msg_data,
               p_capturetrxn_rec    => l_capturetrxn_rec,
	       x_capresp_rec        => l_capresp_rec);

	    IF PG_DEBUG in ('Y', 'C') THEN
	       arp_standard.debug('Apply: ' || 'l_return_status: ' || l_return_status);
	    END IF;

            x_msg_count           := l_msg_count;
            x_msg_data            := l_msg_data;
            p_response_error_code := l_capresp_rec.response.errcode;

            IF (NVL(p_called_from,'NONE') = 'IREC') THEN
                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_standard.debug('Apply: ' || 'l_MSG_COUNT=>'||to_char(l_MSG_COUNT));
                END IF;
                fnd_msg_pub.dump_list;
                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_standard.debug('Apply: ' || 'Errors: ');
                END IF;
                IF(l_MSG_COUNT=1) THEN
                   IF PG_DEBUG in ('Y', 'C') THEN
                      arp_standard.debug('Apply: ' || l_MSG_DATA);
                   END IF;
                ELSIF(l_MSG_COUNT>1)THEN
                  LOOP
                     l_MSG_DATA:=FND_MSG_PUB.GET(p_encoded=>FND_API.G_FALSE);
                     IF (l_MSG_DATA IS NULL)THEN
                        EXIT;
                     END IF;
                     IF PG_DEBUG in ('Y', 'C') THEN
                        arp_standard.debug('Apply: ' || l_MSG_DATA);
                     END IF;
                  END LOOP;
                END IF;
            END IF;

            IF PG_DEBUG in ('Y', 'C') THEN
               arp_standard.debug('Apply: ' || '-------------------------------------');
               arp_standard.debug('Apply: ' || 'l_capresp_rec.response.errcode: ' || l_capresp_rec.response.errcode);
               arp_standard.debug('Apply: ' || 'l_capresp_rec.response.errmessage: ' || l_capresp_rec.response.errmessage);
               arp_standard.debug('Apply: ' || 'l_capresp_rec.errorlocation: ' || l_capresp_rec.errorlocation);
               arp_standard.debug('Apply: ' || 'l_capresp_rec.beperrcode: ' || l_capresp_rec.beperrcode);
               arp_standard.debug('Apply: ' || 'l_capresp_rec.beperrmessage: ' || l_capresp_rec.beperrmessage);
               arp_standard.debug('Apply: ' || 'NVL(l_capresp_rec.response.status,0): ' || to_char(NVL(l_capresp_rec.response.status,0)));
               arp_standard.debug('Apply: ' || 'PmtInstr_Type: ' || l_capresp_rec.PmtInstr_Type);
               arp_standard.debug('Apply: ' || 'Trxn ID: ' || l_capresp_rec.Trxn_ID);
               arp_standard.debug('Apply: ' || '-------------------------------------');
            END IF;

           --Add message to message stack only it it is called from iReceivables
           --if not pass the message stack received from iPayment

           if (l_return_status <> FND_API.G_RET_STS_SUCCESS) AND (NVL(p_called_from,'NONE') = 'IREC')  then
              FND_MESSAGE.set_name('AR', 'AR_PAY_PROCESS_CAPTFAILURE');
              FND_MSG_PUB.Add;
            --bug 3398538
           elsif (l_return_status <>  FND_API.G_RET_STS_SUCCESS ) THEN
             FND_MESSAGE.set_name('AR', 'AR_CC_CAPTURE_FAILED');
             FND_MSG_PUB.Add;
           end if;
           x_return_status := l_return_status;

        END IF;  -- if capture required...

      ELSE

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_standard.debug('Apply: ' || 'credit card bank branch is not 1 --> no CC acct');
        END IF;

        -- currently no processing required

      END IF;

    END IF;
*/


END process_payment;



-- bichatte payment uptake project

PROCEDURE process_payment_1(
                p_cash_receipt_id     IN  NUMBER,
                p_called_from         IN  VARCHAR2,
                p_response_error_code OUT NOCOPY VARCHAR2,
                x_msg_count           OUT NOCOPY NUMBER,
                x_msg_data            OUT NOCOPY VARCHAR2,
                x_return_status       OUT NOCOPY VARCHAR2,
                p_payment_trxn_extension_id IN NUMBER DEFAULT NULL
                ) IS


  CURSOR rct_info_cur IS
     SELECT cr.receipt_number,
            cr.amount,
            cr.currency_code,
            rm.PAYMENT_CHANNEL_CODE,       /* NEW ADDED */
            rc.creation_status,            /* AR USE */
            cr.org_id,
            party.party_id,
            cr.pay_from_customer,
            cr.customer_site_use_id,
            cr.payment_trxn_extension_id,
            cr.receipt_date,
            pr.home_country
     FROM   ar_cash_receipts_all cr,
            ar_receipt_methods rm,
            ar_receipt_classes rc,
            hz_cust_accounts hca,
            hz_parties    party,
            /* Need to pass country code for SEPA specific receipts */
            ce_bank_acct_uses bau,
            ce_bank_accounts cba,
            hz_parties bank,
	    hz_organization_profiles pr
     WHERE  cr.cash_receipt_id = p_cash_receipt_id
     AND    hca.cust_account_id = cr.pay_from_customer
     AND    party.party_id = hca.party_id
     AND    rm.receipt_method_id = cr.receipt_method_id
     AND    rc.receipt_class_id = rm.receipt_class_id
     AND    bau.bank_acct_use_id = cr.remit_bank_acct_use_id
     AND    cba.bank_account_id = bau.bank_account_id
     AND    bank.party_id = cba.bank_id
     AND    pr.party_id = bank.party_id;

            rct_info    rct_info_cur%ROWTYPE;
            l_cr_rec    ar_cash_receipts_all%ROWTYPE;
            l_org_type  HR_ALL_ORGANIZATION_UNITS.TYPE%TYPE;
            l_action VARCHAR2(80);
            l_return_status VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
            l_msg_count NUMBER;
            l_msg_data  VARCHAR2(2000);
            l_iby_msg_data VARCHAR2(2000);
            l_vend_msg_data VARCHAR2(2000);
            l_cpy_msg_data VARCHAR2(2000);

/* DECLARE the variables required for the payment engine (CPY ) all the REC TYPES */
           p_trxn_entity_id    NUMBER;
           lc_trxn_entity_id   IBY_FNDCPT_COMMON_PUB.Id_tbl_type;

           l_auth_flag         VARCHAR2(1);
           l_auth_id           NUMBER;

/* END DECLARE the variables required for the payment engine (CPY ) all the REC TYPES */
/* DECLARE the variables required for the payment engine (CPY AND AUTH) all the REC TYPES */

            l_payer_rec             IBY_FNDCPT_COMMON_PUB.PayerContext_rec_type;
            l_payee_rec             IBY_FNDCPT_TRXN_PUB.PayeeContext_rec_type;
            l_trxn_entity_id        NUMBER;
            l_auth_attribs_rec      IBY_FNDCPT_TRXN_PUB.AuthAttribs_rec_type;
            l_trxn_attribs_rec      IBY_FNDCPT_TRXN_PUB.TrxnExtension_rec_type;
            l_amount_rec            IBY_FNDCPT_TRXN_PUB.Amount_rec_type;
            l_authresult_rec       IBY_FNDCPT_TRXN_PUB.AuthResult_rec_type; /* OUT AUTH RESULT STRUCTURE */
            l_response_rec          IBY_FNDCPT_COMMON_PUB.Result_rec_type;   /* OUT RESPONSE STRUCTURE */
            l_entity_id             NUMBER;  -- OUT FROM COPY
/* END DECLARE the variables required for the payment engine (AUTH) all the REC TYPES */


/* DECLARE the variables required for the payment engine (SETTLEMENT) all the REC TYPES */
            ls_response_rec          IBY_FNDCPT_COMMON_PUB.Result_rec_type;   /* OUT RESPONSE STRUCTURE */
            ls_return_status VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
            ls_msg_count NUMBER;
            ls_msg_data  VARCHAR2(2000);
            ls_iby_msg_data VARCHAR2(2000);

/* END DECLARE the variables required for the payment engine (SETTLEMENT) all the REC TYPES */
l_receipt_info_rec               AR_AUTOREC_API.receipt_info_rec;
l_rcpt_creation_rec              AR_AUTOREC_API.rcpt_creation_info;

 /* 7666285 - for passing settlement_date  on returns */
           lcr_receipt_attr      IBY_FNDCPT_TRXN_PUB.receiptattribs_rec_type;

BEGIN


  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug(  'Entering payment processing...');
  END IF;


  OPEN rct_info_cur;
  FETCH rct_info_cur INTO rct_info;


  IF rct_info_cur%FOUND THEN


        if rct_info.creation_status IN ('REMITTED', 'CLEARED') THEN
          l_action := 'AUTHANDCAPTURE';
        elsif rct_info.creation_status = 'CONFIRMED' THEN
          l_action := 'AUTHONLY';
        else
          IF PG_DEBUG in ('Y', 'C') THEN
             arp_standard.debug('Apply: ' || 'ERROR: Creation status is ' || rct_info.creation_status);
          END IF;

          FND_MESSAGE.set_name('AR', 'AR_PAY_PROCESS_INVALID_STATUS');
          FND_MSG_PUB.Add;

          x_return_status := FND_API.G_RET_STS_ERROR;  -- should never happen
          RETURN;
        end if;

  -- Step 1: (always performed):

          -- set up payee record:
          l_payee_rec.org_id   := rct_info.org_id;                            -- receipt's org_id
          l_payee_rec.org_type := 'OPERATING_UNIT' ;                                -- ( HR_ORGANIZATION_UNITS )
	  l_payee_rec.Int_Bank_Country_Code := rct_info.home_country;


        -- set up payer (=customer) record:

        l_payer_rec.Payment_Function := 'CUSTOMER_PAYMENT';
        l_payer_rec.Party_Id :=   rct_info.party_id;     -- receipt customer party id mandatory
        l_payer_rec.org_id   := rct_info.org_id ;
        l_payer_rec.org_type := 'OPERATING_UNIT';
        l_payer_rec.Cust_Account_Id :=rct_info.pay_from_customer;  -- receipt customer account_id
        l_payer_rec.Account_Site_Id :=rct_info.customer_site_use_id; -- receipt customer site_id


        if rct_info.customer_site_use_id is NULL  THEN

          l_payer_rec.org_id := NULL;
          l_payer_rec.org_type := NULL;

        end if;

        -- set up auth_attribs record:
          l_auth_attribs_rec.RiskEval_Enable_Flag := 'N';

        -- set up trxn_attribs record:
        l_trxn_attribs_rec.Originating_Application_Id := arp_standard.application_id;
        l_trxn_attribs_rec.order_id :=  rct_info.receipt_number;
        l_trxn_attribs_rec.Trxn_Ref_Number1 := 'RECEIPT';
        l_trxn_attribs_rec.Trxn_Ref_Number2 := p_cash_receipt_id;

        -- set up amounts

        l_amount_rec.value := rct_info.amount;
        l_amount_rec.currency_code   := rct_info.currency_code;

        /* 7666285 - settlement_date and settlement_due_date */
        lcr_receipt_attr.settlement_date := rct_info.receipt_date;


        IF PG_DEBUG in ('Y', 'C') THEN
           arp_standard.debug(  'check and then call Auth');
        END IF;

        -- determine whether to AUTHORIZE

        -- assign the value for payment_trxn_extension record

                 l_trxn_entity_id := rct_info.payment_trxn_extension_id;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_standard.debug(  'Calling get auth for  pmt_trxn_extn_id ');
           arp_standard.debug(  'l_trxn_entity_id  '             || to_char(l_trxn_entity_id ) );

       END IF;

             Begin
                SELECT decode(summ.status,   NULL,   'N',   'Y') AUTHORIZED_FLAG
                   into l_auth_flag
                 FROM iby_trxn_summaries_all summ,
                      iby_fndcpt_tx_operations op
                WHERE summ.transactionid = op.transactionid
                      AND reqtype = 'ORAPMTREQ'
                      AND status IN(0,    100)
                      AND trxntypeid IN(2,   3, 20)
                      AND op.trxn_extension_id = p_payment_trxn_extension_id
                      AND summ.trxnmid =
                           (SELECT MAX(trxnmid)
                                FROM iby_trxn_summaries_all
                            WHERE transactionid = summ.transactionid
                            AND reqtype = 'ORAPMTREQ'
                            AND status IN(0, 100)
                            AND trxntypeid IN(2,    3,   20));
             Exception
               when others then
                 l_auth_flag := 'N';
             End;

              arp_standard.debug ( 'the value of auth_flag is = ' || l_auth_flag);

                If l_auth_flag = 'Y' then

                  select AUTHORIZATION_ID
                   into l_auth_id
                   from IBY_TRXN_EXT_AUTHS_V
                   where TRXN_EXTENSION_ID = p_payment_trxn_extension_id;

                  arp_standard.debug ( 'the value of auth_id is = ' || l_auth_id);

                  ARP_CASH_RECEIPTS_PKG.set_to_dummy(l_cr_rec);

                  l_cr_rec.approval_code := 'AR'||to_char(l_auth_Id);

                  ARP_CASH_RECEIPTS_PKG.update_p(l_cr_rec, p_cash_receipt_id);

                 arp_standard.debug('CR rec updated with auth_id and auth code ');
                end if;




           IF  l_auth_flag <> 'Y'  then
                 arp_standard.debug('auth needs to called');

               IF PG_DEBUG in ('Y', 'C') THEN
                  arp_standard.debug(  'Calling get auth for  pmt_trxn_extn_id ');
                  arp_standard.debug(  ' l_payee_rec.org_id '           || to_char(l_payee_rec.org_id) );
                  arp_standard.debug(  ' l_payee_rec.org_type '         || to_char( l_payee_rec.org_type) );
                  arp_standard.debug(  ' l_payer_rec.Payment_Function ' || to_char( l_payer_rec.Payment_Function) );
                  arp_standard.debug(  ' l_payer_rec.Party_Id '         || to_char( l_payer_rec.Party_Id) );
                  arp_standard.debug(  ' l_payer_rec.org_id '           || to_char(l_payer_rec.org_id) );
                  arp_standard.debug(  ' l_payer_rec.org_type  '        || to_char( l_payer_rec.org_type) );
                  arp_standard.debug(  'l_payer_rec.Cust_Account_Id '   || to_char(l_payer_rec.Cust_Account_Id) );
                  arp_standard.debug(  'l_payer_rec.Account_Site_Id '   || to_char(l_payer_rec.Account_Site_Id) );
                  arp_standard.debug(  'l_trxn_entity_id  '             || to_char(l_trxn_entity_id ) );
                  arp_standard.debug(  'l_amount_rec.value: ' || to_char(l_amount_rec.value) );
                  arp_standard.debug(  'l_amount_rec.currency_code: '   || l_amount_rec.currency_code );

                  arp_standard.debug(  'Calling get_auth for  pmt_trxn_extn_id ');
               END IF;

               BEGIN
                 IBY_FNDCPT_TRXN_PUB.Create_Authorization(
                         p_api_version        => 1.0,
                         p_init_msg_list      => FND_API.G_TRUE,
                         x_return_status      => l_return_status,
                         x_msg_count          => l_msg_count,
                         x_msg_data           => l_msg_data,
                         p_payer              => l_payer_rec,
                         p_payer_equivalency  => IBY_FNDCPT_COMMON_PUB.G_PAYER_EQUIV_UPWARD,
                         p_payee              => l_payee_rec,
                         p_trxn_entity_id     => l_trxn_entity_id,
                         p_auth_attribs       => l_auth_attribs_rec,
                         p_amount             => l_amount_rec,
                         x_auth_result        => l_authresult_rec, -- out auth result struct
                         x_response           => l_response_rec );   -- out response struct
                EXCEPTION
                   WHEN OTHERS THEN
                        arp_standard.debug('Exception IBY_FNDCPT_TRXN_PUB.Create_Authorization ');
                        null;
                END;

                  x_msg_count           := l_msg_count;
                  x_msg_data            := substrb(l_msg_data, 1, 240);


                        arp_standard.debug('x_return_status  :<' || l_return_status || '>');
                        arp_standard.debug('x_msg_count      :<' || l_msg_count || '>');

                  FOR i IN 1..l_msg_count LOOP
                      arp_standard.debug('x_msg #' || TO_CHAR(i) || ' = <' ||
                      SUBSTR(fnd_msg_pub.get(p_msg_index => i,p_encoded => FND_API.G_FALSE),1,150) || '>');
                  END LOOP;

                     IF PG_DEBUG in ('Y', 'C') THEN
                        arp_standard.debug(  '-------------------------------------');
                        arp_standard.debug(  'l_response_rec.Result_Code:     ' || l_response_rec.Result_Code);
                        arp_standard.debug(  'l_response_rec.Result_Category: ' || l_response_rec.Result_Category);
                        arp_standard.debug(  'l_response_rec.Result_message : ' || l_response_rec.Result_message );
                        arp_standard.debug(  'l_authresult_rec.Auth_Id:     '       || l_authresult_rec.Auth_Id);
                        arp_standard.debug(  'l_authresult_rec.Auth_Date: '         || l_authresult_rec.Auth_Date);
                        arp_standard.debug(  'l_authresult_rec.Auth_Code:     '     || l_authresult_rec.Auth_Code);
                        arp_standard.debug(  'l_authresult_rec.AVS_Code: '          || l_authresult_rec.AVS_Code);
                        arp_standard.debug(  'l_authresult_rec.Instr_SecCode_Check:'|| l_authresult_rec.Instr_SecCode_Check);
                        arp_standard.debug(  'l_authresult_rec.PaymentSys_Code: '   || l_authresult_rec.PaymentSys_Code);
                        arp_standard.debug(  'l_authresult_rec.PaymentSys_Msg: '    || l_authresult_rec.PaymentSys_Msg);
                     -- arp_standard.debug(  'l_authresult_rec.Risk_Result: '       || l_authresult_rec.Risk_Result);

                    END IF;

             IF (l_return_status = FND_API.G_RET_STS_SUCCESS) THEN
              -- update cash receipt with authorization code and

                ARP_CASH_RECEIPTS_PKG.set_to_dummy(l_cr_rec);
                 l_cr_rec.approval_code := l_authresult_rec.Auth_code ||'AR'||to_char(l_authresult_rec.Auth_Id);

               ARP_CASH_RECEIPTS_PKG.update_p(l_cr_rec, p_cash_receipt_id);

               IF PG_DEBUG in ('Y', 'C') THEN
                 arp_standard.debug('CR rec updated with auth_id and auth code ');
               END IF;

             END IF;

                    -- check if call was successful
                    --Add message to message stack only it it is called from iReceivables
                    --if not pass the message stack received from iPayment

                    IF (NVL(p_called_from,'NONE') = 'IREC') THEN
                          IF PG_DEBUG in ('Y', 'C') THEN
                          arp_standard.debug(  'l_MSG_COUNT=>'||to_char(l_MSG_COUNT));
                    END IF;
                    fnd_msg_pub.dump_list;
                    IF PG_DEBUG in ('Y', 'C') THEN
                    arp_standard.debug(  'Errors: ');
                    END IF;
                      IF(l_MSG_COUNT=1) THEN
                         IF PG_DEBUG in ('Y', 'C') THEN
                          arp_standard.debug(  l_MSG_DATA);
                         END IF;
                      ELSIF(l_MSG_COUNT>1)THEN
                           LOOP
                           l_MSG_DATA:=FND_MSG_PUB.GET(p_encoded=>FND_API.G_FALSE);
                               IF (l_MSG_DATA IS NULL)THEN
                               EXIT;
                               END IF;
                              IF PG_DEBUG in ('Y', 'C') THEN
                              arp_standard.debug(  l_MSG_DATA);
                              END IF;
                           END LOOP;
                      END IF;
                    END IF;

                 IF (l_return_status <> FND_API.G_RET_STS_SUCCESS)
                 AND (NVL(p_called_from,'NONE') = 'IREC')  then

                  FND_MESSAGE.set_name('AR', 'AR_PAY_PROCESS_AUTHFAILURE');
                  FND_MSG_PUB.Add;
                  x_return_status := l_return_status;
                  RETURN;

                ELSIF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN

                 arp_standard.debug('create_cash_126');
                  FND_MESSAGE.set_name('AR', 'AR_CC_AUTH_FAILED');
                  FND_MSG_PUB.Add;

                     IF  l_response_rec.Result_Code is NOT NULL THEN

                       ---Raise the PAYMENT error code concatenated with the message
                        -- 7639165
                        p_response_error_code := l_response_rec.Result_Code;

                        l_iby_msg_data := substrb( l_response_rec.Result_Code || ': '||
                                   l_response_rec.Result_Message , 1, 240);

                        arp_standard.debug(  'l_iby_msg_data: ' || l_iby_msg_data);
                        FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                        FND_MESSAGE.SET_TOKEN('GENERIC_TEXT',l_iby_msg_data);

                        FND_MSG_PUB.Add;

                     END IF;

                     IF l_authresult_rec.PaymentSys_Code is not null THEN

                       ---Raise the VENDOR error code concatenated with the message
                        -- 7639165
                        p_response_error_code := l_authresult_rec.PaymentSys_Code;

                        l_vend_msg_data := substrb(l_authresult_rec.PaymentSys_Code || ': '||
                                   l_authresult_rec.PaymentSys_Msg , 1, 240 );

                        FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                        FND_MESSAGE.SET_TOKEN('GENERIC_TEXT',l_vend_msg_data);

                      FND_MSG_PUB.Add;

                    END IF;


                    FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                               p_count  =>  x_msg_count,
                               p_data   => x_msg_data );

                    x_return_status := l_return_status;
                    RETURN;

                  END IF; /* End the error handling CREATE */

          END IF;  /* END if of auth flag N  */


    IF l_action = 'AUTHANDCAPTURE' THEN

     arp_standard.debug ( 'CALL THE SETTLEMENT API');
                   IF PG_DEBUG in ('Y', 'C') THEN
                       arp_standard.debug(  'Calling settlement for  pmt_trxn_extn_id ');
                       arp_standard.debug(  ' l_payer_rec.Payment_Function ' || to_char( l_payer_rec.Payment_Function) );
                       arp_standard.debug(  ' l_payer_rec.Party_Id '         || to_char( l_payer_rec.Party_Id) );
                       arp_standard.debug(  ' l_payer_rec.org_id '           || to_char(l_payer_rec.org_id) );
                       arp_standard.debug(  ' l_payer_rec.org_type  '        || to_char( l_payer_rec.org_type) );
                       arp_standard.debug(  ' l_payer_rec.Cust_Account_Id '  || to_char(l_payer_rec.Cust_Account_Id) );
                       arp_standard.debug(  ' l_payer_rec.Account_Site_Id '  || to_char(l_payer_rec.Account_Site_Id) );
                       arp_standard.debug(  ' l_trxn_entity_id  '            || to_char(l_trxn_entity_id ) );
                       arp_standard.debug(  ' l_amount_rec.value '          || to_char(l_amount_rec.value) );
                       arp_standard.debug(  ' l_amount_rec.currency_code '  || l_amount_rec.currency_code );
                       arp_standard.debug(  ' lcr_receipt_attr.settlement_date '  || lcr_receipt_attr.settlement_date );
                     END IF;

                       IBY_FNDCPT_TRXN_PUB.Create_Settlement (
                             p_api_version        => 1.0,
                             p_init_msg_list      => FND_API.G_TRUE,
                             x_return_status      => ls_return_status,
                             x_msg_count          => ls_msg_count,
                             x_msg_data           => ls_msg_data,
                             p_payer              => l_payer_rec,
                             p_payer_equivalency  => IBY_FNDCPT_COMMON_PUB.G_PAYER_EQUIV_UPWARD,
                             p_trxn_entity_id     => l_trxn_entity_id,
                             p_amount             => l_amount_rec,
                             p_receipt_attribs    => lcr_receipt_attr,
                             x_response           => ls_response_rec );   -- out response struct



                        arp_standard.debug('x_return_status  :<' || ls_return_status || '>');
                        arp_standard.debug('x_msg_count      :<' || ls_msg_count || '>');

                  FOR i IN 1..ls_msg_count LOOP
                      arp_standard.debug('x_msg #' || TO_CHAR(i) || ' = <' ||
                      SUBSTR(fnd_msg_pub.get(p_msg_index => i,p_encoded => FND_API.G_FALSE),1,150) || '>');
                  END LOOP;

                   IF PG_DEBUG in ('Y', 'C') THEN
                      arp_standard.debug(  '-------------------------------------');
                      arp_standard.debug(  'ls_response_rec.Result_Code:     ' || ls_response_rec.Result_Code);
                      arp_standard.debug(  'ls_response_rec.Result_Category: ' || ls_response_rec.Result_Category);
                      arp_standard.debug(  'ls_response_rec.Result_message : ' || ls_response_rec.Result_message );

                    END IF;


                   IF (NVL(p_called_from,'NONE') = 'IREC') THEN
                          IF PG_DEBUG in ('Y', 'C') THEN
                          arp_standard.debug(  'ls_MSG_COUNT=>'||to_char(ls_MSG_COUNT));
                          END IF;
                       fnd_msg_pub.dump_list;
                    IF PG_DEBUG in ('Y', 'C') THEN
                    arp_standard.debug(  'Errors: ');
                    END IF;
                      IF(ls_MSG_COUNT=1) THEN
                         IF PG_DEBUG in ('Y', 'C') THEN
                          arp_standard.debug(  ls_MSG_DATA);
                         END IF;
                      ELSIF(ls_MSG_COUNT>1)THEN
                           LOOP
                           ls_MSG_DATA:=FND_MSG_PUB.GET(p_encoded=>FND_API.G_FALSE);
                               IF (ls_MSG_DATA IS NULL)THEN
                               EXIT;
                               END IF;
                              IF PG_DEBUG in ('Y', 'C') THEN
                              arp_standard.debug(  ls_MSG_DATA);
                              END IF;
                           END LOOP;
                      END IF;
                    END IF;

              IF (ls_return_status <> FND_API.G_RET_STS_SUCCESS)
                    AND (NVL(p_called_from,'NONE') = 'IREC')  then

                      FND_MESSAGE.set_name('AR', 'AR_PAY_PROCESS_AUTHFAILURE');
                      FND_MSG_PUB.Add;
                      x_return_status := ls_return_status;
                    RETURN;

              ELSIF (ls_return_status <> FND_API.G_RET_STS_SUCCESS) THEN


                  FND_MESSAGE.set_name('AR', 'AR_CC_CAPTURE_FAILED');
                  FND_MSG_PUB.Add;

                     IF  ls_response_rec.Result_Code is NOT NULL THEN

                       ---Raise the PAYMENT error code concatenated with the message
                        -- 7639165
                        p_response_error_code := l_response_rec.Result_Code;

                        ls_iby_msg_data := substrb( ls_response_rec.Result_Code || ': '||
                                   ls_response_rec.Result_Message , 1, 240);

                        arp_standard.debug(  'ls_iby_msg_data: ' || ls_iby_msg_data);
                        FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                        FND_MESSAGE.SET_TOKEN('GENERIC_TEXT',ls_iby_msg_data);

                        FND_MSG_PUB.Add;

                     END IF;


                    FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                               p_count  =>  x_msg_count,
                               p_data   => x_msg_data );

                    x_return_status := ls_return_status;
                    RETURN;

                END IF; /* End the error handling */


    END IF;


  END IF ; /* rct_info_cur%FOUND */
  CLOSE rct_info_cur;

EXCEPTION
 WHEN others THEN
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('Exception : process_payment_1() ');
  END IF;

END process_payment_1;

-- bichatte payment uptake project end

-- bichatte payment uptake strt

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
	      p_called_from                 IN VARCHAR2 DEFAULT NULL,
	      p_receipt_date		    IN DATE DEFAULT NULL
                 ) IS

            l_payer_rec             IBY_FNDCPT_COMMON_PUB.PayerContext_rec_type;
            l_return_status VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
            l_msg_count                     NUMBER;
            l_msg_data                      VARCHAR2(2000);
            l_cpy_msg_data                  VARCHAR2(2000);
            l_assignment_id                 NUMBER;
            l_trxn_attribs_rec              IBY_FNDCPT_TRXN_PUB.TrxnExtension_rec_type;
            l_payment_trxn_extension_id     AR_CASH_RECEIPTS.PAYMENT_TRXN_EXTENSION_ID%TYPE;
            p_trxn_entity_id                AR_CASH_RECEIPTS.PAYMENT_TRXN_EXTENSION_ID%TYPE;
            l_response_rec                  IBY_FNDCPT_COMMON_PUB.Result_rec_type;
            l_party_id                      NUMBER;
            lc_trxn_entity_id               IBY_FNDCPT_COMMON_PUB.Id_tbl_type;
            l_customer_id                   ar_cash_receipts.pay_from_customer%TYPE;
            l_receipt_method_id             ar_cash_receipts.receipt_method_id%TYPE;
            l_org_id                        ar_cash_receipts.org_id%TYPE;
            l_customer_site_use_id          ar_cash_receipts.customer_site_use_id%TYPE;
            l_receipt_number                ar_cash_receipts.receipt_number%TYPE;

	    l_receipt_info_rec              AR_AUTOREC_API.receipt_info_rec;
            l_rcpt_creation_rec		    AR_AUTOREC_API.rcpt_creation_info;

	    l_start_date		    DATE ;
	    l_end_date			    DATE ;

BEGIN


arp_standard.debug ( 'inside Copy payment trxn ');

     l_customer_id := p_customer_id;
     l_receipt_method_id := p_receipt_method_id;
     l_org_id := p_org_id;
     l_customer_site_use_id := p_customer_site_use_id;
     l_receipt_number := p_receipt_number;
     l_payment_trxn_extension_id := p_payment_trxn_extension_id;

    --BUG 6660834
    IF nvl(p_called_from,'NONE') IN ('AUTORECAPI','AUTORECAPI2') THEN
	ar_autorec_api.populate_cached_data(  l_rcpt_creation_rec );

	l_party_id         := l_rcpt_creation_rec.party_id;
	l_assignment_id    := l_rcpt_creation_rec.assignment_id;

     ELSE
     SELECT party.party_id
     INTO   l_party_id
     FROM   hz_cust_accounts hca,
            hz_parties    party
     WHERE  hca.party_id = party.party_id
     AND    hca.cust_account_id = l_customer_id ;

     SELECT INSTR_ASSIGNMENT_ID
     INTO  l_assignment_id
     from  iby_fndcpt_tx_extensions
     where trxn_extension_id = l_payment_trxn_extension_id;
    END IF;


/* Bug 11769052 : Get start and end date for instrument assignment. */
    BEGIN
	SELECT i.start_date, i.end_date
	INTO   l_start_date, l_end_date
	FROM   iby_fndcpt_tx_extensions x, iby_pmt_instr_uses_all i
	WHERE  x.instr_assignment_id = i.instrument_payment_use_id
	AND    x.trxn_extension_id = p_payment_trxn_extension_id
	AND    x.INSTR_ASSIGNMENT_ID = l_assignment_id;
        If l_start_date is not null then
           l_start_date := trunc(l_start_date);
        end if;
        If l_end_Date is not null then
            l_end_date  := trunc(l_end_date);
        end if;
	arp_standard.debug ('p_payment_trxn_extension_id: '|| p_payment_trxn_extension_id);
	arp_standard.debug ('l_assignment_id: '|| l_assignment_id);
	arp_standard.debug ('l_start_date: '|| l_start_date);
	arp_standard.debug ('l_end_date: '|| l_end_date);
	arp_standard.debug ('p_receipt_date: '|| p_receipt_date);

        IF p_receipt_date NOT BETWEEN l_start_date  AND NVL(l_end_date, to_date('31-12-4712','DD-MM-YYYY')) THEN
		arp_standard.debug ( 'Receipt date out of instrument assignment range. Receipt will not be created for this instrument.');
		FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
		FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','Instrument assignment date range out of bound.');
		FND_MSG_PUB.Add;
		x_return_status := FND_API.G_RET_STS_ERROR;
		RETURN;
	ELSE
		arp_standard.debug ('Receipt date is valid for instrument assignment.');
	END IF ;

    EXCEPTION WHEN NO_DATA_FOUND THEN
	  arp_standard.debug ( 'No Data found while getting date range for instrument assignment '|| sqlerrm);
          FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
          FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','No data range found for instrument assignment.');
          FND_MSG_PUB.Add;
	  x_return_status := FND_API.G_RET_STS_ERROR;
	  RETURN;
    WHEN OTHERS THEN
	  arp_standard.debug ( 'Exception while getting date range for instrument assignment '|| sqlerrm);
          FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
          FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','Error getting data range found for instrument assignment.');
          FND_MSG_PUB.Add;
	  x_return_status := FND_API.G_RET_STS_ERROR;
	  RETURN;
    END ;


        l_payer_rec.Payment_Function := 'CUSTOMER_PAYMENT';
        l_payer_rec.Party_Id :=  l_party_id;                  -- receipt customer party id mandatory
        l_payer_rec.org_id   := l_org_id;
        l_payer_rec.org_type := 'OPERATING_UNIT';
        l_payer_rec.Cust_Account_Id :=l_customer_id ;         -- receipt customer account_id
        l_payer_rec.Account_Site_Id :=l_customer_site_use_id; -- receipt customer site_id

        if l_customer_site_use_id is NULL  THEN

          l_payer_rec.org_id := NULL;
          l_payer_rec.org_type := NULL;

        end if;

        l_trxn_attribs_rec.Originating_Application_Id := arp_standard.application_id;
        l_trxn_attribs_rec.order_id :=  l_receipt_number;
        l_trxn_attribs_rec.Trxn_Ref_Number1 := 'RECEIPT';
        l_trxn_attribs_rec.Trxn_Ref_Number2 := l_receipt_number;
        l_assignment_id := l_assignment_id;
        l_trxn_attribs_rec.copy_instr_assign_id := l_assignment_id;
        lc_trxn_entity_id(1):= l_payment_trxn_extension_id;


   arp_standard.debug('l_payer.payment_function :<' || l_payer_rec.payment_function  || '>');
   arp_standard.debug('l_payer.Party_Id         :<' || l_payer_rec.Party_Id || '>');
   arp_standard.debug('l_payer.Org_Type         :<' || l_payer_rec.Org_Type || '>');
   arp_standard.debug('l_payer.Org_id           :<' || l_payer_rec.Org_id || '>');
   arp_standard.debug('l_payer.Cust_Account_Id  :<' || l_payer_rec.Cust_Account_Id || '>');
   arp_standard.debug('l_trxn_attribs.Originating_Application_Id :<'
                                  || l_trxn_attribs_rec.Originating_Application_Id || '>');
   arp_standard.debug('l_trxn_attribs.order_id  :<'|| l_trxn_attribs_rec.order_id || '>');
   arp_standard.debug('l_assignment_id          :<'|| l_assignment_id || '>');
   arp_standard.debug('payment_trx_extension_id          :<'|| l_payment_trxn_extension_id || '>');

                  IBY_FNDCPT_TRXN_PUB.Copy_Transaction_Extension
                     ( p_api_version        => 1.0,
                       p_init_msg_list      => FND_API.G_TRUE,
                       p_commit             => FND_API.G_FALSE,
                       x_return_status      => l_return_status,
                       x_msg_count          => l_msg_count,
                       x_msg_data           => l_msg_data,
                       p_payer              => l_payer_rec,
                       p_payer_equivalency  => IBY_FNDCPT_COMMON_PUB.G_PAYER_EQUIV_UPWARD,
                       p_entities           => lc_trxn_entity_id,
                       p_trxn_attribs       => l_trxn_attribs_rec,
                       x_entity_id          => p_trxn_entity_id,          -- out parm
                       x_response           => l_response_rec             -- out
                      );

                 IF l_return_status = FND_API.G_RET_STS_SUCCESS  THEN
                         o_payment_trxn_extension_id  := p_trxn_entity_id ;

                           arp_standard.debug('the copied value of trx_entn is ' || o_payment_trxn_extension_id );
                 END IF;


               arp_standard.debug('x_return_status  :<' || l_return_status || '>');
               arp_standard.debug('x_msg_count      :<' || l_msg_count || '>');

    FOR i IN 1..l_msg_count LOOP
              arp_standard.debug('x_msg #' || TO_CHAR(i) || ' = <' ||
              SUBSTR(fnd_msg_pub.get(p_msg_index => i,p_encoded => FND_API.G_FALSE),1,150) || '>');
    END LOOP;


   IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN

                 arp_standard.debug('create_cash_127');
       FND_MESSAGE.set_name('AR', 'AR_CC_AUTH_FAILED');
       FND_MSG_PUB.Add;

        IF  l_response_rec.result_Code is NOT NULL THEN

         ---Raise the PAYMENT error code concatenated with the message

          l_cpy_msg_data := substrb( l_response_rec.Result_Code || ': '||
                                   l_response_rec.Result_Message , 1, 240);

          arp_standard.debug(  'l_cpy_msg_data: ' || l_cpy_msg_data);
          FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
          FND_MESSAGE.SET_TOKEN('GENERIC_TEXT',l_cpy_msg_data);

          FND_MSG_PUB.Add;

        END IF;

      FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                                 p_count  =>  x_msg_count,
                                 p_data   => x_msg_data );

                  x_return_status := l_return_status;
                  RETURN;

   END IF;


END Copy_payment_extension;

-- bichatte payment uptake
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
	      p_receipt_date		    IN DATE DEFAULT NULL
                 ) IS

            l_return_status                 VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
            l_msg_count                     NUMBER;
            l_msg_data                      VARCHAR2(2000);

            l_payer_rec                    IBY_FNDCPT_COMMON_PUB.PayerContext_rec_type;
            l_assignment_id             NUMBER;
            l_trxn_attribs_rec            IBY_FNDCPT_TRXN_PUB.TrxnExtension_rec_type;
            l_extension_id                NUMBER;
            l_init_extension_id          NUMBER;
            l_result_rec                    IBY_FNDCPT_COMMON_PUB.Result_rec_type;

            l_customer_id                ra_customer_trx.paying_customer_id%type;
            l_customer_site_use_id  ra_customer_trx.paying_site_use_id%type;
            l_org_id                         ra_customer_trx.org_id%type;
            l_party_id                      hz_parties.party_id%type;
            l_trx_number                 ra_customer_trx.trx_number%type;
            l_payment_channel_code       ar_receipt_methods.payment_channel_code%type;
            l_customer_trx_id          ra_customer_trx.customer_trx_id%type;

	    l_start_date		    DATE ;
	    l_end_date			    DATE ;

    BEGIN

        l_init_extension_id := p_payment_trxn_extension_id;
        l_customer_id := p_customer_id;

    IF l_init_extension_id is NOT NULL THEN

                  SELECT INSTR_ASSIGNMENT_ID
                   into   l_assignment_id
                   FROM   iby_fndcpt_tx_extensions
                   where  trxn_extension_id = l_init_extension_id;


                  SELECT party.party_id
                  INTO      l_party_id
                  FROM   hz_cust_accounts hca,
                               hz_parties    party
                  WHERE  hca.party_id = party.party_id
                   AND    hca.cust_account_id = l_customer_id ;

                        SELECT payment_channel_code
     		INTO   l_payment_channel_code
    		 from ar_receipt_methods
    		 where receipt_method_id = p_receipt_method_id;


/* Start - Bug 13056525 : Get start and end date for instrument assignment. */
    BEGIN
	SELECT i.start_date, i.end_date
	INTO   l_start_date, l_end_date
	FROM   iby_fndcpt_tx_extensions x, iby_pmt_instr_uses_all i
	WHERE  x.instr_assignment_id = i.instrument_payment_use_id
	AND    x.trxn_extension_id = p_payment_trxn_extension_id
	AND    x.INSTR_ASSIGNMENT_ID = l_assignment_id;

	arp_standard.debug ('p_payment_trxn_extension_id: '|| p_payment_trxn_extension_id);
	arp_standard.debug ('l_assignment_id: '|| l_assignment_id);
	arp_standard.debug ('l_start_date: '|| l_start_date);
	arp_standard.debug ('l_end_date: '|| l_end_date);
	arp_standard.debug ('p_receipt_date: '|| p_receipt_date);

        IF p_receipt_date NOT BETWEEN l_start_date AND NVL(l_end_date, to_date('31-12-4712','DD-MM-YYYY')) THEN
		arp_standard.debug ( 'Receipt date out of instrument assignment range. Receipt will not be created for this instrument.');
		FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
		FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','Instrument assignment date range out of bound.');
		FND_MSG_PUB.Add;
		x_return_status := FND_API.G_RET_STS_ERROR;
		RETURN;
	ELSE
		arp_standard.debug ('Receipt date is valid for instrument assignment.');
	END IF ;

    EXCEPTION WHEN NO_DATA_FOUND THEN
	  arp_standard.debug ( 'No Data found while getting date range for instrument assignment '|| sqlerrm);
          FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
          FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','No data range found for instrument assignment.');
          FND_MSG_PUB.Add;
	  x_return_status := FND_API.G_RET_STS_ERROR;
	  RETURN;
    WHEN OTHERS THEN
	  arp_standard.debug ( 'Exception while getting date range for instrument assignment '|| sqlerrm);
          FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
          FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','Error getting data range found for instrument assignment.');
          FND_MSG_PUB.Add;
	  x_return_status := FND_API.G_RET_STS_ERROR;
	  RETURN;
    END ;
/* End - Bug 13056525 : Get start and end date for instrument assignment. */


     /* pouplate values into the variables */

        l_payer_rec.Payment_Function := 'CUSTOMER_PAYMENT';
        l_payer_rec.Party_Id :=  l_party_id;                  -- receipt customer party id mandatory
        l_payer_rec.org_id   := p_org_id;
        l_payer_rec.org_type := 'OPERATING_UNIT';
        l_payer_rec.Cust_Account_Id := p_customer_id ;         -- receipt customer account_id
        l_payer_rec.Account_Site_Id :=p_customer_site_use_id; -- receipt customer site_id

        if p_customer_site_use_id is NULL  THEN

          l_payer_rec.org_id := NULL;
          l_payer_rec.org_type := NULL;

        end if;
        l_trxn_attribs_rec.Originating_Application_Id := arp_standard.application_id;
        l_trxn_attribs_rec.order_id := p_receipt_number ;
        l_trxn_attribs_rec.Trxn_Ref_Number1 := 'RECEIPT';
        l_trxn_attribs_rec.Trxn_Ref_Number2 :=  p_cash_receipt_id;
        l_assignment_id := l_assignment_id;


       /* reset the value of l_extension_id */



 IBY_FNDCPT_TRXN_PUB.Create_Transaction_Extension
   (
   p_api_version        =>1.0,
   p_init_msg_list      =>FND_API.G_TRUE,
   p_commit             =>FND_API.G_FALSE,
   x_return_status      =>l_return_status,
   x_msg_count          =>l_msg_count,
   x_msg_data           =>l_msg_data,
   p_payer              =>l_payer_rec,
   p_payer_equivalency  =>IBY_FNDCPT_COMMON_PUB.G_PAYER_EQUIV_UPWARD,
   p_pmt_channel         =>l_payment_channel_code,
   p_instr_assignment   =>l_assignment_id,
   p_trxn_attribs           =>l_trxn_attribs_rec,
   x_entity_id               =>l_extension_id,
   x_response              =>l_result_rec
   );


      IF l_return_status = FND_API.G_RET_STS_SUCCESS  THEN

                       o_payment_trxn_extension_id := l_extension_id;

                arp_standard.debug(to_char(SQL%ROWCOUNT) || 'PMT_EXTN_ID  row(s) updated.');

      END IF;

    FOR i IN 1..l_msg_count LOOP
              arp_standard.debug('x_msg #' || TO_CHAR(i) || ' = <' ||
              SUBSTR(fnd_msg_pub.get(p_msg_index => i,p_encoded => FND_API.G_FALSE),1,150) || '>');
    END LOOP;


           IF l_return_status <> FND_API.G_RET_STS_SUCCESS  THEN
                    arp_standard.debug('FAILED: ' ||l_result_rec.result_code);
                    arp_standard.debug('PARM-l_payer_rec.Payment_Function ' ||l_payer_rec.Payment_Function);
                    arp_standard.debug('PARM-l_payer_rec.party_id ' ||l_payer_rec.Party_Id);
                    arp_standard.debug('PARM-l_payer_rec.org_id ' ||l_payer_rec.org_id);
                    arp_standard.debug('PARM-l_payer_rec.org_type ' ||l_payer_rec.org_type);
                    arp_standard.debug('PARM-l_payer_rec.customer_id ' ||l_payer_rec.Cust_Account_Id);
                    arp_standard.debug('PARM-l_payer_rec.customer_site_id ' ||l_payer_rec.Account_Site_Id);
                    arp_standard.debug('PARM-l_trxn_attribs_rec.Originating_Application_Id ' ||l_trxn_attribs_rec.Originating_Application_Id);
                    arp_standard.debug('PARM- l_trxn_attribs_rec.order_id ' ||l_trxn_attribs_rec.order_id);
                    arp_standard.debug('PARM-l_trxn_attribs_rec.Trxn_Ref_Number1 ' ||l_trxn_attribs_rec.Trxn_Ref_Number1);
                    arp_standard.debug('PARM-l_assignment_id ' ||l_assignment_id);


                  FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                                 p_count  =>  x_msg_count,
                                 p_data   => x_msg_data );

                  x_return_status := l_return_status;
                  RETURN;


           END IF;


   END IF;  /* payment_trxn_extension_id is not null */

     EXCEPTION
        WHEN OTHERS THEN
            arp_standard.debug('ERROR IN CREATION ');
           RAISE;
      END Create_payment_extension;


-- bichatte payment uptake end

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
      /* tca uptake */
      p_customer_name                    IN  hz_parties.party_name%TYPE DEFAULT NULL,
      p_customer_number                  IN  hz_cust_accounts.account_number%TYPE DEFAULT NULL,
      p_customer_bank_account_id         IN  ar_cash_receipts.customer_bank_account_id%TYPE DEFAULT NULL,
      /* 6612301 */
      p_customer_bank_account_num        IN  iby_ext_bank_accounts_v.bank_account_number%TYPE DEFAULT NULL,
      p_customer_bank_account_name       IN  iby_ext_bank_accounts_v.bank_account_name%TYPE DEFAULT NULL,
      p_payment_trxn_extension_id        IN   NUMBER DEFAULT NULL,  /* bichatte payment uptake */
      p_location                         IN  hz_cust_site_uses.location%TYPE DEFAULT NULL,
      p_customer_site_use_id             IN  hz_cust_site_uses.site_use_id%TYPE DEFAULT NULL,
      p_default_site_use                 IN VARCHAR2 DEFAULT 'Y',   --bug4448307-4509459
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
      p_call_payment_processor    IN VARCHAR2 DEFAULT FND_API.G_FALSE,
      p_org_id             IN NUMBER  DEFAULT NULL
      )  IS
l_cash_receipt_id  NUMBER(15);
l_create_return_status  VARCHAR2(1);
l_create_msg_count NUMBER;
l_create_msg_data  VARCHAR2(2000);
l_payment_trxn_extension_id  ar_cash_receipts.payment_trxn_extension_id%TYPE;

-- OSTEINME 3/2/2001: added return variable for credit card call
l_cc_return_status VARCHAR2(1);		-- credit card return status
l_response_error_code  VARCHAR2(80);
BEGIN
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('ar_receipt_api.Create_and_apply ()+');
  END IF;

       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

        SAVEPOINT Create_Apply_PVT;
      --calling the internal create_cash routine
     Create_cash_1(
                 p_api_version,
                 p_init_msg_list,
                 FND_API.G_FALSE,  --p_commit is passed as FND_API.G_FALSE here but the actual value is passed i Apply routine
                 FND_API.G_VALID_LEVEL_FULL,
                 l_create_return_status,
                 l_create_msg_count,
                 l_create_msg_data,
                 -- Receipt info. parameters
                 p_usr_currency_code,
                 p_currency_code,
                 p_usr_exchange_rate_type,
                 p_exchange_rate_type,
                 p_exchange_rate,
                 p_exchange_rate_date,
                 p_amount,
                 p_factor_discount_amount,
                 p_receipt_number,
                 p_receipt_date,
                 p_gl_date,
                 p_maturity_date,
                 p_postmark_date,
                 p_customer_id,
                 p_customer_name,
                 p_customer_number,
                 p_customer_bank_account_id,
                 p_customer_bank_account_num,
                 p_customer_bank_account_name,
                 p_payment_trxn_extension_id,
                 p_location,
                 p_customer_site_use_id,
                 p_default_site_use,    --bug4448307-4509459
                 p_customer_receipt_reference,
                 p_override_remit_account_flag,
                 p_remittance_bank_account_id,
                 p_remittance_bank_account_num,
                 p_remittance_bank_account_name,
                 p_deposit_date,
                 p_receipt_method_id,
                 p_receipt_method_name,
                 p_doc_sequence_value,
                 p_ussgl_transaction_code,
                 p_anticipated_clearing_date,
                 p_called_from,
                 p_attribute_rec,
       -- ******* Global Flexfield parameters *******
                 p_global_attribute_rec ,
                 p_receipt_comments,
      --   ***  Notes Receivable Additional Information  ***
                 p_issuer_name,
                 p_issue_date,
                 p_issuer_bank_branch_id,
                 p_customer_trx_id,
                 p_trx_number,
                 p_installment,
                 p_applied_payment_schedule_id,
                 'CREATE_AND_APPLY', --used internally to differentiate between create_cash and create_and_apply
                 p_org_id,
      --   ** OUT NOCOPY variables
                 l_cash_receipt_id --out variable
                 );
          IF PG_DEBUG in ('Y', 'C') THEN
             arp_util.debug('Apply: ' || 'Receipt create_return_status '||l_create_return_status);
          END IF;
           --IF the receipt creation part returns no errors then
           --call the application routine.
           IF l_create_return_status = FND_API.G_RET_STS_SUCCESS THEN


              IF l_create_msg_count = 1 THEN
                /* If one message, like warning, then put this back on stack as the
                   Create routine must have removed it from the stack and put it on x_msg_data
                 */
                  FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                  FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','CREATE_AND_APPLY : '||l_create_msg_data);
                  FND_MSG_PUB.Add;
               END IF;

              Apply( p_api_version                  => p_api_version,
                     p_init_msg_list                => FND_API.G_FALSE, --message stack is not initialized here.
                     p_commit                       => p_commit,
                     p_validation_level             => FND_API.G_VALID_LEVEL_FULL,
                     x_return_status                => x_return_status,
                     x_msg_count                    => x_msg_count,
                     x_msg_data                     => x_msg_data,
                     p_cash_receipt_id              => l_cash_receipt_id,
                     p_trx_number                   => p_trx_number,
                     p_customer_trx_id              => p_customer_trx_id,
                     p_installment                  => p_installment,
                     p_applied_payment_schedule_id  => p_applied_payment_schedule_id,
                     p_amount_applied               => p_amount_applied,
                     p_amount_applied_from          => p_amount_applied_from,
                     p_trans_to_receipt_rate        => p_trans_to_receipt_rate,
                     p_discount                     => p_discount,
                     p_apply_date                   => p_apply_date,
                     p_apply_gl_date                => p_apply_gl_date,
                     p_ussgl_transaction_code       => app_ussgl_transaction_code,
                     p_customer_trx_line_id	    => p_customer_trx_line_id,
                     p_line_number                  => p_line_number,
                     p_show_closed_invoices         => p_show_closed_invoices,
                     p_called_from                  => p_called_from,
                     p_move_deferred_tax            => p_move_deferred_tax,
                     p_link_to_trx_hist_id          => p_link_to_trx_hist_id,
                     p_attribute_rec                => app_attribute_rec,
                     p_global_attribute_rec         => app_global_attribute_rec,
                     p_comments                     => app_comments,
                     p_org_id                       => p_org_id
                      );

                  --If the application fails then we need to rollback all the changes
                  --made in the create() routine also.
                  IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                     ROLLBACK TO Create_Apply_PVT;
                  ELSE

                     -- OSTEINME 3/2/2001: Enhancements for iReceivables
                     -- charge credit card if needed.  Note: this only
                     -- happens if the receipt and application creation
                     -- was successful.  All relevant information for the
                     -- payment can be derived from the cash receipt.

                     IF PG_DEBUG in ('Y', 'C') THEN
                        arp_standard.debug('Apply: ' || 'Checking p_call_payment_processor: ' || p_call_payment_processor);
                     END IF;

                     if (p_call_payment_processor = FND_API.G_TRUE) then

                             l_payment_trxn_extension_id := p_payment_trxn_extension_id;

                         process_payment_1(
		               p_cash_receipt_id     => l_cash_receipt_id,
                               p_called_from         => p_called_from,
                               p_response_error_code => l_response_error_code,
                               x_msg_count           => l_create_msg_count,
                               x_msg_data            => l_create_msg_data,
		               x_return_status       => l_cc_return_status,
                               p_payment_trxn_extension_id => l_payment_trxn_extension_id);

                       -- If the payment processor call fails, then we
                       -- need to rollback all the changes
                       -- made in the create() and apply() routines also.

                       IF l_cc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                          ROLLBACK TO Create_Apply_PVT;
                          x_return_status := l_cc_return_status;
                          return; -- exit back to caller
                       END IF;

                     end if;  -- if p_call_payment_processor = fnd_api.g_true

                     -- OSTEINME 2/27/2001: bug 1659048:
                     -- need to pass back cr_id
                     p_cr_id := l_cash_receipt_id;

                  END IF;
            ELSE
             x_return_status := l_create_return_status;
             x_msg_count     := l_create_msg_count;
             x_msg_data      := l_create_msg_data;
             Return;
            END IF;

  IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('ar_receipt_api.Create_and_apply ()-');
  END IF;
EXCEPTION
 WHEN others THEN
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('Exception : Create_and_apply() ');
  END IF;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
         FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','CREATE_AND_APPLY : '||SQLERRM);
         FND_MSG_PUB.Add;
END Create_and_apply;

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
      p_payment_trxn_extension_id    IN NUMBER DEFAULT NULL, /* bichatte payment uptake */
      p_location                   IN  hz_cust_site_uses.location%TYPE DEFAULT NULL,
      p_customer_site_use_id       IN  hz_cust_site_uses.site_use_id%TYPE DEFAULT NULL,
      p_default_site_use                 IN VARCHAR2 DEFAULT 'Y', --bug 4448307-4509459
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
      ) IS

      l_cash_receipt_id   ar_cash_receipts.cash_receipt_id%type;

l_create_return_status  VARCHAR2(1);
l_create_msg_count NUMBER;
l_create_msg_data  VARCHAR2(2000);

l_apply_return_status  VARCHAR2(1);
l_apply_msg_count NUMBER;
l_apply_msg_data  VARCHAR2(2000);

l_cc_return_status      VARCHAR2(1);

l_api_name       CONSTANT VARCHAR2(20) := 'Create_Apply_On_Acc';
l_api_version    CONSTANT NUMBER       := 1.0;
l_creation_method_code   VARCHAR2(50);
l_response_error_code VARCHAR2(80);
l_payment_trxn_extension_id  ar_cash_receipts.payment_trxn_extension_id%TYPE;

BEGIN

     IF PG_DEBUG in ('Y', 'C') THEN
      arp_standard.debug('ar_receipt_api_pub.Create_Apply_On_Acc() +');
     END IF;


     /*------------------------------------+
      |   Standard start of API savepoint  |
      +------------------------------------*/
      SAVEPOINT Create_Apply_On_Acc;

      /*-----------------------------------------+
       |   Initialize return status to SUCCESS   |
       +-----------------------------------------*/

        x_return_status := FND_API.G_RET_STS_SUCCESS;

      /*--------------------------------------------------+
       |   Standard call to check for call compatibility  |
       +--------------------------------------------------*/
        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
              x_return_status := FND_API.G_RET_STS_ERROR;
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*--------------------------------------------------------------+
        |   Initialize message list if p_init_msg_list is set to TRUE  |
        +--------------------------------------------------------------*/
        IF FND_API.to_Boolean( p_init_msg_list )
          THEN
              FND_MSG_PUB.initialize;
        END IF;


        /*-------------------------------------------------+
         | Initialize the profile option package variables |
         +-------------------------------------------------*/
         initialize_profile_globals;

        /*-------------------------------------------------+
        | Call the internal routine to create receipt      |
        +--------------------------------------------------*/

         Create_cash_1(
           -- Standard API parameters.
             p_api_version ,
             p_init_msg_list,
             p_commit,
             p_validation_level,
             l_create_return_status,
             l_create_msg_count,
             l_create_msg_data ,
             -- Receipt info. parameters
             p_usr_currency_code, --the translated currency code
             p_currency_code    ,
             p_usr_exchange_rate_type ,
             p_exchange_rate_type     ,
             p_exchange_rate         ,
             p_exchange_rate_date    ,
             p_amount                ,
             p_factor_discount_amount,
             p_receipt_number        ,
             p_receipt_date          ,
             p_gl_date               ,
             p_maturity_date         ,
             p_postmark_date         ,
             p_customer_id           ,
             p_customer_name         ,
             p_customer_number       ,
             p_customer_bank_account_id ,
             p_customer_bank_account_num ,
             p_customer_bank_account_name ,
             p_payment_trxn_extension_id,   -- bichatte payment uptake project
             p_location               ,
             p_customer_site_use_id   ,
             p_default_site_use,    --bug4448307-4509459
             p_customer_receipt_reference ,
             p_override_remit_account_flag ,
             p_remittance_bank_account_id  ,
             p_remittance_bank_account_num ,
             p_remittance_bank_account_name ,
             p_deposit_date             ,
             p_receipt_method_id        ,
             p_receipt_method_name      ,
             p_doc_sequence_value       ,
             p_ussgl_transaction_code   ,
             p_anticipated_clearing_date ,
             p_called_from               ,
             p_attribute_rec         ,
              -- ******* Global Flexfield parameters *******
             p_global_attribute_rec  ,
             p_receipt_comments      ,
      --   ***  Notes Receivable Additional Information  ***
             p_issuer_name    ,
             p_issue_date     ,
             p_issuer_bank_branch_id  ,
      --added  parameters to differentiate between create_cash and create_and_apply
             NULL,
             NULL,
             NULL,
             NULL,
             'CREATE_CASH',
             p_org_id,
      --   ** OUT variables
             l_cash_receipt_id
              );


           IF PG_DEBUG in ('Y', 'C') THEN
             arp_util.debug(  'Receipt create_return_status '||l_create_return_status);
          END IF;


          /*------------------------------------------------------+
           | Check the return status from create_cash             |
           +------------------------------------------------------*/
          IF l_create_return_status <> FND_API.G_RET_STS_SUCCESS THEN

             x_return_status := l_create_return_status;
             ROLLBACK TO Create_Apply_On_Acc;
             FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                       p_count => l_create_msg_count,
                                       p_data  => l_create_msg_data);

             x_msg_count     := l_create_msg_count;
             x_msg_data      := l_create_msg_data;

             RETURN; -- exit back to caller

          ELSE       --l_create_return_status

              IF l_create_msg_count = 1 THEN

                 ---If one message, like warning, then put this back
                 ---on stack as the Create routine must have removed
                 ---it from the stack and put it on x_msg_data

                 FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                 FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','CREATE_AND_APPLY : '||l_create_msg_data);
                 FND_MSG_PUB.Add;
              END IF;

        /*------------------------------------------------------+
               | Call the internal routine to apply on account receipt|
               +------------------------------------------------------*/
              Apply_on_account(
                p_api_version               =>  p_api_version,
                p_init_msg_list             =>  p_init_msg_list,
                p_commit                    =>  p_commit,
                p_validation_level          =>  p_validation_level,
                x_return_status             =>  l_apply_return_status ,
                x_msg_count                 =>  l_apply_msg_count,
                x_msg_data                  =>  l_apply_msg_data ,
                p_cash_receipt_id           =>  l_cash_receipt_id,
                p_amount_applied            =>  p_amount_applied,
                p_apply_date                =>  p_apply_date,
                p_apply_gl_date             =>  p_apply_gl_date,
                p_ussgl_transaction_code    =>  p_ussgl_transaction_code,
                p_attribute_rec             =>  app_attribute_rec, /* 5731076 */
                p_global_attribute_rec      =>  p_global_attribute_rec,
                p_comments                  =>  app_comments,
                p_called_from               =>  'RAPI',
                p_application_ref_num       =>  p_application_ref_num,
                p_secondary_application_ref_id => p_secondary_application_ref_id,
                p_customer_reference           => p_customer_reference,
                p_customer_reason              => p_customer_reason,
                p_secondary_app_ref_type       => p_secondary_app_ref_type,
                p_secondary_app_ref_num        => p_secondary_app_ref_num,
                p_org_id                       => p_org_id
              );


              /*------------------------------------------------------+
               | Check the return status from Apply_on_account        |
               +------------------------------------------------------*/
              IF l_apply_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                 x_return_status := l_apply_return_status;
                 ROLLBACK TO Create_Apply_On_Acc;
                 FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count => l_apply_msg_count,
                                           p_data  => l_apply_msg_data);

                  x_msg_count     := l_apply_msg_count;
                  x_msg_data      := l_apply_msg_data;

                 RETURN; -- exit back to caller
              ELSE


                    IF PG_DEBUG in ('Y', 'C') THEN
                     arp_util.debug('Create_Apply_On_Acc: ' || 'Checking p_call_payment_processor: ' || p_call_payment_processor);
                    END IF;

                    IF ( p_call_payment_processor = FND_API.G_TRUE ) THEN

                        l_payment_trxn_extension_id := p_payment_trxn_extension_id;

                      /*------------------------------------------------------+
                       | Call the API to process Credit cards                 |
                       +------------------------------------------------------*/
                       Process_Payment_1(
                       p_cash_receipt_id          => l_cash_receipt_id,
                       p_called_from              => p_called_from,
                       p_response_error_code     => l_response_error_code,
                       x_msg_count               => x_msg_count,
                       x_msg_data                => x_msg_data,
                       x_return_status           => l_cc_return_status,
                       p_payment_trxn_extension_id => l_payment_trxn_extension_id);

                       IF PG_DEBUG in ('Y', 'C') THEN
                          arp_util.debug('Create_Apply_On_Acc: ' || 'Process_Credit_card return status: ' || l_cc_return_status);
                       END IF;

                       /*------------------------------------------------------+
                        | Check the return status from Process_Payment         |
                        +------------------------------------------------------*/
                       IF l_cc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                          x_return_status := l_cc_return_status;

                          IF PG_DEBUG in ('Y', 'C') THEN
                             arp_util.debug('Create_Apply_On_Acc: ' || 'p_payment_response_error_code: ' || l_response_error_code);
                          END IF;

                          ROLLBACK TO Create_Apply_On_Acc;
                          FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                      p_count => x_msg_count,
                                      p_data  => x_msg_data);
                          RETURN; -- exit back to caller
                       END IF;

                     END IF;  -- p_call_payment_processor

             END IF;    --l_apply_return_status

          END IF ; ---l_create_return_status

          /*------------------------------------------------------+
           | Initialize the OUT parameter p_cr_id
           +------------------------------------------------------*/
           p_cr_id := l_cash_receipt_id;

       IF PG_DEBUG in ('Y', 'C') THEN
          arp_standard.debug('ar_receipt_api_pub.Create_Apply_On_Acc()-');
       END IF;
EXCEPTION
WHEN OTHERS THEN

     IF PG_DEBUG in ('Y', 'C') THEN
        arp_util.debug('Create_Apply_On_Acc: ' || 'Exception:'|| SQLERRM);
     END IF;

     x_return_status :=  FND_API.G_RET_STS_ERROR ;
     FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
     FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','AR_RECEIPT_API_PUB.Create_Apply_On_Acc:'|| SQLERRM);
     FND_MSG_PUB.Add;
     ROLLBACK TO Create_Apply_On_Acc;
     FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                               p_count => x_msg_count,
                               p_data  => x_msg_data);


END Create_Apply_On_Acc;

PROCEDURE  reverse_cover(
                p_cash_receipt_id        IN NUMBER,
                p_reversal_category_code IN VARCHAR2,
                p_reversal_gl_date       IN DATE,
                p_reversal_date          IN DATE,
                p_reversal_reason_code   IN VARCHAR2,
                p_reversal_comments      IN VARCHAR2,
                p_attribute_record       IN attribute_rec_type,
                p_type                   IN VARCHAR2,
                p_called_from            IN VARCHAR2,
                p_return_status          OUT NOCOPY VARCHAR2

                 ) IS
l_rev_crh_id            NUMBER;
l_crh_rec		ar_cash_receipt_history%ROWTYPE;
l_cr_rec		ar_cash_receipts%ROWTYPE;
l_ps_rec		ar_payment_schedules%ROWTYPE;
BEGIN
  p_return_status := FND_API.G_RET_STS_SUCCESS;
       /*-------------------------------------------------+
        | Initialize SOB/org dependent variables          |
        +-------------------------------------------------*/
        arp_global.init_global;

	/*
	Added apr_standard.sysparm.org_id as IN parameter while calling
	arp_standard.init_standard. Bug 10016914
	*/
	arp_util.debug('Before calling ARP_STANDARD.INIT_STANDARD(), arp_standard.sysparm.org_id = ' || arp_standard.sysparm.org_id);
	arp_standard.init_standard(arp_standard.sysparm.org_id);

  -- --------------------------------------------------------------
  -- First lock existing records from database for update
  -- --------------------------------------------------------------

  -- get current cash_receipt_history record:

  l_crh_rec.cash_receipt_id	:= p_cash_receipt_id;
  arp_cr_history_pkg.nowaitlock_fetch_f_cr_id(l_crh_rec);

  -- get cash receipt record:

  l_cr_rec.cash_receipt_id 	:= p_cash_receipt_id;
  arp_cash_receipts_pkg.nowaitlock_fetch_p(l_cr_rec);

  -- get payment schedule record for cash receipt.
  IF p_type = 'CASH' THEN
     arp_proc_rct_util.get_ps_rec(l_cr_rec.cash_receipt_id,
                                  l_ps_rec);
  END IF;

  --we do not do anything with the fetched data as we just need to do the reversal of the receipt.
  --the existing routines have been used for locking (reusability)
 BEGIN
   arp_reverse_receipt.reverse(
                p_cash_receipt_id,
                p_reversal_category_code,
                p_reversal_gl_date,
                p_reversal_date,
                p_reversal_reason_code,
                p_reversal_comments,
                NULL,                   -- clear_batch_id
                p_attribute_record.attribute_category,
                p_attribute_record.attribute1,
                p_attribute_record.attribute2,
                p_attribute_record.attribute3,
                p_attribute_record.attribute4,
                p_attribute_record.attribute5,
                p_attribute_record.attribute6,
                p_attribute_record.attribute7,
                p_attribute_record.attribute8,
                p_attribute_record.attribute9,
                p_attribute_record.attribute10,
                p_attribute_record.attribute11,
                p_attribute_record.attribute12,
                p_attribute_record.attribute13,
                p_attribute_record.attribute14,
                p_attribute_record.attribute15,
                'RAPI',
                '1.0',
                l_rev_crh_id,
                p_called_from);

               /* Bug 4910860
               Validate if the accounting entries balance */
               arp_balance_check.Check_Recp_Balance(p_cash_receipt_id,NULL,'Y');

 EXCEPTION
   WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN

                      p_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','ARP_REVERSE_RECEIPT.REVERSE : '||SQLERRM);
                      FND_MSG_PUB.Add;

                      RETURN;
                ELSE
                   RAISE;
                END IF;
 END;
EXCEPTION
 WHEN others THEN
 IF PG_DEBUG in ('Y', 'C') THEN
    arp_util.debug('Apply: ' || 'EXCEPTION: reverse_cover()');
 END IF;
 raise;
END reverse_cover;


/* This is standard reversal */
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
      p_global_attribute_rec    IN global_attribute_rec_type DEFAULT global_attribute_rec_const,
      p_cancel_claims_flag      IN VARCHAR2 DEFAULT 'Y',
      p_org_id             IN NUMBER  DEFAULT NULL
       ) IS
l_api_name       CONSTANT VARCHAR2(20) := 'Create_cash';
l_api_version    CONSTANT NUMBER       := 1.0;

l_std_reversal_possible  VARCHAR2(1);
l_cash_receipt_id        NUMBER;
l_reversal_category_code VARCHAR2(20);
l_reversal_reason_code   VARCHAR2(30);
l_rev_crh_id           NUMBER;
l_receipt_state         VARCHAR2(30);
l_reversal_gl_date      DATE;
l_reversal_date         DATE;
l_receipt_gl_date         DATE;
l_rev_return_status       VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS;
l_clm_return_status       VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS;
l_val_return_status       VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS;
l_dflex_val_return_status VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS;
l_dflex_def_return_status VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS; /* Bug fix 3539008 */
l_dflex_val1_return_status VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS;
l_attribute_rec           attribute_rec_type;
--l_global_attribute_rec    global_attribute_rec_type_upd;
l_global_attribute_rec    global_attribute_rec_type;
l_glob_return_status      VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS;
l_def_id_return_status    VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS;
l_type                    VARCHAR2(20);
l_rev_cover_return_status       VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS;
l_msg_count               NUMBER;
l_msg_data                VARCHAR2(2000);
l_org_return_status VARCHAR2(1);
l_org_id                           NUMBER;

l_trxn_extn_id			   NUMBER;
l_pend_settlment_status       VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS;

l_receipt_method_id		NUMBER ;

l_exist_flag number;
l_xla_ev_rec   arp_xla_events.xla_events_type;
l_statement_number ce_statement_headers.statement_number%type;
BEGIN

       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

        SAVEPOINT Reverse_PVT;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*--------------------------------------------------------------+
        |   Initialize message list if p_init_msg_list is set to TRUE  |
        +--------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
          THEN
              FND_MSG_PUB.initialize;
        END IF;
       /*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        x_return_status := FND_API.G_RET_STS_SUCCESS;


        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Apply: ' || 'Reverse()+ ');
        END IF;


/* SSA change */
       l_org_id            := p_org_id;
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;
       ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);
 IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
 ELSE

        /*-------------------------------------------------+
         | Initialize the profile option package variables |
         +-------------------------------------------------*/

           initialize_profile_globals;



       /*---------------------------------------------+
        |   ========== Start of API Body ==========   |
        +---------------------------------------------*/

        --Assign IN parameter values to local variables
        --which are also used as assignment targets.

          l_cash_receipt_id        := p_cash_receipt_id;
          l_reversal_category_code := p_reversal_category_code;
          l_reversal_reason_code   := p_reversal_reason_code;
          l_reversal_gl_date       := trunc(p_reversal_gl_date);
          l_reversal_date          := trunc(p_reversal_date);
          l_attribute_rec          := p_attribute_rec;
          l_global_attribute_rec   := p_global_attribute_rec;

          /*-----------------------+
           |                       |
           |ID TO VALUE CONVERSION |
           |                       |
           +-----------------------*/

          ar_receipt_lib_pvt.Derive_reverse_ids(
                                      p_receipt_number,
                                      l_cash_receipt_id,
                                      p_reversal_category_name,
                                      l_reversal_category_code,
                                      p_reversal_reason_name,
                                      l_reversal_reason_code,
                                      l_def_id_return_status
                                      );
          IF PG_DEBUG in ('Y', 'C') THEN
             arp_util.debug('Apply: ' || 'l_def_id_return_status  :'||l_def_id_return_status);
          END IF;
          /*---------------------+
           |                     |
           |    DEFAULTING       |
           |                     |
           +---------------------*/


           ar_receipt_lib_pvt.default_reverse_info(
                                       l_cash_receipt_id,
                                       l_reversal_gl_date ,
                                       l_reversal_date ,
                                       l_receipt_state,
                                       l_receipt_gl_date,
                                       l_type );

          /*---------------------+
           |                     |
           |    VALIDATION       |
           |                     |
           +---------------------*/

        ar_receipt_val_pvt.validate_reverse_info(
                                        l_cash_receipt_id,
                                        l_receipt_gl_date,
                                        l_reversal_category_code,
                                        l_reversal_reason_code,
                                        l_reversal_gl_date,
                                        l_reversal_date,
                                        l_val_return_status
                                          );
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Apply: ' || 'l_val_return_status  :'||l_val_return_status);
        END IF;

      --Check if the reversal is possible.

        ar_receipt_val_pvt.check_std_reversible(
                                        p_cash_receipt_id,
                                        l_reversal_date, /* Bug fix 3135407 */
                                        l_receipt_state,
                                        p_called_from,
                                        l_std_reversal_possible
                                          );

       IF  l_std_reversal_possible <> 'Y' THEN
         IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug('Apply: ' || 'Standard reversal not possible for this receipt');
         END IF;
         FND_MESSAGE.SET_NAME('AR','AR_RAPI_NON_REVERSIBLE');
         FND_MSG_PUB.Add;
         l_rev_return_status := FND_API.G_RET_STS_ERROR;
       END IF;

     /*Bug 16789203 Adding validation to prevent the reversal of the
         Receipt for Receipts where data has not been converted   */
		arp_util.debug('Before calling arp_acct_event_pkg.upgrade_status_per_doc');
	Declare
        x_upgrade_status    VARCHAR2(100);
		x_return_status1		VARCHAR2(100);
		x_msg_count1		    NUMBER;
		x_msg_data1		    VARCHAR2(2000);
        l_msg_data1           VARCHAR2(2000);
    Begin

	arp_acct_event_pkg.upgrade_status_per_doc
		 (p_init_msg_list     => 'F', --BUG 20625046
		  p_entity_code       => 'RECEIPTS',
		  p_source_int_id     => l_cash_receipt_id,
		  x_upgrade_status    => x_upgrade_status,
		  x_return_status    => x_return_status1,
		  x_msg_count         => x_msg_count1,
		  x_msg_data          => x_msg_data1
		  );
		IF x_upgrade_status = 'N' THEN
			  arp_util.debug('Data has not been converted, Can not REVERSED');
			  FND_MESSAGE.SET_NAME('AR','AR_NOT_FULLY_UPG_DOC');
			  FND_MSG_PUB.ADD;
			  l_val_return_status := FND_API.G_RET_STS_ERROR;
		  END IF;

		 IF x_return_status1 <> 'S' THEN
			  IF x_msg_count1 > 1 THEN
				  FOR i IN 1..x_msg_count1 LOOP
				  l_msg_data1 := SUBSTRB(l_msg_data1 ||FND_MSG_PUB.Get(-2)||'-',1,2000);
				  END LOOP;
				  ELSE
				  l_msg_data1 := x_msg_data1;
			  END IF;
		  arp_util.debug('Exception in arp_acct_event_pkg.upgrade_status_per_doc, x_return_status is U');
                  FND_MESSAGE.SET_NAME('AR','GENERIC_MESSAGE');
		  fnd_message.set_token('GENERIC_MESSAGE',l_msg_data1||'->'||SQLERRM);
		  FND_MSG_PUB.Add;
		  l_val_return_status := FND_API.G_RET_STS_ERROR;
		 END IF;


    End;	--Bug 16789203

         Begin /*20654085 start*/
	 cep_standard.init_security;
 	Begin
	SELECT  max (cb_sh.statement_number) statement_number
	INTO l_statement_number
	FROM    ce_statement_headers cb_sh
	, ce_statement_lines cb_sl
	, ce_statement_recon_gt_v cb_sr
	, ar_cash_receipt_history crh_cb
	WHERE   crh_cb.cash_receipt_id = l_cash_receipt_id
	AND     crh_cb.cash_receipt_history_id = cb_sr.reference_id (+)
	AND     cb_sr.reference_type (+) = 'RECEIPT'
	AND     cb_sr.current_record_flag (+) = 'Y'
	AND     cb_sr.status_flag (+) = 'M'
	AND     cb_sr.statement_line_id = cb_sl.statement_line_id (+)
	AND     cb_sl.statement_header_id = cb_sh.statement_header_id (+);
  	Exception when others then
	    arp_standard.debug(' No statement number present in CE, defaulting statement_number as null ');
            l_statement_number := null;
    	End;
       	IF l_statement_number IS NOT NULL AND
	l_reversal_category_code = 'REV'
	THEN
	IF PG_DEBUG in ('Y', 'C') THEN
	arp_util.debug('statement number present in CE, cannot proceed to reverse.');
	END IF;
	FND_MESSAGE.SET_NAME('AR','AR_RPT_RECONCILD_NOT_RVSL');
	FND_MSG_PUB.ADD;
	l_pend_settlment_status:= FND_API.G_RET_STS_ERROR;
	END IF;
   	Exception when others then
   	arp_standard.debug(' Exception :-  '||sqlcode||'-'||sqlerrm);
  	End ; /*20654085 end*/

    /*Bug 7828491 Adding validation for avoiding reversal of receipt when
      Settlement is not run for remitted receipts*/
     BEGIN

        select cr.payment_trxn_extension_id into l_trxn_extn_id
        from ar_Cash_receipts cr, ar_cash_receipt_history crh
        where cr.cash_receipt_id=crh.cash_receipt_id
        and   crh.current_record_flag= 'Y'
        and   crh.status = 'REMITTED'
        and cr.cash_receipt_id = p_cash_receipt_id;

     EXCEPTION
     WHEN OTHERS THEN
     l_trxn_extn_id := NULL;
     END;

     IF l_trxn_extn_id is not null THEN
        IF arp_reverse_receipt.check_settlement_status(
             p_extension_id => l_trxn_extn_id)
        THEN
          FND_MESSAGE.SET_NAME('AR','AR_IBY_SETTLEMENT_PENDING');
          FND_MSG_PUB.ADD;
          l_pend_settlment_status:= FND_API.G_RET_STS_ERROR;
        END IF;
     END IF;
    -- Bug 2232366 - check for existence of claims and if they are cancellable
       IF arp_reverse_receipt.receipt_has_non_cancel_claims(
             p_cr_id => p_cash_receipt_id,
             p_include_trx_claims => 'Y')
       THEN
         FND_MESSAGE.SET_NAME('AR','AR_RW_NO_REVERSAL_WITH_CLAIMS');
         FND_MSG_PUB.Add;
         l_clm_return_status := FND_API.G_RET_STS_ERROR;
       ELSE
          arp_reverse_receipt.cancel_claims(
             p_cr_id => p_cash_receipt_id
           , p_include_trx_claims  => 'Y'
           , x_return_status =>  l_clm_return_status
           , x_msg_count     =>  l_msg_count
           , x_msg_data      =>  l_msg_data);
       END IF;

	/* Bug 11680143 : Skip DFF validation for AP/AR Netting (receipt method id = -1) */

	BEGIN
            Select receipt_method_id
    	    INTO   l_receipt_method_id
	    FROM   ar_cash_receipts
	    WHERE  cash_receipt_id  = l_cash_receipt_id ;

	EXCEPTION WHEN NO_DATA_FOUND THEN
		 arp_util.debug(  'No Data Found exception while getting Receipt Method Id  : '||sqlerrm);
		 x_return_status := FND_API.G_RET_STS_ERROR ;
	 WHEN OTHERS THEN
		 arp_util.debug(  'Others exception while getting Receipt Method Id  : '||sqlerrm);
		 x_return_status := FND_API.G_RET_STS_ERROR ;
	 END;

	-- start for bug 27573400
        --IF l_receipt_method_id = -1  THEN
	 IF  ( p_called_from in ('CC ERROR HANDLING') ) OR (l_receipt_method_id = -1 ) THEN
        -- end for bug   27573400
            NULL;
         ELSE
        --validate and default the flexfields
         ar_receipt_lib_pvt.Validate_Desc_Flexfield(
                                        l_attribute_rec,
                                        'AR_CASH_RECEIPTS',
                                        l_dflex_val_return_status
                                            );
		IF PG_DEBUG in ('Y', 'C') THEN
	           arp_util.debug('Apply: ' || 'l_dflex_val_return_status  :'||l_dflex_val_return_status);
		END IF;
        END IF;

       /* Bug fix 3539008 */
       /* If the descriptive flex field is not passed in or can not be defaulted,
          default it from the cash receipt */
        IF l_attribute_rec.attribute_category IS NULL THEN
          ar_receipt_lib_pvt.Default_Desc_Flexfield(
                                        l_attribute_rec,
                                        p_cash_receipt_id,
                                        l_dflex_def_return_status
                                            );
          IF l_attribute_rec.attribute_category IS NOT NULL THEN
             ar_receipt_lib_pvt.Validate_Desc_Flexfield(
                                         l_attribute_rec,
                                        'AR_CASH_RECEIPTS',
                                        l_dflex_val1_return_status
                                            );
          END IF;
        END IF;
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug(  'l_dflex_def_return_status  :'||l_dflex_def_return_status);
           arp_util.debug(  'l_dflex_val1_return_status  :'||l_dflex_val1_return_status);
        END IF;

        jg_ar_cash_receipts.reverse(
                                    l_cash_receipt_id,
                                    l_glob_return_status);

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Apply: ' || 'l_glob_return_status  :'||l_glob_return_status);
        END IF;
END IF;

        IF l_val_return_status <> FND_API.G_RET_STS_SUCCESS OR
           l_rev_return_status <> FND_API.G_RET_STS_SUCCESS OR
           l_clm_return_status <> FND_API.G_RET_STS_SUCCESS OR
           l_dflex_val_return_status <> FND_API.G_RET_STS_SUCCESS OR
           l_dflex_def_return_status <> FND_API.G_RET_STS_SUCCESS OR
           l_dflex_val1_return_status <> FND_API.G_RET_STS_SUCCESS OR
        --   l_glob_return_status  <> FND_API.G_RET_STS_SUCCESS OR
           l_def_id_return_status <> FND_API.G_RET_STS_SUCCESS OR
           l_pend_settlment_status <>  FND_API.G_RET_STS_SUCCESS THEN
         x_return_status := FND_API.G_RET_STS_ERROR;
        END IF;

        IF x_return_status <> FND_API.G_RET_STS_SUCCESS  THEN

            ROLLBACK TO Reverse_PVT;

             x_return_status := FND_API.G_RET_STS_ERROR ;

             FND_MSG_PUB.Count_And_Get(
                                        p_count => x_msg_count,
                                        p_data  => x_msg_data
                                       );

             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Apply: ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
             END IF;
             Return;
        END IF;

        -- Bug 5438627 : LLCA - Delete the activity record if llca exists. We need to modify the
        -- LLCA update logic to preserve the previous record details on AR_ACTIVITY_DETAILS instead
        --- of removing it.  Open bug 5397350  exist for this issue.
       /*
	delete from ar_activity_details
        where cash_receipt_id  = l_cash_receipt_id;
	*/

-- Bug 7241111 to retain the old application record under activity details

INSERT INTO AR_ACTIVITY_DETAILS(
                                CASH_RECEIPT_ID,
                                CUSTOMER_TRX_LINE_ID,
                                ALLOCATED_RECEIPT_AMOUNT,
                                AMOUNT,
                                TAX,
                                FREIGHT,
                                CHARGES,
                                LAST_UPDATE_DATE,
                                LAST_UPDATED_BY,
                                LINE_DISCOUNT,
                                TAX_DISCOUNT,
                                FREIGHT_DISCOUNT,
                                LINE_BALANCE,
                                TAX_BALANCE,
                                CREATION_DATE,
                                CREATED_BY,
                                LAST_UPDATE_LOGIN,
                                COMMENTS,
                                APPLY_TO,
                                ATTRIBUTE1,
                                ATTRIBUTE2,
                                ATTRIBUTE3,
                                ATTRIBUTE4,
                                ATTRIBUTE5,
                                ATTRIBUTE6,
                                ATTRIBUTE7,
                                ATTRIBUTE8,
                                ATTRIBUTE9,
                                ATTRIBUTE10,
                                ATTRIBUTE11,
                                ATTRIBUTE12,
                                ATTRIBUTE13,
                                ATTRIBUTE14,
                                ATTRIBUTE15,
                                ATTRIBUTE_CATEGORY,
                                GROUP_ID,
                                REFERENCE1,
                                REFERENCE2,
                                REFERENCE3,
                                REFERENCE4,
                                REFERENCE5,
                                OBJECT_VERSION_NUMBER,
                                CREATED_BY_MODULE,
                                SOURCE_ID,
                                SOURCE_TABLE,
                                LINE_ID,
			        CURRENT_ACTIVITY_FLAG)
                        SELECT
                                LLD.CASH_RECEIPT_ID,
                                LLD.CUSTOMER_TRX_LINE_ID,
                                LLD.ALLOCATED_RECEIPT_AMOUNT*-1,
                                LLD.AMOUNT*-1,
                                LLD.TAX*-1,
                                LLD.FREIGHT*-1,
                                LLD.CHARGES*-1,
                                LLD.LAST_UPDATE_DATE,
                                LLD.LAST_UPDATED_BY,
                                LLD.LINE_DISCOUNT,
                                LLD.TAX_DISCOUNT,
                                LLD.FREIGHT_DISCOUNT,
                                LLD.LINE_BALANCE,
                                LLD.TAX_BALANCE,
                                LLD.CREATION_DATE,
                                LLD.CREATED_BY,
                                LLD.LAST_UPDATE_LOGIN,
                                LLD.COMMENTS,
                                LLD.APPLY_TO,
                                LLD.ATTRIBUTE1,
                                LLD.ATTRIBUTE2,
                                LLD.ATTRIBUTE3,
                                LLD.ATTRIBUTE4,
                                LLD.ATTRIBUTE5,
                                LLD.ATTRIBUTE6,
                                LLD.ATTRIBUTE7,
                                LLD.ATTRIBUTE8,
                                LLD.ATTRIBUTE9,
                                LLD.ATTRIBUTE10,
                                LLD.ATTRIBUTE11,
                                LLD.ATTRIBUTE12,
                                LLD.ATTRIBUTE13,
                                LLD.ATTRIBUTE14,
                                LLD.ATTRIBUTE15,
                                LLD.ATTRIBUTE_CATEGORY,
                                LLD.GROUP_ID,
                                LLD.REFERENCE1,
                                LLD.REFERENCE2,
                                LLD.REFERENCE3,
                                LLD.REFERENCE4,
                                LLD.REFERENCE5,
                                LLD.OBJECT_VERSION_NUMBER,
                                LLD.CREATED_BY_MODULE,
                                LLD.SOURCE_ID,
                                LLD.SOURCE_TABLE,
                                ar_Activity_details_s.nextval,
                                'R'
                        FROM ar_Activity_details LLD
		        where LLD.cash_receipt_id = l_cash_receipt_id
			and nvl(LLD.CURRENT_ACTIVITY_FLAG, 'Y') = 'Y';

		   UPDATE ar_Activity_details dtl
		     set CURRENT_ACTIVITY_FLAG = 'N'
			where dtl.cash_receipt_id = l_cash_receipt_id
			and nvl(dtl.CURRENT_ACTIVITY_FLAG, 'Y') = 'Y';



     --Call the cover routine for entity handler to reverse the receipt

        reverse_cover(
                l_cash_receipt_id,
                l_reversal_category_code,
                l_reversal_gl_date,
                l_reversal_date,
                l_reversal_reason_code,
                p_reversal_comments,
                l_attribute_rec,
                l_type,
                p_called_from,
                l_rev_cover_return_status
                 );
        IF l_rev_cover_return_status <> FND_API.G_RET_STS_SUCCESS  THEN

            ROLLBACK TO Reverse_PVT;

             x_return_status := FND_API.G_RET_STS_ERROR ;

             FND_MSG_PUB.Count_And_Get(
                                        p_count => x_msg_count,
                                        p_data  => x_msg_data
                                       );

             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Apply: ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
             END IF;
             Return;
        ELSE

	  /*Bug14509245: Event Id not stamped on MCD for MISC reverse receipts*/
		  begin
		  --if the receipt is executed from concurrent program,
			  IF(arp_global.request_id IS NOT NULL) THEN
				IF PG_DEBUG in ('Y', 'C') THEN
				  arp_util.debug('Check if the receipts MCD exists with out eventids');
				end if;

				select count(*) into l_exist_flag
				from AR_MISC_CASH_DISTRIBUTIONS_ALL mcd, ar_cash_receipt_history_all rh
				where rh.cash_receipt_id = l_cash_receipt_id
				and mcd.cash_receipt_id = rh.cash_receipt_id
				and mcd.cash_receipt_history_id = rh.cash_receipt_history_id
				and mcd.request_id = arp_global.request_id
				and rh.postable_flag = 'Y'
				and mcd.posting_control_id = -3
				and mcd.event_id is null;

				 if(	l_exist_flag >0) then
				  IF PG_DEBUG in ('Y', 'C') THEN
					arp_util.debug('eventid with null exists for l_cash_receipt_id:'||l_cash_receipt_id);
							  end if;

				  l_xla_ev_rec.xla_from_doc_id := l_cash_receipt_id;
				  l_xla_ev_rec.xla_to_doc_id   := l_cash_receipt_id;
				  l_xla_ev_rec.xla_doc_table   := 'MCD';
				  l_xla_ev_rec.xla_mode        := 'O';
				  l_xla_ev_rec.xla_call        := 'D';

				  ARP_XLA_EVENTS.create_events(p_xla_ev_rec => l_xla_ev_rec);

				  IF PG_DEBUG in ('Y', 'C') THEN
					arp_util.debug('after stamping the eventid on MCD');
						end if;

				  end if;

				END IF;
			exception
			  when others then
				 IF PG_DEBUG in ('Y', 'C') THEN
				  arp_util.debug('Exception while stamping the event id on MCD');
				 end if;
			end;


	  --Bug 1847350: Added the check on p_commit and then the commit.

       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

           IF FND_API.To_Boolean( p_commit )
            THEN
                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply: ' || 'committing');
                END IF;
                Commit;
           END IF;


        END IF;


EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Apply: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Reverse_PVT;
                x_return_status := FND_API.G_RET_STS_ERROR ;

             --   Display_Parameters;

                FND_MSG_PUB.Count_And_Get( p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply: ' || SQLERRM, G_MSG_ERROR);
                END IF;
                ROLLBACK TO Reverse_PVT;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

               --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get( p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN

                      ROLLBACK TO Reverse_PVT;


                      x_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','REVERSE : '||SQLERRM);
                      FND_MSG_PUB.Add;

                      --If only one error message on the stack,
                      --retrive it

                     FND_MSG_PUB.Count_And_Get( p_count  =>  x_msg_count,
                                                 p_data   => x_msg_data
                                                );

                      RETURN;

                ELSE
                     x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                     FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                     FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','REVERSE : '||SQLERRM);
                     FND_MSG_PUB.Add;
                END IF;

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Apply: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Reverse_PVT;

                IF      FND_MSG_PUB.Check_Msg_Level
                THEN
                FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME,
                                        l_api_name
                                       );
                END IF;

             --   Display_Parameters;

                FND_MSG_PUB.Count_And_Get( p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );


END reverse;

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
      p_application_ref_num IN ar_receivable_applications.application_ref_num%TYPE,
      p_secondary_application_ref_id IN ar_receivable_applications.secondary_application_ref_id%TYPE,
      p_customer_reference IN ar_receivable_applications.customer_reference%TYPE,
      p_called_from IN VARCHAR2,
      p_customer_reason IN ar_receivable_applications.customer_reason%TYPE,
      p_secondary_app_ref_type IN
                ar_receivable_applications.secondary_application_ref_type%TYPE := null,
      p_secondary_app_ref_num IN
                ar_receivable_applications.secondary_application_ref_num%TYPE := null,
      p_org_id             IN NUMBER  DEFAULT NULL
	  ) IS
 l_api_name       CONSTANT VARCHAR2(20) := 'Apply_on_acount';
 l_api_version    CONSTANT NUMBER       := 1.0;
 l_cash_receipt_id NUMBER(15);
 l_amount_applied  NUMBER;
 l_apply_date      DATE;
 l_apply_gl_date   DATE;
 l_cr_gl_date      DATE;
 l_default_return_status  VARCHAR2(1);
 l_validation_return_status  VARCHAR2(1);
 l_id_conv_return_status  VARCHAR2(1);
 l_cr_unapp_amount  NUMBER;
 ln_rec_application_id  NUMBER;
 l_cr_date   DATE;
 l_cr_payment_schedule_id NUMBER;
 l_dflex_val_return_status  VARCHAR2(1);
 l_attribute_rec           attribute_rec_type;
 l_cr_currency_code     VARCHAR2(15);
 l_org_return_status VARCHAR2(1);
 l_org_id                           NUMBER;
 BEGIN

       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

      SAVEPOINT Apply_on_ac_PVT;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*--------------------------------------------------------------+
        |   Initialize message list if p_init_msg_list is set to TRUE  |
        +--------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
          THEN
              FND_MSG_PUB.initialize;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Apply_on_account()+ ');
        END IF;
       /*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        x_return_status := FND_API.G_RET_STS_SUCCESS;




/* SSA change */
       l_org_id            := p_org_id;
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;
       ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);
 IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
 ELSE


        /*-------------------------------------------------+
         | Initialize the profile option package variables |
         +-------------------------------------------------*/

           initialize_profile_globals;



       /*---------------------------------------------+
        |   ========== Start of API Body ==========   |
        +---------------------------------------------*/

     l_cash_receipt_id := p_cash_receipt_id;
     l_amount_applied  := p_amount_applied;
     l_apply_date      := trunc(p_apply_date);
     l_apply_gl_date   := trunc(p_apply_gl_date);
     l_attribute_rec   := p_attribute_rec;

          /*-----------------------+
           |                       |
           |ID TO VALUE CONVERSION |
           |                       |
           +-----------------------*/

   ar_receipt_lib_pvt.Default_cash_receipt_id(
                              l_cash_receipt_id ,
                              p_receipt_number ,
                              l_id_conv_return_status
                               );

      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('Apply: ' || 'Defaulting Ids Return_status = '||l_id_conv_return_status);
      END IF;
          /*---------------------+
           |                     |
           |    DEFAULTING       |
           |                     |
           +---------------------*/

      ar_receipt_lib_pvt.Default_on_ac_app_info(
                                  l_cash_receipt_id,
                                  l_cr_gl_date,
                                  l_cr_unapp_amount,
                                  l_cr_date,
                                  l_cr_payment_schedule_id,
                                  l_amount_applied,
                                  l_apply_gl_date,
                                  l_apply_date,
                                  l_cr_currency_code,
                                  l_default_return_status
                                  );
arp_util.debug('after ar_receipt_lib_pvt.default_on_ac_app_info');
          /*---------------------+
           |                     |
           |    VALIDATION       |
           |                     |
           +---------------------*/

      ar_receipt_val_pvt.validate_on_ac_app(
                              l_cash_receipt_id,
                              l_cr_gl_date,
                              l_cr_unapp_amount,
                              l_cr_date,
                              l_cr_payment_schedule_id,
                              l_amount_applied,
                              l_apply_gl_date,
                              l_apply_date,
                              l_validation_return_status,
                              NULL,
			      p_called_from
                               );
arp_util.debug('after ar_receipt_lib_pvt.validate_on_ac_info');

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Apply: ' || 'Validation return status :'||l_validation_return_status);
        END IF;

         --validate and default the flexfields
        ar_receipt_lib_pvt.Validate_Desc_Flexfield(
                                        l_attribute_rec,
                                        'AR_RECEIVABLE_APPLICATIONS',
                                        l_dflex_val_return_status
                                                );

      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('Apply: ' || '*****DUMPING ALL THE ENTITY HANDLER PARAMETERS  ***');
         arp_util.debug('Apply: ' || 'l_cr_payment_schedule_id : '||to_char(l_cr_payment_schedule_id));
         arp_util.debug('Apply: ' || 'l_amount_applied : '||to_char(l_amount_applied));
         arp_util.debug('l_apply_date : '||to_char(l_apply_date,'DD-MON-YY'));
         arp_util.debug('l_apply_gl_date : '||to_char(l_apply_gl_date,'DD-MON-YY'));
      END IF;
END IF;


      IF l_validation_return_status <> FND_API.G_RET_STS_SUCCESS  OR
         l_default_return_status <> FND_API.G_RET_STS_SUCCESS OR
         l_id_conv_return_status <> FND_API.G_RET_STS_SUCCESS OR
         l_dflex_val_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          x_return_status :=  FND_API.G_RET_STS_ERROR;
      END IF;

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS
         THEN

            ROLLBACK TO Apply_on_ac_PVT;

             x_return_status := FND_API.G_RET_STS_ERROR ;

             FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                        p_count => x_msg_count,
                                        p_data  => x_msg_data
                                       );

             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Apply: ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
             END IF;
             Return;
       END IF;

       --lock the receipt before calling the entity handler
       arp_cash_receipts_pkg.nowaitlock_p(p_cr_id => l_cash_receipt_id);

       --call the entity handler
    BEGIN

       arp_process_application.on_account_receipts (
                                  p_receipt_ps_id   => l_cr_payment_schedule_id,
                                  p_amount_applied  => l_amount_applied,
                                  p_apply_date      => l_apply_date,
                                  p_gl_date         => l_apply_gl_date,
                                  p_comments         => p_comments,
                                  p_ussgl_transaction_code => p_ussgl_transaction_code,
                                  p_attribute_category=> l_attribute_rec.attribute_category,
                                  p_attribute1        => l_attribute_rec.attribute1,
                                  p_attribute2        => l_attribute_rec.attribute2,
                                  p_attribute3        => l_attribute_rec.attribute3,
                                  p_attribute4        => l_attribute_rec.attribute4,
                                  p_attribute5        => l_attribute_rec.attribute5,
                                  p_attribute6        => l_attribute_rec.attribute6,
                                  p_attribute7        => l_attribute_rec.attribute7,
                                  p_attribute8        => l_attribute_rec.attribute8,
                                  p_attribute9        => l_attribute_rec.attribute9,
                                  p_attribute10       => l_attribute_rec.attribute10,
                                  p_attribute11       => l_attribute_rec.attribute11,
                                  p_attribute12       => l_attribute_rec.attribute12,
                                  p_attribute13       => l_attribute_rec.attribute13,
                                  p_attribute14       => l_attribute_rec.attribute14,
                                  p_attribute15       => l_attribute_rec.attribute15,
                                  p_global_attribute1 => p_global_attribute_rec.global_attribute1,
                                  p_global_attribute2 => p_global_attribute_rec.global_attribute2,
                                  p_global_attribute3 => p_global_attribute_rec.global_attribute3,
                                  p_global_attribute4 => p_global_attribute_rec.global_attribute4,
                                  p_global_attribute5 => p_global_attribute_rec.global_attribute5,
                                  p_global_attribute6 => p_global_attribute_rec.global_attribute6,
                                  p_global_attribute7 => p_global_attribute_rec.global_attribute7,
                                  p_global_attribute8 => p_global_attribute_rec.global_attribute8,
                                  p_global_attribute9 => p_global_attribute_rec.global_attribute9,
                                  p_global_attribute10 => p_global_attribute_rec.global_attribute10,
                                  p_global_attribute11 => p_global_attribute_rec.global_attribute11,
                                  p_global_attribute12 => p_global_attribute_rec.global_attribute12,
                                  p_global_attribute13 => p_global_attribute_rec.global_attribute13,
                                  p_global_attribute14 => p_global_attribute_rec.global_attribute14,
                                  p_global_attribute15 => p_global_attribute_rec.global_attribute15,
                                  p_global_attribute16 => p_global_attribute_rec.global_attribute16,
                                  p_global_attribute17 => p_global_attribute_rec.global_attribute17,
                                  p_global_attribute18 => p_global_attribute_rec.global_attribute18,
                                  p_global_attribute19 => p_global_attribute_rec.global_attribute19,
                                  p_global_attribute20 => p_global_attribute_rec.global_attribute20,
                                  p_global_attribute_category => p_global_attribute_rec.global_attribute_category,
                                  p_module_name         => 'RAPI',
                                  p_module_version      => p_api_version,
                                  -- *** OUT NOCOPY
                                  p_out_rec_application_id => ln_rec_application_id,
                                  p_application_ref_num => p_application_ref_num,
                                  p_secondary_application_ref_id => p_secondary_application_ref_id,
                                  p_secondary_app_ref_type => p_secondary_app_ref_type,
                                  p_secondary_app_ref_num => p_secondary_app_ref_num,
                                  p_customer_reference => p_customer_reference,
                                  p_customer_reason => p_customer_reason
                                   );

      --Bug 3628401
      -- Assign receivable_application_id to package global variable
      -- So, it can used to perform follow on operation on given application
      g_apply_on_account_out_rec.receivable_application_id :=
                                              ln_rec_application_id;

     EXCEPTION
       WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN
                     ROLLBACK TO Apply_on_ac_PVT;

                      --  Display_Parameters

                      x_return_status := FND_API.G_RET_STS_ERROR ;
                       FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                       FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','ARP_PROCESS_APPLICATION.ON_ACCOUNT_RECEIPTS : '||SQLERRM);
                       FND_MSG_PUB.Add;

                       FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                                                  p_count  =>  x_msg_count,
                                                  p_data   => x_msg_data
                                                );
                      RETURN;
                ELSE
                   RAISE;
                END IF;
     END;
       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Apply: ' || 'committing');
            END IF;
              Commit;
        END IF;
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Apply_on_account ()- ');
        END IF;
EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Apply: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Apply_on_ac_PVT;
                x_return_status := FND_API.G_RET_STS_ERROR ;

               -- Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply: ' || SQLERRM, G_MSG_ERROR);
                END IF;
                ROLLBACK TO Apply_on_ac_PVT;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

               --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN

                      ROLLBACK TO Apply_on_ac_PVT;

                      --If only one error message on the stack,
                      --retrive it

                      x_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','APPLY_ON_ACCOUNT : '||SQLERRM);
                      FND_MSG_PUB.Add;

                      --If only one error message on the stack,
                      --retrive it
                      FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                                 p_count  =>  x_msg_count,
                                                 p_data   => x_msg_data
                                                );

                      RETURN;

                ELSE
                      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','APPLY_ON_ACCOUNT : '||SQLERRM);
                      FND_MSG_PUB.Add;
                END IF;

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Apply: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Apply_on_ac_PVT;

                IF      FND_MSG_PUB.Check_Msg_Level
                THEN
                FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME,
                                        l_api_name
                                       );
                END IF;

             --   Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );
END Apply_on_account;

PROCEDURE Unapply_on_account(
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
      p_org_id             IN NUMBER  DEFAULT NULL
      ) IS
l_api_name       CONSTANT VARCHAR2(20) := 'Unapply_on_account';
l_api_version    CONSTANT NUMBER       := 1.0;
l_customer_trx_id               NUMBER;
l_cash_receipt_id               NUMBER;
l_receivable_application_id     NUMBER;
l_reversal_gl_date              DATE;
l_apply_gl_date                 DATE;
l_receipt_gl_date               DATE;
l_def_return_status             VARCHAR2(1);
l_val_return_status             VARCHAR2(1);
l_bal_due_remaining             NUMBER;
l_org_return_status VARCHAR2(1);
l_org_id                           NUMBER;
l_cr_unapp_amt                  NUMBER  ; /* Bug fix 3569640 */
BEGIN
       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

        SAVEPOINT Unapply_on_ac_PVT;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*--------------------------------------------------------------+
        |   Initialize message list if p_init_msg_list is set to TRUE  |
        +--------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
          THEN
              FND_MSG_PUB.initialize;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Unapply_on_account: ' || 'ar_receipt_api.Unapply_on_ac()+ ');
        END IF;
       /*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        x_return_status := FND_API.G_RET_STS_SUCCESS;

/* SSA change */
       l_org_id            := p_org_id;
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;
       ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);
 IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
 ELSE

        /*-------------------------------------------------+
         | Initialize the profile option package variables |
         +-------------------------------------------------*/

           initialize_profile_globals;


       /*---------------------------------------------+
        |   ========== Start of API Body ==========   |
        +---------------------------------------------*/

        --Assign IN parameter values to local variables
        --which are also used as assignment targets.

         l_cash_receipt_id   := p_cash_receipt_id;
         l_receivable_application_id  := p_receivable_application_id;
         l_reversal_gl_date := trunc(p_reversal_gl_date);


        /*------------------------------------------------+
         |  Derive the id's for the entered values.       |
         |  If both the values and the ids are specified, |
         |  the id's superceed the values                 |
         +------------------------------------------------*/

         ar_receipt_lib_pvt.derive_unapp_on_ac_ids(
                         p_receipt_number   ,
                         l_cash_receipt_id  ,
                         l_receivable_application_id ,
                         l_apply_gl_date     ,
                         l_def_return_status
                               );
         ar_receipt_lib_pvt.default_unapp_on_ac_act_info(
                         l_receivable_application_id ,
                         l_apply_gl_date            ,
                         l_cash_receipt_id          ,
                         l_reversal_gl_date         ,
                         l_receipt_gl_date
                          );

         ar_receipt_val_pvt.validate_unapp_on_ac_act_info(
                                      l_receipt_gl_date,
                                      l_receivable_application_id,
                                      l_reversal_gl_date,
                                      l_apply_gl_date,
                                      l_cr_unapp_amt, /* Bug fix 3569640 */
                                      l_val_return_status);

         IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug('Unapply_on_account: ' || 'validation return status :'||l_val_return_status);
         END IF;
END IF;

        IF l_val_return_status <> FND_API.G_RET_STS_SUCCESS OR
           l_def_return_status <> FND_API.G_RET_STS_SUCCESS  THEN
           x_return_status := FND_API.G_RET_STS_ERROR;
        END IF;

        IF x_return_status <> FND_API.G_RET_STS_SUCCESS
         THEN

            ROLLBACK TO Unapply_on_ac_PVT;

             x_return_status := FND_API.G_RET_STS_ERROR ;

             FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                        p_count => x_msg_count,
                                        p_data  => x_msg_data
                                       );

             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Unapply_on_account: ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
             END IF;
             Return;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Unapply_on_account: ' || '*******DUMP THE INPUT PARAMETERS ********');
           arp_util.debug('Unapply_on_account: ' || 'l_receivable_application_id :'||to_char(l_receivable_application_id));
           arp_util.debug('Unapply_on_account: ' || 'l_reversal_gl_date :'||to_char(l_reversal_gl_date,'DD-MON-YY'));
        END IF;

       --lock the receipt before calling the entity handler
       arp_cash_receipts_pkg.nowaitlock_p(p_cr_id => l_cash_receipt_id);


        --call the entity handler.
       BEGIN
          arp_process_application.reverse(
                                l_receivable_application_id,
                                l_reversal_gl_date,
                                trunc(sysdate),
                                'RAPI',
                                p_api_version,
                                l_bal_due_remaining );
       EXCEPTION
          WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN
                     ROLLBACK TO Unapply_on_ac_PVT;

                      --  Display_Parameters;
                      x_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','ARP_PROCESS_APPLICATION.REVERSE : '||SQLERRM);
                      FND_MSG_PUB.Add;

                       FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                                                  p_count  =>  x_msg_count,
                                                  p_data   => x_msg_data
                                                );
                      RETURN;
                ELSE
                   RAISE;
                END IF;
       END;

       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Unapply_on_account: ' || 'committing');
            END IF;
              Commit;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Unapply_on_account: ' || 'ar_receipt_api.Unapply_on_ac ()- ');
        END IF;


EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Unapply_on_account: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Unapply_on_account: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Unapply_on_ac_PVT;
                x_return_status := FND_API.G_RET_STS_ERROR ;

              --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Unapply_on_account: ' || SQLERRM, G_MSG_ERROR);
                END IF;
                ROLLBACK TO Unapply_on_ac_PVT;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

               --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN

                      ROLLBACK TO Unapply_on_ac_PVT;

                      --If only one error message on the stack,
                      --retrive it

                      x_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','UNAPPLY_ON_ACCOUNT : '||SQLERRM);
                      FND_MSG_PUB.Add;
                      FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                                 p_count  =>  x_msg_count,
                                                 p_data   => x_msg_data
                                                );

                      RETURN;

                ELSE
                      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','UNAPPLY_ON_ACCOUNT : '||SQLERRM);
                      FND_MSG_PUB.Add;
                END IF;

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Unapply_on_account: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Unapply_on_account: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Unapply_on_ac_PVT;

                IF      FND_MSG_PUB.Check_Msg_Level
                THEN
                FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME,
                                        l_api_name
                                       );
                END IF;

             --   Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );
END Unapply_on_account;

PROCEDURE Unapply_other_account(
    -- Standard API parameters.
      p_api_version      IN  NUMBER,
      p_init_msg_list    IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit           IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status    OUT NOCOPY VARCHAR2 ,
      x_msg_count        OUT NOCOPY NUMBER ,
      x_msg_data         OUT NOCOPY VARCHAR2 ,
   -- *** Receipt Info. parameters *****
      p_receipt_number   IN  ar_cash_receipts.receipt_number%TYPE,
      p_cash_receipt_id  IN  ar_cash_receipts.cash_receipt_id%TYPE,
      p_receivable_application_id   IN  ar_receivable_applications.receivable_application_id%TYPE,
      p_reversal_gl_date IN ar_receivable_applications.reversal_gl_date%TYPE,
      p_cancel_claim_flag         IN  VARCHAR2,
      p_called_from               IN  VARCHAR2,
      p_org_id             IN NUMBER  DEFAULT NULL
      ) IS
l_api_name       CONSTANT VARCHAR2(20) := 'Unapply_on_account';
l_api_version    CONSTANT NUMBER       := 1.0;
l_customer_trx_id               NUMBER;
l_cash_receipt_id               NUMBER;
l_receipt_number                ar_cash_receipts.receipt_number%TYPE;
l_receivable_application_id     NUMBER;
l_applied_ps_id                 NUMBER;
l_sec_app_ref_id                NUMBER;
l_amount_applied                NUMBER;
l_reversal_gl_date              DATE;
l_apply_gl_date                 DATE;
l_receipt_gl_date               DATE;
l_def_return_status             VARCHAR2(1);
l_val_return_status             VARCHAR2(1);
l_clm_return_status             VARCHAR2(1);
l_bal_due_remaining             NUMBER;
l_claim_reason_name             VARCHAR2(100);
l_claim_reason_code_id          NUMBER;
l_claim_number                  VARCHAR2(30);
l_org_return_status VARCHAR2(1);
l_org_id                           NUMBER;
l_cr_unapp_amt                  NUMBER; /* Bug fix 3569640 */
BEGIN
       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

        SAVEPOINT Unapply_other_ac_PVT;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                              p_current_version_number => l_api_version,
                              p_caller_version_number  => p_api_version,
                              p_api_name               => l_api_name,
                              p_pkg_name               => G_PKG_NAME
                              )
        THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*--------------------------------------------------------------+
        |   Initialize message list if p_init_msg_list is set to TRUE  |
        +--------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
          THEN
              FND_MSG_PUB.initialize;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('ar_receipt_api.Unapply_other_account()+ ');
        END IF;
       /*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        x_return_status := FND_API.G_RET_STS_SUCCESS;

/* SSA change */
       l_org_id            := p_org_id;
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;
       ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);
 IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
 ELSE
        /*-------------------------------------------------+
         | Initialize the profile option package variables |
         +-------------------------------------------------*/

           initialize_profile_globals;


       /*---------------------------------------------+
        |   ========== Start of API Body ==========   |
        +---------------------------------------------*/

        --Assign IN parameter values to local variables
        --which are also used as assignment targets.

         l_cash_receipt_id   := p_cash_receipt_id;
         l_receipt_number    := p_receipt_number;
         l_receivable_application_id  := p_receivable_application_id;
         l_reversal_gl_date := trunc(p_reversal_gl_date);
         --At present this routine supports only prepayments
         -- Bug 2270879 - updated to allow claims

         SELECT applied_payment_schedule_id
              , secondary_application_ref_id
              , amount_applied
         INTO   l_applied_ps_id
              , l_sec_app_ref_id
              , l_amount_applied
         FROM   ar_receivable_applications
         WHERE  receivable_application_id = p_receivable_application_id;

        /*------------------------------------------------+
         |  Derive the id's for the entered values.       |
         |  If both the values and the ids are specified, |
         |  the id's superceed the values                 |
         +------------------------------------------------*/

         ar_receipt_lib_pvt.derive_otheraccount_ids(
                         p_receipt_number  => p_receipt_number   ,
                         p_cash_receipt_id => l_cash_receipt_id  ,
                         p_applied_ps_id   => l_applied_ps_id,
                         p_receivable_application_id => l_receivable_application_id ,
                         p_apply_gl_date             =>  l_apply_gl_date     ,
                         p_cr_unapp_amt              =>  l_cr_unapp_amt, /* bug fix 3569640 */
                         p_return_status             => l_def_return_status
                               );

         ar_receipt_lib_pvt.default_unapp_on_ac_act_info(
                         p_receivable_application_id => l_receivable_application_id ,
                         p_apply_gl_date             => l_apply_gl_date          ,
                         p_cash_receipt_id           => l_cash_receipt_id          ,
                         p_reversal_gl_date          => l_reversal_gl_date         ,
                         p_receipt_gl_date           => l_receipt_gl_date
                          );

         -- Bug 3708728: unapplied amount set to null to prevent validation
         -- in the case of a receipt to receipt application
	 -- Bug 3809272 - validation on unapplied also prevented if called
	 -- as part of claim settlement
         IF p_called_from IN ('APPLY_OPEN_RECEIPT','TRADE_MANAGEMENT') THEN
            l_cr_unapp_amt := NULL;
         END IF;
         ar_receipt_val_pvt.validate_unapp_on_ac_act_info(
                                      p_receipt_gl_date => l_receipt_gl_date,
                                      p_receivable_application_id => l_receivable_application_id,
                                      p_reversal_gl_date => l_reversal_gl_date,
                                      p_apply_gl_date    => l_apply_gl_date,
                                      p_cr_unapp_amt     =>  l_cr_unapp_amt, /* bug fix 3569640 */
                                      p_return_status    => l_val_return_status);
         -- Bug 2270809 , bug 2751910
         -- If a claim investigation app, then update the claim.
         -- Bug 3708728: update_claim not called if validation errors exist

        IF (l_val_return_status = FND_API.G_RET_STS_SUCCESS AND
            l_def_return_status = FND_API.G_RET_STS_SUCCESS AND
            l_applied_ps_id = -4 AND
             NVL(p_called_from,'RAPI') <> 'TRADE_MANAGEMENT')
         THEN
           /* Bug 4170060 do not update with claim balance for partial
	      rct to rct applications */
           IF (NVL(p_called_from,'RAPI') = 'APPLY_OPEN_RECEIPT' AND
	       NVL(pg_update_claim_amount,0) <> 0) THEN
              NULL;
	   ELSE
              arp_process_application.update_claim(
                p_claim_id      =>  l_sec_app_ref_id
              , p_invoice_ps_id =>  NULL
              , p_customer_trx_id => NULL
              , p_amount        =>  0
              , p_amount_applied => l_amount_applied
              , p_apply_date    =>  trunc(SYSDATE)
              , p_cash_receipt_id => l_cash_receipt_id
              , p_receipt_number => l_receipt_number
              , p_action_type   => 'U'
              , x_claim_reason_code_id => l_claim_reason_code_id
              , x_claim_reason_name => l_claim_reason_name
              , x_claim_number => l_claim_number
              , x_return_status =>  l_clm_return_status
              , x_msg_count     =>  x_msg_count
              , x_msg_data      =>  x_msg_data);
           END IF;
         END IF;

         IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug('Unapply_other_account: ' || 'validation return status :'||l_val_return_status);
         END IF;
END IF;

        IF l_val_return_status <> FND_API.G_RET_STS_SUCCESS OR
           l_def_return_status <> FND_API.G_RET_STS_SUCCESS OR
           l_clm_return_status <> FND_API.G_RET_STS_SUCCESS  THEN
           x_return_status := FND_API.G_RET_STS_ERROR;
        END IF;

        IF x_return_status <> FND_API.G_RET_STS_SUCCESS
         THEN

            ROLLBACK TO Unapply_other_ac_PVT;

             x_return_status := FND_API.G_RET_STS_ERROR ;

             FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                        p_count => x_msg_count,
                                        p_data  => x_msg_data
                                       );

             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Unapply_other_account: ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
             END IF;
             Return;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Unapply_other_account: ' || '*******DUMP THE INPUT PARAMETERS ********');
           arp_util.debug('Unapply_other_account: ' || 'l_receivable_application_id :'||to_char(l_receivable_application_id));
           arp_util.debug('Unapply_other_account: ' || 'l_reversal_gl_date :'||to_char(l_reversal_gl_date,'DD-MON-YY'));
        END IF;

       --lock the receipt before calling the entity handler
       arp_cash_receipts_pkg.nowaitlock_p(p_cr_id => l_cash_receipt_id);


        --call the entity handler.
       BEGIN
	--Bug7194951
	IF nvl(p_called_from,'NONE') = 'PREPAYMENT' THEN
          arp_process_application.reverse(
                                p_ra_id   => l_receivable_application_id,
                                p_reversal_gl_date => l_reversal_gl_date,
                                p_reversal_date => trunc(sysdate),
                                p_module_name => 'RAPI',
                                p_module_version => p_api_version,
                                p_bal_due_remaining => l_bal_due_remaining,
				p_called_from =>p_called_from );
	ELSE
          arp_process_application.reverse(
                                p_ra_id   => l_receivable_application_id,
                                p_reversal_gl_date => l_reversal_gl_date,
                                p_reversal_date => trunc(sysdate),
                                p_module_name => 'RAPI',
                                p_module_version => p_api_version,
                                p_bal_due_remaining => l_bal_due_remaining );
        END IF;
       EXCEPTION
          WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN
                     ROLLBACK TO Unapply_other_ac_PVT;

                      --  Display_Parameters;
                      x_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','ARP_PROCESS_APPLICATION.REVERSE : '||SQLERRM);
                      FND_MSG_PUB.Add;

                       FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                                                  p_count  =>  x_msg_count,
                                                  p_data   => x_msg_data
                                                );
                      RETURN;
                ELSE
                   RAISE;
                END IF;
       END;

       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Unapply_other_account: ' || 'committing');
            END IF;
              Commit;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('ar_receipt_api.Unapply_other_account ()- ');
        END IF;


EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Unapply_other_account: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Unapply_other_account: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Unapply_other_ac_PVT;
                x_return_status := FND_API.G_RET_STS_ERROR ;

              --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Unapply_other_account: ' || SQLERRM, G_MSG_ERROR);
                END IF;
                ROLLBACK TO Unapply_other_ac_PVT;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

               --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN

                      ROLLBACK TO Unapply_other_ac_PVT;

                      --If only one error message on the stack,
                      --retrive it

                      x_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','UNAPPLY_ON_ACCOUNT : '||SQLERRM);
                      FND_MSG_PUB.Add;
                      FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                                 p_count  =>  x_msg_count,
                                                 p_data   => x_msg_data
                                                );

                      RETURN;

                ELSE
                      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','UNAPPLY_OTHER_ACCOUNT : '||SQLERRM);
                      FND_MSG_PUB.Add;
                END IF;

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Unapply_other_account: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Unapply_other_account: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Unapply_other_ac_PVT;

                IF      FND_MSG_PUB.Check_Msg_Level
                THEN
                FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME,
                                        l_api_name
                                       );
                END IF;

             --   Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );
END Unapply_other_account;

PROCEDURE Activity_application(
-- Standard API parameters.
      p_api_version                   IN  NUMBER,
      p_init_msg_list                 IN  VARCHAR2 := FND_API.G_FALSE,
      p_commit                        IN  VARCHAR2 := FND_API.G_FALSE,
      p_validation_level              IN  NUMBER   := FND_API.G_VALID_LEVEL_FULL,
      x_return_status                 OUT NOCOPY VARCHAR2,
      x_msg_count                     OUT NOCOPY NUMBER,
      x_msg_data                      OUT NOCOPY VARCHAR2,
  --  Receipt application parameters.
      p_cash_receipt_id               IN ar_cash_receipts.cash_receipt_id%TYPE DEFAULT NULL,
      p_receipt_number                IN ar_cash_receipts.receipt_number%TYPE DEFAULT NULL,
      p_amount_applied                IN ar_receivable_applications.amount_applied%TYPE DEFAULT NULL,
      p_applied_payment_schedule_id   IN ar_payment_schedules.payment_schedule_id%TYPE, --this has no default
      p_link_to_customer_trx_id       IN ra_customer_trx.customer_trx_id%TYPE DEFAULT NULL,
      p_receivables_trx_id            IN ar_receivable_applications.receivables_trx_id%TYPE,
      p_apply_date                    IN ar_receivable_applications.apply_date%TYPE DEFAULT NULL,
      p_apply_gl_date                 IN ar_receivable_applications.gl_date%TYPE DEFAULT NULL,
      p_ussgl_transaction_code        IN ar_receivable_applications.ussgl_transaction_code%TYPE DEFAULT NULL,
      p_attribute_rec                 IN attribute_rec_type DEFAULT attribute_rec_const,
	 -- ******* Global Flexfield parameters *******
      p_global_attribute_rec          IN global_attribute_rec_type DEFAULT global_attribute_rec_const,
      p_comments                      IN ar_receivable_applications.comments%TYPE DEFAULT NULL,
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
      p_customer_reference IN ar_receivable_applications.customer_reference%TYPE,
      p_val_writeoff_limits_flag     IN VARCHAR2,
      p_called_from 		     IN VARCHAR2,
      p_netted_receipt_flag          IN VARCHAR2,
      p_netted_cash_receipt_id       IN ar_cash_receipts.cash_receipt_id%TYPE,
      p_secondary_app_ref_type IN
                ar_receivable_applications.secondary_application_ref_type%TYPE := null,
      p_secondary_app_ref_num IN
                ar_receivable_applications.secondary_application_ref_num%TYPE := null,
      p_org_id             IN NUMBER  DEFAULT NULL,
      p_customer_reason    IN
                ar_receivable_applications.customer_reason%TYPE DEFAULT NULL
     ,p_pay_group_lookup_code	IN  FND_LOOKUPS.lookup_code%TYPE
     ,p_pay_alone_flag		IN  VARCHAR2
     ,p_payment_method_code	IN  ap_invoices.payment_method_code%TYPE
     ,p_payment_reason_code	IN  ap_invoices.payment_reason_code%TYPE
     ,p_payment_reason_comments	IN  ap_invoices.payment_reason_comments%TYPE
     ,p_delivery_channel_code	IN  ap_invoices.delivery_channel_code%TYPE
     ,p_remittance_message1	IN  ap_invoices.remittance_message1%TYPE
     ,p_remittance_message2	IN  ap_invoices.remittance_message2%TYPE
     ,p_remittance_message3	IN  ap_invoices.remittance_message3%TYPE
     ,p_party_id		IN  hz_parties.party_id%TYPE
     ,p_party_site_id	IN  hz_party_sites.party_site_id%TYPE
     ,p_bank_account_id		IN  ar_cash_receipts.customer_bank_account_id%TYPE
     ,p_payment_priority	IN  ap_invoices_interface.PAYMENT_PRIORITY%TYPE		--Bug8290172
     ,p_terms_id		IN  ap_invoices_interface.TERMS_ID%TYPE			--Bug8290172
	  ) IS

 l_api_name       CONSTANT VARCHAR2(20) := 'Activity_application';
 l_api_version    CONSTANT NUMBER       := 1.0;
 l_cash_receipt_id NUMBER(15);
 l_amount_applied  NUMBER;
 l_apply_date      DATE;
 l_apply_gl_date   DATE;
 l_cr_gl_date      DATE;
 l_default_return_status  VARCHAR2(1);
 l_validation_return_status  VARCHAR2(1);
 l_id_conv_return_status  VARCHAR2(1);
 l_cr_unapp_amount  NUMBER;
 ln_rec_application_id  NUMBER;
 l_cr_date   DATE;
 l_cr_payment_schedule_id NUMBER;
 l_cr_currency_code VARCHAR2(15);
 l_application_ref_type ar_receivable_applications.application_ref_type%TYPE;
 l_application_ref_id   ar_receivable_applications.application_ref_id%TYPE;
 l_application_ref_num  ar_receivable_applications.application_ref_num%TYPE;
 l_secondary_application_ref_id ar_receivable_applications.secondary_application_ref_id%TYPE;
 l_secondary_app_ref_type ar_receivable_applications.secondary_application_ref_type%TYPE;
 l_secondary_app_ref_num  ar_receivable_applications.secondary_application_ref_num%TYPE;
 l_payment_set_id ar_receivable_applications.payment_set_id%TYPE;
 l_acctd_amount_applied_from NUMBER;
 l_acctd_amount_applied_to   NUMBER;
 l_org_return_status VARCHAR2(1);
 l_org_id                           NUMBER;

 l_party_id hz_parties.party_id%TYPE;
 l_party_name hz_parties.party_name%TYPE;
 l_party_number hz_parties.party_number%TYPE;
 l_party_site_id hz_party_sites.party_site_id%TYPE;
 l_party_address VARCHAR2(360);
 l_payment_method_code iby_payment_methods_vl.payment_method_code%TYPE;
 l_payment_method_name iby_payment_methods_vl.payment_method_name%TYPE;
 l_bank_account_id iby_ext_bank_accounts.ext_bank_account_id%TYPE;
 l_bank_account_num iby_ext_bank_accounts.bank_account_num%TYPE;
 l_payment_reason_code iby_payment_reasons_vl.payment_reason_code%TYPE;
 l_payment_reason_name iby_payment_reasons_vl.meaning%TYPE;
 l_delivery_channel_code iby_delivery_channels_vl.delivery_channel_code%TYPE;
 l_delivery_channel_name iby_delivery_channels_vl.meaning%TYPE;
 l_pay_alone_flag VARCHAR2(1);
 l_legal_entity_id ar_cash_receipts.legal_entity_id%TYPE;
 l_exchange_rate ar_cash_receipts.exchange_rate%TYPE;
 l_exchange_rate_type ar_cash_receipts.exchange_rate_type%TYPE;
 l_exchange_date ar_cash_receipts.exchange_date%TYPE;
 l_invoice_id ap_invoices.invoice_id%TYPE;
 l_dft_ref_return_status  VARCHAR2(1);
 l_called_from  varchar2(20); /*5444407*/

  --Bug8290172 Changes Start Here
  l_term_id			ap_invoices_interface.TERMS_ID%TYPE;
  l_pay_term_return_status	VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
  l_pay_priority_return_status	VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
 --Bug8290172 Changes End Here
 l_ap_period_status VARCHAR2(1); /*Bug 19569317*/

  l_gl_exch_rate  		ar_cash_receipts.exchange_rate%TYPE;
  l_func_curr_code    varchar2(15);
 BEGIN
	l_called_from:=p_called_from; /*5444407*/

       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

      SAVEPOINT Activity_app_PVT;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*--------------------------------------------------------------+
        |   Initialize message list if p_init_msg_list is set to TRUE  |
        +--------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
          THEN
              FND_MSG_PUB.initialize;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Activity_application()+ ');
        END IF;
       /*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        x_return_status := FND_API.G_RET_STS_SUCCESS;




/* SSA change */
       l_org_id            := p_org_id;
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;

/*Bug 11705172 Changed to set org_context only when org_id is not same when called from writeoff*/
       IF l_called_from  = 'WRITEOFF' THEN
           IF nvl(mo_global.get_current_org_id,-99) <> l_org_id THEN
              ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);
           END IF;

       ELSE

           ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);

       END IF;
 IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
 ELSE
        /*-------------------------------------------------+
         | Initialize the profile option package variables |
         +-------------------------------------------------*/

           initialize_profile_globals;


       /*---------------------------------------------+
        |   ========== Start of API Body ==========   |
        +---------------------------------------------*/

     l_cash_receipt_id := p_cash_receipt_id;
     l_amount_applied  := p_amount_applied;
     l_apply_date      := trunc(p_apply_date);
     l_apply_gl_date   := trunc(p_apply_gl_date);
     l_application_ref_type         := p_application_ref_type;
     l_application_ref_id           := p_application_ref_id;
     l_application_ref_num          := p_application_ref_num;
     l_secondary_application_ref_id := p_secondary_application_ref_id;
     l_secondary_app_ref_type := p_secondary_app_ref_type;
     l_secondary_app_ref_num  := p_secondary_app_ref_num;
     l_payment_set_id               := p_payment_set_id;
     l_party_id		:= p_party_id;
     l_party_site_id	:= p_party_site_id;


          /*-----------------------+
           |                       |
           |ID TO VALUE CONVERSION |
           |                       |
           +-----------------------*/

     ar_receipt_lib_pvt.Default_cash_receipt_id(
                              l_cash_receipt_id ,
                              p_receipt_number ,
                              l_id_conv_return_status
                               );

     IF PG_DEBUG in ('Y', 'C') THEN
        arp_util.debug('Activity_application: ' || 'Default_cash_receipt_i return status :'||l_default_return_status);
     END IF;

          /*---------------------+
           |                     |
           |    DEFAULTING       |
           |                     |
           +---------------------*/

      ar_receipt_lib_pvt.Default_on_ac_app_info(
                                     l_cash_receipt_id,
                                     l_cr_gl_date,
                                     l_cr_unapp_amount,
                                     l_cr_date,
                                     l_cr_payment_schedule_id,
                                     l_amount_applied,
                                     l_apply_gl_date,
                                     l_apply_date,
                                     l_cr_currency_code,
                                     l_default_return_status
                                     );

      IF p_applied_payment_schedule_id = -8 THEN
		/* Start of code changes - Bug 19569317*/

		/*If the GL Period in AP is not open / future enterable , AR should not create Refund.
		These are the status of GL period's in AP
        	C (closed), N (never opened), O (open) and F (future enterable).*/
		BEGIN
		 IF PG_DEBUG in ('Y', 'C') THEN
		  arp_util.debug('Checking GL Period status in Payables...');
		 END IF;
		 SELECT nvl(ap_utilities_pkg.period_status(l_apply_gl_date),'C')
  		 INTO l_ap_period_status
		 FROM DUAL;

		IF l_ap_period_status NOT IN('O', 'F') THEN
			IF PG_DEBUG in ('Y', 'C') THEN
				arp_util.debug('GL Period status in Payables:'||l_ap_period_status);
			END IF;
 		FND_MESSAGE.SET_NAME('AR','AR_GL_DATE_PA_NOT_OPEN');
		FND_MSG_PUB.Add;
		RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
		END IF;

		EXCEPTION WHEN OTHERS THEN
		RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
		END;

		/* End of code changes - Bug 19569317*/

         /* Default the refund attributes from IBY */
         ar_receipt_lib_pvt.default_refund_attributes(
            	 p_cash_receipt_id	=>  l_cash_receipt_id
            	,p_customer_trx_id	=>  null
		,p_currency_code	=>  l_cr_currency_code
		,p_amount		=>  l_amount_applied
		,p_party_id		=>  l_party_id
		,p_party_site_id	=>  l_party_site_id
		,x_party_name		=>  l_party_name
		,x_party_number		=>  l_party_number
		,x_party_address	=>  l_party_address
		,x_exchange_rate	=>  l_exchange_rate
		,x_exchange_rate_type	=>  l_exchange_rate_type
		,x_exchange_date	=>  l_exchange_date
		,x_legal_entity_id	=>  l_legal_entity_id
		,x_payment_method_code	=>  l_payment_method_code
		,x_payment_method_name	=>  l_payment_method_name
		,x_bank_account_id	=>  l_bank_account_id
          	,x_bank_account_num	=>  l_bank_account_num
          	,x_payment_reason_code => l_payment_reason_code
          	,x_payment_reason_name => l_payment_reason_name
          	,x_delivery_channel_code => l_delivery_channel_code
          	,x_delivery_channel_name => l_delivery_channel_name
		,x_pay_alone_flag	=>  l_pay_alone_flag
		,x_return_status	=> l_dft_ref_return_status
		,x_msg_count		=> x_msg_count
		,x_msg_data		=> x_msg_data );

         /* If values have been passed in they should be used instead */
         IF p_payment_method_code IS NOT NULL THEN
            l_payment_method_code := p_payment_method_code;
		 ELSIF p_payment_method_code IS NULL AND l_payment_method_code IS NULL THEN/*Bug 6923248*/
            l_payment_method_code := 'CHECK';
	 END IF;
         IF p_bank_account_id IS NOT NULL THEN
            l_bank_account_id := p_bank_account_id;
	 END IF;
         IF p_payment_reason_code IS NOT NULL THEN
            l_payment_reason_code := p_payment_reason_code;
	 END IF;
         IF p_delivery_channel_code IS NOT NULL THEN
            l_delivery_channel_code := p_delivery_channel_code;
	 END IF;
         IF p_pay_alone_flag IS NOT NULL THEN
            l_pay_alone_flag := p_pay_alone_flag;
		ELSIF l_pay_alone_flag IS NULL AND p_pay_alone_flag IS NULL THEN /*Bug 6923248*/
            l_pay_alone_flag := 'N';
	 END IF;

      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('Activity_application: ' || 'Default_on_ac_app_info return status :'||l_default_return_status);
         arp_util.debug('Activity_application: ' || 'Default_refund_attributes return status :'||l_dft_ref_return_status);
      END IF;
          /*---------------------+
           |                     |
           |    VALIDATION       |
           |                     |
           +---------------------*/

      ar_receipt_val_pvt.validate_activity_app(
                                     p_receivables_trx_id,
                                     p_applied_payment_schedule_id,
                                     l_cash_receipt_id,
                                     l_cr_gl_date,
                                     l_cr_unapp_amount,
                                     l_cr_date,
                                     l_cr_payment_schedule_id,
                                     l_amount_applied,
                                     l_apply_gl_date,
                                     l_apply_date,
                                     p_link_to_customer_trx_id,
                                     l_cr_currency_code,
                                     l_validation_return_status,
                                     p_val_writeoff_limits_flag,
				     p_called_from
                                     );

		IF l_exchange_rate is not null and l_Cash_receipt_id is not null AND l_exchange_rate_type <> 'User' THEN
            l_func_curr_code  := arpcurr.getfunctcurr(arp_global.set_of_books_id);
         		l_gl_exch_rate := arpcurr.getrate( l_cr_currency_code, l_func_curr_code,
                                                     		          l_exchange_date,
                                                      		        l_exchange_rate_type);

		   	IF PG_DEBUG in ('Y', 'C') THEN
			    arp_util.debug('Exchange rate derived from Daily rates:  '||l_gl_exch_rate);
			  END IF;

				IF l_gl_exch_rate <> l_exchange_rate THEN
		  			l_exchange_rate := NULL;
						IF PG_DEBUG in ('Y', 'C') THEN
							arp_util.debug('Overriding exchange rate with NULL from AR to AP_INVOICES_INTERFACE_PKG');
						END IF;
				END IF;


		END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('Activity_application: ' || 'Validation return status :'||l_validation_return_status);
         arp_util.debug('Activity_application: ' || '*****DUMPING ALL THE ENTITY HANDLER PARAMETERS  ***');
         arp_util.debug('Activity_application: ' || 'l_cr_payment_schedule_id : '||to_char(l_cr_payment_schedule_id));
         arp_util.debug('Activity_application: ' || 'l_amount_applied         : '||to_char(l_amount_applied));
         arp_util.debug('Activity_application: ' || 'l_apply_date             : '||to_char(l_apply_date,'DD-MON-YY'));
         arp_util.debug('Activity_application: ' || 'l_apply_gl_date          : '||to_char(l_apply_gl_date,'DD-MON-YY'));
      END IF;
END IF;

      -- Bug8290172 Changes Start Here
      -- Validate Payment Term Id
      IF p_terms_id IS NOT NULL THEN
	      BEGIN
		SELECT term_id
		INTO l_term_id
		FROM ap_terms_bat_pay_terms_v
		WHERE term_id = p_terms_id;
	      EXCEPTION
	      WHEN OTHERS THEN
		     l_pay_term_return_status := FND_API.G_RET_STS_ERROR ;

                     FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                     FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','Invalid Payment Term');
                     FND_MSG_PUB.Add;

		     IF PG_DEBUG in ('Y', 'C') THEN
			arp_util.debug('Activity_application: ' || 'Invalid Payment Term. Rolling back and setting status to ERROR');
		     END IF;
	      END;
      END IF;

      -- Validate Payment Priority. It Should be between 1 to 99
      IF p_payment_priority IS NOT NULL THEN
      	IF p_payment_priority < 1 OR p_payment_priority > 99 THEN

	     l_pay_priority_return_status := FND_API.G_RET_STS_ERROR ;

	     FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
	     FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','Payment Priority Not In Range(1-99)');
	     FND_MSG_PUB.Add;

	     IF PG_DEBUG in ('Y', 'C') THEN
		arp_util.debug('Activity_application: ' || 'Payment Priority Not In Range(1-99). Rolling back and setting status to ERROR');
	     END IF;
	 END IF;
      END IF;
      -- Bug8290172 Changes End Here

      IF l_validation_return_status <> FND_API.G_RET_STS_SUCCESS  OR
         l_default_return_status <> FND_API.G_RET_STS_SUCCESS OR
         l_dft_ref_return_status <> FND_API.G_RET_STS_SUCCESS OR
         l_id_conv_return_status <> FND_API.G_RET_STS_SUCCESS OR
         l_pay_term_return_status <> FND_API.G_RET_STS_SUCCESS OR	-- Bug8290172
         l_pay_priority_return_status <> FND_API.G_RET_STS_SUCCESS THEN	-- Bug8290172

          IF PG_DEBUG in ('Y', 'C') THEN
             arp_util.debug('Activity_application: ' || 'Validation FAILED ');
          END IF;
          x_return_status :=  FND_API.G_RET_STS_ERROR;
      END IF;

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS
         THEN

            ROLLBACK TO Activity_app_PVT;

             x_return_status := FND_API.G_RET_STS_ERROR ;

             FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                        p_count => x_msg_count,
                                        p_data  => x_msg_data
                                       );

             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Activity_application: ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
             END IF;
             Return;
       END IF;


       --call the entity handler
       --BR
     BEGIN

         arp_process_application.activity_application (
                                  p_receipt_ps_id   => l_cr_payment_schedule_id,
                                  p_application_ps_id => p_applied_payment_schedule_id,
                                  p_link_to_customer_trx_id => p_link_to_customer_trx_id,
                                  p_amount_applied  => l_amount_applied,
                                  p_apply_date      => l_apply_date,
                                  p_gl_date         => l_apply_gl_date,
                                  p_receivables_trx_id => p_receivables_trx_id,
                                  p_ussgl_transaction_code => p_ussgl_transaction_code,
                                  p_attribute_category=> p_attribute_rec.attribute_category,
                                  p_attribute1        => p_attribute_rec.attribute1,
                                  p_attribute2        => p_attribute_rec.attribute2,
                                  p_attribute3        => p_attribute_rec.attribute3,
                                  p_attribute4        => p_attribute_rec.attribute4,
                                  p_attribute5        => p_attribute_rec.attribute5,
                                  p_attribute6        => p_attribute_rec.attribute6,
                                  p_attribute7        => p_attribute_rec.attribute7,
                                  p_attribute8        => p_attribute_rec.attribute8,
                                  p_attribute9        => p_attribute_rec.attribute9,
                                  p_attribute10       => p_attribute_rec.attribute10,
                                  p_attribute11       => p_attribute_rec.attribute11,
                                  p_attribute12       => p_attribute_rec.attribute12,
                                  p_attribute13       => p_attribute_rec.attribute13,
                                  p_attribute14       => p_attribute_rec.attribute14,
                                  p_attribute15       => p_attribute_rec.attribute15,
                                  p_global_attribute1 => p_global_attribute_rec.global_attribute1,
                                  p_global_attribute2 => p_global_attribute_rec.global_attribute2,
                                  p_global_attribute3 => p_global_attribute_rec.global_attribute3,
                                  p_global_attribute4 => p_global_attribute_rec.global_attribute4,
                                  p_global_attribute5 => p_global_attribute_rec.global_attribute5,
                                  p_global_attribute6 => p_global_attribute_rec.global_attribute6,
                                  p_global_attribute7 => p_global_attribute_rec.global_attribute7,
                                  p_global_attribute8 => p_global_attribute_rec.global_attribute8,
                                  p_global_attribute9 => p_global_attribute_rec.global_attribute9,
                                  p_global_attribute10 => p_global_attribute_rec.global_attribute10,
                                  p_global_attribute11 => p_global_attribute_rec.global_attribute11,
                                  p_global_attribute12 => p_global_attribute_rec.global_attribute12,
                                  p_global_attribute13 => p_global_attribute_rec.global_attribute13,
                                  p_global_attribute14 => p_global_attribute_rec.global_attribute14,
                                  p_global_attribute15 => p_global_attribute_rec.global_attribute15,
                                  p_global_attribute16 => p_global_attribute_rec.global_attribute16,
                                  p_global_attribute17 => p_global_attribute_rec.global_attribute17,
                                  p_global_attribute18 => p_global_attribute_rec.global_attribute18,
                                  p_global_attribute19 => p_global_attribute_rec.global_attribute19,
                                  p_global_attribute20 => p_global_attribute_rec.global_attribute20,
                                  p_global_attribute_category => p_global_attribute_rec.global_attribute_category,
                                  p_module_name         => 'RAPI',
                                  p_comments         => p_comments,
                                  p_application_ref_type => l_application_ref_type,
                                  p_application_ref_id   => l_application_ref_id,
                                  p_application_ref_num  => l_application_ref_num,
                                  p_secondary_application_ref_id   => l_secondary_application_ref_id,
                                  p_secondary_app_ref_type => l_secondary_app_ref_type,
                                  p_secondary_app_ref_num  => l_secondary_app_ref_num,
                                  p_payment_set_id   => l_payment_set_id,
                                  p_module_version      => p_api_version,
                                  -- *** OUT NOCOPY
				  p_called_from 	   => l_called_from, /*5444407*/
                                  p_out_rec_application_id => ln_rec_application_id,
                                  p_customer_reference => p_customer_reference,
				  p_netted_receipt_flag => p_netted_receipt_flag,
				  p_netted_cash_receipt_id => p_netted_cash_receipt_id,
                                  p_customer_reason => p_customer_reason -- 4145224
                                   );

     EXCEPTION
       WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN
                     ROLLBACK TO Activity_app_PVT;

                      --  Display_Parameters;
                      x_return_status := FND_API.G_RET_STS_ERROR ;
                       FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                       FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','ARP_PROCESS_APPLICATION.ACTIVITY_APPLICATION : '||SQLERRM);
                       FND_MSG_PUB.Add;

                       FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                                                  p_count  =>  x_msg_count,
                                                  p_data   => x_msg_data
                                                );
                      RETURN;
                ELSE
                   RAISE;
                END IF;

     END;

     /* Call AP API's to create payment request if refund */
     IF p_applied_payment_schedule_id = -8 THEN
	BEGIN
	  ar_refunds_pvt.create_refund
		(p_receivable_application_id	=>  ln_rec_application_id
		,p_amount			=>  l_amount_applied
		,p_currency_code		=>  l_cr_currency_code
		,p_exchange_rate		=>  l_exchange_rate
		,p_exchange_rate_type		=>  l_exchange_rate_type
		,p_exchange_date		=>  l_exchange_date
		,p_description			=>  NULL
          	,p_pay_group_lookup_code	=>  p_pay_group_lookup_code
          	,p_pay_alone_flag		=>  l_pay_alone_flag
		,p_org_id			=>  l_org_id
	  	,p_legal_entity_id        	=>  l_legal_entity_id
          	,p_payment_method_code		=>  l_payment_method_code
          	,p_payment_reason_code		=>  l_payment_reason_code
          	,p_payment_reason_comments	=>  p_payment_reason_comments
          	,p_delivery_channel_code	=>  l_delivery_channel_code
          	,p_remittance_message1		=>  p_remittance_message1
          	,p_remittance_message2		=>  p_remittance_message2
          	,p_remittance_message3		=>  p_remittance_message3
          	,p_party_id			=>  l_party_id
          	,p_party_site_id		=>  l_party_site_id
                ,p_bank_account_id		=>  l_bank_account_id
		,p_called_from			=>  'RECEIPT_API'
		,x_invoice_id			=> l_invoice_id
		,x_return_status		=> x_return_status
		,x_msg_count			=> x_msg_count
		,x_msg_data			=> x_msg_data
		,p_payment_priority		=> NVL(p_payment_priority,99)	--Bug8290172  Default 99 of no Payment Proirity is passed
		,p_terms_id			=> p_terms_id		 	--Bug8290172
		,p_invoice_date                 => l_apply_date                  -- Bug 9909157
		,p_gl_date         => l_apply_gl_date);

          l_application_ref_id := l_invoice_id;
          l_application_ref_num := l_invoice_id;

        EXCEPTION
       WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN
                     ROLLBACK TO Activity_app_PVT;

                      --  Display_Parameters;
                      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                       FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                       FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','AR_REFUNDS_PVT.Create_Refund : '||SQLERRM);
                       FND_MSG_PUB.Add;

                       FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                                                  p_count  =>  x_msg_count,
                                                  p_data   => x_msg_data
                                                );
                      RETURN;
                ELSE
                   RAISE;
                END IF;
        END;
     END IF;
        p_receivable_application_id   := ln_rec_application_id;
        p_application_ref_type := l_application_ref_type;
        p_application_ref_id   := l_application_ref_id;
        p_application_ref_num  := l_application_ref_num;
        p_secondary_application_ref_id   := l_secondary_application_ref_id;
       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Activity_application: ' || 'committing');
            END IF;
              Commit;
        END IF;
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Activity_application ()- ');
        END IF;
EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Activity_application: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Activity_application: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Activity_app_PVT;
                x_return_status := FND_API.G_RET_STS_ERROR ;

               -- Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Activity_application: ' || SQLERRM, G_MSG_ERROR);
                END IF;
                ROLLBACK TO Activity_app_PVT;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

               --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN

                      ROLLBACK TO Activity_app_PVT;

                      --If only one error message on the stack,
                      --retrive it

                      x_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','ACTIVITY_APPLICATION : '||SQLERRM);
                      FND_MSG_PUB.Add;

                      --If only one error message on the stack,
                      --retrive it

                      FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                                 p_count  =>  x_msg_count,
                                                 p_data   => x_msg_data
                                                );

                      RETURN;

                ELSE
                     x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                     FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                     FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','ACTIVITY_APPLICATION : '||SQLERRM);
                     FND_MSG_PUB.Add;
                END IF;

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Activity_application: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Activity_application: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Activity_app_PVT;

                IF      FND_MSG_PUB.Check_Msg_Level
                THEN
                FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME,
                                        l_api_name
                                       );
                END IF;

             --   Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );
END Activity_application;

PROCEDURE Activity_Unapplication(
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
      ) IS
l_api_name       CONSTANT VARCHAR2(20) := 'Activity_unapp';
l_api_version    CONSTANT NUMBER       := 1.0;
l_customer_trx_id               NUMBER;
l_cash_receipt_id               NUMBER;
l_receivable_application_id     NUMBER;
l_reversal_gl_date              DATE;
l_apply_gl_date                 DATE;
l_receipt_gl_date               DATE;
l_def_return_status             VARCHAR2(1);
l_val_return_status             VARCHAR2(1);
l_bal_due_remaining             NUMBER;
l_org_return_status VARCHAR2(1);
l_org_id                           NUMBER;
l_cr_unapp_amt                  NUMBER; /* Bug fix 3569640 */
l_application_ref_id		ar_receivable_applications.application_ref_id%TYPE;
l_applied_ps_id			ar_payment_schedules.payment_schedule_id%TYPE;
l_refund_return_status		VARCHAR2(1);
BEGIN
       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

        SAVEPOINT Activity_unapplication_PVT;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*--------------------------------------------------------------+
        |   Initialize message list if p_init_msg_list is set to TRUE  |
        +--------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
          THEN
              FND_MSG_PUB.initialize;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('ar_receipt_api.activity_unapplication()+ ');
        END IF;
       /*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        x_return_status := FND_API.G_RET_STS_SUCCESS;



/* SSA change */
       l_org_id            := p_org_id;
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;
       ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);
 IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
 ELSE

        /*-------------------------------------------------+
         | Initialize the profile option package variables |
         +-------------------------------------------------*/

           initialize_profile_globals;



        Original_activity_unapp_info.cash_receipt_id := p_cash_receipt_id;
        Original_activity_unapp_info.receipt_number  := p_receipt_number;
        Original_activity_unapp_info.receivable_application_id := p_receivable_application_id;

       /*---------------------------------------------+
        |   ========== Start of API Body ==========   |
        +---------------------------------------------*/


        --Assign IN parameter values to local variables
        --which are also used as assignment targets.

         l_cash_receipt_id   := p_cash_receipt_id;
         l_receivable_application_id  := p_receivable_application_id;
         l_reversal_gl_date := trunc(p_reversal_gl_date);


        /*------------------------------------------------+
         |  Derive the id's for the entered values.       |
         |  If both the values and the ids are specified, |
         |  the id's superceed the values                 |
         +------------------------------------------------*/

         ar_receipt_lib_pvt.derive_activity_unapp_ids(
                         p_receipt_number   ,
                         l_cash_receipt_id  ,
                         l_receivable_application_id ,
                         p_called_from,
                         l_apply_gl_date     ,
                         l_cr_unapp_amt, /* Bug fix 3569640 */
                         l_def_return_status
                               );
         ar_receipt_lib_pvt.default_unapp_on_ac_act_info(
                         l_receivable_application_id ,
                         l_apply_gl_date            ,
                         l_cash_receipt_id          ,
                         l_reversal_gl_date         ,
                         l_receipt_gl_date
                          );

         ar_receipt_val_pvt.validate_unapp_on_ac_act_info(
                                      l_receipt_gl_date,
                                      l_receivable_application_id,
                                      l_reversal_gl_date,
                                      l_apply_gl_date,
                                      l_cr_unapp_amt, /* Bug fix 3569640 */
                                      l_val_return_status);

         IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug('Activity_Unapplication: ' || 'validation return status :'||l_val_return_status);
         END IF;
END IF;

	/* Refunds - check for refund and cancel if refund application */
        SELECT applied_payment_schedule_id, application_ref_id
	INTO   l_applied_ps_id, l_application_ref_id
	FROM   ar_receivable_applications
  	WHERE  receivable_application_id = l_receivable_application_id;

        IF (l_applied_ps_id = -8 AND p_called_from <> 'AR_REFUNDS_GRP') THEN
           ar_refunds_pvt.cancel_refund(
		  p_application_ref_id  => l_application_ref_id
		, p_gl_date		=> l_reversal_gl_date
		, x_return_status	=> l_refund_return_status
		, x_msg_count		=> x_msg_count
		, x_msg_data		=> x_msg_data);
        END IF;


        IF l_val_return_status <> FND_API.G_RET_STS_SUCCESS OR
	   l_refund_return_status <> FND_API.G_RET_STS_SUCCESS OR
           l_def_return_status <> FND_API.G_RET_STS_SUCCESS  THEN
           x_return_status := FND_API.G_RET_STS_ERROR;
        END IF;

        IF x_return_status <> FND_API.G_RET_STS_SUCCESS
         THEN

            ROLLBACK TO Activity_unapplication_PVT;

             x_return_status := FND_API.G_RET_STS_ERROR ;

             FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                        p_count => x_msg_count,
                                        p_data  => x_msg_data
                                       );

             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Activity_Unapplication: ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
             END IF;
             Return;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Activity_Unapplication: ' || '*******DUMP THE INPUT PARAMETERS ********');
           arp_util.debug('Activity_Unapplication: ' || 'l_receivable_application_id :'||to_char(l_receivable_application_id));
           arp_util.debug('Activity_Unapplication: ' || 'l_reversal_gl_date :'||to_char(l_reversal_gl_date,'DD-MON-YY'));
        END IF;

       --lock the receipt before calling the entity handler
       arp_cash_receipts_pkg.nowaitlock_p(p_cr_id => l_cash_receipt_id);


        --call the entity handler.
      BEGIN
          arp_process_application.reverse(
                                l_receivable_application_id,
                                l_reversal_gl_date,
                                trunc(sysdate),
                                NVL(p_called_from,'RAPI'), -- Bug 2855180
                                p_api_version,
                                l_bal_due_remaining );
      EXCEPTION
        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN
                     ROLLBACK TO Activity_unapplication_PVT;

                      --  Display_Parameters;
                      x_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','ARP_PROCESS_APPLICATION.REVERSE : '||SQLERRM);
                      FND_MSG_PUB.Add;

                       FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                                                  p_count  =>  x_msg_count,
                                                  p_data   => x_msg_data
                                                );
                      RETURN;
                ELSE
                   RAISE;
                END IF;
      END;

       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Activity_Unapplication: ' || 'committing');
            END IF;
              Commit;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('ar_receipt_api.Activity_unapplication()- ');
        END IF;


EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Activity_Unapplication: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Activity_Unapplication: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Activity_unapplication_PVT;
                x_return_status := FND_API.G_RET_STS_ERROR ;

              --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Activity_Unapplication: ' || SQLERRM, G_MSG_ERROR);
                END IF;
                ROLLBACK TO Activity_unapplication_PVT;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

               --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN

                      ROLLBACK TO Activity_unapplication_PVT;

                      x_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','ACTIVITY_UNAPPLICATION : '||SQLERRM);
                      FND_MSG_PUB.Add;

                      --If only one error message on the stack,
                      --retrive it
                      FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                                 p_count  =>  x_msg_count,
                                                 p_data   => x_msg_data
                                                );

                      RETURN;

                ELSE
                      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','ACTIVITY_UNAPPLICATION : '||SQLERRM);
                      FND_MSG_PUB.Add;
                END IF;

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Activity_Unapplication: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Activity_Unapplication: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Activity_unapplication_PVT;

                IF      FND_MSG_PUB.Check_Msg_Level
                THEN
                FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME,
                                        l_api_name
                                       );
                END IF;

             --   Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );
END Activity_unapplication;

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
      p_called_from             IN VARCHAR2,
      p_org_id             IN NUMBER  DEFAULT NULL
	  ) IS
 l_api_name       CONSTANT VARCHAR2(20) := 'Apply_Other_account';
 l_api_version    CONSTANT NUMBER       := 1.0;
 l_cash_receipt_id NUMBER(15);
 l_amount_applied  NUMBER;
 l_apply_date      DATE;
 l_apply_gl_date   DATE;
 l_cr_gl_date      DATE;
 l_default_return_status  VARCHAR2(1);
 l_validation_return_status  VARCHAR2(1);
 l_app_validation_return_status  VARCHAR2(1);
 l_id_conv_return_status  VARCHAR2(1);
 l_cr_unapp_amount  NUMBER;
 ln_rec_application_id  NUMBER;
 l_cr_date   DATE;
 l_cr_payment_schedule_id NUMBER;
 l_dflex_val_return_status  VARCHAR2(1);
 l_attribute_rec           attribute_rec_type;
 l_cr_currency_code     VARCHAR2(15);
 l_receivables_trx_id           NUMBER;
 l_applied_payment_schedule_id       ar_receivable_applications.applied_payment_schedule_id%TYPE;
 l_gdflex_return_status             VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS;
 l_global_attribute_rec             global_attribute_rec_type;

 -- Bug # 2707702
 l_temp_ref_id  ar_receivable_applications.application_ref_id%TYPE;
 l_temp_ref_num ar_receivable_applications.application_ref_num%TYPE;
 l_claim_reason_name                VARCHAR2(100);
 l_org_return_status VARCHAR2(1);
 l_org_id                           NUMBER;

BEGIN

       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

      SAVEPOINT Apply_other_ac_PVT;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*--------------------------------------------------------------+
        |   Initialize message list if p_init_msg_list is set to TRUE  |
        +--------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
          THEN
              FND_MSG_PUB.initialize;
        END IF;

        arp_util.debug('Apply_other_account()+ ');
       /*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        x_return_status := FND_API.G_RET_STS_SUCCESS;




/* SSA change */
       l_org_id            := p_org_id;
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;
       ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);
 IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
 ELSE
        /*-------------------------------------------------+
         | Initialize the profile option package variables |
         +-------------------------------------------------*/

           initialize_profile_globals;


       /*---------------------------------------------+
        |   ========== Start of API Body ==========   |
        +---------------------------------------------*/

     l_cash_receipt_id := p_cash_receipt_id;
     l_amount_applied  := p_amount_applied;
     l_apply_date      := trunc(p_apply_date);
     l_apply_gl_date   := trunc(p_apply_gl_date);
     l_attribute_rec   := p_attribute_rec;
     l_receivables_trx_id := p_receivables_trx_id;
     l_applied_payment_schedule_id := p_applied_payment_schedule_id;
     l_global_attribute_rec        := p_global_attribute_rec;
          /*-----------------------+
           |                       |
           |ID TO VALUE CONVERSION |
           |                       |
           +-----------------------*/

      ar_receipt_lib_pvt.Default_cash_receipt_id(
                              l_cash_receipt_id ,
                              p_receipt_number ,
                              l_id_conv_return_status
                               );

      arp_util.debug('Defaulting Ids Return_status = '||l_id_conv_return_status);
          /*---------------------+
           |                     |
           |    DEFAULTING       |
           |                     |
           +---------------------*/

      ar_receipt_lib_pvt.Default_on_ac_app_info(
                                  l_cash_receipt_id,
                                  l_cr_gl_date,
                                  l_cr_unapp_amount,
                                  l_cr_date,
                                  l_cr_payment_schedule_id,
                                  l_amount_applied,
                                  l_apply_gl_date,
                                  l_apply_date,
                                  l_cr_currency_code,
                                  l_default_return_status
                                  );

      arp_util.debug('Default_on_ac_app_info return status = '||l_default_return_status);
          /*---------------------+
           |                     |
           |    VALIDATION       |
           |                     |
           +---------------------*/

       --This routine will validate both validate_on_ac_app and activity
       ar_receipt_val_pvt.validate_activity_app(
                              l_receivables_trx_id ,
                              l_applied_payment_schedule_id,
                              l_cash_receipt_id,
                              l_cr_gl_date,
                              l_cr_unapp_amount,
                              l_cr_date ,
                              l_cr_payment_schedule_id,
                              l_amount_applied,
                              l_apply_gl_date,
                              l_apply_date ,
                              NULL, --p_link_to_customer_trx_id not required
                              l_cr_currency_code,
                              l_validation_return_status,
			      p_called_from);


        arp_util.debug('Validation return status :'||l_validation_return_status);

        --Validate application reference details passed.
        ar_receipt_val_pvt.validate_application_ref(
                              l_applied_payment_schedule_id,
                              p_application_ref_type,
                              p_application_ref_id,
                              p_application_ref_num,
                              p_secondary_application_ref_id,
                              l_cash_receipt_id,
                              l_amount_applied,
                              NULL,
                              l_cr_currency_code,
                              NULL,
                              p_application_ref_reason,
                              l_app_validation_return_status
                               );

        arp_util.debug('Application ref Validation return status :'||l_app_validation_return_status);


         --validate and default the flexfields
        ar_receipt_lib_pvt.Validate_Desc_Flexfield(
                                        l_attribute_rec,
                                        'AR_RECEIVABLE_APPLICATIONS',
                                        l_dflex_val_return_status
                                                );
        arp_util.debug('Desc flexfield Validation return status :'||l_dflex_val_return_status);

      --default and validate the global descriptive flexfield
        jg_ar_receivable_applications.apply(
                  p_apply_before_after        => 'BEFORE',
                  p_global_attribute_category => l_global_attribute_rec.global_attribute_category,
                  p_set_of_books_id           => arp_global.set_of_books_id,
                  p_cash_receipt_id           => l_cash_receipt_id,
                  p_receipt_date              => l_cr_date,
                  p_applied_payment_schedule_id => l_applied_payment_schedule_id,
                  p_amount_applied              => l_amount_applied,
                  p_unapplied_amount            => (l_cr_unapp_amount - l_amount_applied),
                  p_due_date                    => NULL,
                  p_receipt_method_id           => NULL,
                  p_remittance_bank_account_id  => NULL,
                  p_global_attribute1           => l_global_attribute_rec.global_attribute1,
                  p_global_attribute2           => l_global_attribute_rec.global_attribute2,
                  p_global_attribute3           => l_global_attribute_rec.global_attribute3,
                  p_global_attribute4           => l_global_attribute_rec.global_attribute4,
                  p_global_attribute5           => l_global_attribute_rec.global_attribute5,
                  p_global_attribute6           => l_global_attribute_rec.global_attribute6,
                  p_global_attribute7           => l_global_attribute_rec.global_attribute7,
                  p_global_attribute8           => l_global_attribute_rec.global_attribute8,
                  p_global_attribute9           => l_global_attribute_rec.global_attribute9,
                  p_global_attribute10          => l_global_attribute_rec.global_attribute10,
                  p_global_attribute11          => l_global_attribute_rec.global_attribute11,
                  p_global_attribute12          => l_global_attribute_rec.global_attribute12,
                  p_global_attribute13          => l_global_attribute_rec.global_attribute13,
                  p_global_attribute14          => l_global_attribute_rec.global_attribute14,
                  p_global_attribute15          => l_global_attribute_rec.global_attribute15,
                  p_global_attribute16          => l_global_attribute_rec.global_attribute16,
                  p_global_attribute17          => l_global_attribute_rec.global_attribute17,
                  p_global_attribute18          => l_global_attribute_rec.global_attribute18,
                  p_global_attribute19          => l_global_attribute_rec.global_attribute19,
                  p_global_attribute20          => l_global_attribute_rec.global_attribute20,
                  p_return_status               => l_gdflex_return_status);

      arp_util.debug('*****DUMPING ALL THE ENTITY HANDLER PARAMETERS  ***');
      arp_util.debug('l_cr_payment_schedule_id : '||to_char(l_cr_payment_schedule_id));
      arp_util.debug('l_amount_applied : '||to_char(l_amount_applied));
      arp_util.debug('l_apply_date : '||to_char(l_apply_date,'DD-MON-YY'));
      arp_util.debug('l_apply_gl_date : '||to_char(l_apply_gl_date,'DD-MON-YY'));
END IF;


      IF l_validation_return_status <> FND_API.G_RET_STS_SUCCESS  OR
         l_app_validation_return_status <> FND_API.G_RET_STS_SUCCESS  OR
         l_default_return_status <> FND_API.G_RET_STS_SUCCESS OR
         l_id_conv_return_status <> FND_API.G_RET_STS_SUCCESS OR
         l_dflex_val_return_status <> FND_API.G_RET_STS_SUCCESS OR
         l_gdflex_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          x_return_status :=  FND_API.G_RET_STS_ERROR;
      END IF;

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS
         THEN

            ROLLBACK TO Apply_other_ac_PVT;

             x_return_status := FND_API.G_RET_STS_ERROR ;

             FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                        p_count => x_msg_count,
                                        p_data  => x_msg_data
                                       );

             arp_util.debug('Error(s) occurred. Rolling back and setting status to ERROR');
             Return;
       END IF;

       --lock the receipt before calling the entity handler
       arp_cash_receipts_pkg.nowaitlock_p(p_cr_id => l_cash_receipt_id);

       --call the entity handler
    BEGIN
       arp_process_application.other_account_application (
                                  p_receipt_ps_id   => l_cr_payment_schedule_id,
                                  p_amount_applied  => l_amount_applied,
                                  p_apply_date      => l_apply_date,
                                  p_gl_date         => l_apply_gl_date,
                                  p_receivables_trx_id =>l_receivables_trx_id,
                                  p_applied_ps_id      => p_applied_payment_schedule_id,
                                  p_ussgl_transaction_code => p_ussgl_transaction_code,
                                  p_application_ref_type => p_application_ref_type,
                                  p_application_ref_id   => p_application_ref_id,
                                  p_application_ref_num  => p_application_ref_num,
                                  p_secondary_application_ref_id => p_secondary_application_ref_id,
                                  p_comments             => p_comments,
                                  p_attribute_category=> l_attribute_rec.attribute_category,
                                  p_attribute1        => l_attribute_rec.attribute1,
                                  p_attribute2        => l_attribute_rec.attribute2,
                                  p_attribute3        => l_attribute_rec.attribute3,
                                  p_attribute4        => l_attribute_rec.attribute4,
                                  p_attribute5        => l_attribute_rec.attribute5,
                                  p_attribute6        => l_attribute_rec.attribute6,
                                  p_attribute7        => l_attribute_rec.attribute7,
                                  p_attribute8        => l_attribute_rec.attribute8,
                                  p_attribute9        => l_attribute_rec.attribute9,
                                  p_attribute10       => l_attribute_rec.attribute10,
                                  p_attribute11       => l_attribute_rec.attribute11,
                                  p_attribute12       => l_attribute_rec.attribute12,
                                  p_attribute13       => l_attribute_rec.attribute13,
                                  p_attribute14       => l_attribute_rec.attribute14,
                                  p_attribute15       => l_attribute_rec.attribute15,
                                  p_global_attribute_category => p_global_attribute_rec.global_attribute_category,
                                  p_global_attribute1 => p_global_attribute_rec.global_attribute1,
                                  p_global_attribute2 => p_global_attribute_rec.global_attribute2,
                                  p_global_attribute3 => p_global_attribute_rec.global_attribute3,
                                  p_global_attribute4 => p_global_attribute_rec.global_attribute4,
                                  p_global_attribute5 => p_global_attribute_rec.global_attribute5,
                                  p_global_attribute6 => p_global_attribute_rec.global_attribute6,
                                  p_global_attribute7 => p_global_attribute_rec.global_attribute7,
                                  p_global_attribute8 => p_global_attribute_rec.global_attribute8,
                                  p_global_attribute9 => p_global_attribute_rec.global_attribute9,
                                  p_global_attribute10 => p_global_attribute_rec.global_attribute10,
                                  p_global_attribute11 => p_global_attribute_rec.global_attribute11,
                                  p_global_attribute12 => p_global_attribute_rec.global_attribute12,
                                  p_global_attribute13 => p_global_attribute_rec.global_attribute13,
                                  p_global_attribute14 => p_global_attribute_rec.global_attribute14,
                                  p_global_attribute15 => p_global_attribute_rec.global_attribute15,
                                  p_global_attribute16 => p_global_attribute_rec.global_attribute16,
                                  p_global_attribute17 => p_global_attribute_rec.global_attribute17,
                                  p_global_attribute18 => p_global_attribute_rec.global_attribute18,
                                  p_global_attribute19 => p_global_attribute_rec.global_attribute19,
                                  p_global_attribute20 => p_global_attribute_rec.global_attribute20,
                                  p_module_name         => 'RAPI',
                                  p_module_version      => p_api_version,
                                  p_payment_set_id      => p_payment_set_id,
                                  -- *** OUT NOCOPY
                                  x_application_ref_id     => l_temp_ref_id,
                                  x_application_ref_num    => l_temp_ref_num,
                                  x_return_status          => x_return_status,
                                  x_msg_count              => x_msg_count,
                                  x_msg_data               => x_msg_data,
                                  p_out_rec_application_id => ln_rec_application_id,
                                  p_application_ref_reason => p_application_ref_reason,
                                  p_customer_reference     => p_customer_reference,
                                  p_customer_reason        => p_customer_reason,
                                  x_claim_reason_name      => l_claim_reason_name,
				  p_called_from		   => p_called_from
                                   );

     -- The following two lines and some related changes above are done
     -- to resolve bug # 2707702.
     --
     -- ORASHID 13-DEC-2002

     p_application_ref_id  := l_temp_ref_id;
     p_application_ref_num := l_temp_ref_num;

     arp_util.debug('Application ID  :'||to_char(ln_rec_application_id));
     p_receivable_application_id := ln_rec_application_id;
     arp_util.debug('Other Accounting Application return status :'||x_return_status);
     EXCEPTION
       WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN
                     ROLLBACK TO Apply_other_ac_PVT;

                      --  Display_Parameters

                      x_return_status := FND_API.G_RET_STS_ERROR ;
                       FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                       FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','ARP_PROCESS_APPLICATION.APPLY_OTHER_ACCOUNT : '||SQLERRM);
                       FND_MSG_PUB.Add;

                       FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                                                  p_count  =>  x_msg_count,
                                                  p_data   => x_msg_data
                                                );
                      RETURN;
                ELSE
                   RAISE;
                END IF;
     END;
       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit )
        THEN
            arp_util.debug('committing');
              Commit;
        END IF;
        arp_util.debug('Apply_other_account ()- ');
EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                arp_util.debug(SQLCODE, G_MSG_ERROR);
                arp_util.debug(SQLERRM, G_MSG_ERROR);

                ROLLBACK TO Apply_other_ac_PVT;
                x_return_status := FND_API.G_RET_STS_ERROR ;

               -- Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                arp_util.debug(SQLERRM, G_MSG_ERROR);
                ROLLBACK TO Apply_other_ac_PVT;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

               --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN

                      ROLLBACK TO Apply_other_ac_PVT;

                      --If only one error message on the stack,
                      --retrive it

                      x_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','APPLY_OTHER_ACCOUNT : '||SQLERRM);
                      FND_MSG_PUB.Add;

                      --If only one error message on the stack,
                      --retrive it
                      FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                                 p_count  =>  x_msg_count,
                                                 p_data   => x_msg_data
                                                );

                      RETURN;

                ELSE
                      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','APPLY_OTHER_ACCOUNT : '||SQLERRM);
                      FND_MSG_PUB.Add;
                END IF;

                arp_util.debug(SQLCODE, G_MSG_ERROR);
                arp_util.debug(SQLERRM, G_MSG_ERROR);

                ROLLBACK TO Apply_other_ac_PVT;

                IF      FND_MSG_PUB.Check_Msg_Level
                THEN
                FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME,
                                        l_api_name
                                       );
                END IF;

             --   Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );
        END;
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
      p_receipt_number               IN  OUT NOCOPY VARCHAR2 ,
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
      p_attribute_record             IN  attribute_rec_type        DEFAULT attribute_rec_const,
      p_global_attribute_record      IN  global_attribute_rec_type DEFAULT global_attribute_rec_const,
      p_comments                     IN  VARCHAR2 DEFAULT NULL,
      p_org_id                       IN NUMBER  DEFAULT NULL,
      p_misc_receipt_id              OUT NOCOPY NUMBER,
      p_called_from                  IN VARCHAR2 DEFAULT NULL,
      p_payment_trxn_extension_id    IN ar_cash_receipts.payment_trxn_extension_id%TYPE DEFAULT NULL)  /* Bug fix 3619780*/
IS
l_misc_dist_tbl                     AR_RECEIPT_API_PUB.misc_dist_tbl_type;
BEGIN
    create_misc (p_api_version,
                 p_init_msg_list,
		 p_commit,
		 p_validation_level,
		 x_return_status,
		 x_msg_count,
		 x_msg_data,
		 p_usr_currency_code,
		 p_currency_code,
		 p_usr_exchange_rate_type,
		 p_exchange_rate_type,
		 p_exchange_rate,
		 p_exchange_rate_date,
		 p_amount,
		 p_receipt_number,
		 p_receipt_date,
		 p_gl_date,
		 p_receivables_trx_id,
		 p_activity,
		 p_misc_payment_source,
		 p_tax_code,
		 p_vat_tax_id,
		 p_tax_rate,
		 p_tax_amount,
		 p_deposit_date,
		 p_reference_type,
		 p_reference_num,
		 p_reference_id,
		 p_remittance_bank_account_id,
		 p_remittance_bank_account_num,
		 p_remittance_bank_account_name,
		 p_receipt_method_id,
		 p_receipt_method_name,
		 p_doc_sequence_value,
		 p_ussgl_transaction_code,
		 p_anticipated_clearing_date,
		 p_attribute_record,
		 p_global_attribute_record,
		 p_comments,
		 p_org_id,
		 p_misc_receipt_id,
		 p_called_from,
		 p_payment_trxn_extension_id,
		 l_misc_dist_tbl);
END create_misc; /*ER 7417553*/


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
      p_receipt_number               IN  OUT NOCOPY VARCHAR2 ,
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
      p_attribute_record             IN  attribute_rec_type        DEFAULT attribute_rec_const,
      p_global_attribute_record      IN  global_attribute_rec_type DEFAULT global_attribute_rec_const,
      p_comments                     IN  VARCHAR2 DEFAULT NULL,
      p_org_id                       IN NUMBER  DEFAULT NULL,
      p_misc_receipt_id              OUT NOCOPY NUMBER,
      p_called_from                  IN VARCHAR2 DEFAULT NULL,
      p_payment_trxn_extension_id    IN ar_cash_receipts.payment_trxn_extension_id%TYPE DEFAULT NULL, /* Bug fix 3619780*/
       p_misc_dist_tbl                IN  AR_RECEIPT_API_PUB.misc_dist_tbl_type) /*ER 7417553*/
IS
l_currency_code                ar_cash_receipts.currency_code%TYPE;
l_exchange_rate_type           ar_cash_receipts.exchange_rate_type%TYPE;
l_exchange_rate                NUMBER;
l_exchange_date                DATE;
l_receipt_number               ar_cash_receipts.receipt_number%TYPE;
l_amount                       NUMBER;
l_receipt_date                 DATE;
l_gl_date                      DATE;
l_receivables_trx_id           NUMBER(15);
l_vat_tax_id                   NUMBER(15);
l_tax_rate                     NUMBER;
l_deposit_date                 DATE;
l_reference_id                 NUMBER;
l_remit_bank_acct_use_id       NUMBER(15);
l_receipt_method_id            NUMBER(15);
l_doc_sequence_value           NUMBER(15);
l_doc_sequence_id              NUMBER(15);
l_distribution_set_id          NUMBER(15);
l_anticipated_clearing_date    DATE;
l_row_id                       VARCHAR2(30);
l_attribute_rec                attribute_rec_type;
l_global_attribute_rec         global_attribute_rec_type;

l_api_name                     CONSTANT VARCHAR2(20) := 'Create_misc';
l_api_version                  CONSTANT NUMBER       := 1.0;

l_receipt_method_name          VARCHAR2(30);
l_state                        VARCHAR2(30);
l_creation_method              VARCHAR2(1);
l_doc_seq_status               VARCHAR2(1);
l_def_misc_id_return_status    VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS;
l_misc_def_return_status       VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS;
l_val_return_status            VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS;
l_dflex_val_return_status      VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS;
l_creation_method_code         ar_receipt_classes.creation_method_code%TYPE;
/* Bug fix 2300268 */
l_tax_account_id               ar_distributions.code_combination_id%TYPE;
/* Bug fix 2742388 */
l_crh_id                       ar_cash_receipt_history.cash_receipt_history_id%TYPE;
l_org_return_status VARCHAR2(1);
l_org_id                           NUMBER;
l_legal_entity_id              NUMBER;  /* R12 LE uptake */
l_payment_trxn_extension_id    ar_cash_receipts.payment_trxn_extension_id%TYPE;
/* bichatte payment uptake */
l_copy_return_status                VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
l_copy_msg_count                    NUMBER;
l_copy_msg_data                     VARCHAR2(2000);
l_copy_pmt_trxn_extension_id        ar_cash_receipts.payment_trxn_extension_id%TYPE; /* bichatte payment uptake project */
l_default_site_use                  VARCHAR2(1);
l_customer_id                       NUMBER(15);
l_customer_site_use_id              NUMBER(15);
l_misc_dist_tbl                     AR_RECEIPT_API_PUB.misc_dist_tbl_type;  /*ER 7417553*/
l_attribute_rec_tbl                  AR_RECEIPT_API_PUB.attribute_rec_tbl_type;/*ER 24375569*/
l_misc_dflex_val_return_status      VARCHAR2(1) DEFAULT FND_API.G_RET_STS_SUCCESS;/*ER 24375569*/
BEGIN

 --assigning the parameters to local variables
	l_currency_code                := p_currency_code;
	l_exchange_rate_type           := p_exchange_rate_type;
        l_exchange_rate                := p_exchange_rate;
        l_exchange_date                := trunc(p_exchange_rate_date);
	l_receipt_number               := p_receipt_number;
        l_amount                       := p_amount;
	l_receipt_date                 := trunc(p_receipt_date);
	l_gl_date                      := trunc(p_gl_date);
	l_receivables_trx_id           := p_receivables_trx_id;
	l_vat_tax_id                   := p_vat_tax_id;
        l_tax_rate                     := p_tax_rate;
	l_deposit_date                 := trunc(p_deposit_date);
	l_reference_id                 := p_reference_id;
	l_remit_bank_acct_use_id       := p_remittance_bank_account_id;
	l_receipt_method_id            := p_receipt_method_id;
        l_receipt_method_name          := p_receipt_method_name;
	l_doc_sequence_value           := p_doc_sequence_value;
        l_anticipated_clearing_date    := trunc(p_anticipated_clearing_date);
	l_attribute_rec                := p_attribute_record;
	l_global_attribute_rec         := p_global_attribute_record;
        l_payment_trxn_extension_id    := p_payment_trxn_extension_id;  /* payment uptake */
	l_misc_dist_tbl                := p_misc_dist_tbl; /*ER 7417553*/
       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

        SAVEPOINT Create_misc_PVT;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*--------------------------------------------------------------+
        |   Initialize message list if p_init_msg_list is set to TRUE  |
        +--------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
          THEN
              FND_MSG_PUB.initialize;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('ar_receipt_api.create_misc()+ ');
        END IF;
       /*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        x_return_status := FND_API.G_RET_STS_SUCCESS;
        l_doc_seq_status := FND_API.G_RET_STS_SUCCESS;



/* SSA change */
       l_org_id            := p_org_id;
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;
       ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);
 IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
 ELSE
        /*-------------------------------------------------+
         | Initialize the profile option package variables |
         +-------------------------------------------------*/

           initialize_profile_globals;

       /*---------------------------------------------+
        |   ========== Start of API Body ==========   |
        +---------------------------------------------*/

   --If any value to id conversion fails then error status is returned

   -- ETAX: (bug 4594101) added l_receipt_date for derivation of tax rates.

       /*-------------------------------+
        |   Defaulting Ids from Values  |
        +-------------------------------*/

        ar_receipt_lib_pvt.Default_misc_ids(
                              p_usr_currency_code  ,
                              p_usr_exchange_rate_type,
                              p_activity,
                              p_reference_type,
                              p_reference_num,
                              p_tax_code,
                              l_receipt_method_name,
                              p_remittance_bank_account_name ,
                              p_remittance_bank_account_num ,
                              l_currency_code ,
                              l_exchange_rate_type ,
                              l_receivables_trx_id ,
                              l_reference_id,
                              l_vat_tax_id,
                              l_receipt_method_id,
                              l_remit_bank_acct_use_id ,
                              l_def_misc_id_return_status,
                              l_receipt_date
                              );


       /*-------------------------------+
        |          Defaulting           |
        +-------------------------------*/

        ar_receipt_lib_pvt.Get_misc_defaults(
                              l_currency_code,
                              l_exchange_rate_type,
                              l_exchange_rate,
                              l_exchange_date,
                              l_amount,
                              l_receipt_date,
                              l_gl_date,
                              l_remit_bank_acct_use_id,
                              l_deposit_date,
                              l_state,
                              l_distribution_set_id,
                              l_vat_tax_id,
                              l_tax_rate,
                              l_receipt_method_id,
                              l_receivables_trx_id,
                              p_tax_code,
                              p_tax_amount,
                              l_creation_method_code,
                              l_misc_def_return_status
                              );

       /*------------------------------------------+
        |  Get legal_entity_id                     |
        +------------------------------------------*/  /* R12 LE uptake */
           l_legal_entity_id := ar_receipt_lib_pvt.get_legal_entity(l_remit_bank_acct_use_id);

       /*-------------------------------+
        |         Validation            |
        +-------------------------------*/

        ar_receipt_val_pvt.Validate_misc_receipt(
                              l_receipt_number,
                              l_receipt_method_id,
                              l_state,
                              l_receipt_date,
                              l_gl_date,
                              l_deposit_date,
                              l_amount,
                              p_receivables_trx_id,
                              l_receivables_trx_id,
                              l_distribution_set_id,
                              p_vat_tax_id,
                              l_vat_tax_id,
                              l_tax_rate,
                              p_tax_amount,
                              p_reference_num,
                              p_reference_id, --original reference_id
                              l_reference_id,
                              p_reference_type,
                              l_remit_bank_acct_use_id,
                              l_anticipated_clearing_date,
                              l_currency_code,
                              l_exchange_rate_type,
                              l_exchange_rate,
                              l_exchange_date,
                              l_doc_sequence_value,
                              l_val_return_status
                              );

         --validate and default the flexfields
         /* Bug fix 3619780 : Don't Validate the descriptive flex field if api is called from
           Credit card refund */

         --Bug 4166986  CC_chargeback project
         IF NVL(p_called_from ,'X')  NOT IN
            ('CC_REFUND','CM_REFUND','CC_CHARGEBACK') THEN
            ar_receipt_lib_pvt.Validate_Desc_Flexfield(
                              l_attribute_rec,
                              'AR_CASH_RECEIPTS',
                              l_dflex_val_return_status
                              );
        END IF;
	/*Validate misc distributions desc flex fields*/
	IF p_misc_dist_tbl.COUNT > 0 THEN
	FOR I IN p_misc_dist_tbl.FIRST..p_misc_dist_tbl.LAST
	LOOP
	l_attribute_rec_tbl(I).ATTRIBUTE_CATEGORY 		    :=  p_misc_dist_tbl(I).ATTRIBUTE_CATEGORY;
	l_attribute_rec_tbl(I).ATTRIBUTE1          		    :=  p_misc_dist_tbl(I).ATTRIBUTE1;
	l_attribute_rec_tbl(I).ATTRIBUTE2          		    :=  p_misc_dist_tbl(I).ATTRIBUTE2;
	l_attribute_rec_tbl(I).ATTRIBUTE3          		    :=  p_misc_dist_tbl(I).ATTRIBUTE3;
	l_attribute_rec_tbl(I).ATTRIBUTE4          		    :=  p_misc_dist_tbl(I).ATTRIBUTE4;
	l_attribute_rec_tbl(I).ATTRIBUTE5          		    :=  p_misc_dist_tbl(I).ATTRIBUTE5;
	l_attribute_rec_tbl(I).ATTRIBUTE6          		    :=  p_misc_dist_tbl(I).ATTRIBUTE6;
	l_attribute_rec_tbl(I).ATTRIBUTE7          		    :=  p_misc_dist_tbl(I).ATTRIBUTE7;
	l_attribute_rec_tbl(I).ATTRIBUTE8          		    :=  p_misc_dist_tbl(I).ATTRIBUTE8;
	l_attribute_rec_tbl(I).ATTRIBUTE9          		    :=  p_misc_dist_tbl(I).ATTRIBUTE9;
	l_attribute_rec_tbl(I).ATTRIBUTE10         		    :=  p_misc_dist_tbl(I).ATTRIBUTE10;
	l_attribute_rec_tbl(I).ATTRIBUTE11         		    :=  p_misc_dist_tbl(I).ATTRIBUTE11;
	l_attribute_rec_tbl(I).ATTRIBUTE12         		    :=  p_misc_dist_tbl(I).ATTRIBUTE12;
	l_attribute_rec_tbl(I).ATTRIBUTE13         		    :=  p_misc_dist_tbl(I).ATTRIBUTE13;
	l_attribute_rec_tbl(I).ATTRIBUTE14         		    :=  p_misc_dist_tbl(I).ATTRIBUTE14;
	l_attribute_rec_tbl(I).ATTRIBUTE15         		    :=  p_misc_dist_tbl(I).ATTRIBUTE15;
	END LOOP;

	FOR I IN l_attribute_rec_tbl.FIRST ..l_attribute_rec_tbl.LAST
	LOOP
	ar_receipt_lib_pvt.Validate_Desc_Flexfield(
	l_attribute_rec_tbl(I),
	'AR_MISC_CASH_DISTRIBUTIONS',
	l_misc_dflex_val_return_status
	);
	  IF l_misc_dflex_val_return_status <> FND_API.G_RET_STS_SUCCESS THEN
			EXIT;
	  END IF;
	END LOOP;
       END IF;
      --added by Jixun for ER#20226110 begin
      IF fv_install.enabled_yn = 'Y' THEN

        IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug(' Calling FV Pre-processor Code Hook');
        END IF;

        DECLARE
          l_gdf_tbl   FV_GTAS_UTILITY_PKG.GDF_TBL_TYPE;
          l_ledger_id GL_LEDGERS.LEDGER_ID%TYPE;
        BEGIN

          BEGIN
            SELECT set_of_books_id
              INTO l_ledger_id
              FROM hr_operating_units
             WHERE organization_id = l_org_id;
          EXCEPTION
            WHEN no_data_found THEN
              l_ledger_id := -1;
          END;

          FOR i IN 1 .. l_misc_dist_tbl.count LOOP
            l_gdf_tbl(i).org_id := l_org_id;
            l_gdf_tbl(i).ledger_id := l_ledger_id;
            l_gdf_tbl(i).code_combination_id := l_misc_dist_tbl(i)
                                                .code_combination_id;
            l_gdf_tbl(i).global_attribute1 := l_misc_dist_tbl(i)
                                              .global_attribute1;
            l_gdf_tbl(i).global_attribute2 := l_misc_dist_tbl(i)
                                              .global_attribute2;
            l_gdf_tbl(i).global_attribute3 := l_misc_dist_tbl(i)
                                              .global_attribute3;
            l_gdf_tbl(i).global_attribute4 := l_misc_dist_tbl(i)
                                              .global_attribute4;
            l_gdf_tbl(i).global_attribute5 := l_misc_dist_tbl(i)
                                              .global_attribute5;
            l_gdf_tbl(i).global_attribute6 := l_misc_dist_tbl(i)
                                              .global_attribute6;
            l_gdf_tbl(i).global_attribute7 := l_misc_dist_tbl(i)
                                              .global_attribute7;
            l_gdf_tbl(i).global_attribute8 := l_misc_dist_tbl(i)
                                              .global_attribute8;
            l_gdf_tbl(i).global_attribute9 := l_misc_dist_tbl(i)
                                              .global_attribute9;
            l_gdf_tbl(i).global_attribute10 := l_misc_dist_tbl(i)
                                               .global_attribute10;
            l_gdf_tbl(i).global_attribute11 := l_misc_dist_tbl(i)
                                               .global_attribute11;
            l_gdf_tbl(i).global_attribute12 := l_misc_dist_tbl(i)
                                               .global_attribute12;
            l_gdf_tbl(i).global_attribute13 := l_misc_dist_tbl(i)
                                               .global_attribute13;
            l_gdf_tbl(i).global_attribute14 := l_misc_dist_tbl(i)
                                               .global_attribute14;
            l_gdf_tbl(i).global_attribute15 := l_misc_dist_tbl(i)
                                               .global_attribute15;
            l_gdf_tbl(i).global_attribute16 := l_misc_dist_tbl(i)
                                               .global_attribute16;
            l_gdf_tbl(i).global_attribute17 := l_misc_dist_tbl(i)
                                               .global_attribute17;
            l_gdf_tbl(i).global_attribute18 := l_misc_dist_tbl(i)
                                               .global_attribute18;
            l_gdf_tbl(i).global_attribute19 := l_misc_dist_tbl(i)
                                               .global_attribute19;
            l_gdf_tbl(i).global_attribute20 := l_misc_dist_tbl(i)
                                               .global_attribute20;
            l_gdf_tbl(i).global_attribute21 := l_misc_dist_tbl(i)
                                               .global_attribute21;
            l_gdf_tbl(i).global_attribute22 := l_misc_dist_tbl(i)
                                               .global_attribute22;
            l_gdf_tbl(i).global_attribute23 := l_misc_dist_tbl(i)
                                               .global_attribute23;
            l_gdf_tbl(i).global_attribute24 := l_misc_dist_tbl(i)
                                               .global_attribute24;
            l_gdf_tbl(i).global_attribute25 := l_misc_dist_tbl(i)
                                               .global_attribute25;
            l_gdf_tbl(i).global_attribute26 := l_misc_dist_tbl(i)
                                               .global_attribute26;
            l_gdf_tbl(i).global_attribute27 := l_misc_dist_tbl(i)
                                               .global_attribute27;
            l_gdf_tbl(i).global_attribute28 := l_misc_dist_tbl(i)
                                               .global_attribute28;
            l_gdf_tbl(i).global_attribute29 := l_misc_dist_tbl(i)
                                               .global_attribute29;
            l_gdf_tbl(i).global_attribute30 := l_misc_dist_tbl(i)
                                               .global_attribute30;
            l_gdf_tbl(i).customer_id	    :=l_global_attribute_rec
	    					.global_attribute7;
	    l_gdf_tbl(i).reclass_receipt_id :=l_global_attribute_rec
	    					.global_attribute8;

          END LOOP;

          FV_GTAS_UTILITY_PKG.ar_misc_adj_gdf_pre_processor(p_mode          => 'MISC_RECEIPT',
                                                            p_mis_adj_rec  => l_gdf_tbl,
                                                            p_msg_data      => x_msg_data,
                                                            p_msg_count     => x_msg_count,
                                                            p_return_status => x_return_status);

          IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) then
            arp_util.debug('ar_check_gdf_pre_processor validation failed');
            arp_util.debug('Message : ' || x_msg_data);
            x_return_status := FND_API.G_RET_STS_ERROR;
          END IF;

        EXCEPTION
          WHEN OTHERS THEN
            IF PG_DEBUG in ('Y', 'C') THEN
              arp_standard.debug('ar_check_gdf_post_processor: Exception calling FV_GTAS_UTILITY_PKG.ar_check_gdf_post_processor.');
              arp_standard.debug('Error Calling FV Code Hook');
              arp_standard.debug('ar_check_gdf_pre_processor: ' || sqlcode ||
                                 SQLERRM);
              ROLLBACK to Create_misc_PVT;
              raise;
            END IF;
        END;

        IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug(' Exiting FV Pre-process Code Hook');
        END IF;
      END IF;
      --added by Jixun for ER#20226110 end

END IF;


         IF l_misc_def_return_status <> FND_API.G_RET_STS_SUCCESS OR
            l_val_return_status <> FND_API.G_RET_STS_SUCCESS  OR
            l_def_misc_id_return_status <> FND_API.G_RET_STS_SUCCESS OR
            l_dflex_val_return_status <> FND_API.G_RET_STS_SUCCESS  OR
	    l_misc_dflex_val_return_status <> FND_API.G_RET_STS_SUCCESS  THEN

            x_return_status := FND_API.G_RET_STS_ERROR;
         END IF;

        --Call the document sequence routine only if there have been no errors
        --reported so far.
	IF NVL(l_creation_method_code, 'X') = 'MANUAL'
		THEN
		   l_creation_method := 'M';
		ELSIF NVL(l_creation_method_code, 'X') = 'AUTOMATIC'
		THEN
		   l_creation_method := 'A';
		ELSE
		   l_creation_method := 'M';
        END IF;

          IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('create_misc: l_misc_def_return_status = ' || l_misc_def_return_status);
               arp_util.debug('create_misc: l_val_return_status = ' || l_val_return_status);
               arp_util.debug('create_misc: l_def_misc_id_return_status = ' || l_def_misc_id_return_status);
               arp_util.debug('create_misc: l_dflex_val_return_status = ' || l_dflex_val_return_status);
               arp_util.debug('create_misc: l_creation_method = ' || l_creation_method );
               arp_util.debug('create_misc: arp_global.set_of_books_id = ' || arp_global.set_of_books_id );
               arp_util.debug('create_misc: l_receipt_date = ' || l_receipt_date );
               arp_util.debug('create_misc: x_return_status = ' || x_return_status );
            END IF;
        IF x_return_status = FND_API.G_RET_STS_SUCCESS  THEN

           ar_receipt_lib_pvt.get_doc_seq(
                              222,
                              l_receipt_method_name,
                              arp_global.set_of_books_id,
                              l_creation_method,
                              l_receipt_date,
                              l_doc_sequence_value,
                              l_doc_sequence_id,
                              l_doc_seq_status
                               );
        END IF;

      --If receipt number has not been passed in the document sequence value is
      --used as the receipt number.
        IF l_receipt_number IS NULL THEN
          IF l_doc_sequence_value IS NOT NULL THEN
            l_receipt_number := l_doc_sequence_value;
			-- Copy the Receipt Number in the out NOCOPY parameter
	        p_receipt_number := l_receipt_number;
            --warning message
             IF FND_MSG_PUB.Check_Msg_Level(G_MSG_SUCCESS)
              THEN
                 FND_MESSAGE.SET_NAME('AR','AR_RAPI_RCPT_NUM_DFLT_DOC_SEQ');
                 FND_MSG_PUB.Add;
             END IF;
          ELSE
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('create_misc: ' || 'Receipt Number is null ');
            END IF;
            --raise error message
              FND_MESSAGE.SET_NAME('AR','AR_RAPI_RCPT_NUM_NULL');
              FND_MSG_PUB.Add;
              x_return_status := FND_API.G_RET_STS_ERROR;
          END IF;
        END IF;

	/*  payment uptake copy extn start */
        /*bug 17536419 */
      IF  (l_creation_method = 'A'
      and (l_payment_trxn_extension_id is NULL and l_reference_id is not null)
      or  (l_payment_trxn_extension_id is not NULL and l_reference_id is null) ) THEN

               arp_util.debug('create_misc: l_creation_method= ' || l_creation_method);
               arp_util.debug('create_misc: l_payment_trxn_extension_id= ' || l_payment_trxn_extension_id );
              FND_MESSAGE.SET_NAME('AR','AR_CC_AUTH_FAILED');
              FND_MSG_PUB.Add;
              x_return_status := FND_API.G_RET_STS_ERROR;
      END IF;
       /*  payment uptake copy extn end */

       /*------------------------------------------------------------+
        |  If any errors - including validation failures - occurred, |
        |  rollback any changes and return an error status.          |
        +------------------------------------------------------------*/

         IF (
              x_return_status         <> FND_API.G_RET_STS_SUCCESS
              OR l_doc_seq_status     <> FND_API.G_RET_STS_SUCCESS
             )
             THEN

              ROLLBACK TO Create_misc_PVT;

              x_return_status := FND_API.G_RET_STS_ERROR ;

              FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                        p_count => x_msg_count,
                                        p_data  => x_msg_data);

              IF PG_DEBUG in ('Y', 'C') THEN
                 arp_util.debug('create_misc: ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
              END IF;
             Return;
        END IF;
          IF PG_DEBUG in ('Y', 'C') THEN
             arp_util.debug('create_misc: ' || 'x_return_status '||x_return_status);
          END IF;

        /* Bug fix 2300268
           Get the tax account id corresponding to the vat_tax_id */
           IF l_vat_tax_id IS NOT NULL THEN
            /* 5955921 Replaced select statement */
             SELECT tax_account_ccid
              INTO   l_tax_account_id
             FROM zx_accounts
             WHERE  tax_account_entity_id = l_vat_tax_id
              AND  tax_account_entity_code = 'RATES'
              AND  internal_organization_id = l_org_id;

	     /*SELECT tax_account_id
             INTO   l_tax_account_id
             FROM   ar_vat_tax
             WHERE  vat_tax_id = l_vat_tax_id;*/
          ELSE
             l_tax_account_id := NULL;
          END IF;
       /* End Bug fix 2300268 */

       /*-------------------------------+
        |   Call to the Entity Handler  |
        +-------------------------------*/
          IF PG_DEBUG in ('Y', 'C') THEN
             arp_util.debug('create_misc: ' || ' orig payment_trxn_extension_id '||l_payment_trxn_extension_id);
          END IF;

/* bichatte payment uptake copy extn start */
      IF l_creation_method = 'A' and l_reference_id is not null  THEN
          arp_standard.debug('calling copy  Extension....');
       /* 5955921 */
     Begin
       select pay_from_customer,customer_site_use_id
       into   l_customer_id,l_customer_site_use_id
       from ar_cash_receipts
       --where payment_trxn_extension_id = l_payment_trxn_extension_id;
       --Bug : 6855895
       where cash_receipt_id = l_reference_id;


     IF PG_DEBUG in ('Y','C') THEN
       arp_util.debug ( 'the value of pmt_trxn_extn_id '|| l_payment_trxn_extension_id);
       arp_util.debug ( 'the value of customer_id      '|| l_customer_id);
       arp_util.debug ( 'the value of receipt_met_id   '|| l_receipt_method_id);
       arp_util.debug ( 'the value of org_id           '|| l_org_id);
       arp_util.debug ( 'the value of cust_site_use_id '|| l_customer_site_use_id);
       arp_util.debug ( 'the value of rec_number       '|| l_receipt_number);
     END IF;

	   Copy_payment_extension (
              p_payment_trxn_extension_id => l_payment_trxn_extension_id,
              p_customer_id => l_customer_id,
              p_receipt_method_id =>l_receipt_method_id,
              p_org_id =>l_org_id,
              p_customer_site_use_id  =>l_customer_site_use_id,
              p_receipt_number=> l_receipt_number,
              x_msg_count => l_copy_msg_count,
              x_msg_data => l_copy_msg_data,
              x_return_status =>l_copy_return_status,
              o_payment_trxn_extension_id =>l_copy_pmt_trxn_extension_id ,
	      p_receipt_date => l_receipt_date
                 );

         IF l_copy_return_status <>  FND_API.G_RET_STS_SUCCESS THEN
             arp_util.debug('Create_misc_123: ' );
             FND_MESSAGE.set_name('AR', 'AR_CC_AUTH_FAILED');
             FND_MSG_PUB.Add;
              x_return_status := FND_API.G_RET_STS_ERROR;
         END IF;
           l_payment_trxn_extension_id := l_copy_pmt_trxn_extension_id;

          arp_standard.debug('calling copy  Extension  end ....');
         arp_standard.debug('calling copy  Extension  end ...2'|| to_char(l_copy_pmt_trxn_extension_id));

	 EXCEPTION WHEN NO_DATA_FOUND THEN
          FND_MESSAGE.set_name('AR', 'AR_CC_AUTH_FAILED');
          FND_MSG_PUB.Add;
          x_return_status := FND_API.G_RET_STS_ERROR;
         END;

     END IF;


/* Assign NUll to pmt_trxn_extension_id for 'CC_Chargeback trxn'sCC_CHARGEBACK */

       IF p_called_from = 'CC_CHARGEBACK' THEN

           l_copy_pmt_trxn_extension_id := null;
         IF PG_DEBUG in ('Y','C') THEN
          arp_standard.debug('calling copy  Extension  end ....');
         END IF;

       END IF;


/* bichatte payment uptake copy extn end */
       BEGIN
         arp_process_misc_receipts.insert_misc_receipt(
	                       p_currency_code
                                       => l_currency_code,
	                       p_amount
                                       => p_amount,
	                       p_receivables_trx_id
                                       => l_receivables_trx_id,
	                       p_misc_payment_source
                                       => p_misc_payment_source,
	                       p_receipt_number
                                       => l_receipt_number,
	                       p_receipt_date
                                       => l_receipt_date,
	                       p_gl_date
                                       => l_gl_date,
	                       p_comments
                                       => p_comments,
	                       p_exchange_rate_type
                                       => l_exchange_rate_type,
	                       p_exchange_rate
                                       => l_exchange_rate,
                               p_exchange_date
                                       => l_exchange_date,
		               p_batch_id
                                       => null,
	                       p_attribute_category
                                       => l_attribute_rec.attribute_category,
	                       p_attribute1
                                       => l_attribute_rec.attribute1,
	                       p_attribute2
                                       => l_attribute_rec.attribute2,
	                       p_attribute3
                                       => l_attribute_rec.attribute3,
	                       p_attribute4
                                       => l_attribute_rec.attribute4,
	                       p_attribute5
                                       => l_attribute_rec.attribute5,
	                       p_attribute6
                                       => l_attribute_rec.attribute6,
	                       p_attribute7
                                       => l_attribute_rec.attribute7,
	                       p_attribute8
                                       => l_attribute_rec.attribute8,
	                       p_attribute9
                                       => l_attribute_rec.attribute9,
	                       p_attribute10
                                       => l_attribute_rec.attribute10,
	                       p_attribute11
                                       => l_attribute_rec.attribute11,
	                       p_attribute12
                                       => l_attribute_rec.attribute12,
	                       p_attribute13
                                       => l_attribute_rec.attribute13,
                               p_attribute14
                                       => l_attribute_rec.attribute14,
	                       p_attribute15
                                       => l_attribute_rec.attribute15,
	                       p_remittance_bank_account_id
                                       => l_remit_bank_acct_use_id,
	                       p_deposit_date
                                       => l_deposit_date,
	                       p_receipt_method_id
                                       => l_receipt_method_id,
	                       p_doc_sequence_value
                                       => l_doc_sequence_value,
	                       p_doc_sequence_id
                                       => l_doc_sequence_id,
	                       p_distribution_set_id
                                       => l_distribution_set_id,
	                       p_reference_type
                                       => p_reference_type,
	                       p_reference_id
                                       => l_reference_id,
	                       p_vat_tax_id
                                       => l_vat_tax_id,
                               p_ussgl_transaction_code
                                       => p_ussgl_transaction_code,
	                       p_anticipated_clearing_date
                                       => l_anticipated_clearing_date, /* Bug fix 3135407 */
	                       p_global_attribute1
                                       => l_global_attribute_rec.global_attribute1,
	                       p_global_attribute2
                                       => l_global_attribute_rec.global_attribute2,
	                       p_global_attribute3
                                       => l_global_attribute_rec.global_attribute3,
	                       p_global_attribute4
                                       => l_global_attribute_rec.global_attribute4,
	                       p_global_attribute5
                                       => l_global_attribute_rec.global_attribute5,
	                       p_global_attribute6
                                       => l_global_attribute_rec.global_attribute6,
	                       p_global_attribute7
                                       => l_global_attribute_rec.global_attribute7,
	                       p_global_attribute8
                                       => l_global_attribute_rec.global_attribute8,
	                       p_global_attribute9
                                       => l_global_attribute_rec.global_attribute9,
	                       p_global_attribute10
                                       => l_global_attribute_rec.global_attribute10,
	                       p_global_attribute11
                                       => l_global_attribute_rec.global_attribute11,
	                       p_global_attribute12
                                       => l_global_attribute_rec.global_attribute12,
	                       p_global_attribute13
                                       => l_global_attribute_rec.global_attribute13,
                               p_global_attribute14
                                       => l_global_attribute_rec.global_attribute14,
	                       p_global_attribute15
                                       => l_global_attribute_rec.global_attribute15,
	                       p_global_attribute16
                                       => l_global_attribute_rec.global_attribute16,
	                       p_global_attribute17
                                       => l_global_attribute_rec.global_attribute17,
	                       p_global_attribute18
                                       => l_global_attribute_rec.global_attribute18,
	                       p_global_attribute19
                                       => l_global_attribute_rec.global_attribute19,
	                       p_global_attribute20
                                       => l_global_attribute_rec.global_attribute20,
	                       p_global_attribute_category
                                     => l_global_attribute_rec.global_attribute_category,
 	                       p_cr_id
                                       => p_misc_receipt_id,
	                       p_row_id
                                       => l_row_id,
	                       p_form_name
                                       => 'RAPI',
	                       p_form_version
                                       => p_api_version,
                               p_tax_rate
                                       => l_tax_rate,
                               p_gl_tax_acct
                                       => l_tax_account_id ,/* Bug fix 2300268 */
                               p_crh_id
                                       => l_crh_id, /* Bug fix 2742388 */
			       p_legal_entity_id => l_legal_entity_id, /* R12 LE uptake */
                               p_payment_trxn_extension_id => l_copy_pmt_trxn_extension_id,
			        p_misc_dist_tbl => l_misc_dist_tbl  /*ER 7417553*/
                                );
       EXCEPTION
         WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN
                     ROLLBACK TO Create_misc_PVT;

                      --  Display_Parameters;
                      x_return_status := FND_API.G_RET_STS_ERROR ;
                       FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                       FND_MESSAGE.SET_TOKEN('GENERIC_TEXT',
                           'ARP_PROCESS_MISC_RECEIPTS.INSERT_MISC_RECEIPT : '||SQLERRM);
                       FND_MSG_PUB.Add;

                       FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                                                  p_count  =>  x_msg_count,
                                                  p_data   => x_msg_data
                                                );
                      RETURN;
                ELSE
                   RAISE;
                END IF;

         END;

            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('create_misc: ' || 'Misc Receipt id : '||to_char(p_misc_receipt_id));
            END IF;

      --added by Jixun for ER#20226110 begin
      IF fv_install.enabled_yn = 'Y' THEN
        IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug(' Calling FV Post-process Code Hook');
        END IF;

      BEGIN
        FV_GTAS_UTILITY_PKG.ar_check_gdf_post_processor(p_id            => p_misc_receipt_id,
                                                        p_mode          => 'MISC_RECEIPT',
                                                        p_msg_data      => x_msg_data,
                                                        p_msg_count     => x_msg_count,
                                                        p_return_status => x_return_status);

        IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) then
          arp_util.debug('ar_check_gdf_post_processor validation failed');
          arp_util.debug('Message : ' || x_msg_data);
          x_return_status := FND_API.G_RET_STS_ERROR;
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
          IF PG_DEBUG in ('Y', 'C') THEN
            arp_standard.debug('ar_check_gdf_post_processor: Exception calling FV_GTAS_UTILITY_PKG.ar_check_gdf_post_processor.');
            arp_standard.debug('Error Calling FV Code Hook');
            arp_standard.debug('ar_check_gdf_post_processor: ' || sqlcode ||
                               SQLERRM);
            ROLLBACK to Create_misc_PVT;
            raise;
          END IF;
      END;

      IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug(' Exiting FV Post-process Code Hook');
      END IF;
    END IF;
    --added by Jixun for ER#20226110 end

       /*-------------------------------------------------------+
        | FND_MSG_PUB.Count_And_Get used  get the count of mesg.|
        | in the message stack. If there is only one message in |
        | the stack it retrieves this message                   |
        +-------------------------------------------------------*/

          FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                   p_count => x_msg_count,
                                   p_data  => x_msg_data
                                 );


       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('create_misc: ' || 'committing');
            END IF;
            Commit;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Create_Misc_Receipt()- ');
        END IF;






EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('create_misc: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('create_misc: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Create_misc_PVT;
                x_return_status := FND_API.G_RET_STS_ERROR ;

                --Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('create_misc: ' || SQLERRM, G_MSG_ERROR);
                END IF;
                ROLLBACK TO Create_misc_PVT;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

               --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN
                     ROLLBACK TO Create_misc_PVT;

                      --  Display_Parameters;
                      x_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','CREATE_MISC : '||SQLERRM);
                      FND_MSG_PUB.Add;

                      FND_MSG_PUB.Count_And_Get( p_encoded => FND_API.G_FALSE,
                                                 p_count  =>  x_msg_count,
                                                 p_data   => x_msg_data
                                                );
                      RETURN;
                ELSE
                      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','CREATE_MISC : '||SQLERRM);
                      FND_MSG_PUB.Add;
                END IF;

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('create_misc: ' || SQLCODE);
                   arp_util.debug('create_misc: ' || SQLERRM);
                END IF;

                ROLLBACK TO Create_misc_PVT;


                IF      FND_MSG_PUB.Check_Msg_Level
                THEN
                FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME,
                                        l_api_name
                                       );
                END IF;

             --   Display_Parameters;
                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

END Create_misc;


PROCEDURE set_profile_for_testing(p_profile_doc_seq            VARCHAR2,
                                  p_profile_enable_cc          VARCHAR2,
                                  p_profile_appln_gl_date_def  VARCHAR2,
                                  p_profile_amt_applied_def    VARCHAR2,
                                  p_profile_cc_rate_type       VARCHAR2,
                                  p_profile_dsp_inv_rate       VARCHAR2,
                                  p_profile_create_bk_charges  VARCHAR2,
                                  p_profile_def_x_rate_type    VARCHAR2,
                                  p_pay_unrelated_inv_flag     VARCHAR2,
                                  p_unearned_discount          VARCHAR2) IS
BEGIN
	ar_receipt_lib_pvt.pg_profile_doc_seq           := p_profile_doc_seq;
	ar_receipt_lib_pvt.pg_profile_enable_cc         := p_profile_enable_cc;
	ar_receipt_lib_pvt.pg_profile_appln_gl_date_def := p_profile_appln_gl_date_def;
	ar_receipt_lib_pvt.pg_profile_amt_applied_def   := p_profile_amt_applied_def;
	ar_receipt_lib_pvt.pg_profile_cc_rate_type      := p_profile_cc_rate_type;
	ar_receipt_lib_pvt.pg_profile_dsp_inv_rate      := p_profile_dsp_inv_rate;
	ar_receipt_lib_pvt.pg_profile_create_bk_charges := p_profile_create_bk_charges;
	ar_receipt_lib_pvt.pg_profile_def_x_rate_type   := p_profile_def_x_rate_type;
	arp_global.sysparam.pay_unrelated_invoices_flag := p_pay_unrelated_inv_flag;
	arp_global.sysparam.unearned_discount           := p_unearned_discount;


END set_profile_for_testing;

PROCEDURE Apply_Open_Receipt(
-- Standard API parameters.
      p_api_version                  IN  NUMBER,
      p_init_msg_list                IN  VARCHAR2,
      p_commit                       IN  VARCHAR2,
      p_validation_level             IN  NUMBER,
      x_return_status                OUT NOCOPY VARCHAR2,
      x_msg_count                    OUT NOCOPY NUMBER,
      x_msg_data                     OUT NOCOPY VARCHAR2,
 --  Receipt application parameters.
      p_cash_receipt_id              IN ar_cash_receipts.cash_receipt_id%TYPE,
      p_receipt_number               IN ar_cash_receipts.receipt_number%TYPE,
      p_applied_payment_schedule_id  IN ar_payment_schedules.payment_schedule_id%TYPE,
      p_open_cash_receipt_id         IN ar_cash_receipts.cash_receipt_id%TYPE,
      p_open_receipt_number          IN ar_cash_receipts.receipt_number%TYPE,
      p_open_rec_app_id              IN ar_receivable_applications.receivable_application_id%TYPE,
      p_amount_applied               IN ar_receivable_applications.amount_applied%TYPE,
      p_apply_date    IN ar_receivable_applications.apply_date%TYPE,
      p_apply_gl_date                IN ar_receivable_applications.gl_date%TYPE,
      p_ussgl_transaction_code       IN ar_receivable_applications.ussgl_transaction_code%TYPE,
      p_called_from                  IN VARCHAR2 ,
      p_attribute_rec                IN attribute_rec_type,
	 -- ******* Global Flexfield parameters *******
      p_global_attribute_rec  IN global_attribute_rec_type,
      p_comments                     IN ar_receivable_applications.comments%TYPE,
      p_org_id             IN NUMBER  DEFAULT NULL,
      x_application_ref_num          OUT NOCOPY ar_receivable_applications.application_ref_num%TYPE,
      x_receivable_application_id    OUT NOCOPY ar_receivable_applications.receivable_application_id%TYPE,
      x_applied_rec_app_id           OUT NOCOPY ar_receivable_applications.receivable_application_id%TYPE,
      x_acctd_amount_applied_from    OUT NOCOPY ar_receivable_applications.acctd_amount_applied_from%TYPE,
      x_acctd_amount_applied_to      OUT NOCOPY ar_receivable_applications.acctd_amount_applied_to%TYPE
      ) IS
l_api_name       CONSTANT VARCHAR2(20) := 'Apply_Open_Receipt';
l_api_version    CONSTANT NUMBER       := 1.0;
l_cash_receipt_id  NUMBER;
l_receipt_number             ar_cash_receipts.receipt_number%TYPE;
l_open_cash_receipt_id    ar_cash_receipts.cash_receipt_id%TYPE;
l_open_receipt_number     ar_cash_receipts.receipt_number%TYPE;
l_applied_payment_schedule_id ar_payment_schedules.payment_schedule_id%TYPE;
l_open_rec_app_id  ar_receivable_applications.receivable_application_id%TYPE;
l_cr_gl_date       DATE;
l_open_cr_gl_date  DATE;
l_cr_date          DATE;
l_last_receipt_date DATE;
l_cr_amount        NUMBER;
l_cr_unapp_amount  NUMBER;
l_cr_currency VARCHAR2(15);
l_open_cr_currency VARCHAR2(15);
l_apply_gl_date DATE;
l_amount_applied NUMBER;
l_reapply_amount NUMBER;
l_open_amount_applied NUMBER;
l_cr_payment_schedule_id  NUMBER;
l_open_applied_ps_id NUMBER;
l_unapplied_cash  NUMBER;
l_open_cr_ps_id           NUMBER;
l_apply_date              DATE;
l_cr_customer_id          NUMBER;
l_open_cr_customer_id     NUMBER;

l_def_return_status  VARCHAR2(1);
l_val_return_status VARCHAR2(1);
l_dflex_val_return_status  VARCHAR2(1);
l_attribute_rec         attribute_rec_type;
l_global_attribute_rec  global_attribute_rec_type;
l_remi_bank_acct_use_id    NUMBER;
l_receipt_method_id             NUMBER;
l_application_ref_id      ar_receivable_applications.application_ref_id%TYPE;
l_application_ref_num     ar_receivable_applications.application_ref_num%TYPE;
l_secondary_app_ref_id    ar_receivable_applications.secondary_application_ref_id%TYPE;
l_application_ref_reason  ar_receivable_applications.application_ref_reason%TYPE;
l_customer_reference      ar_receivable_applications.customer_reference%TYPE;
l_customer_reason         ar_receivable_applications.customer_reason%TYPE;
l_act_application_ref_id   ar_receivable_applications.application_ref_id%TYPE;
l_act_application_ref_num  ar_receivable_applications.application_ref_num%TYPE;
l_act_application_ref_type ar_receivable_applications.application_ref_type%TYPE;
l_act_secondary_app_ref_id ar_receivable_applications.secondary_application_ref_id%TYPE;
l_reapply_rec_trx_id      ar_receivables_trx.receivables_trx_id%TYPE;
l_netting_rec_trx_id      CONSTANT ar_receivables_trx.receivables_trx_id%TYPE := -16;
l_reapply_rec_app_id      ar_receivable_applications.receivable_application_id%TYPE;
l_net_rec_app_id          ar_receivable_applications.receivable_application_id%TYPE;
l_open_net_rec_app_id     ar_receivable_applications.receivable_application_id%TYPE;
l_return_status           VARCHAR2(1);
l_msg_count               NUMBER;
l_reapply_msg_count       NUMBER;
l_unapply_msg_count       NUMBER;
l_act1_msg_count          NUMBER;
l_act2_msg_count          NUMBER;
l_msg_data                VARCHAR2(2000);
l_called_from		  VARCHAR2(100);

l_app_rec		  ar_receivable_applications%ROWTYPE;
l_org_return_status VARCHAR2(1);
l_org_id                           NUMBER;

BEGIN

       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

      SAVEPOINT Apply_Open_Receipt_PVT;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*--------------------------------------------------------------+
        |   Initialize message list if p_init_msg_list is set to TRUE  |
        +--------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
          THEN
              FND_MSG_PUB.initialize;
        END IF;


        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Apply_Open_Receipt ()+ ');
        END IF;
       /*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        x_return_status := FND_API.G_RET_STS_SUCCESS;




/* SSA change */
       l_org_id            := p_org_id;
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;
       ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);
 IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
 ELSE
        /*-------------------------------------------------+
         | Initialize the profile option package variables |
         +-------------------------------------------------*/

        initialize_profile_globals;

       /*---------------------------------------------+
        |   ========== Start of API Body ==========   |
        +---------------------------------------------*/

        l_cash_receipt_id        := p_cash_receipt_id;
        l_receipt_number         := p_receipt_number;
        l_open_cash_receipt_id   := p_open_cash_receipt_id;
        l_open_receipt_number    := p_open_receipt_number;
        l_open_rec_app_id        := p_open_rec_app_id;
        l_applied_payment_schedule_id := p_applied_payment_schedule_id;
        l_amount_applied         := p_amount_applied;
        l_apply_date             := trunc(p_apply_date);
        l_apply_gl_date          := trunc(p_apply_gl_date);
        l_attribute_rec          := p_attribute_rec;
        l_global_attribute_rec   := p_global_attribute_rec;


          /*---------------------+
           |                     |
           |    DEFAULTING       |
           |                     |
           +---------------------*/

        ar_receipt_lib_pvt.default_open_receipt(
                            l_cash_receipt_id,
                            l_receipt_number,
                            l_applied_payment_schedule_id,
                            l_open_cash_receipt_id,
                            l_open_receipt_number,
                            l_apply_gl_date,
                            l_open_rec_app_id,
                            l_cr_payment_schedule_id,
                            l_last_receipt_date,
                            l_open_applied_ps_id,
                            l_unapplied_cash,
                            l_open_amount_applied,
                            l_reapply_rec_trx_id,
                            l_application_ref_num,
                            l_secondary_app_ref_id,
                            l_application_ref_reason,
                            l_customer_reference,
                            l_customer_reason,
                            l_cr_gl_date,
                            l_open_cr_gl_date,
                            l_cr_currency,
                            l_open_cr_currency,
                            l_cr_customer_id,
                            l_open_cr_customer_id,
                            l_def_return_status);

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('Apply_Open_Receipt: ' || 'Defaulting Ids Return_status = '||l_def_return_status);
   END IF;
          /*---------------------+
           |                     |
           |    VALIDATION       |
           |                     |
           +---------------------*/
    --The defaulting routine will raise error only if there is an error in
    --defaulting for any of the two receipts.
    --So in this case there is no point in calling the validation routines as
    --at least one of the two main entities are invalid.

    IF l_def_return_status = FND_API.G_RET_STS_SUCCESS
      THEN
          ar_receipt_val_pvt.Validate_open_receipt_info(
                      p_cash_receipt_id         =>  l_cash_receipt_id
                    , p_open_cash_receipt_id    =>  l_open_cash_receipt_id
                    , p_apply_date              =>  l_apply_date
                    , p_apply_gl_date           =>  l_apply_gl_date
                    , p_cr_gl_date              =>  l_cr_gl_date
                    , p_open_cr_gl_date         =>  l_open_cr_gl_date
                    , p_cr_date                 =>  l_last_receipt_date
                    , p_amount_applied          =>  l_amount_applied
                    , p_other_amount_applied    =>  l_open_amount_applied
                    , p_receipt_currency        =>  l_cr_currency
                    , p_open_receipt_currency   =>  l_open_cr_currency
                    , p_cr_customer_id          =>  l_cr_customer_id
                    , p_open_cr_customer_id     =>  l_open_cr_customer_id
                    , p_unapplied_cash          =>  l_unapplied_cash
                    , p_called_from             =>  p_called_from -- bug 2897244
                    , p_return_status           =>  l_val_return_status);

       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('Apply_Open_Receipt: ' || 'Validation Return_status = '||l_val_return_status);
       END IF;
    END IF;

         --validate and default the flexfields
        ar_receipt_lib_pvt.Validate_Desc_Flexfield(
                                        l_attribute_rec,
                                        'AR_RECEIVABLE_APPLICATIONS',
                                        l_dflex_val_return_status
                                                );

      arp_util.debug('*****DUMPING ALL THE ENTITY HANDLER PARAMETERS  ***');
      arp_util.debug('l_cr_payment_schedule_id : '||to_char(l_cr_payment_schedule_id));
      arp_util.debug('l_amount_applied : '||to_char(l_amount_applied));
      arp_util.debug('l_apply_date : '||to_char(l_apply_date,'DD-MON-YY'));
      arp_util.debug('l_apply_gl_date : '||to_char(l_apply_gl_date,'DD-MON-YY'));
END IF;


      IF l_val_return_status <> FND_API.G_RET_STS_SUCCESS  OR
         l_def_return_status <> FND_API.G_RET_STS_SUCCESS OR
         l_dflex_val_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          x_return_status := FND_API.G_RET_STS_ERROR;
       END IF;

       IF x_return_status <> FND_API.G_RET_STS_SUCCESS
         THEN

            ROLLBACK TO Apply_Open_Receipt_PVT;

             x_return_status := FND_API.G_RET_STS_ERROR ;

             FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                        p_count => x_msg_count,
                                        p_data  => x_msg_data
                                       );

             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Apply_Open_Receipt: ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
             END IF;
             Return;
        END IF;

      --Dump the input variables to the entity handler
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('Apply_Open_Receipt: ' || 'l_cr_payment_schedule_id      : '||to_char(l_cr_payment_schedule_id));
       arp_util.debug('Apply_Open_Receipt: ' || 'l_applied_payment_schedule_id : '||to_char(l_applied_payment_schedule_id));
       arp_util.debug('Apply_Open_Receipt: ' || 'l_amount_applied              : '||to_char(l_amount_applied));
       arp_util.debug('Apply_Open_Receipt: ' || 'l_cr_currency                 : '||l_cr_currency);
       arp_util.debug('Apply_Open_Receipt: ' || 'l_open_cr_currency            : '||l_open_cr_currency);
       arp_util.debug('l_apply_date                  : '||to_char(l_apply_date,'DD-MON-YY'));
       arp_util.debug('l_apply_gl_date               : '||to_char(l_apply_gl_date,'DD-MON-YY'));
    END IF;

     --lock both receipts before calling the entity handlers
       arp_cash_receipts_pkg.nowaitlock_p(p_cr_id => l_cash_receipt_id);
       arp_cash_receipts_pkg.nowaitlock_p(p_cr_id => l_open_cash_receipt_id);

          /*-------------------------------+
           |                               |
           |    Unapply open receipt       |
           |                               |
           +-------------------------------*/
     -- 1. Unapply open receipt if on account or claim , reapply any difference

     l_reapply_amount := (l_open_amount_applied + l_amount_applied);
     /* bug 5440979 . Passed p_customer_reference in call to Apply_on_account */
     pg_update_claim_amount := l_reapply_amount * -1; /* Bug 4170060 */

     IF l_open_applied_ps_id = -1 THEN
         Unapply_on_account(
              p_api_version               =>  1.0,
              p_validation_level          =>  FND_API.G_VALID_LEVEL_FULL,
              x_return_status             =>  x_return_status ,
              x_msg_count                 =>  l_unapply_msg_count,
              x_msg_data                  =>  x_msg_data ,
              p_cash_receipt_id           =>  l_open_cash_receipt_id,
              p_receivable_application_id =>  l_open_rec_app_id,
              p_reversal_gl_date          =>  l_apply_gl_date
              );

         IF (x_return_status = FND_API.G_RET_STS_SUCCESS) THEN
           IF (l_reapply_amount <> 0) THEN
             Apply_on_account(
              p_api_version               =>  1.0,
              p_validation_level          =>  FND_API.G_VALID_LEVEL_FULL,
              x_return_status             =>  x_return_status ,
              x_msg_count                 =>  l_reapply_msg_count,
              x_msg_data                  =>  x_msg_data ,
              p_cash_receipt_id           =>  l_open_cash_receipt_id,
              p_amount_applied            =>  l_reapply_amount,
              p_apply_date                =>  l_apply_date,
              p_apply_gl_date             =>  l_apply_gl_date,
              p_ussgl_transaction_code    =>  p_ussgl_transaction_code,
              p_attribute_rec             =>  p_attribute_rec,
              p_global_attribute_rec      =>  p_global_attribute_rec,
              p_comments                  =>  p_comments,
              p_customer_reference        =>  l_customer_reference,
              p_called_from               =>  'RAPI'
	      );
           END IF;
         END IF;

     ELSIF l_open_applied_ps_id = -4 THEN

        /* Bug 3708728: APPLY_OPEN_RECEIPT passed to p_called_from to bypass
           validation on unapplied amount */

         Unapply_other_account(
              p_api_version               =>  1.0,
              p_validation_level          =>  FND_API.G_VALID_LEVEL_FULL,
              x_return_status             =>  x_return_status ,
              x_msg_count                 =>  l_unapply_msg_count ,
              x_msg_data                  =>  x_msg_data ,
              p_cash_receipt_id           =>  l_open_cash_receipt_id,
              p_receivable_application_id =>  l_open_rec_app_id,
              p_reversal_gl_date          =>  l_apply_gl_date,
              p_org_id                    =>  p_org_id,
	      p_called_from		  =>  'APPLY_OPEN_RECEIPT'
      );
         IF (x_return_status = FND_API.G_RET_STS_SUCCESS) THEN
           IF (l_reapply_amount <> 0) THEN
             IF p_called_from = 'ARXRWAPP' THEN
                l_called_from := 'RAPI';
	     ELSE
		l_called_from := p_called_from;
	     END IF;
             Apply_other_account(
              p_api_version               =>  1.0,
              p_validation_level          =>  FND_API.G_VALID_LEVEL_FULL,
              x_return_status             =>  x_return_status ,
              x_msg_count                 =>  l_reapply_msg_count,
              x_msg_data                  =>  x_msg_data ,
              p_receivable_application_id =>  l_reapply_rec_app_id,
              p_cash_receipt_id           =>  l_open_cash_receipt_id,
              p_amount_applied            =>  l_reapply_amount,
              p_receivables_trx_id        =>  l_reapply_rec_trx_id,
              p_applied_payment_schedule_id => -4,
              p_apply_date                =>  l_apply_date,
              p_apply_gl_date             =>  l_apply_gl_date,
              p_ussgl_transaction_code    =>  p_ussgl_transaction_code,
              p_application_ref_type      =>  'CLAIM',
              p_application_ref_id        =>  l_application_ref_id,
              p_application_ref_num       =>  l_application_ref_num,
              p_secondary_application_ref_id => l_secondary_app_ref_id ,
              p_attribute_rec             =>  p_attribute_rec,
              p_global_attribute_rec      =>  p_global_attribute_rec,
              p_comments                  =>  p_comments,
              p_application_ref_reason    =>  l_application_ref_reason,
              p_customer_reference        =>  l_customer_reference,
              p_customer_reason           =>  l_customer_reason,
              p_org_id                    =>  p_org_id,
	      p_called_from		  =>  l_called_from
	      );
           END IF;
         END IF;

     END IF;

          /*------------------------------------------------+
           |                                                |
           |    Apply open receipt to netting activity      |
           |                                                |
           +------------------------------------------------*/

     IF (x_return_status = FND_API.G_RET_STS_SUCCESS) THEN
        Activity_application(
              p_api_version               =>  1.0,
              p_validation_level          =>  FND_API.G_VALID_LEVEL_FULL,
              x_return_status             =>  x_return_status ,
              x_msg_count                 =>  l_act1_msg_count,
              x_msg_data                  =>  x_msg_data ,
              p_cash_receipt_id           =>  l_open_cash_receipt_id,
              p_amount_applied            =>  l_amount_applied * -1,
              p_applied_payment_schedule_id => l_cr_payment_schedule_id,
              p_receivables_trx_id        =>  l_netting_rec_trx_id,
              p_apply_date                =>  l_apply_date,
              p_apply_gl_date             =>  l_apply_gl_date,
              p_ussgl_transaction_code    =>  p_ussgl_transaction_code,
              p_attribute_rec             =>  p_attribute_rec,
              p_global_attribute_rec      =>  p_global_attribute_rec,
              p_comments                  =>  p_comments,
              p_application_ref_type      =>  l_act_application_ref_type,
              p_application_ref_id        =>  l_act_application_ref_id,
              p_application_ref_num       =>  l_application_ref_num,
              p_secondary_application_ref_id => l_secondary_app_ref_id ,
              p_receivable_application_id =>  l_open_net_rec_app_id,
              p_customer_reference        =>  l_customer_reference, --4145224
              p_called_from		  =>  'RAPI',
              p_netted_receipt_flag 	  =>  'Y',
	      p_netted_cash_receipt_id    =>  l_open_cash_receipt_id,
	      p_org_id                    =>  p_org_id,
              p_customer_reason           =>  l_customer_reason -- 4145224
              );
     END IF;

          /*------------------------------------------------+
           |                                                |
           |    Apply netting receipt to netting activity   |
           |                                                |
           +------------------------------------------------*/

     IF (x_return_status = FND_API.G_RET_STS_SUCCESS) THEN
          Activity_application(
              p_api_version               =>  1.0,
              p_validation_level          =>  FND_API.G_VALID_LEVEL_FULL,
              x_return_status             =>  x_return_status ,
              x_msg_count                 =>  l_act2_msg_count,
              x_msg_data                  =>  x_msg_data ,
              p_cash_receipt_id           =>  l_cash_receipt_id,
              p_amount_applied            =>  l_amount_applied,
              p_applied_payment_schedule_id => l_applied_payment_schedule_id,
              p_receivables_trx_id        =>  l_netting_rec_trx_id,
              p_apply_date                =>  l_apply_date,
              p_apply_gl_date             =>  l_apply_gl_date,
              p_ussgl_transaction_code    =>  p_ussgl_transaction_code,
              p_attribute_rec             =>  p_attribute_rec,
              p_global_attribute_rec      =>  p_global_attribute_rec,
              p_comments                  =>  p_comments,
              p_application_ref_type      =>  l_act_application_ref_type,
              p_application_ref_id        =>  l_act_application_ref_id,
              p_application_ref_num       =>  l_application_ref_num,
              p_secondary_application_ref_id => l_secondary_app_ref_id ,
              p_receivable_application_id =>  l_net_rec_app_id,
              p_customer_reference        =>  l_customer_reference, -- 4145224
              p_called_from		  =>  p_called_from,
              p_netted_receipt_flag 	  =>  'N',
	      p_netted_cash_receipt_id    =>  l_open_cash_receipt_id,
	      p_org_id    =>  p_org_id,
              p_customer_reason           =>  l_customer_reason -- 4145224
      );
     END IF;

     --
     -- Setting the applied_rec_app_id on each netting application..
     --
     IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('Apply_Open_Receipt: Updating applications ');
     END IF;

     IF (l_net_rec_app_id IS NULL OR l_open_net_rec_app_id IS NULL)
     THEN
       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('Apply_Open_Receipt: error updating applications ' || SQLERRM);
          arp_util.debug('Apply_Open_Receipt: l_net_rec_app_id = ' || l_net_rec_app_id);
          arp_util.debug('Apply_Open_Receipt: l_open_net_rec_app_id = ' || l_open_net_rec_app_id);
       END IF;
       FND_MESSAGE.SET_NAME('AR','AR_RAPI_REC_APP_ID_INVALID');
       FND_MSG_PUB.Add;
       x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
     END IF;

     BEGIN
        arp_app_pkg.fetch_p(l_net_rec_app_id,l_app_rec);
        l_app_rec.applied_rec_app_id := l_open_net_rec_app_id;
        arp_app_pkg.update_p(l_app_rec);

        x_acctd_amount_applied_from := l_app_rec.acctd_amount_applied_from;
        x_acctd_amount_applied_to := l_app_rec.acctd_amount_applied_to;

        arp_app_pkg.fetch_p(l_open_net_rec_app_id,l_app_rec);
        l_app_rec.applied_rec_app_id := l_net_rec_app_id;
        arp_app_pkg.update_p(l_app_rec);

     EXCEPTION
       when others THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Apply_Open_Receipt: error updating applications ' || SQLCODE, G_MSG_ERROR);
               arp_util.debug('Apply_Open_Receipt: ' || SQLERRM, G_MSG_ERROR);
            END IF;
            x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
            RAISE;
     END;

     x_application_ref_num := l_application_ref_num;

     x_msg_count := l_unapply_msg_count + l_reapply_msg_count
                    + l_act1_msg_count + l_act2_msg_count;

       /*---------------------------------------------------+
        |   Raise exception if return status is not success |
        +---------------------------------------------------*/

     IF x_return_status = FND_API.G_RET_STS_ERROR
     THEN
       RAISE FND_API.G_EXC_ERROR;
     ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR
     THEN
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
     END IF;

     x_receivable_application_id := l_net_rec_app_id;
     x_applied_rec_app_id := l_open_net_rec_app_id;

       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Apply_Open_Receipt: ' || 'committing');
            END IF;
              Commit;
        END IF;
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Apply_Open_Receipt()- ');
        END IF;
EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply_Open_Receipt: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Apply_Open_Receipt: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Apply_Open_Receipt_PVT;
                x_return_status := FND_API.G_RET_STS_ERROR ;

               -- Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply_Open_Receipt: ' || SQLERRM, G_MSG_ERROR);
                END IF;
                ROLLBACK TO Apply_Open_Receipt_PVT;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

               --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN

                      ROLLBACK TO Apply_Open_Receipt_PVT;

                      --If only one error message on the stack,
                      --retrive it

                      x_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','APPLY_Open_Receipt : '||SQLERRM);
                      FND_MSG_PUB.Add;

                      FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                                 p_count  =>  x_msg_count,
                                                 p_data   => x_msg_data
                                                );

                      RETURN;

                ELSE
                      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','APPLY_Open_Receipt : '||SQLERRM);
                      FND_MSG_PUB.Add;
                END IF;

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Apply_Open_Receipt: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Apply_Open_Receipt: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Apply_Open_Receipt_PVT;

                IF      FND_MSG_PUB.Check_Msg_Level
                THEN
                FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME,
                                        l_api_name
                                       );
                END IF;

             --   Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

END Apply_Open_Receipt;

PROCEDURE Unapply_Open_Receipt(
    -- Standard API parameters.
      p_api_version      IN  NUMBER,
      p_init_msg_list    IN  VARCHAR2,
      p_commit           IN  VARCHAR2,
      p_validation_level IN  NUMBER,
      x_return_status    OUT NOCOPY VARCHAR2 ,
      x_msg_count        OUT NOCOPY NUMBER ,
      x_msg_data         OUT NOCOPY VARCHAR2 ,
      p_receivable_application_id   IN  ar_receivable_applications.receivable_application_id%TYPE,
      p_reversal_gl_date IN ar_receivable_applications.reversal_gl_date%TYPE ,
      p_called_from                  IN VARCHAR2,
      p_org_id             IN NUMBER  DEFAULT NULL
      ) IS

l_api_name       CONSTANT VARCHAR2(20) := 'Unapply_Open_Receipt';
l_api_version    CONSTANT NUMBER       := 1.0;
l_receivable_application_id     NUMBER;
l_applied_rec_app_id            NUMBER;
l_applied_cash_receipt_id       NUMBER;
l_amount_applied                NUMBER;
l_reversal_gl_date              DATE;
l_act1_msg_count          NUMBER;
l_act2_msg_count          NUMBER;
l_def_return_status             VARCHAR2(1);
l_val_return_status             VARCHAR2(1);
l_org_return_status VARCHAR2(1);
l_org_id                           NUMBER;

BEGIN
       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

        SAVEPOINT Unapply_Open_Receipt_PVT;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                              p_current_version_number => l_api_version,
                              p_caller_version_number  => p_api_version,
                              p_api_name               => l_api_name,
                              p_pkg_name               => G_PKG_NAME
                              )
        THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*--------------------------------------------------------------+
        |   Initialize message list if p_init_msg_list is set to TRUE  |
        +--------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
          THEN
              FND_MSG_PUB.initialize;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Unapply_Open_Receipt: ' || 'ar_receipt_api.Unapply_Open_Receipt()+ ');
        END IF;
       /*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        l_def_return_status := FND_API.G_RET_STS_SUCCESS;
        l_val_return_status := FND_API.G_RET_STS_SUCCESS;
        x_return_status := FND_API.G_RET_STS_SUCCESS;



/* SSA change */
       l_org_id            := p_org_id;
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;
       ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);
 IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
 ELSE
        /*-------------------------------------------------+
         | Initialize the profile option package variables |
         +-------------------------------------------------*/

           initialize_profile_globals;



       /*---------------------------------------------+
        |   ========== Start of API Body ==========   |
        +---------------------------------------------*/

        --Assign IN parameter values to local variables
        --which are also used as assignment targets.

         l_receivable_application_id  := p_receivable_application_id;
         l_reversal_gl_date := trunc(p_reversal_gl_date);

          /*---------------------+
           |                     |
           |    DEFAULTING       |
           |                     |
           +---------------------*/

         ar_receipt_lib_pvt.default_unapp_open_receipt(
              p_receivable_application_id  =>  l_receivable_application_id
            , x_applied_cash_receipt_id => l_applied_cash_receipt_id
            , x_applied_rec_app_id  => l_applied_rec_app_id
            , x_amount_applied      => l_amount_applied
            , x_return_status => l_def_return_status);

          /*---------------------+
           |                     |
           |    VALIDATION       |
           |                     |
           +---------------------*/

         ar_receipt_val_pvt.validate_unapp_open_receipt(
              p_applied_cash_receipt_id => l_applied_cash_receipt_id
            , p_amount_applied  => l_amount_applied
            , p_return_status   => l_val_return_status);

			/*Bug 16789203 Adding validation to prevent the reversal of the
         Receipt for Receipts where data has not been converted   */
		arp_util.debug('Before calling arp_acct_event_pkg.upgrade_status_per_doc inside Unapply_Open_Receipt ');
	Declare
        x_upgrade_status    VARCHAR2(100);
		x_return_status1		VARCHAR2(100);
		x_msg_count1		    NUMBER;
		x_msg_data1		    VARCHAR2(2000);
        l_msg_data1           VARCHAR2(2000);
    Begin

	arp_acct_event_pkg.upgrade_status_per_doc
		 (p_init_msg_list     => 'F', --BUG 20625046
		  p_entity_code       => 'RECEIPTS',
		  p_source_int_id     => l_applied_cash_receipt_id,
		  x_upgrade_status    => x_upgrade_status,
		  x_return_status    => x_return_status1,
		  x_msg_count         => x_msg_count1,
		  x_msg_data          => x_msg_data1
		  );
		IF x_upgrade_status = 'N' THEN
			  arp_util.debug('Data1 has not been converted, Can not REVERSED');
			  FND_MESSAGE.SET_NAME('AR','AR_NOT_FULLY_UPG_DOC');
			  FND_MSG_PUB.ADD;
			  l_val_return_status:= FND_API.G_RET_STS_ERROR;
		  END IF;

		 IF x_return_status1 <> 'S' THEN
			  IF x_msg_count1 > 1 THEN
				  FOR i IN 1..x_msg_count1 LOOP
				  l_msg_data1 := SUBSTRB(l_msg_data1 ||FND_MSG_PUB.Get(-2)||'-',1,2000);
				  END LOOP;
				  ELSE
				  l_msg_data1 := x_msg_data1;
			  END IF;
		  arp_util.debug('Exception1 in arp_acct_event_pkg.upgrade_status_per_doc, x_return_status is U');
		  FND_MESSAGE.SET_NAME('AR','GENERIC_MESSAGE');
		  fnd_message.set_token('GENERIC_MESSAGE',l_msg_data1||'->'||SQLERRM);
		  FND_MSG_PUB.Add;
		  l_val_return_status:= FND_API.G_RET_STS_ERROR;
		 END IF;


    End;	--Bug 16789203







          /*------------------------------------------------+
           |                                                |
           |    Unapply netting activity on both receipts   |
           |                                                |
           +------------------------------------------------*/

         IF (l_def_return_status = FND_API.G_RET_STS_SUCCESS AND
             l_val_return_status = FND_API.G_RET_STS_SUCCESS)
         THEN
           Activity_Unapplication(
              p_api_version               =>  1.0,
              p_validation_level          =>  FND_API.G_VALID_LEVEL_FULL,
              x_return_status             =>  x_return_status ,
              x_msg_count                 =>  l_act1_msg_count,
              x_msg_data                  =>  x_msg_data ,
              p_receivable_application_id =>  l_receivable_application_id,
              p_reversal_gl_date          =>  l_reversal_gl_date,
              p_org_id                    =>  p_org_id,
              p_called_from               =>  p_called_from);

           IF x_return_status = FND_API.G_RET_STS_SUCCESS
           THEN
             Activity_Unapplication(
              p_api_version               =>  1.0,
              p_validation_level          =>  FND_API.G_VALID_LEVEL_FULL,
              x_return_status             =>  x_return_status ,
              x_msg_count                 =>  l_act2_msg_count,
              x_msg_data                  =>  x_msg_data ,
              p_receivable_application_id =>  l_applied_rec_app_id,
              p_reversal_gl_date          =>  l_reversal_gl_date,
              p_org_id                    =>  p_org_id,
              p_called_from               =>  'RAPI');
           END IF;
         END IF;


     x_msg_count := l_act1_msg_count + l_act2_msg_count;
END IF;

       /*---------------------------------------------------+
        |   Raise exception if return status is not success |
        +---------------------------------------------------*/

     IF (l_def_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
        x_return_status := l_def_return_status;
     ELSIF (l_val_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
        x_return_status := l_val_return_status;
     END IF;

     IF x_return_status = FND_API.G_RET_STS_ERROR
     THEN
       RAISE FND_API.G_EXC_ERROR;
     ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR
     THEN
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
     END IF;

       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Unapply_Open_Receipt: ' || 'committing');
            END IF;
              Commit;
        END IF;
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Unapply_Open_Receipt()- ');
        END IF;
EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Unapply_Open_Receipt: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Unapply_Open_Receipt: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Unapply_Open_Receipt_PVT;
                x_return_status := FND_API.G_RET_STS_ERROR ;

               -- Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Unapply_Open_Receipt: ' || SQLERRM, G_MSG_ERROR);
                END IF;
                ROLLBACK TO Unapply_Open_Receipt_PVT;
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

               --  Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN

                      ROLLBACK TO Unapply_Open_Receipt_PVT;

                      --If only one error message on the stack,
                      --retrive it

                      x_return_status := FND_API.G_RET_STS_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','UnaPPLY_Open_Receipt : '||SQLERRM);
                      FND_MSG_PUB.Add;

                      FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                                 p_count  =>  x_msg_count,
                                                 p_data   => x_msg_data
                                                );

                      RETURN;

                ELSE
                      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                      FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
                      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','UnaPPLY_Open_Receipt : '||SQLERRM);
                      FND_MSG_PUB.Add;
                END IF;

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Unapply_Open_Receipt: ' || SQLCODE, G_MSG_ERROR);
                   arp_util.debug('Apply_Open_Receipt: ' || SQLERRM, G_MSG_ERROR);
                END IF;

                ROLLBACK TO Unapply_Open_Receipt_PVT;

                IF      FND_MSG_PUB.Check_Msg_Level
                THEN
                FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME,
                                        l_api_name
                                       );
                END IF;

             --   Display_Parameters;

                FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                           p_count       =>      x_msg_count,
                                           p_data        =>      x_msg_data
                                         );

END Unapply_Open_Receipt;


/*=======================================================================
 | INTERNAL Procedure Reverse_Remittances_In_Err
 |
 | DESCRIPTION
 |      This Procedure is for internal use for setting status
 |      of receipts from remittance to conformation under certain
 |      condition evolving internally
 |
 |      Parematers to be passed for this rutine are mentioned below.
 |      -------------------------------------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |  p_cash_receipts_id IN  AR_RECEIPT_API_PUB.CR_ID
 |  p_called_from      IN  VARCHAR2
 |
 | RETURNS
 |      Nothing
 |
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
 | 21-JAN-2009           Naneja         Created
 |
 |
 *=======================================================================*/
PROCEDURE Reverse_Remittances_in_err(
           -- Standard API parameters.
                 p_api_version      IN  NUMBER,
                 p_cash_receipts_id IN  CR_ID_TABLE,
                 p_called_from      IN  VARCHAR2 DEFAULT NULL,
                 p_commit           IN  VARCHAR2 := FND_API.G_FALSE,
                 x_return_status    OUT NOCOPY VARCHAR2,
                 x_msg_count        OUT NOCOPY NUMBER,
                 x_msg_data         OUT NOCOPY VARCHAR2
                 ) IS
MAX_LIMIT               NUMBER := 1000;

TYPE CRH_UPD_TYPE IS RECORD
(
cash_receipt_history_id         DBMS_SQL.NUMBER_TABLE,
cash_receipt_id                 DBMS_SQL.NUMBER_TABLE,
reversal_gl_date                DBMS_SQL.DATE_TABLE,
gl_date                         DBMS_SQL.DATE_TABLE,
reversal_cash_receipt_hist_id   DBMS_SQL.NUMBER_TABLE,
batch_id			DBMS_SQL.NUMBER_TABLE,
amount				DBMS_SQL.NUMBER_TABLE,
cc_error_code			DBMS_SQL.VARCHAR2_TABLE,
cc_error_text			DBMS_SQL.VARCHAR2_TABLE,
cc_instrtype			DBMS_SQL.VARCHAR2_TABLE,
rec_status                      DBMS_SQL.VARCHAR2_TABLE
);

l_api_name       CONSTANT VARCHAR2(30) := 'Reverse_Remittances_in_err';
l_api_version    CONSTANT NUMBER       := 1.0;


l_crh_upd       CRH_UPD_TYPE;

l_error_message        VARCHAR2(128);

l_defaulting_rule_used VARCHAR2(100);
l_default_gl_date      DATE;
l_entered_date         DATE;

l_last_updated_by         NUMBER;
l_created_by              NUMBER;
l_last_update_login       NUMBER;
l_program_application_id  NUMBER;
l_program_id              NUMBER;
l_request_id              ar_cash_receipt_history.request_id%TYPE;
l_request_id_bulk         ar_cash_receipt_history.request_id%TYPE;
l_request_id_set          VARCHAR2(1);

l_xla_ev_rec             ARP_XLA_EVENTS.XLA_EVENTS_TYPE;

l_last_fetch BOOLEAN := FALSE;

CURSOR crh_upd_rec is
select  cash_receipt_history_id,
        cash_receipt_id,
        reversal_gl_date,
        gl_date,
	ar_cash_receipt_history_s.nextval,
	batch_id,
	amount,
	cc_error_code,
	cc_error_text,
	cc_instrtype,
        'VALID'
from ar_rr_crh_gt;

CURSOR cr_exp_rec (p_req_id in number) is
select crhgt.cash_receipt_id
from ar_rr_crh_gt crhgt
where crhgt.cash_receipt_id
 not in
(
   select crh.cash_receipt_id
   from ar_cash_receipt_history crh
   where crh.cash_receipt_id= crhgt.cash_receipt_id
   and crh.status = 'CONFIRMED'
   and crh.current_record_flag='Y'
   and crh.request_id =p_req_id
);
BEGIN
 IF PG_DEBUG in ('Y', 'C') THEN
   arp_util.debug('Reverse_Remittances_in_err ()+' );
 END IF;

  x_return_status := FND_API.G_RET_STS_SUCCESS;

--        SAVEPOINT Reverse_Rem_PVT;

        IF NOT FND_API.Compatible_API_Call(
                              p_current_version_number => l_api_version,
                              p_caller_version_number  => p_api_version,
                              p_api_name               => l_api_name,
                              p_pkg_name               => G_PKG_NAME
                              )
        THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;


 IF PG_DEBUG in ('Y', 'C') THEN
   arp_util.debug(' Delete data in GT table' );
 END IF;

  /* initiating global table for fresh call*/

--     IF  NOT FND_API.To_Boolean( p_commit ) THEN
        delete from ar_rr_crh_gt;
--     END IF;

 IF PG_DEBUG in ('Y', 'C') THEN
   arp_util.debug(' Caching variables for setting who columns' );
 END IF;

  /*Caching variables for setting who columns*/
  l_request_id_set := 'Y';
  l_last_updated_by := arp_standard.profile.last_update_login ;
  l_created_by := arp_standard.profile.user_id ;
  l_last_update_login := arp_standard.profile.last_update_login ;
  l_program_application_id := arp_standard.application_id ;
  l_program_id := arp_standard.profile.program_id;
  l_request_id := fnd_global.conc_request_id;

  IF l_request_id = -1 THEN
     l_request_id_set := 'N';
     l_request_id_bulk := -999;
  ELSE
     l_request_id_bulk := l_request_id;
  END IF;
  IF  nvl(p_called_from,'X') <> 'SUBMIT_OFFLINE' THEN

     FND_MESSAGE.SET_NAME('AR', 'GENERIC_MESSAGE');
     FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','API called with wrong parameters. Call is not internal');
     FND_MSG_PUB.Add;
     x_return_status := FND_API.G_RET_STS_ERROR;
     return;
  END IF;

 IF PG_DEBUG in ('Y', 'C') THEN
   arp_util.debug(' Insert CRH data of passsed receipts into GT table' );
 END IF;

  /* Collecting CRH data of passsed receipts*/
  /*Insert into ar_rr_crh_gt select * from ar_cash_receipt_history*/
  FORALL i IN p_cash_receipts_id.cash_receipt_id.first..p_cash_receipts_id.cash_receipt_id.last
INSERT INTO AR_RR_CRH_GT
(
CASH_RECEIPT_HISTORY_ID,
CASH_RECEIPT_ID,
STATUS,
TRX_DATE,
AMOUNT,
FIRST_POSTED_RECORD_FLAG,
POSTABLE_FLAG,
FACTOR_FLAG,
GL_DATE,
CURRENT_RECORD_FLAG,
BATCH_ID,
ACCOUNT_CODE_COMBINATION_ID,
REVERSAL_GL_DATE,
REVERSAL_CASH_RECEIPT_HIST_ID,
FACTOR_DISCOUNT_AMOUNT,
BANK_CHARGE_ACCOUNT_CCID,
POSTING_CONTROL_ID,
REVERSAL_POSTING_CONTROL_ID,
GL_POSTED_DATE,
REVERSAL_GL_POSTED_DATE,
LAST_UPDATE_LOGIN,
ACCTD_AMOUNT,
ACCTD_FACTOR_DISCOUNT_AMOUNT,
CREATED_BY,
CREATION_DATE,
EXCHANGE_DATE,
EXCHANGE_RATE,
EXCHANGE_RATE_TYPE,
LAST_UPDATE_DATE,
PROGRAM_APPLICATION_ID,
PROGRAM_ID,
PROGRAM_UPDATE_DATE,
REQUEST_ID,
LAST_UPDATED_BY,
PRV_STAT_CASH_RECEIPT_HIST_ID,
CREATED_FROM,
REVERSAL_CREATED_FROM,
ATTRIBUTE1,
ATTRIBUTE2,
ATTRIBUTE3,
ATTRIBUTE4,
ATTRIBUTE5,
ATTRIBUTE6,
ATTRIBUTE7,
ATTRIBUTE8,
ATTRIBUTE9,
ATTRIBUTE10,
ATTRIBUTE11,
ATTRIBUTE12,
ATTRIBUTE13,
ATTRIBUTE14,
ATTRIBUTE15,
ATTRIBUTE_CATEGORY,
ORG_ID,
EVENT_ID,
CC_ERROR_CODE,
CC_ERROR_TEXT,
CC_INSTRTYPE
)
select
CASH_RECEIPT_HISTORY_ID,
CASH_RECEIPT_ID,
STATUS,
TRX_DATE,
AMOUNT,
FIRST_POSTED_RECORD_FLAG,
POSTABLE_FLAG,
FACTOR_FLAG,
GL_DATE,
CURRENT_RECORD_FLAG,
BATCH_ID,
ACCOUNT_CODE_COMBINATION_ID,
REVERSAL_GL_DATE,
REVERSAL_CASH_RECEIPT_HIST_ID,
FACTOR_DISCOUNT_AMOUNT,
BANK_CHARGE_ACCOUNT_CCID,
POSTING_CONTROL_ID,
REVERSAL_POSTING_CONTROL_ID,
GL_POSTED_DATE,
REVERSAL_GL_POSTED_DATE,
LAST_UPDATE_LOGIN,
ACCTD_AMOUNT,
ACCTD_FACTOR_DISCOUNT_AMOUNT,
CREATED_BY,
CREATION_DATE,
EXCHANGE_DATE,
EXCHANGE_RATE,
EXCHANGE_RATE_TYPE,
LAST_UPDATE_DATE,
PROGRAM_APPLICATION_ID,
PROGRAM_ID,
PROGRAM_UPDATE_DATE,
REQUEST_ID,
LAST_UPDATED_BY,
PRV_STAT_CASH_RECEIPT_HIST_ID,
CREATED_FROM,
REVERSAL_CREATED_FROM,
ATTRIBUTE1,
ATTRIBUTE2,
ATTRIBUTE3,
ATTRIBUTE4,
ATTRIBUTE5,
ATTRIBUTE6,
ATTRIBUTE7,
ATTRIBUTE8,
ATTRIBUTE9,
ATTRIBUTE10,
ATTRIBUTE11,
ATTRIBUTE12,
ATTRIBUTE13,
ATTRIBUTE14,
ATTRIBUTE15,
ATTRIBUTE_CATEGORY,
ORG_ID,
EVENT_ID,
p_cash_receipts_id.CC_ERROR_CODE(i),
p_cash_receipts_id.CC_ERROR_TEXT(i),
p_cash_receipts_id.CC_INSTRTYPE(i)
FROM ar_Cash_receipt_history
  where cash_receipt_id=p_cash_receipts_id.cash_receipt_id(i)
  and   current_record_flag = 'Y'
  and   status = 'REMITTED'
  and   NOT EXISTS (SELECT * FROM AR_RR_CRH_GT WHERE cash_receipt_id = p_cash_receipts_id.cash_receipt_id(i)); -- Bug 13549918


 IF PG_DEBUG in ('Y', 'C') THEN
   arp_util.debug(' Reversing the receipts in GT table start ' );
 END IF;

/* Caching data in structure for processing*/
  OPEN crh_upd_rec;
  LOOP
  FETCH crh_upd_rec bulk collect into l_crh_upd LIMIT MAX_LIMIT;

       IF crh_upd_rec%NOTFOUND THEN
          l_last_fetch := TRUE;
       END IF;

       IF (l_crh_upd.cash_receipt_history_id.COUNT = 0) AND (l_last_fetch) THEN
         IF PG_DEBUG in ('Y', 'C') THEN
            arp_standard.debug('Records for update: ' || 'COUNT = 0 and LAST FETCH ');
         END IF;
         EXIT;
       END IF;
/*
  IF l_crh_upd.cash_receipt_history_id.count = 0 THEN
    EXIT;
  END IF;
  */

   IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug(' Before savepoint creation ' );
   END IF;

  SAVEPOINT Reverse_Rem_PVT;
  l_entered_date := sysdate;

   IF PG_DEBUG in ('Y', 'C') THEN
   arp_util.debug(' Validate CRH gl_date ' );
 END IF;

  /*Setting gl date for new CRH record and reversal gl date for old crh record*/
  FOR i in l_crh_upd.cash_receipt_history_id.first..l_crh_upd.cash_receipt_history_id.last
  LOOP

     l_entered_date := l_crh_upd.gl_date(i);

     IF (arp_util.validate_and_default_gl_date(
                l_entered_date,
                NULL,
                l_crh_upd.gl_date(i),
                NULL,
                NULL,
                l_entered_date,
                NULL,
                NULL,
                'N',
                NULL,
                arp_global.set_of_books_id,
                222,
                l_default_gl_date,
                l_defaulting_rule_used,
                l_error_message) = TRUE)
     THEN
       l_crh_upd.reversal_gl_date(i) := l_default_gl_date;
     ELSE
/*
      FND_MESSAGE.SET_NAME('AR', 'GENERIC_MESSAGE');
      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT', l_error_message);
      FND_MSG_PUB.Add;
      x_return_status := FND_API.G_RET_STS_ERROR;
      EXIT;
*/
      l_crh_upd.rec_status(i) := 'INVALID_GL_DATE';
     END IF;
  END LOOP;


  IF PG_DEBUG in ('Y', 'C') THEN
        arp_util.debug('After gl date validation');
  END IF;

  FORALL i in  l_crh_upd.cash_receipt_history_id.first..l_crh_upd.cash_receipt_history_id.last
  UPDATE ar_cash_receipts SET
  CC_ERROR_FLAG ='Y',
  CC_ERROR_CODE = l_crh_upd.cc_error_code(i),
  CC_ERROR_TEXT = l_crh_upd.cc_error_text(i),
  LAST_UPDATE_DATE = sysdate,
  LAST_UPDATE_LOGIN = l_last_update_login,
  LAST_UPDATED_BY    = l_last_updated_by
  WHERE cash_receipt_id = l_crh_upd.cash_receipt_id(i)
  AND   l_crh_upd.cc_instrtype(i) in ('CREDITCARD','BANKACCOUNT')
  AND l_crh_upd.rec_status(i) ='VALID';

  IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('After CR Updation');
  END IF;

  /*Update existing CRH record of remittance*/
  FORALL i in l_crh_upd.cash_receipt_history_id.first..l_crh_upd.cash_receipt_history_id.last
  update ar_cash_receipt_history set
    reversal_cash_receipt_hist_id = l_crh_upd.reversal_cash_receipt_hist_id(i),
                reversal_gl_date = l_crh_upd.reversal_gl_date(i),
                reversal_created_from = 'ARREVREM',
                current_record_flag = NULL,
                        last_update_date              = sysdate,
                        last_updated_by               = l_last_updated_by,
                        last_update_login             = l_last_update_login
                  WHERE cash_receipt_history_id = l_crh_upd.cash_receipt_history_id(i)
                  AND current_record_flag = 'Y'
                  AND status = 'REMITTED'
                  AND l_crh_upd.rec_status(i) = 'VALID';

  IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('After updating existing Remittance records');
  END IF;


  /*Inserting new CRH record for CONFIRM State*/
  FORALL i in l_crh_upd.cash_receipt_history_id.first..l_crh_upd.cash_receipt_history_id.last
  Insert into ar_cash_receipt_history
  (
    CASH_RECEIPT_HISTORY_ID,
    CASH_RECEIPT_ID,
    STATUS,
    TRX_DATE,
    AMOUNT,
    FIRST_POSTED_RECORD_FLAG,
    POSTABLE_FLAG,
    FACTOR_FLAG,
    GL_DATE,
    CURRENT_RECORD_FLAG,
    BATCH_ID,
    ACCOUNT_CODE_COMBINATION_ID,
    REVERSAL_GL_DATE,
    REVERSAL_CASH_RECEIPT_HIST_ID,
    FACTOR_DISCOUNT_AMOUNT,
    BANK_CHARGE_ACCOUNT_CCID,
    POSTING_CONTROL_ID,
    REVERSAL_POSTING_CONTROL_ID,
    GL_POSTED_DATE,
    REVERSAL_GL_POSTED_DATE,
    LAST_UPDATE_LOGIN,
    ACCTD_AMOUNT,
    ACCTD_FACTOR_DISCOUNT_AMOUNT,
    CREATED_BY,
    CREATION_DATE,
    EXCHANGE_DATE,
    EXCHANGE_RATE,
    EXCHANGE_RATE_TYPE,
    LAST_UPDATE_DATE,
    PROGRAM_APPLICATION_ID,
    PROGRAM_ID,
    PROGRAM_UPDATE_DATE,
    REQUEST_ID,
    LAST_UPDATED_BY,
    PRV_STAT_CASH_RECEIPT_HIST_ID,
    CREATED_FROM,
    REVERSAL_CREATED_FROM,
    ATTRIBUTE1,
    ATTRIBUTE2,
    ATTRIBUTE3,
    ATTRIBUTE4,
    ATTRIBUTE5,
    ATTRIBUTE6,
    ATTRIBUTE7,
    ATTRIBUTE8,
    ATTRIBUTE9,
    ATTRIBUTE10,
    ATTRIBUTE11,
    ATTRIBUTE12,
    ATTRIBUTE13,
    ATTRIBUTE14,
    ATTRIBUTE15,
    ATTRIBUTE_CATEGORY,
    ORG_ID,
    EVENT_ID
   )
   SELECT
    l_crh_upd.reversal_cash_receipt_hist_id(i),
    CASH_RECEIPT_ID,
    STATUS,
    TRX_DATE,
    AMOUNT,
    'N',
    POSTABLE_FLAG,
    FACTOR_FLAG,
    l_crh_upd.reversal_gl_date(i),
    'Y',
    NULL,
    ACCOUNT_CODE_COMBINATION_ID,
    NULL,
    NULL,
    FACTOR_DISCOUNT_AMOUNT,
    BANK_CHARGE_ACCOUNT_CCID,
    -3,
    NULL,
    NULL,
    NULL,
    l_last_update_login,
    ACCTD_AMOUNT,
    ACCTD_FACTOR_DISCOUNT_AMOUNT,
    l_created_by,
    sysdate,
    EXCHANGE_DATE,
    EXCHANGE_RATE,
    EXCHANGE_RATE_TYPE,
    sysdate,
    l_PROGRAM_APPLICATION_ID,
    l_PROGRAM_ID,
    sysdate,
    l_request_id_bulk,
    l_last_updated_by,
    l_crh_upd.CASH_RECEIPT_HISTORY_ID(i),
    'ARREVREM',
    NULL,
    ATTRIBUTE1,
    ATTRIBUTE2,
    ATTRIBUTE3,
    ATTRIBUTE4,
    ATTRIBUTE5,
    ATTRIBUTE6,
    ATTRIBUTE7,
    ATTRIBUTE8,
    ATTRIBUTE9,
    ATTRIBUTE10,
    ATTRIBUTE11,
    ATTRIBUTE12,
    ATTRIBUTE13,
    ATTRIBUTE14,
    ATTRIBUTE15,
    ATTRIBUTE_CATEGORY,
    ORG_ID,
    NULL
  FROM AR_CASH_RECEIPT_HISTORY
  WHERE reversal_cash_receipt_hist_id=l_crh_upd.cash_receipt_history_id(i)
  AND l_crh_upd.rec_status(i)='VALID';

  IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('Inserted new CRH record for new status CONFIRM');
  END IF;


   /*Creating events for newly created CRH records*/
   arp_xla_events.create_events_req(p_request_id   => l_request_id_bulk,
                               p_doc_table    =>'CRH',
                               p_mode         => 'O',
                               p_call         => 'B');


   IF l_request_id_bulk = -999 THEN

      FORALL i in l_crh_upd.cash_receipt_history_id.first..l_crh_upd.cash_receipt_history_id.last
      update ar_cash_receipt_history set
          request_id = l_request_id
                  WHERE cash_receipt_history_id = l_crh_upd.reversal_cash_receipt_hist_id(i)
                  AND current_record_flag = 'Y'
                  AND status = 'CONFIRMED'
                  AND l_crh_upd.rec_status(i)='VALID'
		  AND request_id = l_request_id_bulk;
   END IF;


      FORALL i in l_crh_upd.cash_receipt_history_id.first..l_crh_upd.cash_receipt_history_id.last
      update ar_batches set
	  control_count = control_count - 1,
	  control_amount= control_amount - l_crh_upd.amount(i)
                  WHERE batch_id = l_crh_upd.batch_id(i)
                  AND l_crh_upd.rec_status(i)='VALID';

/*
   FOR i in l_crh_upd.first..l_crh_upd.last
   LOOP
      IF l_crh_upd(i).rec_status='VALID' THEN
          l_xla_ev_rec.xla_from_doc_id := to_number(l_crh_upd(i).cash_receipt_id);
          l_xla_ev_rec.xla_to_doc_id := to_number(l_crh_upd(i).cash_receipt_id);
          l_xla_ev_rec.xla_doc_table := 'CRH';
          l_xla_ev_rec.xla_mode := 'O';
          l_xla_ev_rec.xla_call := 'B';

                IF PG_DEBUG in ('Y', 'C') THEN
                        arp_util.debug('xla_from_doc_id= '|| l_crh_upd(i).cash_receipt_id);
                        arp_util.debug('xla_to_doc_id= '|| l_crh_upd(i).cash_receipt_id);
                        arp_util.debug('xla_doc_table= '|| 'CRH');
                        arp_util.debug('xla_mode= '|| 'O');
                        arp_util.debug('xla_call= '|| 'B');
                END IF;

          arp_xla_events.create_events(l_xla_ev_rec);


                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('RETURN STATUS FROM XLA () '|| to_char(SQLCODE));
                END IF;

      END IF;
  END LOOP;
*/

  IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('Generated events for CRH');
  END IF;


      /*Creating distributions as follow
        Dr.     Conformation
             Cr.     Remittance

        Reversing existing distribution when receipt was remitted
      */
      FORALL i in l_crh_upd.cash_receipt_history_id.first..l_crh_upd.cash_receipt_history_id.last
      INSERT INTO  ar_distributions (
                   line_id,
                   source_id,
                   source_table,
                   source_type,
                   source_type_secondary,
                   code_combination_id,
                   amount_dr,
                   amount_cr,
                   acctd_amount_dr,
                   acctd_amount_cr,
                   created_by,
                   creation_date,
                   last_updated_by,
                   last_update_date,
                   last_update_login,
                   source_id_secondary,
                   source_table_secondary,
                   currency_code        ,
                   currency_conversion_rate,
                   currency_conversion_type,
                   currency_conversion_date,
                   third_party_id,
                   third_party_sub_id,
                   tax_code_id,
                   location_segment_id,
                   taxable_entered_dr,
                   taxable_entered_cr,
                   taxable_accounted_dr,
                   taxable_accounted_cr,
                   tax_link_id,
                   reversed_source_id,
                   tax_group_code_id,
                   org_id,
                   ref_customer_trx_line_id,
                   ref_cust_trx_line_gl_dist_id,
                   ref_line_id,
                   from_amount_dr,
                   from_amount_cr,
                   from_acctd_amount_dr,
                   from_acctd_amount_cr,
                   ref_account_class,
                   activity_bucket,
                   ref_dist_ccid,
                   ref_mf_dist_flag
                 )
       select ar_distributions_s.nextval,
              l_crh_upd.reversal_Cash_receipt_hist_id(i),
              'CRH',
              ard.source_type,
              ard.source_type_secondary,
              ard.code_combination_id,
              decode(sign(nvl(ard.amount_dr,0)- nvl(ard.amount_cr,0)),-1,ard.amount_cr,NULL),
              decode(sign(nvl(ard.amount_cr,0)- nvl(ard.amount_dr,0)),-1,ard.amount_dr,NULL),
              decode(sign(nvl(ard.acctd_amount_dr,0)- nvl(ard.acctd_amount_cr,0)),-1,ard.acctd_amount_cr,NULL),
              decode(sign(nvl(ard.acctd_amount_cr,0)- nvl(ard.acctd_amount_dr,0)),-1,ard.acctd_amount_dr,NULL),
              arp_standard.profile.user_id,
              SYSDATE,
              arp_standard.profile.user_id,
              SYSDATE,
              arp_standard.profile.last_update_login,
              ard.source_id_secondary,
              ard.source_table_secondary,
              ard.currency_code        ,
              ard.currency_conversion_rate,
              ard.currency_conversion_type,
              ard.currency_conversion_date,
              ard.third_party_id,
              ard.third_party_sub_id,
              ard.tax_code_id,
              ard.location_segment_id,
              ard.taxable_entered_dr,
              ard.taxable_entered_cr,
              ard.taxable_accounted_dr,
              ard.taxable_accounted_cr,
              ard.tax_link_id,
              ard.reversed_source_id,
              ard.tax_group_code_id,
              ard.org_id,
              ard.ref_customer_trx_line_id,
              ard.ref_cust_trx_line_gl_dist_id,
              ard.ref_line_id,
              ard.from_amount_dr,
              ard.from_amount_cr,
              ard.from_acctd_amount_dr,
              ard.from_acctd_amount_cr,
              ard.ref_account_class,
              ard.activity_bucket,
              ard.ref_dist_ccid,
              ard.ref_mf_dist_flag
       FROM   ar_distributions ard,
              ar_Cash_receipt_history crh
       WHERE  ard.source_id=crh.cash_receipt_history_id
       and    ard.source_table = 'CRH'
       and    cash_receipt_history_id=l_crh_upd.cash_receipt_history_id(i)
       AND l_crh_upd.rec_status(i)='VALID';

  IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug('Created Distributions');
  END IF;



   IF l_crh_upd.cash_receipt_history_id.count > 0 THEN
   FOR i in l_crh_upd.cash_receipt_history_id.first..l_crh_upd.cash_receipt_history_id.last
   LOOP
         IF l_crh_upd.rec_status(i) <> 'VALID' THEN
                arp_util.debug('Could Not Process Receipt with receipt id -' || l_crh_upd.cash_receipt_id(i) ||
                                                                             ' Its getting into status- ' || l_crh_upd.rec_status(i) );
         END IF;
  END LOOP;
  END IF;

  IF FND_API.To_Boolean( p_commit ) THEN
     COMMIT;
  END IF;

  END LOOP;

  close crh_upd_rec;

  IF PG_DEBUG in ('Y', 'C') THEN
    arp_util.debug('Reverse_Remittances_in_err-' );
  END IF;

EXCEPTION
WHEN OTHERS THEN
      IF PG_DEBUG in ('Y', 'C') THEN
        IF l_request_id <> -1 THEN

          FOR i in cr_exp_rec(l_request_id)
          LOOP
            arp_util.debug('Cash Receipts not processed:  ' || i.cash_receipt_id );
          END LOOP;
        END IF;
      END IF;

      ROLLBACK TO Reverse_Rem_PVT;
      l_error_message := 'Unexpected Error: ' || substr(1,100,sqlerrm);
      FND_MESSAGE.SET_NAME('AR', 'GENERIC_MESSAGE');
      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT', l_error_message);
      FND_MSG_PUB.Add;
      x_return_status := FND_API.G_RET_STS_ERROR;
      x_msg_data :=   substr(1,2000,sqlerrm);
END Reverse_Remittances_in_err;



PROCEDURE process_events( p_gt_id       NUMBER,
			  p_request_id  NUMBER,
			  p_org_id      NUMBER )  IS

  l_xla_ev_rec             arp_xla_events.xla_events_type;
  l_from_doc_id            NUMBER;
  l_to_doc_id              NUMBER;
  l_from_ra_doc_id         NUMBER;
  l_to_ra_doc_id           NUMBER;

  BEGIN

    IF PG_DEBUG in ('Y', 'C') THEN
      arp_standard.debug('process_events()+');
    END IF;

    update ar_cash_receipts
    SET last_update_date       = sysdate,
	request_id             = p_request_id
    WHERE cash_receipt_id in
     ( select cash_receipt_id
       from ar_create_receipts_gt
       where gt_id = p_gt_id
       and    request_id = p_request_id
       and return_error_status = 'S'
       and org_id = p_org_id );


    IF PG_DEBUG in ('Y','C') THEN
      arp_standard.debug ( 'NO of Receipts updated =  '|| to_char(SQL%ROWCOUNT));
    END IF;

    update ar_cash_receipt_history SET
    last_update_date = sysdate,
    request_id = p_request_id
    WHERE cash_receipt_id in
     ( select cash_receipt_id
       from ar_create_receipts_gt
       where  gt_id = p_gt_id
       and    request_id = p_request_id
       and    return_error_status = 'S'
       and    org_id = p_org_id );

    IF PG_DEBUG in ('Y','C') THEN
      arp_standard.debug ( 'NO of Receipts updated CRH =  '|| to_char(SQL%ROWCOUNT));
    END IF;

    update AR_payment_schedules  SET
    last_update_date = sysdate,
    request_id = p_request_id
    WHERE cash_receipt_id in
     ( select cash_receipt_id
       from ar_create_receipts_gt
       where  gt_id = p_gt_id
       and    request_id = p_request_id
       and    return_error_status = 'S'
       and    org_id = p_org_id );

    IF PG_DEBUG in ('Y','C') THEN
      arp_standard.debug ( 'NO of Receipts updated  PS =  '|| to_char(SQL%ROWCOUNT));
    END IF;

    update ar_receivable_applications SET
    last_update_date = sysdate,
    request_id = p_request_id
    WHERE cash_receipt_id in
     ( select cash_receipt_id
       from ar_create_receipts_gt
       where  gt_id = p_gt_id
       and    request_id = p_request_id
       and    return_error_status = 'S'
       and    org_id = p_org_id );

    IF PG_DEBUG in ('Y','C') THEN
      arp_standard.debug ( 'NO of RA updated =  '|| to_char(SQL%ROWCOUNT));
    END IF;


    select /*+ LEADING (GT) INDEX (GT AR_CREATE_RECEIPTS_GT_N2) USE_NL(GT RA)
		INDEX (RA AR_RECEIVABLE_APPLICATIONS_N1) */
	   min(gt.cash_receipt_id),
	   max(gt.cash_receipt_id),
	   min(ra.receivable_application_id),
	   max(ra.receivable_application_id)
    into l_from_doc_id,
	 l_to_doc_id,
	 l_from_ra_doc_id,
	 l_to_ra_doc_id
    from   ar_create_receipts_gt gt, ar_receivable_applications ra
    where  gt.cash_receipt_id = ra.cash_receipt_id
    AND    gt_id = p_gt_id
    and    gt.request_id = p_request_id
    and    return_error_status = 'S'
    and    gt.org_id = p_org_id ;

    IF PG_DEBUG in ('Y','C') THEN
      arp_standard.debug ( 'Calling XLA event creation procedures for');
      arp_standard.debug ( 'xla_req_id      '|| p_request_id);
      arp_standard.debug ( 'xla_from_doc_id '|| l_from_doc_id);
      arp_standard.debug ( 'xla_to_doc_id   '|| l_to_doc_id);
      arp_standard.debug ( 'l_from_ra_doc_id '|| l_from_ra_doc_id);
      arp_standard.debug ( 'l_to_ra_doc_id   '|| l_to_ra_doc_id);
    END IF;

    /* Create events for the receipts associated to this request id and given range*/
	l_xla_ev_rec.xla_doc_table   := 'CRHAPP';
	l_xla_ev_rec.xla_req_id      := p_request_id;
	l_xla_ev_rec.xla_from_doc_id := l_from_doc_id;
	l_xla_ev_rec.xla_to_doc_id   := l_to_doc_id;
	l_xla_ev_rec.xla_mode        := 'B';
	l_xla_ev_rec.xla_call        := 'C';

	arp_xla_events.Create_Events( l_xla_ev_rec );

	l_xla_ev_rec.xla_doc_table   := 'CRH';
	l_xla_ev_rec.xla_req_id      := p_request_id;
	l_xla_ev_rec.xla_from_doc_id := l_from_doc_id;
	l_xla_ev_rec.xla_to_doc_id   := l_to_doc_id;
	l_xla_ev_rec.xla_mode        := 'B';
	l_xla_ev_rec.xla_call        := 'D';

	arp_xla_events.Create_Events( l_xla_ev_rec );

	l_xla_ev_rec.xla_doc_table   := 'APP';
	l_xla_ev_rec.xla_req_id      := p_request_id;
	l_xla_ev_rec.xla_from_doc_id := l_from_ra_doc_id;
	l_xla_ev_rec.xla_to_doc_id   := l_to_ra_doc_id;
	l_xla_ev_rec.xla_mode        := 'B';
	l_xla_ev_rec.xla_call        := 'D';

	arp_xla_events.Create_Events( l_xla_ev_rec );

    IF PG_DEBUG in ('Y', 'C') THEN
      arp_standard.debug('process_events()-');
    END IF;

    EXCEPTION
     WHEN others THEN
	 arp_util.debug('Exception : process_events() '|| SQLERRM);

  END process_events;


/*=======================================================================
 | PROCEDURE Create_Cash_Bulk
 |
 | DESCRIPTION
 |      This procedure is for calling Create_Cash routine in BULK mode.
 |      Before calling this routine customer has to populate AR_CREATE_RECEIPTS_GT
 |      After successful completion of thei procedure customer has to query
 |	AR_CREATE_RECEIPTS_ERROR table to get the error records.
 |
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |  This API is called in BULK mode so we have only generic IN parameters.
 |
 | RETURNS
 |      x_return_error_status , x_msg_count , x_msg_data
 |
 |
 | KNOWN ISSUES : Later this procedure will be moulded in SRS concurrent request11/19/2009
 |
 | NOTES
 |
 | MODIFICATION HISTORY
 | Date                  Author         Description of Changes
 | 19-NOV-2009           SPDIXIT         Created
 |
 |
 *=======================================================================*/
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
                )
IS

l_api_name       CONSTANT VARCHAR2(20) := 'CREATE_CASH_BULK';
l_api_version    CONSTANT NUMBER       := 1.0;
l_org_id		number;
l_org_return_status	varchar2(1);

l_gt_id			NUMBER;
l_err_rcpt_index	INTEGER;
l_cash_receipt_index    INTEGER;

TYPE cash_receipt_info_rec IS RECORD
(  cash_receipt_id      DBMS_SQL.NUMBER_TABLE ,
   receipt_number	DBMS_SQL.VARCHAR2_TABLE,
   receipt_date		DBMS_SQL.DATE_TABLE,
   gt_id		DBMS_SQL.NUMBER_TABLE,
   request_id		DBMS_SQL.NUMBER_TABLE,
   return_error_status  DBMS_SQL.VARCHAR2_TABLE,
   org_id		DBMS_SQL.NUMBER_TABLE);


l_cash_receipt_info_rec  cash_receipt_info_rec;


TYPE rcpt_error_info_rec IS RECORD
(  BATCH_ID                       DBMS_SQL.NUMBER_TABLE,
   REQUEST_ID                     DBMS_SQL.NUMBER_TABLE,
   CASH_RECEIPT_ID                DBMS_SQL.NUMBER_TABLE,
   RECEIPT_NUMBER                 DBMS_SQL.VARCHAR2_TABLE,
   RECEIPT_DATE                   DBMS_SQL.DATE_TABLE,
   CUSTOMER_TRX_ID                DBMS_SQL.NUMBER_TABLE,
   TRXN_NUMBER                    DBMS_SQL.VARCHAR2_TABLE,
   PAYMENT_SCHEDULE_ID            DBMS_SQL.NUMBER_TABLE,
   APPLIED_PAYMENT_SCHEDULE_ID    DBMS_SQL.NUMBER_TABLE,
   PAYING_CUSTOMER_ID             DBMS_SQL.NUMBER_TABLE,
   PAYING_SITE_USE_ID             DBMS_SQL.NUMBER_TABLE,
   EXCEPTION_CODE                 DBMS_SQL.VARCHAR2_TABLE,
   ADDITIONAL_MESSAGE             DBMS_SQL.VARCHAR2_TABLE,
   REMIT_BANK_ACCT_USE_ID         DBMS_SQL.NUMBER_TABLE,
   LAST_UPDATE_DATE               DBMS_SQL.DATE_TABLE,
   CREATION_DATE                  DBMS_SQL.DATE_TABLE,
   CREATED_BY                     DBMS_SQL.NUMBER_TABLE,
   LAST_UPDATE_LOGIN              DBMS_SQL.NUMBER_TABLE,
   PROGRAM_APPLICATION_ID         DBMS_SQL.NUMBER_TABLE,
   PROGRAM_ID                     DBMS_SQL.NUMBER_TABLE,
   PROGRAM_UPDATE_DATE            DBMS_SQL.DATE_TABLE,
   LAST_UPDATED_BY                DBMS_SQL.NUMBER_TABLE );

l_rcpt_error_info_tab	rcpt_error_info_rec;

TYPE rcpt_info_rec IS TABLE OF ar_create_receipts_gt%rowtype INDEX BY BINARY_INTEGER;
l_rcpt_info_tab		rcpt_info_rec;

CURSOR org_cur IS
SELECT org_id
FROM ar_create_receipts_gt
GROUP BY org_id;

CURSOR create_rcpt_cursor(p_c_org_id NUMBER) IS
SELECT *
FROM ar_create_receipts_gt
WHERE org_id = p_c_org_id
AND   return_error_status IS NULL;

l_attribute_rec         attribute_rec_type;
l_global_attribute_rec  global_attribute_rec_type;

    l_cash_receipt_id	NUMBER;
    l_return_status	varchar2(30);
    l_msg_count		number;
    l_msg_data		varchar2(240);
    l_count		number;
    l_request_id	number;
    l_bulk_count	BINARY_INTEGER ;
    P_CALLED_FROM	varchar2(30);

BEGIN
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_standard.debug('Create_Cash_Bulk()+');
   END IF;

   FOR org_rec IN org_cur LOOP
    /*code to set the org context for the batch,will avoid the org setting for
     each record inside the receipt API code */
    l_org_return_status := FND_API.G_RET_STS_SUCCESS;
    ar_mo_cache_utils.set_org_context_in_api( p_org_id => org_rec.org_id,
					      p_return_status => l_org_return_status);

    IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
	x_return_status := FND_API.G_RET_STS_ERROR;
	RETURN;
    END IF;

    l_gt_id := 0;
    l_count := 0;

    --fetch request_id ,all the receipts to be created in the batch will be associated
    -- to this request
    SELECT FND_CONCURRENT_REQUESTS_S.nextval
    INTO l_request_id
    FROM dual;

    IF NVL(p_fetch_bulk_commit,0) > 0 THEN
	l_bulk_count := p_fetch_bulk_commit ;
    ELSE
	l_bulk_count := MAX_ARRAY_SIZE ;
    END IF;

    IF PG_DEBUG in ('Y', 'C') THEN
	arp_standard.debug('Opening receipt cursor for org '||org_rec.org_id );
    END IF;

    OPEN create_rcpt_cursor( org_rec.org_id );
    LOOP
	FETCH  create_rcpt_cursor BULK COLLECT INTO l_rcpt_info_tab LIMIT l_bulk_count;

	IF PG_DEBUG in ('Y', 'C') THEN
	    arp_standard.debug('current fetch count   '|| l_rcpt_info_tab.count);
	END IF;

	IF l_rcpt_info_tab.count = 0 THEN
	    EXIT;
	END IF;


	/* In order to have intermediate commits with in the process(for better performance and
	   to support processing of large volumes of data),we have devided the data into various
	   logical batches based on value of MAX_ARRAY_SIZE.Each of these batch gets processed
	   and committed to the database before continuing the loop for remaining set of data.

   	   The field gt_id is used for logically seperating the data among different batches.*/
	l_gt_id := nvl(l_gt_id,0) + 1;

	IF PG_DEBUG in ('Y', 'C') THEN
	    arp_standard.debug('Value of l_gt_id '|| l_gt_id );
	END IF;


	  --reset the error index. Clearing all the junk data from record type
	  l_err_rcpt_index := 0;
	  l_rcpt_error_info_tab.BATCH_ID.DELETE;
	  l_rcpt_error_info_tab.REQUEST_ID.DELETE;
	  l_rcpt_error_info_tab.CASH_RECEIPT_ID.DELETE;
	  l_rcpt_error_info_tab.RECEIPT_NUMBER.DELETE;
	  l_rcpt_error_info_tab.RECEIPT_DATE.DELETE;
	  l_rcpt_error_info_tab.CUSTOMER_TRX_ID.DELETE;
	  l_rcpt_error_info_tab.TRXN_NUMBER.DELETE;
	  l_rcpt_error_info_tab.PAYMENT_SCHEDULE_ID.DELETE;
	  l_rcpt_error_info_tab.APPLIED_PAYMENT_SCHEDULE_ID.DELETE;
	  l_rcpt_error_info_tab.PAYING_CUSTOMER_ID.DELETE;
	  l_rcpt_error_info_tab.PAYING_SITE_USE_ID.DELETE;
	  l_rcpt_error_info_tab.EXCEPTION_CODE.DELETE;
	  l_rcpt_error_info_tab.ADDITIONAL_MESSAGE.DELETE;
	  l_rcpt_error_info_tab.REMIT_BANK_ACCT_USE_ID.DELETE;
	  l_rcpt_error_info_tab.LAST_UPDATE_DATE.DELETE;
	  l_rcpt_error_info_tab.CREATION_DATE.DELETE;
	  l_rcpt_error_info_tab.CREATED_BY.DELETE;
	  l_rcpt_error_info_tab.LAST_UPDATE_LOGIN.DELETE;
	  l_rcpt_error_info_tab.PROGRAM_APPLICATION_ID.DELETE;
	  l_rcpt_error_info_tab.PROGRAM_ID.DELETE;
	  l_rcpt_error_info_tab.PROGRAM_UPDATE_DATE.DELETE;
	  l_rcpt_error_info_tab.LAST_UPDATED_BY.DELETE;

	  --reset the receipt gt index. Clearing all the junk data from record type
	  l_cash_receipt_index := 0;
	  l_cash_receipt_info_rec.cash_receipt_id.delete;
	  l_cash_receipt_info_rec.receipt_number.delete;
	  l_cash_receipt_info_rec.receipt_date.delete;
	  l_cash_receipt_info_rec.gt_id.delete;
	  l_cash_receipt_info_rec.request_id.delete;
	  l_cash_receipt_info_rec.return_error_status.delete;
	  l_cash_receipt_info_rec.org_id.delete;

	  --loop over the array to create receipts and do payment processing if needed
	  FOR i IN l_rcpt_info_tab.FIRST..l_rcpt_info_tab.LAST   LOOP

		-- This is set so Xla events engine code is not invoked
		p_called_from := 'CUSTRECAPIBULK' ;

		l_attribute_rec.attribute_category := l_rcpt_info_tab(i).ATTRIBUTE_CATEGORY;
		l_attribute_rec.attribute1	   := l_rcpt_info_tab(i).ATTRIBUTE1;
		l_attribute_rec.attribute2	   := l_rcpt_info_tab(i).ATTRIBUTE2;
		l_attribute_rec.attribute3	   := l_rcpt_info_tab(i).ATTRIBUTE3;
		l_attribute_rec.attribute4	   := l_rcpt_info_tab(i).ATTRIBUTE4;
		l_attribute_rec.attribute5	   := l_rcpt_info_tab(i).ATTRIBUTE5;
		l_attribute_rec.attribute6	   := l_rcpt_info_tab(i).ATTRIBUTE6;
		l_attribute_rec.attribute7	   := l_rcpt_info_tab(i).ATTRIBUTE7;
		l_attribute_rec.attribute8	   := l_rcpt_info_tab(i).ATTRIBUTE8;
		l_attribute_rec.attribute9	   := l_rcpt_info_tab(i).ATTRIBUTE9;
		l_attribute_rec.attribute10	   := l_rcpt_info_tab(i).ATTRIBUTE10;
		l_attribute_rec.attribute11	   := l_rcpt_info_tab(i).ATTRIBUTE11;
		l_attribute_rec.attribute12	   := l_rcpt_info_tab(i).ATTRIBUTE12;
		l_attribute_rec.attribute13	   := l_rcpt_info_tab(i).ATTRIBUTE13;
		l_attribute_rec.attribute14	   := l_rcpt_info_tab(i).ATTRIBUTE14;
		l_attribute_rec.attribute15	   := l_rcpt_info_tab(i).ATTRIBUTE15;

		l_global_attribute_rec.global_attribute_category   := l_rcpt_info_tab(i).GLOBAL_ATTRIBUTE_CATEGORY;
		l_global_attribute_rec.global_attribute1	   := l_rcpt_info_tab(i).GLOBAL_ATTRIBUTE1;
		l_global_attribute_rec.global_attribute2	   := l_rcpt_info_tab(i).GLOBAL_ATTRIBUTE2;
		l_global_attribute_rec.global_attribute3	   := l_rcpt_info_tab(i).GLOBAL_ATTRIBUTE3;
		l_global_attribute_rec.global_attribute4	   := l_rcpt_info_tab(i).GLOBAL_ATTRIBUTE4;
		l_global_attribute_rec.global_attribute5	   := l_rcpt_info_tab(i).GLOBAL_ATTRIBUTE5;
		l_global_attribute_rec.global_attribute6	   := l_rcpt_info_tab(i).GLOBAL_ATTRIBUTE6;
		l_global_attribute_rec.global_attribute7	   := l_rcpt_info_tab(i).GLOBAL_ATTRIBUTE7;
		l_global_attribute_rec.global_attribute8	   := l_rcpt_info_tab(i).GLOBAL_ATTRIBUTE8;
		l_global_attribute_rec.global_attribute9	   := l_rcpt_info_tab(i).GLOBAL_ATTRIBUTE9;
		l_global_attribute_rec.global_attribute10	   := l_rcpt_info_tab(i).GLOBAL_ATTRIBUTE10;
		l_global_attribute_rec.global_attribute11	   := l_rcpt_info_tab(i).GLOBAL_ATTRIBUTE11;
		l_global_attribute_rec.global_attribute12	   := l_rcpt_info_tab(i).GLOBAL_ATTRIBUTE12;
		l_global_attribute_rec.global_attribute13	   := l_rcpt_info_tab(i).GLOBAL_ATTRIBUTE13;
		l_global_attribute_rec.global_attribute14	   := l_rcpt_info_tab(i).GLOBAL_ATTRIBUTE14;
		l_global_attribute_rec.global_attribute15	   := l_rcpt_info_tab(i).GLOBAL_ATTRIBUTE15;

	   --call the internal routine
	     Create_cash_1(
	         -- Standard API parameters.
                 p_api_version ,
                 p_init_msg_list,
                 p_commit,
                 p_validation_level,
                 l_return_status,
                 l_msg_count,
                 l_msg_data,
                 -- Receipt info. parameters
                 l_rcpt_info_tab(i).usr_currency_code, --the translated currency code
                 l_rcpt_info_tab(i).currency_code ,
                 l_rcpt_info_tab(i).usr_exchange_rate_type ,
                 l_rcpt_info_tab(i).exchange_rate_type  ,
                 l_rcpt_info_tab(i).exchange_rate       ,
                 l_rcpt_info_tab(i).exchange_rate_date  ,
                 l_rcpt_info_tab(i).amount              ,
                 l_rcpt_info_tab(i).factor_discount_amount,
                 l_rcpt_info_tab(i).receipt_number  ,
                 l_rcpt_info_tab(i).receipt_date    ,
                 l_rcpt_info_tab(i).gl_date         ,
                 l_rcpt_info_tab(i).maturity_date   ,
                 l_rcpt_info_tab(i).postmark_date   ,
                 l_rcpt_info_tab(i).customer_id     ,
                 l_rcpt_info_tab(i).customer_name   ,
                 l_rcpt_info_tab(i).customer_number ,
                 l_rcpt_info_tab(i).customer_bank_account_id ,
                 l_rcpt_info_tab(i).customer_bank_account_num ,
                 l_rcpt_info_tab(i).customer_bank_account_name ,
                 l_rcpt_info_tab(i).payment_trxn_extension_id ,
                 l_rcpt_info_tab(i).location               ,
                 l_rcpt_info_tab(i).customer_site_use_id   ,
                 l_rcpt_info_tab(i).default_site_use,
                 l_rcpt_info_tab(i).customer_receipt_reference ,
                 l_rcpt_info_tab(i).override_remit_account_flag ,
                 l_rcpt_info_tab(i).remittance_bank_account_id  ,
                 l_rcpt_info_tab(i).remittance_bank_account_num ,
                 l_rcpt_info_tab(i).remittance_bank_account_name ,
                 l_rcpt_info_tab(i).deposit_date         ,
                 l_rcpt_info_tab(i).receipt_method_id    ,
                 l_rcpt_info_tab(i).receipt_method_name  ,
                 l_rcpt_info_tab(i).doc_sequence_value   ,
                 l_rcpt_info_tab(i).ussgl_transaction_code   ,
                 l_rcpt_info_tab(i).anticipated_clearing_date ,
                 p_called_from,
                 l_attribute_rec,
       -- ******* Global Flexfield parameters *******
                 l_global_attribute_rec,
                 l_rcpt_info_tab(i).comments             ,
       --  ***  Notes Receivable Additional Information  ***
                 l_rcpt_info_tab(i).issuer_name    ,
                 l_rcpt_info_tab(i).issue_date     ,
                 l_rcpt_info_tab(i).issuer_bank_branch_id  ,
      --  added  parameters to differentiate between create_cash and create_and_apply
                 NULL,
                 NULL,
                 l_rcpt_info_tab(i).installment,
                 NULL,
                 'CREATE_CASH_BULK',
                 l_rcpt_info_tab(i).org_id,
      --   ** OUT NOCOPY variables
                 l_cash_receipt_id
                 );

	    IF PG_DEBUG in ('Y', 'C') THEN
    		arp_standard.debug('Return Status ' || l_return_status);
	        arp_standard.debug('Cash Receipts ID '|| l_cash_receipt_id);
	    END IF;

	   l_cash_receipt_info_rec.receipt_number(l_cash_receipt_index) := l_rcpt_info_tab(i).receipt_number;
	   l_cash_receipt_info_rec.receipt_date(l_cash_receipt_index)   := l_rcpt_info_tab(i).receipt_date;
	   l_cash_receipt_info_rec.cash_receipt_id(l_cash_receipt_index) := l_cash_receipt_id ;
	   l_cash_receipt_info_rec.gt_id(l_cash_receipt_index)		:= l_gt_id;
	   l_cash_receipt_info_rec.request_id(l_cash_receipt_index)	:= l_request_id;
	   l_cash_receipt_info_rec.org_id(l_cash_receipt_index)		:= l_rcpt_info_tab(i).org_id;

	IF l_return_status = 'S' THEN

	   l_cash_receipt_info_rec.return_error_status(l_cash_receipt_index) := 'S';

	ELSE

	   l_cash_receipt_info_rec.return_error_status(l_cash_receipt_index) := 'E';
  	   l_count := 0;

	IF l_msg_count  = 1 THEN

	    IF PG_DEBUG in ('Y', 'C') THEN
	        arp_util.debug('l_msg_count '||l_msg_count);
	        arp_standard.debug ( 'the message data is ' || l_msg_data );
	    END IF;

	   l_rcpt_error_info_tab.receipt_number(l_err_rcpt_index)	:= l_rcpt_info_tab(i).receipt_number;
	   l_rcpt_error_info_tab.receipt_date(l_err_rcpt_index)		:= l_rcpt_info_tab(i).receipt_date;
	   l_rcpt_error_info_tab.cash_receipt_id(l_err_rcpt_index)	:= l_cash_receipt_id;
	   l_rcpt_error_info_tab.request_id(l_err_rcpt_index)		:= l_request_id;
	   l_rcpt_error_info_tab.paying_customer_id(l_err_rcpt_index)	:= l_rcpt_info_tab(i).customer_number;
   	   l_rcpt_error_info_tab.paying_site_use_id(l_err_rcpt_index)	:= l_rcpt_info_tab(i).customer_site_use_id;
	   l_rcpt_error_info_tab.remit_bank_acct_use_id(l_err_rcpt_index) := l_rcpt_info_tab(i).remittance_bank_account_id;
	   l_rcpt_error_info_tab.exception_code(l_err_rcpt_index)	:= 'CREATE_CASH_BULK_ERROR';
	   l_rcpt_error_info_tab.additional_message(l_err_rcpt_index)	:= substr(l_msg_data, 1,240);

          l_err_rcpt_index := l_err_rcpt_index + 1;

	 ELSIF l_msg_count > 1 THEN
	FOR l_count IN 1..l_msg_count LOOP

	    l_msg_data :=FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);

		  IF PG_DEBUG in ('Y', 'C') THEN
		    arp_standard.debug ( 'the number is  ' || l_count );
		    arp_standard.debug ( 'the message data is ' || l_msg_data );
		  END IF;

	   IF l_msg_data IS NOT NULL THEN
	   l_rcpt_error_info_tab.receipt_number(l_err_rcpt_index)	:= l_rcpt_info_tab(i).receipt_number;
	   l_rcpt_error_info_tab.receipt_date(l_err_rcpt_index)		:= l_rcpt_info_tab(i).receipt_date;
	   l_rcpt_error_info_tab.cash_receipt_id(l_err_rcpt_index)	:= l_cash_receipt_id;
	   l_rcpt_error_info_tab.request_id(l_err_rcpt_index)		:= l_request_id;
	   l_rcpt_error_info_tab.paying_customer_id(l_err_rcpt_index)	:= l_rcpt_info_tab(i).customer_number;
   	   l_rcpt_error_info_tab.paying_site_use_id(l_err_rcpt_index)	:= l_rcpt_info_tab(i).customer_site_use_id;
	   l_rcpt_error_info_tab.remit_bank_acct_use_id(l_err_rcpt_index) := l_rcpt_info_tab(i).remittance_bank_account_id;
	   l_rcpt_error_info_tab.exception_code(l_err_rcpt_index)	:= 'CREATE_CASH_BULK_ERROR';
	   l_rcpt_error_info_tab.additional_message(l_err_rcpt_index)	:= substr(l_msg_data, 1,240);

	   l_err_rcpt_index := l_err_rcpt_index + 1 ;
	   END IF;
	END LOOP;

 	ELSE
	    EXIT;
        END IF;

	END IF;

	l_cash_receipt_index := l_cash_receipt_index + 1;

	END LOOP;


     FORALL j IN l_cash_receipt_info_rec.cash_receipt_id.FIRST..l_cash_receipt_info_rec.cash_receipt_id.LAST
	UPDATE ar_create_receipts_gt
		SET request_id		= l_cash_receipt_info_rec.request_id(j),
		    cash_receipt_id	= l_cash_receipt_info_rec.cash_receipt_id(j),
		    return_error_status = l_cash_receipt_info_rec.return_error_status(j),
		    gt_id		= l_cash_receipt_info_rec.gt_id(j)
		WHERE receipt_number	= l_cash_receipt_info_rec.receipt_number(j)
		AND   receipt_date	= l_cash_receipt_info_rec.receipt_date(j)
		AND   org_id		= l_cash_receipt_info_rec.org_id(j);


	  FORALL k IN l_rcpt_error_info_tab.receipt_number.FIRST..l_rcpt_error_info_tab.receipt_number.LAST
		INSERT INTO AR_CREATE_RECEIPTS_ERROR VALUES (
			NULL,
			l_rcpt_error_info_tab.request_id(k),
			l_rcpt_error_info_tab.cash_receipt_id(k),
			l_rcpt_error_info_tab.receipt_number(k),
			l_rcpt_error_info_tab.receipt_date(k),
			NULL,
			NULL,
			NULL,
			NULL,
			l_rcpt_error_info_tab.paying_customer_id(k),
			l_rcpt_error_info_tab.paying_site_use_id(k),
			l_rcpt_error_info_tab.exception_code(k),
			l_rcpt_error_info_tab.additional_message(k),
			l_rcpt_error_info_tab.remit_bank_acct_use_id(k),
			sysdate,
			sysdate,
			fnd_global.user_id,
			fnd_global.login_id,
			fnd_global.prog_appl_id,
			NULL,
			SYSDATE,
			fnd_global.user_id ) ;

    	 process_events( l_gt_id, l_request_id, org_rec.org_id );

	-- Commit after every bulk fetch specified
	COMMIT;

    END LOOP;--main select cursor loop
  END LOOP; --org id cursor

  IF PG_DEBUG in ('Y', 'C') THEN
   arp_standard.debug('Create_Cash_Bulk()-');
  END IF;

  EXCEPTION
    WHEN others THEN
      IF PG_DEBUG in ('Y', 'C') THEN
	arp_standard.debug('Exception : Create_Cash_Bulk() '|| SQLERRM);
      END IF;
END Create_Cash_Bulk;

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
 	       ) IS
 	 l_api_name       CONSTANT VARCHAR2(20) := 'Change_customer';
 	 l_api_version    CONSTANT NUMBER       := 1.0;
 	 l_cash_receipt_id  NUMBER;
 	 l_receivable_application_id NUMBER;
 	 l_customer_id NUMBER;
 	 l_location NUMBER;
 	 l_rec_customer_id NUMBER;
 	 l_rec_date DATE;
 	 l_pay_unrel_inv_flag            ar_system_parameters.pay_unrelated_invoices_flag%TYPE;

 	 BEGIN

 	        /*------------------------------------+
 	         |   Standard start of API savepoint  |
 	         +------------------------------------*/

 	       SAVEPOINT Change_customer_PVT;

 	        /*--------------------------------------------------+
 	         |   Standard call to check for call compatibility  |
 	         +--------------------------------------------------*/

 	         IF NOT FND_API.Compatible_API_Call(
 	                                             l_api_version,
 	                                             p_api_version,
 	                                             l_api_name,
 	                                             G_PKG_NAME
 	                                           )
 	         THEN
 	               RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
 	  END IF;

 	        /*--------------------------------------------------------------+
 	         |   Initialize message list if p_init_msg_list is set to TRUE  |
 	         +--------------------------------------------------------------*/

 	         IF FND_API.to_Boolean( p_init_msg_list )
 	           THEN
 	               FND_MSG_PUB.initialize;
 	         END IF;


 	         IF PG_DEBUG in ('Y', 'C') THEN
 	            arp_util.debug('Change_customer()+ ');
 	         END IF;

 	         /*-------------------------------------------------+
 	          | Initialize the profile option package variables |
 	          +-------------------------------------------------*/

 	            initialize_profile_globals;

 	        /*-------------------------------------------------+
 	         | Initialize SOB/org dependent variables          |
 	         +-------------------------------------------------*/
 	         arp_global.init_global;
 	         arp_standard.init_standard;

 	        /*-----------------------------------------+
 	         |   Initialize return status to SUCCESS   |
 	         +-----------------------------------------*/

 	         x_return_status := FND_API.G_RET_STS_SUCCESS;

 	        /*---------------------------------------------+
 	         |   ========== Start of API Body ==========   |
 	         +---------------------------------------------*/

 	      l_cash_receipt_id        := p_cash_receipt_id;
 	      l_receivable_application_id := p_receivable_application_id;
 	      l_customer_id := p_customer_id;
 	      l_location := p_location;

 	      /*----------------------------------------------+
 	       |  Get pay_unrelated_invoice flag              |
 	      +-----------------------------------------------*/
 	         SELECT  nvl(pay_unrelated_invoices_flag,'N')
 	         INTO  l_pay_unrel_inv_flag
 	         FROM   ar_system_parameters;

 	      /*----------------------------------------------+
 	       |  Get Customer info from Receipt Header       |
 	      +-----------------------------------------------*/

 	         SELECT pay_from_customer
 	               , receipt_date
 	         INTO  l_rec_customer_id
 	               , l_rec_date
 	         FROM  ar_cash_receipts
 	         WHERE cash_receipt_id = l_cash_receipt_id;


 	      /*----------------------------------------------+
 	       |  Validate customer_id                        |
 	      +-----------------------------------------------*/

 	        IF ( l_pay_unrel_inv_flag  = 'Y')
 	        THEN
 	             BEGIN
 	               SELECT cust_acct.cust_account_id
 	                 INTO l_customer_id
 	                 FROM  hz_cust_accounts cust_acct,
 	                       hz_parties party
 	                WHERE cust_acct.party_id = party.party_id
 	                 and  cust_acct.cust_account_id = l_customer_id
 	                 and  cust_acct.status = 'A' ;
 	             EXCEPTION
 	             WHEN no_data_found THEN
 	                 FND_MESSAGE.SET_NAME('AR','AR_RAPI_CUST_ID_INVALID');
 	                 FND_MSG_PUB.Add;
 	                 RAISE FND_API.G_EXC_ERROR;
 	             END;
 	         ELSIF ( l_pay_unrel_inv_flag  = 'N')
 	         THEN
 	            BEGIN
 	              SELECT cust_acct.cust_account_id
 	               INTO  l_customer_id
 	               FROM hz_cust_accounts cust_acct,
 	                    hz_parties party
 	            WHERE cust_acct.party_id = party.party_id
 	               AND cust_acct.status = 'A'
 	               AND cust_acct.cust_account_id = l_customer_id
 	               AND cust_acct.cust_account_id in
 	                (
 	                 SELECT TO_NUMBER(l_rec_customer_id)
 	                 FROM dual
 	                 UNION
 	                 SELECT related_cust_account_id
 	                 FROM hz_cust_acct_relate r
 	                 WHERE r.cust_account_id = l_rec_customer_id
 	                   AND r.status = 'A'
 	                   AND r.bill_to_flag = 'Y'
 	                 UNION
 	                 SELECT rel.related_cust_account_id
 	                 FROM ar_paying_relationships_v rel,
 	                      hz_cust_accounts acc
 	                 WHERE rel.party_id = acc.party_id
 	                   AND acc.cust_account_id = l_rec_customer_id
 	                   AND l_rec_date BETWEEN effective_start_date
 	                                    AND effective_end_date
 	                 );
 	             EXCEPTION
 	             WHEN no_data_found THEN
 	                 FND_MESSAGE.SET_NAME('AR','AR_RAPI_CUST_ID_INVALID');
 	                 FND_MSG_PUB.Add;
 	                 RAISE FND_API.G_EXC_ERROR;
 	             END;
 	           END IF;

 	      /*----------------------------------------------+
 	       |  Validate customer_site_use_id               |
 	      +-----------------------------------------------*/

 	      BEGIN
 	        --Bug 2474471- Corrected the validation logic take from customer
 	        --account.

 	        SELECT  site_uses.site_use_id
 	        INTO    l_location
 	        FROM    hz_cust_acct_sites acct_site,
 	                hz_party_sites party_site,
 	                hz_locations loc,
 	                hz_cust_site_uses site_uses
 	        WHERE   acct_site.cust_acct_site_id = site_uses.cust_acct_site_id
 	        AND     acct_site.party_site_id = party_site.party_site_id
 	       AND     loc.location_id = party_site.location_id
 	        AND     site_uses.site_use_code in ('BILL_TO','DRAWEE')
 	        AND     acct_site.cust_account_id = l_customer_id
 	        AND     site_uses.site_use_id=l_location;

 	        EXCEPTION
 	         WHEN no_data_found THEN
 	           FND_MESSAGE.SET_NAME('AR','AR_RAPI_CUS_STE_USE_ID_INVALID');
 	           FND_MSG_PUB.Add;
 	           RAISE FND_API.G_EXC_ERROR;
 	        END;

 	      /*----------------------------------------------+
 	       |  Update receivable_application with new value|
 	      +-----------------------------------------------*/

 	     BEGIN
 	          UPDATE ar_receivable_applications
 	          SET    ON_ACCT_CUST_ID = l_customer_id,
 	                 ON_ACCT_CUST_SITE_USE_ID = l_location
 	          WHERE  cash_receipt_id = l_cash_receipt_id
 	          AND    receivable_application_id = l_receivable_application_id;

 	     EXCEPTION
 	         WHEN OTHERS THEN
 	                      arp_standard.debug('Change_customer: ' || 'Unexpected error '||sqlerrm||
 	                     ' at AR_RECEIPT_API_PUB.Change_customer()+');
 	                   x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
 	                   IF    FND_MSG_PUB.Check_Msg_Level
 	                         (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
 	                   THEN
 	                         FND_MSG_PUB.Add_Exc_Msg
 	                         (       G_PKG_NAME          ,
 	                                 l_api_name
 	                         );
 	                    END IF;
 	    END;

 	 EXCEPTION
 	        WHEN FND_API.G_EXC_ERROR THEN

 	                 IF PG_DEBUG in ('Y', 'C') THEN
 	                    arp_util.debug('Change_customer: ' || SQLCODE, G_MSG_ERROR);
 	                    arp_util.debug('Change_customer: ' || SQLERRM, G_MSG_ERROR);
 	                 END IF;

 	             ROLLBACK TO Change_customer_PVT;
 	                 x_return_status := FND_API.G_RET_STS_ERROR ;

 	                -- Display_Parameters;

 	                 FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
 	                                            p_count       =>      x_msg_count,
 	                                            p_data        =>      x_msg_data
 	                                          );

 	         WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

 	                 IF PG_DEBUG in ('Y', 'C') THEN
 	                    arp_util.debug('Change_customer: ' || SQLERRM, G_MSG_ERROR);
 	                 END IF;
 	                 ROLLBACK TO Unapply_Open_Receipt_PVT;
 	                 x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

 	                --  Display_Parameters;

 	                 FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
 	                                            p_count       =>      x_msg_count,
 	                                            p_data        =>      x_msg_data
 	                                          );

 	         WHEN OTHERS THEN
 	                IF (SQLCODE = -20001)
 	                 THEN

 	                       ROLLBACK TO Change_customer_PVT;

 	                       --If only one error message on the stack,
 	                       --retrive it

 	                       x_return_status := FND_API.G_RET_STS_ERROR ;
 	                       FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
 	                       FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','Change_customer: '||SQLERRM);
 	                       FND_MSG_PUB.Add;

 	                       FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
 	                                                  p_count  =>  x_msg_count,
 	                                                  p_data   => x_msg_data
 	                                                 );
 	                       RETURN;
 	                 ELSE
 	                       x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
 	                       FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
 	                       FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','Change_customer : '||SQLERRM);
 	                       FND_MSG_PUB.Add;
 	                 END IF;

 	                 IF PG_DEBUG in ('Y', 'C') THEN
 	                    arp_util.debug(  SQLCODE, G_MSG_ERROR);
 	                    arp_util.debug(  SQLERRM, G_MSG_ERROR);
 	                 END IF;

 	                 ROLLBACK TO Change_customer_PVT;

 	                 IF      FND_MSG_PUB.Check_Msg_Level
 	                 THEN
 	                 FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME,
 	                                         l_api_name
 	                                        );
 	                 END IF;

 	              --   Display_Parameters;

 	                 FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
 	                                            p_count       =>      x_msg_count,
 	                                            p_data        =>      x_msg_data
 	                                          );

END Change_customer;

/* Added for bug 21391824 - Begin */
/*=======================================================================
 | PROCEDURE check_recp_balance_bulk
 |
 | DESCRIPTION
 |      This procedure is for calling Check receipt balance in BULK mode.
 |      This routine has to be called using P_called_from parameter value
 |      as 'AR_RECEIPT_API_PUB.APPLY'.
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |  This API is called in BULK mode so we have only generic IN parameters.
 |
 | RETURNS
 |      x_return_status , p_unbalanced_cr_tbl
 |
 |
 | NOTES
 |
 | MODIFICATION HISTORY
 | Date                  Author         Description of Changes
 | 14-JUL-2015           RRAVIKIR         Created
 |
 |
 *=======================================================================*/
PROCEDURE check_recp_balance_bulk(
                  p_called_from IN VARCHAR2,
                  p_unbalanced_cr_tbl OUT NOCOPY unbalanced_receipts,
                  x_return_status    OUT NOCOPY VARCHAR2) IS

BAL_CHECK_FAILED	EXCEPTION;

CURSOR c1 is
      select sum(nvl(amount_dr,0)) sum_amount_dr,
           sum(nvl(amount_cr,0)) sum_amount_cr,
           sum(nvl(acctd_amount_dr,0)) sum_acctd_amount_dr,
           sum(nvl(acctd_amount_cr,0)) sum_acctd_amount_cr,
           max(src.cc_flag) cc_flag, src.gl_date, src.cr_id
      from (	     select mcd.cash_receipt_id cr_id,
                   mcd.misc_cash_distribution_id src_id,
                   'MCD' src_tab,
                   'N' cc_flag,
                   mcd.gl_date
             from  ar_cash_receipts cr, ar_misc_cash_distributions mcd
             where  cr.cash_receipt_id in (select cash_receipt_id
                                           from ar_create_receipts_gt)
	      and  cr.cash_receipt_id = mcd.cash_receipt_id
              and  mcd.posting_control_id = -3
              UNION ALL
            select crh.cash_receipt_id cr_id,
                   crh.cash_receipt_history_id src_id,
                   'CRH'  src_tab,
                   'N'  cc_flag,
                   crh.gl_date
              from ar_cash_receipts cr, ar_cash_receipt_history crh
              where  cr.cash_receipt_id in (select cash_receipt_id
                                            from ar_create_receipts_gt)
	      and  cr.cash_receipt_id = crh.cash_receipt_id
              and  crh.posting_control_id = -3
              and  nvl(crh.postable_flag,'Y') = 'Y'
              UNION ALL
            select ra.cash_receipt_id cr_id,
                   ra.receivable_application_id src_id,
                   'RA' src_tab,
                   decode(ra.amount_applied_from,NULL,
                          'N',
                          'Y') cc_flag,
                   ra.gl_date
              from ar_cash_receipts cr, ar_receivable_applications ra
              where  cr.cash_receipt_id in (select cash_receipt_id
                                            from ar_create_receipts_gt)
	       and cr.cash_receipt_id = ra.cash_receipt_id
               and nvl(ra.confirmed_flag,'Y') = 'Y'
               and nvl(ra.postable,'Y') = 'Y'
               and ra.posting_control_id = -3) src,
            ar_distributions ard
      where ard.source_id = src.src_id
        and ard.source_table = src.src_tab
      group by src.gl_date, src.cr_id
      having ((sum(nvl(amount_dr,0)) <> sum(nvl(amount_cr,0)) AND max(src.cc_flag) = 'N')
             OR (sum(nvl(acctd_amount_dr,0)) <> sum(nvl(acctd_amount_cr,0))))
      order by src.cr_id;

l_bulk_index     NUMBER := 0;
l_error_occured  BOOLEAN := FALSE;

BEGIN

IF PG_DEBUG in ('Y', 'C') THEN
   arp_standard.debug('AR_RECEIPT_API_PUB.CHECK_RECP_BALANCE_BULK (+)');
END IF;

IF PG_BAL_CHECK_ENABLED = 'Y' THEN

  IF p_called_from = 'AR_RECEIPT_API_PUB.APPLY' AND arp_global.sysparam.accounting_method = 'ACCRUAL' THEN

   FOR c2 in c1 LOOP

     IF PG_DEBUG in ('Y', 'C') THEN
        arp_standard.debug('AR_RECEIPT_API_PUB.CHECK_RECP_BALANCE_BULK - OUT_OF_BALANCE');
        arp_standard.debug('Cash Receipt Id: '     || c2.cr_id);
        arp_standard.debug('GL Date: '             || to_char(c2.gl_date,'DD-MON-YYYY'));
        arp_standard.debug('Sum Amount Dr: '       || c2.sum_amount_dr);
        arp_standard.debug('Sum Amount Cr: '       || c2.sum_amount_cr);
        arp_standard.debug('Sum Acctd Amount Dr: ' || c2.sum_acctd_amount_dr);
        arp_standard.debug('Sum Acctd Amount Cr: ' || c2.sum_acctd_amount_cr);
        arp_standard.debug('Cross Currency Flag: ' || c2.cc_flag);
     END IF;

     l_bulk_index := l_bulk_index + 1;
     p_unbalanced_cr_tbl(l_bulk_index).cash_receipt_id := c2.cr_id;

     IF ARP_BALANCE_CHECK.CHECK_PRECISION(c2.sum_acctd_amount_dr)
        OR ARP_BALANCE_CHECK.CHECK_PRECISION(c2.sum_acctd_amount_cr)
     THEN
        p_unbalanced_cr_tbl(l_bulk_index).message_code := 'AR_APP_CURR_PRECISION';
        l_error_occured := TRUE;
     ELSE
        p_unbalanced_cr_tbl(l_bulk_index).message_code := 'AR_AMOUNTS_NO_MATCH';
        l_error_occured := TRUE;
     END IF;

   END LOOP;

  END IF;

 END IF;

 delete from AR_CREATE_RECEIPTS_GT;

 IF (l_error_occured) THEN

   ROLLBACK TO Apply_PVT;
   x_return_status := FND_API.G_RET_STS_ERROR ;
   RAISE BAL_CHECK_FAILED;

 END IF;

IF PG_DEBUG in ('Y', 'C') THEN
   arp_standard.debug('AR_RECEIPT_API_PUB.CHECK_RECP_BALANCE_BULK (-)');
END IF;

EXCEPTION
  WHEN BAL_CHECK_FAILED THEN
     IF PG_DEBUG in ('Y', 'C') THEN
        arp_standard.debug('AR_RECEIPT_API_PUB.CHECK_RECP_BALANCE_BULK - BALANCE CHECK FAILED');
     END IF;
     RAISE;
  WHEN OTHERS THEN
     IF PG_DEBUG in ('Y', 'C') THEN
        arp_standard.debug('AR_RECEIPT_API_PUB.CHECK_RECP_BALANCE_BULK - OTHERS');
     END IF;
     RAISE;
END check_recp_balance_bulk;

/* Added for bug 21391824 - End */

BEGIN
    arp_util.debug('initialization section of ar_receipt_api_pub');
	ar_receipt_lib_pvt.pg_profile_doc_seq             := FND_API.G_MISS_CHAR;
	ar_receipt_lib_pvt.pg_profile_enable_cc           := FND_API.G_MISS_CHAR;
	ar_receipt_lib_pvt.pg_profile_appln_gl_date_def   := FND_API.G_MISS_CHAR;
	ar_receipt_lib_pvt.pg_profile_amt_applied_def     := FND_API.G_MISS_CHAR;
	ar_receipt_lib_pvt.pg_profile_cc_rate_type        := FND_API.G_MISS_CHAR;
	ar_receipt_lib_pvt.pg_profile_dsp_inv_rate        := FND_API.G_MISS_CHAR;
	ar_receipt_lib_pvt.pg_profile_create_bk_charges   := FND_API.G_MISS_CHAR;
	ar_receipt_lib_pvt.pg_profile_def_x_rate_type     := FND_API.G_MISS_CHAR;

END AR_RECEIPT_API_PUB;
/
