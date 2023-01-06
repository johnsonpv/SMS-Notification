codeunit 50300 "GW SMS Entry Executer"
{
    TableNo = "GW SMS Notification Entry";
    trigger OnRun()
    begin
        Rec.TESTFIELD(Active, TRUE);
        Rec.TestField("Mobile No.");
        CheckMobileValidation(Rec);
        GetSMSConnectorSetup();
        SMSConnectorSetup.TestField("SMS URL");
        SMSConnectorSetup.TestField("Auth Key");
        SMSConnectorSetup.TestField("Flow Id");
        ExecuteSMSEntries(Rec);
    end;

    Procedure CheckMobileValidation(VAR _SMSNotifyEntry: Record "GW SMS Notification Entry")
    var
        Ch: Char;
        i: Integer;
        Vari: Variant;
    begin
        for i := 1 to StrLen(_SMSNotifyEntry."Mobile No.") do begin
            Ch := _SMSNotifyEntry."Mobile No."[i];
            vari := Ch;
            if not Vari.IsInteger then
                Error('%1 does not have valid mobile no.', _SMSNotifyEntry."Client Name");
        end;
        if (StrLen(_SMSNotifyEntry."Mobile No.") > 12) OR (StrLen(_SMSNotifyEntry."Mobile No.") < 10) OR (StrLen(_SMSNotifyEntry."Mobile No.") = 11) THEN
            Error('%1 does not have valid mobile no.', _SMSNotifyEntry."Client Name");

        if (StrLen(_SMSNotifyEntry."Mobile No.") = 10) THEN
            _SMSNotifyEntry."Mobile No." := '91' + _SMSNotifyEntry."Mobile No.";

        IF (StrPos(_SMSNotifyEntry."Mobile No.", '91') <> 1) then
            Error('%1 does not have valid mobile no.', _SMSNotifyEntry."Client Name");
    end;

    PROCEDURE ProcessSMSEntry(VAR _SMSNotifyEntry: Record "GW SMS Notification Entry"): Boolean;
    VAR
        _SMSNotifyEntry2: Record "GW SMS Notification Entry";
        _SMSEntryExecuter: Codeunit "GW SMS Entry Executer";
    BEGIN
        COMMIT;
        IF _SMSEntryExecuter.RUN(_SMSNotifyEntry) THEN BEGIN
            _SMSNotifyEntry.MODIFY;
            _SMSNotifyEntry2.GET(_SMSNotifyEntry."Entry No.");
            _SMSNotifyEntry2.Active := false;
            _SMSNotifyEntry2."Has Error" := false;
            _SMSNotifyEntry2."Error Message" := '';
            _SMSNotifyEntry2."Processed DateTime" := CurrentDateTime;
            _SMSNotifyEntry2."Response Status" := _SMSNotifyEntry2."Response Status"::Successful;
            _SMSNotifyEntry2.MODIFY(TRUE);
            COMMIT;
            EXIT(TRUE);
        END ELSE BEGIN
            _SMSNotifyEntry.MODIFY;
            _SMSNotifyEntry2.GET(_SMSNotifyEntry."Entry No.");
            //_SMSNotifyEntry2.Active := FALSE;
            _SMSNotifyEntry2."Has Error" := TRUE;
            _SMSNotifyEntry2."Error Message" := COPYSTR(GETLASTERRORTEXT, 1, MAXSTRLEN(_SMSNotifyEntry2."Error Message"));
            _SMSNotifyEntry2."Processed DateTime" := CurrentDateTime;
            _SMSNotifyEntry2."Response Status" := _SMSNotifyEntry2."Response Status"::Unsuccessful;
            _SMSNotifyEntry2.MODIFY(TRUE);
            COMMIT;
            EXIT(FALSE);
        END;
    END;



    local procedure ExecuteSMSEntries(VAR SMSNotifyEntry: Record "GW SMS Notification Entry")
    begin
        IF NOT SMSNotifyEntry."Is SMS Sent" THEN
            SendSMS(SMSNotifyEntry);
        IF NOT SMSNotifyEntry."Is E-mail Sent" THEN
            SendEmail(SMSNotifyEntry);
    end;

    local procedure SendSMS(VAR _SMSNotifyEntry: Record "GW SMS Notification Entry")
    var
        _DataJson: Text;
    begin
        _DataJson := _SMSNotifyEntry.SMSToJson(SMSConnectorSetup."Flow Id");
        InvokeHttpJSONRequest(_DataJson, _SMSNotifyEntry);
        _SMSNotifyEntry."Is SMS Sent" := true;
    end;

    procedure SendEmail(VAR _SMSNotifyEntry: Record "GW SMS Notification Entry")
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
        Recipients.add(_SMSNotifyEntry."E-mail");
        Body := StrSubstNo(SalesNotificationMsg, _SMSNotifyEntry."Client Name", _SMSNotifyEntry."Order Date", _SMSNotifyEntry.Comment);
        EmailMsg.Create(Recipients, SubjectMsg, Body, true, TxtDefaultCCMailList, TxtDefaultBCCMailList);
        Emailobj.Send(EmailMsg, Enum::"Email Scenario"::Default);
        _SMSNotifyEntry."Is E-mail Sent" := true;
    end;

    local procedure InvokeHttpJSONRequest(_DataJson: Text; var _SMSNotifyEntry: Record "GW SMS Notification Entry")
    var
        _HeaderJson: JsonObject;
        _RequestContent: HttpContent;
        _RequestTxt: Text;
    begin
        _RequestContent.WriteFrom(_DataJson);
        InvokeService(_DataJson, _RequestContent, _SMSNotifyEntry);
    end;

    local procedure InvokeService(_RequestJson: Text; _RequestContent: HttpContent; var _SMSNotifyEntry: Record "GW SMS Notification Entry")
    var
        _Client: HttpClient;
        _RequestHeaders: HttpHeaders;
        _ResponseMessage: HttpResponseMessage;
        _RequestMessage: HttpRequestMessage;
        _ContentHeaders: HttpHeaders;
        _ErrorMessage: Text;
        _Result: Boolean;
    begin
        _Client.Clear();
        _Client.Timeout(60000);
        _RequestHeaders.Clear();
        _RequestHeaders := _Client.DefaultRequestHeaders();
        _Client.DefaultRequestHeaders.Add('Authorization', StrSubstNo('Bearer %1', SMSConnectorSetup."Access Token"));
        _RequestContent.WriteFrom(_RequestJson);
        _RequestContent.GetHeaders(_ContentHeaders);
        _ContentHeaders.Clear();
        _ContentHeaders.Add('Content-Type', 'application/json');
        _ContentHeaders.Add('Accept', '*/*');
        _ContentHeaders.Add('Connection', 'keep-alive');
        _ContentHeaders.Add('authkey', SMSConnectorSetup."Auth Key");
        _Result := _Client.Post(SMSConnectorSetup."SMS Url", _RequestContent, _ResponseMessage);

        if not _Result then
            if _ResponseMessage.IsBlockedByEnvironment() then
                _ErrorMessage := StrSubstNo(EnvironmentBlocksErr, SMSConnectorSetup."SMS Url")
            else
                _ErrorMessage := StrSubstNo(ConnectionErr, SMSConnectorSetup."SMS Url");

        if _ErrorMessage <> '' then
            Error(_ErrorMessage);

        ProcessHttpResponseMessage(_ResponseMessage);
    end;


    local procedure ProcessHttpResponseMessage(ResponseMessage: HttpResponseMessage)
    var
        ResponseJObject: JsonObject;
        ContentJObject: JsonObject;
        JToken: JsonToken;
        ResponseText: Text;
        JsonResponse: Boolean;
        StatusCode: Integer;
        StatusReason: Text;
        StatusDetails: Text;
        Result: Boolean;
        HttpError: Text;
    begin
        Result := ResponseMessage.IsSuccessStatusCode();
        StatusCode := ResponseMessage.HttpStatusCode();
        StatusReason := ResponseMessage.ReasonPhrase();

        if ResponseMessage.Content().ReadAs(ResponseText) then
            JsonResponse := ContentJObject.ReadFrom(ResponseText);

        if not Result then begin
            HttpError := StrSubstNo('HTTP error %1 (%2)', StatusCode, StatusReason);
            if JsonResponse then
                if ContentJObject.SelectToken('error_description', JToken) then begin
                    StatusDetails := JToken.AsValue().AsText();
                    HttpError += StrSubstNo('\%1', StatusDetails);
                end;
        end;

        IF HttpError <> '' then
            Error(HttpError);
    end;

    local procedure CreateBasicAuthHeader(_UserName: Text; _Password: Text): Text
    Var
        _TempBlob: Codeunit "Temp Blob";
        _lOutStream: OutStream;
        _InStream: InStream;
        _MyBase64String: Text;
        _Base64Convert: Codeunit "Base64 Convert";
    begin
        _TempBlob.CreateOutStream(_lOutStream);
        _lOutStream.WriteText(StrSubstNo('%1:%2', _UserName, _Password));
        _TempBlob.CreateInStream(_InStream, TextEncoding::UTF8);
        _MyBase64String := _Base64Convert.ToBase64(_InStream);
        Exit(StrSubstNo('Basic %1', _MyBase64String));
        //Exit(StrSubstNo('Basic %1', 'cmFiYml0bXEtYXBpLXVzZXItc3RnQHR5cmVzYWxlcy5jb20uYXU6VkVIRDhlcHptVHkzNkNaOQ=='));
    end;

    local procedure GetSMSConnectorSetup();
    begin
        SMSConnectorSetup.GET;
    end;


    var
        SMSConnectorSetup: Record "GW SMS Connector Setup";
        EnvironmentBlocksErr: Label 'Environment blocks an outgoing HTTP request to ''%1''.', Comment = '%1 - url, e.g. https://microsoft.com';
        ConnectionErr: Label 'Connection to the remote service ''%1'' could not be established.', Comment = '%1 - url, e.g. https://microsoft.com';
}
