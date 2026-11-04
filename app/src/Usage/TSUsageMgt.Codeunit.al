namespace Origo.Bifrost.Timesheets;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;

/// <summary>Owns usage authorization, validation and transaction dispatch.</summary>
codeunit 10036850 "TS Usage Mgt ori"
{
    Access = Internal;
    var
        InvalidKeyLbl: Label 'The value for %1 is missing or invalid.', Comment = '%1 = request key; is-IS=Gildið fyrir %1 vantar eða er ógilt.';
        UnknownKeyLbl: Label 'Unknown request key: %1.', Comment = '%1 = request key; is-IS=Óþekktur beiðnilykill: %1.';
        PermissionLbl: Label 'The caller cannot perform this usage operation.', Comment = 'is-IS=Kallandinn má ekki framkvæma þessa notkunaraðgerð.';
        StateLbl: Label 'The usage line is not in the required state for %1.', Comment = '%1 = operation; is-IS=Notkunarlínan er ekki í réttri stöðu fyrir %1.';
        NextStepLbl: Label 'Correct the named key and permissions, then retry the dedicated Timesheets.Usage message.', Comment = 'is-IS=Leiðréttu tilgreindan lykil og heimildir og reyndu aftur með sértækum Timesheets.Usage skilaboðum.';

    /// <summary>Checks direct permissions without granting indirect write access.</summary>
    procedure IsEnabled(Operation: Text): Boolean
    var
        Usage: Record "TS Usage Line ori";
        Header: Record "Time Sheet Header";
        Line: Record "Time Sheet Line";
        Resource: Record Resource;
        Item: Record Item;
    begin
        if not (Usage.ReadPermission() and Header.ReadPermission() and Line.ReadPermission()) then
            exit(false);
        if Operation = 'List' then
            exit(true);
        exit(Usage.WritePermission() and Resource.ReadPermission() and Item.ReadPermission());
    end;

    /// <summary>Runs writes in an isolated runner and maps failures to structured refusals.</summary>
    procedure Execute(var Argument: Record "Message Argument ori"; Operation: Text)
    var
        Context: Codeunit "TS Usage Context ori";
        Failure: Text;
    begin
        if not IsEnabled(Operation) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PermissionDenied, PermissionLbl, '', '', '', NextStepLbl);
            exit;
        end;
        if (Operation <> 'List') and Argument."Omit Commit" then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PreconditionFailed, StateLbl, 'omitCommit', '', '', NextStepLbl);
            exit;
        end;
        Context.Initialize(Operation, Argument.GetRequestJson());
        if Operation = 'List' then begin
            // List never commits the caller's work. Parsing errors are caught by the read-only runner.
            if not ReadList() then begin
                Failure := GetLastErrorText();
                Argument.RespondWithError(Context.GetErrorCode(), Failure, Context.GetParameter(), '', '', NextStepLbl);
            end else
                Argument.SetResponseJson(Context.GetResponse());
            Context.Reset();
            exit;
        end;
        if Database.IsInWriteTransaction() then
            Commit();
        if not Codeunit.Run(Codeunit::"TS Usage Runner ori") then begin
            Failure := GetLastErrorText();
            Argument.RespondWithError(Context.GetErrorCode(), Failure, Context.GetParameter(), '', '', NextStepLbl);
        end else
            Argument.SetResponseJson(Context.GetResponse());
        Context.Reset();
    end;

    [TryFunction]
    local procedure ReadList()
    begin
        ApplyRequest();
    end;

    /// <summary>Validates and executes the request inside its authorized transaction.</summary>
    procedure ApplyRequest()
    var
        Usage: Record "TS Usage Line ori";
        Context: Codeunit "TS Usage Context ori";
        Operation: Text;
        Request: JsonObject;
        Response: JsonObject;
    begin
        Operation := Context.GetOperation();
        Request := Context.GetRequest();
        CheckKeys(Request, Operation);
        if not IsEnabled(Operation) then
            Refuse("Bifrost Error Code ori"::PermissionDenied, '', PermissionLbl);
        if (Operation = 'Transfer') and Request.Contains('entryNos') then begin
            TransferSelection(Request, Response);
            Context.SetResponse(Response);
            exit;
        end;
        case Operation of
            'Register':
                Register(Request, Usage);
            'List': begin
                ListUsage(Request, Response);
                Context.SetResponse(Response);
                exit;
            end;
            else begin
                Usage.ReadIsolation := IsolationLevel::UpdLock;
                if not Usage.Get(ReadInteger(Request, 'entryNo', true)) then
                    Invalid('entryNo');
                case Operation of
                    'Submit':
                        Submit(Usage);
                    'Approve', 'Reject':
                        Decide(Usage, Request, Operation = 'Reject');
                    'Transfer':
                        Transfer(Usage, Request);
                    'Reverse':
                        Reverse(Usage, Request);
                    else
                        Invalid('operation');
                end;
            end;
        end;
        Response.Add('status', 'Success');
        Response.Add('line', ToJson(Usage));
        Context.SetResponse(Response);
    end;

    local procedure Register(Request: JsonObject; var Usage: Record "TS Usage Line ori")
    var
        Header: Record "Time Sheet Header";
        Line: Record "Time Sheet Line";
        Resource: Record Resource;
        Item: Record Item;
        Kind: Text;
    begin
        Header.ReadIsolation := IsolationLevel::UpdLock;
        if not Header.Get(ReadCode(Request, 'timeSheetNo', 20, true)) then
            Invalid('timeSheetNo');
        CheckOwner(Header);
        Line.ReadIsolation := IsolationLevel::UpdLock;
        if not Line.Get(Header."No.", ReadInteger(Request, 'lineNo', true)) then
            Invalid('lineNo');
        Usage.Init();
        Usage."Time Sheet No." := Header."No.";
        Usage."Time Sheet Line No." := Line."Line No.";
        Usage."Resource No." := Header."Resource No.";
        Usage."Owner User ID" := Header."Owner User ID";
        Kind := ReadText(Request, 'type', 20, true);
        case Kind of
            'Item':
                Usage.Type := Usage.Type::Item;
            'Resource':
                Usage.Type := Usage.Type::Resource;
            else
                Invalid('type');
        end;
        Usage."No." := ReadCode(Request, 'no', 20, true);
        Usage.Description := CopyStr(ReadText(Request, 'description', 100, false), 1, MaxStrLen(Usage.Description));
        Usage."Unit of Measure" := CopyStr(ReadCode(Request, 'unitOfMeasure', 10, false), 1, 10);
        if Usage.Type = Usage.Type::Item then begin
            if not Item.Get(Usage."No.") then
                Invalid('no');
            if Item.Blocked then
                Invalid('no');
            if Usage."Unit of Measure" = '' then
                Usage."Unit of Measure" := Item."Base Unit of Measure";
            if Usage.Description = '' then
                Usage.Description := Item.Description;
        end else begin
            if not Resource.Get(Usage."No.") then
                Invalid('no');
            if Resource.Blocked then
                Invalid('no');
            if Usage."Unit of Measure" = '' then
                Usage."Unit of Measure" := Resource."Base Unit of Measure";
            if Usage.Description = '' then
                Usage.Description := Resource.Name;
        end;
        Usage.Date := ReadDate(Request, 'date', true);
        if (Usage.Date < Header."Starting Date") or (Usage.Date > Header."Ending Date") then
            Invalid('date');
        Usage.Quantity := ReadDecimal(Request, 'quantity', true);
        if Usage.Quantity <= 0 then
            Invalid('quantity');
        Usage.Status := Usage.Status::Open;
        Usage.Insert(true);
    end;

    local procedure CheckOwner(Header: Record "Time Sheet Header")
    var
        Resource: Record Resource;
    begin
        if (Header."Owner User ID" = '') or (Header."Owner User ID" <> UpperCase(UserId())) then
            Refuse("Bifrost Error Code ori"::PermissionDenied, 'timeSheetNo', PermissionLbl);
        if not Resource.Get(Header."Resource No.") then
            Invalid('timeSheetNo');
        if (Resource."Time Sheet Owner User ID" <> Header."Owner User ID") or Resource.Blocked then
            Refuse("Bifrost Error Code ori"::PermissionDenied, 'timeSheetNo', PermissionLbl);
    end;

    local procedure Submit(var Usage: Record "TS Usage Line ori")
    var
        Header: Record "Time Sheet Header";
    begin
        Header.Get(Usage."Time Sheet No.");
        CheckOwner(Header);
        if not (Usage.Status in [Usage.Status::Open, Usage.Status::Rejected]) then
            Refuse("Bifrost Error Code ori"::InvalidLine, 'entryNo', StrSubstNo(StateLbl, 'Submit'));
        if Usage."Journal Line No." <> 0 then
            Refuse("Bifrost Error Code ori"::InvalidLine, 'entryNo', StrSubstNo(StateLbl, 'Submit'));
        Usage.Status := Usage.Status::Submitted;
        Usage."Rejection Comment" := '';
        Usage.Modify(true);
    end;

    local procedure CheckApprover(Usage: Record "TS Usage Line ori")
    var
        Header: Record "Time Sheet Header";
    begin
        Header.ReadIsolation := IsolationLevel::UpdLock;
        Header.Get(Usage."Time Sheet No.");
        if (Header."Approver User ID" = '') or (Header."Approver User ID" <> UpperCase(UserId())) or
           (Header."Owner User ID" = UpperCase(UserId())) or (Usage."Owner User ID" = UpperCase(UserId())) then
            Refuse("Bifrost Error Code ori"::PermissionDenied, 'entryNo', PermissionLbl);
    end;

    local procedure Decide(var Usage: Record "TS Usage Line ori"; Request: JsonObject; Reject: Boolean)
    begin
        CheckApprover(Usage);
        if Usage.Status <> Usage.Status::Submitted then
            Refuse("Bifrost Error Code ori"::InvalidLine, 'entryNo', StrSubstNo(StateLbl, 'Approve/Reject'));
        if Reject then begin
            Usage.Status := Usage.Status::Rejected;
            Usage."Rejection Comment" := CopyStr(ReadText(Request, 'comment', 80, false), 1, 80);
            Clear(Usage."Approved By");
            Clear(Usage."Approved At");
        end else begin
            Usage.Status := Usage.Status::Approved;
            Usage."Approved By" := CopyStr(UserId(), 1, MaxStrLen(Usage."Approved By"));
            Usage."Approved At" := CurrentDateTime();
        end;
        Usage.Modify(true);
    end;

    local procedure Transfer(var Usage: Record "TS Usage Line ori"; Request: JsonObject)
    var
        Journals: Codeunit "TS Usage Journals ori";
    begin
        CheckApprover(Usage);
        if Usage.Status <> Usage.Status::Approved then
            Refuse("Bifrost Error Code ori"::InvalidLine, 'entryNo', StrSubstNo(StateLbl, 'Transfer'));
        if Usage."Journal Line No." <> 0 then
            exit;
        Journals.Create(Usage, CopyStr(ReadCode(Request, 'journalTemplate', 10, true), 1, 10), CopyStr(ReadCode(Request, 'journalBatch', 10, true), 1, 10), false);
        Usage.Modify(true);
    end;

    local procedure TransferSelection(Request: JsonObject; var Response: JsonObject)
    var
        Usage: Record "TS Usage Line ori";
        Token: JsonToken;
        EntryToken: JsonToken;
        Selection: JsonArray;
        Lines: JsonArray;
        EntryRequest: JsonObject;
        Index: Integer;
        EntryNo: Integer;
    begin
        if Request.Contains('entryNo') then
            Invalid('entryNos');
        Request.Get('entryNos', Token);
        if not Token.IsArray() then
            Invalid('entryNos');
        Selection := Token.AsArray();
        if (Selection.Count() = 0) or (Selection.Count() > 200) then
            Invalid('entryNos');
        Usage.ReadIsolation := IsolationLevel::UpdLock;
        for Index := 0 to Selection.Count() - 1 do begin
            Selection.Get(Index, EntryToken);
            Clear(EntryRequest);
            EntryRequest.Add('entryNos', EntryToken);
            EntryNo := ReadInteger(EntryRequest, 'entryNos', true);
            if not Usage.Get(EntryNo) then
                Invalid('entryNos');
            Transfer(Usage, Request);
            Lines.Add(ToJson(Usage));
        end;
        Response.Add('status', 'Success');
        Response.Add('lines', Lines);
    end;

    local procedure Reverse(var Usage: Record "TS Usage Line ori"; Request: JsonObject)
    var
        Journals: Codeunit "TS Usage Journals ori";
    begin
        CheckApprover(Usage);
        if (Usage.Status <> Usage.Status::Posted) or Usage.Reversed then
            Refuse("Bifrost Error Code ori"::InvalidLine, 'entryNo', StrSubstNo(StateLbl, 'Reverse'));
        if ReadBoolean(Request, 'createJournal') then
            Journals.Create(Usage, CopyStr(ReadCode(Request, 'journalTemplate', 10, true), 1, 10), CopyStr(ReadCode(Request, 'journalBatch', 10, true), 1, 10), true);
        Usage.Reversed := true;
        Usage.Modify(true);
    end;

    local procedure ListUsage(Request: JsonObject; var Response: JsonObject)
    var
        Usage: Record "TS Usage Line ori";
        Header: Record "Time Sheet Header";
        Lines: JsonArray;
        SheetNo: Code[20];
        StatusName: Text;
        Week: Date;
        AfterEntry: Integer;
        Limit: Integer;
        Count: Integer;
        LastEntry: Integer;
        HasMore: Boolean;
        Visible: Boolean;
    begin
        SheetNo := ReadCode(Request, 'timeSheetNo', 20, false);
        StatusName := ReadText(Request, 'status', 20, false);
        Week := ReadDate(Request, 'week', false);
        AfterEntry := ReadInteger(Request, 'afterEntryNo', false);
        Limit := ReadInteger(Request, 'limit', false);
        if Limit = 0 then
            Limit := 50;
        if Limit > 200 then
            Invalid('limit');
        Usage.ReadIsolation := IsolationLevel::ReadCommitted;
        Usage.SetRange("Entry No.", AfterEntry + 1, 2147483647);
        if SheetNo <> '' then
            Usage.SetRange("Time Sheet No.", SheetNo);
        if StatusName <> '' then
            SetStatusFilter(Usage, StatusName);
        if Week <> 0D then
            Usage.SetRange(Date, Week, Week + 6);
        Count := 0;
        // All fields are returned; partial-record loading cannot reduce this read.
        if Usage.FindSet() then
            repeat
                Header.Get(Usage."Time Sheet No.");
                Visible := (Header."Owner User ID" = UpperCase(UserId())) or
                    ((Usage.Status = Usage.Status::Submitted) and (Header."Approver User ID" = UpperCase(UserId())));
                if Visible then begin
                    if Count = Limit then begin
                        HasMore := true;
                        break;
                    end;
                    Lines.Add(ToJson(Usage));
                    LastEntry := Usage."Entry No.";
                    Count += 1;
                end;
            until Usage.Next() = 0;
        Response.Add('status', 'Success');
        Response.Add('lines', Lines);
        Response.Add('hasMore', HasMore);
        if HasMore then
            Response.Add('afterEntryNo', LastEntry);
    end;

    local procedure SetStatusFilter(var Usage: Record "TS Usage Line ori"; StatusName: Text)
    begin
        case StatusName of
            'Open':
                Usage.SetRange(Status, Usage.Status::Open);
            'Submitted':
                Usage.SetRange(Status, Usage.Status::Submitted);
            'Approved':
                Usage.SetRange(Status, Usage.Status::Approved);
            'Rejected':
                Usage.SetRange(Status, Usage.Status::Rejected);
            'Posted':
                Usage.SetRange(Status, Usage.Status::Posted);
            else
                Invalid('status');
        end;
    end;

    /// <summary>Returns stable, language-independent usage data.</summary>
    procedure ToJson(Usage: Record "TS Usage Line ori") Result: JsonObject
    begin
        Result.Add('entryNo', Usage."Entry No.");
        Result.Add('timeSheetNo', Usage."Time Sheet No.");
        Result.Add('lineNo', Usage."Time Sheet Line No.");
        Result.Add('resourceNo', Usage."Resource No.");
        Result.Add('type', Usage.Type.Names().Get(Usage.Type.Ordinals().IndexOf(Usage.Type.AsInteger())));
        Result.Add('no', Usage."No.");
        Result.Add('date', Usage.Date);
        Result.Add('quantity', Usage.Quantity);
        Result.Add('unitOfMeasure', Usage."Unit of Measure");
        Result.Add('description', Usage.Description);
        Result.Add('status', Usage.Status.Names().Get(Usage.Status.Ordinals().IndexOf(Usage.Status.AsInteger())));
        Result.Add('reversed', Usage.Reversed);
        Result.Add('approvedBy', Usage."Approved By");
        Result.Add('approvedAt', Usage."Approved At");
        Result.Add('journalTableNo', Usage."Journal Table No.");
        Result.Add('journalTemplate', Usage."Journal Template");
        Result.Add('journalBatch', Usage."Journal Batch");
        Result.Add('journalLineNo', Usage."Journal Line No.");
        Result.Add('ledgerEntryNo', Usage."Ledger Entry No.");
        Result.Add('comment', Usage."Rejection Comment");
    end;

    local procedure CheckKeys(Request: JsonObject; Operation: Text)
    var
        Keys: List of [Text];
        Allowed: List of [Text];
        KeyName: Text;
    begin
        case Operation of
            'Register':
                Allowed := 'timeSheetNo,lineNo,type,no,date,quantity,unitOfMeasure,description'.Split(',');
            'List':
                Allowed := 'timeSheetNo,week,status,afterEntryNo,limit'.Split(',');
            'Reject':
                Allowed := 'entryNo,comment'.Split(',');
            'Transfer':
                Allowed := 'entryNo,entryNos,journalTemplate,journalBatch'.Split(',');
            'Reverse':
                Allowed := 'entryNo,createJournal,journalTemplate,journalBatch'.Split(',');
            else
                Allowed.Add('entryNo');
        end;
        Keys := Request.Keys();
        foreach KeyName in Keys do
            if not Allowed.Contains(KeyName) then
                Refuse("Bifrost Error Code ori"::UnknownParameter, KeyName, StrSubstNo(UnknownKeyLbl, KeyName));
    end;

    local procedure ReadText(Request: JsonObject; KeyName: Text; MaxLength: Integer; Required: Boolean): Text
    var
        Token: JsonToken;
        Raw: Text;
        Value: Text;
    begin
        if not Request.Get(KeyName, Token) then begin
            if Required then
                Invalid(KeyName);
            exit('');
        end;
        if not Token.IsValue() then
            Invalid(KeyName);
        Token.WriteTo(Raw);
        if CopyStr(Raw, 1, 1) <> '"' then
            Invalid(KeyName);
        Value := Token.AsValue().AsText();
        if (StrLen(Value) > MaxLength) or (Required and (Value = '')) then
            Invalid(KeyName);
        exit(Value);
    end;

    local procedure ReadCode(Request: JsonObject; KeyName: Text; MaxLength: Integer; Required: Boolean): Code[20]
    begin
        exit(CopyStr(ReadText(Request, KeyName, MaxLength, Required), 1, 20));
    end;

    local procedure ReadDecimal(Request: JsonObject; KeyName: Text; Required: Boolean): Decimal
    var
        Token: JsonToken;
        Raw: Text;
        Value: Decimal;
    begin
        if not Request.Get(KeyName, Token) then begin
            if Required then
                Invalid(KeyName);
            exit(0);
        end;
        if not Token.IsValue() then
            Invalid(KeyName);
        Token.WriteTo(Raw);
        if not (CopyStr(Raw, 1, 1) in ['-', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9']) then
            Invalid(KeyName);
        if not Evaluate(Value, Raw, 9) then
            Invalid(KeyName);
        exit(Value);
    end;

    local procedure ReadInteger(Request: JsonObject; KeyName: Text; Required: Boolean): Integer
    var
        Value: Decimal;
    begin
        Value := ReadDecimal(Request, KeyName, Required);
        if (Value <> Round(Value, 1)) or (Value < 0) or (Value > 2147483646) or (Required and (Value = 0)) then
            Invalid(KeyName);
        exit(Value);
    end;

    local procedure ReadDate(Request: JsonObject; KeyName: Text; Required: Boolean): Date
    var
        Value: Date;
        TextValue: Text;
    begin
        TextValue := ReadText(Request, KeyName, 10, Required);
        if TextValue = '' then
            exit(0D);
        if not Evaluate(Value, TextValue, 9) then
            Invalid(KeyName);
        exit(Value);
    end;

    local procedure ReadBoolean(Request: JsonObject; KeyName: Text): Boolean
    var
        Token: JsonToken;
        Raw: Text;
    begin
        if not Request.Get(KeyName, Token) then
            exit(false);
        Token.WriteTo(Raw);
        if not (Raw in ['true', 'false']) then
            Invalid(KeyName);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure Invalid(KeyName: Text)
    begin
        Refuse("Bifrost Error Code ori"::InvalidParameterFormat, KeyName, StrSubstNo(InvalidKeyLbl, KeyName));
    end;

    local procedure Refuse(Code: Enum "Bifrost Error Code ori"; KeyName: Text; Message: Text)
    var
        Context: Codeunit "TS Usage Context ori";
    begin
        Context.Refuse(Code, KeyName, Message);
    end;
}
