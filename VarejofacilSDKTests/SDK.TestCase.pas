unit SDK.TestCase;

{$WARN IMPLICIT_STRING_CAST OFF}
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}

interface

uses
  TestFramework, SysUtils, SDK.Client, SDK.Types, SDK.TestConfig, SDK.TestValueGenerator, TypInfo, Variants, Classes, System.IOUtils;

type

  TSDKTestCase = class(TTestCase)
  strict private
    FClient: IClient;
  protected
    function GetClient: IClient;
  public
    procedure AssertAllPropertiesAreEqual(const AModelA, AModelB: IModel; AMessage: TString = ''; AIgnoreFields: TStringArray = []);
    procedure FillWithRandomValues(const AModel: IModel); overload;
    procedure FillWithRandomValues(const AModel: IModel; const APropertyName: TString); overload;
    procedure AfterConstruction; override;
  end;

implementation

{ TSDKTestCase }

procedure TSDKTestCase.FillWithRandomValues(const AModel: IModel);
var
  PropertiesSize: Integer;
  Properties: PPropList;
  PropIdx: Integer;
  Prop: PPropInfo;
begin
  PropertiesSize := GetPropList(AModel.GetReference, Properties);
  for PropIdx := 0 to PropertiesSize - 1 do
  begin
    Prop := Properties[PropIdx];
    FillWithRandomValues(AModel, TString(Prop^.Name));
  end;
end;

procedure TSDKTestCase.AfterConstruction;
begin
  inherited;

end;

procedure TSDKTestCase.AssertAllPropertiesAreEqual(const AModelA, AModelB: IModel; AMessage: TString; AIgnoreFields: TStringArray);
var
  PropertiesSize: Integer;
  Properties: PPropList;
  PropIdx: Integer;
  Prop: PPropInfo;
  VarValueA, VarValueB: Double;
  ValueA, ValueB: TString;
  Differences: TStringList;
begin
  Differences := TStringList.Create;
  try
    PropertiesSize := GetPropList(AModelA.GetReference, Properties);
    for PropIdx := 0 to PropertiesSize - 1 do
    begin
      Prop := Properties[PropIdx];
      if IndexOf(TString(Prop^.Name), AIgnoreFields) > -1 then
        Continue;
      case Prop^.PropType^.Kind of
        tkInterface, tkEnumeration, tkMethod, tkProcedure, tkRecord, tkArray, tkDynArray, tkClass, tkSet, tkPointer:;
        else
        begin
          if SameText(Prop^.PropType^.Name, 'TDateTime') then
          begin
            VarValueA := GetPropValue(AModelA.GetReference, Prop^.Name);
            VarValueB := GetPropValue(AModelB.GetReference, Prop^.Name);
            if Trunc(VarValueA) <> Trunc(VarValueB) then
              Differences.Add(Format('Propriedade %s diferente', [Prop^.Name]));
          end
          else
          begin
            ValueA := Trim(VarToStr(GetPropValue(AModelA.GetReference, Prop^.Name)));
            ValueB := Trim(VarToStr(GetPropValue(AModelB.GetReference, Prop^.Name)));
          end;
          if not SameText(ValueA, ValueB) then
            Differences.Add(Format('| Propriedade %s diferente [ valor a: "%s", valor b: "%s" ] |', [Prop^.Name, ValueA, ValueB]));
        end;
      end;
    end;
    TFile.AppendAllText(GetCurrentDir + '\tests.log', Differences.Text);
    Assert(Differences.Count = 0, Differences.Text);
  finally
    Differences.Free;
  end;
end;

procedure TSDKTestCase.FillWithRandomValues(const AModel: IModel; const APropertyName: TString);
var
  PropInfo: PPropInfo;
  Value: Variant;
begin
  PropInfo := GetPropInfo(AModel.GetReference, APropertyName);
  Value := TTestValueGenerator.Generate(PropInfo^.PropType^);
  if not VarIsNull(Value) then
    SetPropValue(AModel.GetReference, APropertyName, Value);
end;

function TSDKTestCase.GetClient: IClient;
begin
  if not Assigned(FClient) then
    FClient := TClient.Create(TestConfig.VarejofacilURL, TestConfig.Username, TestConfig.Password);
  Result := FClient;
end;

end.