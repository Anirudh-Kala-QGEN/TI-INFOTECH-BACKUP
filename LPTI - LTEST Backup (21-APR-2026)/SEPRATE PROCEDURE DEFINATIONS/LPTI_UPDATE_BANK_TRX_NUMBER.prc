CREATE OR REPLACE procedure APPS.lpti_update_bank_trx_number(retcode    OUT VARCHAR2,
                                                             errbuf OUT VARCHAR2
                                                             ) is
v_trx_number varchar2(50);
begin
for i in (
SELECT RTRIM(LTRIM(REF_RECEIPT_NO)) REF_RECEIPT_NO,TO_CHAR(BANK_BRANCH_ID) BANK_BRANCH_ID,AMOUNT,RECEIPT_NUMBER 
FROM oa_ar_receipt_mas@taprod_dblink
WHERE (RTRIM(LTRIM(REF_RECEIPT_NO)),BANK_BRANCH_ID,AMOUNT) IN (
SELECT BANK_TRX_NUMBER,bank_account_id,amount
FROM CE_STATEMENT_HEADERS_ALL h,
CE_STATEMENT_LINES l
where h.STATEMENT_HEADER_ID=l.STATEMENT_HEADER_ID
and l.trx_type='CREDIT'
AND l.status = 'UNRECONCILED'
and RTRIM(LTRIM(REF_RECEIPT_NO))='124952'
)) loop

UPDATE CE_STATEMENT_LINES
SET BANK_TRX_NUMBER=I.RECEIPT_NUMBER
WHERE ATTRIBUTE5=I.REF_RECEIPT_NO
AND ATTRIBUTE7=i.BANK_BRANCH_ID
and amount=i.amount;

end loop;
commit;
end;
/
