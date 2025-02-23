public with sharing class CountyLeadController {
    
    @AuraEnabled
    public static List<Lead> insertLeads(List<Lead> leadList) {
        try {
            Set<String> countyNames = new Set<String>();

            for (Lead lead : leadList) {
                if (String.isNotBlank(lead.County__c)) { 
                    countyNames.add(lead.County__c);
                }
            }

            Map<String, Id> countyMap = new Map<String, Id>();
            if (!countyNames.isEmpty()) {
                for (County__c county : [SELECT Id, Name FROM County__c WHERE Name IN :countyNames]) {
                    countyMap.put(county.Name, county.Id);
                }
            }

            List<State__c> unknownState = [SELECT Id, Name FROM State__c WHERE Name = 'UNKNOWN'];
            State__c newState = (unknownState.isEmpty()) ? new State__c(Name = 'UNKNOWN') : unknownState[0];

            if (unknownState.isEmpty()) {
                insert newState;
            }

            List<County__c> newCounties = new List<County__c>();
            for (Lead lead : leadList) {
                if (String.isNotBlank(lead.County__c)) {
                    if (countyMap.containsKey(lead.County__c)) {
                        lead.County__c = countyMap.get(lead.County__c);
                    } else {
                        County__c newCounty = new County__c(
                            Name = lead.County__c,
                            State__c = newState.Id
                        );
                        newCounties.add(newCounty);
                    }
                }
            }

            if (!newCounties.isEmpty()) {
                insert newCounties;
                for (County__c county : newCounties) {
                    countyMap.put(county.Name, county.Id);
                }
                for (Lead lead : leadList) {
                    if (String.isNotBlank(lead.County__c) && countyMap.containsKey(lead.County__c)) {
                        lead.County__c = countyMap.get(lead.County__c);
                    }
                }
            }

            // Remove empty fields before inserting leads
            for (Lead lead : leadList) {
                if (String.isBlank(lead.Parcel_ID__c)) lead.Parcel_ID__c = null;
                if (String.isBlank(lead.Lead_Land_Owner_Address__City__s)) lead.Lead_Land_Owner_Address__City__s = null;
                if (String.isBlank(lead.Lead_Land_Owner_Address__StateCode__s)) lead.Lead_Land_Owner_Address__StateCode__s = null;
                if (String.isBlank(lead.Lead_Land_Owner_Address__PostalCode__s)) lead.Lead_Land_Owner_Address__PostalCode__s = null;
                if (String.isBlank(lead.Site_Address__c)) lead.Site_Address__c = null;
            }

            insert leadList;
            return [SELECT Id, FirstName, LastName, Company, County__c FROM Lead WHERE Id IN :leadList];

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
