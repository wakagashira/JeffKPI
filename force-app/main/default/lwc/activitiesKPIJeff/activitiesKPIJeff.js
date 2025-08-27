import { LightningElement, wire, track } from 'lwc';
import getUserActivitySummary from '@salesforce/apex/UserHierarchyController.getUserActivitySummary';

export default class ActivitiesKPIJeff extends LightningElement {
    @track summaries;
    @track errorMessage;

    @wire(getUserActivitySummary)
    wiredSummaries({ data, error }) {
        if (data) {
            this.summaries = data;
            this.errorMessage = undefined;
        } else if (error) {
            this.summaries = undefined;
            this.errorMessage = (error.body && error.body.message)
                ? error.body.message
                : JSON.stringify(error);
        }
    }
}
