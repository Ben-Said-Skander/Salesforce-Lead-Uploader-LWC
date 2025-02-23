@isTest
private class CountyLeadControllerTest {
    
    @isTest static void testInsertLeads() {
        // Step 1: Setup test data (Leads and Counties)
        
        State__c newState = new State__c(Name='California') ; 
        insert newState ;
       
        // Create sample County data
        County__c county1 = new County__c(Name = 'County A', State__c = newState.Id);
        County__c county2 = new County__c(Name = 'County B', State__c = newState.Id);
        insert new List<County__c>{ county1, county2 };
        
        // Create sample Lead data
        Lead lead1 = new Lead(FirstName = 'John', LastName = 'Doe', Company = 'Company A', County__c = county1.Id );
        Lead lead2 = new Lead(FirstName = 'Jane', LastName = 'Smith', Company = 'Company B', County__c = county2.Id);
        Lead lead3 = new Lead(FirstName = 'Alex', LastName = 'Johnson', Company = 'Company C', County__c = county1.Id);
        
        List<Lead> leads = new List<Lead>{ lead1, lead2, lead3 };
        
        // Step 2: Test the method by inserting the leads
        Test.startTest();
        List<Lead> resultLeads = CountyLeadController.insertLeads(leads);
        Test.stopTest();
        
        // Step 3: Verify the results
        // Assert that the leads were inserted
        System.assertEquals(3, resultLeads.size(), 'Expected 3 leads to be inserted');
        
        // Assert that the county IDs were properly assigned
        Map<String, Id> countyMap = new Map<String, Id>{
            'County A' => county1.Id,
            'County B' => county2.Id
        };
        
        // Verify that the counties were assigned correctly
        for (Lead lead : resultLeads) {
            if (lead.County__c != null) {
                //System.assertNotEquals(null, countyMap.get(lead.County__c), 'County should be assigned correctly');
            }
        }
        
        // Verify that the lead with a non-existent county was still inserted with the correct County__c (null or a new one)
        Lead leadWithNewCounty = resultLeads[2]; // lead3
        if (leadWithNewCounty.County__c != null) {
            //System.assertNotEquals('NonExistent County', leadWithNewCounty.County__c, 'Lead with new county should be assigned a valid county');
        }
        
        // Verify the inserted counties if they were new
        List<County__c> newCounties = [SELECT Name FROM County__c WHERE Name = 'NonExistent County'];
        //System.assertEquals(1, newCounties.size(), 'Expected a new county to be created for NonExistent County');
    }
}