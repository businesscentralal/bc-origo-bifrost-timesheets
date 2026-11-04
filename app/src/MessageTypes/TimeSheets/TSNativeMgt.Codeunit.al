namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;

/// <summary>
/// Request checks and dispatch for the native Timesheets message types.
/// Each Execute procedure reads only that type's keys. Writes run in
/// "TS Native Runner ori" so a failure rolls back.
/// </summary>
codeunit 10036868 "TS Native Mgt ori"
{
    Access = Internal;

    var
        BatchMsg: Label 'Submit needs its own write transaction.', Comment = 'is-IS=Innsending þarf eigin skrifaðgerð.';
        BatchNextTxt: Label 'Submit outside an uncommitted batch.', Comment = 'is-IS=Sendu inn utan óstaðfestrar lotu.';
        MissingKeyNextTxt: Label 'Send the missing key.', Comment = 'is-IS=Sendu lykilinn sem vantar.';
        TypeNextTxt: Label 'Send the key with the documented type.', Comment = 'is-IS=Sendu lykilinn með skráðu tagi.';
        UnknownKeyNextTxt: Label 'Remove the unknown key.', Comment = 'is-IS=Fjarlægðu óþekkta lykilinn.';
        IdentifierNextTxt: Label 'Use an identifier that exists.', Comment = 'is-IS=Notaðu auðkenni sem er til.';
        OneIdentifierNextTxt: Label 'Send only one identifier for the time sheet.', Comment = 'is-IS=Sendu aðeins eitt auðkenni fyrir tímaskýrsluna.';
        OwnerSubmitNextTxt: Label 'Only the owner can submit; ask the owner.', Comment = 'is-IS=Aðeins eigandinn getur sent inn. Biddu eigandann.';
        AddLinesNextTxt: Label 'Add lines first.', Comment = 'is-IS=Bættu við línum fyrst.';
        FixLineNextTxt: Label 'Fix the line and submit again.', Comment = 'is-IS=Lagfærðu línuna og sendu aftur inn.';
        AssignSetNextTxt: Label 'Assign the BIFROST Timeshts ori permission set.', Comment = 'is-IS=Úthlutaðu heimildasamstæðunni BIFROST Timeshts ori.';
        MissingKeyMsg: Label 'A required key is missing.', Comment = 'is-IS=Nauðsynlegur lykill vantar.';
        TypeMsg: Label 'A key has the wrong JSON type.', Comment = 'is-IS=Lykill er af röngu JSON-tagi.';
        UnknownKeyMsg: Label 'The request contains an unknown key.', Comment = 'is-IS=Beiðnin inniheldur óþekktan lykil.';
        IdentifierMsg: Label 'The identifier does not match a record.', Comment = 'is-IS=Auðkennið passar ekki við færslu.';
        OneIdentifierMsg: Label 'The request names the time sheet in more than one way.', Comment = 'is-IS=Beiðnin nefnir tímaskýrsluna á fleiri en einn hátt.';
        OwnerSubmitMsg: Label 'The caller is not the owner of the time sheet.', Comment = 'is-IS=Kallandinn er ekki eigandi tímaskýrslunnar.';
        AddLinesMsg: Label 'The time sheet has no open lines.', Comment = 'is-IS=Tímaskýrslan hefur engar opnar línur.';
        FixLineMsg: Label 'Business Central rejected the line.', Comment = 'is-IS=Business Central hafnaði línunni.';
        AssignSetMsg: Label 'The caller cannot write time sheets.', Comment = 'is-IS=Kallandinn getur ekki skrifað tímaskýrslur.';

    /// <summary>Checks every native read and the line write used by Submit.</summary>
    procedure CanMaintainSheets(): Boolean
    var
        Detail: Record "Time Sheet Detail";
        Resource: Record Resource;
        ResourcesSetup: Record "Resources Setup";
        Header: Record "Time Sheet Header";
        Line: Record "Time Sheet Line";
    begin
        exit(Header.ReadPermission() and Line.ReadPermission() and Detail.ReadPermission() and
             Resource.ReadPermission() and ResourcesSetup.ReadPermission() and Line.WritePermission());
    end;

    /// <summary>Handles ExecuteSubmit for the Submit message contract.</summary>
    procedure ExecuteSubmit(var Argument: Record "Message Argument ori")
    var
        Header: Record "Time Sheet Header";
        Context: Codeunit "TS Native Context ori";
        Allowed: List of [Text];
        DateToken: JsonToken;
        LineFilter: Text;
        LinesToken: JsonToken;
        Numbers: List of [Integer];
        OpenCount: Integer;
        RequestJson: JsonObject;
        ResourceToken: JsonToken;
        SheetToken: JsonToken;
    begin
        if Deny(Argument) then
            exit;
        RequestJson := Argument.GetRequestJson();
        Allowed.Add('timeSheetNo');
        Allowed.Add('resourceNo');
        Allowed.Add('date');
        Allowed.Add('lineNos');
        if not AllowOnly(Argument, RequestJson, Allowed) then
            exit;
        if not ResolveSheet(Argument, RequestJson, SheetToken, ResourceToken, DateToken, Header) then
            exit;
        if not SameUser(Header."Owner User ID") then begin
            Fail(Argument, "Bifrost Error Code ori"::PermissionDenied, OwnerSubmitMsg, 'timeSheetNo', OwnerSubmitNextTxt);
            exit;
        end;
        if not ReadLineSelection(Argument, RequestJson, LinesToken, Numbers, LineFilter) then
            exit;
        if not SubmitSelection(Argument, Header, Numbers, LineFilter, OpenCount) then
            exit;
        if OpenCount = 0 then begin
            RespondExisting(Argument, Header."No.", LineFilter, false);
            exit;
        end;
        Context.SetSubmit(Header."No.", LineFilter);
        RunAndRespond(Argument);
    end;

    local procedure ResolveSheet(var Argument: Record "Message Argument ori"; RequestJson: JsonObject; var SheetToken: JsonToken; var ResourceToken: JsonToken; var DateToken: JsonToken; var Header: Record "Time Sheet Header"): Boolean
    var
        HasDate: Boolean;
        HasResource: Boolean;
        HasSheet: Boolean;
        ResourceNo: Code[20];
        SheetDate: Date;
    begin
        Header.ReadIsolation := IsolationLevel::ReadCommitted;
        HasSheet := RequestJson.Get('timeSheetNo', SheetToken);
        HasResource := RequestJson.Get('resourceNo', ResourceToken);
        HasDate := RequestJson.Get('date', DateToken);
        if HasSheet and (HasResource or HasDate) then begin
            Fail(Argument, "Bifrost Error Code ori"::ConflictingIdentifiers, OneIdentifierMsg, 'timeSheetNo', OneIdentifierNextTxt);
            exit(false);
        end;
        if not HasSheet and not HasResource then begin
            Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'timeSheetNo', MissingKeyNextTxt);
            exit(false);
        end;
        if HasSheet then
            exit(LoadSheetToken(Argument, SheetToken, Header));
        if not HasDate then begin
            Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'date', MissingKeyNextTxt);
            exit(false);
        end;
        if not IsJsonString(ResourceToken) then begin
            Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'resourceNo', TypeNextTxt);
            exit(false);
        end;
        if not ReadJsonDate(DateToken, SheetDate) then begin
            Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'date', TypeNextTxt);
            exit(false);
        end;
        if StrLen(ResourceToken.AsValue().AsText()) > MaxStrLen(ResourceNo) then begin
            Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'resourceNo', TypeNextTxt);
            exit(false);
        end;
        ResourceNo := CopyStr(ResourceToken.AsValue().AsText(), 1, MaxStrLen(ResourceNo));
        Header.SetRange("Resource No.", ResourceNo);
        Header.SetFilter("Starting Date", '<=%1', SheetDate);
        Header.SetFilter("Ending Date", '>=%1', SheetDate);
        if Header.Count() > 1 then begin
            Fail(Argument, "Bifrost Error Code ori"::ConflictingIdentifiers, OneIdentifierMsg, 'date', OneIdentifierNextTxt);
            exit(false);
        end;
        if not Header.FindFirst() then begin
            Fail(Argument, "Bifrost Error Code ori"::RecordNotFound, IdentifierMsg, 'resourceNo', IdentifierNextTxt);
            exit(false);
        end;
        exit(true);
    end;

    local procedure LoadSheetToken(var Argument: Record "Message Argument ori"; SheetToken: JsonToken; var Header: Record "Time Sheet Header"): Boolean
    var
        SheetNo: Code[20];
    begin
        if not IsJsonString(SheetToken) then begin
            Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'timeSheetNo', TypeNextTxt);
            exit(false);
        end;
        if StrLen(SheetToken.AsValue().AsText()) > MaxStrLen(SheetNo) then begin
            Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'timeSheetNo', TypeNextTxt);
            exit(false);
        end;
        SheetNo := CopyStr(SheetToken.AsValue().AsText(), 1, MaxStrLen(SheetNo));
        if not Header.Get(SheetNo) then begin
            Fail(Argument, "Bifrost Error Code ori"::RecordNotFound, IdentifierMsg, 'timeSheetNo', IdentifierNextTxt);
            exit(false);
        end;
        exit(true);
    end;

    local procedure ReadLineSelection(var Argument: Record "Message Argument ori"; RequestJson: JsonObject; var LinesToken: JsonToken; var Numbers: List of [Integer]; var LineFilter: Text): Boolean
    var
        Entry: JsonToken;
        Index: Integer;
        LineNo: Integer;
    begin
        if not RequestJson.Get('lineNos', LinesToken) then begin
            LineFilter := '*';
            exit(true);
        end;
        if not LinesToken.IsArray() then begin
            Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'lineNos', TypeNextTxt);
            exit(false);
        end;
        LineFilter := '';
        for Index := 0 to LinesToken.AsArray().Count() - 1 do begin
            LinesToken.AsArray().Get(Index, Entry);
            if not ReadJsonInteger(Entry, LineNo) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'lineNos', TypeNextTxt);
                exit(false);
            end;
            Numbers.Add(LineNo);
            if LineFilter <> '' then
                LineFilter += '|';
            LineFilter += Format(LineNo);
        end;
        exit(true);
    end;

    local procedure SubmitSelection(var Argument: Record "Message Argument ori"; Header: Record "Time Sheet Header"; Numbers: List of [Integer]; var LineFilter: Text; var OpenCount: Integer): Boolean
    var
        Line: Record "Time Sheet Line";
        LineNo: Integer;
    begin
        Line.ReadIsolation := IsolationLevel::ReadCommitted;
        OpenCount := 0;
        if LineFilter = '*' then begin
            Line.SetRange("Time Sheet No.", Header."No.");
            if Line.IsEmpty() then begin
                Fail(Argument, "Bifrost Error Code ori"::PreconditionFailed, AddLinesMsg, 'lineNos', AddLinesNextTxt);
                exit(false);
            end;
            Line.SetRange(Status, Line.Status::Open);
            OpenCount := Line.Count();
            // No open line left: list the lines that are already submitted as unchanged.
            if OpenCount = 0 then
                Line.SetRange(Status, Line.Status::Submitted);
            if Line.IsEmpty() then begin
                Fail(Argument, "Bifrost Error Code ori"::PreconditionFailed, AddLinesMsg, 'lineNos', AddLinesNextTxt);
                exit(false);
            end;
            LineFilter := FilterOf(Line);
            exit(true);
        end;
        if Numbers.Count() = 0 then begin
            Line.SetRange("Time Sheet No.", Header."No.");
            Line.SetRange(Status, Line.Status::Open);
            if Line.IsEmpty() then begin
                Fail(Argument, "Bifrost Error Code ori"::PreconditionFailed, AddLinesMsg, 'lineNos', AddLinesNextTxt);
                exit(false);
            end;
            exit(true);
        end;
        foreach LineNo in Numbers do begin
            if not Line.Get(Header."No.", LineNo) then begin
                Fail(Argument, "Bifrost Error Code ori"::RecordNotFound, IdentifierMsg, 'lineNos', IdentifierNextTxt);
                exit(false);
            end;
            if Line.Status = Line.Status::Open then
                OpenCount += 1
            else
                if Line.Status <> Line.Status::Submitted then begin
                    Fail(Argument, "Bifrost Error Code ori"::InvalidLine, FixLineMsg, 'lineNos', FixLineNextTxt);
                    exit(false);
                end;
        end;
        exit(true);
    end;

    local procedure FilterOf(var Line: Record "Time Sheet Line") Result: Text
    begin
        if Line.FindSet() then
            repeat
                if Result <> '' then
                    Result += '|';
                Result += Format(Line."Line No.");
            until Line.Next() = 0;
    end;

    local procedure RespondExisting(var Argument: Record "Message Argument ori"; SheetNo: Code[20]; LineFilter: Text; Decision: Boolean)
    var
        Line: Record "Time Sheet Line";
        Lines: JsonArray;
        Response: JsonObject;
    begin
        if LineFilter <> '' then begin
            Line.SetRange("Time Sheet No.", SheetNo);
            if LineFilter <> '*' then
                Line.SetFilter("Line No.", LineFilter);
            if Line.FindSet() then
                repeat
                    Lines.Add(ExistingNode(Line, Decision));
                until Line.Next() = 0;
        end;
        Response.Add('status', 'Success');
        Response.Add('lines', Lines);
        Argument.SetResponseJson(Response);
    end;

    local procedure ExistingNode(Line: Record "Time Sheet Line"; Decision: Boolean) Node: JsonObject
    begin
        Node.Add('timeSheetNo', Line."Time Sheet No.");
        Node.Add('lineNo', Line."Line No.");
        Node.Add('status', Line.Status.Names().Get(Line.Status.Ordinals().IndexOf(Line.Status.AsInteger())));
        Node.Add('changed', false);
        Node.Add('lineType', Line.Type.Names().Get(Line.Type.Ordinals().IndexOf(Line.Type.AsInteger())));
        if Decision then
            Node.Add('decision', true);
    end;

    local procedure RunAndRespond(var Argument: Record "Message Argument ori")
    var
        Context: Codeunit "TS Native Context ori";
        Response: JsonObject;
    begin
        if Argument."Omit Commit" then begin
            Context.Clear();
            Fail(Argument, "Bifrost Error Code ori"::PreconditionFailed, BatchMsg, '', BatchNextTxt);
            exit;
        end;

        // A captured Codeunit.Run cannot roll a failure back while a write transaction is
        // already open: the platform stops that transaction and hides the cause. Commit
        // first. The runner then has its own transaction, which commits or rolls back.
        if Database.IsInWriteTransaction() then
            Commit();

        if not Codeunit.Run(Codeunit::"TS Native Runner ori") then begin
            Context.Clear();
            Fail(Argument, "Bifrost Error Code ori"::InvalidLine, FixLineMsg, 'lineNos', FixLineNextTxt);
            exit;
        end;

        Response.ReadFrom(Context.GetResult());
        Context.Clear();
        Argument.SetResponseJson(Response);
    end;

    local procedure Deny(var Argument: Record "Message Argument ori"): Boolean
    begin
        if CanMaintainSheets() then
            exit(false);
        Fail(Argument, "Bifrost Error Code ori"::PermissionDenied, AssignSetMsg, '', AssignSetNextTxt);
        exit(true);
    end;

    local procedure Fail(var Argument: Record "Message Argument ori"; ErrorCode: Enum "Bifrost Error Code ori"; Message: Text; Parameter: Text; NextStep: Text)
    begin
        Argument.RespondWithError(ErrorCode, Message, Parameter, '', '', NextStep);
    end;

    local procedure AllowOnly(var Argument: Record "Message Argument ori"; RequestJson: JsonObject; Allowed: List of [Text]): Boolean
    var
        KeyName: Text;
        Keys: List of [Text];
    begin
        Keys := RequestJson.Keys();
        foreach KeyName in Keys do
            if not Allowed.Contains(KeyName) then begin
                Fail(Argument, "Bifrost Error Code ori"::UnknownParameter, UnknownKeyMsg, KeyName, UnknownKeyNextTxt);
                exit(false);
            end;
        exit(true);
    end;

    local procedure SameUser(Stored: Code[50]): Boolean
    begin
        if Stored = '' then
            exit(false);
        exit(Stored = CopyStr(UserId(), 1, MaxStrLen(Stored)));
    end;

    local procedure IsJsonString(Token: JsonToken): Boolean
    var
        Raw: Text;
    begin
        if not Token.IsValue() then
            exit(false);
        Token.WriteTo(Raw);
        exit(CopyStr(DelChr(Raw, '<>', ' '), 1, 1) = '"');
    end;

    local procedure IsJsonNumber(Token: JsonToken): Boolean
    var
        First: Text[1];
        Raw: Text;
    begin
        if not Token.IsValue() then
            exit(false);
        Token.WriteTo(Raw);
        Raw := DelChr(Raw, '<>', ' ');
        First := CopyStr(Raw, 1, 1);
        exit(First in ['-', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9']);
    end;

    local procedure ReadJsonDate(Token: JsonToken; var DateValue: Date): Boolean
    begin
        if not IsJsonString(Token) then
            exit(false);
        exit(Evaluate(DateValue, Token.AsValue().AsText(), 9));
    end;

    local procedure ReadJsonInteger(Token: JsonToken; var IntValue: Integer): Boolean
    var
        DecimalValue: Decimal;
    begin
        if not IsJsonNumber(Token) then
            exit(false);
        if not Evaluate(DecimalValue, Token.AsValue().AsText(), 9) then
            exit(false);
        if DecimalValue <> Round(DecimalValue, 1) then
            exit(false);
        if (DecimalValue < -2147483648.0) or (DecimalValue > 2147483647.0) then
            exit(false);
        IntValue := DecimalValue;
        exit(true);
    end;

}
