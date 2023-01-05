//Created: 14/01/23 by Rajesh(rajesh.gan@3ktechnologies.com)
//Description: This ia a new Table "GW SMS Connector Setup"
table 50301 "GW SMS Connector Setup"
{
    Caption = 'SMS Connector Setup';
    DataClassification = ToBeClassified;
    DrillDownPageId = "GW SMS Connector Setup";
    LookupPageId = "GW SMS Connector Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "SMS URL"; Text[250])
        {
            Caption = 'SMS URL';

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "SMS URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("SMS URL");
            end;
        }
        field(3; "Access Token"; Blob)
        {
            Caption = 'Access Token';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Auth Key"; Text[250])
        {
            Caption = 'Auth Key';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Flow Id"; Text[250])
        {
            Caption = 'Flow Id';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    local procedure CheckAndAppendURLPath(var value: Text)
    begin
        if value <> '' then
            if value[1] <> '/' then
                value := '/' + value;
    end;

    procedure SetAccessToken(NewToken: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Access Token");
        "Access Token".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(NewToken);
        Modify();
    end;

    procedure GetAccessToken() AccessToken: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Access Token");
        "Access Token".CreateInStream(InStream, TEXTENCODING::UTF8);
        if not TypeHelper.TryReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator(), AccessToken) then Message(ReadingDataSkippedMsg, FieldCaption("Access Token"));
    end;

    Var
        ReadingDataSkippedMsg: Label 'Loading field %1 will be skipped because there was an error when reading the data.\To fix the current data, contact your administrator.\Alternatively, you can overwrite the current data by entering data in the field.', Comment = '%1=field caption';
}

