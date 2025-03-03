public with sharing class CountyLeadController {

    @AuraEnabled
    public static List<Map<String, String>> insertLeads(List<Lead> leadList) {
        List<Map<String, String>> failedLeads = new List<Map<String, String>>();

        // Collect county names
        Set<String> countyNames = new Set<String>();
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
 
        // Collect failed leads with structured data
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                Map<String, String> failedLeadData = new Map<String, String>();
                failedLeadData.put('FirstName', leadList[i].FirstName);
                failedLeadData.put('LastName', leadList[i].LastName);
                failedLeadData.put('Company', leadList[i].Company);
                failedLeadData.put('Phone', leadList[i].Phone);
                failedLeadData.put('Email', leadList[i].Email);
                failedLeadData.put('Property_Owner__c', leadList[i].Property_Owner__c);
                failedLeadData.put('Site_Acreage__c', String.valueOf(leadList[i].Site_Acreage__c));
                failedLeadData.put('Parcel_ID__c', leadList[i].Parcel_ID__c);
                failedLeadData.put('Site_Address__c', leadList[i].Site_Address__c);
                failedLeadData.put('Site_City__c', leadList[i].Site_City__c);
                failedLeadData.put('County__c', leadList[i].County__c);
                failedLeadData.put('Lead_Land_Owner_Address__City__s', leadList[i].Lead_Land_Owner_Address__City__s);
                failedLeadData.put('Lead_Land_Owner_Address__StateCode__s', leadList[i].Lead_Land_Owner_Address__StateCode__s);
                failedLeadData.put('Lead_Land_Owner_Address__PostalCode__s', leadList[i].Lead_Land_Owner_Address__PostalCode__s);

                // Collect error messages
                String errorMessage = '';
                for (Database.Error error : results[i].getErrors()) {
                    errorMessage += error.getMessage() + ' ';
                }
                failedLeadData.put('Error', errorMessage.trim());

                failedLeads.add(failedLeadData);
            }
        }

        return failedLeads; // Return structured data
    }

    @AuraEnabled
    public static void sendEmailNotification(Integer insertedCount, Integer failedCount, List<Map<String, String>> failedLeads) {
     try {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{'bensaid303@gmail.com'});
        mail.setSubject('Lead Import Summary');
        
        // Email body
        String htmlBody = '<html><body>' +
            '<p>The following lead import has been completed:</p>' +
            '<ul>' +
            '<li><strong>Leads created successfully:</strong> ' + insertedCount + '</li>' +
            '<li><strong>Leads failed to insert:</strong> ' + failedCount + '</li>' +
            '</ul>' +
            '<p>Best regards,<br>Salesforce System</p>' +
            '</body></html>';
        
        mail.setHtmlBody(htmlBody);

        // Generate CSV content
        if (!failedLeads.isEmpty()) {
            String csvData = 'FirstName,LastName,Company,Phone,Email,Property_Owner__c,Site_Acreage__c,Parcel_ID__c,Site_Address__c,Site_City__c,County__c,Lead_Land_Owner_Address__City__s,Lead_Land_Owner_Address__StateCode__s,Lead_Land_Owner_Address__PostalCode__s,Error\n';

            for (Map<String, String> lead : failedLeads) {
                csvData += '"' + lead.get('FirstName') + '","' + lead.get('LastName') + '","' + lead.get('Company') + '","' +
                           lead.get('Phone') + '","' + lead.get('Email') + '","' + lead.get('Property_Owner__c') + '","' +
                           lead.get('Site_Acreage__c') + '","' + lead.get('Parcel_ID__c') + '","' + lead.get('Site_Address__c') + '","' +
                           lead.get('Site_City__c') + '","' + lead.get('County__c') + '","' + lead.get('Lead_Land_Owner_Address__City__s') + '","' +
                           lead.get('Lead_Land_Owner_Address__StateCode__s') + '","' + lead.get('Lead_Land_Owner_Address__PostalCode__s') + '","' +
                           lead.get('Error') + '"\n';
            }

            // Convert CSV string to Blob
            Blob csvBlob = Blob.valueOf(csvData);

            // Create email attachment
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFilename('Failed_Leads.csv');
            attachment.setBody(csvBlob);
            attachment.setContentType('text/csv');

            // Attach the CSV file to the email
            mail.setFileAttachments(new Messaging.EmailFileAttachment[]{attachment});
        }

        // Send email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        
    } catch (Exception e) {
        throw new AuraHandledException('Error sending email: ' + e.getMessage());
    }
}

    

}
