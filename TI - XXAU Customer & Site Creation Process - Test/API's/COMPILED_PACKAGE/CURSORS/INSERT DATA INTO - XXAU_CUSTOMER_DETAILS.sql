INSERT INTO aucustom.xxau_customer_details@ebstohr (
unit,
unit_name,
customer_name,
customer_class,
customer_type,
address1,
address2,
address3,
address4,
state,
city,
pincode,
country,
county,
station_name,
account_description,
location1,
rec_account,
mobile_no,
contact_person,
payment_terms,
primary_site_falg,
gstin,
pan,
third_party_sate_code,
process_flag,
error_msz,
third_party_reg_flag,
old_party_id,
old_customer_id,
agency_id,
centre_number,
abc_type,
creation_date
)
SELECT
	tt4.organization_code,
	tt4.org_name,
	tt.agency_name,
	NULL                                                                                             customer_class,
	decode(tt.prouct_name, 'Amar Ujala - Variant', 'Circulation Customers', 'Amar Ujala', 'Circulation Customers',
		   'Amar Ujala - Udaan', 'Udaan Customers', 'Amar Ujala - Safalta', 'NEW SAFALTA CUSTOMERS') customer_type,
	nvl((
		SELECT
			address
		FROM
			aucustom.au_customer_master_advance@ebstohr
		WHERE
				agency_id = tt.agency_id
			AND inv_org = tt.inv_org
	),(
		SELECT
			address
		FROM
			aucustom.au_customer_master_occupa@ebstohr
		WHERE
				agency_id = tt.agency_id
			AND inv_org = tt.inv_org
	))                                                                                               address,
	NULL                                                                                             address2,
	NULL                                                                                             address3,
	NULL                                                                                             address4,
	tt3.state,
	tt3.city,
	tt3.postal_code,
	'INDIA'                                                                                          country,
	tt3.district,
	tt3.name_of_centre                                                                               station_name,
	tt5.drop_point                                                                                   account_description,
	tt3.name_of_centre                                                                               location1,
	tt4.organization_code
	|| '.9999.'
	|| tt4.organization_code
	|| '.102.205110.'
	|| tt3.dak_code
	|| '.999.999.999.999'                                                                            rec_account,
	nvl((
		SELECT
			mobile_no
		FROM
			aucustom.au_customer_master_advance@ebstohr
		WHERE
				agency_id = tt.agency_id
			AND inv_org = tt.inv_org
	),(
		SELECT
			mobile_no
		FROM
			aucustom.au_customer_authorise_per@ebstohr
		WHERE
				agency_id = tt.agency_id
			AND inv_org = tt.inv_org
	))                                                                                               mobile_no,
	nvl((
		SELECT
			entity_name
		FROM
			aucustom.au_customer_master_advance@ebstohr
		WHERE
				agency_id = tt.agency_id
			AND inv_org = tt.inv_org
	),(
		SELECT
			entity_name
		FROM
			aucustom.au_customer_authorise_per@ebstohr
		WHERE
				agency_id = tt.agency_id
			AND inv_org = tt.inv_org
	))                                                                                               contact_person,
	'Immediate '                                                                                     payment_term,
	decode(tt3.primary_flag, 'Y', 'YES', 'NO')                                                       primary_flag,
	'Unregistered'                                                                                   gstin,
	nvl((
		SELECT
			pan
		FROM
			aucustom.au_customer_master_advance@ebstohr
		WHERE
				agency_id = tt.agency_id
			AND inv_org = tt.inv_org
	),(
		SELECT
			pan
		FROM
			aucustom.au_customer_authorise_per@ebstohr
		WHERE
				agency_id = tt.agency_id
			AND inv_org = tt.inv_org
	))                                                                                               pan,
	(
		SELECT
			state_code
		FROM
			aucustom.xxau_agency_state@ebstohr
		WHERE
			description = tt3.state
	)                                                                                                third_party_sate_code
	,
	'N',
	NULL,
	'N',
	decode(tt.prouct_name, 'Amar Ujala - Udaan', tt3.erp_party_id, 'Amar Ujala - Safalta', tt3.erp_party_id,
		   tt5.erp_party_id)                                                                         erp_party_id,
	decode(tt.prouct_name, 'Amar Ujala - Udaan', tt3.erp_customer_id, 'Amar Ujala - Safalta', tt3.erp_customer_id,
		   tt5.erp_customer_id)                                                                      erp_customer_id,
	tt3.agency_id,
	tt3.centre_number,
	decode(tt5.agency_area_type, 'D.Hq UPC', 2, 1)                                                   abc_audit,
	sysdate
FROM
	aucustom.xxau_agency_approval_detials@ebstohr tt,
	aucustom.au_customer_ship_to@ebstohr          tt3,
	aucustom.xxau_inv_organization@ebstohr        tt4,
	aucustom.au_customer_master_new@ebstohr       tt5
WHERE
		tt.agency_id = tt3.agency_id
	AND tt.inv_org = tt3.inv_org
	AND tt3.inv_org = tt4.inv_org_id
	AND tt.centre_number = tt3.centre_number
	AND tt.inv_org = tt5.inv_org
	AND tt.agency_id = tt5.agency_id
	AND tt.inv_org = tt3.inv_org
	AND tt.approve_reject = 'A'
	AND tt.agency_id = NVL(p_agency_id, tt.agency_id)
--             AND tt.agency_id = 6074637
	AND nvl(tt3.approve_flag, 'N') = 'N'
	AND tt3.erp_site_use_id IS NULL
	AND NOT EXISTS (
		SELECT
			'Y'
		FROM
			aucustom.xxau_customer_details@ebstohr
		WHERE
				agency_id = tt3.agency_id
			AND centre_number = tt3.centre_number
	)
	AND sysdate BETWEEN tt3.effective_start_date AND tt3.effective_end_date
	AND sysdate BETWEEN tt5.effective_start_date AND tt5.effective_end_date;