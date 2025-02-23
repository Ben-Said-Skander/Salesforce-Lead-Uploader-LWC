import { LightningElement, track } from 'lwc';
import insertLeads from '@salesforce/apex/CountyLeadController.insertLeads';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LeadUploader extends LightningElement {
    @track fileData;
    @track uploadedLeads = []; // Stores inserted leads for display
    @track fileName = ''; // Stores the uploaded file name
    @track leadCount = 0; // Stores the number of leads inserted

    columns = [
        { label: 'First Name', fieldName: 'FirstName' },
        { label: 'Last Name', fieldName: 'LastName' },
        { label: 'Company', fieldName: 'Company' }
    ];

    handleFileChange(event) {
        const file = event.target.files[0];
        if (file) {
            this.fileName = file.name; // Store file name
            const reader = new FileReader();
            reader.onload = (e) => {
                const csv = e.target.result;
                this.fileData = this.parseCSV(csv);
            };
            reader.readAsText(file);
        }
    }

    parseCSV(csv) {
        const rows = csv.split('\n');
        const headers = rows[0].split(',');
        const leads = [];

        for (let i = 1; i < rows.length; i++) {
            const values = rows[i].split(',');
            if (values.length === headers.length) {
                let lead = {
                    LastName: '',
                    FirstName: '',
                    Company: ''
                };

                headers.forEach((header, index) => {
                    const value = values[index].trim();
                    if (header.trim() === 'Property Owner Last Name') {
                        lead.LastName = value;
                    } else if (header.trim() === 'Property Owner First Name') {
                        lead.FirstName = value;
                    } else if (header.trim() === 'Business Name') {
                        lead.Company = value;
                    } else if (header.trim() === 'Acreage') {
                        lead.Site_Acreage__c = value ? parseFloat(value) : null;
                    } else if (header.trim() === 'Millage Rate') {
                        lead.Millage__c = value ? parseFloat(value) : null;
                    } else if (header.trim() === 'Land Value') {
                        lead.Land_Value__c = value ? parseFloat(value) : null;
                    } else if (header.trim() === 'Parcel ID') {
                        lead.Parcel_ID__c = value || null;
                    } else if (header.trim() === 'Landowner City') {
                        lead.Lead_Land_Owner_Address__City__s = value || null;
                    } else if (header.trim() === 'Landowner State') {
                        lead.Lead_Land_Owner_Address__StateCode__s = value || null;
                    } else if (header.trim() === 'Landowner Zip') {
                        lead.Lead_Land_Owner_Address__PostalCode__s = value || null;
                    } else if (header.trim() === 'Site Address') {
                        lead.Site_Address__c = value || null;
                    } else if (header.trim() === 'County') {
                        lead.County__c = value || null;
                    }
                });

                if (lead.LastName && lead.FirstName && lead.Company) {
                    leads.push(lead);
                }
            }
        }
        return leads;
    }

    handleUpload() {
        if (this.fileData && this.fileData.length > 0) {
            insertLeads({ leadList: this.fileData })
                .then((result) => {
                    this.uploadedLeads = result; // Store inserted leads for display
                    this.leadCount = result.length; // Set lead count
                    this.showToast('Success', 'Leads imported successfully', 'success');
                })
                .catch(error => {
                    this.showToast('Error', error.body.message, 'error');
                });
        } else {
            this.showToast('Error', 'No valid data to upload', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }

    get hasLeads() {
        return this.uploadedLeads.length > 0;
    }
}
