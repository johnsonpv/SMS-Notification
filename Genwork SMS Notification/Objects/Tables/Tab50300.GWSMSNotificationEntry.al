//Created: 13/01/23 by Rajesh(rajesh.gan@3ktechnologies.com)
//Description: This ia a new table "GW SMS Notification Entry"
table 50300 "GW SMS Notification Entry"
{
    Caption = 'SMS/E-mail Notification Entry';
    LookupPageId = "GW SMS Notifiscation Entries";
    DrillDownPageId = "GW SMS Notifiscation Entries";
    DataClassification = ToBeClassified;
    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = ToBeClassified;
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = ToBeClassified;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = ToBeClassified;
        }
        field(4; "Created DateTime"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Error Message"; text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(6; "Response Status"; Option)
        {
            OptionMembers = ,Successful,Unsuccessful;
            DataClassification = ToBeClassified;
        }
        field(7; "Payload Json"; Blob)
        {
            DataClassification = ToBeClassified;
        }
        field(8; "Processed DateTime"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(9; active; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Has Error"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(11; "Description"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(12; "Customer No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(13; "Order Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(14; "Mobile No."; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(15; "E-mail"; Text[80])
        {
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
    trigger OnInsert()
    begin
        IF "Entry No." = 0 THEN
            "Entry No." := GetNextEntryNo;
    end;

    PROCEDURE GetNextEntryNo() _NextEntryNo: Integer;
    VAR
        _SMSNotifyEntry: Record "GW SMS Notification Entry";
    BEGIN
        _SMSNotifyEntry.LOCKTABLE;
        IF _SMSNotifyEntry.FINDLAST THEN
            _NextEntryNo := _SMSNotifyEntry."Entry No." + 1
        ELSE
            _NextEntryNo := 1;
    END;

    procedure GetRequestJson(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        TempBlob.FromRecord(Rec, FieldNo("Payload Json"));
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator));
    end;

    procedure SetRequestJson(StreamText: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Payload Json");
        "Payload Json".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.Write(StreamText);
        if Modify(true) then;
    end;

    procedure DeleteEntries(DaysOld: Integer)
    var
        Isexist: Boolean;
    begin
        If not Confirm(Text001) then
            exit;
        Window.open(DeletingMsg);
        IF DaysOld > 0 then
            SETFILTER("Created DateTime", '<=%1', CreateDateTime((TODAY - DaysOld), 0T));
        Isexist := not Rec.IsEmpty;

        DeleteAll();
        Window.Close();
        SetRange("Created DateTime");
        if Isexist then
            Message(DeletedMsg)
        else
            Message(DeletedMsg2);
    end;

    var
        Text001: TextConst ENU = 'you sure that you want to delete SMS/E-Mail Notification Entries?';
        DeletingMsg: TextConst ENU = 'Deleting Entries...';
        DeletedMsg: TextConst ENU = 'Entries have been deleted.';
        DeletedMsg2: TextConst ENU = 'Entries are not there during duration.';
        Window: Dialog;
}
