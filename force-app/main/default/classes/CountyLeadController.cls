public with sharing class CountyLeadController {
  @AuraEnabled
  public static Map<String, List<Map<String, String>>> insertLeads(
    List<Lead> leadList
  ) {
    List<Map<String, String>> failedLeads = new List<Map<String, String>>();
    List<Map<String, String>> insertedLeads = new List<Map<String, String>>();

    Set<String> countyNames = new Set<String>();
    for (Lead lead : leadList) {
      if (String.isNotBlank(lead.County__c)) {
        countyNames.add(lead.County__c);
      }
    }

    Map<String, Id> countyMap = new Map<String, Id>();
    if (!countyNames.isEmpty()) {
      for (County__c county : [
        SELECT Id, Name
        FROM County__c
        WHERE Name IN :countyNames
      ]) {
        countyMap.put(county.Name, county.Id);
      }
    }

    for (Lead lead : leadList) {
      if (
        String.isNotBlank(lead.County__c) &&
        countyMap.containsKey(lead.County__c)
      ) {
        lead.County__c = countyMap.get(lead.County__c);
      }
    }

    List<Database.SaveResult> results = Database.insert(leadList, false);

    for (Integer i = 0; i < results.size(); i++) {
      Map<String, String> leadData = new Map<String, String>{
        'FirstName' => leadList[i].FirstName,
        'LastName' => leadList[i].LastName,
        'Company' => leadList[i].Company,
        'Phone' => leadList[i].Phone,
        'Email' => leadList[i].Email,
        'Property_Owner__c' => leadList[i].Property_Owner__c,
        'Site_Acreage__c' => String.valueOf(leadList[i].Site_Acreage__c),
        'Parcel_ID__c' => leadList[i].Parcel_ID__c,
        'Site_Address__c' => leadList[i].Site_Address__c,
        'Site_City__c' => leadList[i].Site_City__c,
        'County__c' => leadList[i].County__c,
        'Lead_Land_Owner_Address__City__s' => leadList[i]
          .Lead_Land_Owner_Address__City__s,
        'Lead_Land_Owner_Address__StateCode__s' => leadList[i]
          .Lead_Land_Owner_Address__StateCode__s,
        'Lead_Land_Owner_Address__PostalCode__s' => leadList[i]
          .Lead_Land_Owner_Address__PostalCode__s
      };

      if (!results[i].isSuccess()) {
        String errorMessage = '';
        for (Database.Error error : results[i].getErrors()) {
          errorMessage += error.getMessage() + ' ';
        }
        leadData.put('Error', errorMessage.trim());
        failedLeads.add(leadData);
      } else {
        insertedLeads.add(leadData);
      }
    }

    return new Map<String, List<Map<String, String>>>{
      'insertedLeads' => insertedLeads,
      'failedLeads' => failedLeads
    };
  }

  @AuraEnabled
  public static void sendEmailNotification(
    Integer insertedCount,
    Integer failedCount,
    List<Map<String, String>> insertedLeads,
    List<Map<String, String>> failedLeads
  ) {
    try {
      String currentUserEmail = [
        SELECT Email
        FROM User
        WHERE Id = :UserInfo.getUserId()
      ]
      .Email;

      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      mail.setToAddresses(new List<String>{ currentUserEmail });
      mail.setSubject('Lead Import Summary');

      String htmlBody =
        '<html><body>' +
        '<p>The following lead import has been completed:</p>' +
        '<ul>' +
        '<li><strong>Leads created successfully:</strong> ' +
        insertedCount +
        '</li>' +
        '<li><strong>Leads failed to insert:</strong> ' +
        failedCount +
        '</li>' +
        '</ul>' +
        '<p>Best regards,<br>Salesforce System</p>' +
        '</body></html>';
      mail.setHtmlBody(htmlBody);

      List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();

      if (!insertedLeads.isEmpty()) {
        String insertedCsv = generateCsv(insertedLeads, 'Inserted_Leads.csv');
        Messaging.EmailFileAttachment insertedAttachment = new Messaging.EmailFileAttachment();
        insertedAttachment.setFilename('Inserted_Leads.csv');
        insertedAttachment.setBody(Blob.valueOf(insertedCsv));
        insertedAttachment.setContentType('text/csv');
        attachments.add(insertedAttachment);
      }

      if (!failedLeads.isEmpty()) {
        String failedCsv = generateCsv(failedLeads, 'Failed_Leads.csv');
        Messaging.EmailFileAttachment failedAttachment = new Messaging.EmailFileAttachment();
        failedAttachment.setFilename('Failed_Leads.csv');
        failedAttachment.setBody(Blob.valueOf(failedCsv));
        failedAttachment.setContentType('text/csv');
        attachments.add(failedAttachment);
      }

      mail.setFileAttachments(attachments);
      Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    } catch (Exception e) {
      throw new AuraHandledException('Error sending email: ' + e.getMessage());
    }
  }

  // Helper function to generate CSV content
  private static String generateCsv(
    List<Map<String, String>> leads,
    String filename
  ) {
    String csvData = 'FirstName,LastName,Company,Phone,Email,Property_Owner__c,Site_Acreage__c,Parcel_ID__c,Site_Address__c,Site_City__c,County__c,Lead_Land_Owner_Address__City__s,Lead_Land_Owner_Address__StateCode__s,Lead_Land_Owner_Address__PostalCode__s\n';

    for (Map<String, String> lead : leads) {
      csvData +=
        '"' +
        lead.get('FirstName') +
        '","' +
        lead.get('LastName') +
        '","' +
        lead.get('Company') +
        '","' +
        lead.get('Phone') +
        '","' +
        lead.get('Email') +
        '","' +
        lead.get('Property_Owner__c') +
        '","' +
        lead.get('Site_Acreage__c') +
        '","' +
        lead.get('Parcel_ID__c') +
        '","' +
        lead.get('Site_Address__c') +
        '","' +
        lead.get('Site_City__c') +
        '","' +
        lead.get('County__c') +
        '","' +
        lead.get('Lead_Land_Owner_Address__City__s') +
        '","' +
        lead.get('Lead_Land_Owner_Address__StateCode__s') +
        '","' +
        lead.get('Lead_Land_Owner_Address__PostalCode__s') +
        '"\n';
    }

    return csvData;
  }
}
