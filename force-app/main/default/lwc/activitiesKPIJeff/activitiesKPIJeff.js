import { LightningElement, wire, track } from 'lwc';
import getUserActivitySummary from '@salesforce/apex/UserHierarchyController.getUserActivitySummary';

export default class ActivitiesKPIJeff extends LightningElement {
    @track groupedData = [];
    @track filteredData = [];
    @track errorMessage;

    @track partnerOptions = [{ label: 'All Partners', value: 'All' }];
    @track userOptions = [{ label: 'All Users', value: 'All' }];
    @track selectedPartner = 'All';
    @track selectedUser = 'All';

    @wire(getUserActivitySummary)
    wiredSummaries({ data, error }) {
        if (data) {
            this.errorMessage = undefined;
            const groups = {};
            const allUsers = [];

            data.forEach(user => {
                const partner = user.partnerName || 'No Partner';
                if (!groups[partner]) {
                    groups[partner] = [];
                }
                groups[partner].push(user);
                allUsers.push({ label: user.name, value: user.userId });
            });

            this.groupedData = Object.keys(groups)
                .sort((a, b) => a.localeCompare(b))
                .map(partner => ({
                    partner,
                    users: groups[partner].sort((a, b) =>
                        (a.name || '').localeCompare(b.name || '')
                    )
                }));

            this.partnerOptions = [{ label: 'All Partners', value: 'All' }]
                .concat(Object.keys(groups).map(p => ({ label: p, value: p })));

            this.userOptions = [{ label: 'All Users', value: 'All' }]
                .concat(allUsers.sort((a, b) => a.label.localeCompare(b.label)));

            this.applyFilters();
        } else if (error) {
            this.groupedData = [];
            this.filteredData = [];
            this.errorMessage = (error.body && error.body.message)
                ? error.body.message
                : JSON.stringify(error);
        }
    }

    handlePartnerChange(event) {
        this.selectedPartner = event.detail.value;
        this.applyFilters();
    }

    handleUserChange(event) {
        this.selectedUser = event.detail.value;
        this.applyFilters();
    }

    applyFilters() {
        let data = JSON.parse(JSON.stringify(this.groupedData));

        if (this.selectedPartner !== 'All') {
            data = data.filter(g => g.partner === this.selectedPartner);
        }

        if (this.selectedUser !== 'All') {
            data.forEach(g => {
                g.users = g.users.filter(u => u.userId === this.selectedUser);
            });
        }

        data = data.filter(g => g.users.length > 0);
        this.filteredData = data;
    }
}
