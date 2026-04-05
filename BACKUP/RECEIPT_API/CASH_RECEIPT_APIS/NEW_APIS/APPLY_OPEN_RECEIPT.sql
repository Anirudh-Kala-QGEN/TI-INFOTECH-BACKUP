DECLARE
    l_return_status VARCHAR2(1);
    l_msg_count NUMBER;
    l_msg_data VARCHAR2(240);
    p_count number := 0;
    l_application_ref_num VARCHAR2(30);
    l_receivable_application_id NUMBER;
    l_applied_rec_app_id NUMBER;
    l_acctd_amount_applied_from NUMBER;
    l_acctd_amount_applied_to VARCHAR2(30);
BEGIN
    -- 1) Set the applications context
    mo_global.init('AR');
    mo_global.set_policy_context('S','204');
    fnd_global.apps_initialize(1011902, 50559, 222,0);

   AR_RECEIPT_API_PUB.APPLY_OPEN_RECEIPT
   ( p_api_version => 1.0,
     p_init_msg_list => FND_API.G_TRUE,
     p_commit => FND_API.G_TRUE,
     p_validation_level => FND_API.G_VALID_LEVEL_FULL,
     x_return_status => l_return_status,
     x_msg_count => l_msg_count,
     x_msg_data => l_msg_data,
     p_amount_applied => -20.00,
     p_receipt_number => 'rct-api11',
     p_open_receipt_number => 'rct-api10',
     x_application_ref_num => l_application_ref_num,
     x_receivable_application_id => l_receivable_application_id,
     x_applied_rec_app_id => l_applied_rec_app_id,
     x_acctd_amount_applied_from => l_acctd_amount_applied_from,
     x_acctd_amount_applied_to => l_acctd_amount_applied_to);


    -- 3) Review the API output
    dbms_output.put_line('Status ' || l_return_status);
    dbms_output.put_line('Message count ' || l_msg_count);
    dbms_output.put_line('Receivable Application Id ' || l_receivable_application_id);

    if l_msg_count = 1 Then
       dbms_output.put_line('l_msg_data '|| l_msg_data);
    elsif l_msg_count > 1 Then
       loop
          p_count := p_count + 1;
          l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
          if l_msg_data is NULL Then
             exit;
          end if;
          dbms_output.put_line('Message ' || p_count ||'. '||l_msg_data);
       end loop;
    end if;
END;
/