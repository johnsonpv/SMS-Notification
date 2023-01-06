codeunit 50301 "GW SMS Entry Handler"
{
    trigger OnRun()
    var
        _SMSNotifyEntry: Record "GW SMS Notification Entry";
    begin
        ProcessEntries(_SMSNotifyEntry);
    end;

    procedure ProcessEntries(var SMSNotifyEntry: Record "GW SMS Notification Entry")
    var
        _SMSEntryExecuter: Codeunit "GW SMS Entry Executer";
        _TempSMSNotifyEntry: Record "GW SMS Notification Entry" temporary;
        _CounterAll: Integer;
        _Counter: Integer;
        _CounterOK: Integer;
        _CounterError: Integer;
        _CounterSkip: Integer;
        _Window: Dialog;
        _Text001: TextConst ENU = 'Sending Whse Notification. Please wait...\';
        _Text002: TextConst ENU = '@@@@@@@@@@@1@@@@@@@@@@@@';
        _Text003: TextConst ENU = 'Do you really want to send SMS/E-Mail?';
        _Text004: TextConst ENU = 'Process finished. %1 Successful, %2 with Error.';
    begin
        //  _TempSMSNotifyEntry.DELETEALL();
        IF GUIALLOWED THEN BEGIN
            IF NOT CONFIRM(_Text003) THEN
                EXIT;
            _Window.OPEN(_Text001 + _Text002);
        END;

        SMSNotifyEntry.SETRANGE(Active, TRUE);
        SMSNotifyEntry.SETFILTER("Created DateTime", '<%1', CURRENTDATETIME);
        _CounterAll := SMSNotifyEntry.COUNT + 1;
        _Counter := 1;
        IF SMSNotifyEntry.FINDSET(TRUE, FALSE) THEN
            REPEAT
                _Counter += 1;
                IF GUIALLOWED THEN
                    _Window.UPDATE(1, ROUND(10000 / _CounterAll * _Counter, 1));
                // _TempSMSNotifyEntry.SetCurrentKey("Entry No.");
                // _TempSMSNotifyEntry.SetRange("Entry No.", SMSNotifyEntry."Entry No.");
                //if not _TempSMSNotifyEntry.FindFirst() then begin
                if _SMSEntryExecuter.ProcessSMSEntry(SMSNotifyEntry) THEN
                    _CounterOK += 1
                else begin
                    _CounterError += 1;
                    //PrepareDataForResendLogEntry(SMSNotifyEntry, _TempSMSNotifyEntry)
                end;
            UNTIL SMSNotifyEntry.NEXT = 0;
        IF GUIALLOWED THEN BEGIN
            _Window.CLOSE;
            MESSAGE(_Text004, _CounterOK, _CounterError);
        END;
    END;

    LOCAL PROCEDURE PrepareDataForResendLogEntry(VAR _SMSNotifyEntry: Record "GW SMS Notification Entry"; VAR _TempSMSNotifyEntry: Record "GW SMS Notification Entry" temporary)
    BEGIN
        _TempSMSNotifyEntry := _SMSNotifyEntry;
        _TempSMSNotifyEntry.INSERT;
    END;

}
