

# Event Grid System Topic Event Subscription
$egstSub = Get-AzEventGridSystemTopicEventSubscription -SystemTopicName $rotationEventGridName -ResourceGroupName $rgName -EventSubscriptionName "RotateSecret1"
if ( $null -eq $egstSub ) {
    $egstSubEp = $rotFunc.Id + "/functions/RotateSecret1"
    $egstSub = New-AzEventGridSystemTopicEventSubscription `
        -SystemTopicName $rotationEventGridName -ResourceGroupName $rgName `
        -EventSubscriptionName "RotateSecret1" `
        -EndpointType "AzureFunction" `
        -Endpoint $egstSubEp `
        -IncludedEventType "Microsoft.KeyVault.SecretNearExpiry"
}
