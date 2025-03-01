public with sharing class CountyLeadController {
    
    @AuraEnabled
    public static List<Lead> insertLeads(List<Lead> leadList) {
        List<Lead> insertedLeads = new List<Lead>();
        Set<String> countyNames = new Set<String>();
    
        // Collect county names from the leads
        for (Lead lead : leadList) {
            if (String.isNotBlank(lead.County__c)) { 
                countyNames.add(lead.County__c);
            }
        }
    
        // Query existing counties
        Map<String, Id> countyMap = new Map<String, Id>();
        if (!countyNames.isEmpty()) {
            for (County__c county : [SELECT Id, Name FROM County__c WHERE Name IN :countyNames]) {
                countyMap.put(county.Name, county.Id);
            }
        }
    
        // Ensure "UNKNOWN" state exists
        List<State__c> unknownState = [SELECT Id FROM State__c WHERE Name = 'UNKNOWN'];
        State__c newState;
        
        if (unknownState.isEmpty()) {
            newState = new State__c(Name = 'UNKNOWN');
            insert newState;
        } else {
            newState = unknownState[0];
        }
    
        // Create new counties if they don't exist
        List<County__c> newCounties = new List<County__c>();
        for (String countyName : countyNames) {
            if (!countyMap.containsKey(countyName)) {
                newCounties.add(new County__c(Name = countyName, State__c = newState.Id));
            }
        }
    
        if (!newCounties.isEmpty()) {
            insert newCounties;
            for (County__c county : newCounties) {
                countyMap.put(county.Name, county.Id);
            }
        }
    
        // Assign correct County__c Ids to leads
        for (Lead lead : leadList) {
            if (String.isNotBlank(lead.County__c) && countyMap.containsKey(lead.County__c)) {
                lead.County__c = countyMap.get(lead.County__c);
            }
        }
    
        // Insert leads with partial success handling
        List<Database.SaveResult> results = Database.insert(leadList, false);
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                insertedLeads.add(leadList[i]); // Add successfully inserted lead
            }
        }
    
        return insertedLeads; // Return only successfully inserted leads
    }
    

    @AuraEnabled
    public static void sendEmailNotification(Integer insertedCount, Integer failedCount) {
     try {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{'bensaid303@gmail.com'});
        mail.setSubject('Lead Import Summary');
        mail.setPlainTextBody('The following lead import has been completed:\n\n' + 
                      '* Leads created successfully: ' + insertedCount + '\n' + 
                      '* Leads failed to insert: ' + failedCount + '\n\n' + 
                      'Best regards,\nSalesforce System' + '\n' + 
                      'Timestamp: ' + System.now() 
                      );

        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
        
    } catch (Exception e) {
        throw new AuraHandledException('Error sending email: ' + e.getMessage());
    }
}

}
