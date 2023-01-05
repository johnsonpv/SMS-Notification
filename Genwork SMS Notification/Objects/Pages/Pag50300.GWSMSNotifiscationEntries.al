//Created: 13/01/23 by Rajesh(rajesh.gan@3ktechnologies.com)
//Description: This ia a new table "GW SMS Notification Entries"
page 50300 "GW SMS Notifiscation Entries"
{
    ApplicationArea = All;
    Caption = 'SMS Notification Entries';
    PageType = List;
    SourceTable = "GW SMS Notification Entry";
    SourceTableView = order(descending);
    UsageCategory = Lists;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = False;
    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                }
                field("Description"; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(active; Rec.active)
                {
                    ApplicationArea = All;
                }
                field("Has Error"; Rec."Has Error")
                {
                    ApplicationArea = All;
                }
                field("Response Status"; Rec."Response Status")
                {
                    ApplicationArea = All;
                }
                field("Has Payload"; Rec."Payload Json".HasValue)
                {
                    ApplicationArea = All;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                }
                field("Created DateTime"; Rec."Created DateTime")
                {
                    ApplicationArea = All;
                }
                field("Processed DateTime"; Rec."Processed DateTime")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(Process)
            {
                ApplicationArea = All;
                Caption = 'Process';
                Promoted = true;
                PromotedIsBig = true;
                Image = Process;
                PromotedCategory = Process;
                trigger OnAction()
                Var
                    _SMSNotifyEntry: record "GW SMS Notification Entry";
                    _Text000: TextConst ENU = 'Process all, Process only selected';
                    _SMSEntryHandler: Codeunit "GW SMS Entry Handler";
                    _Selection: Integer;
                begin
                    _Selection := STRMENU(_Text000, 2);
                    CASE _Selection OF
                        0:
                            EXIT;
                        1:
                            _SMSNotifyEntry.COPYFILTERS(Rec);
                        2:
                            BEGIN
                                _SMSNotifyEntry.COPY(Rec);
                                CurrPage.SETSELECTIONFILTER(_SMSNotifyEntry);
                            END;
                    END;
                    _SMSEntryHandler.ProcessEntries(_SMSNotifyEntry);
                    CurrPage.UPDATE(TRUE);
                end;
            }
            Group("Delete Log Entries")
            {
                action(Delete7Days)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Delete Entries Older Than 7 Days';
                    Ellipsis = true;
                    Image = ClearLog;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Clear the list of log enties that are older than 7 days.';
                    trigger OnAction()
                    begin
                        Rec.DeleteEntries(7);
                    end;
                }
                action(Delete60Days)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Delete Entries Older Than 60 Days';
                    Ellipsis = true;
                    Image = ClearLog;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Clear the list of log enties that are older than 60 days.';
                    trigger OnAction()
                    begin
                        Rec.DeleteEntries(60);
                    end;
                }
                action(Delete0Days)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Delete All Entries';
                    Ellipsis = true;
                    Image = ClearLog;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Clear the list of all log enties.';
                    trigger OnAction()
                    begin
                        Rec.DeleteEntries(0);
                    end;
                }
            }
        }
    }
}
