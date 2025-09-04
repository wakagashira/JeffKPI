import { LightningElement, track } from 'lwc';
import getUserOptions from '@salesforce/apex/JeffKPIController.getUserOptions';
import getPartnerOptions from '@salesforce/apex/JeffKPIController.getPartnerOptions';
import getUserActivitySummaryFiltered from '@salesforce/apex/JeffKPIController.getUserActivitySummaryFiltered';
import getOpportunityMetricsFiltered from '@salesforce/apex/JeffKPIController.getOpportunityMetricsFiltered';

export default class JeffKpi extends LightningElement {
    @track userOptions = [{ label: 'All Users', value: '' }];
    @track partnerOptions = [{ label: 'All Partners', value: '' }];
    @track timeframeOptions = [
        { label: 'This Month', value: 'ThisMonth' },
        { label: 'Last Month', value: 'LastMonth' },
        { label: 'This Week', value: 'ThisWeek' },
        { label: 'Last Week', value: 'LastWeek' },
        { label: 'Last 7 Days', value: 'Last7Days' },
        { label: 'Last 30 Days', value: 'Last30Days' },
        { label: 'This Quarter', value: 'ThisQuarter' },
        { label: 'Last Quarter', value: 'LastQuarter' }
    ];

    selectedUserId = '';
    selectedPartner = '';
    selectedTimeframe = 'ThisMonth';

    @track metrics = { openCount: 0, openAmount: 0, wonCount: 0, wonAmount: 0, lostCount: 0, lostAmount: 0 };
    @track activity = { openTasks: 0, completedTasks: 0, events: 0 };

    connectedCallback() {
        Promise.all([getUserOptions(), getPartnerOptions()])
            .then(([users, partners]) => {
                this.userOptions = [{ label: 'All Users', value: '' }, ...users];
                this.partnerOptions = [{ label: 'All Partners', value: '' }, ...partners];
                this.refreshData();
            })
            .catch((e) => {
                console.error('Init error', e);
            });
    }

    handleUserChange(event) {
        this.selectedUserId = event.detail.value || '';
        this.refreshData();
    }
    handlePartnerChange(event) {
        this.selectedPartner = event.detail.value || '';
        this.refreshData();
    }
    handleTimeframeChange(event) {
        this.selectedTimeframe = event.detail.value;
        this.refreshData();
    }

    refreshData() {
        const userId = this.selectedUserId && this.selectedUserId !== '' ? this.selectedUserId : null;
        const partner = this.selectedPartner && this.selectedPartner !== '' ? this.selectedPartner : null;
        const tf = this.selectedTimeframe;

        Promise.all([
            getOpportunityMetricsFiltered({ timeframe: tf, selectedUserId: userId, selectedPartner: partner }),
            getUserActivitySummaryFiltered({ timeframe: tf, selectedUserId: userId, selectedPartner: partner })
        ]).then(([opps, act]) => {
            this.metrics = opps || this.metrics;
            this.activity = act || this.activity;
        }).catch((e) => {
            console.error('Refresh error', e);
        });
    }
}
