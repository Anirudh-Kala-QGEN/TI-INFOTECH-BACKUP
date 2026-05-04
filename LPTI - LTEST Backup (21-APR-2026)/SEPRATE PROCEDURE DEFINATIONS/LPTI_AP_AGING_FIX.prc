CREATE OR REPLACE procedure APPS.lpti_ap_aging_fix(v_run_id varchar2) is

PP_BAL NUMBER;
CR_BAL NUMBER;
SI_BAL NUMBER;

PP_ADJ NUMBER:=0;
SI_ADJ NUMBER;
V_AMT  NUMBER:=0;
V_BAL_AMT   NUMBER:=0;
V_REF_INV_ID    VARCHAR2(250):=NULL;
V_COUNT NUMBER:=0;
v_si_amount number:=0;
v_pp_amount number:=0;
begin

--final pro

---- run the below script before runing the procedure ------

    begin
    
    begin
    update lpti_ap_open_item_wise_os
    set si_amount=Remaining_amt,
    pp_amount=0,
    REF_INV_ID=null
    where invoice_type IN ('STANDARD')
    and run_req_id=v_run_id
    and vendor_id <> 9323;
    exception when others then 
    null;   
    end;
               
    begin
    update lpti_ap_open_item_wise_os
    set pp_amount=Remaining_amt,
    si_amount=0,
    REF_INV_ID=null
    where invoice_type IN ('PREPAYMENT','CREDIT')
    and run_req_id=v_run_id
    and vendor_id <> 9323;
    exception when others then 
    null;   
    end;
    
    commit;
               
    end;

---- run the above script before runing the procedure ------


for i in (select invoice_id ,
                 VENDOR_ID,
                 SUPPLIER_NUMBER,
                 invoice_type,
                 --OUTSTANDING_AMT_FUNC_T,
                 --OUTSTANDING_AMT_FUNC_02,
                 DAYS,
                 --ADDJ_OUTS_BAL,
                 NVL(Remaining_amt,0) Remaining_amt,
                 nvl(pp_amount,0) pp_amount,
                 nvl(si_amount,0) si_amount,
                 run_req_id
            from lpti_ap_open_item_wise_os
           where invoice_type IN ('PREPAYMENT','CREDIT')
             and run_req_id=v_run_id
             and round(nvl(pp_amount,0)) <> 0
             and vendor_id <> 9323
             --and round(pp_amount) <> 0
           ORDER BY VENDOR_ID,DAYS DESC ,INVOICE_ID) LOOP
           
FOR J IN (select invoice_id ,
                 VENDOR_ID,
                 SUPPLIER_NUMBER,
                 invoice_type,
                 --OUTSTANDING_AMT_FUNC_T,
                 --OUTSTANDING_AMT_FUNC_02,
                 DAYS,
                -- NVL(ADDJ_OUTS_BAL,0) ADDJ_OUTS_BAL,
                 nvl(pp_amount,0) pp_amount,
                 nvl(si_amount,0) si_amount,
                 run_req_id
            from lpti_ap_open_item_wise_os
           where invoice_type IN ('STANDARD')
             and run_req_id=v_run_id
             AND VENDOR_ID=I.VENDOR_ID
             and round(nvl(si_amount,0)) <> 0
             and vendor_id <> 9323
             --and round(si_amount) <> 0
             and rownum=1
           ORDER BY DAYS DESC ,INVOICE_ID )   LOOP

--V_BAL_AMOUNT;

-- FOR SI----

v_si_amount:=j.si_amount;
v_pp_amount:=i.pp_amount;

if abs(v_pp_amount) < abs(v_si_amount) and abs(v_pp_amount)>0 then

update lpti_ap_open_item_wise_os l
set 
l.si_amount=v_pp_amount+v_si_amount,
l.pp_amount=0,
ref_inv_id=j.invoice_id
where l.vendor_id=i.vendor_id
and l.invoice_id=i.invoice_id
and l.run_req_id=i.run_req_id
and vendor_id <> 9323;
v_si_amount:=v_pp_amount+v_si_amount;
v_pp_amount:=0;
commit;

--*************************************
update lpti_ap_open_item_wise_os kk
set kk.si_amount=v_si_amount,
kk.pp_amount=v_pp_amount
where kk.invoice_id=j.invoice_id
and vendor_id <> 9323;
--*************************************
commit;
--insert into test (text,SI_ADJ) values ('1-'||j.invoice_id,v_si_amount); 
exit;

elsif abs(v_pp_amount) > abs(v_si_amount) and abs(v_si_amount) >0 then

update lpti_ap_open_item_wise_os l
set l.si_amount=0,
l.pp_amount=v_pp_amount+v_si_amount,
ref_inv_id=i.invoice_id
where l.vendor_id=i.vendor_id
and l.invoice_id=j.invoice_id
and l.run_req_id=i.run_req_id
and vendor_id <> 9323;
v_pp_amount:=v_pp_amount+v_si_amount;
v_si_amount:=0;
commit;

--*************************************
update lpti_ap_open_item_wise_os kk
set kk.si_amount=v_si_amount,
kk.pp_amount=v_pp_amount
where kk.invoice_id=i.invoice_id
and kk.run_req_id=i.run_req_id
and vendor_id <> 9323;
--*************************************
commit;

--insert into test (text) values ('2-'||i.invoice_id);

--elsif abs(i.pp_amount) = abs(j.si_amount) then
--update LPTI_AP_OPEN_ITEM_31MAR2015 l
--set l.si_amount=0,
--l.pp_amount=0,
--ref_inv_id=j.invoice_id
--where l.vendor_id=i.vendor_id
--and l.invoice_id=j.invoice_id;
--commit;
--insert into test (text) values ('3');
end if;


commit;
END LOOP;

END LOOP;
  
commit;

----after runing the below procedure  run the below script------

UPDATE lpti_ap_open_item_wise_os
SET PP_AMOUNT=0
where SI_amount=0
and invoice_type='STANDARD'
and run_req_id=v_run_id
AND REF_INV_ID IS NOT NULL
and vendor_id <> 9323;

commit;

UPDATE lpti_ap_open_item_wise_os
SET SI_AMOUNT=0
where pp_amount=0
and invoice_type IN ('CREDIT','PREPAYMENT')
and run_req_id=v_run_id
AND REF_INV_ID IS NOT NULL
and vendor_id <> 9323;

commit;


----after runing the below procedure  run the below script------


--query to fetch the data for final statment



--SELECT 
--aa.vendor_id,
--aa.SUPPLIER_NUMBER,
--aa.SUPPLIER_Name,
--sum(nvl(aa.pp_amount,0))+sum(nvl(aa.si_amount,0)) remaining_amount,
--aa.invoice_id,
--aa.invoice_num ,
--(select api.gl_date from ap_invoices_all@appsprod_dblink api where api.invoice_id=aa.invoice_id) gl_date,
--(select api.invoice_date from ap_invoices_all@appsprod_dblink api where api.invoice_id=aa.invoice_id) invoice_date,
--aa.days
--FROM lpti_ap_open_item_31mar2015_02 aa
--where aa.vendor_id in (select bb.vendor_id from xx_vendor_id bb where bb.vendor_id=aa.vendor_id)
--group by aa.invoice_id,aa.vendor_id,aa.SUPPLIER_NUMBER,
--aa.SUPPLIER_Name,aa.invoice_num,aa.days
--having sum(nvl(aa.pp_amount,0))+sum(nvl(aa.si_amount,0)) <> 0
--order by remaining_amount desc


end;
/
