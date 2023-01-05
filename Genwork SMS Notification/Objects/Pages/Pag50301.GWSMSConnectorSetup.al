//Created: 14/01/23 by Rajesh(rajesh.gan@3ktechnologies.com)
//Description: This ia a new Page "GW SMS Connector Setup"
page 50301 "GW SMS Connector Setup"
{
    Caption = 'SMS Connector Setup';
    PageType = Card;
    SourceTable = "GW SMS Connector Setup";
    UsageCategory = Administration;
    ApplicationArea = ALL;

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                field("SMS URL"; Rec."SMS URL")
                {
                    ApplicationArea = All;
                }
                field("Auth Key"; Rec."Auth Key")
                {
                    ApplicationArea = All;
                }
                group("New Access Token")
                {
                    Caption = 'Access Token';

                    field(NewAccessToken; AccessToken)
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        MultiLine = true;
                        ShowCaption = false;
                        Editable = false;

                        ToolTip = 'Specifies the value of the Access Token field.';

                        trigger OnValidate()
                        begin
                            Rec.SetAccessToken(AccessToken);
                        end;
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.reset;
        IF Rec.IsEmpty THEN begin
            Rec.Init();
            rec.insert();
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        AccessToken := Rec.GetAccessToken();
    end;

    var
        AccessToken: Text;
}
