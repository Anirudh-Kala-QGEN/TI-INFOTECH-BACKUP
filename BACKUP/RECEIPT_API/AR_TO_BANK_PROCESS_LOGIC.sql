In Oracle R12.2, Receivables (AR) bank information is primarily managed within the Cash Management (CE) module using Oracle Trading 
Community Architecture (TCA) for party data. 

Key tables include 
CE_BANK_ACCOUNTS (bank accounts), 
CE_BANK_ACCT_USES_ALL (usage), 
IBY_EXT_BANK_ACCOUNTS (external/customer accounts), 
and AR_RECEIPT_METHOD_ACCOUNTS_ALL (linking receipts to banks). 


Key Bank Tables in Oracle R12.2 (AR Context)

Internal Bank Accounts (Remittance/Receipt Banks):
	1. CE_BANK_ACCOUNTS: Stores bank account details.
	2. CE_BANK_ACCT_USES_ALL: Stores the usage of bank accounts (e.g., Payables or Receivables use).
	3. CE_BANK_BRANCHES_V: View for bank branch details.
	4. CE_BANKS_V: View for bank information.
	5. AR_RECEIPT_METHOD_ACCOUNTS_ALL: Links receipt methods to bank accounts, defining accounting for receipt lifecycles.

Customer (External) Bank Accounts:
	1. IBY_EXT_BANK_ACCOUNTS: Stores bank account numbers and routing details for customers.
	2. IBY_PMT_INSTR_USES_ALL: Maps bank accounts to external payers (customers/sites).
	3. IBY_EXTERNAL_PAYERS_ALL: Links the instrument to the customer site.
	4. HZ_PARTIES & HZ_PARTY_SITES: Stores the bank/branch name and location data.

AR-Specific Views (Updated for R12.2):
	1. AR_CASH_RECEIPTS_V: Updated to show bank details on receipts.
	2. AR_BATCHES_V: Updated for remittance bank information. 

Key Relationships
	1. Customer to Bank: HZ_PARTIES -> IBY_EXT_BANK_ACCOUNTS -> IBY_PMT_INSTR_USES_ALL.
	2. Receipt to Bank: AR_CASH_RECEIPTS_ALL -> AR_RECEIPT_METHOD_ACCOUNTS_ALL -> CE_BANK_ACCOUNTS. 