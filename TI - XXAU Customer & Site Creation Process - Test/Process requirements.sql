Process Requirements
----------------------------------------
Responsibility: AUPL Reeivable Super User
----------------------------------------

Concurrent program
Program Name	:	TI - XXAU Customer & Site Creation Process - Test
Short Name 		: 	XXAU_CREATE_CUSTOMER_SITE
--------------------------------------------------

Executable
Name			:	XXAU_CREATE_CUSTOMER_SITE
Short Name		:	XXAU_CREATE_CUSTOMER_SITE
Execution File	:	XXAU_CREATE_CUSTOMER_SITE_PKG.MAIN
--------------------------------------------------

Pacakge
Package Body	:	XXAU_CREATE_CUSTOMER_SITE_PKG.pkb
Package Spec	:	XXAU_CREATE_CUSTOMER_SITE_PKG.pks
--------------------------------------------------


Columns Needed in Custom Tables 

Table Name			:	AU_CUSTOMER_MASTER_NEW
===============================================
ERP_ERR_MSG			:	VARCHAR2(4000)
ERP_PROCESS_FLAG	:	VARCHAR2(10)

Table Name			:	AU_CUSTOMER_SHIP_TO
===============================================
ERP_ERR_MSG			:	VARCHAR2(4000)
ERP_PROCESS_FLAG	:	VARCHAR2(10)
CCID				:	NUMBER

-----------------------------------------------