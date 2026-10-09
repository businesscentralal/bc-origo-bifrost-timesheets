param([string] $ProjectPath = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = 'Stop'
. (Join-Path $ProjectPath 'tools/BifrostTestAnalyzers.ps1')

foreach ($appType in @('app', 'testApp', 'bcptApp')) {
    $parameters = @{
        EnableCodeCop = $true
        EnableUICop = $true
        EnableAppSourceCop = $true
        FailOn = 'warning'
        AppProjectFolder = 'original-path'
    }
    $alpaca = {
        param([string] $AppType, [ref] $Parameters)
        # Simulate the upstream hook replacing the parameter map, not just a key.
        $Parameters.Value = $Parameters.Value.Clone()
        $Parameters.Value.AppProjectFolder = 'alpaca-path'
        $Parameters.Value.HookAppType = $AppType
        $Parameters.Value.EnableAppSourceCop = $true
    }
    Invoke-BifrostPreCompile -AppType $appType -Parameters ([ref] $parameters) -AlpacaPreCompile $alpaca
    if ($parameters.AppProjectFolder -ne 'alpaca-path' -or $parameters.HookAppType -ne $appType) {
        throw "Alpaca hook was not preserved for $appType."
    }
    if (!$parameters.EnableCodeCop -or !$parameters.EnableUICop -or $parameters.FailOn -ne 'warning') {
        throw "Required analyzers or warning gate changed for $appType."
    }
    if ($parameters.EnableAppSourceCop -ne ($appType -ne 'testApp')) {
        throw "AppSourceCop selection is incorrect for $appType."
    }
}

# Exercise the actual installed hook in the same child/parent scope arrangement.
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $ProjectPath '.AL-Go/PipelineInitialize.ps1'), [ref] $tokens, [ref] $errors)
if ($errors.Count) { throw 'PipelineInitialize.ps1 must parse.' }
$installCommands = @($ast.EndBlock.Statements | Where-Object {
    $_.Extent.Text -match "^Set-Variable -Name '(BifrostAlpacaPreCompileApp|PreCompileApp)'"
})
if ($installCommands.Count -ne 2) { throw 'Missing post-Alpaca hook installation.' }
$install = [scriptblock]::Create(($installCommands.Extent.Text -join "`n"))
Push-Location $ProjectPath
try {
    $PreCompileApp = $alpaca
    Invoke-Command -ScriptBlock $install
    $parameters = @{ EnableCodeCop = $true; EnableUICop = $true; EnableAppSourceCop = $true; FailOn = 'warning' }
    Invoke-Command -ScriptBlock $PreCompileApp -ArgumentList 'testApp', ([ref] $parameters)
    if ($parameters.EnableAppSourceCop -or $parameters.AppProjectFolder -ne 'alpaca-path' -or
        !$parameters.EnableCodeCop -or !$parameters.EnableUICop -or $parameters.FailOn -ne 'warning') {
        throw 'Installed pipeline hook did not preserve Alpaca and required test analyzers.'
    }
}
finally { Pop-Location }

Write-Host 'Bifrost analyzer guard passed: product AppSourceCop, test CodeCop/UICop, warning gate and Alpaca hook chain.'
