codeunit 50303 "GW SMS OnInstall App"
{
    Subtype = Install;
    trigger OnRun()
    begin

    end;

    trigger OnInstallAppPerCompany();
    begin
        InsertIntegrationSetup();
        CreateJobQueue();
    end;

    local procedure InsertIntegrationSetup()
    var
        _SMSConnectorSetup: Record "GW SMS Connector Setup";
        _SMSURLtxt: TextConst ENU = '';
        _SMSFLowId: TextConst ENU = '';
        _SMSAuthKey: TextConst ENU = '';

    begin
        IF NOT _SMSConnectorSetup.GET THEN BEGIN
            _SMSConnectorSetup.Init();
            _SMSConnectorSetup.INSERT(TRUE);
        END;
        _SMSConnectorSetup.VALIDATE("SMS URL", _SMSURLtxt);
        _SMSConnectorSetup."Flow Id" := _SMSFLowId;
        _SMSConnectorSetup."Auth Key" := _SMSAuthKey;
        _SMSConnectorSetup.Modify(TRUE);
    end;

    local procedure CreateJobQueue();
    var
        _JobQueueEntry: Record "Job Queue Entry";
    begin
        WITH _JobQueueEntry DO BEGIN
            Reset();
            SetRange("Object ID to Run", Codeunit::"GW SMS Entry Handler");
            SETRANGE("Object Type to Run", "Object Type to Run"::Codeunit);
            IF not FINDFIRST THEN begin
                INIT;
                VALIDATE("Object Type to Run", "Object Type to Run"::Codeunit);
                VALIDATE("Object ID to Run", Codeunit::"GW SMS Entry Handler");
                Validate(Description, 'Send Sales Order Info Via SMS/Email');
                VALIDATE("Run on Mondays", TRUE);
                VALIDATE("Run on Tuesdays", TRUE);
                VALIDATE("Run on Wednesdays", TRUE);
                VALIDATE("Run on Thursdays", TRUE);
                VALIDATE("Run on Fridays", TRUE);
                VALIDATE("Run on Saturdays", TRUE);
                VALIDATE("Run on Sundays", TRUE);
                VALIDATE("No. of Minutes between Runs", 5);
                VALIDATE("Maximum No. of Attempts to Run", 3);
                INSERT(TRUE);
                SetStatus(Status::"On Hold");
            END;
        END;
    end;
}
