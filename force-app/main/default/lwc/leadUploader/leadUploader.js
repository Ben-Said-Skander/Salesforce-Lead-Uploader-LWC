import { LightningElement, track } from 'lwc';
import insertLeads from '@salesforce/apex/CountyLeadController.insertLeads';
import sendEmailNotification from '@salesforce/apex/CountyLeadController.sendEmailNotification';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LeadUploader extends LightningElement {
    
    @track fileData;         // Valid leads to be inserted
    @track uploadedLeads = []; // Inserted leads returned from Apex
    @track failedLeads = [];   // Leads that failed validation
    @track fileName = '';      // Stores the uploaded file name
    @track leadCount = 0;      // Number of leads inserted
    @track failedLeadCount = 0;      // Number of leads inserted

    // Define columns to display in the data tables.
    columns = [
        { label: 'First Name', fieldName: 'FirstName' },
        { label: 'Last Name', fieldName: 'LastName' },
        { label: 'Company', fieldName: 'Company' },
        { label: 'Phone', fieldName: 'Phone' },
        { label: 'Email', fieldName: 'Email' },
        { label: 'Property Owner', fieldName: 'Property_Owner__c' },
        { label: 'Acreage', fieldName: 'Site_Acreage__c' },
        { label: 'Parcel ID', fieldName: 'Parcel_ID__c' },
        { label: 'Parcel Address', fieldName: 'Site_Address__c' },
        { label: 'Parcel City', fieldName: 'Site_City__c' },
        { label: 'Parcel County', fieldName: 'County__c' },
        { label: 'Owner 1 City', fieldName: 'Lead_Land_Owner_Address__City__s' },
        { label: 'Owner 1 State', fieldName: 'Lead_Land_Owner_Address__StateCode__s' },
        { label: 'Owner 1 Zip', fieldName: 'Lead_Land_Owner_Address__PostalCode__s' }
    ];
    

    handleFileChange(event) {
        const file = event.target.files[0];
        if (file) {
            this.fileName = file.name; 
            const reader = new FileReader();
            reader.onload = (e) => {
                const csv = e.target.result;
                this.parseCSV(csv);
            };
            reader.readAsText(file);
        }
    }

    parseCSV(csv) {
        const rows = csv.split('\n');
        const headers = rows[0].split(',');
        const validLeads = [];
        const invalidLeads = [];

        // Loop through each row (starting at row 1 to skip header)
        for (let i = 1; i < rows.length; i++) {
            // Skip any empty lines.
            if (!rows[i].trim()) continue;

            const values = rows[i].split(',');
            if (values.length === headers.length) {
                // Build a lead record with default properties.
                let lead = {
                    LastName: '',
                    FirstName: '',
                    Company: '',
                    Phone: '',
                    Email: '',
                    Property_Owner__c: '',
                    Site_Acreage__c: null,
                    Parcel_ID__c: null,
                    Site_Address__c: '',
                    Site_City__c: '',
                    County__c: '',
                    Lead_Land_Owner_Address__City__s: '',
                    Lead_Land_Owner_Address__StateCode__s: '',
                    Lead_Land_Owner_Address__PostalCode__s: ''
                };
                

                headers.forEach((header, index) => {
                    const trimmedHeader = header.trim();
                    const value = values[index].trim();
                  
                    if (trimmedHeader === 'Owner 1 Last Name') {
                        lead.LastName = value;
                    } else if (trimmedHeader === 'Owner 1 First Name') {
                        lead.FirstName = value || null;
                    } 
               
                    else if (trimmedHeader === 'Prop Ind Mapping') {
                        lead.Company = value;
                    }        
                    else if (trimmedHeader === 'Acreage') {
                        lead.Site_Acreage__c = value ? parseFloat(value) : null;
                    } else if (trimmedHeader === 'ID') {
                        lead.Parcel_ID__c = value || null;
                    }           
                    else if (trimmedHeader === 'Owner') {
                        lead.Property_Owner__c = value || null;
                    }
                    else if (trimmedHeader === 'Owner 1 Cell Phone') {
                        lead.Phone = value || null;
                    }
                    else if (trimmedHeader === 'Owner 1 Email') {
                        lead.Email = value || null;
                    }
                    else if (trimmedHeader === 'Owner 2 Last Name') {
                        lead.Property_Owner_2__c = value || null;
                    }      
                    else if (trimmedHeader === 'Owner 1 City') {
                        lead.Lead_Land_Owner_Address__City__s = value || null;
                    } else if (trimmedHeader === 'Owner 1 State') {
                        lead.Lead_Land_Owner_Address__StateCode__s = value || null;
                    } else if (trimmedHeader === 'Owner 1 Zip') {
                        lead.Lead_Land_Owner_Address__PostalCode__s = value || null;
                    } else if (trimmedHeader === 'Parcel Address') {
                        lead.Site_Address__c = value || null;
                    }       
                    else if (trimmedHeader === 'Parcel County') {
                        lead.County__c = value || null;
                    }
                    else if (trimmedHeader === 'Parcel City') {
                        lead.Site_City__c = value || null;
                    }
                });

                // If LastName is not provided, assign the Business Name to LastName.
                if (!lead.LastName && lead.Company) {
                    lead.LastName = lead.Company;
                } else if (!lead.Company && lead.LastName  ){
                    lead.Company = lead.LastName ;
                }

                // Validate required fields: LastName and Company.
                if (!lead.LastName && !lead.Company) {
                    invalidLeads.push(lead);
                } 
                    
                validLeads.push(lead);
                
            }
        }
        this.fileData = validLeads;
        this.failedLeads = invalidLeads;
    }

    handleUpload() {
        if (this.fileData && this.fileData.length > 0) {
            insertLeads({ leadList: this.fileData })
                .then((insertedLeads) => {
                    this.uploadedLeads = insertedLeads;
                    this.leadCount = this.uploadedLeads.length;
                    this.failedLeadCount = this.failedLeads.length ; 
                    // Send email notification
                    return sendEmailNotification({ insertedCount: this.leadCount , failedCount: this.failedLeadCount});
                })
                .then(() => {
                    this.showToast('Success', `Leads imported successfully: ${this.leadCount}`, 'success');
                })
                .catch(error => {
                    this.showToast('Error', error.body.message, 'error');
                });
        } else {
            this.showToast('Error', 'No valid data to upload', 'error');
        }
    }
    

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // Getter for inserted leads table
    get hasLeads() {
        return this.uploadedLeads.length > 0;
    }

    // Getter for failed leads table
    get hasFailedLeads() {
        return this.failedLeads.length > 0;
    }

   
}