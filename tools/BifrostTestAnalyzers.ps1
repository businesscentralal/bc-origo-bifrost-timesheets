# AppSource packaging rules apply to the distributable product, not the test harness.
# Run Alpaca's hook first so its compiler paths and other parameters remain intact.
function Invoke-BifrostPreCompile {
    param(
        [string] $AppType,
        [ref] $Parameters,
        [scriptblock] $AlpacaPreCompile
    )

    if ($AlpacaPreCompile) {
        Invoke-Command -ScriptBlock $AlpacaPreCompile -ArgumentList $AppType, $Parameters
    }
    if ($AppType -eq 'testApp') {
        $Parameters.Value.EnableAppSourceCop = $false
        Write-Host 'Bifrost: testApp uses CodeCop/UICop; product AppSourceCop remains unchanged.'
    }
}
