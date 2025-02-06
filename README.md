# Schritt #1 - Resource Group in einer bestimmten Region erstellen
az group create --name virtiUebeung3 --location westeurope

# Schritt #2 - Bicep File deployen
az deployment group create --resource-group virtiUebung3 --template-file main.bicep

# Schritt #3 - Ressourcen löschen
az group delete --name virtiUebung3
