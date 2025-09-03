import { LightningElement, wire, track } from 'lwc';
import getUserActivitySummary from '@salesforce/apex/UserHierarchyController.getUserActivitySummary';
import getOpportunityMetrics from '@salesforce/apex/UserHierarchyController.getOpportunityMetrics';

export default class ActivitiesKPIJeff extends LightningElement {
    @track groupedData = [];
    @track filteredData = [];
    @track errorMessage;

    @track partnerOptions = [{ label: 'All Partners', value: 'All' }];
    @track userOptions = [{ label: 'All Users', value: 'All' }];
    @track selectedPartner = 'All';
    @track selectedUser = 'All';
    @track selectedTimeframe = 'ThisMonth';

    @track pipelineValue = 0;
    @track averageDealSize = 0;
    @track conversionRate = 0;

    get pipelineValueFormatted() {
        try { return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD' }).format(this.pipelineValue || 0); }
        catch(e) { return `$${(this.pipelineValue || 0).toLocaleString()}`; }
    }
    get avgDealSizeFormatted() {
        try { return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD' }).format(this.averageDealSize || 0); }
        catch(e) { return `$${(this.averageDealSize || 0).toLocaleString()}`; }
    }
    get conversionRateFormatted() {
        return `${(this.conversionRate || 0).toFixed(1)}%`;
    }

    get timeframeOptions() {
        return [
            { label: 'Today', value: 'Today' },
            { label: 'Yesterday', value: 'Yesterday' },
            { label: 'This Week', value: 'ThisWeek' },
            { label: 'Last Week', value: 'LastWeek' },
            { label: 'Last 7 Days', value: 'Last7Days' },
            { label: 'This Month', value: 'ThisMonth' },
            { label: 'Last Month', value: 'LastMonth' },
            { label: 'This Quarter', value: 'ThisQuarter' },
            { label: 'Last Quarter', value: 'LastQuarter' },
            { label: 'This Year', value: 'ThisYear' },
            { label: 'Last Year', value: 'LastYear' }
        ];
    }

    @wire(getUserActivitySummary, { timeframe: '$selectedTimeframe' })
    wiredSummaries({ data, error }) {
        if (data) {
            this.errorMessage = undefined;
            const groups = {};
            const allUsers = [];

            data.forEach(user => {
                const partner = user.partnerName || 'No Partner';
                if (!groups[partner]) groups[partner] = [];
                groups[partner].push(user);
                allUsers.push({ label: user.name, value: user.userId });
            });

            this.groupedData = Object.keys(groups)
                .sort((a, b) => a.localeCompare(b))
                .map(partner => ({
                    partner,
                    users: groups[partner].sort((a, b) => (a.name || '').localeCompare(b.name || ''))
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

    @wire(getOpportunityMetrics, { timeframe: '$selectedTimeframe' })
    wiredMetrics({ data, error }) {
        if (data) {
            this.pipelineValue = data.pipelineValue || 0;
            this.averageDealSize = data.averageDealSize || 0;
            this.conversionRate = data.conversionRate || 0;
        } else if (error) {
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

    handleTimeframeChange(event) {
        this.selectedTimeframe = event.detail.value;
    }

    applyFilters() {
        let data = JSON.parse(JSON.stringify(this.groupedData));

        if (this.selectedPartner !== 'All') {
            data = data.filter(g => g.partner === this.selectedPartner);
        }

        if (this.selectedUser !== 'All') {
            data.forEach(g => g.users = g.users.filter(u => u.userId === this.selectedUser));
        }

        this.filteredData = data.filter(g => g.users.length > 0);
    }
}
