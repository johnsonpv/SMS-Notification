//Created: 14/01/23 by Rajesh(rajesh.gan@3ktechnologies.com)
//Description: This ia a new codeunit for API Event Subscription
codeunit 50302 "GW SMS EventSubscription"
{
    trigger OnRun()
    begin

    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Comment Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure GWSalesCommentLineOnAfterInsertEvent(var Rec: Record "Sales Comment Line"; RunTrigger: Boolean)
    begin
        if (not RunTrigger) then
            exit;
        IF Rec."Document Type" <> rec."Document Type"::Order then
            exit;
        IF (Rec.Comment = '') then
            exit;

        CreateSMSEntries(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Comment Line", 'OnAfterModifyEvent', '', false, false)]
    local procedure GWSalesCommentLineOnAfterModifyEvent(var Rec: Record "Sales Comment Line"; var xRec: Record "Sales Comment Line"; RunTrigger: Boolean)
    begin
        if (not RunTrigger) then
            exit;
        IF Rec."Document Type" <> rec."Document Type"::Order then
            exit;
        IF (Rec.Comment = '') then
            exit;

        CreateSMSEntries(Rec);
    end;

    local procedure CreateSMSEntries(var SalesCommentLine: Record "Sales Comment Line")
    var
        _SMSNotifyEntry: Record "GW SMS Notification Entry";
    begin
        _SMSNotifyEntry.INIT;
        _SMSNotifyEntry.INSERT(TRUE);
        _SMSNotifyEntry."Document No." := SalesCommentLine."No.";
        _SMSNotifyEntry."Line No." := SalesCommentLine."Line No.";
        _SMSNotifyEntry.Comment := SalesCommentLine.Comment;
        GetSMSConnectorSetup();
        GetSalesHeader(SalesCommentLine."No.");
        GetCustomer(SalesHeader."Sell-to Customer No.");
        _SMSNotifyEntry."Customer No." := Customer."No.";
        _SMSNotifyEntry."Mobile No." := Customer."Mobile Phone No.";
        _SMSNotifyEntry."E-mail" := Customer."E-Mail";
        _SMSNotifyEntry."Order Date" := SalesHeader."Order Date";
        _SMSNotifyEntry."Client Name" := SalesHeader."Sell-to Customer Name";
        _SMSNotifyEntry.active := true;
        _SMSNotifyEntry."Is SMS Sent" := false;
        _SMSNotifyEntry."Is E-mail Sent" := false;
        _SMSNotifyEntry."Created DateTime" := CURRENTDATETIME;
        _SMSNotifyEntry.Modify(true);
    end;



    local procedure GetSMSConnectorSetup();
    begin
        SMSConnectorSetup.GET();
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



    var
        SMSConnectorSetup: Record "GW SMS Connector Setup";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SMSConnectorSetupRead: Boolean;


}