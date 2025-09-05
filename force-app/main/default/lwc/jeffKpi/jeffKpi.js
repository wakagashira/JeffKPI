const VERSION = "5.0.3";
import { LightningElement, wire, track } from 'lwc';
import getFilterOptions from '@salesforce/apex/JeffKPIController.getFilterOptions';
import getUserKpis from '@salesforce/apex/JeffKPIController.getUserKpis';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class JeffKpi extends LightningElement {
    version = "5.0.5";
    get headerText() { return `Jeff KPI v${this.version}`; }

    @track partnerOptions = [];
    @track userOptions = [];
    @track timeframeOptions = [
        { label: 'Last 7 Days', value: '7' },
        { label: 'Last 30 Days', value: '30' }
    ];

    selectedPartner = 'ALL';
    selectedUser = 'ALL';
    timeframeDays = '7';

    loading = true;
    userKpis = [];

    get userKpisToShow() {
        if (!this.userKpis) return [];
        if (this.selectedUser === 'ALL') return this.userKpis;
        return this.userKpis.filter(u => String(u.userId) === String(this.selectedUser));
    }

    @wire(getFilterOptions)
    wiredFilters({ error, data }) {
        if (data) {
            this.partnerOptions = [{ label: 'All Partners', value: 'ALL' }, ...data.partners.map(p => ({ label: p.label, value: p.value }))];
            this.userOptions = [{ label: 'All Users', value: 'ALL' }, ...data.users.map(u => ({ label: u.label, value: u.value }))];
            this.loading = false;
            this.loadAll();
        } else if (error) {
            this.loading = false;
            this.showError('Failed to load filters', error);
        }
    }

    connectedCallback() { this.loading = true; }

    handlePartnerChange(event) {
        this.selectedPartner = event.detail.value || 'ALL';
        this.loadAll();
    }
    handleUserChange(event) {
        this.selectedUser = event.detail.value || 'ALL';
        this.loadAll();
    }
    handleTimeframeChange(event) {
        this.timeframeDays = event.detail.value;
        this.loadAll();
    }

    loadAll() {
        this.loading = true;
        const partnerName = (this.selectedPartner === 'ALL') ? null : this.selectedPartner;
        const days = parseInt(this.timeframeDays, 10);

        getUserKpis({ partnerName, timeframeDays: days })
            .then(users => {
                this.userKpis = users || [];
            })
            .catch(err => {
                this.showError('Failed to load KPIs', err);
            })
            .finally(() => {
                this.loading = false;
            });
    }

    showError(title, error) {
        let message = (error && error.body && error.body.message) ? error.body.message : 'Unknown error';
        this.dispatchEvent(new ShowToastEvent({ title, message, variant: 'error' }));
    }
}
