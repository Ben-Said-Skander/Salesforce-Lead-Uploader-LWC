import { LightningElement, track } from 'lwc';
import insertLeads from '@salesforce/apex/CountyLeadController.insertLeads';
import sendEmailNotification from '@salesforce/apex/CountyLeadController.sendEmailNotification';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LeadUploader extends LightningElement {
   
    @track fileData;
    @track uploadedLeads = [];
    @track failedLeads = [];
    @track fileName = '';
    @track leadCount = 0;
    @track failedLeadCount = 0;

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
        const leadsToInsert = [];

        for (let i = 1; i < rows.length; i++) {
            if (!rows[i].trim()) continue;
            const values = rows[i].split(',');
            if (values.length === headers.length) {
                let lead = {
                    LastName: null,
                    FirstName: null,
                    Company: null,
                    Phone: null,
                    Email: null,
                    Property_Owner__c: null,
                    Site_Acreage__c: null,
                    Parcel_ID__c: null,
                    Site_Address__c: null,
                    Site_City__c: null,
                    County__c: null,
                    Lead_Land_Owner_Address__City__s: null,
                    Lead_Land_Owner_Address__StateCode__s: null,
                    Lead_Land_Owner_Address__PostalCode__s: null
                };

                headers.forEach((header, index) => {
                    const trimmedHeader = header.trim();
                    const value = values[index].trim();
                    if (trimmedHeader === 'Owner 1 Last Name') {
                        lead.LastName = value || null;
                    } else if (trimmedHeader === 'Owner 1 First Name') {
                        lead.FirstName = value || null;
                    } else if (trimmedHeader === 'Owner 1 Last Name') {
                        lead.Company = value || null ;
                    } else if (trimmedHeader === 'Acreage') {
                        lead.Site_Acreage__c = value ? parseFloat(value) : null;
                    } else if (trimmedHeader === 'ID') {
                        lead.Parcel_ID__c = value || null;
                    } else if (trimmedHeader === 'Owner') {
                        lead.Property_Owner__c = value || null;
                    } else if (trimmedHeader === 'Owner 1 Cell Phone') {
                        lead.Phone = value || null;
                    } else if (trimmedHeader === 'Owner 1 Email') {
                        lead.Email = value || null;
                    } else if (trimmedHeader === 'Owner 1 City') {
                        lead.Lead_Land_Owner_Address__City__s = value || null;
                    } else if (trimmedHeader === 'Owner 1 State') {
                        lead.Lead_Land_Owner_Address__StateCode__s = value || null;
                    } else if (trimmedHeader === 'Owner 1 Zip') {
                        lead.Lead_Land_Owner_Address__PostalCode__s = value || null;
                    } else if (trimmedHeader === 'Parcel Address') {
                        lead.Site_Address__c = value || null;
                    } else if (trimmedHeader === 'Parcel County') {
                        lead.County__c = (value.charAt(0).toUpperCase() + value.slice(1).toLowerCase()) + ' County (' + (lead.Lead_Land_Owner_Address__StateCode__s || '') + ')';
                    } else if (trimmedHeader === 'Parcel City') {
                        lead.Site_City__c = value || null;
                    }
                });
                
                if(lead.LastName && !lead.Company){
                    lead.Company = lead.LastName ; 
                } 
                else if(!lead.LastName && lead.Company){
                    lead.LastName = lead.Company
                }
                leadsToInsert.push(lead);
            }
        }
        
        this.fileData = leadsToInsert;

    }

    handleUpload() {
        if (this.fileData && this.fileData.length > 0) {
            insertLeads({ leadList: this.fileData })
                .then((result) => {
                    this.uploadedLeads = result.insertedLeads;
                    this.failedLeads = result.failedLeads;
                    this.failedLeadCount = this.failedLeads.length;
                    this.leadCount = this.uploadedLeads.length;
    
                    return sendEmailNotification({ 
                        insertedCount: this.leadCount, 
                        failedCount: this.failedLeadCount,
                        insertedLeads: this.uploadedLeads, 
                        failedLeads: this.failedLeads 
                    });
                })
                .then(() => {
                    this.showToast('Success', `Leads imported: ${this.leadCount}, Failed: ${this.failedLeadCount}`, 'success');
                })
                .catch(error => {
                    this.showToast('Error', error.body.message, 'error');
                });
        } else {
            this.showToast('Error', 'No valid data to upload', 'error');
        }
    }
    
    
    // Download failed leads as CSV
    downloadFailedLeads() {
        if (this.failedLeads.length > 0) {
            // Define CSV headers (including Error column)
            const headers = [
                'Owner 1 First Name', 
                'Owner 1 Last Name', 
                'Prop Ind Mapping', 
                'Owner 1 Cell Phone', 
                'Owner 1 Email', 
                'Owner', 
                'Acreage', 
                'ID', 
                'Parcel Address', 
                'Parcel City', 
                'Parcel County', 
                'Owner 1 City', 
                'Owner 1 State', 
                'Owner 1 Zip', 
                'Error' 
            ];

        // Map failedLeads into CSV rows
        const rows = this.failedLeads.map(lead => [
            lead.FirstName || '',
            lead.LastName || '',
            lead.Company || '',
            lead.Phone || '',
            lead.Email || '',
            lead.Property_Owner__c || '',
            lead.Site_Acreage__c || '',
            lead.Parcel_ID__c || '',
            lead.Site_Address__c || '',
            lead.Site_City__c || '',
            lead.County__c || '',
            lead.Lead_Land_Owner_Address__City__s || '',
            lead.Lead_Land_Owner_Address__StateCode__s || '',
            lead.Lead_Land_Owner_Address__PostalCode__s || '',
            lead.Error || '' 
        ]);

        // Generate CSV content
        let csvContent = 'data:text/csv;charset=utf-8,';
        csvContent += headers.join(',') + '\n';
        rows.forEach(row => {
            csvContent += row.join(',') + '\n';
        });

        // Create a download link and trigger the download
        const encodedUri = encodeURI(csvContent);
        const link = document.createElement('a');
        link.setAttribute('href', encodedUri);
        link.setAttribute('download', 'failed_leads.csv');
        document.body.appendChild(link); // Required for Firefox
        link.click();
    } else {
        this.showToast('Error', 'No failed leads to download', 'error');
    }
}

    showToast(title, message, variant) {
       this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // Getter for inserted leads table
    get hasLeads() {
        return this.leadCount > 0;
    }

    // Getter for failed leads table
    get hasFailedLeads() {
        return this.failedLeadCount > 0;
    }

}