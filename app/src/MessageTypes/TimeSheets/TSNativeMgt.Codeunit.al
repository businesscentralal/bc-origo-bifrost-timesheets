namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;
using System.Security.User;

/// <summary>Validates the native Reopen, Post and Archive aliases and isolates their writes.</summary>
codeunit 10036868 "TS Native Mgt ori"
{
    Access = Internal;

    var
        MissingKeyNextTxt: Label 'Send the missing key.', Comment = 'is-IS=Sendu lykilinn sem vantar.';
        TypeNextTxt: Label 'Send the key with the documented type.', Comment = 'is-IS=Sendu lykilinn með skráðu tagi.';
        UnknownKeyNextTxt: Label 'Remove the unknown key.', Comment = 'is-IS=Fjarlægðu óþekkta lykilinn.';
        IdentifierNextTxt: Label 'Use an identifier that exists.', Comment = 'is-IS=Notaðu auðkenni sem er til.';
        NativeNameNextTxt: Label 'Use the native name.', Comment = 'is-IS=Notaðu innlenda heitið.';
        AssignSetNextTxt: Label 'Assign the BIFROST Timeshts ori permission set.', Comment = 'is-IS=Úthlutaðu heimildasamstæðunni BIFROST Timeshts ori.';
        RetryNextTxt: Label 'Retry the call.', Comment = 'is-IS=Reyndu kallið aftur.';
        MissingKeyMsg: Label 'A required key is missing.', Comment = 'is-IS=Nauðsynlegur lykill vantar.';
        TypeMsg: Label 'A key has the wrong JSON type.', Comment = 'is-IS=Lykill er af röngu JSON-tagi.';
        UnknownKeyMsg: Label 'The request contains an unknown key.', Comment = 'is-IS=Beiðnin inniheldur óþekktan lykil.';
        IdentifierMsg: Label 'The identifier does not match a record.', Comment = 'is-IS=Auðkennið passar ekki við færslu.';
        FixLineMsg: Label 'Business Central rejected the line.', Comment = 'is-IS=Business Central hafnaði línunni.';
        AssignSetMsg: Label 'The caller cannot write time sheets.', Comment = 'is-IS=Kallandinn getur ekki skrifað tímaskýrslur.';
        LegacyMsg: Label 'The Clockify.TimeSheet name still runs. Use the native name.', Comment = 'is-IS=Clockify.TimeSheet heitið keyrir enn. Notaðu innlenda heitið.';

    /// <summary>True when the caller may insert or modify time sheet header, line and detail.</summary>
    procedure CanMaintainSheets(): Boolean
    var
        Detail: Record "Time Sheet Detail";
        Header: Record "Time Sheet Header";
        Line: Record "Time Sheet Line";
    begin
        exit(Header.WritePermission() and Line.WritePermission() and Detail.WritePermission());
    end;

    /// <summary>True when the caller may read time sheet header, line and detail.</summary>
    procedure CanReadSheets(): Boolean
    var
        Detail: Record "Time Sheet Detail";
        Header: Record "Time Sheet Header";
        Line: Record "Time Sheet Line";
    begin
        exit(Header.ReadPermission() and Line.ReadPermission() and Detail.ReadPermission());
    end;

    /// <summary>Checks the base records used by bulk reopening.</summary>
    procedure CanReopenSheets(): Boolean
    var
        Resource: Record Resource;
        PostingEntry: Record "Time Sheet Posting Entry";
        UserSetup: Record "User Setup";
    begin
        exit(CanMaintainSheets() and CanReadSheets() and Resource.ReadPermission() and
             UserSetup.ReadPermission() and PostingEntry.ReadPermission());
    end;

    /// <summary>Checks the directly accessed journal records used by bulk posting.</summary>
    procedure CanPostSheets(): Boolean
    var
        Batch: Record "Job Journal Batch";
        JournalLine: Record "Job Journal Line";
        JournalTemplateRecord: Record "Job Journal Template";
    begin
        exit(CanMaintainSheets() and CanReadSheets() and Batch.ReadPermission() and
             JournalTemplateRecord.ReadPermission() and JournalLine.ReadPermission() and JournalLine.WritePermission());
    end;

    /// <summary>Checks the active and archive records used by bulk archiving.</summary>
    procedure CanArchiveSheets(): Boolean
    var
        CommentLine: Record "Time Sheet Comment Line";
        CommentArchive: Record "Time Sheet Cmt. Line Archive";
        DetailArchive: Record "Time Sheet Detail Archive";
        HeaderArchive: Record "Time Sheet Header Archive";
        LineArchive: Record "Time Sheet Line Archive";
    begin
        exit(CanMaintainSheets() and CanReadSheets() and CommentLine.ReadPermission() and
             CommentLine.WritePermission() and CommentArchive.ReadPermission() and CommentArchive.WritePermission() and
             DetailArchive.ReadPermission() and DetailArchive.WritePermission() and
             HeaderArchive.ReadPermission() and HeaderArchive.WritePermission() and
             LineArchive.ReadPermission() and LineArchive.WritePermission());
    end;

    /// <summary>Adds the deprecation warning the old Clockify.TimeSheet names return on success.</summary>
    procedure AddLegacyNameWarning(var ResponseJson: JsonObject)
    var
        Warning: JsonObject;
        Warnings: JsonArray;
    begin
        Warning.Add('code', 'DeprecatedParameter');
        Warning.Add('message', LegacyMsg);
        Warning.Add('parameter', 'type');
        Warning.Add('nextStep', NativeNameNextTxt);
        Warnings.Add(Warning);
        ResponseJson.Add('warnings', Warnings);
    end;

    /// <summary>Reopens submitted or approved lines under the native name.</summary>
    procedure ExecuteReopen(var Argument: Record "Message Argument ori")
    var
        Context: Codeunit "TS Native Context ori";
        Allowed: List of [Text];
        DateToken: JsonToken;
        EndingDateTo: Date;
        RequestJson: JsonObject;
    begin
        if not CanReopenSheets() then begin
            Fail(Argument, "Bifrost Error Code ori"::PermissionDenied, AssignSetMsg, '', AssignSetNextTxt);
            exit;
        end;
        RequestJson := Argument.GetRequestJson();
        Allowed.Add('endingDateTo');
        if not AllowOnly(Argument, RequestJson, Allowed) then
            exit;
        if RequestJson.Get('endingDateTo', DateToken) then
            if not ReadJsonDate(DateToken, EndingDateTo) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'endingDateTo', TypeNextTxt);
                exit;
            end;
        Context.SetReopen(EndingDateTo);
        RunBulkAndRespond(Argument);
    end;

    /// <summary>Posts approved lines under the native name.</summary>
    procedure ExecutePost(var Argument: Record "Message Argument ori")
    var
        Batch: Record "Job Journal Batch";
        JournalTemplateRecord: Record "Job Journal Template";
        SetupMgt: Codeunit "Clockify Setup Mgt ori";
        Context: Codeunit "TS Native Context ori";
        Allowed: List of [Text];
        BatchToken: JsonToken;
        JournalBatch: Code[10];
        JournalTemplate: Code[10];
        RequestJson: JsonObject;
        TemplateToken: JsonToken;
    begin
        if not CanPostSheets() then begin
            Fail(Argument, "Bifrost Error Code ori"::PermissionDenied, AssignSetMsg, '', AssignSetNextTxt);
            exit;
        end;
        RequestJson := Argument.GetRequestJson();
        Allowed.Add('journalTemplate');
        Allowed.Add('journalBatch');
        if not AllowOnly(Argument, RequestJson, Allowed) then
            exit;
        SetupMgt.TryGetJobJournal(JournalTemplate, JournalBatch);
        if RequestJson.Get('journalTemplate', TemplateToken) then begin
            if not IsJsonString(TemplateToken) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'journalTemplate', TypeNextTxt);
                exit;
            end;
            JournalTemplate := CopyStr(TemplateToken.AsValue().AsText(), 1, MaxStrLen(JournalTemplate));
        end;
        if RequestJson.Get('journalBatch', BatchToken) then begin
            if not IsJsonString(BatchToken) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'journalBatch', TypeNextTxt);
                exit;
            end;
            JournalBatch := CopyStr(BatchToken.AsValue().AsText(), 1, MaxStrLen(JournalBatch));
        end;
        if JournalTemplate = '' then begin
            Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'journalTemplate', MissingKeyNextTxt);
            exit;
        end;
        if JournalBatch = '' then begin
            Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'journalBatch', MissingKeyNextTxt);
            exit;
        end;
        JournalTemplateRecord.ReadIsolation := IsolationLevel::ReadCommitted;
        Batch.ReadIsolation := IsolationLevel::ReadCommitted;
        if not JournalTemplateRecord.Get(JournalTemplate) then begin
            Fail(Argument, "Bifrost Error Code ori"::RecordNotFound, IdentifierMsg, 'journalTemplate', IdentifierNextTxt);
            exit;
        end;
        if not Batch.Get(JournalTemplate, JournalBatch) then begin
            Fail(Argument, "Bifrost Error Code ori"::RecordNotFound, IdentifierMsg, 'journalBatch', IdentifierNextTxt);
            exit;
        end;
        Context.SetPost(JournalTemplate, JournalBatch);
        RunBulkAndRespond(Argument);
    end;

    /// <summary>Archives posted time sheets under the native name.</summary>
    procedure ExecuteArchive(var Argument: Record "Message Argument ori")
    var
        Context: Codeunit "TS Native Context ori";
        Allowed: List of [Text];
        RequestJson: JsonObject;
    begin
        if not CanArchiveSheets() then begin
            Fail(Argument, "Bifrost Error Code ori"::PermissionDenied, AssignSetMsg, '', AssignSetNextTxt);
            exit;
        end;
        RequestJson := Argument.GetRequestJson();
        if not AllowOnly(Argument, RequestJson, Allowed) then
            exit;
        Context.SetArchive();
        RunBulkAndRespond(Argument);
    end;

    local procedure RunBulkAndRespond(var Argument: Record "Message Argument ori")
    var
        Context: Codeunit "TS Native Context ori";
        Response: JsonObject;
    begin
        // Keep Omit Commit in the caller's transaction, as the existing native writes do.
        if Argument."Omit Commit" then begin
            Codeunit.Run(Codeunit::"TS Native Runner ori");
            Response.ReadFrom(Context.GetResult());
            Context.Clear();
            Argument.SetResponseJson(Response);
            exit;
        end;

        if Database.IsInWriteTransaction() then
            Commit();
        if not Codeunit.Run(Codeunit::"TS Native Runner ori") then begin
            Context.Clear();
            // The platform diagnostic may contain internal object and record information.
            // Return a structured refusal instead of exposing the runtime error to callers.
            Fail(Argument, "Bifrost Error Code ori"::BusinessCentralError, FixLineMsg, '', RetryNextTxt);
            exit;
        end;
        Response.ReadFrom(Context.GetResult());
        Context.Clear();
        Argument.SetResponseJson(Response);
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

    local procedure IsJsonString(Token: JsonToken): Boolean
    var
        Raw: Text;
    begin
        if not Token.IsValue() then
            exit(false);
        Token.WriteTo(Raw);
        exit(CopyStr(DelChr(Raw, '<>', ' '), 1, 1) = '"');
    end;

    local procedure ReadJsonDate(Token: JsonToken; var DateValue: Date): Boolean
    begin
        if not IsJsonString(Token) then
            exit(false);
        exit(Evaluate(DateValue, Token.AsValue().AsText(), 9));
    end;
}
