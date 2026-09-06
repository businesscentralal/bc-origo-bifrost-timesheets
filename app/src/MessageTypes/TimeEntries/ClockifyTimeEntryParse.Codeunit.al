namespace Origo.Bifrost.Timesheets;

/// <summary>
/// Shared JSON parsing helpers for the Clockify time-entry sync message types
/// (workspace/user/entry parameters, tag arrays, and ISO-8601 hours/date derivation).
/// </summary>
codeunit 10036842 "Clockify TimeEntry Parse ori"
{
    Access = Internal;

    /// <summary>Reads a string property, returning '' when absent or null.</summary>
    procedure GetText(JsonObject: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not JsonObject.Get(PropertyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    /// <summary>Reads a boolean property, returning <paramref name="DefaultValue"/> when absent or null.</summary>
    procedure GetBoolean(JsonObject: JsonObject; PropertyName: Text; DefaultValue: Boolean): Boolean
    var
        Token: JsonToken;
    begin
        if not JsonObject.Get(PropertyName, Token) then
            exit(DefaultValue);
        if not Token.IsValue() then
            exit(DefaultValue);
        if Token.AsValue().IsNull() then
            exit(DefaultValue);
        exit(Token.AsValue().AsBoolean());
    end;

    /// <summary>Reads the <c>tagIds</c> string array into <paramref name="TagIds"/>.</summary>
    procedure GetTagIds(JsonObject: JsonObject; var TagIds: List of [Text])
    var
        Token: JsonToken;
        TagToken: JsonToken;
    begin
        Clear(TagIds);
        if not JsonObject.Get('tagIds', Token) then
            exit;
        if not Token.IsArray() then
            exit;
        foreach TagToken in Token.AsArray() do
            if TagToken.IsValue() then
                if not TagToken.AsValue().IsNull() then
                    TagIds.Add(TagToken.AsValue().AsText());
    end;

    /// <summary>Returns the entry duration in hours from ISO-8601 start/end, or 0 when unparseable.</summary>
    procedure CalculateHours(StartText: Text; EndText: Text): Decimal
    var
        StartDT: DateTime;
        EndDT: DateTime;
        DurationMs: BigInteger;
    begin
        if (StartText = '') or (EndText = '') then
            exit(0);
        if not Evaluate(StartDT, StartText) then
            exit(0);
        if not Evaluate(EndDT, EndText) then
            exit(0);
        DurationMs := EndDT - StartDT;
        exit(DurationMs / 3600000);
    end;

    /// <summary>Returns the date part of an ISO-8601 datetime, or 0D when unparseable.</summary>
    procedure ParseDate(DateTimeText: Text): Date
    var
        DateTimeParsed: DateTime;
    begin
        if DateTimeText = '' then
            exit(0D);
        if not Evaluate(DateTimeParsed, DateTimeText) then
            exit(0D);
        exit(DT2Date(DateTimeParsed));
    end;
}
