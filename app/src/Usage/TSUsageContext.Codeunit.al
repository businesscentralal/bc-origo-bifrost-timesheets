namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>Session-local request and refusal state for the isolated usage runner.</summary>
codeunit 10036852 "TS Usage Context ori"
{
    Access = Internal;
    SingleInstance = true;
    var
        Request: JsonObject;
        Response: JsonObject;
        Operation: Text;
        ErrorCode: Enum "Bifrost Error Code ori";
        Parameter: Text;

    /// <summary>Starts a new request and clears all previous response and refusal state.</summary>
    procedure Initialize(NewOperation: Text; NewRequest: JsonObject)
    begin
        ClearAll();
        Operation := NewOperation;
        Request := NewRequest.Clone().AsObject();
        ErrorCode := ErrorCode::BusinessCentralError;
    end;

    /// <summary>Returns the isolated request.</summary>
    procedure GetRequest(): JsonObject
    begin
        exit(Request);
    end;

    /// <summary>Returns the operation selected by the dedicated message.</summary>
    procedure GetOperation(): Text
    begin
        exit(Operation);
    end;

    /// <summary>Stores a successful response.</summary>
    procedure SetResponse(NewResponse: JsonObject)
    begin
        Response := NewResponse;
    end;

    /// <summary>Returns the successful response.</summary>
    procedure GetResponse(): JsonObject
    begin
        exit(Response);
    end;

    /// <summary>Records a structured refusal before raising an error that rolls writes back.</summary>
    procedure Refuse(Code: Enum "Bifrost Error Code ori"; KeyName: Text; Message: Text)
    begin
        ErrorCode := Code;
        Parameter := KeyName;
        Error(ErrorInfo.Create(Message));
    end;

    /// <summary>Returns the structured refusal code.</summary>
    procedure GetErrorCode(): Enum "Bifrost Error Code ori"
    begin
        exit(ErrorCode);
    end;

    /// <summary>Returns the offending request key.</summary>
    procedure GetParameter(): Text
    begin
        exit(Parameter);
    end;

    /// <summary>Clears the completed request.</summary>
    procedure Reset()
    begin
        ClearAll();
    end;
}
