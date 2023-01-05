//Created: 14/01/23 by Rajesh(rajesh.gan@3ktechnologies.com)
//Description: This ia a new codeunit for API Event Subscription
codeunit 50302 "GW API EventSubscription"
{
    trigger OnRun()
    begin

    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Comment Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure GWSalesCommentLineOnAfterInsertEvent(var Rec: Record "Sales Comment Line"; RunTrigger: Boolean)
    begin
        if (not RunTrigger) AND (Rec.Comment = '') then
            exit;

        CreateSMSEntries(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Comment Line", 'OnAfterModifyEvent', '', false, false)]
    local procedure GWSalesCommentLineOnAfterModifyEvent(var Rec: Record "Sales Comment Line"; var xRec: Record "Sales Comment Line"; RunTrigger: Boolean)
    begin
        if (not RunTrigger) AND (Rec.Comment = '') then
            exit;

        CreateSMSEntries(Rec);
    end;

    local procedure CreateSMSEntries(var SalesCommentLine: Record "Sales Comment Line")
    var
        _SMSNotifyEntry: Record "GW SMS Notification Entry";
        _SMSJson: Text;
    begin
        _SMSNotifyEntry.INIT;

        _SMSNotifyEntry.INSERT(TRUE);

        _SMSNotifyEntry."Line No." := SalesCommentLine."Line No.";
        _SMSNotifyEntry."Created DateTime" := CURRENTDATETIME;
        GetSMSConnectorSetup();
        GetSalesHeader(SalesCommentLine."No.");
        _SMSJson := SMSToJson(SalesCommentLine);
        If _SMSJson <> '' then
            _SMSNotifyEntry.SetRequestJson(_SMSJson);

        _SMSNotifyEntry.active := true;
        _SMSNotifyEntry.Modify(true);
    end;

    local procedure SMSToJson(var _SalesCommentLine: Record "Sales Comment Line"): Text
    var
        _SMSObj: JsonObject;
        _SMSJson: Text;
    begin
        Clear(_SMSObj);
        _SMSObj.Add('flow_id', SMSConnectorSetup."Flow Id");
        _SMSObj.Add('short_url', '0');
        _SMSObj.Add('mobiles', Customer."Mobile Phone No.");
        _SMSObj.Add('var1', SalesHeader."Sell-to Customer Name");
        _SMSObj.Add('var2', 'Dated' + Format(SalesHeader."Order Date"));
        _SMSObj.Add('var3', _SalesCommentLine.Comment);
        _SMSObj.WriteTo(_SMSJson);
        exit(_SMSJson);
    end;

    local procedure GetSMSConnectorSetup();
    begin
        SMSConnectorSetup.GET;
    end;

    local procedure GetSalesHeader(DocumentNo: Code[20])
    begin
        Clear(SalesHeader);
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
    end;

    // local procedure GetCustomer(var CustNo: Code[20]): Text[30]
    // var
    //     Customer: Record Customer;
    //     MobileNo: Text[30];
    // begin
    //     if Customer.Get(CustNo) then begin
    //         if Customer."Mobile Phone No." <> '' then begin
    //             if (StrLen(Customer."Mobile Phone No.") <> 12) AND (StrPos(Customer."Mobile Phone No.", '91') = 1) then
    //                 MobileNo := '91' + Customer."Mobile Phone No."
    //             else
    //                 MobileNo := Customer."Mobile Phone No.";
    //         end else
    //             Error('%1 does not have mobile no.', Customer.Name);
    //     end;
    //     exit(MobileNo);
    // end;

    local procedure GetCustomer(CustNo: Code[20])
    begin
        Clear(Customer);
        Customer.Get(CustNo);
    end;

    procedure CreateAndSendEmail()
    var
        Recipients: List of [Text];
        Emailobj: Codeunit Email;
        EmailMsg: Codeunit "Email Message";
        TxtDefaultCCMailList: List of [Text];
        TxtDefaultBCCMailList: List of [Text];
        Body: Text;
        SalesNotificationMsg: Label 'Dear %1, <br><br> Your order dated %2 is %3 .<br><br> Thank You, <br> -GWH';
        SubjectMsg: Label 'Attention - Your Order Status ';
        _CurrentDateTime: DateTime;
    begin
        Recipients.add(SalesHeader."Sell-to E-Mail");
        Body := StrSubstNo(SalesNotificationMsg, SalesHeader."Sell-to Customer Name", SalesHeader."Order Date", '');
        EmailMsg.Create(Recipients, SubjectMsg, Body, true, TxtDefaultCCMailList, TxtDefaultBCCMailList);
        Emailobj.Send(EmailMsg, Enum::"Email Scenario"::Default);
    end;

    var
        SMSConnectorSetup: Record "GW SMS Connector Setup";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SMSConnectorSetupRead: Boolean;


}