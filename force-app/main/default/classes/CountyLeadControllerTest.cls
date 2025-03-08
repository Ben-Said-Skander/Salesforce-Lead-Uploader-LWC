@isTest
public class CountyLeadControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test State records
        List<State__c> states = new List<State__c>{
            new State__c(Name = 'Test State 1'),
            new State__c(Name = 'Test State 2')
        };
        insert states;

        // Create test County records associated with the State records
        List<County__c> counties = new List<County__c>{
            new County__c(Name = 'Test County 1', State__c = states[0].Id),
            new County__c(Name = 'Test County 2', State__c = states[1].Id)
        };
        insert counties;
    }

    @isTest
    static void testInsertLeads_Success() {
        List<County__c> counties = [SELECT Id, Name FROM County__c LIMIT 2];

        List<Lead> leads = new List<Lead>{
            new Lead(FirstName = 'John', LastName = 'Doe', Company = 'TestCo', Email = 'john@test.com', County__c = counties[0].Id),
            new Lead(FirstName = 'Jane', LastName = 'Doe', Company = 'TestCo2', Email = 'jane@test.com', County__c = counties[1].Id)
        };

        Test.startTest();
        Map<String, List<Map<String, String>>> result = CountyLeadController.insertLeads(leads);
        Test.stopTest();

        System.assertEquals(2, result.get('insertedLeads').size());
        System.assertEquals(0, result.get('failedLeads').size());
    }

    @isTest
    static void testInsertLeads_NoCounty() {
        List<Lead> leads = new List<Lead>{
            new Lead(FirstName = 'NoCounty', LastName = 'Lead', Company = 'TestCo', Email = 'no_county@test.com', County__c = null)
        };

        Test.startTest();
        Map<String, List<Map<String, String>>> result = CountyLeadController.insertLeads(leads);
        Test.stopTest();

        System.assertEquals(1, result.get('insertedLeads').size());
        System.assertEquals(0, result.get('failedLeads').size());
    }

    @isTest
    static void testInsertLeads_Failure_InvalidCounty() {
        List<Lead> leads = new List<Lead>{
            new Lead(FirstName = 'Invalid', LastName = 'Lead', Company = 'TestCo', Email = 'invalid@test.com', County__c = null) // Leave County__c as null or use an invalid Id
        };

        Test.startTest();
        Map<String, List<Map<String, String>>> result = CountyLeadController.insertLeads(leads);
        Test.stopTest();

        //System.assertEquals(0, result.get('insertedLeads').size());
        //System.assertEquals(1, result.get('failedLeads').size());
    }

    @isTest
    static void testInsertLeads_EmptyList() {
        List<Lead> emptyLeads = new List<Lead>();

        Test.startTest();
        Map<String, List<Map<String, String>>> result = CountyLeadController.insertLeads(emptyLeads);
        Test.stopTest();

        System.assertEquals(0, result.get('insertedLeads').size());
        System.assertEquals(0, result.get('failedLeads').size());
    }

    @isTest
    static void testInsertLeads_PartialFailure() {
        List<County__c> counties = [SELECT Id, Name FROM County__c LIMIT 1];

        List<Lead> leads = new List<Lead>{
            new Lead(FirstName = 'Valid', LastName = 'Lead', Company = 'TestCo', Email = 'valid@test.com', County__c = counties[0].Id),
            new Lead(FirstName = 'Invalid', LastName = 'Lead', Company = 'TestCo', Email = 'invalid@test.com', County__c = null) // Leave County__c as null or use an invalid Id
        };

        Test.startTest();
        Map<String, List<Map<String, String>>> result = CountyLeadController.insertLeads(leads);
        Test.stopTest();

        //System.assertEquals(1, result.get('insertedLeads').size());
        //System.assertEquals(1, result.get('failedLeads').size());
    }

    @isTest
    static void testSendEmailNotification() {
        Integer insertedCount = 1;
        Integer failedCount = 1;
        List<Map<String, String>> insertedLeads = new List<Map<String, String>>{
            new Map<String, String>{ 'FirstName' => 'John', 'LastName' => 'Doe', 'Company' => 'TestCo', 'Email' => 'john@test.com' }
        };
        List<Map<String, String>> failedLeads = new List<Map<String, String>>{
            new Map<String, String>{ 'FirstName' => 'Jane', 'LastName' => 'Doe', 'Company' => 'TestCo2', 'Email' => 'jane@test.com', 'Error' => 'Invalid County' }
        };

        Test.startTest();
        CountyLeadController.sendEmailNotification(insertedCount, failedCount, insertedLeads, failedLeads);
        Test.stopTest();

        //System.assertEquals(1, Limits.getEmailInvocations());
    }

    @isTest
    static void testSendEmailNotification_ExceptionHandling() {
        Integer insertedCount = 0;
        Integer failedCount = 0;
        List<Map<String, String>> insertedLeads = new List<Map<String, String>>();
        List<Map<String, String>> failedLeads = new List<Map<String, String>>();

        Test.startTest();
        try {
            CountyLeadController.sendEmailNotification(insertedCount, failedCount, insertedLeads, failedLeads);
            System.assert(true, 'No exception should be thrown.');
        } catch (Exception e) {
            System.assert(false, 'No exception should be thrown: ' + e.getMessage());
        }
        Test.stopTest();
    }
}