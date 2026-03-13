Write-Host "Indexing sample documents..."
Invoke-RestMethod -Method POST http://localhost:8000/index

Write-Host ""
Write-Host "Running sample query..."
Invoke-RestMethod -Method POST http://localhost:8000/query `
    -ContentType "application/json" `
    -Body '{"question":"How many annual leave days do employees get?"}'