import { LightningElement, wire, track } from 'lwc';
import getUsersInMyHierarchy from '@salesforce/apex/UserHierarchyController.getUsersInMyHierarchy';

export default class ActivitiesKPIJeff extends LightningElement {
    @track users;
    @track errorMessage;

    columns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'First Name', fieldName: 'FirstName' },
        { label: 'Last Name', fieldName: 'LastName' },
        { label: 'Email', fieldName: 'Email', type: 'email' },
        { label: 'Title', fieldName: 'Title' },
        { label: 'Role', fieldName: 'UserRole.Name' }
    ];

    @wire(getUsersInMyHierarchy)
    wiredUsers({ data, error }) {
        if (data) {
            this.users = data;
            this.errorMessage = undefined;
        } else if (error) {
            this.errorMessage = (error.body && error.body.message)
                ? error.body.message
                : JSON.stringify(error);
            this.users = undefined;
        }
    }
}
