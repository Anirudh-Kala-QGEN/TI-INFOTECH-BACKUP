CREATE OR REPLACE VIEW TI_AP_INVOICE_BATCH_LOV_VIEW
AS
    (SELECT DISTINCT BATCH_ID
       FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr TBL
      WHERE     (SELECT COUNT (1)
                   FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
                  WHERE     INVOICE_NUMBER = TBL.INVOICE_NUMBER
                        AND OPERATING_UNIT = TBL.OPERATING_UNIT
                        AND PARTY_NAME = TBL.PARTY_NAME
                        AND PROCESS_FLAG = 'N') =
                (SELECT COUNT (1)
                   FROM XXAU_AP_INV_WITH_GST_TDS_TBL@ebstohr
                  WHERE     INVOICE_NUMBER = TBL.INVOICE_NUMBER
                        AND OPERATING_UNIT = TBL.OPERATING_UNIT
                        AND PARTY_NAME = TBL.PARTY_NAME
                        AND TAX_CATEGORY IS NULL
                        AND PROCESS_FLAG = 'N')
            AND PROCESS_FLAG = 'N');